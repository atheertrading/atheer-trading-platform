# AI Navigation and Repository Operating Map

## Entry point
Read root AGENTS.md first. It is the mandatory policy entry point for humans and agents. This document supplements, and never overrides, AGENTS.md or approved Library specifications.

## Navigation map
| Need | Start here |
|---|---|
| Project purpose and status | README.md |
| Mandatory engineering policy | AGENTS.md |
| Current state and next action | docs/engineering/PROJECT_CONTINUITY.md |
| Continuous execution, approvals, and handover | docs/engineering/ATHEER_CONTINUOUS_ENGINEERING_OPERATING_DIRECTIVE.md |
| Active work | docs/engineering/TASK_REGISTER.md |
| Verified vs historical implementation | docs/engineering/IMPLEMENTATION_STATUS.md |
| Source and document provenance | docs/engineering/MASTER_DOCUMENT_REGISTRY.md and SOURCE_RECONCILIATION_REGISTER.md |
| System boundaries | docs/architecture/REPOSITORY_ARCHITECTURE.md |
| Target source layout | docs/architecture/REPOSITORY_LAYOUT.md |
| ChatGPT UI/UX and SwiftUI design/implementation rules | docs/architecture/ATP-UX-001_CHATGPT_UI_UX_AND_SWIFTUI_ENGINEERING_DIRECTIVE.md |
| macOS setup and build | docs/development/DEVELOPER_SETUP.md |
| AI contributor workflow | docs/development/AI_AGENT_WORKING_GUIDE.md |
| Governance and repository topology | docs/governance/ |

## Task execution protocol

Apply the Continuous Engineering Operating Directive for recovery, delegated decision-making, approval gates, exact-head verification, and session handover.
1. Resolve task scope and acceptance criteria.
2. Inspect latest main, current branch, working tree, relevant code, tests, and PR state.
3. Search Library sources by exact document ID and verify version, approval, and implementation status.
4. Record conflicts and assumptions before coding.
5. Design interfaces and dependency direction before adding modules.
6. Implement the smallest coherent change with tests.
7. Run the appropriate local checks and record exact outputs.
8. Update continuity, task, implementation, and decision records as needed.
9. Create a focused PR with source references and evidence.
10. Merge only under the delegated project workflow and repository policy; never perform LIVE trading, credential access, or production deployment as an incidental coding step.

## UI/UX task protocol
For any new screen, visual redesign, shared component, settings experience, or interaction change, read and follow [ATP-UX-001](ATP-UX-001_CHATGPT_UI_UX_AND_SWIFTUI_ENGINEERING_DIRECTIVE.md) before proposing or implementing the change. Do not substitute model-generated aesthetic preferences for approved requirements, IPDS tokens, existing component contracts, or verified repository behavior. UI work requires actual running-app visual verification; if unavailable, mark it NOT VERIFIED.

## Source hierarchy
- Owner instructions and explicit authorization govern scope.
- Library specifications and approved standards govern intended behavior and architecture.
- GitHub main and its history govern the verified committed implementation.
- Local uncommitted work is user data and must be preserved.
- Historical conversation summaries provide context, not proof of code or approvals.

## Agent outputs
Agents must state what was inspected, what changed, which source requirements were used, what commands were run, what passed or failed, and what remains unknown. Do not invent transcript recovery, repository state, test results, or external API behavior.
