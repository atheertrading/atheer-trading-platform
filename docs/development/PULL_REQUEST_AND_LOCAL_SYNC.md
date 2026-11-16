# Pull Request, Integration, and Local Synchronization Workflow

## Branch lifecycle

1. Fetch and fast-forward local main.
2. Create a short-lived branch using feat/, fix/, refactor/, docs/, test/, build/, or chore/.
3. Make a bounded change; add tests and update specifications/continuity.
4. Push the branch and open a PR against main.
5. Review the diff, source references, security/trading impact, CI, and mergeability.
6. Resolve conflicts deliberately; rerun the full affected test suite.
7. Squash merge routine engineering PRs after required checks pass and policy review is complete.
8. Delete the feature branch only after merge is confirmed and any local work is preserved.

## Conflict resolution

- Fetch both base and head; inspect the common ancestor and changed files.
- Never use force-push as a conflict-resolution shortcut.
- Preserve owner changes and user-authored local modifications.
- Resolve semantic conflicts against approved Library specifications and current main, not by blindly choosing ours/theirs.
- Re-run build, unit, integration, and static checks affected by the resolution.
- Document any behavior change and update the decision/continuity records.
- If history rewriting or destructive recovery is needed, stop and preserve a backup; it is outside routine PR handling.

## Local first clone

~bash
mkdir -p ~/Developer/ATHEER
cd ~/Developer/ATHEER
git clone https://github.com/atheertrading/atheer-trading-platform.git
cd atheer-trading-platform
git switch main
git pull --ff-only origin main
~

Do not clone into the old atheer-trading-pro directory. The new repository is a distinct Git repository; keep any older repository and uncommitted work intact until its contents and history have been inventoried.

## Update an existing local clone

~bash
cd ~/Developer/ATHEER/atheer-trading-platform
git status --short --branch
git switch main
git fetch origin --prune
git pull --ff-only origin main
git log -5 --oneline --decorate
~

If the working tree is not clean, do not discard changes. Commit or stash only after inspecting them and preserving a backup. If fast-forward fails, inspect divergence with git status and git log; do not reset --hard.

## Update a feature branch

~bash
git fetch origin
git switch feat/your-scope
git merge origin/main
~

Resolve conflicts, run affected checks, then push. Use rebase only for a private, unpublished branch when history rewrite is safe and explicitly intended.

## Build and test after synchronization

~bash
make doctor
make generate
make build
make test
~

## Merge and release policy

Routine engineering PR review, conflict resolution, and merging are delegated to the Head of Engineering. Merge only after required checks pass and the change meets source, architecture, security, and test requirements. Production deployments, credential operations, broker-account permission changes, destructive history rewriting, and LIVE dealing remain separately authorized.

A successful merge is not a release. Tagging, notarization, distribution, and deployment require their own reproducible pipeline and qualification criteria.
