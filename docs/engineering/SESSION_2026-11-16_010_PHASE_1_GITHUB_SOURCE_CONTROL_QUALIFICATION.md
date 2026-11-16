# ATHEER Trading — Phase 1 GitHub and Source-Control Qualification

**Assessment date:** 2026-11-16  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `docs/phase-1-github-source-control-qualification`  
**Base commit:** `70794e7f20f129c17ba64bcf4b1eba0df32999df`  
**Status:** IN PROGRESS — repository identity and hosted CI verified; enforcement and local workstation source-control setup remain incomplete.

## 1. Phase boundary and interpretation

This report follows Phase 1 of the **Chief Engineering, macOS Development & Local Environment Setup Mandate**.

The mandate's Phase 0 is local environment discovery and technical assessment. Its first bounded local qualification task is recorded as completed in the Codex local environment assessment: repository cloned, XcodeGen 2.36.1 generated the Xcode project, doctor passed, Debug and Release builds passed, XCTest passed (1/1), and the app process launched. The owner additionally confirms that the current GitHub application has been tested and is working on the iMac.

This does not complete the separate Phase 0 of the Codex documentation-transformation/source-reconciliation workstream. That inventory explicitly leaves the formal 47-document archive, full semantic review of the Q&A archive, approvals, lineage, and conflicts incomplete. Those documentation activities remain parallel evidence dependencies and must not be misreported as complete.

## 2. Repository identity and permissions

| Check | Result | Evidence |
|---|---|---|
| Repository | VERIFIED | `atheertrading/atheer-trading-platform` |
| Repository ID | VERIFIED | `1459589616` |
| Owner | VERIFIED | `atheertrading` |
| Visibility | VERIFIED | Public |
| Archived | VERIFIED | False |
| Default branch | VERIFIED | `main` |
| Integration permissions | VERIFIED | Admin, maintain, push, pull, triage all true |
| Main HEAD | VERIFIED | `70794e7f20f129c17ba64bcf4b1eba0df32999df` |
| Commit history | VERIFIED | Four commits returned by the inspected history endpoint |
| Clone URL | VERIFIED | HTTPS: `https://github.com/atheertrading/atheer-trading-platform.git` |

No duplicate repository was created. The repository remains the canonical engineering monorepo under the recorded EDL-004 topology decision.

## 3. Branches, history, tags, and local synchronization

The GitHub branch listing returned these branches:

- `main`
- `build/platform-foundation`
- `docs/architecture-diagram-baseline`
- `engineering/bootstrap-governance`
- Three Dependabot branches for Actions updates

Every branch in the returned branch listing reported `protected=false`.

The latest `main` commit is `70794e7f20f129c17ba64bcf4b1eba0df32999df`. The Codex local environment report records the local clone at the same commit before its local documentation branch was created.

The local workstation report records the following subsequent state:

- Local branch: `chore/local-environment-qualification`.
- Local HEAD remains the same commit as `origin/main`.
- Four tracked continuity documents have uncommitted modifications.
- One new session report is untracked.
- No commit or push was made.
- Global Git author identity was not configured.

Those local changes are owner work and must be preserved. Do not reset, clean, stash, switch branches, or synchronize over them without first reviewing and preserving their contents.

A tag-reference query did not return a usable tag listing. Tag inventory is therefore **UNVERIFIED**, not assumed empty.

## 4. Hosted CI and repository automation

The current `main` commit has successful hosted runs:

