# Requirements Traceability Matrix

**Status:** Initial template; requirement-level population pending formal source reconciliation.  
**Owner:** Project Owner  
**Accountable role:** Head of Engineering

## Purpose

Provide bidirectional traceability from owner-approved requirements to their authoritative source, architecture decision, implementation, tests and verification evidence.

Do not populate a requirement as approved merely because it appears in a reconstructed document or historical conversation.

## Required fields

| Field | Meaning |
|---|---|
| Requirement ID | Stable identifier |
| Requirement statement | Atomic, testable requirement |
| Source document and revision | Exact source path, ID and version |
| Authority / approval | Owner-approved, accepted ADR, established specification, proposed, historical or unresolved |
| Bounded context | Owning domain/module |
| Contract / design reference | API, event, state model or architecture record |
| Implementation path | Exact repository path and commit |
| Verification | Test name, CI run, build or operational evidence |
| Status | Proposed, source-reconciliation, specified, implemented, verified, superseded |
| Dependencies / conflicts | Linked requirements, ADRs and source conflicts |

## Initial traceability work packages

| Work package | Scope | Status |
|---|---|---|
| TR-MD | Instrument catalog, historical data, streaming, timestamps, integrity, freshness and recovery | Pending source reconciliation |
| TR-RISK | Risk policy, exposure aggregation, pre-trade checks, emergency controls and authorization | Pending source reconciliation |
| TR-OMS | Order intent, durable order state, idempotency, outbox, cancellation and reconciliation | Pending source reconciliation |
| TR-EGW | Broker command boundary, retries, timeout ambiguity and broker response normalization | Pending source reconciliation |
| TR-BROKER | Capital.com authentication, API limits, instrument specs, demo/live separation and adapter contracts | Pending official API/source verification |
| TR-AI | Model Gateway, agent autonomy, capability permissions, tool scopes and audit | Pending source reconciliation |
| TR-APP | macOS app architecture, navigation, workspace state, IPDS and accessibility | Pending source reconciliation |
| TR-SEC | Identity, authorization, secrets, audit, supply chain and deployment boundaries | Pending source reconciliation |

## Acceptance criteria

- Every implemented financial control traces to an approved requirement.
- Every requirement has a verification method and evidence location.
- Conflicting source statements are linked to the Specification Conflict Register.
- Historical or proposed material is not silently promoted to approved status.
- Changes to accepted architecture update the applicable ADR and traceability links.
