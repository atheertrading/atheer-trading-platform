# ATHEER Trading — Non-Destructive Local Synchronization

## Target workstation repository

Default path: `$HOME/Developer/AtheerTradingPlatform`.

The repository must have the expected `origin` URL for `atheertrading/atheer-trading-platform`. The procedure updates the local `main` branch only. It does not rebase or merge a feature branch automatically.

## Commands

From the repository root:

```bash
make doctor
make sync
```

To run the complete workstation bootstrap after reviewing local branch state:

```bash
make bootstrap
```

`make bootstrap` proceeds with XcodeGen and backend dependency setup only when the current branch is `main`. If the original branch is a feature branch, safe synchronization updates `main`, restores the original branch and its local work, then stops. Review and preserve the feature work before switching to `main` and rerunning bootstrap.

## Preservation and synchronization sequence

When the worktree contains staged changes, unstaged changes, or non-ignored untracked files, `scripts/safe-sync.sh`:

1. Records the current branch and HEAD.
2. Creates a private external backup under `$HOME/Developer/AtheerTradingPlatform-backups/` (or `ATHEER_SYNC_BACKUP_ROOT` when explicitly overridden).
3. Saves staged and unstaged binary patches and a status record.
4. Copies non-ignored untracked files while preserving their relative paths.
5. Creates a local `backup/pre-sync-*` branch at the original HEAD.
6. Creates a Git stash with `--include-untracked`.
7. Fetches `origin`, switches to `main`, and uses `git merge --ff-only origin/main`.
8. Restores the original branch and reapplies the stash with `--index`.
9. Retains the stash, backup branch, and external backup for inspection.

If the fast-forward or stash restoration cannot complete safely, the script stops. It does not discard the stash or external backup. Resolve the issue manually before retrying.

## Explicit safety properties

- No `git reset --hard`.
- No `git clean`.
- No force-push.
- No `git stash pop` or automatic stash deletion.
- No automatic rebase or merge of feature branches.
- No deletion of local branches.
- No deployment, database migration, signing identity change, broker operation, or LIVE trading operation.

Ignored files are not copied into the external backup. Review important ignored local configuration separately before synchronization. The backup directory is local to the workstation and is not committed or pushed.

## Development workflow after synchronization

- `make doctor` — read-only prerequisite and repository-state diagnostic.
- `make backend-setup` — install the locked API development dependency set.
- `make backend-check` — typecheck and test the backend API.
- `make backend-start` — run the loopback-only API in the foreground; use Ctrl-C to stop it.
- `make generate` — generate the Xcode project from `project.yml`.
- `make build` — build the macOS app without changing signing identities.
- `make test` — run the macOS XCTest suite.
- `make app-run` — build and request launch of the local app.
- `make clean` — remove local build artifacts only; it does not delete the generated Xcode project or source files.

The backend binds to `127.0.0.1:4100`. Its readiness response remains not ready and trading remains disabled until persistence and broker adapters are independently implemented and qualified.

## Verification boundary

The safe-sync script is tested against temporary local Git repositories, including staged changes, unstaged changes, untracked files, external backups, retained stashes, clean-worktree fast-forward, origin-identity rejection, and refusal of divergent main history. This does not prove synchronization on the owner's Mac. Actual local repository identity, worktree state, Xcode, XcodeGen, Node.js, and build/test results must be obtained by running the diagnostic and workflow on the Mac.