| Workflow | Result | Run |
|---|---|---|
| CI | SUCCESS | [43859015049](https://github.com/atheertrading/atheer-trading-platform/actions/runs/43859015049) |
| CodeQL | SUCCESS | [43859014948](https://github.com/atheertrading/atheer-trading-platform/actions/runs/43859014948) |
| Mermaid architecture diagrams | SUCCESS | [43859015633](https://github.com/atheertrading/atheer-trading-platform/actions/runs/43859015633) |

The CI workflow currently provides repository hygiene/Markdown lint, macOS build and XCTest on `macos-15-intel`, Swift CodeQL in the macOS job, and a Node.js 24 backend-toolchain check. The CodeQL workflow analyzes GitHub Actions. Mermaid sources are rendered by a separate workflow.

The repository uses:

- `.nvmrc` set to Node.js major 24.
- `.gitignore` rules excluding environment files, credentials, signing materials, local databases, generated Xcode project output, build products, and runtime artifacts.
- `.github/CODEOWNERS` assigning all paths to `@atheertrading`.
- Weekly Dependabot updates for GitHub Actions and npm.
- A PR template requiring source/ADR references, safety checks, and verification evidence.
- Workflow-level least-privilege permissions in the inspected CI definitions.

Open Dependabot PRs at inspection:

- [#3 actions/setup-node 4 → 7](https://github.com/atheertrading/atheer-trading-platform/pull/3): reported checks passed; major version change requires compatibility review.
- [#4 markdownlint-cli2 action 19 → 25](https://github.com/atheertrading/atheer-trading-platform/pull/4): CI failed on MD060 compact-table spacing in `DEVELOPER_SETUP.md` and `AI_AGENT_NAVIGATION.md`; do not merge until corrected and rerun.
- [#5 actions/checkout 4 → 7](https://github.com/atheertrading/atheer-trading-platform/pull/5): reported checks passed; major version change requires compatibility review.

The three open PRs are not proof of changes already merged to `main`. Do not adopt their dependency updates without reviewing the PR diff and compatibility.

## 5. Repository governance and security findings

### Verified

- The repository's configuration guide defines a main-branch ruleset requiring PR review, named CI checks, conversation resolution, blocking force pushes, and blocking branch deletion.
- The configuration guide calls for read-only default Actions token permissions and explicit workflow permissions.
- The checked-in workflows inspected use explicit least-privilege permissions.
- Secret-bearing files and local runtime artifacts are excluded by `.gitignore`.
- The PR template explicitly checks that DEMO/SIMULATION/BACKTEST/LIVE boundaries and centralized execution governance are preserved.

### Not configured or not verified

- The branch listing reports `protected=false` for `main` and all other returned branches.
- The repository rulesets endpoint returned an empty list.
- The detailed branch-protection endpoint returned HTTP 403 to the connected integration. This is an integration access limitation, not evidence that the endpoint itself is disabled.
- GitHub Actions repository-level default token permissions could not be inspected through the available connector.
- Secret scanning, push protection, Dependabot alerts/security updates, and private vulnerability reporting settings were not independently verified.
- No tag inventory was established.

**Disposition:** Main-branch protection is a P0 governance gap. Configure an active ruleset in GitHub Settings → Rules → Rulesets, targeting `main`, with the controls specified in `docs/development/GITHUB_REPOSITORY_CONFIGURATION.md`. Require the exact CI checks only after confirming their names and successful PR execution. Do not require a second reviewer while the repository has one owner; preserve administrator recovery access.

## 6. Local GitHub authentication and author identity

The local workstation report records:

- GitHub CLI `gh` is not installed.
- Global Git author identity is unset.
- The local clone uses HTTPS.
- The connected ChatGPT GitHub integration has admin permission.

The GitHub integration's permission does not prove that local Git HTTPS credentials are configured or that local push authentication works. Absence of `gh` does not by itself prevent Git use through macOS Keychain or another credential helper.

Required local verification, without exposing credentials:

1. Inspect `git config --show-origin --get-regexp '^(user\\.|credential\\.|init\\.defaultBranch|pull\\.ff|push\\.)'`.
2. Run `git ls-remote origin HEAD` to verify read access.
3. After the owner confirms the intended commit author identity, set repository-local `user.name` and `user.email`; do not change global identity.
4. Verify write authentication with a non-mutating dry-run only after reviewing the local branch and intended ref. Never paste tokens or credential-helper output into chat.

The recorded historical commit author is `atheertrading <atheertradingpro@gmail.com>`; this is repository metadata, not sufficient authorization to assign the owner's local commit identity.

## 7. Phase 1 acceptance checklist

| Acceptance criterion | Status |
|---|---|
| Correct repository identity and ownership verified | PASS |
| Visibility, default branch, and integration permissions verified | PASS |
| Existing branches and main commit history inspected | PASS |
| Local clone origin and HEAD alignment inspected | PASS — local worktree remains dirty |
| GitHub integration access verified | PASS |
| Local GitHub CLI/authentication verified | BLOCKED — `gh` absent; local credential state unverified |
| Local Git author identity configured | BLOCKED — owner identity not confirmed; global identity unset |
| Branch naming and PR workflow documented | PASS |
| `.gitignore` and secret exclusions inspected | PASS |
| CI workflows and latest main checks inspected | PASS |
| Main branch protection/ruleset enforced | BLOCKED — no active ruleset returned; branch reports unprotected |
| Actions default permissions and security settings verified | BLOCKED — connector cannot inspect these settings |
| Tags inventoried | UNVERIFIED |

**Phase 1 is not complete.** At the time of this assessment, Phase 2 had not been authorized. On 2026-11-16, the owner subsequently gave explicit authorization to proceed with Phase 2 as a documented sequencing exception while these Phase 1 controls remain open. This authorization does not waive or close any Phase 1 finding.

## 8. Required owner-side actions

1. In GitHub repository Settings → Rules → Rulesets, configure and enable the main-branch ruleset described in `docs/development/GITHUB_REPOSITORY_CONFIGURATION.md`.
2. In Settings → Actions → General, verify default `GITHUB_TOKEN` permissions are read-only and review the allowed-actions policy.
3. In Settings → Code security and analysis, verify available secret scanning, push protection, Dependabot alerts/security updates, and private vulnerability reporting.
4. Confirm the intended local Git commit author name and email. Do not send credentials, tokens, private keys, or passwords.
5. On the iMac, verify the local clone's HTTPS read/write authentication without exposing credential data; preserve the dirty working tree throughout.

## 9. Verification and phase exit

This is a documentation-only qualification change. The GitHub API confirmed the base commit and branch creation. The pull request's repository hygiene, Markdown lint, macOS build/test, backend-toolchain, CodeQL, and Mermaid checks must pass before merging this report.

No source code, Xcode project, backend, database, broker connection, credentials, signing identities, or trading permissions were modified.

Phase 1 remains open pending the owner-side controls above. The owner's later explicit authorization permits Phase 2 to proceed as a sequencing exception; it does not constitute Phase 1 completion. Continue to track the owner-side actions and issue a separate Phase 1 completion handover only after the exit criteria are verified.
