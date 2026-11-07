# ---------------------------------------------------------------------------
# migrate_legacy_db.ps1  (Windows / PowerShell equivalent of migrate_legacy_db.sh)
#
# One-shot, repeatable migration of the legacy Expertiza anonymized dump
# (anon_db\expertiza_anonymized_2026-10-20.sql) into the development database
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
#      estimate - see docs\legacy-expertiza-migration.md).
#
# WARNING: this DELETES the existing development database contents.
#
# Environment overrides (all optional):
#   $env:DUMP                 path to the legacy dump, relative to the repo root
#                             (default: anon_db\expertiza_anonymized_2026-10-20.sql)
#   $env:DB_NAME              target database (default: reimplementation_development)
#   $env:MYSQL_ROOT_PASSWORD  required (e.g. `$env:MYSQL_ROOT_PASSWORD = "expertiza"`)
#
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File db\migrate_legacy_db.ps1
# ---------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

$dbName   = if ($env:DB_NAME) { $env:DBName } else { 'reimplementation_development' }
$dump     = if ($env:DUMP) { Join-Path (Get-Location) $env:DUMP } else { Join-Path (Get-Location) 'anon_db\expertiza_anonymized_2026-10-20.sql' }
$surgery  = Join-Path (Get-Location) 'db\legacy_surgery.sql'
$network  = 'reimplementation-back-end_default'
$volume   = 'reimplementation-back-end_expertiza-mysql'
$tmpDir   = Join-Path (Get-Location) 'tmp'
New-Item -ItemType Directory -Force $tmpDir | Out-Null

if (-not (Test-Path $dump))    { throw "Legacy dump not found at $dump" }
if (-not (Test-Path $surgery)) { throw "Surgery script not found at $surgery" }
if ([string]::IsNullOrWhiteSpace($env:MYSQL_ROOT_PASSWORD)) { throw 'MYSQL_ROOT_PASSWORD is not set. Set it (e.g. `$env:MYSQL_ROOT_PASSWORD = "expertiza"`) and re-run.' }
$rootPw = $env:MYSQL_ROOT_PASSWORD

$timings = @()
function Start-Phase([string]$name) { $script:_phase = [System.Diagnostics.Stopwatch]::StartNew() }
function Stop-Phase([string]$name) {
  $script:timings += [pscustomobject]@{ Name = $name; Seconds = [math]::Round($script:_phase.Elapsed.TotalSeconds, 1) }
  Write-Host ("`n   (done in {0}s) == {1} ==" -f $script:_phase.Elapsed.TotalSeconds, $name)
}

# --- 1/5 reset + clean stack ---------------------------------------------
Write-Host "`n== 1/5 Reset Docker volumes and start a clean stack ==" -ForegroundColor Cyan
Start-Phase '1/5 Reset Docker volumes and start a clean stack'
docker compose down -v
# Wait until the MySQL volume is actually gone so a pristine one is created.
for ($i = 0; $i -lt 60; $i++) {
  $still = docker volume ls --quiet --filter "name=$volume"
  if (-not $still) { break }
  docker volume rm $volume 2>$null | Out-Null
  Start-Sleep -Seconds 1
}
docker compose up -d
Stop-Phase '1/5 Reset Docker volumes and start a clean stack'

# --- 2/5 wait for MySQL ----------------------------------------------------
Write-Host "`n== 2/5 Wait for MySQL ==" -ForegroundColor Cyan
Start-Phase '2/5 Wait for MySQL'
# mysqladmin prints a password-warning to stderr; with $ErrorActionPreference
# 'Stop' a native command's stderr becomes a terminating NativeCommandError,
# so the ping loops below temporarily drop back to 'Continue'.
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
do {
  Start-Sleep -Seconds 2
  docker compose exec -T db sh -c "mysqladmin -uroot -p$rootPw ping" *> $null
} while ($LASTEXITCODE -ne 0)
$ErrorActionPreference = $prevEap
# Verify that the database was created (it should be created by the init script).
$out = docker compose exec -T db sh -c "mysql -uroot -p$rootPw -e 'SHOW DATABASES;' 2>/dev/null"
if ($out -notmatch [regex]::Escape($dbName)) { throw "$dbName was not created" }

# After init the MySQL server is still starting up, so wait until it is fully ready to accept connections.
do {
  Start-Sleep -Seconds 2
  docker compose exec -T db sh -c "mysqladmin -uroot -p$rootPw ping" *> $null
} while ($LASTEXITCODE -ne 0)
$ErrorActionPreference = $prevEap
Stop-Phase '2/5 Wait for MySQL'

