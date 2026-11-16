# Risk Domain Contracts

**Status:** Fail-closed domain engine and configurable baseline policies implemented; approved production limits and complete financial risk formulas are not implemented.

## Authorization contract

Every order intent must be evaluated by `RiskEngine` before the OMS can mark it `RISK_AUTHORIZED`. The same contract applies regardless of intent origin. No UI, strategy or agent receives execution authority.

Risk context includes account, trading session, instrument specification, quote, current positions, complete gross account-exposure snapshot by currency, assessment time and emergency-halt state.

## Current fail-closed controls

- Account identity, status and platform authorization.
- Account/session/intent environment consistency.
- LIVE environment rejection.
- Active session for exposure-increasing operations.
- Emergency halt for exposure-increasing operations.
- Active instrument and matching quote.
- Quote freshness under an explicitly configured age limit.
- Quantity, price, tick and precision validation.
- No active risk policies → reject.
- Incomplete account exposure snapshot → reject when account-exposure policy is configured.
- Missing FX conversion for cross-currency account exposure → reject.
- Unsupported non-linear valuation model → reject under the current exposure policies.

## Configurable policies implemented

- `MaximumOrderQuantityPolicy`.
- `MaximumInstrumentExposurePolicy` (gross exposure, linear instruments only).
- `MaximumAccountExposurePolicy` (requires a complete exposure snapshot and account-currency-compatible valuation; no implicit FX).

The account-exposure context field is `existingGrossExposureByCurrency`; the provider must supply a complete gross exposure snapshot. No netting assumption is made. No numeric production limit is embedded as a default. Policy values and versions must be supplied explicitly by a future authorized configuration layer.

## Risk controls still outstanding

Margin, leverage, daily loss, max drawdown, account equity watermark, portfolio/correlated exposure, strategy allocation, instrument-specific restrictions, execution cost/slippage, broker stop-out, market session restrictions, event risk, and emergency halt persistence/recovery are not yet implemented. Their formulas, data authority, configuration approval and policy versions must be established from formal source material before coding.

## Emergency halt semantics

The current domain baseline blocks exposure-increasing `OPEN`/`INCREASE` intents when halted. `REDUCE`/`CLOSE` remain within the same RiskEngine path and are not a broker execution bypass. Actual broker-side risk-reduction operations are not implemented.

## LIVE restriction

The current implementation unconditionally rejects LIVE intents and prevents a TradingAccount from being platform-enabled for LIVE dealing. This is a code-level safety guard, not permission to enable LIVE later.
