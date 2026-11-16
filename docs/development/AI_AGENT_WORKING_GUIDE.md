# AI Agent Working Guide

## Mandatory read order
1. AGENTS.md
2. docs/engineering/PROJECT_CONTINUITY.md
3. docs/engineering/IMPLEMENTATION_STATUS.md
4. docs/engineering/TASK_REGISTER.md
5. docs/engineering/MASTER_DOCUMENT_REGISTRY.md
6. docs/engineering/SOURCE_RECONCILIATION_REGISTER.md
7. Relevant Library specification, including revision and approval status
8. Relevant source code, tests, Git history, and open PRs

Do not assume a document is approved merely because it appears in a registry. Record inaccessible sources rather than inventing their contents.

## Before editing
Establish outcome, bounded context, acceptance criteria, and non-goals. Inspect branch, working tree, recent commits, open PRs, and implementation. Identify authoritative requirements and conflicts. Search for existing types and tests before creating new ones.

## Engineering standards
Use OOP, SOLID, dependency inversion, DI, encapsulation, cohesion, and separation of concerns. Keep UI, application orchestration, domain policy, infrastructure adapters, and persistence separate. Avoid speculative frameworks, unnecessary dependencies, god objects, global mutable state, and duplicate sources of truth. Add deterministic tests for financial calculations and state transitions. Preserve macOS 13 / Swift 5.8 compatibility until revised.

## Trading and AI safety
Never invent market data, fills, positions, balances, or broker responses. Never connect CI or tests to a LIVE account. Agents may create typed order intents only within declared permissions. No agent or strategy calls broker dealing APIs directly. All financial effects pass through deterministic authorization, RiskEngine, OMS, and Execution Gateway. Trading remains disabled by default.

## Completion report
Report changed files, architecture/source references, exact build and test commands/results, failures, unverified areas, security/trading impact, continuity updates, and commit/PR links. Never claim tests or production readiness without evidence.