# --- 3/5 import the legacy dump -------------------------------------------
Write-Host "`n== 3/5 Import the legacy Expertiza dump (can take several minutes) ==" -ForegroundColor Cyan
Start-Phase '3/5 Import the legacy Expertiza dump'
# The legacy dump hardcodes DEFINER=`root`@`localhost` on its views. That
# account (or the SUPER privilege it would need) may not exist in other
# environments, so strip the DEFINER clause before import: with no DEFINER
# clause, MySQL records the importing user as the definer, which keeps the
# views portable. (MySQL has no CURRENT_USER() definer; omission = current user.)
$dumpPosix  = $dump.Replace('\', '/')
$logPosix   = "$tmpDir".Replace('\', '/')
docker run --rm --network $network `
  -v "${dumpPosix}:/dump:ro" -v "${logPosix}:/log:rw" `
  mysql:8.0 sh -c "time (sed -e 's|/\*!50013 DEFINER=[^*]*\*/||' /dump | MYSQL_PWD=$rootPw mysql -h db -uroot $dbName)" > "$tmpDir\import.log" 2>&1
if ($LASTEXITCODE -ne 0) { throw "Import failed; see $tmpDir\import.log" }
Get-Content "$tmpDir\import.log" | Select-String -Pattern 'real|error|ERROR'
Stop-Phase '3/5 Import the legacy Expertiza dump'

# Dump current schema of the database for reference (not strictly necessary, but useful for debugging).
docker compose exec -T db sh -c "mysqldump -uroot -p$rootPw --no-data $dbName > /docker-entrypoint-initdb.d/rei_dev_legacy_schema.sql.txt"

# --- 4/5 schema_migrations surgery -----------------------------------------
Write-Host "`n== 4/5 Mark the old migrations as applied (schema_migrations surgery) ==" -ForegroundColor Cyan
Start-Phase '4/5 Mark the old migrations as applied (schema_migrations surgery)'
$surgeryPosix = $surgery.Replace('\', '/')
docker run --rm --network $network `
  -v "${surgeryPosix}:/surgery:ro" `
  mysql:8.0 sh -c "MYSQL_PWD=$rootPw mysql -h db -uroot $dbName < /surgery"
if ($LASTEXITCODE -ne 0) { throw 'schema_migrations surgery failed' }
docker compose exec -T db sh -c "MYSQL_PWD=$rootPw mysql -uroot $dbName -e 'SELECT COUNT(*) AS marked_applied FROM schema_migrations;' 2>/dev/null"
Stop-Phase '4/5 Mark the old migrations as applied (schema_migrations surgery)'

# --- 5/5 run the migrations --------------------------------------------------
Write-Host "`n== 5/5 Run the guarded 2026 bridge + legacy translation migrations ==" -ForegroundColor Cyan
Start-Phase '5/5 Run the guarded 2026 bridge + legacy translation migrations'
docker compose exec -T app sh -c "cd /app && RAILS_ENV=development bundle exec rake db:migrate 2>&1"
if ($LASTEXITCODE -ne 0) { throw 'rake db:migrate failed' }
Stop-Phase '5/5 Run the guarded 2026 bridge + legacy translation migrations'

# --- verification ------------------------------------------------------------
Write-Host "`n== Verification ==" -ForegroundColor Cyan
docker compose exec -T db sh -c @"
MYSQL_PWD=$rootPw mysql -uroot $dbName 2>/dev/null -e "SELECT COUNT(DISTINCT TABLE_NAME) AS tables FROM information_schema.tables WHERE table_schema = '$dbName' AND table_type = 'BASE TABLE'; SELECT (SELECT COUNT(*) FROM users) AS users, (SELECT COUNT(*) FROM assignments) AS assignments, (SELECT COUNT(*) FROM answers) AS answers, (SELECT COUNT(*) FROM participants) AS participants, (SELECT COUNT(*) FROM items) AS items, (SELECT COUNT(*) FROM project_topics) AS project_topics, (SELECT COUNT(*) FROM teams_users) AS teams_users, (SELECT COUNT(*) FROM teams_participants) AS teams_participants\G"
"@

# The reference dump can fail on the legacy scratch view `view2` (its definition
# references a column the 2026 bridge removes - see docs). PowerShell does not
# throw on a native command's exit code, so the run continues past it.
docker compose exec db sh -c "mysqldump -uroot -p$rootPw --no-data $dbName > /docker-entrypoint-initdb.d/rei_dev_legacy_schema_post_migration.sql.txt"

Write-Host "`n== Phase timing summary =="
$total = 0.0
foreach ($t in $timings) { $total += $t.Seconds; Write-Host ("  {0,-60} {1,6}s" -f $t.Name, $t.Seconds) }
Write-Host ("  {0,-60} {1,6}s" -f 'TOTAL (import + surgery + migrations)', [math]::Round($total, 1))
Write-Host '  import + surgery + migrations is the maintenance-window lower bound for production'

Write-Host @"

Done. Next steps:
  - Boot the app:         docker compose up -d app
  - No-seed smoke test:   docker compose exec app sh -c "cd /app && bin/rails runner db/smoke_test_legacy.rb"
"@
