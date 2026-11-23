# CodeRabbit Setup For This Repository

This repository uses CodeRabbit as an AI pull request reviewer for the Expertiza backend reimplementation. The goal is to improve review quality and preserve project-specific policy without replacing the existing CI runners.

## What CodeRabbit Should Do Here

- Review pull requests automatically and re-review on new commits.
- Leave useful inline comments on Rails, API, database, workflow, and test changes.
- Summarize the impact of a pull request clearly for human reviewers.
- Focus on contextual code review, including correctness, security, maintainability, performance, and test effectiveness.
- Avoid repeating deterministic PR policy checks already performed by Danger or GitHub Actions.
- Read GitHub check results and use them as context when tests or workflows fail.

## What CodeRabbit Should Not Replace Here

- GitHub Actions still runs the real work.
- `main.yml` executes the full RSpec suite, database setup, coverage reporting, and Docker-related jobs.
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
- Schema changes should usually have corresponding model and test updates.

### Tests

- Prefer meaningful request and model specs over shallow examples.
- Check authentication, authorization, invalid input, and failure paths.
- Flag behavior changes in `app/` or `config/routes.rb` that are not reflected in `spec/models` or `spec/requests`.
- Evaluate whether tests meaningfully verify the intended behavior.
- Review important edge cases, failure scenarios, and assertion quality.
- Check that tests remain aligned with application changes.
- Leave mechanical RSpec policy checks to Danger.

### Workflows And Bot Files

- Treat workflow changes as security-sensitive.
- Flag `pull_request_target` combined with checkout of PR-head code, broad write permissions, unsafe token handling, brittle artifact passing, and comment spam patterns.
- If a Danger rule is removed, the replacement enforcement path must be explicit.

## Responsibility Separation: Danger, CodeRabbit, and CI

### Danger

Danger remains responsible for deterministic PR policies, including:

- PR size and changed file count.
- WIP titles and duplicate commit messages.
- TODO/FIXME markers and debugging statements.
- Temporary files and sensitive configuration changes.
- Mechanical RSpec checks, such as skipped or focused tests,
  deprecated syntax, and basic assertion patterns.
- Schema changes without corresponding migrations.

Danger intentionally runs on pull requests created from
branches within the main repository.

### CodeRabbit

CodeRabbit focuses on contextual code review, including:

- Application correctness and maintainability.
- Authentication, authorization, and security vulnerabilities.
- Database integrity, migration safety, and query efficiency.
- Test effectiveness and meaningful assertion coverage.
- API compatibility and Swagger documentation consistency.
- GitHub Actions security and deployment risks.
- Dockerfile security, image efficiency, and dependency management.
- Setup-script safety, idempotence, and environment compatibility.

CodeRabbit should avoid duplicating mechanical warnings
already reported by Danger or other CI tools.

For fork-origin pull requests, Danger does not execute. CodeRabbit therefore retains a targeted debug-code warning for these PRs. This check is not applicable to same-repository PRs, where Danger already provides coverage.

### GitHub Actions

GitHub Actions remains responsible for running RSpec,
RuboCop, spellchecking, coverage reporting, and other CI checks.

CodeRabbit provides supplementary review feedback and must
not be required for core CI validation.

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
- It pauses after a few reviewed commits to avoid excessive review activity.

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

The following contextual pre-merge checks remain configured
as warnings:

- `behavior-change-needs-tests`: Reviews whether behavior changes
  are meaningfully tested.
- `workflow-security`: Identifies security risks in GitHub Actions.
- `config-and-setup-scrutiny`: Reviews configuration changes for
  security, compatibility, and unintended behavior.
- `fork-pr-debug-code`: This is the sole deliberate exception to
  avoiding duplicate mechanical checks.

Mechanical PR policy checks remain with Danger to prevent
duplicated automated feedback.

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
- `.github/workflows/lint.yml`

These are execution workflows and should remain the source of truth for running tests, linting, coverage, and build logic.

### Danger

The existing Dangerfile and Danger workflow will be retained.

Danger enforces deterministic PR policies, while CodeRabbit
provides contextual review and analysis.

The two tools serve complementary purposes rather than
replacing one another.

### Validation

To evaluate this separation:

1. Compare Danger and CodeRabbit feedback on representative PRs.
2. Check whether duplicate warnings have been reduced.
3. Verify that Danger continues to run for same-repository PRs.
4. Confirm that CodeRabbit reviews focus on application behavior,
   test quality, security, and maintainability.
5. Monitor CodeRabbit review availability and rate limits.

### Possible Future Cleanup

Future cleanup should focus on reducing duplicate feedback,
improving the accuracy of existing checks, and removing obsolete
configuration.

Danger will remain responsible for deterministic PR policies,
while CodeRabbit will provide contextual analysis.

## Rollout Plan

1. Commit `.coderabbit.yaml` and this document on a feature branch.
2. Open a PR for the CodeRabbit and Danger overlap cleanup.
3. Validate the CodeRabbit configuration and verify that existing Danger checks remain unchanged.
4. Compare Danger, CodeRabbit, and CI feedback on representative PRs.
5. Confirm that CodeRabbit focuses on correctness, security, maintainability, and meaningful test coverage.
6. Monitor CodeRabbit rate limits while retaining automatic incremental reviews.
7. Refine noisy instructions without weakening deterministic PR checks.

## Practical Commands

Common PR comment commands reviewers can use:

- `@coderabbitai review`
- `@coderabbitai summary`
- `@coderabbitai resolve`

Use comment chat to teach preferences gradually. If CodeRabbit learns something that should become a permanent repository rule, move it into this document or `.coderabbit.yaml`.
