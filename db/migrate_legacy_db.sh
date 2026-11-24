#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# migrate_legacy_db.sh  (Linux / bash equivalent of migrate_legacy_db.ps1)
#
# One-shot, repeatable migration of the legacy Expertiza anonymized dump
# (anon_db/expertiza_anonymized_2026-10-20.sql) into the development database
# of the reimplementation.
#
#   1. Resets the Docker MySQL/Redis volumes and starts a clean stack.
#   2. Imports the legacy dump into reimplementation_development.
#   3. Rewrites schema_migrations so that the unguarded 2023-2025 migrations
#      (which would collide with the legacy tables) are treated as applied.
#   4. Runs `rake db:migrate` (only the guarded 2026 bridge + translation
#      migrations actually execute).
#   5. Prints verification results (table count, key row counts) and a
#      per-phase timing summary (the basis for the production downtime
#      estimate - see docs/legacy-expertiza-migration.md).
#
# WARNING: this DELETES the existing development database contents.
#
# Environment overrides (all optional):
#   DUMP                  path to the legacy dump to import
#                         (default: anon_db/expertiza_anonymized_2026-10-20.sql)
#   DB_NAME               target database (default: reimplementation_development)
#   MYSQL_ROOT_PASSWORD   required (e.g. export MYSQL_ROOT_PASSWORD=expertiza)
#
# Usage:  bash db/migrate_legacy_db.sh
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")/.."

DB_CONTAINER="db"
DB_NAME="${DB_NAME:-reimplementation_development}"
DUMP="${DUMP:-anon_db/expertiza_anonymized_2026-10-20.sql}"
SURGERY="db/legacy_surgery.sql"
NETWORK="${COMPOSE_PROJECT_NAME:-reimplementation-back-end}_default"
VOLUME="${COMPOSE_PROJECT_NAME:-reimplementation-back-end}_expertiza-mysql"
TMP_DIR="tmp"
mkdir -p "$TMP_DIR"

[ -f "$DUMP" ]    || { echo "Legacy dump not found at $DUMP" >&2; exit 1; }
[ -f "$SURGERY" ] || { echo "Surgery script not found at $SURGERY" >&2; exit 1; }
if [ -z "${MYSQL_ROOT_PASSWORD:-}" ]; then
  echo "MYSQL_ROOT_PASSWORD is not set. Export it (e.g. export MYSQL_ROOT_PASSWORD=expertiza) and re-run." >&2
  exit 1
fi

log() { printf '\033[1;34m== %s ==\033[0m' "$*"; }

# Per-phase timing, printed as a summary at the end. The import + surgery +
# migrate durations are the maintenance-window lower bound for the production
# run (see docs/legacy-expertiza-migration.md).
TIMINGS=()
phase_begin() { SECONDS=0; }
phase_end() {
  TIMINGS+=("$1|$SECONDS")
  printf '\033[0m\n   (done in %ds) == %s ==\033[0m\n' "$SECONDS" "$1"
}

# --- 1/5 reset + clean stack ---------------------------------------------
log "1/5 Reset Docker volumes and start a clean stack"
phase_begin "1/5 Reset Docker volumes and start a clean stack"
docker compose down -v
# Wait until the MySQL volume is actually gone so a pristine one is created.
for i in $(seq 1 60); do
  if ! docker volume ls --quiet --filter "name=$VOLUME" | grep -q .; then
    break
  fi
  docker volume rm "$VOLUME" >/dev/null 2>&1 || true
  sleep 1
done
docker compose up -d
phase_end "1/5 Reset Docker volumes and start a clean stack"

# --- 2/5 wait for MySQL ----------------------------------------------------
log "2/5 Wait for MySQL"
phase_begin "2/5 Wait for MySQL"
until docker compose exec -T "$DB_CONTAINER" sh -c "mysqladmin -uroot -p$MYSQL_ROOT_PASSWORD ping" >/dev/null 2>&1; do
  sleep 2
done
# Verify that the database was created (it should be created by the init script).
# Retried in a loop because the server can still be transitioning to the real
# instance right after init: a one-shot query would transiently fail there.
db_ready=0
i=0
while [ "$db_ready" -eq 0 ]; do
  out="$(docker compose exec -T "$DB_CONTAINER" sh -c "mysql -uroot -p$MYSQL_ROOT_PASSWORD -e 'SHOW DATABASES;' 2>/dev/null" || true)"
  case "$out" in
    *"$DB_NAME"*) db_ready=1 ;;
    *)
      i=$((i + 1))
      if [ "$i" -ge 60 ]; then
        echo "$DB_NAME was not created" >&2
        exit 1
      fi
      sleep 2
      ;;
  esac
done
# After init the MySQL server is still starting up, so wait until it is fully ready to accept connections.
until docker compose exec -T "$DB_CONTAINER" sh -c "mysqladmin -uroot -p$MYSQL_ROOT_PASSWORD ping" >/dev/null 2>&1; do
  sleep 2
done
phase_end "2/5 Wait for MySQL"

