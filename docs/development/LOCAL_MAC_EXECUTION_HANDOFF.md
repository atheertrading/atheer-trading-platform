# Local Mac Execution Handoff

**Status:** Owner-directed operating procedure  
**Applies to:** ChatGPT-assisted engineering tasks that require the owner's local Mac, Terminal, Xcode, simulator/runtime, or local filesystem  
**Authority:** Owner instruction; supplements the root `AGENTS.md`, the Continuous Engineering Operating Directive (CEOD), and the approved local developer workflow.

## 1. Core rule

When a task requires execution on the owner's Mac, provide the owner with complete, ready-to-run Terminal commands. Do not imply that GitHub access or a hosted CI runner can inspect or operate the local Mac.

Use GitHub integration for repository operations that can be completed remotely. Use owner-executed Terminal commands for work that depends on the local checkout, installed toolchain, local files, Xcode, application launch, connected displays, or runtime behavior.

## 2. Owner-provided macOS source path

The owner supplied the following working source directory:

```text
/Users/enghossamalfahad/Developer/AtheerTradingPlatform/apps/macos/ATHEERTradingPro/Sources
```

Treat this as the default owner-provided application source path for local macOS instructions. It is a source directory, not necessarily the Git repository root or Xcode project root. Verify its current existence and derive the repository root before running Git commands. Do not silently substitute another checkout or the historical `atheer-trading-pro` repository.

The path is owner-provided context, not proof that the directory is currently mounted, unchanged, or clean. Verify those facts through commands run by the owner.

## 3. Command delivery requirements

Every local execution handoff must:

1. State the purpose and expected result of the command group.
2. Use the exact verified/owner-provided path and quote paths containing spaces.
3. Start with read-only preflight checks where repository state matters (`pwd`, path existence, `git status`, current branch, repository root, and relevant tool versions).
4. Separate inspection, modification, build/test, and runtime steps. Do not combine a destructive or broad operation with routine diagnostics.
5. Explain which output the owner should return before the next dependent step.
6. Prefer reproducible repository scripts and documented `make` targets over invented command sequences.
7. Never put credentials, API keys, tokens, signing secrets, or private account data in command arguments or requested output.
8. Never use `reset --hard`, `clean -fd`, force-push, recursive deletion, overwrite, or destructive synchronization as a convenience. Such actions require the applicable explicit owner approval.
9. Preserve uncommitted changes. Inspect them before any checkout, pull, rebase, merge, generation, or file replacement that could affect them.
10. Distinguish a command that is proposed from one the owner has actually executed; report results only after receiving output or other direct evidence.

Commands should be copy/paste-ready, bounded, and grouped into small stages with a verification checkpoint between stages. Do not ask the owner to improvise missing paths, flags, or command syntax.

## 4. Local repository and source verification

Before any local code change or synchronization:

- Confirm the supplied source directory exists.
- Resolve the Git top-level directory with Git; do not assume the source directory itself is the repository root.
- Record the active branch and `git status --short --branch`.
- Identify staged, unstaged, and untracked user work.
- Inspect the relevant project specification, Xcode project/workspace, schemes, scripts, and applicable `AGENTS.md` files.
- Confirm the intended remote, branch, and commit before fetching or integrating changes.
- Stop and report if the path resolves to an unexpected repository, the worktree is dirty in a way that could be affected, or the target branch/commit is ambiguous.

Do not copy files from GitHub into the local source tree manually when a safe Git-based integration is appropriate. Do not assume a successful hosted build proves local Xcode compatibility or runtime correctness.

## 5. Build, test, and runtime evidence

For local macOS work, choose commands from the repository's current scripts and project configuration. Record:

- Exact repository commit and branch.
- macOS, Xcode, Swift, and XcodeGen versions when relevant.
- Exact command executed.
- Exit status and meaningful test/build summary.
- Whether the application was launched and what was actually observed.
- Any limitations, skipped tests, warnings, or owner-confirmed-only evidence.

Keep these evidence classes separate:

- GitHub Actions / hosted CI.
- Local project generation and compilation.
- Local XCTest/unit/integration tests.
- Application launch and runtime behavior.
- Visual QA, accessibility, multi-window, and multi-display testing.

A two-screen test reported by the owner is owner-confirmed unless logs, screenshots, or a reproducible local session independently establish it. Never assign an unverified commit SHA to a local runtime test.

## 6. Handoff protocol

For each local stage:

1. Provide the commands and state what they inspect or change.
2. Wait for the owner to execute them and return the output when the next action depends on the result.
3. Analyze the actual output and select the next bounded command group.
4. If a command fails, diagnose from its output before proposing corrective changes.
5. After completion, update the relevant GitHub task/continuity record with the exact evidence and classify it as owner-reported or independently verified.

This procedure does not grant permission for LIVE trading, broker credential access, signing-identity access, production deployment, risk-policy changes, or destructive repository operations. Existing approval gates remain in force.
