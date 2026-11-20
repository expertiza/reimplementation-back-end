#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# migrate_production_db.sh
#
# Production counterpart of migrate_legacy_db.sh.
#
# migrate_legacy_db.sh is a DEVELOPMENT convenience: it resets the local
# Docker volumes and targets the dev database. This script operates on a real
# MySQL 8.x / MariaDB 10.x/11.x server over TCP and performs the same
# translation, in one of two modes:
#
#   FRESH TARGET (default): creates a new database and imports a full data
#     dump of the legacy production DB before converting it.
#   IN_PLACE=1: converts the EXISTING legacy production database in place
#     (no import; nothing is dropped). This is the intended mode for a
#     production that keeps its current server (e.g. MariaDB 10.11).
#
# Phases:
#   1. Preflight: server reachable, engine accepted (MySQL >= 8 /
#      MariaDB >= 10), target DB empty (fresh mode) / present (IN_PLACE).
#   2. Create the target database (fresh mode only; utf8mb4 /
#      utf8mb4_general_ci - a collation both engines support; the
#      MySQL-only utf8mb4_0900_ai_ci is deliberately not used).
#   3. Import the full data dump (fresh mode only; view DEFINER clauses
#      stripped, as in the dev flow).
#   4. Run db/legacy_surgery.sql against the target DB (USE line rewritten).
#   5. Optionally run `rake db:migrate` in a Rails app image (APP_IMAGE),
#      which executes the guarded 2026 bridge + convergence migrations.
#
# It then verifies (tables/views/row counts) and prints a per-phase timing
# summary, which is the anticipated maintenance-window duration.
#
# NOTHING here deletes an existing database. The convergence migration is
# irreversible, so your rollback is restoring the pre-migration backup
# (in place mode: a full dump taken during the maintenance window).
#
# Required env:
#   TARGET_DB   the target database (fresh name, or the legacy DB for IN_PLACE)
#   MYSQL_PWD   password for MYSQL_USER
#   DUMP        full data dump of the legacy production DB (fresh mode only)
# Optional env:
#   IN_PLACE=1  convert the existing TARGET_DB in place (no import)
#   MYSQL_HOST (default 127.0.0.1)   MYSQL_PORT (3306)   MYSQL_USER (root)
#   APP_IMAGE  Rails app image; when set, phase 5 runs rake db:migrate in it
#   APP_NET    docker network the app image can reach the server from
#   APP_USER   runtime app DB user name (used in the printed grant statements)
#   FORCE=1    proceed even if the target DB is not empty (fresh mode)
#
# Usage (in place, the production scenario):
#   IN_PLACE=1 TARGET_DB=expertiza MYSQL_HOST=prod-host MYSQL_PWD=... \
#   bash db/migrate_production_db.sh
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")/.."

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
TARGET_DB="${TARGET_DB:-}"
DUMP="${DUMP:-}"
APP_IMAGE="${APP_IMAGE:-}"
APP_NET="${APP_NET:-}"
APP_USER="${APP_USER:-expertiza_app}"
SURGERY="db/legacy_surgery.sql"
TMP_DIR="tmp"
mkdir -p "$TMP_DIR"

if [ -z "$TARGET_DB" ]; then echo "TARGET_DB is required" >&2; exit 1; fi
if [ "${IN_PLACE:-0}" -ne 1 ]; then
  if [ -z "$DUMP" ]; then echo "DUMP is required (path to the full production data dump; not needed with IN_PLACE=1)" >&2; exit 1; fi
  [ -f "$DUMP" ] || { echo "Dump not found at $DUMP" >&2; exit 1; }
fi
[ -f "$SURGERY" ] || { echo "Surgery script not found at $SURGERY" >&2; exit 1; }
if [ -z "${MYSQL_PWD:-}" ]; then echo "MYSQL_PWD is required (password for MYSQL_USER)" >&2; exit 1; fi

TIMINGS=()
phase_begin() { SECONDS=0; }
phase_end() {
  TIMINGS+=("$1|$SECONDS")
  printf '\033[0m\n   (done in %ds) == %s ==\033[0m\n' "$SECONDS" "$1"
}
log() { printf '\033[1;34m== %s ==\033[0m\n' "$*"; }