# --- 3/5 import the legacy dump -------------------------------------------
log "3/5 Import the legacy Expertiza dump (can take several minutes)"
phase_begin "3/5 Import the legacy Expertiza dump (can take several minutes)"
# The legacy dump hardcodes DEFINER=`root`@`localhost` on its views. That
# account (or the SUPER privilege it would need) may not exist in other
# environments, so strip the DEFINER clause before import: with no DEFINER
# clause, MySQL records the importing user as the definer, which keeps the
# views portable. (MySQL has no CURRENT_USER() definer; omission = current user.)
if ! docker run --rm --network "$NETWORK" \
  -v "$(pwd)/$DUMP":/dump:ro -v "$(pwd)/$TMP_DIR:/log:rw" \
  mysql:8.0 sh -c "time (sed -e 's|/\*!50013 DEFINER=[^*]*\*/||' /dump | MYSQL_PWD=$MYSQL_ROOT_PASSWORD mysql -h ${DB_CONTAINER} -uroot ${DB_NAME})" \
  > "$TMP_DIR/import.log" 2>&1; then
  echo "Import failed; see $TMP_DIR/import.log" >&2; tail -20 "$TMP_DIR/import.log" >&2; exit 1
fi
grep -E 'real|error|ERROR' "$TMP_DIR/import.log" || true
phase_end "3/5 Import the legacy Expertiza dump (can take several minutes)"

# Dump current schema of the database for reference (not strictly necessary, but useful for debugging).
docker compose exec -T "$DB_CONTAINER" sh -c "mysqldump -uroot -p$MYSQL_ROOT_PASSWORD --no-data $DB_NAME > /docker-entrypoint-initdb.d/rei_dev_legacy_schema.sql.txt"

# --- 4/5 schema_migrations surgery -----------------------------------------
log "4/5 Mark the old migrations as applied (schema_migrations surgery)"
phase_begin "4/5 Mark the old migrations as applied (schema_migrations surgery)"
docker run --rm --network "$NETWORK" \
  -v "$(pwd)/$SURGERY":/surgery:ro \
  mysql:8.0 sh -c "MYSQL_PWD=$MYSQL_ROOT_PASSWORD mysql -h ${DB_CONTAINER} -uroot ${DB_NAME} < /surgery" \
  || { echo "schema_migrations surgery failed" >&2; exit 1; }
docker compose exec -T "$DB_CONTAINER" sh -c "MYSQL_PWD=$MYSQL_ROOT_PASSWORD mysql -uroot $DB_NAME -e 'SELECT COUNT(*) AS marked_applied FROM schema_migrations;' 2>/dev/null"
phase_end "4/5 Mark the old migrations as applied (schema_migrations surgery)"

# --- 5/5 run the migrations --------------------------------------------------
log "5/5 Run the guarded 2026 bridge + legacy translation migrations"
phase_begin "5/5 Run the guarded 2026 bridge + legacy translation migrations"
docker compose exec -T app sh -c "cd /app && RAILS_ENV=development bundle exec rake db:migrate 2>&1" \
  || { echo "rake db:migrate failed" >&2; exit 1; }
phase_end "5/5 Run the guarded 2026 bridge + legacy translation migrations"

# --- verification ------------------------------------------------------------
log "Verification"
docker compose exec -T "$DB_CONTAINER" sh -c "MYSQL_PWD=$MYSQL_ROOT_PASSWORD mysql -uroot $DB_NAME 2>/dev/null -e \"SELECT COUNT(DISTINCT TABLE_NAME) AS tables FROM information_schema.tables WHERE table_schema = '$DB_NAME' AND table_type = 'BASE TABLE'; SELECT (SELECT COUNT(*) FROM users) AS users, (SELECT COUNT(*) FROM assignments) AS assignments, (SELECT COUNT(*) FROM answers) AS answers, (SELECT COUNT(*) FROM participants) AS participants, (SELECT COUNT(*) FROM items) AS items, (SELECT COUNT(*) FROM project_topics) AS project_topics, (SELECT COUNT(*) FROM teams_users) AS teams_users, (SELECT COUNT(*) FROM teams_participants) AS teams_participants\\G\""

# The reference dump can fail on the legacy scratch view `view2` (its definition
# references a column the 2026 bridge removes - see docs); that is expected and
# non-fatal, so a failed reference dump must not abort the run under set -e.
docker compose exec -T "$DB_CONTAINER" sh -c "mysqldump -uroot -p${MYSQL_ROOT_PASSWORD} --no-data $DB_NAME > /docker-entrypoint-initdb.d/rei_dev_legacy_schema_post_migration.sql.txt" || true

echo
echo "== Phase timing summary =="
total=0
for entry in "${TIMINGS[@]}"; do
  ph="${entry%|*}"; dt="${entry#*|}"; total=$((total + dt))
  printf "  %-60s %4ds\n" "$ph" "$dt"
done
printf "  %-60s %4ds\n" "TOTAL (import + surgery + migrations)" "$total"
echo "  import + surgery + migrations is the maintenance-window lower bound for production"

log "Done. Next steps:
  - Boot the app:         docker compose up -d app
  - No-seed smoke test:   docker compose exec app sh -c \"cd /app && bin/rails runner db/smoke_test_legacy.rb\"
"
