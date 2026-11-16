# ATHEER Trading — Project Continuity

| Field | Value |
|---|---|
| Project | ATHEER Trading / ATHEER Trading Pro |
| Repository | https://github.com/atheertrading/atheer-trading-platform |
| Repository role | Canonical engineering and implementation repository; not the sole project knowledge authority |
| Default branch | `main` |
| Current work branch | `engineering/bootstrap-governance` |
| Record status | Initial baseline; further source reconciliation required |
| Last reviewed | 2026-11-16 |

## 1. Current verified state

- The public GitHub repository `atheertrading/atheer-trading-platform` exists and is accessible.
- The default branch is `main`.
- The initial commit is `505c06c88c2eaaf819b202d5b2687a9d4ee99bb9`.
- The initial repository contained a two-line README with an incomplete personal-profile description; it did not contain a root `AGENTS.md`.
- The current engineering bootstrap branch was created from `main`.
- The ChatGPT Library contains the owner-designated document **ATHEER Trading — Engineering Operating Standards**.
- The owner has confirmed that `AtheerAutotrade` has been deleted.
- The owner has established that GitHub, the ChatGPT Library, and relevant historical conversations must work together as the project knowledge system.

This record describes the inspected baseline and bootstrap activity. It does not assert that this branch has been merged or that the documents in this branch are already on `main`.

## 2. Project definition

ATHEER Trading is intended to be a professional, intelligent, extensible multi-asset trading platform. Its scope includes market data, quantitative analysis, strategies, AI agents, centralized risk, OMS, execution, broker integrations, portfolio and position management, backtesting, simulation, and a professional macOS workstation.

Capital.com is the primary planned broker integration. Swift/SwiftUI is the recorded native application direction; Node.js 24/TypeScript is the recorded backend direction. Current toolchain compatibility must be reverified.

## 3. Knowledge authority and source roles

- **Owner instructions and explicit approvals:** scope, authorization, and binding project requirements.
- **ChatGPT Library:** governing engineering standards, approved specifications, architecture knowledge, research, and historical archives.
- **GitHub:** committed source code, tests, CI, implementation evidence, and Git history.
- **Historical conversations:** decision chronology, rationale, context, and unresolved discussion.
- **This continuity system:** indexes and reconciles the above sources; it does not replace them.

Do not describe this repository as the sole source of truth for all project architecture. Do not treat conversational summaries as proof of implementation or as substitutes for approved documents.

## 4. Owner-endorsed operating direction

- Public repository visibility is intentional at the foundational stage.
- AI architecture must be extensible across model providers, hosted and local models, agent frameworks, tools, and multi-agent orchestration.
- Model flexibility must not weaken credential security, authorization, auditability, centralized risk, or execution governance.
- OOP, SOLID, dependency injection, separation of concerns, modularity, and rigorous testing are mandatory engineering standards.
- Manual, strategy, and AI-generated order intents must use the same governed risk and execution path.
- DEMO, SIMULATION, BACKTEST, and LIVE must remain distinct.
- LIVE dealing, production deployment, destructive repository actions, and credential-sensitive actions require explicit authorization.

## 5. Historical engineering context requiring reconciliation

Earlier project work included a macOS SwiftUI application foundation, workspace/design-system files, Capital.com UI planning, an engineering repository, architecture documents, and test/build investigations. Historical environment references include macOS 13.7.8, Xcode 14.3.1, and Swift 5.8.1 on an Intel iMac. These are historical facts, not current verification.

A prior repository named `AtheerTrader` was referenced in earlier engineering sessions. Its relationship to the deleted `AtheerAutotrade` repository and any surviving local work must be established from accessible evidence before migration decisions. Do not assume that the deletion of `AtheerAutotrade` deleted all project code or history.

Prior requirements include Capital.com as primary broker, broker-authoritative state, quote freshness controls, centralized RiskEngine, OMS/Execution Gateway/reconciliation, and an AI decision-intelligence layer that does not itself possess execution authority. Review the applicable Library specifications before implementation.

## 6. Active milestone

**Milestone 00 — Knowledge, governance, and source reconciliation**

Objectives:
1. Establish repository instructions, security baseline, continuity records, and source registry.
2. Reconcile Library standards, specifications, archives, ADRs, and historical conversations.
3. Inventory surviving repositories, local code, branches, commits, and implementation evidence.
4. Establish document registry, source provenance, specification conflict register, and requirements traceability.
5. Define the architecture baseline and IPDS specification status.
6. Establish CI and documentation validation appropriate to the verified toolchains.

## 7. Immediate next actions

1. Review this bootstrap pull request and verify every file on the branch.
2. Reconcile the Library's Engineering Operating Standards with existing approved governance and ADRs.
3. Inspect the available Library archives and build a source/document inventory without altering original archives.
4. Retrieve and inspect historical repository records and surviving code; record inaccessible sources explicitly.
5. Create the Master Document Registry, Source Provenance Register, Specification Conflict Register, and Requirements Traceability Matrix.
6. Establish the architecture baseline only after source reconciliation.
7. Define IPDS v1.0 primitives, semantic tokens, component contracts, theme mappings, and accessibility validation.
8. Establish CI and security automation after toolchain and branch settings are verified.

## 8. Session handover protocol

For every substantial engineering session, update:
- `CONVERSATION_INDEX.md` with the session ID and chronological entry.
- `ENGINEERING_DECISION_LOG.md` for new decisions or changed statuses.
- `TASK_REGISTER.md` for task state, blockers, and dependencies.
- `IMPLEMENTATION_STATUS.md` only when supported by direct evidence.
- This file with the verified current state and the next concrete action.

Each session entry must include date, objective, previous session reference, sources inspected, decisions, files/modules affected, implementation actions, test/verification evidence, unresolved issues, and next action.

Never invent missing conversation transcripts. If a historical transcript cannot be retrieved, record the available summary and mark the source as a summary rather than a complete transcript.
