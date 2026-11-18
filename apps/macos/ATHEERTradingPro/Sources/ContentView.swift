import SwiftUI

@MainActor
struct ContentView: View {
    @ObservedObject private var backendRuntimeModel: BackendRuntimeViewModel
    @State private var selection: AppSection? = .workspace
    @State private var showingBrokers = false
    @State private var selectedChartInstrumentId: String?

    init(backendRuntimeModel: BackendRuntimeViewModel? = nil) {
        _backendRuntimeModel = ObservedObject(
            wrappedValue: backendRuntimeModel ?? BackendRuntimeViewModel()
        )
    }

    /// Apply sidebar selection after AppKit exits the NSTableView delegate callback.
    private func scheduleSelectionChange(_ newSelection: AppSection?) {
        Task { @MainActor in
            await Task.yield()
            selection = newSelection
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("ATHEER")
                        .font(ATHEERDesignTokens.Typography.brand)
                        .tracking(2)
                        .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
                    Text("TRADING PRO")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 16)

                List(selection: Binding(
                    get: { selection },
                    set: { newSelection in scheduleSelectionChange(newSelection) }
                )) {
                    Section("WORKSPACE") {
                        Label(AppSection.workspace.title, systemImage: AppSection.workspace.systemImage)
                            .tag(AppSection.workspace)
                    }
                    Section("MARKETS") {
                        Label(AppSection.markets.title, systemImage: AppSection.markets.systemImage)
                            .tag(AppSection.markets)
                        Label(AppSection.charts.title, systemImage: AppSection.charts.systemImage)
                            .tag(AppSection.charts)
                    }
                    Section("SYSTEM") {
                        Label(AppSection.apiConnection.title, systemImage: AppSection.apiConnection.systemImage)
                            .tag(AppSection.apiConnection)
                    }
                    Section("PREFERENCES") {
                        Label(AppSection.settings.title, systemImage: AppSection.settings.systemImage)
                            .tag(AppSection.settings)
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 190)
            .background(ATHEERDesignTokens.ColorRole.deepTeal.opacity(0.22))
        } detail: {
            Group {
                switch selection ?? .workspace {
                case .workspace:
                    WorkspaceHomeView(
                        backendHealthModel: backendRuntimeModel.healthModel,
                        marketHistoryClient: backendRuntimeModel.marketHistoryClient,
                        marketDataStreamModel: backendRuntimeModel.marketDataStreamModel,
                        selectedChartInstrumentId: selectedChartInstrumentId,
                        onOpenAPIConnection: { selection = .apiConnection },
                        onOpenMarkets: { selection = .markets }
                    )
                case .markets:
                    if let client = backendRuntimeModel.marketSearchClient,
                       let streamModel = backendRuntimeModel.marketDataStreamModel {
                        MarketExplorerView(
                            client: client,
                            streamModel: streamModel,
                            onOpenAPIConnection: { selection = .apiConnection },
                            onOpenChart: { instrumentId in
                                selectedChartInstrumentId = instrumentId
                                selection = .charts
                            }
                        )
                    } else {
                        BackendRuntimeUnavailableView(
                            state: backendRuntimeModel.state,
                            onRetry: { Task { await backendRuntimeModel.start() } },
                            onOpenAPIConnection: { selection = .apiConnection }
                        )
                    }
                case .charts:
                    if let client = backendRuntimeModel.marketHistoryClient {
                        ChartWorkspaceView(
                            client: client,
                            initialInstrumentId: selectedChartInstrumentId,
                            onOpenMarkets: { selection = .markets }
                        )
                    } else {
                        BackendRuntimeUnavailableView(
                            state: backendRuntimeModel.state,
                            onRetry: { Task { await backendRuntimeModel.start() } },
                            onOpenAPIConnection: { selection = .apiConnection }
                        )
                    }
                case .apiConnection:
                    APIConnectionView(model: backendRuntimeModel.healthModel)
                case .settings:
                    SettingsHomeView(onOpenBrokers: { showingBrokers = true })
                        .sheet(isPresented: $showingBrokers) {
                            BrokerManagementView(model: backendRuntimeModel.brokerManagementModel)
                                .frame(minWidth: 760, minHeight: 560)
                        }
                }
            }
            .frame(minWidth: 620, minHeight: 520)
            .background(ATHEERDesignTokens.ColorRole.canvas)
            .navigationTitle((selection ?? .workspace).title)
        }
        .frame(minWidth: 900, minHeight: 600)
        .task {
            await backendRuntimeModel.start()
        }
    }
}
