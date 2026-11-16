# ATHEER Trading — Specification Conflict Register

**Snapshot date:** 2026-11-16  
**Status:** Open; no conflicting architecture has been silently replaced.

A conflict may be a direct contradiction, an unresolved scope difference, a status discrepancy, or two sources that appear to assign different authority. Each entry must be resolved against source authority, revision history, owner direction, and implementation evidence.

| ID | Topic | Source A | Source B / recent direction | Current assessment | Required resolution |
|---|---|---|---|---|---|
| SCR-001 | Repository topology | ATP-ARCH-042 records four separately governed repositories. | Current owner direction adopts atheer-trading-platform as the single modular engineering monorepo, with the ChatGPT Library and historical conversations remaining federated knowledge sources. | RESOLVED for repository topology by EDL-004. ATP-ARCH-042 is superseded only as to the number of Git repositories; its substantive requirements remain. | Preserve the original Library specification and maintain logical governance domains, source traceability, and modular boundaries. Reopen only through a new ADR. |
| SCR-002 | Repository identity and migration | Older standards reference `AtheerAutotrade`; an archive report records a separate `AtheerTrader` repository and foundation branch. | Owner reports `AtheerAutotrade` deleted; `atheer-trading-platform` is the new public repository. Direct API lookup of `AtheerTrader` returned 404 during this session. | Partially resolved. `AtheerAutotrade` deletion is owner-reported. `AtheerTrader` is inaccessible, not confirmed deleted. Migration lineage remains unknown. | Recover surviving local work/history or confirm unavailability. Build a migration/provenance map before importing code. |
| SCR-003 | Architecture authority | ATP-ARCH-042 assigns formal architecture specifications to the Owner repository and source code to Engineering. | Owner specifies GitHub, ChatGPT Library, project documentation, and historical conversations as coordinated knowledge sources; the new repository is not the sole architecture authority. | Broadly compatible, but exact authority of the Library versus historical Owner/Knowledge Base repositories needs a formal mapping. | Define source-of-authority matrix and synchronization policy; retain source identifiers and versions. |
| SCR-004 | AI flexibility versus operational authority | ATP-ARCH-011, ATP-ARCH-028, and ATP-ARCH-029 establish provider-independent AI and prohibit AI from independently authorizing financial risk or executing broker orders. | Owner requests AI incorporation “without restrictions” and expects a broad, extensible AI capability. | Interpreted as no arbitrary provider/model/framework limitation, not removal of security or trading controls. | Design provider-neutral model gateway and broad agent ecosystem; preserve least privilege, auditability, and RiskEngine/OMS/Execution Gateway authority. Revisit only if owner explicitly changes financial authority policy. |
| SCR-005 | IPDS palette and token authority | Existing design directives record brand colors `#121212`, `#093732`, `#001F3F`, `#384959`, `#008080`, `#00CEC8`, `#81D8D0`, `#FFD700`. | Prior conversation proposed an alternative palette and semantic mappings. | Existing brand palette is the source baseline; alternative values remain proposals. Several design documents have different approval metadata. | Reconcile approved master design reference and approval register; preserve brand primitives; validate semantic mappings and WCAG contrast before implementation. |
| SCR-006 | Archive inventory counts | A prior review refers to 600 canonical extracted source files and 31 Markdown files with Mermaid diagrams. | Direct inspection of `Project documents and questions and answers.zip` found 564 Markdown documents: 517 Q&A + 47 formal architecture/implementation docs. | Counts likely refer to different collections or extraction layers; not yet reconciled. | Inspect the 600-source integrity report and locate the 31-diagram archive before publishing final counts. |
| SCR-007 | Specification status | Several architecture documents are marked established or decided by authority. | Other documents explicitly remain in progress, proposed, or pending qualification; ATP-ARCH-041 says ATP-ARCH-036 remains incomplete. | The archive is not a single uniformly approved specification set. | Build per-document status registry; do not treat all 47 files as approved or implementation-ready. |
| SCR-008 | Public visibility and license | New repository is owner-authorized as public. | No explicit open-source license selection is recorded. | Public visibility is verified; reuse rights remain unspecified. | Do not add a license or claim open-source reuse rights until owner selects one. |

## Additional AI architecture reconciliation findings

| ID | Topic | Source A | Source B / related source | Current assessment | Required resolution |
|---|---|---|---|---|---|
| SCR-009 | Agent autonomy versus permission taxonomy | Q27.2 and Q29.5 define five operational autonomy levels (L0–L4 / A0–A4). | Q28.24 defines four capability-authority levels (observe, analyze, propose, controlled operation); Q27.5 adds explicit authority boundaries. | Likely distinct dimensions rather than one conflicting scale. Do not collapse them into one numeric permission. | Reconcile as separate autonomy and capability-permission dimensions, with a canonical action authorization classification and receiving-domain enforcement. Preserve historical mappings. |
| SCR-010 | AI-initiated execution versus direct broker submission | ATP-ARCH-011 prohibits agents from authorizing risk and submitting broker orders. | Q27.4 permits AI to initiate and execute trading workflows through the centralized Execution Gateway under explicit authorization; Q27.6 requires risk validation for risk-relevant actions. | Compatible if “submit broker orders” means direct broker API access. Agents can initiate an order intent; only the governed execution infrastructure transmits broker commands. | Define the agent-to-domain order-intent contract and retain RiskEngine, OMS, Execution Gateway, broker confirmation, and reconciliation as independent controls. |

## Resolution policy

- Do not delete, overwrite, or silently reinterpret conflicting source documents.
- Record exact document IDs, versions, dates, and approval states.
- Prefer explicit owner-approved requirements and accepted ADRs within their scope.
- Use direct repository/runtime evidence for implementation status.
- Use delegated engineering authority for routine design decisions, but preserve owner approval boundaries for material scope changes, consequential security actions, destructive operations, production deployment, and LIVE dealing.
- Every resolution must include rationale, affected records, and any superseding decision reference.


## Resolved conflicts

- SCR-001 — Repository topology: Resolved by EDL-004 and docs/governance/REPOSITORY_TOPOLOGY_DECISION.md. The single modular engineering monorepo is adopted. ATP-ARCH-042 is superseded only for its four-repository topology prescription; its other substantive provisions remain in force.
