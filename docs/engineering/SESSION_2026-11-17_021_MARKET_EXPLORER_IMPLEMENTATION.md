# Engineering Session — Master Screen Execution Prompt and Market Explorer

**Session ID:** ATP-2026-11-17-021  
**Date:** 2026-11-17  
**Workstream:** Screen implementation / native macOS / Markets  
**Repository:** atheertrading/atheer-trading-platform  
**Branch:** feat/macos-market-explorer  
**Base:** PR #26 head 9f46a5ce9fc313e73dbff9e78680804c4dd1692f

## 1. Owner request

The owner requested an English ChatGPT execution prompt for **Screen Implementation, Application Development & Professional Trading Workstation**, asked that it be retained in ChatGPT memory, and directed the assistant to begin actual implementation on GitHub. The owner supplied this Library reference:

https://chatgpt.com/library/d/6afb316873908191b374122ff1194ed8?tab=all

The exact linked Library item could not be resolved through the accessible Library listing/search in this session. Its contents are therefore not represented as inspected. The URL is recorded in the published prompt as a governing source to be read when accessible. The prompt was prepared from the accessible project Engineering Operating Standards, Master Documentation Engineering Prompt, repository instructions, current product IA, provisional IPDS foundation, Capital.com market-data architecture, API health contract, and verified project continuity.

ChatGPT Memory cannot be synchronously or explicitly written by the assistant from this session. A durable copy of the prompt has instead been committed to the engineering repository; the assistant will continue to apply it in this conversation context.

## 2. Published reusable prompt

- docs/development/ATHEER_CHATGPT_SCREEN_IMPLEMENTATION_EXECUTION_PROMPT.md
- Document ID: ATP-PROMPT-SCREEN-EXEC-001
- Language: English.
- Scope: source authority, repository preservation, product navigation, screen implementation contracts, macOS/SwiftUI engineering, workspace and panel architecture, broker/trading safety, AI permissions, IPDS/UI quality, testing/verification, GitHub discipline, protected approvals, and handover.

## 3. Repository and dependency verification

- Active repository: atheertrading/atheer-trading-platform.
- Default branch: main.
- main baseline observed at 0dc062bb620a4afa93c60e5f060ee405846e3cbc.
- PR #24: Command Center and Workspace Engine, open/draft.
- PR #25: Capital.com DEMO backend and market-data REST/search contracts, open/draft; based on PR #24.
- PR #26: native Capital.com DEMO broker management and Keychain credentials, open/draft; based on PR #25.
- PR #26 exact parent head: 9f46a5ce9fc313e73dbff9e78680804c4dd1692f.
- Created feat/macos-market-explorer directly from that exact PR #26 head. This is a stacked feature branch; it does not alter PR #24, #25, or #26.
- Root AGENTS.md was inspected and its engineering, source-authority, trading-safety, branch, and continuity requirements were followed.

## 4. Actual implementation

### Native application

- Added Markets as an implemented navigation destination.
- Added Market Explorer / Instrument Search screen.
- Added a backend market-search client and typed status/instrument response models.
- Added strict DEMO/provider response validation.
- Added explicit backend REST session, streaming, and trading state presentation.
- Search is permitted only when the backend reports an active Capital.com DEMO REST session.
- Added API Diagnostics navigation from the Market Explorer screen.
- Results display instrument identity and metadata only. Untimestamped bid/offer values are intentionally omitted.
- Added explicit unavailable, empty, searching, and failed states.

### Important integration boundary

PR #26 stores broker credentials and authenticates in the native app Keychain workflow. PR #25's backend market-data runtime uses backend environment credentials and its own server-side session. These two session/credential paths are not automatically integrated in the inspected source. The new screen reports the backend session independently and does not claim that saving native Keychain credentials enables backend search. A secure credential/session handoff requires a separate design decision and implementation.

### Tests added

Five deterministic XCTest cases were added for:
- DEMO-only status decoding.
- Provider-backed instrument metadata decoding.
- Rejection of LIVE and invalid instrument payloads.
- Blocking search when the backend session is disconnected.
- Publishing search results only after a connected backend session.

## 5. Product traceability

- Added docs/product/ATHEER_SCREEN_AND_WORKFLOW_INVENTORY.md.
- Screen ID: ATP-SCR-MKT-001.
- Navigation group: Markets.
- Screen status: implemented on this feature branch; PR review pending.
- Verification status: pending exact-head CI and owner-Mac build/runtime/visual/accessibility acceptance.

## 6. Safety and exclusions

