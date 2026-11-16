# ATHEER Trading — Engineering Decision Log

This log records decisions and proposals across project knowledge sources. It does not replace formal ADRs. Formal architectural decisions must be reconciled with historical ADRs before assigning or reusing ADR identifiers.

## Owner-endorsed decisions

### EDL-001 — Federated project knowledge and authority

- **Date:** 2026-11-16
- **Status:** Owner-endorsed
- **Decision:** GitHub, ChatGPT Library, and relevant historical ChatGPT conversations form a coordinated project knowledge system. GitHub is authoritative for committed software and Git history, but is not the sole authoritative source for all project architecture or knowledge. The Library remains the designated workspace for governing standards, specifications, architecture documentation, research, and archives. Conversations preserve chronology and rationale. Continuity records connect these sources.
- **Consequences:** Maintain source provenance, document registry, conversation index, decision log, and continuity records. Do not duplicate or silently supersede authoritative documents.

### EDL-002 — Public foundational repository

- **Date:** 2026-11-16
- **Status:** Owner-endorsed
- **Decision:** `atheertrading/atheer-trading-platform` is public during the foundational stage.
- **Consequences:** Treat all committed content, issues, pull requests, workflow logs, and artifacts as public. Never commit secrets or sensitive account data. Public visibility does not itself grant a reuse license; license selection remains a separate owner decision.

### EDL-003 — Provider-independent AI extensibility

- **Date:** 2026-11-16
- **Status:** Owner-endorsed product/architecture direction; detailed design pending
- **Decision:** AI is a foundational platform capability. The architecture should remain extensible across model providers, hosted and local models, agent frameworks, tools, and multi-agent orchestration rather than imposing arbitrary single-vendor restrictions. AI agents may initiate and execute pre-authorized workflows, including bounded autonomous trading and position-management operations, within their assigned mandate.
- **Constraints:** Model/provider flexibility does not imply ungoverned permissions. Agents must have explicit responsibilities, least-privilege tool access, data boundaries, auditability, and controlled side effects. Agents cannot access broker dealing APIs directly, authorize their own risk, or expand their permissions. Every financial action must pass through the same centralized authorization, RiskEngine, OMS, and Execution Gateway path as other order sources.
- **Next:** Develop an AI architecture proposal and compare provider abstraction, model routing, agent runtime, tool contracts, evaluation, observability, and cost/latency controls.

## Proposals and unresolved decisions

| ID | Topic | Status | Required next step |
|---|---|---|---|
| EDP-001 | Modular monorepo structure | Proposed | Reconcile surviving code and documentation before finalizing boundaries |
| EDP-002 | IPDS color and semantic token system | Proposed | Inspect existing visual specifications, then validate contrast and component semantics |
| EDP-003 | License for public repository | Unresolved | Owner selects an explicit license; do not add one by assumption |
| EDP-004 | Branch protection and merge policy | Pending configuration | Inspect repository settings and choose enforceable rules |
| EDP-005 | CI toolchain matrix | Pending verification | Confirm local and hosted Swift/Xcode/Node toolchains |

## Decision maintenance

Every material decision must state its source, date, scope, status, rationale, consequences, and whether a formal ADR is required. Superseded decisions remain in the log with a replacement reference; do not erase history.


### EDP-006 — Orthogonal AI autonomy and capability permissions

- **Date:** 2026-11-16
- **Status:** Proposed synthesis; formal source reconciliation pending
- **Source basis:** ATP-ARCH-011, ATP-ARCH-028, ATP-ARCH-029; Q27.2, Q27.4, Q27.5, Q27.6, Q28.24, Q28.47, and Q29.5 in the Library Q&A archive.
- **Problem:** The source set uses multiple taxonomies: five operational autonomy levels (L0–L4 / A0–A4), four capability-authority levels (observe/analyze/propose/controlled operation), and three execution models. These describe related but non-identical concerns.
- **Recommendation:** Model autonomy level and capability permissions as separate dimensions. Autonomy describes how independently an agent may operate a workflow; permissions describe which data, tools, records, and side effects it may access. Every action additionally carries an authorization classification and passes the receiving domain's deterministic policy.
- **Execution boundary:** Agents may initiate pre-authorized order workflows, but cannot submit directly to broker APIs or authorize risk. All financial state changes use the central RiskEngine, OMS, and Execution Gateway.
- **Next:** Reconcile the formal specifications and Q&A decision chronology, then establish one canonical autonomy/permission matrix with migration mappings from the historical labels.


### EDL-004 — Consolidated modular engineering repository