# MySQL client: a local client when available, otherwise the mysql:8 image
# (reached over the network / a compose network). All SQL is passed on stdin
# so the same function works for both; only single-token flags follow.
net_args=()
[ -n "$APP_NET" ] && net_args=(--network "$APP_NET")
if command -v mysql >/dev/null 2>&1; then
  msql() { MYSQL_PWD="$MYSQL_PWD" mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" "$@"; }
else
  msql() {
    MYSQL_PWD="$MYSQL_PWD" docker run --rm "${net_args[@]}" -i mysql:8 sh -c \
      "mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER $*"
  }
fi

# --- 1/5 preflight -----------------------------------------------------------
log "1/5 Preflight checks"
phase_begin "1/5 Preflight checks"
ver_out="$(printf 'SELECT VERSION();' | msql -N)" || { echo "Cannot reach MySQL/MariaDB at $MYSQL_HOST:$MYSQL_PORT as $MYSQL_USER" >&2; exit 1; }
ver="${ver_out%%@*}"
case "$ver" in
  *MariaDB*) engine="MariaDB"; major="${ver%%.*}" ;;
  *)         engine="MySQL";   major="${ver%%.*}" ;;
esac
# MySQL: 8.x (Rails 8 adapter baseline). MariaDB: 10.x/11.x (the collations
# used are utf8mb4_general_ci, which both engines support; MySQL-only
# collations like utf8mb4_0900_ai_ci are deliberately avoided).
if [ "$engine" = "MySQL" ] && [ "$major" -lt 8 ]; then
  echo "$engine $ver is too old: the canonical schema requires MySQL 8.x or MariaDB 10.x/11.x." >&2
  exit 1
fi
if [ "$engine" = "MariaDB" ] && [ "$major" -lt 10 ]; then
  echo "$engine $ver is too old: the canonical schema requires MariaDB 10.x/11.x." >&2
  exit 1
fi
echo "   server: $engine $ver"
cnt="$(printf "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$TARGET_DB' AND table_type='BASE TABLE';" | msql -N 2>/dev/null || echo 0)"
if [ "${cnt:-0}" -gt 0 ] && [ "${FORCE:-0}" -ne 1 ] && [ "${IN_PLACE:-0}" -ne 1 ]; then
  echo "Target DB $TARGET_DB already contains $cnt tables; refusing to proceed (set FORCE=1, or IN_PLACE=1 to convert that database in place)." >&2
  exit 1
fi
if [ "${IN_PLACE:-0}" -eq 1 ]; then
  echo "   IN_PLACE mode: converting the existing $TARGET_DB ($cnt tables); no import, nothing is dropped"
fi
phase_end "1/5 Preflight checks"

# --- 2/5 create target DB (fresh target only) ---------------------------------
log "2/5 Create target database"
phase_begin "2/5 Create target database"
if [ "${IN_PLACE:-0}" -ne 1 ]; then
  printf "CREATE DATABASE IF NOT EXISTS \`$TARGET_DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" | msql
else
  echo "   in-place: using the existing database"
fi
phase_end "2/5 Create target database"

# --- 3/5 import the legacy production dump (fresh target only) -----------------
log "3/5 Import the production dump (the long phase)"
phase_begin "3/5 Import the production dump"
if [ "${IN_PLACE:-0}" -ne 1 ]; then
  # Strip DEFINER from the legacy views before import: with no DEFINER clause,
  # the server records the importing user as definer, which keeps the views
  # portable (the dump hardcodes a DEFINER account that may not exist on the
  # target).
  if command -v mysql >/dev/null 2>&1; then
    if ! sed -e 's|/\*!50013 DEFINER=[^*]*\*/||' "$DUMP" | msql "$TARGET_DB" > "$TMP_DIR/prod_import.log" 2>&1; then
      echo "Import failed; see $TMP_DIR/prod_import.log" >&2; tail -20 "$TMP_DIR/prod_import.log" >&2; exit 1
    fi
  else
    dump_abs="$(cd "$(dirname "$DUMP")" && pwd)/$(basename "$DUMP")"
    if ! MYSQL_PWD="$MYSQL_PWD" docker run --rm "${net_args[@]}" -v "${dump_abs}:/dump:ro" mysql:8 sh -c \
        "time (sed -e 's|/\*!50013 DEFINER=[^*]*\*/||' /dump | mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER $TARGET_DB)" \
        > "$TMP_DIR/prod_import.log" 2>&1; then
      echo "Import failed; see $TMP_DIR/prod_import.log" >&2; tail -20 "$TMP_DIR/prod_import.log" >&2; exit 1
    fi
  fi
  grep -Ei 'error' "$TMP_DIR/prod_import.log" || true
else
  echo "   in-place: data already present, skipping import"
fi
phase_end "3/5 Import the production dump"

