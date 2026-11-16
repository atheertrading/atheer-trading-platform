# Conversation Continuity and Recovery Protocol

## Purpose

Preserve project chronology and decisions across ChatGPT sessions so engineering work resumes from verified state rather than restarting or relying on vague recollection.

## Required session record

For each material project session, record:

- Stable session identifier and date.
- Scope, requested outcome, and bounded work completed.
- Governing source documents and revisions consulted.
- Decisions made, decision owner, status, and rationale.
- Repository, branch, PR, commit, and changed file references.
- Build/test commands and exact results.
- Open issues, unresolved conflicts, risks, and assumptions.
- Next concrete action and dependencies.

## Required continuity updates

At the end of a material engineering session, update the relevant records:

1. CONVERSATION_INDEX.md — chronology and session locator.
2. PROJECT_CONTINUITY.md — durable project state, latest verified baseline, and next action.
3. TASK_REGISTER.md — task status, evidence, owner, and blockers.
4. IMPLEMENTATION_STATUS.md — implemented, partial, unverified, and pending states.
5. ENGINEERING_DECISION_LOG.md and SPECIFICATION_CONFLICT_REGISTER.md — material decisions and conflicts.

Do not add routine chat noise. Record only information that affects future engineering decisions, traceability, or continuation.

## Recovery sequence

1. Locate the most relevant session in CONVERSATION_INDEX.md by session ID, date, project area, PR, or task.
2. Retrieve the relevant prior conversation or available history context where accessible.
3. Read the current repository branch, commit, working tree, open PRs, and latest CI results.
4. Compare historical decisions with current approved Library specifications and repository records.
5. Distinguish original transcript evidence, a conversation summary, an approved decision, and current implementation evidence.
6. Resume from the latest verified state; do not repeat completed work or silently revive superseded assumptions.

## Retrieval integrity

- A conversation index is a locator and summary, not a complete transcript archive.
- Do not claim to have retrieved a full transcript when only a summary or indexed record is available.
- Preserve exact document IDs, commit SHAs, PR numbers, and dates when known.
- If a historical conversation or artifact is inaccessible, record it as unavailable/unverified and continue from the remaining authoritative evidence.
- Never invent missing decisions, approvals, test results, or historical implementation details.