- Date: 2026-11-16
- Status: Adopted under the owner's current direction.
- Decision: Use atheertrading/atheer-trading-platform as the single modular engineering monorepo. The ChatGPT Library remains the federated authority for approved specifications, standards, research, and historical archives; conversation chronology is indexed through continuity records.
- Historical reconciliation: This supersedes ATP-ARCH-042 only for the prescribed four separate Git repositories. Its substantive architecture, governance, and control requirements remain in force unless separately revised. The original specification remains preserved in the Library.
- Rationale: Atomic changes across source, tests, contracts, build and documentation; one AI navigation hierarchy; simpler CI and integration; no loss of Library knowledge authority.
- Consequences: Maintain logical ownership domains, CODEOWNERS, traceability, modular dependency rules, and source provenance. Do not create additional repositories absent a new ADR.


## EDL-005 — Mermaid architecture diagrams are maintained as source

**Date:** 2026-11-16  
**Status:** Accepted engineering practice under delegated Head of Engineering authority  
**Decision:** Maintain architecture diagrams as version-controlled Mermaid source files (`.mmd`) under `docs/architecture/diagrams/`, with a catalog, provenance for historical extracts, and automated rendering in CI. Historical diagrams must be preserved separately from canonical current diagrams; extraction does not imply approval or implementation.  
**Rationale:** Source-controlled diagrams are diffable, reviewable, reproducible, and can be validated alongside architecture documentation. Exported images alone are not sufficient source artifacts.  
**Constraints:** Mermaid diagrams express intended architecture and workflows; they are not evidence of implementation. Historical source paths and revisions must remain traceable. A diagram may be marked superseded only with an explicit replacement reference; original source content is retained.

## EDL-006 — Conservative Xcode configuration baseline

- **Date:** 2026-11-16
- **Status:** Accepted engineering decision under delegated Head of Engineering authority; implementation is present on the Phase 2 review branch and hosted CI passed; local Xcode 14.3.1 compatibility verification remains pending.
- **Scope:** Native macOS project configuration for `ATHEERTradingPro`.
- **Decision:** Preserve the verified project identity (bundle ID `com.atheertrading.desktop`), macOS 13.0 deployment target, Swift 5 language mode, and pinned XcodeGen 2.36.1 toolchain compatibility. Define explicit Debug and Release build configurations. Enable targeted Swift concurrency diagnostics as a staged migration baseline. Keep standard architecture selection rather than forcing a universal binary. Keep local/CI code signing disabled pending Phase 3. Do not invent app entitlements, sandbox capabilities, icons, UI-test targets, or package dependencies without concrete product requirements.
- **Rationale:** Minimize compatibility risk against the historical Xcode 14.3.1 / Swift 5.8.1 Intel workstation while improving build reproducibility, diagnostics, and Release qualification.
- **Consequences:** CI must generate the project, inspect the scheme, build Debug, run XCTest, and build Release. Local Intel/Xcode 14.3.1 verification remains required. arm64 requires a separate verified host/toolchain. Hardened-runtime settings do not constitute signing or notarization.
- **Evidence:** Session `ATP-2026-11-16-011`; branch `build/phase-2-xcode-configuration`.
- **Formal ADR:** Not assigned; historical ADR inventory/reconciliation remains in progress.


## EDL-007 — Local backend health vertical slice

- Date: 2026-11-16
- Status: Accepted engineering decision for the bounded local-development slice under delegated engineering authority; not an owner-approved general API transport decision.
- Decision: Establish a minimal Node.js 24 / TypeScript API process using Node's built-in HTTP server. Bind only to 127.0.0.1 by default and reject non-loopback host configuration. Expose GET /health/live for process liveness and GET /health/ready for platform readiness.
- Readiness remains HTTP 503 while persistence and broker adapters are not configured. Trading is explicitly disabled. No market, account, order, strategy, risk, or broker endpoints are exposed.
- Rationale: Deliver a non-trading application/backend operational slice without fabricating data, exposing services to the network, or prematurely deciding the full API/event transport architecture.
- Constraints: The slice does not settle REST versus WebSocket versus IPC for business APIs. It does not establish database, broker, authentication, production, or LIVE readiness.
- Verification: Strict TypeScript build/check and six Node test cases passed in an isolated Linux container using Node 22.16.0. A prior GitHub run on the previous revision passed npm ci, typecheck, and tests on Node 24.22.2, repository hygiene, and GitHub Actions CodeQL; the macOS build remained queued. The compile-first refactor requires a fresh hosted run; local Mac verification remains pending.
