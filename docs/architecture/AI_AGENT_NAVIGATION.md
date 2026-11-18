# AI Navigation and Repository Operating Map

## Entry point
Read root `AGENTS.md` first. It is the mandatory policy entry point for humans and agents. This document supplements, and never overrides, `AGENTS.md` or approved Library specifications.

## Navigation map
| Need | Start here |
|---|---|
| Project purpose and status | `README.md` |
| Mandatory engineering policy | `AGENTS.md` |
| Current state and next action | `docs/engineering/PROJECT_CONTINUITY.md` |
| Active work | `docs/engineering/TASK_REGISTER.md` |
| Verified vs historical implementation | `docs/engineering/IMPLEMENTATION_STATUS.md` |
| Source and document provenance | `docs/engineering/MASTER_DOCUMENT_REGISTRY.md` and `SOURCE_RECONCILIATION_REGISTER.md` |
| System boundaries | `docs/architecture/REPOSITORY_ARCHITECTURE.md` |
| Target source layout | `docs/architecture/REPOSITORY_LAYOUT.md` |
| macOS setup and build | `docs/development/DEVELOPER_SETUP.md` |
| AI contributor workflow | `docs/development/AI_AGENT_WORKING_GUIDE.md` |
| Reusable ChatGPT continuation prompt | `docs/development/ATHEER_CHATGPT_ENGINEERING_CONTINUATION.md` |
| Session chronology | `docs/engineering/CONVERSATION_INDEX.md` |
| Governance and repository topology | `docs/governance/` |

## Task execution protocol
1. Resolve task scope and acceptance criteria.
2. Inspect latest default branch, current branch, working tree, relevant code, tests, and PR state.
3. Search Library sources by exact document ID and verify version, approval, and implementation status.
4. Record conflicts and assumptions before coding.
5. Design interfaces and dependency direction before adding modules.
6. Implement the smallest coherent change with tests.
7. For local Mac work, provide safe Terminal commands and require returned evidence.
8. Run the appropriate checks and record exact outputs.
9. Update continuity, task, implementation, decision, and conversation records as needed.
10. Create a focused PR with source references and evidence.
11. Merge only under delegated project workflow and repository policy; never perform LIVE trading, credential access, or production deployment as an incidental coding step.

## Workspace product direction
The eight product workspace concepts are Command Center, Trading Desk, Strategy Lab, Automated Trading, AI Intelligence, Risk & Exposure, Portfolio, and System Monitor. These are not automatically eight navigation destinations or independent windows.

A separate historical navigation vocabulary includes Dashboard, Markets, Charts, Trading, Positions, Orders, Strategies, Portfolio, Risk, Analytics, AI Intelligence, Activity, and Settings. Do not assume one-to-one equivalence. Reconcile ATP-ARCH-014, ATP-ARCH-037, ATP-ARCH-038, and ATP-UX-001 from their approved Library revisions before freezing the information architecture. ATHEER Trading Workspace is the first quality/integration benchmark before scaling the experience.

## Source hierarchy
- Owner instructions and explicit authorization govern scope.
- Library specifications and approved standards govern intended behavior.
- GitHub default branch and history govern committed implementation evidence.
- Local uncommitted work is user data and must be preserved.
- Historical conversation summaries provide context, not proof of code or approvals.

## Agent outputs
Agents must state what was inspected, what changed, which source requirements were used, what commands were run, what passed or failed, and what remains unknown. Do not invent transcript recovery, repository state, test results, or external API behavior.
