import SwiftUI

struct WorkspaceHomeView: View {
    @ObservedObject var backendHealthModel: BackendHealthViewModel
    let onOpenAPIConnection: () -> Void

    @State private var visiblePanels = WorkspacePanelID.defaultVisible

    // Initial adaptive metrics; final breakpoints remain subject to specification reconciliation and owner visual QA.
    private let statusColumns = [GridItem(.adaptive(minimum: 150, maximum: 240), spacing: 10)]
    private let panelColumns = [GridItem(.adaptive(minimum: 320, maximum: 560), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ATHEERDesignTokens.Spacing.section) {
                header

                LazyVGrid(columns: statusColumns, alignment: .leading, spacing: 10) {
                    WorkspaceStatusTile(
                        title: "Market data",
                        value: "Unavailable",
                        detail: "No market-data provider",
                        symbol: "waveform.path",
                        tint: ATHEERDesignTokens.ColorRole.attention
                    )
                    WorkspaceStatusTile(
                        title: "Broker",
                        value: "Not connected",
                        detail: "No broker adapter configured",
                        symbol: "building.columns",
                        tint: .secondary
                    )
                    WorkspaceStatusTile(
                        title: "Account",
                        value: "Unavailable",
                        detail: "No account state loaded",
                        symbol: "person.crop.rectangle",
                        tint: .secondary
                    )
                    WorkspaceStatusTile(
                        title: "Trading",
                        value: "Disabled",
                        detail: "Execution capability is off",
                        symbol: "lock",
                        tint: ATHEERDesignTokens.ColorRole.attention
                    )
                }

                HStack {
                    Text("WORKSPACE PANELS")
                        .font(ATHEERDesignTokens.Typography.caption)
                        .tracking(1.0)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(visiblePanels.count) OF \(WorkspacePanelID.allCases.count) VISIBLE")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                if visiblePanels.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "rectangle.3.group")
                            .font(.system(size: 22))
                            .foregroundColor(.secondary)
                        Text("All workspace panels are hidden")
                            .font(ATHEERDesignTokens.Typography.panelTitle)
                        Button("Restore default panels", action: resetPanels)
                            .buttonStyle(.link)
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .background(ATHEERDesignTokens.ColorRole.panel)
                } else {
                    LazyVGrid(columns: panelColumns, alignment: .leading, spacing: 14) {
                        ForEach(WorkspacePanelID.allCases) { panel in
                            if visiblePanels.contains(panel) {
                                panelView(for: panel)
                            }
                        }
                    }
                }
            }
            .padding(ATHEERDesignTokens.Spacing.page)
            .frame(maxWidth: 1280, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(ATHEERDesignTokens.ColorRole.canvas)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Workspace")
                    .font(ATHEERDesignTokens.Typography.screenTitle)
                    .foregroundColor(.primary)
                Text("Trading operations overview")
                    .font(ATHEERDesignTokens.Typography.body)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 12)

            HStack(spacing: 7) {
                environmentTag("LOCAL", tint: ATHEERDesignTokens.ColorRole.accent)
                environmentTag("READ ONLY", tint: .secondary)
            }

            Button(action: onOpenAPIConnection) {
                Label("API details", systemImage: "network")
            }
            .help("Open local API connection diagnostics")

            Menu {
                ForEach(WorkspacePanelID.allCases) { panel in
                    Button {
                        togglePanel(panel)
                    } label: {
                        Label(
                            panel.title,
                            systemImage: visiblePanels.contains(panel) ? "checkmark" : "square"
                        )
                    }
                }

                Divider()

                Button("Restore default panels", action: resetPanels)
                    .disabled(visiblePanels == WorkspacePanelID.defaultVisible)
            } label: {
                Label("Panels", systemImage: "rectangle.3.group")
            }
            .help("Show or hide workspace panels")
        }
    }

    @ViewBuilder
    private func panelView(for panel: WorkspacePanelID) -> some View {
        switch panel {
        case .marketWatch:
            WorkspacePanelCard(
                title: panel.title,
                subtitle: "Instrument discovery and quote monitoring",
                symbol: "list.bullet.rectangle",
                status: "NO FEED",
                statusColor: ATHEERDesignTokens.ColorRole.attention
            ) {
                WorkspaceUnavailableState(
                    symbol: "antenna.radiowaves.left.and.right",
                    message: "Market data is not connected. The instrument catalogue and quote stream are unavailable."
                )
            }

        case .charts:
            WorkspacePanelCard(
                title: panel.title,
                subtitle: "Price action and technical analysis",
                symbol: "chart.xyaxis.line",
                status: "NO SERIES",
                statusColor: ATHEERDesignTokens.ColorRole.attention
            ) {
                WorkspaceUnavailableState(
                    symbol: "chart.line.uptrend.xyaxis",
                    message: "No market series is available. Candles, indicators, and drawing tools require an integrated market-data source."
                )
            }

        case .accountRisk:
            WorkspacePanelCard(
                title: panel.title,
                subtitle: "Account state, exposure, and controls",
                symbol: "shield.lefthalf.filled",
                status: "NO ACCOUNT",
                statusColor: .secondary
            ) {
                WorkspaceUnavailableState(
                    symbol: "person.crop.circle.badge.questionmark",
                    message: "No broker account is connected. Balances, margin, exposure, and risk assessments are not available."
                )
            }

        case .platformHealth:
            BackendStatusPanel(
                model: backendHealthModel,
                accent: ATHEERDesignTokens.ColorRole.accent
            )
        }
    }

    private func environmentTag(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .bold))
            .tracking(0.7)
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.10))
            .clipShape(Capsule())
    }

    private func togglePanel(_ panel: WorkspacePanelID) {
        if visiblePanels.contains(panel) {
            visiblePanels.remove(panel)
        } else {
            visiblePanels.insert(panel)
        }
    }

    private func resetPanels() {
        visiblePanels = WorkspacePanelID.defaultVisible
    }
}
