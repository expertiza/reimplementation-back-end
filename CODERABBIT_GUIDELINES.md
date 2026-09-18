# CodeRabbit Setup For This Repository

This repository uses CodeRabbit as an AI pull request reviewer for the Expertiza backend reimplementation. The goal is to improve review quality and preserve project-specific policy without replacing the existing CI runners.

## What CodeRabbit Should Do Here

- Review pull requests automatically and re-review on new commits.
- Leave useful inline comments on Rails, API, database, workflow, and test changes.
- Summarize the impact of a pull request clearly for human reviewers.
- Surface policy issues that used to live in Danger-like rules, but start in warning mode instead of blocking merges.
- Read GitHub check results and use them as context when tests or workflows fail.

## What CodeRabbit Should Not Replace Here

- GitHub Actions still runs the real work.
- `main.yml` and `TestPR.yml` still execute RSpec, database setup, coverage generation, and Docker-related jobs.
- `lint.yml` still remains the source of truth for runnable spellcheck and lint workflows unless those checks are intentionally retired.
- CodeRabbit is a reviewer and explainer, not the test runner or deployment engine.

## Repository Context

- Language and framework: Ruby 3.4.5 with Rails 8.
- Test stack: RSpec, mainly under `spec/models` and `spec/requests`.
- API surface: controllers plus request specs, with Swagger documentation checked into `swagger/v1/swagger.yaml`.
- Database: MySQL-backed Rails app with a large migration history and `db/schema.rb` committed.
- Automation: GitHub Actions workflows in `.github/workflows`, including CI, PR test reporting, linting, and Danger.

## Review Standards For This Codebase

### Controllers

- Verify authorization behavior and strong parameters.
- Check HTTP status codes and response payload consistency.
- Flag N+1 queries or heavy database work in request paths.
- Expect request-spec coverage for behavior changes.
- If an endpoint contract changes, expect Swagger documentation to stay in sync.

### Models

- Check associations, validations, callbacks, and transactions.
- Pay extra attention to STI, polymorphic associations, foreign keys, and null constraints.
- Prefer data integrity enforced in both application code and schema where appropriate.
- Flag query inefficiencies and fragile callback chains.

### Serializers And Mailers

- Watch for accidental exposure of internal fields or sensitive data.
- Keep serialized response shape stable unless the PR explicitly changes the API contract.
- For mailers, ensure template data and recipients are safe and consistent.

### Routes And API Docs

- Flag duplicate, shadowed, or surprising route definitions.
- Require controller, request-spec, and Swagger alignment when routes or endpoints change.

### Migrations And Schema

- Prefer reversible migrations.
- Check for missing indexes, foreign keys, null constraints, and destructive data changes.
- If `db/schema.rb` changes, expect a matching migration.
- Schema changes should usually have corresponding model and test updates.

### Tests

- Prefer meaningful request and model specs over shallow examples.
- Check authentication, authorization, invalid input, and failure paths.
- Flag behavior changes in `app/` or `config/routes.rb` that are not reflected in `spec/models` or `spec/requests`.
- Apply the legacy Expertiza Danger RSpec rules:
  - avoid skipped, pending, or focused tests
  - avoid `.should`
  - avoid redundant helper `require` lines
  - avoid overusing `create(` in unit-style specs when lighter setup would work
  - flag shallow expectations such as wildcard matcher overuse, missing expectations, commented-out expectations,
    matcher-less expectations, and assertions that only prove values are not nil, empty, or zero

### Workflows And Bot Files

- Treat workflow changes as security-sensitive.
- Flag `pull_request_target` combined with checkout of PR-head code, broad write permissions, unsafe token handling, brittle artifact passing, and comment spam patterns.
- If a Danger rule is removed, the replacement enforcement path must be explicit.

## Legacy Danger Policy To Preserve

The repository now carries a larger Expertiza-style Danger policy. CodeRabbit should mirror that policy in spirit even when the rule is heuristic rather than executable.

### Pull Request Hygiene

- Welcome first-time or non-maintainer contributors politely.
- Flag PRs over roughly 500 LoC.
- Flag course-project PRs under roughly 50 LoC.
- Flag PRs touching more than 30 files.
- Flag many duplicated commit messages.
- Flag WIP titles.

### Change Content Rules

- Flag newly added TODO or FIXME markers.
- Fail or strongly warn on temp, tmp, or cache artifacts committed into the PR.
- Flag newly introduced global variables, class variables, and obvious debug code.
- Flag application changes without corresponding test changes.

### Spec Rules

- Flag skipped, pending, or focused tests.
- Discourage `create(` inside model and controller specs when lighter setup would work.
- Reject `.should`.
- Reject redundant `require 'rspec'`, `spec_helper`, `rails_helper`, `test_helper`, or factory helper lines in specs.
- Warn on committed `.txt` or `.csv` files under spec paths unless clearly justified.

### Sensitive Files

