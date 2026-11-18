# ATHEER Trading — Multi-Agent Engineering Operating Model

| Field | Value |
|---|---|
| Document ID | ATP-MA-ENG-001 |
| Version | 1.0 |
| Date | 2026-11-18 |
| Status | Owner-directed operating-model baseline; adoption and pilot qualification tracked by [Issue #60](https://github.com/atheertrading/atheer-trading-platform/issues/60) |
| Scope | Engineering collaboration across backend, infrastructure, macOS, UI/UX, QA, architecture and security |
| Authority | Supplements `AGENTS.md`, approved Library specifications, accepted ADRs and repository governance; does not override them |

## 1. Purpose

Define a controlled multi-agent engineering operating model for ATHEER Trading Pro. Specialized AI agents may work concurrently on separate but coordinated engineering workstreams while producing one coherent, testable and maintainable product.

The objective is not to maximize the number of agents. It is to increase safe parallel throughput without fragmenting architecture, duplicating sources of truth, creating incompatible contracts, weakening security, or bypassing trading controls.

This document defines logical roles, ownership boundaries, collaboration protocols, integration contracts, GitHub workflow, quality gates, escalation rules and a staged adoption plan.

### 1.1 Status and implementation distinction

This document establishes the operating design. It does **not** claim that:
- separate agent identities, ChatGPT sessions, or autonomous runtimes are already provisioned;
- agents automatically share memory, context, credentials, tools or repository state;
- an agent has been granted GitHub write access;
- automated agent-to-agent communication or orchestration is running;
- any application, backend, broker or trading capability has been implemented by this documentation change.

Actual agent availability, model/provider capability, tool access, repository permissions and execution limits must be verified when provisioning each agent. Until then, the roles can be performed as explicitly assigned work modes by the engineering orchestrator.

## 2. Governing principles

1. **One product architecture:** all agents work from the same approved requirements, architecture, contracts and engineering standards.
2. **Explicit ownership:** every task, file/module, contract and acceptance decision has a named accountable role.
3. **Contract-first parallelism:** dependent work may proceed concurrently only after the required interface contract is stable enough to implement against.
4. **Bounded autonomy:** agents may execute only within declared task, repository, data and tool permissions.
5. **No implicit shared context:** GitHub issues, pull requests, versioned specifications and evidence records are the durable collaboration protocol.
6. **No direct mainline writes:** agents work on isolated task branches and submit focused pull requests.
7. **Evidence over assertion:** implementation, test, security and runtime claims require exact commit and reproducible evidence.
8. **Fail closed:** ambiguous authorization, stale or invalid data, missing contracts, tool failure or uncertain execution state must not be treated as success.
9. **Preserve history and owner work:** no force-push, branch rewriting, destructive synchronization or deletion without the required authorization.
10. **Provider neutrality:** do not bind the architecture to a single model vendor, agent framework or orchestration runtime without an accepted architecture decision.

## 3. Team topology and accountability

The target operating topology is:

`Owner → Chief Engineering Orchestrator → Specialized Roles → Integration / Quality Gate`

### 3.1 Chief Engineering Orchestrator

**Accountable for:** end-to-end delivery coherence.

Responsibilities:
- translate product requirements into bounded outcomes and acceptance criteria;
- inspect governing sources, current repository state, code, tests, PRs and dependencies before delegation;
- decompose work into independently deliverable tasks;
- assign an accountable agent/role, file ownership, dependencies and permission profile;
- establish and version cross-agent contracts before parallel implementation;
- resolve architectural conflicts and prevent duplicate implementations;
- review evidence, integration behavior, safety and release readiness;
- maintain task register, continuity, decision log and handover records.

The orchestrator is not permitted to waive security, RiskEngine, OMS, broker or owner-approval gates.

### 3.2 Backend & Infrastructure Agent

**Primary ownership:**
- Node.js / TypeScript services and backend application composition;
- service lifecycle, local process supervision and authenticated IPC;
- broker adapters and provider integration under approved contracts;
- market-data ingestion, normalization, quality, freshness and recovery;
- persistence, migrations, audit and event handling;
- backend domain/application services, API adapters and deterministic backend tests;
- observability, diagnostics, resilience and backend build/test workflows.

**Must not:**
- create an alternate order execution path;
- let agents, strategies or UI call broker dealing APIs directly;
- bypass central authorization, RiskEngine, OMS or Execution Gateway;
- invent broker facts, provider limits, financial values or execution outcomes;
- expose credentials or session tokens in logs, client payloads or prompts;
- enable LIVE or change production/risk permissions.

### 3.3 UI/UX & macOS Agent

**Primary ownership:**
- Swift / SwiftUI application and presentation architecture;
- design tokens, themes, reusable components and interaction patterns;
- navigation, workspace composition, panels and window behavior;
- screen layouts, view models, accessibility and localization foundations;
- charting and market visualization presentation;
- client-side state, loading/error/empty/stale states and user feedback;
- deterministic Swift/XCTest and UI-level verification where available.

**Must not:**
- create an independent broker session authority;
- embed broker credentials, model-provider secrets or service-side authorization policy;
- treat local UI state as authoritative financial state;
- fabricate production quotes, balances, positions, fills or execution status;
- bypass backend authorization, RiskEngine, OMS or Execution Gateway;
- interpret a successful request submission as a confirmed broker execution.

### 3.4 QA & Integration Agent

**Primary ownership:**
- contract conformance and cross-layer integration scenarios;
- deterministic test design, regression matrices and failure-path coverage;
- exact-head CI inspection and evidence collection;
- API/IPC compatibility, serialization and state-transition verification;
- integration defect reproduction and regression prevention;
- traceability from requirement to test and observed result.

This role may initially be performed by the orchestrator until a separately provisioned QA agent is justified.

### 3.5 Architecture & Security Reviewer

**Primary ownership:**
- dependency direction, bounded contexts and module boundaries;
- authentication, authorization, secret custody and trust boundaries;
- threat modeling, least privilege and data handling;
- agent/tool capability profiles and audit requirements;
- trading safety invariants and separation of advisory from execution authority;
- review of architecture decision changes and high-risk integration plans.

This role may initially be performed by the orchestrator. A specialized reviewer must not approve its own security-sensitive implementation without independent review.

## 4. Responsibility and decision matrix

| Work product / decision | Accountable | Responsible contributors | Required review |
|---|---|---|---|
| Product scope and owner approvals | Owner | Orchestrator | Owner |
| Task decomposition and dependency graph | Orchestrator | Specialized agents | Orchestrator |
| Backend implementation | Backend Agent | Backend Agent | QA + Architecture as risk requires |
| SwiftUI / UI implementation | UI/UX Agent | UI/UX Agent | QA + UX/Architecture review |
| Cross-layer integration contract | Orchestrator / designated contract owner | Backend + UI agents | Both sides + QA |
| Contract implementation mapping | Each owning agent | Backend or UI agent | Contract owner |
| Security / permission model | Architecture & Security Reviewer | Relevant agent | Independent review; owner where required |
| Test evidence and integration result | QA & Integration | Both implementation agents | Orchestrator |
| Architecture decision record | Orchestrator | Relevant agents | Owner if reserved decision |
| Pull request merge | Delegated repository maintainer / Orchestrator | PR author supplies evidence | Required checks and review |
| LIVE, production, broker permission or risk-limit authorization | Owner | No agent may self-authorize | Explicit owner approval |

Accountability cannot be transferred merely by mentioning another agent in a prompt or issue.

## 5. Work decomposition and parallel execution

### 5.1 Eligible parallel work

Parallelize work when:
- each task has a bounded outcome and acceptance criteria;
- file/module ownership does not overlap;
- required upstream contracts are published and versioned;
- dependencies are either satisfied or explicitly mocked through test-only fixtures;
- each branch can be reviewed and tested independently.

Examples:
- backend implementation of a published market-data response contract;
- SwiftUI Market Explorer implementation against the same contract;
- independent backend and UI test suites;
- documentation, test fixtures and observability work that do not change the same files.

### 5.2 Work that must be serialized

Serialize or explicitly coordinate:
- changes to shared domain semantics or integration contracts;
- changes to authorization, credential custody, risk policy or order lifecycle;
- shared persistence schema and event-version changes;
- changes to root governance, build configuration, dependency versions or CI workflows;
- work where the second task cannot be meaningfully tested before the first contract or migration is stable.

### 5.3 Dependency states

Use these states in task descriptions:
- `READY`: inputs, contract and prerequisites are verified.
- `IN PROGRESS`: implementation is active within the assigned boundary.
- `WAITING ON CONTRACT`: implementation must not guess a missing interface.
- `BLOCKED`: an external or upstream dependency prevents safe progress.
- `INTEGRATION READY`: local task acceptance evidence is attached and PR is reviewable.
- `INTEGRATED`: cross-layer checks pass on the integrated exact head.
- `ACCEPTED`: all stated acceptance criteria and required approvals are satisfied.

A drafted document, generated code, open PR or passing isolated unit test is not by itself evidence of integration or acceptance.

## 6. Backend–Frontend Integration Contract

The integration contract is the shared boundary between Backend and UI/UX agents. It must be written before parallel implementation begins.

For each vertical slice, record:

1. Contract identifier, version, owner and status.
2. User-visible capability and explicit non-goals.
3. Transport and route/channel definition (REST, WebSocket, authenticated local IPC or another approved transport).
4. Request, response and event schemas with required/optional fields.
5. Domain identifiers, decimal/monetary representation and timestamp/time-zone semantics.
6. Environment and provenance (DEMO, SIMULATION, BACKTEST, LIVE) where relevant.
7. Authentication and authorization requirements; never place secrets in ordinary DTOs.
8. Error taxonomy, validation behavior and user-safe messages.
9. Timeout, cancellation, retry, idempotency and duplicate-delivery semantics.
10. Ordering, sequence, reconnect, gap and stale-data behavior for streams.
11. Correlation/request IDs and observability requirements.
12. Compatibility/versioning and deprecation policy.
13. Contract tests, fixtures and acceptance criteria.

### 6.1 Contract ownership

- The orchestrator assigns one contract owner for each interface.
- Backend and UI agents jointly review the semantics before implementation.
- The backend agent owns server-side conformance; the UI agent owns client decoding and presentation mapping.
- A contract change after implementation begins requires a versioned change proposal, impact analysis, both-agent acknowledgement and updated tests.
- Neither agent may silently change shared semantics or create a private incompatible DTO.
- Provider-specific DTOs remain inside infrastructure adapters. UI consumes provider-neutral semantic models.

### 6.2 Recommended repository artifacts

Use the repository's existing conventions and avoid creating duplicate registries. For each approved vertical slice, keep the authoritative contract beside the relevant API/architecture documentation, with machine-readable schemas where appropriate. OpenAPI, JSON Schema or another format is selected per boundary; do not introduce multiple competing sources of truth.

Generated client types must identify their source schema and generation/version process. Hand-maintained duplicate schemas require explicit justification and contract tests.

## 7. File, module and Git ownership

### 7.1 Default ownership boundaries

| Area | Primary owner |
|---|---|
| `services/**`, backend runtime and server adapters | Backend Agent |
| `apps/macos/**`, SwiftUI screens and presentation | UI/UX Agent |
| Shared API/domain contract source | Explicit contract owner |
| Cross-layer tests and integration fixtures | QA & Integration |
| `AGENTS.md`, governance, architecture decisions and shared navigation | Orchestrator, with review |
| CI workflows, security policy and dependency policy | Orchestrator / Architecture & Security |

This is a default allocation, not permission to edit every matching path. The issue must list the exact paths and exclusions for each task.

### 7.2 Git workflow

1. Start from the verified target base and record its exact SHA.
2. Create one short-lived branch per independently reviewable task.
3. Do not let two agents push to the same feature branch.
4. Do not let agents commit directly to `main`.
5. Open focused PRs with scope, contract version, dependencies, changed paths, test evidence and known limitations.
6. Stack PRs only when dependency requires it; declare parent PR and exact base SHA.
7. Re-fetch current PR metadata, diff, head SHA and checks before review/merge.
8. Merge only after required checks pass on the exact current head and conflicts are resolved without rewriting contributor history.
9. Update task/continuity/implementation records only with evidence-backed state.

A green check on an old SHA, a parent branch or a different PR does not qualify the current PR head.

### 7.3 Shared-file contention

If two tasks require the same file:
- stop parallel edits to that file;
- appoint one owner for the shared change;
- agree a minimal patch boundary and sequence;
- integrate the shared change first or isolate it in a dedicated PR;
- rebase/merge only through a preservation-first, reviewed process;
- rerun all affected checks after integration.

Do not solve contention by force-pushing, overwriting, deleting or silently retargeting another agent's branch.

## 8. Agent identity, tools and permissions

Each provisioned agent must have a written capability profile:

- identity and accountable human/role;
- purpose and allowed task classes;
- repositories and paths it may read or write;
- permitted GitHub operations;
- permitted connectors, tools and external destinations;
- data classification and retention constraints;
- secret-handling restrictions;
- allowed side effects;
- required approvals;
- audit/logging and failure behavior;
- revocation and incident response procedure.

### 8.1 Least privilege

- Prefer read access by default; grant write access only to the scoped repository/branch workflow required.
- Use separate identities or installation credentials for agents when supported; never share personal access tokens or private credentials in prompts.
- Restrict writes to task branches and PR creation where the platform supports it.
- Do not grant organization administration, repository settings, secrets, environments or deployment access merely to enable coding.
- Revoke unused access and rotate exposed credentials through the owner-controlled security process.
- Tool access must be tested and recorded; an available connector is not proof of permission to perform every action.

### 8.2 Context and communication

Agents do not automatically share memory, chat history, tool results or local workspaces. Treat all cross-agent communication as explicit handoff.

The durable handoff record is the GitHub issue/PR plus linked contract and evidence. Each handoff includes:
- objective and non-goals;
- authoritative source links and exact revisions;
- task status and dependency state;
- contract identifier/version;
- owned paths and forbidden paths;
- assumptions and unresolved questions;
- implementation summary and changed-file list;
- commands, exact commit SHA and test results;
- security/trading impact;
- next action and receiving role.

Do not rely on an undocumented verbal or chat-only handoff.

## 9. Quality and integration gates

### Gate A — Task readiness
- source authority and requirements are identified;
- acceptance criteria and non-goals are explicit;
- dependencies and file ownership are resolved;
- required contract is versioned;
- permissions are least-privilege.

### Gate B — Agent completion
- implementation remains within scope;
- tests cover success, validation, errors and relevant failure/recovery paths;
- no secrets, synthetic production data or unapproved dependency changes;
- exact commit and verification evidence are attached;
- limitations and unverified claims are stated.

### Gate C — Cross-agent integration
- backend and UI agree on the same contract version;
- serialization, errors, timestamps, IDs and environment semantics match;
- loading, empty, disconnected, stale, partial and failure states are correct;
- cancellation, retries and duplicate events behave as specified;
- no duplicate session, state or authorization authority is introduced;
- end-to-end behavior is tested with clearly identified test fixtures.

### Gate D — Repository and security review
- exact-head CI and required security checks pass;
- diff and dependency changes are reviewed;
- permissions, secrets, logs and trust boundaries are checked;
- no unrelated files or generated artifacts are included;
- branch ancestry and merge order are safe.

### Gate E — Owner/workstation or operational qualification
Where required, owner-Mac runtime, visual, accessibility, Keychain, authenticated DEMO or broker integration evidence is recorded separately from hosted CI. Do not infer local qualification from CI.

No gate grants production deployment or LIVE dealing authority.

## 10. Trading-system safety invariants

These rules apply to every agent, model, tool, UI surface, backend service and integration:

1. No agent may call broker dealing APIs directly.
2. Manual, strategy, automation and AI-originated order intents converge on the same governed path:

   `Intent → Validation → Central RiskEngine → OMS → Execution Gateway → Broker Adapter`

3. AI agents may analyze, research and create typed intents only within explicit permission profiles. They cannot authorize their own risk, expand their permissions or bypass deterministic policy.
4. Broker-confirmed account, order, fill, position, balance and margin state remains authoritative for broker activity.
5. An ambiguous order timeout requires reconciliation before retry; never assume failure or resend blindly.
6. DEMO, SIMULATION, BACKTEST and LIVE remain isolated in configuration, credentials, data provenance, persistence and reporting.
7. Keep `CAP_ALLOW_TRADING=false` until all documented DEMO gates are met and the owner authorizes the applicable change. LIVE requires separate explicit owner authorization and risk acknowledgement.
8. No agent may change risk limits, broker account permissions, production credentials, deployment settings or LIVE state as an incidental task.
9. UI must represent unavailable, stale, disconnected and unconfirmed states honestly. Never fabricate broker-derived facts.
10. Deterministic code, not probabilistic model output, enforces exact calculations, hard financial constraints and safety-critical state transitions.

## 11. Conflict and escalation protocol

Stop the affected workstream and notify the orchestrator when:
- approved sources conflict or the contract is underspecified;
- two agents claim ownership of the same file or decision;
- a task requires broader permissions than granted;
- a provider/API behavior cannot be verified;
- tests reveal financial, security, concurrency or data-integrity risk;
- a tool reports an ambiguous result for a consequential operation;
- the branch is unexpectedly divergent or contains unknown commits;
- an agent cannot reproduce its claimed result.

The orchestrator records the conflict, evidence, affected tasks, options and recommendation. Owner approval is required for reserved decisions. Do not guess or silently choose a behavior that changes financial, security or product semantics.

## 12. Initial operating configuration

Start with a small topology:

| Logical role | Initial execution arrangement |
|---|---|
| Chief Engineering Orchestrator | Central coordinating ChatGPT/engineering role |
| Backend & Infrastructure | Dedicated agent/session when provisioned; otherwise explicitly delegated backend work mode |
| UI/UX & macOS | Dedicated agent/session when provisioned; otherwise explicitly delegated UI work mode |
| QA & Integration | Initially orchestrator-led, with independent checks |
| Architecture & Security | Initially orchestrator-led; independent review required for high-risk changes |

A dedicated agent is considered provisioned only after its identity, model/runtime, tools, repository access, permissions and handoff procedure are verified. Separate chats alone do not establish shared context or autonomous execution.

### 12.1 Pilot vertical slice

Use a read-only Market Explorer enhancement as the first pilot, subject to revalidation of the current mainline and open PR dependencies.

Parallel work:
- Backend: define/implement the approved read-only search/market-data contract, validation, error mapping and backend tests.
- UI/UX: implement the SwiftUI screen/view model, accessibility and explicit loading/empty/disconnected/error states against the same contract.
- QA: verify schema compatibility, query bounds, environment gating, stale response handling, error mapping and exact-head test evidence.
- Orchestrator: manage contract approval, task dependency graph, PR ancestry, integration and handover.

Pilot exclusions:
- no order entry, broker dealing, account mutation or position mutation;
- no synthetic production market data;
- no new broker credential/session authority;
- no LIVE access or trading enablement;
- no merge while required parent PRs, contracts or checks are unresolved.

The pilot must use current verified code and issue/PR state, not assume historical branch or PR status remains current.

## 13. Adoption sequence and exit criteria

1. **Publish and review:** merge this operating model after documentation checks and owner review.
2. **Provision safely:** verify actual agent runtimes, GitHub identities, tools and least-privilege permissions.
3. **Prepare contract:** select the pilot and publish a versioned interface contract.
4. **Decompose:** create linked backend, UI and QA issues with explicit path ownership and dependency states.
5. **Execute in parallel:** separate branches and PRs; use durable handoffs.
6. **Integrate:** run contract and cross-layer tests on the integrated exact head.
7. **Evaluate:** record cycle time, rework, contract defects, escaped defects, CI evidence and owner acceptance.
8. **Scale selectively:** add agents or autonomy only where the pilot demonstrates measurable value without weakening controls.

The pilot is successful only when both independently delivered workstreams integrate against one contract, all relevant quality gates pass, evidence is traceable, and the owner accepts the observed workflow. Do not claim productivity gains before measuring the pilot.

## 14. Operational metrics

Record, where available:
- lead time from issue readiness to accepted integration;
- parallel work duration versus dependency waiting time;
- contract changes after implementation start;
- integration defects and rework attributable to contract drift;
- exact-head CI pass/failure and rerun rates;
- escaped regressions and rollback/recovery events;
- handoff completeness and evidence quality;
- permission exceptions and security findings.

Metrics are diagnostic, not incentives to bypass review or reduce safety coverage.

## 15. Related governing sources

- [Repository engineering instructions](../../AGENTS.md)
- [AI Agent Working Guide](../development/AI_AGENT_WORKING_GUIDE.md)
- [AI Agent Navigation](../architecture/AI_AGENT_NAVIGATION.md)
- [Repository Architecture](../architecture/REPOSITORY_ARCHITECTURE.md)
- [Project Continuity](PROJECT_CONTINUITY.md)
- [Task Register](TASK_REGISTER.md)
- [Engineering Decision Log](ENGINEERING_DECISION_LOG.md)
- [Engineering review and trading safety decisions](ATP-ENGINEERING-REVIEW-2026-11-18.md)
- [Adoption and pilot tracker — Issue #60](https://github.com/atheertrading/atheer-trading-platform/issues/60)

## 16. Change control

Material changes to role ownership, permission profiles, contract governance, integration gates or trading safety must be proposed through a focused pull request and reviewed against `AGENTS.md`, approved Library sources and accepted ADRs.

This operating model does not grant permissions by itself. Permission is granted only by the relevant platform controls and explicit authorization. Where this document conflicts with higher-authority owner instructions, approved specifications or accepted ADRs, stop the affected work and record the conflict for resolution.
