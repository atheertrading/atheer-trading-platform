# Repository Layout
~text
.
├── apps/macos/ATHEERTradingPro/  # Native SwiftUI application and tests
├── packages/                     # Shared contracts only where justified
├── services/                     # Backend services; execution gateway later
├── docs/
│   ├── architecture/
│   ├── development/
│   ├── governance/
│   └── engineering/
├── scripts/
└── .github/workflows/
~

## Rules
- Swift app code stays under the macOS app target; domain/application modules become separate targets when contracts are defined.
- Backend services are independently testable TypeScript packages.
- Cross-runtime contracts use versioned language-neutral schemas where required.
- Do not share persistence models as public API contracts.
- Do not commit credentials, local datasets, DerivedData, generated Xcode projects, build outputs, or machine-specific workspace state.
- This is a target map, not proof that all directories or modules are implemented.
