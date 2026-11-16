# ATHEER Trading

**A professional, intelligent, extensible multi-asset trading platform.**

ATHEER Trading is being engineered as an integrated trading environment combining real-time market data, quantitative analysis, configurable strategies, centralized risk management, order and position management, broker connectivity, AI-assisted decision intelligence, and a professional macOS workstation.

> **Project status:** Foundational setup and engineering-governance work. The capabilities described below are product objectives and architectural direction; this README does not claim that they are implemented or production-ready.

## Product direction

- **Market intelligence:** authentic broker and market data, instrument metadata, streaming, historical data, validation, and freshness controls.
- **Quantitative systems:** technical indicators, statistical research, strategy development, backtesting, and simulation.
- **Governed trading lifecycle:** common order-intent intake, centralized risk authorization, order management, execution gateway, broker confirmation, and reconciliation.
- **AI and agent ecosystem:** provider-independent model integration, local and hosted model support, specialized agents, tool adapters, multi-agent orchestration, and pre-authorized autonomous workflows.
- **Professional workstation:** native macOS experience, charts, monitoring, trading workflows, risk visibility, and configurable workspaces.
- **Operational integrity:** security, observability, auditability, deterministic testing, and controlled deployment.

## Architecture principles

The platform is intended to use modular, domain-oriented architecture with explicit contracts and dependency direction. OOP, SOLID, dependency injection, separation of concerns, testability, and maintainability are mandatory engineering standards.

AI is a first-class extensibility concern, not a single-vendor feature. Model and framework flexibility must coexist with least-privilege tool permissions, traceability, and centralized financial risk controls. No AI agent, strategy, or user interface may bypass the governed execution path.

## Technology direction

| Area | Recorded direction |
|---|---|
| Native workstation | Swift / SwiftUI for macOS |
| Backend | Node.js 24 / TypeScript |
| Primary broker | Capital.com |
| Persistence | PostgreSQL direction, subject to architecture qualification |
| Design system | Institutional Precision Design System (IPDS) |
| AI | Provider-independent model and agent architecture |

Versions and compatibility must be verified against the active development and CI environments before implementation decisions are finalized.

## Repository and project knowledge

This repository is the canonical home for committed software, build configuration, tests, CI, and implementation history. It is **not the sole authoritative source for project architecture or knowledge**.

The wider project knowledge system consists of:

1. **GitHub:** source code, tests, CI, implementation evidence, and Git history.
2. **ChatGPT Library:** governing standards, approved specifications, architecture documentation, research, and source archives.
3. **Historical conversations:** chronology, decisions, rationale, and discussion context.
4. **Continuity records:** traceable links between the sources and the latest verified project state.

Start with [AGENTS.md](AGENTS.md), [AI Agent Navigation](docs/architecture/AI_AGENT_NAVIGATION.md), and [Project Continuity](docs/engineering/PROJECT_CONTINUITY.md). For local setup and Xcode build instructions, see [Developer Setup](docs/development/DEVELOPER_SETUP.md) and the [Toolchain Manifest](docs/development/TOOLCHAIN_MANIFEST.md). Conversation continuity is maintained through the [Conversation Index](docs/engineering/CONVERSATION_INDEX.md) and [Recovery Protocol](docs/engineering/CONVERSATION_RECOVERY_PROTOCOL.md). See [Pull Request and Local Sync Workflow](docs/development/PULL_REQUEST_AND_LOCAL_SYNC.md) for branch, merge, conflict-resolution, and local update procedures, and [GitHub Repository Configuration](docs/development/GITHUB_REPOSITORY_CONFIGURATION.md) for Actions, branch protection, and security settings.

## Trading safety

DEMO, SIMULATION, BACKTEST, and LIVE are distinct operating modes. Broker-derived values must come from authentic broker sources. Manual orders, strategies, and AI-generated order intents must share the same centralized risk and execution controls. LIVE trading is not enabled by this repository's existence and requires explicit owner authorization and verified operational safeguards.

## Current status

The governance baseline and platform foundation are merged. PR #9 adds a loopback-only Node.js/TypeScript health/readiness service; PR #11 adds tested non-destructive local synchronization and workstation bootstrap tooling. PR #10 adds the native macOS health integration. Its current head `bbe43218e4010442605befb9527907b0968dca4f` has passed hosted CI #116 (including macOS Debug, XCTest, Release, and Swift CodeQL), Local Sync Safety #46, and GitHub Actions CodeQL #116. The branch is 26 commits ahead of `main` and zero behind; GitHub reports it mergeable. Review policy/branch protection remains unverified, and local Mac/Xcode build, test, launch, and end-to-end app/backend qualification remain outstanding. Hosted CI does not establish local qualification. Local synchronization, arm64 qualification, production trading, Capital.com integration, persistence, RiskEngine, OMS, Execution Gateway, and production IPDS are not claimed. See [Implementation Status](docs/engineering/IMPLEMENTATION_STATUS.md), [Task Register](docs/engineering/TASK_REGISTER.md), and [Project Continuity](docs/engineering/PROJECT_CONTINUITY.md).

## Contributing

All contributions must follow [AGENTS.md](AGENTS.md), applicable specifications and accepted ADRs, the security policy, and the project continuity process. Proposed changes should be submitted through focused branches and pull requests with tests and verification evidence.

## License

No open-source license has been selected yet. Public visibility does not itself grant permission to reuse, modify, or redistribute this software. A license decision must be made explicitly by the project owner.


## Trading Domain Foundation — ATP-DOMAIN-001 (in progress)

The initial broker-independent Trading Domain package is under implementation on feat/atp-domain-foundation, stacked on PR #10's current head. It adds exact decimal/money primitives, canonical instrument/account/quote/order/position/portfolio/session models, an explicit order lifecycle, fail-closed risk contracts, OMS idempotency and transactional-outbox interfaces, reconciliation primitives, domain events, and deterministic tests. It does not add broker execution, persistence, trading endpoints, or LIVE capability. The domain branch is not integrated into main; its integration is gated on PR #10 and the required local engineering qualification. See docs/architecture/ATP-DOMAIN-001_TRADING_DOMAIN_FOUNDATION.md and docs/engineering/IMPLEMENTATION_STATUS.md.
