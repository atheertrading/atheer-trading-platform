# ATHEER Trading — Project Governance Charter

## Purpose

Establish the decision, authorization, documentation, and engineering controls for developing ATHEER Trading as a secure, intelligent, extensible trading platform.

This charter is a repository baseline and must be reconciled with the owner-designated Library governance documents and accepted historical ADRs. It does not silently supersede them.

## Roles

### Project Owner

The owner controls product direction, binding requirements, formal approvals, sensitive access, consequential external actions, and LIVE trading authorization.

### Head of Engineering

Responsible for technical vision, architecture, engineering quality, implementation planning, technical review, risk identification, continuity, and evidence-based recommendations. Routine product, architecture, engineering, risk-design, quality-assurance, and documentation decisions are delegated to the Head of Engineering to the extent established by the owner's instructions and the archived Owner and Developer Approval record. The Head of Engineering should make reasoned decisions without repeated consultation, document material choices, and preserve the owner's reserved authorization boundaries. Delegation does not authorize LIVE trades, broker-account permission changes, credential access, production deployment, destructive repository operations, or other explicitly reserved consequential actions.

### Engineering contributors and AI agents

Operate within explicit task scope, repository instructions, assigned permissions, and applicable specifications. They must report uncertainty, preserve history, and never represent unverified work as complete.

## Decision classes

| Class | Examples | Control |
|---|---|---|
| Routine engineering | Refactoring within approved boundaries, tests, documentation corrections | May proceed within delegated scope; document material changes |
| Architectural | Module boundaries, persistence strategy, event contracts, model gateway | Analyze alternatives; record decision and obtain required owner approval |
| Security-sensitive | Credentials, account access, permissions, private data, secrets | Least privilege; explicit authorization for sensitive access |
| Operationally consequential | Production deployment, destructive repository operations, external integrations | Explicit owner authorization |
| Financial execution | LIVE orders, dealing permissions, account operations | Explicit owner authorization and verified risk controls |

## Engineering lifecycle

Discovery → source reconciliation → requirements → architecture → bounded implementation → integration → testing → verification → documentation → review → handover.

## Trading governance

All order sources converge on one order-intake contract and centralized risk authorization. The OMS and Execution Gateway own durable order lifecycle and broker communication. Broker-confirmed state is reconciled and remains authoritative for external execution facts. No UI, strategy, agent, or service may bypass this path.

DEMO, SIMULATION, BACKTEST, and LIVE are distinct modes with separate data provenance, configuration, authorization, and reporting. LIVE must remain disabled until all required controls are verified and the owner explicitly authorizes it.

## AI governance

The platform is model- and provider-extensible. AI agents may perform research, analysis, strategy evaluation, monitoring, and authorized workflow assistance. Every agent/tool must have explicit capabilities, scoped data access, least-privilege permissions, side-effect declarations, audit trails, and testable failure behavior. AI cannot grant itself permissions or bypass the central risk/execution architecture.

## Documentation and continuity

The Library remains the designated documentation workspace. GitHub records committed engineering assets. Historical conversations preserve discussion chronology and rationale. Continuity records index and reconcile these sources.

Material decisions, task changes, and verified implementation changes must be reflected in the applicable decision log, task register, implementation status, conversation index, and project continuity record.

## Review and change control

Material architectural or governance changes require a documented rationale, alternatives, impacts, acceptance criteria, and verification plan. Preserve prior records and mark superseded material rather than silently deleting it.
