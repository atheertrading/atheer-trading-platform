import SwiftUI

/// The primary read-only workstation surface. It deliberately renders unavailable
/// states instead of inventing quotes, balances, positions, or execution activity.
@MainActor
struct CommandCenterView: View {
    @ObservedObject var backendHealthModel: BackendHealthViewModel
    let marketHistoryClient: MarketHistoryClient?
    let marketDataStreamModel: MarketDataStreamViewModel?
    let selectedChartInstrumentId: String?
    let onOpenAPIConnection: () -> Void
    let onOpenMarkets: () -> Void

    init(
        backendHealthModel: BackendHealthViewModel,
        marketHistoryClient: MarketHistoryClient? = nil,
        marketDataStreamModel: MarketDataStreamViewModel? = nil,
        selectedChartInstrumentId: String? = nil,
        onOpenAPIConnection: @escaping () -> Void,
        onOpenMarkets: @escaping () -> Void = {}
    ) {
        _backendHealthModel = ObservedObject(wrappedValue: backendHealthModel)
        self.marketHistoryClient = marketHistoryClient
        self.marketDataStreamModel = marketDataStreamModel
        self.selectedChartInstrumentId = selectedChartInstrumentId
        self.onOpenAPIConnection = onOpenAPIConnection
        self.onOpenMarkets = onOpenMarkets
    }

    @StateObject private var workspaceEngine = WorkspaceEngine()
    @State private var isPanelManagementPresented = false

