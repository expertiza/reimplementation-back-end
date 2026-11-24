# The converged legacy shape is the canonical schema

Status: accepted

The project supports two database populations — a **canonical chain** build
(2023–2026 migrations from an empty database) and a **legacy-migrated**
database (anonymized dump → bridge → convergence). They diverge in details
that a `rake db:migrate` schema dump encodes: the legacy path yields
`fk_canon_*`-named foreign keys, no-precision `DATETIME` columns, and a
`cakes` table, while the clean chain yields chain-named foreign keys
(`fk_course_users`, …) and precision-6 timestamps.

**Decision:** the committed `db/schema.rb` (version `2026_11_01_000005`,
dumped from the converged legacy shape) is the *single* definition of the
canonical schema. The application, tests, and the no-seed smoke test target
that shape; the clean chain is hardened to stay app-compatible with it
rather than the two shapes being unified (e.g. `cakes` is created on every
path so both populations carry it).

**Considered options**

1. *Regenerate `db/schema.rb` from the clean chain* (the pre-convergence
   shape, as on `origin/main` at version `2026_10_28_000002`): rejected —
   `db:schema:load` would then reproduce a shape the migrated development
   and production databases do not have, so every test database would
   diverge from the real data.
2. *Rewrite the 2023–2025 chain migrations to emit the converged shape*
   (`fk_canon_*` names, no-precision datetimes): rejected — a large
   upstream diff for a difference invisible to Active Record (FK constraint
   names and DATETIME precision are not read by the application).

**Consequences**

- "Canonical" in `docs/legacy-expertiza-migration.md` means the converged
  shape, *not* the pre-convergence schema on `origin/main`. When this branch
  merges upstream, the branch's `db/schema.rb` redefines upstream "canonical".
- Residual cosmetic divergences between the two build paths — FK constraint
  names, DATETIME precision, and the column set of the vestigial
  `questionnaire_types` table (the bridge creates it with `display_type` on
  a clean database; the converged shape has `name`) — are accepted. No
  application code reads the `questionnaire_types` table; the app keys
  questionnaires through the `questionnaires.questionnaire_type` column and
  `Questionnaire::QUESTIONNAIRE_TYPES`. Do not "fix" one path's
  `questionnaire_types` shape without re-running both verification paths.
- A freshly migrated database shows 56 base tables until any Rails process
  connects (the bridge drops `ar_internal_metadata`; Rails recreates it on
  connect). The documented steady state is 57 base tables + 1 view.
- The gitignored schema snapshots under `db/*.txt` are investigation
  artifacts of one rehearsal run, not canonical references.
