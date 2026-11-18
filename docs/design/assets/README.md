# ATHEER Trading Pro — Design Asset Manifest

Status: initial manifest; all screen-specific high-fidelity assets are pending creation and review.

## Asset conventions

- Root: `docs/design/assets/`
- Screen folder: `SCR-<NN>-<screen-slug>/`
- Stable export name: `SCR-<NN>-<screen-slug>-<appearance>-<locale>-<density>-v<MAJOR>.<ext>`
- Example: `SCR-01-command-center-dark-en-balanced-v1.png`
- Preserve editable source files alongside exports when available.
- Never replace an approved version in place; increment the version and retain history.

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
- At least the agreed minimum and wide desktop viewport sizes, to be defined by the design review.

## Safety and integrity

- Generated concept art is inspiration only.
- Clearly watermark synthetic sample content as illustrative.
- Never present fabricated prices, balances, margin, P&L, risk limits, probabilities, or broker/execution states as real.
- Do not include credentials, account identifiers, personal data, or secrets in design assets.
- Asset approval does not approve the corresponding SwiftUI implementation or any trading capability.