    private var sidebarWidth: CGFloat { CGFloat(workspaceEngine.activeWorkspace.layout.sidebarWidth) }
    private var minimumPrimaryWidth: CGFloat { CGFloat(workspaceEngine.activeWorkspace.layout.minimumPrimaryWidth) }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .overlay(ATHEERDesignTokens.ColorRole.separator)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    operationalStatus

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 16) {
                            primaryWorkspace
                                .frame(minWidth: minimumPrimaryWidth, maxWidth: .infinity, alignment: .topLeading)

                            secondaryWorkspace
                                .frame(width: sidebarWidth, alignment: .topLeading)
                        }
                        .frame(minWidth: 820, alignment: .topLeading)

                        VStack(spacing: 16) {
                            primaryWorkspace
                            secondaryWorkspace
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .padding(22)
                .frame(maxWidth: 1600, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .background(ATHEERDesignTokens.ColorRole.canvas)
        .sheet(isPresented: $isPanelManagementPresented) {
            WorkspacePanelManagementView(engine: workspaceEngine)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("COMMAND CENTER")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.8)
                    .foregroundColor(ATHEERDesignTokens.ColorRole.accent)

                Text("Trading workstation")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Market, account and platform state in one operational view")
                    .font(ATHEERDesignTokens.Typography.body)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                environmentTag("LOCAL")
                environmentTag("READ ONLY")
                environmentTag("TRADING DISABLED", tint: ATHEERDesignTokens.ColorRole.attention)
            }

            Menu {
                ForEach(workspaceEngine.snapshot.workspaces) { workspace in
                    Button {
                        workspaceEngine.selectWorkspace(workspace.id)
                    } label: {
                        if workspace.id == workspaceEngine.activeWorkspace.id {
                            Label(workspace.name, systemImage: "checkmark")
                        } else {
                            Text(workspace.name)
                        }
                    }
                }
                Divider()
                Button("New workspace") {
                    _ = workspaceEngine.createWorkspace(
                        name: "Workspace \(workspaceEngine.snapshot.workspaces.count + 1)"
                    )
                }
            } label: {
                Label(workspaceEngine.activeWorkspace.name, systemImage: "square.grid.2x2")
            }
            .help("Select or create a workspace")

            Button {
                isPanelManagementPresented = true
            } label: {
                Label("Manage panels", systemImage: "rectangle.3.group")
            }
            .help("Reorder, show, hide, add, or remove workspace panels")

            Button(action: onOpenAPIConnection) {
                Label("Connections", systemImage: "network")
            }
            .buttonStyle(.bordered)
            .help("Open API connection diagnostics")
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ATHEERDesignTokens.ColorRole.panel)
    }

    private var operationalStatus: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 180), spacing: 10)],
            alignment: .leading,
            spacing: 10
        ) {
            CommandCenterStatusItem(
                title: "MARKET DATA",
                value: marketDataStatus.value,
                detail: marketDataStatus.detail,
                symbol: marketDataStatus.symbol,
                tint: marketDataStatus.tint
            )

            CommandCenterStatusItem(
                title: "BROKER",
                value: brokerStatus.value,
                detail: brokerStatus.detail,
                symbol: "building.columns",
                tint: brokerStatus.tint
            )

            CommandCenterStatusItem(
                title: "ACCOUNT",
                value: "NOT AVAILABLE",
                detail: "Authenticated account read model is not integrated",
                symbol: "person.crop.rectangle",
                tint: .secondary
            )

            CommandCenterStatusItem(
                title: "TRADING GATE",
                value: tradingGateStatus.value,
                detail: tradingGateStatus.detail,
                symbol: tradingGateStatus.symbol,
                tint: tradingGateStatus.tint
            )
        }
    }

    private var marketDataStatus: (value: String, detail: String, symbol: String, tint: Color) {
        guard let model = marketDataStreamModel else {
            return (
                "UNAVAILABLE",
                "Managed backend market stream is not available",
                "waveform.path",
                ATHEERDesignTokens.ColorRole.attention
            )
        }

        switch model.connectionState {
        case .connected:
            if model.quotes.isEmpty {
                return (
                    "CONNECTED · WAITING",
                    "Stream connected; awaiting the first provider quote",
                    "waveform.path",
                    ATHEERDesignTokens.ColorRole.attention
                )
            }
            return (
                "STREAMING",
                "\(model.quotes.count) provider quote(s) · \(model.selectedCount) selected",
                "waveform.path",
                ATHEERDesignTokens.ColorRole.success
            )
        case .connecting:
            return (
                "CONNECTING",
                "\(model.selectedCount) selected instrument(s)",
                "arrow.triangle.2.circlepath",
                ATHEERDesignTokens.ColorRole.attention
            )
        case .degraded:
            return (
                "DEGRADED",
                model.lastError ?? "Market-data stream recovery is in progress",
                "exclamationmark.triangle",
                ATHEERDesignTokens.ColorRole.attention
            )
        case .disconnected:
            let value = model.selectedEpics.isEmpty ? "NO WATCHLIST" : "STOPPED"
            return (
                value,
                model.selectedEpics.isEmpty
                    ? "Open Markets to select DEMO instruments"
                    : "Last quote snapshots retain their age and freshness state",
                "waveform.path",
                .secondary
            )
        }
    }

    private var brokerStatus: (value: String, detail: String, tint: Color) {
        guard case .connected(let snapshot) = backendHealthModel.state,
              snapshot.readinessFailure == nil,
              let status = snapshot.brokerStatus else {
            return (
                "NOT VERIFIED",
                "Backend readiness has not confirmed broker state",
                .secondary
            )
        }

        let value = status
            .replacingOccurrences(of: "_", with: " ")
            .uppercased()
        let isConnected = status.lowercased() == "connected"
        return (
            value,
            "Backend-reported broker dependency state",
            isConnected ? ATHEERDesignTokens.ColorRole.success : ATHEERDesignTokens.ColorRole.attention
        )
    }

    private var tradingGateStatus: (value: String, detail: String, symbol: String, tint: Color) {
        guard case .connected(let snapshot) = backendHealthModel.state,
              snapshot.readinessFailure == nil,
              let enabled = snapshot.tradingEnabled else {
            return (
                "NOT VERIFIED",
                "No verified backend trading-permission snapshot",
                "questionmark.circle",
                .secondary
            )
        }

        if enabled {
            return (
                "ENABLED",
                "Backend-reported permission; no dealing controls are exposed here",
                "exclamationmark.triangle",
                ATHEERDesignTokens.ColorRole.attention
            )
        }

        return (
            "DISABLED",
            "Backend confirms the trading gate is disabled",
            "lock",
            .secondary
        )
    }

    private var primaryWorkspace: some View {
        let panels = workspaceEngine.orderedPanels.filter {
            $0.panelID.isPrimaryRegion && $0.isVisible
        }
        return VStack(spacing: 16) {
            ForEach(panels) { configuration in
                Group {
                    switch configuration.panelID {
                    case .charts:
                        chartPanel
                    case .platformHealth:
                        BackendStatusPanel(
                            model: backendHealthModel,
                            accent: ATHEERDesignTokens.ColorRole.accent
                        )
                    case .marketWatch, .accountRisk:
                        EmptyView()
                    }
                }
            }

            if panels.isEmpty {
                emptySelectionState
            }
        }
    }

    @ViewBuilder
    private var chartPanel: some View {
        if let marketHistoryClient {
            MarketChartSurfaceView(
                client: marketHistoryClient,
                initialInstrumentId: selectedChartInstrumentId,
                compact: true,
                onOpenMarkets: onOpenMarkets
            )
        } else {
            CommandCenterPanel(
                title: "Chart Workspace",
                subtitle: "Price action · Technical analysis",
                symbol: "chart.xyaxis.line",
                status: "WAITING FOR AUTHENTICATED HISTORY",
                statusColor: ATHEERDesignTokens.ColorRole.attention,
                minHeight: 438
            ) {
                VStack(spacing: 12) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 34, weight: .light))
                        .foregroundColor(ATHEERDesignTokens.ColorRole.accent.opacity(0.75))
                    Text("Historical DEMO data is unavailable")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Start the supervised backend and establish the authenticated broker session. No sample prices or synthetic candles are displayed.")
                        .font(ATHEERDesignTokens.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 430)
                    Button("Connections", action: onOpenAPIConnection)
                        .buttonStyle(.borderless)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
            }
        }
    }

    private var secondaryWorkspace: some View {
        let panels = workspaceEngine.orderedPanels.filter {
            !$0.panelID.isPrimaryRegion && $0.isVisible
        }
        return VStack(spacing: 16) {
            ForEach(panels) { configuration in
                Group {
                    switch configuration.panelID {
                    case .marketWatch:
                        marketWatchPanel
                    case .accountRisk:
                        accountRiskPanel
                    case .charts, .platformHealth:
                        EmptyView()
                    }
                }
            }

            if panels.isEmpty {
                emptySelectionState
            }
        }
    }

    @ViewBuilder
    private var marketWatchPanel: some View {
        if let marketDataStreamModel {
            LiveMarketWatchPanel(
                model: marketDataStreamModel,
                onOpenMarkets: onOpenMarkets
            )
        } else {
            CommandCenterPanel(
                title: "Market Watch",
                subtitle: "Instrument discovery · DEMO quotes",
                symbol: "list.bullet.rectangle",
                status: "BACKEND OFFLINE",
                statusColor: ATHEERDesignTokens.ColorRole.attention,
                minHeight: 244
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Authenticated market stream unavailable", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Start the supervised backend to restore the shared DEMO quote monitor. No synthetic or cached price is presented as current.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Connections", action: onOpenAPIConnection)
                        .buttonStyle(.borderless)
                }
                .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            }
        }
    }

    private var accountRiskPanel: some View {
        CommandCenterPanel(
            title: "Account & Risk",
            subtitle: "Balances · Exposure · Controls",
            symbol: "shield.lefthalf.filled",
            status: "NO ACCOUNT",
            statusColor: .secondary,
            minHeight: 220
        ) {
            VStack(alignment: .leading, spacing: 12) {
                unavailableMetric("Account equity", explanation: "No broker account snapshot")
                unavailableMetric("Margin / exposure", explanation: "No verified account data")
                unavailableMetric("Risk authorization", explanation: "Trading remains disabled")
            }
        }
    }

    private var emptySelectionState: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            Text("No panels in this region")
                .font(ATHEERDesignTokens.Typography.panelTitle)
            Text("Use Manage panels to restore a workspace panel.")
                .font(ATHEERDesignTokens.Typography.body)
                .foregroundColor(.secondary)
            Button("Restore default panels") {
                workspaceEngine.restoreDefaultPanels()
            }
                .buttonStyle(.link)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func unavailableMetric(_ title: String, explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.5)
                .foregroundColor(.secondary)
            Text("Unavailable")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
            Text(explanation)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func environmentTag(
        _ title: String,
        tint: Color = ATHEERDesignTokens.ColorRole.accent
    ) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .bold))
            .tracking(0.6)
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.10))
            .clipShape(Capsule())
    }

}

private struct CommandCenterPanel<Content: View>: View {
    let title: String
    let subtitle: String
    let symbol: String
    let status: String
    let statusColor: Color
    let minHeight: CGFloat
    private let content: Content

    init(
        title: String,
        subtitle: String,
        symbol: String,
        status: String,
        statusColor: Color,
        minHeight: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.status = status
        self.statusColor = statusColor
        self.minHeight = minHeight
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
                    .frame(width: 28, height: 28)
                    .background(ATHEERDesignTokens.ColorRole.accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(ATHEERDesignTokens.Typography.panelTitle)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 8)

                Text(status)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .tracking(0.4)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.10))
                    .clipShape(Capsule())
            }

            Rectangle()
                .fill(ATHEERDesignTokens.ColorRole.separator)
                .frame(height: 1)

            content
                .frame(maxWidth: .infinity, minHeight: max(0, minHeight - 74), alignment: .topLeading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(ATHEERDesignTokens.ColorRole.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

private struct CommandCenterStatusItem: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.7)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(detail)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(ATHEERDesignTokens.ColorRole.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
