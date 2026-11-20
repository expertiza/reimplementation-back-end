# Expertiza Reimplementation

Reimplementation of the Expertiza peer-review application. This glossary
covers the database-migration domain: the two database populations the
project supports and the stages that convert one into the other.

## Language

### Database populations

**Legacy shape**:
The original Expertiza database schema: INT primary keys, utf8mb3/latin1
character sets, and the legacy table names (`questions`, `sign_up_topics`,
`teams_users`, `goldberg_*`, `sessions`, …).
_Avoid_: old schema, the dump schema

**Anonymized dump**:
The one-off snapshot of the legacy production database with personal data
anonymized (`anon_db/expertiza_anonymized_2026-10-20.sql`); the only source
of legacy data.
_Avoid_: the SQL file, the big dump

**Legacy-migrated database**:
A database produced by the legacy import procedure: anonymized dump imported,
then bridge, then convergence. Holds legacy *data* in canonical *shape*.
_Avoid_: the new DB, the converted DB

**Canonical chain**:
The reimplementation's 2023–2026 migration set, run from an empty database,
producing a database built only from the reimplementation's own migrations.
_Avoid_: clean chain, from-scratch chain, original migrations

**Canonical schema**:
The single target database shape for the project, defined by the committed
`db/schema.rb` (version `2026_11_01_000005` — the converged legacy shape).
Both database populations are expected to match it. See ADR-0001.
_Avoid_: new schema, target schema, the reimplementation schema

### Procedure stages

**Surgery**:
The `schema_migrations` rewrite (`db/legacy_surgery.sql`) that marks the
unguarded 2023–2025 migrations as already applied, so `rake db:migrate`
executes only the guarded 2026 set against a freshly imported legacy database.
_Avoid_: the hack, the migration cheat

**Bridge**:
The guarded 2026 migrations that translate a legacy database to canonical
*names* — table/column renames, legacy-table drops, data translation —
without yet reaching full shape parity.
_Avoid_: 2026 migrations, transformations

**Convergence**:
The one-shot, irreversible step (`20261101000005`) that rewrites a legacy
database to the exact canonical shape: drops every legacy-only table, widens
keys to BIGINT, normalizes types, defaults, and character sets, and
re-creates the canonical foreign keys and the `score_views` view.
_Avoid_: cleanup, final migration, the big DDL
