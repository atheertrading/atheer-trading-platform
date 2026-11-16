# Engineering Session ATP-2026-11-16-014 — Non-Destructive Local Synchronization

**Date:** 2026-11-16  
**Branch:** feat/dev/safe-local-sync  
**Base main:** e2546a783a565bf123dd7ae389518a8f27494fe5  
**Related work:** PR #9 backend health service; PR #10 macOS health integration; local workstation mandate

## Objective

Prepare a safe local synchronization and workstation bootstrap workflow for the owner's Mac. The procedure must preserve existing staged, unstaged, and untracked work before updating local main.

## Implementation

- Added scripts/safe-sync.sh with strict repository-origin validation and a fast-forward-only main synchronization sequence.
- Before synchronization, the script records the original branch and HEAD, writes staged/unstaged patches and status metadata to a private external backup, copies non-ignored untracked files, creates a local backup branch, and creates a retained stash with --include-untracked.
- The script fetches origin, updates only local main using git merge --ff-only origin/main, restores the original branch, and reapplies the stash with --index.
- The stash, backup branch, and external backup are intentionally retained. Conflicts stop the procedure without dropping preservation data.
- The script rejects an unexpected origin, detached HEAD, and divergent main history. It does not reset, clean, force-push, delete branches, or automatically merge feature branches.
- Corrected the default local repository path to $HOME/Developer/AtheerTradingPlatform.
- Updated bootstrap to stop rather than silently build from a restored non-main feature branch.
- Expanded the read-only workstation doctor for Git identity/state, Xcode, Swift, XcodeGen, Node.js 24, npm, optional GitHub CLI authentication, and optional PostgreSQL/Docker status.
- Standardized local Xcode DerivedData under .build/DerivedData; added an app-run helper and Makefile targets for sync, bootstrap, backend setup/check/start, app run, and safe-sync tests.
- Changed make clean to remove build artifacts only; it no longer deletes the generated Xcode project.

## Verification performed in the isolated Linux container

- bash -n passed for all modified/new shell scripts.
- make -n help and make -n safe-sync-test passed.
- scripts/tests/test-safe-sync.sh passed against temporary local Git repositories.
- The test verifies staged and unstaged changes, untracked files, backup branch identity, external backup contents, retained stash, clean-worktree fast-forward, origin mismatch rejection, and refusal of divergent main history.
- The test does not operate on the owner's repository or workstation.

## Acceptance status

**IN PROGRESS.** Hosted repository CI must run the script test and lint checks. The owner's Mac still requires actual repository-state inspection, safe synchronization, prerequisite diagnostics, Xcode project generation, build, XCTest, and application launch.

## Protected boundaries

No local user files were accessed or modified. No GitHub credentials, Apple signing identities, database credentials, broker credentials, production resources, or trading accounts were touched. The script does not install PostgreSQL or Docker and does not enable trading.

## Next actions

1. Integrate the safe-sync test into repository CI after the workflow action-update PRs are merged.
2. Merge this PR only after its relevant CI checks pass.
3. Reconcile the current Mac worktree and run the safe-sync procedure only when authorized local computer access is available.
4. Run make doctor, make bootstrap, make backend-check, make build, make test, start the local API, and verify app launch on the actual Mac.
