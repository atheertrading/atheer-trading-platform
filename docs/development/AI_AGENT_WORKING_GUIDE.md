# AI Agent Working Guide

## Mandatory read order
1. `AGENTS.md`
2. `docs/engineering/PROJECT_CONTINUITY.md`
3. `docs/engineering/CONVERSATION_INDEX.md` and `CONVERSATION_RECOVERY_PROTOCOL.md`
4. `docs/engineering/IMPLEMENTATION_STATUS.md`
5. `docs/engineering/TASK_REGISTER.md`
6. `docs/engineering/MASTER_DOCUMENT_REGISTRY.md`
7. `docs/engineering/SOURCE_RECONCILIATION_REGISTER.md`
8. Relevant approved Library specification, including exact document ID, revision, and approval status
9. `docs/architecture/AI_AGENT_NAVIGATION.md`
10. `docs/development/ATHEER_CHATGPT_ENGINEERING_CONTINUATION.md`
11. Relevant source code, tests, Git history, and open PRs

Do not assume a document is approved merely because it appears in a registry. Record inaccessible sources rather than inventing their contents. The ChatGPT continuation directive supplements this guide; it does not override `AGENTS.md`, owner approvals, or approved specifications.

## Before editing
Establish outcome, bounded context, acceptance criteria, and non-goals. Inspect the current default branch, working branch, working tree, recent commits, open PRs, exact head SHAs, checks, and implementation. Identify authoritative requirements and conflicts. Search for existing types and tests before creating new ones. Preserve uncommitted and untracked user work.

## ChatGPT continuation and session discipline
Use the reusable prompt in `docs/development/ATHEER_CHATGPT_ENGINEERING_CONTINUATION.md` when opening or resuming a substantial ChatGPT engineering session. Revalidate its historical checkpoints against live GitHub and local evidence; never assume a prior prompt's branch, PR, task, or CI state remains current.

At session start, recover the earliest eligible task from the existing sequential task register. Do not create a parallel queue. At handover, record sources inspected, exact repository/branch/commit, decisions and conflicts, files changed, commands and results, blockers, and the next eligible action. Distinguish verified facts from owner-confirmed reports and proposals.

## Local Mac and Terminal requirements
When a task requires the owner's Mac, Xcode, local runtime, screenshots, or local tests, provide complete ready-to-run Terminal commands. Each command group must identify:
- Exact working directory and purpose.
- Whether it inspects, modifies, builds, tests, or synchronizes.
- Expected output or evidence and follow-up verification.
- Any local prerequisites.

Before mutation, inspect `pwd`, branch, and `git status --short --branch`. Preserve local modifications and untracked files. Do not use destructive reset, clean, force-push, or overwrite operations without explicit authorization. Do not claim local commands ran unless the owner executed them and supplied results.

Use GitHub integration for remote repository operations it supports. Use Terminal for local-only operations. Never imply direct access to the user's Mac.

## Engineering standards
Use OOP, SOLID, dependency inversion, DI, encapsulation, cohesion, and separation of concerns. Keep UI, application orchestration, domain policy, infrastructure adapters, and persistence separate. Avoid speculative frameworks, unnecessary dependencies, god objects, global mutable state, and duplicate sources of truth. Add deterministic tests for financial calculations and state transitions. Preserve verified macOS and Swift compatibility until the active toolchain is rechecked.

## Trading and AI safety
Never invent market data, fills, positions, balances, or broker responses. Never connect CI or tests to a LIVE account. Agents may create typed order intents only within declared permissions. No agent or strategy calls broker dealing APIs directly. All financial effects pass through deterministic authorization, RiskEngine, OMS, and Execution Gateway. Trading remains disabled by default. Explicit approval boundaries in `AGENTS.md` remain mandatory.

## Git and commit discipline
Use focused branches, cohesive commits, and specific conventional commit messages. Review the complete diff and dependency ancestry. Never rewrite shared history or overwrite user work. A mergeable flag alone is not merge approval. Revalidate exact-head CI and review state immediately before merge. Record commit SHAs and PR URLs only after GitHub confirms them.

## Completion report
Report changed files, architecture/source references, exact build and test commands/results, failures, unverified areas, security/trading impact, continuity updates, commit/PR links, and next action. Never claim tests, commits, pushes, merges, or production readiness without evidence.
