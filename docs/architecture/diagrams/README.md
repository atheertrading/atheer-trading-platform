# ATHEER Trading — Architecture Diagram Source

This directory contains version-controlled Mermaid source. Diagrams are engineering artifacts: they describe architecture and workflows, but do not prove that the depicted components are implemented or operational.

## Canonical baseline diagrams

| File | Scope |
|---|---|
| `01-system-context.mmd` | Product actors, platform boundary, external providers |
| `02-logical-container-architecture.mmd` | Workstation, backend, bounded contexts, persistence, adapters |
| `03-market-data-pipeline.mmd` | Historical bootstrap, streaming, normalization, freshness and recovery |
| `04-order-intent-risk-lifecycle.mmd` | Common manual/strategy/AI intent path and centralized risk authorization |
| `05-oms-execution-reconciliation.mmd` | Durable OMS, Execution Gateway, broker acknowledgement and reconciliation |
| `06-ai-agent-authority-boundaries.mmd` | Model Gateway, agent permissions and non-bypassable financial controls |
| `07-environment-isolation.mmd` | SIMULATION, BACKTEST, DEMO and LIVE separation |
| `08-project-knowledge-topology.mmd` | GitHub, Library, conversations and local verification authority |
| `09-capital-demo-market-data-streaming.mmd` | Capital.com DEMO WebSocket ingestion, local SSE relay, and native quote presentation |
| `10-historical-market-data-normalization.mmd` | Historical Bid/Ask OHLC normalization, UTC lineage, duplicate validation, and observed gaps |

## Original-source diagram recovery

The Library archive `/AtheerTradingPro/90_SOURCE_ARCHIVES/Project documents and questions and answers.zip` was re-inspected on 2026-11-16. Its 564 Markdown files contain 31 documents with Mermaid fences and 52 Mermaid blocks. The original ZIP remains unchanged in the Library.

The reproducible extractor is `scripts/extract-mermaid-sources.py`. It extracts every Mermaid block into an individual `.mmd` file, writes a provenance manifest, and checks the expected source-document/block counts. Run it after downloading the original Library archive:

```bash
python3 scripts/extract-mermaid-sources.py \
  --archive "/path/to/Project documents and questions and answers.zip" \
  --output "docs/architecture/diagrams/legacy"
```

**Migration status:** canonical baseline diagrams are committed separately from the historical source set. The 52 historical blocks have been counted and the extraction process is versioned, but their individual generated files still require review and commit. Do not describe that migration as complete until all generated files are present and syntax-validated.

## Governance

- Preserve source-relative paths and source document names in extracted diagram metadata.
- Do not silently modernize a historical diagram while extracting it.
- A corrected or superseding diagram must be a separate canonical file with a documented relationship to its source.
- Review architecture claims against current approved specifications and implementation evidence.
- Render and validate every `.mmd` file in CI.
- Keep sensitive values, real account identifiers, API keys and secrets out of diagrams.


| `11-canonical-trading-domain.mmd` | Provider-independent canonical identities, instrument specifications, accounts, order-intent envelope, risk assessment, lifecycle-policy boundary, execution facts, reconciliation and audit |
| `12-postgres-transactional-persistence.mmd` | PostgreSQL migration ledger, environment-scoped records, atomic intent/risk journal, transactional domain outbox, and explicit no-dispatch boundary |
| `13-oms-authorized-order-persistence.mmd` | Risk-gated OMS order creation, immutable lifecycle event, transactional audit/outbox, and explicit no-broker-dispatch boundary |
| `14-command-center-live-market-watch.mmd` | App-scoped shared market-data model, persistent instrument watchlist, live DEMO quote panel, and separation from broker/trading authority |
| `15-historical-candlestick-chart-workspace.mmd` | Historical DEMO candle flow, normalized Bid/Ask OHLC validation, shared chart model, native chart rendering, and read-only boundary |

### Library archive availability re-check — 2026-11-18

The exact historical archive path referenced above (`Project documents and questions and answers.zip`) was not present in the accessible Library root during this session. The available `Atheer Q&A Repository.zip` contains 517 Markdown documents and 12 fenced Mermaid blocks; `Codex.zip` contains 58 Markdown documents and five standalone `.mmd` sources. All 17 accessible Mermaid sources were inspected. The previously recorded 564-document / 52-block inventory remains historical evidence for a different archive and is not re-claimed as revalidated or fully extracted in this session.

| `16-live-candle-aggregation.mmd` | Every validated DEMO stream quote reaches the app-scoped analytical event bus before UI throttling; fixed-interval intraday OHLC aggregation remains separate from historical bars and execution authority |