- DEMO-only, read-only catalogue search.
- No market-data streaming, live quotes, charting, orders, positions, account mutation, or dealing capability is introduced.
- No bid/ask values are shown without the required timestamp/freshness contract.
- No credentials, tokens, or session secrets are committed.
- CAP_ALLOW_TRADING=false and existing LIVE/dealing restrictions remain unchanged.
- No RiskEngine, OMS, Execution Gateway, risk limit, broker permission, or production configuration was changed.

## 7. Verification status

- GitHub branch creation and file commits: verified through GitHub connector responses.
- Source and tests: committed; not yet claimed compiled or executed.
- Exact-head CI: pending PR creation.
- Owner-Mac Xcode build, XCTest, app launch, Keychain QA, visual QA, keyboard/focus, VoiceOver, and multi-display QA: pending.
- Real Capital.com DEMO backend authentication and market search: not attempted; no owner credentials were supplied and no provider connection is claimed.

## 8. GitHub PR and exact-head CI checkpoint

- PR #31: https://github.com/atheertrading/atheer-trading-platform/pull/31
- PR title: feat(macos): add DEMO Market Explorer and instrument search.
- PR state: OPEN / DRAFT / not merged.
- Base branch: feat/broker-management-keychain-demo at 9f46a5ce9fc313e73dbff9e78680804c4dd1692f.
- Feature branch head at PR creation: 94766cfe98ff3238e3c42d0560335d45395df163.
- Branch comparison: 17 commits ahead of the exact PR #26 head; 14 intended changed files.

Initial PR CI run #44159176929 on head 94766cfe98ff3238e3c42d0560335d45395df163:
- Repository hygiene / Markdown lint: SUCCESS.
- Backend toolchain / TypeScript type-check / API tests: SUCCESS.
- Intel x86_64 macOS build, XCTest, Release, and Swift CodeQL: QUEUED.
- Apple Silicon arm64 macOS build, XCTest, and Release: QUEUED.
- Local Sync Safety run #44159176655: SUCCESS.
- A separate Local Sync Safety push run #44159105424: SUCCESS.

The successful checks above apply only to the exact head shown. They do not establish macOS build/XCTest success, owner-Mac runtime/visual acceptance, or provider connectivity.

### Feature-branch commit trail

The following 17 commits were added after the PR #26 base:

1. 3f0c3401248096ca4d2d11252e0014000b364246 — publish the English execution prompt.
2. a91f8bfcc28208ef3a828c027a47df8080d1fca7 — add the read-only DEMO market-search client.
3. 1c5c3aa5ab9913e279978df7d7190dd2f4ff59c8 — add Market Explorer screen.
4. 8cf8d7693b5550bffc1b2d57a2edbc062f34ef14 — add Markets navigation destination.
5. 81cba78312c3feb9e53eb4aabd358ee67be5bca5 — integrate Market Explorer into ContentView.
6. 6644ad47ded427c521c6d5d730701ec60520626c — preserve search failure state after backend status refresh.
7. 090aa2c88a4c5be48263d42fc010b3411ed581bd — adapt status and result layouts.
8. 36b88db5e156821d0f2203de6576202efe9f59bb — add DEMO search decoder and session-gating tests.
9. 676e82c9f13d1c801bbab989c5cc6b17edfbbcbb — add API diagnostics navigation.
10. 9707db15fbde9e95bae52f9cc3591c4d1875d932 — register the screen inventory.
11. 8e21221b85a11f976e3b51ec1488d7b82623f4e1 — add the engineering session report.
12. 876be40cb1c34870eb8eb5751ff4dd12030fe44a — update product IA.
13. 9cee993a5557e611928c9f5406b5cd88d5b9050d — update document registry.
14. b8ff150e85e3b36a2000901fdf7f2a583bbc498d — update task register.
15. 1578b27ba8bcb93e3f55d92f9a35a3533282b983 — update implementation status.
16. 60f1a4f8102823a3731c34f7cab37ec8d2c6a2e9 — update project continuity.
17. 94766cfe98ff3238e3c42d0560335d45395df163 — update conversation index.

## 9. Next actions

1. Finish the product IA and engineering continuity cross-references.
2. Review the full branch diff for correctness and scope.
3. Open a focused draft PR stacked on PR #26.
4. Inspect exact-head CI and remediate any compile/test failures.
5. Request owner-Mac Xcode/runtime/visual verification.
6. Resolve the secure native Keychain-to-backend credential/session boundary before claiming the app's native broker connection powers backend market-data search.
