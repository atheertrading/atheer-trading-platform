# ATHEER Trading — Repository Engineering Instructions

## Mission

Develop ATHEER Trading as a professional, intelligent, extensible multi-asset trading platform. The intended system combines real-time market data, quantitative research, strategy execution, centralized risk management, order and position management, broker connectivity, AI-assisted decision intelligence, and a professional macOS workstation.

This repository is the canonical engineering and implementation workspace. It is **not the sole authority for all project knowledge or architecture**. The project operates through coordinated GitHub, ChatGPT Library, and historical conversation sources.

## Mandatory operating principles

1. Inspect this file, the current continuity record, task register, implementation status, relevant specifications, and applicable ADRs before substantial work.
2. Inspect the actual source tree and current Git history. Never infer implementation from documentation alone.
3. Preserve existing user work and Git history. Do not force-push, delete, rewrite, or destructively synchronize without explicit owner authorization.
4. Distinguish owner-approved requirements, accepted decisions, proposals, assumptions, historical statements, implementation, and verified behavior.
5. Never claim code is implemented, tested, integrated, secure, production-ready, or broker-verified without corresponding evidence.
6. Apply OOP, SOLID, dependency inversion, dependency injection, encapsulation, cohesion, low coupling, and separation of concerns. Prefer composition and idiomatic language features; do not create abstractions without a concrete responsibility.
7. Define module ownership, public contracts, dependency direction, failure behavior, and tests before expanding module boundaries.
8. Use authentic, timestamped, validated broker data for broker-derived facts. Never fabricate quotes, account values, positions, fills, or execution status.
9. Manual, strategy-generated, and AI-proposed order intents must converge on the same governed order-intake and risk-authorization path.
10. No strategy, agent, UI, or service may bypass the centralized RiskEngine or Execution Gateway.
11. Keep DEMO, SIMULATION, BACKTEST, and LIVE semantically and operationally distinct.
12. LIVE dealing, production deployment, destructive repository actions, credential access, and other consequential operations require explicit owner authorization.
13. Protect credentials and personal/account data. Never commit secrets, API keys, tokens, certificates, private keys, account identifiers, or real customer data.
14. Write deterministic tests for financial calculations, risk policies, state transitions, and order lifecycle behavior.
15. Document material decisions and update continuity records when work changes project state.

## Knowledge and authority model

- **Project owner instructions and explicit approvals** govern scope and authorization.
- **ChatGPT Library** is the designated documentation and knowledge workspace for governing standards, specifications, architecture records, research, historical archives, and approved documentation.
- **This GitHub repository** is authoritative for committed source code, build configuration, tests, CI, branches, commits, and repository implementation history.
- **Historical ChatGPT conversations** are a source of context, rationale, and chronology; they are not a substitute for durable approved specifications or verified repository state.
- **Continuity records** link these sources and identify the latest verified state. They must never imply that inaccessible conversations or uninspected files were reviewed.

When sources conflict, record the conflict, dates, revisions, and authority; inspect current implementation; preserve owner-approved requirements and accepted ADRs; and escalate decisions requiring owner authorization. Do not silently overwrite an accepted decision.

## AI and agent engineering

The platform must remain model- and provider-extensible. Do not hardwire the architecture to a single model vendor, model family, agent framework, or orchestration provider without an accepted decision. Support evaluation of hosted and local models, model routing, tool adapters, specialized agents, and multi-agent workflows.

Extensibility does not mean unrestricted permissions. Every agent and tool integration must declare purpose, inputs/outputs, permissions, data access, side effects, audit requirements, and failure behavior. AI may analyze, research, recommend, and propose order intents within its scope. Broker dealing remains behind the same centralized risk and execution governance as every other order source.

## Trading safety baseline

- Capital.com is the primary planned broker integration; verify current official API behavior before implementation.
- Broker-confirmed account, order, fill, position, balance, and margin state is authoritative for broker activity.
- Keep historical-data retrieval, live streaming, timestamp normalization, freshness checks, and recovery explicit.
- Existing project baseline records quote-age controls of 5 seconds normal, over 10 seconds blocking new automated entries, and over 15 seconds stale. Treat these as historical owner-approved requirements to reconcile against the current authoritative specification before implementation.
- Keep DEMO, SIMULATION, BACKTEST, and LIVE isolated in configuration, persistence, authorization, and reporting.
- The recorded trading gate is disabled by default until the required DEMO reconciliation and risk-gateway validation are complete. LIVE requires explicit owner authorization and risk acknowledgement.

## Engineering workflow

For substantial work, follow: discovery → source reconciliation → design → bounded implementation → tests → verification → documentation → review → handover.

Use focused branches and pull requests. Prefer small, reviewable commits. Include acceptance criteria and verification evidence in PR descriptions. Do not merge a PR or release software unless the owner has authorized that action or the applicable governance explicitly delegates it.

## Compatibility and platform constraints

Historical development records identify macOS 13.7.8, Xcode 14.3.1, and Swift 5.8.1 on an Intel iMac, with a macOS 13 minimum deployment target. These are historical environment facts and must be rechecked before choosing APIs or dependencies. Preserve compatibility until the active toolchain is verified. Backend technology is recorded as Node.js 24 and TypeScript; verify runtime and CI versions before pinning.

## Required continuity records

Maintain and cross-reference:

- `docs/engineering/PROJECT_CONTINUITY.md`
- `docs/engineering/CONVERSATION_INDEX.md`
- `docs/engineering/ENGINEERING_DECISION_LOG.md`
- `docs/engineering/TASK_REGISTER.md`
- `docs/engineering/IMPLEMENTATION_STATUS.md`
- `docs/engineering/PROJECT_KNOWLEDGE_SOURCES.md`

Update these records whenever verified project state, decisions, blockers, or next actions change.
