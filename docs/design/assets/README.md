# ATHEER Trading Pro — Design Asset Manifest

Status: source reference archive identified in Library; four raster concepts inspected; binary repository ingestion and screen-specific high-fidelity production remain pending. The source archive is `ATHEER Trading Pro Showcase.zip` (Library path: `/AtheerTradingPro/ATHEER Trading Pro Showcase.zip`). The archive is retained in the Library; this does not imply its binary contents are committed to Git.

## Asset conventions

- Root: `docs/design/assets/`
- Screen folder: `assets/SCR-<NN>-<screen-slug>/`
- Stable export name: `SCR-<NN>-<screen-slug>-<appearance>-<locale>-<density>-v<MAJOR>.<ext>`
- Example: `SCR-00-application-shell-dark-ar-balanced-v1.png`
- Preserve editable source files alongside exports when available.
- Never replace an approved version in place; increment the version and retain history.
- Reference concepts must remain in a separate `reference/` namespace; do not silently promote them to approved screen assets.

## Original source archive and reference concepts

Source: Library file **ATHEER Trading Pro Showcase.zip**, uploaded 2026-11-18. The archive contains four original PNG images (plus macOS `__MACOSX` metadata files). Original raster dimensions were inspected after extraction.

| Reference ID | Archive filename | Dimensions | Classification | Status |
|---|---|---:|---|---|
| REF-01 | `ATHEER Trading Pro Dashboard-1.png` | 1672 × 941 px | Composite dark dashboard/UI reference | Library source; Git binary ingestion pending |
| REF-02 | `ATHEER Trading Pro Dashboard Mockup-2.png` | 1536 × 1024 px | High-detail dark workstation concept | Library source; Git binary ingestion pending |
| REF-03 | `ATHEER Trading Pro Concept Board-3.png` | 1536 × 1024 px | Multi-screen promotional concept board | Library source; Git binary ingestion pending |
| REF-04 | `ATHEER Trading Pro Showcase-4.png` | 1536 × 1024 px | UI/UX showcase composition | Library source; Git binary ingestion pending |

Reference handling:
- Preserve original bytes and filenames when ingesting; record SHA-256 checksums and source provenance.
- Do not crop, retouch, recolor, or overwrite source references. Derivatives require separate filenames and traceable parent references.
- These are composite concept references, not twelve independent screen mockups, verified application screenshots, or implementation evidence.
- Treat visible prices, balances, account data, broker states, performance values, and charts as illustrative unless independently verified.
- Label references `Reference / Not Approved`; do not infer product behavior or measurements from their pixels.

## Viewport standard

See [ATHEER macOS Viewport Specification v1](../ATHEER_MACOS_VIEWPORT_SPEC_V1.md).

| Purpose | Logical content viewport | 2× export canvas | Qualification |
|---|---:|---:|---|
| Minimum layout baseline | 900 × 600 pt | 1800 × 1200 px | Current SwiftUI source declaration; runtime QA pending |
| Wide desktop reference | 1440 × 900 pt | 2880 × 1800 px | Design target, not a supported minimum claim |

SwiftUI dimensions are logical points. PNG export dimensions are pixels. Do not conflate the two or claim runtime qualification until visual QA evidence is attached.

## Required metadata per asset

| Field | Requirement |
|---|---|
| Screen ID / name | Match the screen contract in the blueprint |
| Design version | Explicit version |
| Viewport | Exact logical width × height and export scale |
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
- Minimum and wide viewports from the viewport specification; add intermediate breakpoints when behavior materially changes.
- Record macOS logical points separately from exported raster pixels and scale.

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
