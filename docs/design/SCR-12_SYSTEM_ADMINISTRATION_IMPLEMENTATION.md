# SCR-12 — System & Administration

**Project:** ATHEER Trading Pro  
**Workstream:** Team A — Native macOS / UI  
**Specification:** docs/design/IPDS_12_SCREEN_PIXEL_SPEC_V1.md  
**Screen asset:** docs/design/assets/scr-12-system-administration/scr-12-system-administration-dark-en-balanced-v1.svg  
**Status:** Initial SwiftUI implementation candidate; native visual and accessibility qualification pending  
**Owner direction:** Design implementation authorized on 2026-11-20

## 1. Scope

Implement the existing System & Administration destination as the first screen-specific SwiftUI increment from the twelve-screen IPDS design set. The destination replaces the previous lightweight Settings content; it does not expose new placeholder routes for the remaining product areas.

The screen contains four adaptive information panels:

1. Application Preferences.
2. Broker & Environments.
3. System Health.
4. Security & Audit.

## 2. Existing contracts consumed

- ATHEERAppearance and its AppStorage preference for Dark / Light appearance.
- BackendHealthViewModel and BackendHealthSnapshot for local API liveness, readiness, backend version, broker readiness, and trading-gate state.
- CommandCenterStatusViewModel and the existing market-data status contract for provider, environment and REST-session state.
- CommandCenterStatusPresentation and OperationalStatusPresentation for source-grounded status semantics.

No backend route, broker adapter, credential authority, permission API, audit API, or dealing operation is introduced.

## 3. Presentation rules

- Missing backend facts remain NOT VERIFIED; account data remains NO SNAPSHOT.
- A connected REST session is not represented as a verified streaming feed.
- Local API liveness, platform readiness, broker state and trading authorization are rendered as separate dimensions.
- An enabled trading gate is an attention state, not a healthy state.
- Provider and environment labels are only populated from the existing market-data backend status response.
- The current native broker settings client uses Keychain-backed credential storage. The separate requirement for one backend-owned credential and broker-session authority remains an integration gate (EDL-022); this screen does not resolve or hide that discrepancy.
- Audit events and permission administration are labelled unavailable/not exposed because their UI-facing contracts are not present.
- Locale, Arabic RTL, density profiles and full accessibility qualification remain explicit pending states.

## 4. Safety boundaries

- Read-only system status presentation.
- No order-entry, cancel, close-position or dealing controls.
- No ability to enable trading or mutate risk policies.
- No fabricated balances, P&L, quotes, positions, strategy states, audit events or execution state.
- No change to CAP_ALLOW_TRADING=false.
- Broker credential editing remains in the pre-existing broker-management flow.

## 5. Verification

SystemAdministrationPresentationTests.swift covers:

- Unavailable facts remain explicitly unverified.
- REST status remains distinct from streaming and account state.
- Readiness failure does not become broker or trading authorization.
- An enabled trading flag with a not-ready platform is not presented as success.

Hosted exact-head CI, native owner-Mac build/launch, screenshots, window resizing, Light appearance, Arabic RTL, keyboard/focus and VoiceOver qualification are pending until performed.

## 6. Integration notes

The screen is implemented on a child branch of PR #92 to preserve the current UI delivery ancestry. ContentView.swift is also touched by the separate chart/market stack (#70/#83); the resulting stack must receive a deliberate shared-file review before integration. No rebase, force-push or independent merge of the chart stack is implied.
