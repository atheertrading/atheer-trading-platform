# ATHEER Trading Pro — توثيق جلسة ترجمة التوجيه التنفيذي الرئيسي

**Session ID:** ATP-2026-11-17-004  
**Date:** 2026-11-17  
**Work type:** Documentation / Arabic translation / GitHub traceability  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `docs/arabic-master-execution-directive-2026-11-17`  
**Base:** `main` at `0dc062bb620a4afa93c60e5f060ee405846e3cbc`

## 1. Objective

Publish an Arabic counterpart of the reusable **ATHEER Trading Pro — MASTER EXECUTION DIRECTIVE: Screen Implementation, Application Development & Professional Trading Workstation**, while preserving the technical meaning, implementation controls, screen scope, architecture boundaries, trading safeguards, GitHub workflow, and acceptance criteria.

## 2. Sources inspected

- Root `AGENTS.md` and its authority, safety, and engineering workflow rules.
- `docs/development/AI_AGENT_WORKING_GUIDE.md`.
- Existing English continuation directive on the open PR #21 branch, for terminology and governance alignment.
- Current `main` tree and `docs/development` / `docs/engineering` inventories.
- `PROJECT_CONTINUITY.md`, `TASK_REGISTER.md`, `CONVERSATION_INDEX.md`, and `MASTER_DOCUMENT_REGISTRY.md`.
- Open PR inventory, including #21, #23, #24, #25, and #26.

The existing English continuation directive is a related governing document, not the exact source text of the newer screen-execution directive. The Arabic document is therefore a faithful, scope-preserving Arabic counterpart based on the supplied master directive and the verified project context; it does not claim to be a line-by-line translation of a separately committed English source file.

## 3. Repository and branch evidence

- Repository: `atheertrading/atheer-trading-platform`.
- Default branch: `main`.
- Base SHA: `0dc062bb620a4afa93c60e5f060ee405846e3cbc`.
- A dedicated documentation branch was created from `main`: `docs/arabic-master-execution-directive-2026-11-17`.
- Existing PRs were not modified. In particular, PR #21, PR #23, PR #24, PR #25, and PR #26 remain outside this change.

## 4. Published document

- `docs/development/ATHEER_CHATGPT_MASTER_EXECUTION_DIRECTIVE_AR.md`
- Arabic title: **ATHEER Trading Pro — التوجيه الرئيسي للتنفيذ: تنفيذ الشاشات، وتطوير التطبيق، وبناء محطة عمل تداول احترافية**.
- The document covers the reusable execution prompt, source authority, repository discovery, 12 navigation groups, screen contracts, Application Shell, Workspace & Panel Management, broker management, Capital.com safeguards, authoritative financial data, centralized risk/execution governance, AI/agent boundaries, design/UX standards, acceptance gates, GitHub workflow, local Terminal workflow, screen/workflow inventory, handover, and explicit approval boundaries.

## 5. Governance and safety

- The Arabic document is subordinate to owner approvals, repository instructions, and approved specifications.
- It does not authorize LIVE trading, production deployment, broker permission changes, risk-limit changes, or destructive repository operations.
- It preserves the disabled-by-default trading gate and the unified authorization → RiskEngine → OMS → Execution Gateway → broker → reconciliation path.
- It distinguishes documented requirements from implementation and verification evidence.
- It directs future work to the existing task register and does not create a parallel work queue.

## 6. Verification status

- GitHub branch creation: verified.
- Arabic Markdown file creation: verified by returned GitHub commit SHA.
- Repository CI, Markdown lint, local rendering, and local application tests: not yet run for this branch at the time this report was authored.
- No application source, build configuration, CI workflow, broker credentials, or trading permissions were changed.

## 7. Next actions

1. Complete the documentation registry, conversation index, continuity, and task-register cross-references.
2. Review the complete branch diff and confirm that only the intended documentation files changed.
3. Open a focused documentation PR against `main`.
4. Run the applicable repository hygiene / Markdown checks and record their exact result.
5. Do not mark the directive as fully integrated into the default branch until the PR is merged and verified.

## 8. Commit trace

Initial Arabic directive commit:

- `6984a2459e4c4013da391d1c35cc58646746b789` — `docs(development): add Arabic master execution directive`.

Subsequent commits and the PR URL will be added after GitHub confirms each operation.