# --- 4/5 schema_migrations surgery --------------------------------------------
log "4/5 Mark the legacy-colliding migrations as applied (surgery)"
phase_begin "4/5 schema_migrations surgery"
surgery_db="$(sed "s/USE [^;]*;/USE \`$TARGET_DB\`;/" "$SURGERY")"
if ! printf '%s\n' "$surgery_db" | msql "$TARGET_DB" >/dev/null; then
  echo "schema_migrations surgery failed" >&2; exit 1
fi
printf 'SELECT COUNT(*) AS marked_applied FROM schema_migrations;' | msql "$TARGET_DB" -N
phase_end "4/5 schema_migrations surgery"

# --- 5/5 run the migrations (optional: requires a Rails app image) ------------
log "5/5 Run the guarded 2026 bridge + convergence migrations"
if [ -n "$APP_IMAGE" ]; then
  phase_begin "5/5 rake db:migrate"
  # config/database.yml rewrites DATABASE_URL by appending _<RAILS_ENV> to the
  # base name, so the URL base must be TARGET_DB minus its _production suffix.
  url_base="${TARGET_DB%_production}"
  if [ "$url_base" = "$TARGET_DB" ]; then
    echo "   note: TARGET_DB does not end in '_production'; Rails will look for ${TARGET_DB}_production (check the name)"
  fi
  # Assumes the app image keeps the repository at /app (as the dev Dockerfile does).
  if ! MYSQL_PWD="$MYSQL_PWD" docker run --rm "${net_args[@]}" \
      -e "DATABASE_URL=mysql2://$MYSQL_USER:***@${MYSQL_HOST}:${MYSQL_PORT}/${url_base}?" \
      -e RAILS_ENV=production \
      "$APP_IMAGE" sh -c "cd /app && bundle exec rake db:migrate 2>&1" \
      > "$TMP_DIR/prod_migrate.log" 2>&1; then
    echo "rake db:migrate failed; see $TMP_DIR/prod_migrate.log" >&2
    tail -30 "$TMP_DIR/prod_migrate.log" >&2
    exit 1
  fi
  phase_end "5/5 rake db:migrate"
else
  echo "   APP_IMAGE not set - run this once the app can reach the server:"
  echo "   DATABASE_URL='mysql2://$MYSQL_USER:<app-pass>@${MYSQL_HOST}:${MYSQL_PORT}/${TARGET_DB%_production}?' RAILS_ENV=production bundle exec rake db:migrate"
fi

# --- verification --------------------------------------------------------------
log "Verification"
printf "SELECT COUNT(DISTINCT TABLE_NAME) AS tables FROM information_schema.tables WHERE table_schema = '$TARGET_DB' AND table_type = 'BASE TABLE'; SELECT (SELECT COUNT(*) FROM users) AS users, (SELECT COUNT(*) FROM assignments) AS assignments, (SELECT COUNT(*) FROM answers) AS answers, (SELECT COUNT(*) FROM participants) AS participants, (SELECT COUNT(*) FROM items) AS items, (SELECT COUNT(*) FROM project_topics) AS project_topics, (SELECT COUNT(*) FROM teams_users) AS teams_users, (SELECT COUNT(*) FROM teams_participants) AS teams_participants\\G" | msql "$TARGET_DB" 2>/dev/null || true

echo
echo "== Phase timing summary (anticipated maintenance-window duration) =="
total=0
for entry in "${TIMINGS[@]}"; do
  ph="${entry%|*}"; dt="${entry#*|}"; total=$((total + dt))
  printf "  %-55s %4ds\n" "$ph" "$dt"
done
printf "  %-55s %4ds\n" "TOTAL" "$total"
echo "  Add your final-dump time and the app cutover time to this total."
echo
cat <<GRANTS
== Create the runtime app account (or reuse the legacy app user) ==
-- In in-place mode the legacy app's existing user already has the privileges
-- on this database and can be reused; the statements below are for a fresh
-- least-privilege account. Create fresh accounts rather than importing the
-- legacy server's GRANT dump (MySQL 8.4 disables mysql_native_password by
-- default, so legacy accounts would fail to load there; on MariaDB either
-- way works, but a new account is still the cleaner option).
CREATE USER IF NOT EXISTS '$APP_USER'@'%' IDENTIFIED BY '<strong-password>';
GRANT SELECT, INSERT, UPDATE, DELETE ON \`$TARGET_DB\`.* TO '$APP_USER'@'%';
FLUSH PRIVILEGES;

== Cutover ==
  Point the app at the database, then verify:
    DATABASE_URL='mysql2://$APP_USER:<strong-password>@${MYSQL_HOST}:${MYSQL_PORT}/<url-base>?' RAILS_ENV=production bin/rails runner db/smoke_test_legacy.rb
  Rollback if needed: stop the app and restore the pre-migration backup
  (in in-place mode: the full dump taken during the maintenance window -
  the convergence migration is irreversible and cannot be rolled back in place).
GRANTS


