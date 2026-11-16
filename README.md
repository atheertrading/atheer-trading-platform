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

Start with [AGENTS.md](AGENTS.md), [AI Agent Navigation](docs/architecture/AI_AGENT_NAVIGATION.md), and [Project Continuity](docs/engineering/PROJECT_CONTINUITY.md). For local setup and Xcode build instructions, see [Developer Setup](docs/development/DEVELOPER_SETUP.md).

## Trading safety

DEMO, SIMULATION, BACKTEST, and LIVE are distinct operating modes. Broker-derived values must come from authentic broker sources. Manual orders, strategies, and AI-generated order intents must share the same centralized risk and execution controls. LIVE trading is not enabled by this repository's existence and requires explicit owner authorization and verified operational safeguards.

## Current status

The governance baseline is merged. The platform foundation branch introduces a reproducible XcodeGen macOS app shell and CI/tooling configuration; it remains subject to CI and local Xcode verification. No production trading, Capital.com integration, or production IPDS is claimed by this README. See [Implementation Status](docs/engineering/IMPLEMENTATION_STATUS.md) and [Task Register](docs/engineering/TASK_REGISTER.md).

## Contributing

All contributions must follow [AGENTS.md](AGENTS.md), applicable specifications and accepted ADRs, the security policy, and the project continuity process. Proposed changes should be submitted through focused branches and pull requests with tests and verification evidence.

## License

No open-source license has been selected yet. Public visibility does not itself grant permission to reuse, modify, or redistribute this software. A license decision must be made explicitly by the project owner.
