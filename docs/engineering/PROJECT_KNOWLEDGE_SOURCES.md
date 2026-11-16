# ATHEER Trading — Project Knowledge Sources

This register identifies source categories and their intended authority. It is an initial inventory, not a claim that every historical source has been retrieved or exhaustively reviewed.

## Source authority and responsibility

| Source | Role | Authority / limitation |
|---|---|---|
| Project owner instructions and explicit approvals | Scope, binding requirements, permissions, and consequential authorization | Highest authority for owner-controlled decisions |
| ChatGPT Library — `AtheerTradingPro` | Governing standards, specifications, architecture documents, research, historical archives | Designated documentation and knowledge workspace; verify document approval status and revision |
| GitHub — `atheertrading/atheer-trading-platform` | Committed code, tests, CI, implementation evidence, branches, commits, releases | Authoritative for committed software and Git history; not sole authority for all project architecture |
| Historical ChatGPT conversations | Chronology, rationale, decisions, context, and open questions | Use original transcripts where accessible; summaries are not complete transcripts |
| Local development repositories and artifacts | Uncommitted source, build results, runtime evidence, and local work | Must be inspected and mapped to exact paths/commits; never assume synchronization |

## Known Library sources

| Source | Known identity | Current treatment |
|---|---|---|
| Engineering Operating Standards | `ATHEER Trading — Engineering Operating Standards.md`; Library file ID `libfile_63ddd9b4fbb48191bced1dfcea470ec5` | Owner-designated governing operational reference; preserve its formal approval metadata and reconcile its historical repository references |
| Complete Engineering Archive | `ATHEER Trading — Complete Engineering Archive.zip` | Original archive; preserve unchanged; inspect contents and inventory |
| Architecture and Engineering Knowledge Base | `ATHEER Trading Pro — Architecture and Engineering Knowledge Base.zip` | Original archive; preserve unchanged; inspect contents and inventory |

Earlier archive reviews referenced 31 Markdown documents with Mermaid diagrams, 47 formal architecture/implementation documents, and 517 Q&A records (564 total). These counts are historical review claims and must be independently reconciled against the actual archive contents before being treated as verified.

## Historical repository references

- The owner reports that `atheertrading/AtheerAutotrade` has been deleted.
- A repository named `AtheerTrader` appeared in prior engineering work. Its current accessibility, contents, and relationship to other local repositories must be rechecked.
- Earlier local project work was associated with `~/Developer/ATHEER` and `atheer-trading-pro`; this is historical context only. Local state must be inspected before migration.
- Do not infer that deletion of one GitHub repository deleted local working copies, other repositories, Library documents, or conversation history.

## Source inventory requirements

For every source, record:
- Stable source identifier and exact title/path/URL.
- Source type and owner.
- Version/revision and date where available.
- Approval and authority status.
- Scope and subject coverage.
- Whether the original was inspected, partially inspected, or only summarized.
- Related documents, ADRs, requirements, code, commits, and tests.
- Conflicts, superseded statements, and unresolved questions.

## Integrity rules

Preserve original archives unchanged. Do not claim exhaustive review without enumerating all archive entries. Do not treat a historical assistant summary as the source document. Keep Library updates and GitHub commits independently verifiable.


## 5. Direct archive inspection — 2026-11-16

The Library folder inventory and read-only ZIP inspection are documented in [Source Reconciliation Register](SOURCE_RECONCILIATION_REGISTER.md).

Verified structural counts for `Project documents and questions and answers.zip`:
- 1,312 ZIP entries.
- 564 Markdown documents: 517 Q&A and 47 formal architecture/implementation documents.
- 32 `.DS_Store` files and 656 AppleDouble metadata entries under `__MACOSX/`.
- 3 other non-Markdown, non-`.DS_Store` files.

The separate `ATHEER — Engineering Foundation & Establishment.zip` contains two Markdown documents, including a historical repository audit and legacy `AGENTS.md`. The audit reports a former `AtheerTrader` foundation branch and commit; these are archive-reported, not currently verified GitHub state.

A previous review also refers to 600 canonical extracted source files and 31 Mermaid-containing Markdown documents. These figures are not reconciled with the 564-Markdown ZIP inventory and must remain separately qualified.

## 6. Reconciliation records

- [Source Reconciliation Register](SOURCE_RECONCILIATION_REGISTER.md) — archive structure, formal architecture sources, and historical repository evidence.
- [Specification Conflict Register](SPECIFICATION_CONFLICT_REGISTER.md) — unresolved repository topology, source authority, AI authority, IPDS palette, archive counts, and document-status issues.

Do not mark source reconciliation complete until the 47 formal documents, 517 Q&A documents, approval metadata, and source-provenance reports have been reconciled to the required depth.


The initial [Master Document Registry](MASTER_DOCUMENT_REGISTRY.md) lists the 47 formal architecture/implementation documents and section-level counts for the 517 Q&A documents. It is a navigation baseline; approval, revision, dependencies, and supersession metadata still require full reconciliation.
