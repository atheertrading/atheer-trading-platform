# ATHEER Trading Pro — Design Asset Manifest

Status: reference source assets identified; repository binary ingestion and screen-specific high-fidelity production are pending. The four source concepts listed below are retained as reference material, not approved screen specifications.

## Asset conventions

- Root: `docs/design/assets/`
- Screen folder: `assets/SCR-<NN>-<screen-slug>/`
- Stable export name: `SCR-<NN>-<screen-slug>-<appearance>-<locale>-<density>-v<MAJOR>.<ext>`
- Example: `SCR-01-command-center-dark-en-balanced-v1.png`
- Preserve editable source files alongside exports when available.
- Never replace an approved version in place; increment the version and retain history.
- Reference concepts must remain in a separate `reference/` namespace; do not silently promote them to approved screen assets.

## Identified source reference concepts

These four original raster concepts were recovered from the 2026-11-18 conversation attachments and inspected. Their binary files have not yet been committed to this repository.

| Reference ID | Original filename | Dimensions | Intended classification | Status |
|---|---|---:|---|---|
| REF-01 | `a_wide_clean_composite_ui_mockup_a_dark_profess.png` | 1672 × 941 | Composite multi-screen dark UI reference | Identified; repository ingestion pending |
| REF-02 | `a_high_detail_polished_dark_themed_ui_concept_pos.png` | 1536 × 1024 | High-detail dark workstation concept | Identified; repository ingestion pending |
| REF-03 | `a_polished_dark_themed_promotional_design_board.png` | 1536 × 1024 | Promotional multi-screen design board | Identified; repository ingestion pending |
| REF-04 | `a_polished_dark_ui_ux_showcase_poster_for_a_tradin.png` | 1536 × 1024 | UI/UX showcase poster with screen compositions | Identified; repository ingestion pending |

Reference handling rules:
- Preserve original bytes and filenames when ingesting; record a SHA-256 checksum and source provenance.
- Do not crop, retouch, recolor, or overwrite source references. Any derivative must have its own filename and traceable parent reference.
- These are composite concept references, not 12 individual screen mockups, not verified product screenshots, and not implementation evidence.
- Treat visible prices, balances, account data, broker states, performance values, and charts as illustrative unless independently verified.
- Keep these references separate from approved deliverables and label them `Reference / Not Approved`.

## Required metadata per asset

| Field | Requirement |
|---|---|
| Screen ID / name | Match the screen contract in the blueprint |
| Design version | Explicit version |
| Viewport | Exact logical width × height and scale where relevant |
| Appearance | Dark or Light |
| Locale / direction | English LTR or Arabic RTL |
| Density | Compact, Balanced, or Spacious |
| State | Normal, loading, empty, stale, disconnected, error/rejected, pending/unknown as applicable |
| Data classification | Real verified source or clearly marked illustrative data |
| Editable source | Source file path or explicit unavailable status |
| Review status | Draft, In Review, Approved, Superseded |
| Traceability | Issue, PR, screen contract, component and interaction spec |

## Screen asset inventory

| Screen ID | Screen | Folder | High-fidelity assets |
|---|---|---|---|
| SCR-00 | Application Shell + Navigation | `assets/SCR-00-application-shell/` | Pending |
| SCR-01 | Command Center | `assets/SCR-01-command-center/` | Pending |
| SCR-02 | Markets | `assets/SCR-02-markets/` | Pending |
| SCR-03 | Charts & Analysis | `assets/SCR-03-charts-analysis/` | Pending |
| SCR-04 | Intelligence & Research | `assets/SCR-04-intelligence-research/` | Pending |
| SCR-05 | Strategy Center | `assets/SCR-05-strategy-center/` | Pending |
| SCR-06 | Automated Trading | `assets/SCR-06-automated-trading/` | Pending |
| SCR-07 | Trading & Execution | `assets/SCR-07-trading-execution/` | Pending |
| SCR-08 | Positions & Portfolio | `assets/SCR-08-positions-portfolio/` | Pending |
| SCR-09 | Risk Management | `assets/SCR-09-risk-management/` | Pending |
| SCR-10 | Performance & Analytics | `assets/SCR-10-performance-analytics/` | Pending |
| SCR-11 | Atheer Mind OS | `assets/SCR-11-atheer-mind-os/` | Pending |
| SCR-12 | System & Administration | `assets/SCR-12-system-administration/` | Pending |

## Current committed visual reference

- `ipds-application-shell-wireframe.svg`: authored structural shell wireframe; not a screenshot, high-fidelity mockup, or implementation evidence.

## Required variant matrix

For each screen, determine applicability and provide:
- Dark + Light.
- English LTR + Arabic RTL.
- Compact + Balanced + Spacious where the layout changes materially.
- Normal, loading, empty, stale/disconnected, error/rejected, and pending/unknown states where applicable.
- A verified minimum supported logical window size and an agreed wide desktop viewport. Do not label provisional design canvases as supported application minimums.
- Record macOS points (logical dimensions) separately from exported raster pixel dimensions and display scale.

## Screen delivery gates

Each screen is delivered as an independently reviewable vertical slice:
1. Screen contract and information architecture approved for design.
2. Window/viewports and responsive behavior specified.
3. High-fidelity Dark and Light variants created.
4. Arabic RTL variant created and checked for mirrored layout, typography, truncation, and control order.
5. Relevant density and operational-state variants documented.
6. SwiftUI component mapping, state ownership, and data provenance documented.
7. Acceptance tests linked to the screen contract and implementation.
8. Design review and engineering verification recorded separately.

Initial sequence: SCR-00 Application Shell + Navigation, SCR-01 Command Center, SCR-02 Markets, then SCR-03 Charts & Analysis. Do not design all screens as one composite canvas.

## Safety and integrity

- Generated concept art is inspiration only until reviewed and approved.
- Clearly watermark synthetic sample content as illustrative.
- Never present fabricated prices, balances, margin, P&L, risk limits, probabilities, or broker/execution states as real.
- Do not include credentials, account identifiers, personal data, or secrets in design assets.
- Asset approval does not approve the corresponding SwiftUI implementation or any trading capability.