- Non-maintainer changes to Markdown, YAML, helper files, Gemfile, Gemfile.lock, `.gitignore`, `.rspec`,
  `Dangerfile`, `Rakefile`, `config.ru`, `setup.sh`, `vendor/**`, and `spec/factories/**` should be scrutinized closely.
- Schema changes should normally come with migrations.

### Shallow Test Detection

- Flag excessive wildcard argument matchers.
- Flag tests with no expectations.
- Flag commented-out expectations.
- Flag expectations without matchers.
- Flag expectations that only verify non-nil, non-empty, or non-zero conditions instead of real values.
- In page-oriented tests, encourage assertions beyond simple page content when deeper validation is possible.

### Developer Scripts And Docker

- `bin/*` and `setup.sh` should be idempotent and safe for repeated local use.
- `Dockerfile` changes should minimize layers, avoid unnecessary packages, and avoid leaving unsafe defaults behind.

## How The `.coderabbit.yaml` Is Structured

### Review Behavior

- The profile is set to `chill` to reduce noise.
- `request_changes_workflow` is disabled so CodeRabbit does not block PRs on day one.
- Review details are enabled during rollout so reviewers can see ignored files and review context.
- Walkthroughs stay expanded to make the review easier to scan.
- Poems and fortune messages are disabled because this repository benefits more from direct signal than personality in review comments.

### Auto Review

- CodeRabbit reviews PRs automatically.
- It skips drafts.
- It re-reviews new commits incrementally.
- It pauses after a few reviewed commits so a very active PR does not get spammy.

### Labels

- The config narrows label suggestions to a repository-specific set:
  - `api`
  - `database`
  - `workflow`
  - `security`
  - `tests`

### Path Instructions

The config teaches CodeRabbit that different parts of the repository need different review criteria. This is more useful than a single broad Rails instruction because this codebase has clear subsystems:

- `app/controllers/**/*.rb`
- `app/models/**/*.rb`
- `app/serializers/**/*.rb`
- `app/mailers/**/*.rb`
- `config/routes.rb`
- `db/migrate/**/*.rb`
- `db/schema.rb`
- `spec/models/**/*.rb`
- `spec/requests/**/*.rb`
- `swagger/**/*.yml`
- `.github/workflows/**/*.{yml,yaml}`
- `Dangerfile`
- `Dockerfile`
- `bin/*`

### Pre-Merge Checks

These checks are configured as warnings first. They are meant to preserve policy signal from the current Danger setup without creating accidental merge blockers.

- `schema-without-migration`
- `behavior-change-needs-tests`
- `workflow-security`
- `config-and-setup-scrutiny`
- `todo-temp-debug-artifacts`
- `legacy-pr-scope-and-title`
- `legacy-config-file-guardrails`
- `legacy-rspec-hygiene`
- `legacy-global-debug-code`

These checks should only move from `warning` to `error` after the team is happy with the signal quality.

### Tool Integrations

The config enables tooling that fits this repository:

- `github-checks` for reading CI outcomes and logs
- `rubocop` for Ruby style and common issues
- `brakeman` for Rails security review
- `actionlint` for workflow validation
- `gitleaks` for secrets scanning
- `hadolint` for Dockerfile review
- `shellcheck` for shell script review
- `markdownlint` for Markdown consistency
- `yamllint` for YAML sanity

If the current CodeRabbit plan does not include tool integrations, the YAML can stay in place and those tools can be treated as future-ready configuration.

### Knowledge Base

- Web search is disabled so reviews stay grounded in repository context.
- Learnings, issues, and past PR context are scoped to `local` so this repository does not inherit unrelated preferences from other repositories.
- This file is explicitly included as a CodeRabbit guideline document through `knowledge_base.code_guidelines.filePatterns`.

## Relationship To The Current Workflows

### Keep

- `.github/workflows/main.yml`
- `.github/workflows/TestPR.yml`
- `.github/workflows/lint.yml`

These are execution workflows and should remain the source of truth for running tests, linting, coverage, and build logic.

### Keep For Comparison During Rollout

- `Dangerfile`
- `.github/workflows/danger.yml`
- `.github/workflows/danger_target.yml`

Keep them temporarily while comparing CodeRabbit output against current customized review behavior.

### Possible Future Cleanup

Once CodeRabbit proves it is consistently covering the intended review policy, the repository can decide whether parts of the Danger setup are redundant. That should happen only after side-by-side comparison on real PRs.

## Rollout Plan

1. Commit `.coderabbit.yaml` and this document on a feature branch.
2. Open a small PR that touches one Rails file and, ideally, one spec or workflow file.
3. Confirm CodeRabbit posts an automatic review and walkthrough.
4. Compare its comments with Danger and CI output.
5. Tune noisy path instructions or checks before expanding enforcement.
6. Only after a few successful PRs, decide whether any Danger logic should be retired.

## Practical Commands

Common PR comment commands reviewers can use:

- `@coderabbitai review`
- `@coderabbitai summary`
- `@coderabbitai resolve`

Use comment chat to teach preferences gradually. If CodeRabbit learns something that should become a permanent repository rule, move it into this document or `.coderabbit.yaml`.
