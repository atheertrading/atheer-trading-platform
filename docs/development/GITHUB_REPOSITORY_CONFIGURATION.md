# GitHub Repository Configuration

**Status:** Configuration specification; settings must be verified in GitHub after application.

## Repository baseline

- Repository: atheertrading/atheer-trading-platform
- Visibility: public
- Default branch: main
- Merge strategy: squash preferred for routine engineering PRs
- Workflow permissions: read-only by default; grant write permissions only to a workflow that requires them
- All issues, PRs, commits, workflow logs, and artifacts must be treated as public.

## Actions

In Settings → Actions → General:

1. Enable GitHub Actions for the repository.
2. Permit only the actions required by the checked-in workflows and trusted dependencies.
3. Set default GITHUB_TOKEN permissions to read repository contents.
4. Require explicit permissions blocks for workflows that need elevated scopes.
5. Do not expose secrets to pull requests from forks or untrusted code.
6. Do not add Capital.com credentials or any live broker secrets to repository or CI secrets.

The CI workflow defines these jobs:
- Repository hygiene
- macOS build, tests, and Swift CodeQL
- Backend toolchain

CodeQL runs separately through the CodeQL workflow. Confirm workflow runs appear for PR #2 before making the checks required.

## Main branch ruleset

In Settings → Rules → Rulesets, create an active branch ruleset targeting the main branch:

- Require a pull request before merging.
- Require the Repository hygiene, macOS build and tests, and Backend toolchain checks after their first successful run.
- Require conversation resolution.
- Block force pushes.
- Block branch deletion.
- Do not require a second reviewer when the repository has only one owner; retain administrator access for recovery and emergency governance.
- Permit squash merging. Disable merge commits if a linear main history is the chosen repository policy.
- Do not permit direct pushes to main for routine engineering work.

The GitHub connector previously could not read branch protection (HTTP 403), and no rulesets were returned at that inspection. This is an access limitation, not proof that protection is absent. Verify the settings in the repository UI and record the ruleset identifier and date.

## Security

In Settings → Code security and analysis, enable where available:

- Dependency graph.
- Dependabot alerts.
- Dependabot security updates.
- Secret scanning.
- Push protection for detected secrets.
- Private vulnerability reporting.

Availability depends on repository/plan eligibility. Do not claim a control is active until GitHub confirms it is enabled.

The checked-in CodeQL workflow is a configuration artifact; its successful execution must be verified from Actions/Security before reporting coverage.

## Merge and cleanup

- Review the complete diff and required checks before merge.
- Use squash merge for focused feature PRs.
- Delete merged feature branches only after merge confirmation.
- Keep main protected from force-push and deletion.
- Do not configure automatic deployment or LIVE broker access in CI.
