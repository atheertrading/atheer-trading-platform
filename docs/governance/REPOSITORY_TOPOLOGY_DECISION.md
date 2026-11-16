# Repository Topology Decision
**Decision ID:** EDL-004
**Date:** 2026-11-16
**Status:** Adopted for the current project baseline.

## Decision
Use atheertrading/atheer-trading-platform as the single modular engineering monorepo for executable software, implementation records, tests, build tooling, CI, and release artifacts.

The ChatGPT Library remains the designated federated knowledge authority for governing standards, approved architecture specifications, research, historical source archives, and formal reference documents. Historical conversations remain indexed sources for chronology and rationale.

## Reconciliation with ATP-ARCH-042
ATP-ARCH-042 specified four independently governed repositories: Engineering, Owner, Knowledge Base, and User Guide. The current owner-directed strategy consolidates their operational Git repository topology into one monorepo. Their responsibilities remain logically separated through directory ownership, document status, CODEOWNERS, and change-control rules.

This decision supersedes ATP-ARCH-042 only where it prescribes four separate Git repositories. It does not supersede substantive requirements, approvals, or controls in that document. Preserve the original Library document and record this supersession in the source and conflict registers.

## Rationale
- Source, tests, contracts, and implementation documentation can change atomically in one PR.
- AI contributors navigate one instruction hierarchy.
- Cross-module changes and CI are easier to coordinate.
- The Library remains separate and preserves formal knowledge authority.
- Logical governance domains remain distinct without synchronizing four Git repositories.

## Consequences
Use modular boundaries and CODEOWNERS; do not create a coupled monolith. Record exact Library source IDs and revisions. Avoid committing duplicate archives. Extract services only when scale, deployment, security, or ownership boundaries justify it and an ADR records the migration. This decision does not select an open-source license or authorize LIVE trading.
