import SwiftUI

struct ContentView: View {
    @State private var selection: AppSection? = .workspace
    @StateObject private var backendHealthModel = BackendHealthViewModel()
    @StateObject private var brokerManagementModel = BrokerManagementViewModel()
    @State private var showingBrokers = false
    @State private var isInstrumentQuickSearchPresented = false
    @State private var pendingMarketSearchTerm: String?

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

                Button {
                    isInstrumentQuickSearchPresented = true
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
                        Text("Search instruments")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer(minLength: 8)
                        Text("⌘K")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(ATHEERDesignTokens.ColorRole.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                .keyboardShortcut("k", modifiers: [.command])
                .help("Search the authenticated instrument catalogue")
                .accessibilityIdentifier("navigation.instrument-quick-search")
                .padding(.horizontal, 12)

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
            VStack(spacing: 0) {
                Group {
                    switch selection ?? .workspace {
                    case .workspace:
                        WorkspaceHomeView(
                            backendHealthModel: backendHealthModel,
                            onOpenAPIConnection: { selection = .apiConnection }
                        )
                    case .markets:
                        MarketExplorerView(
                            client: URLSessionMarketSearchClient(),
                            requestedSearchTerm: $pendingMarketSearchTerm,
                            onOpenAPIConnection: { selection = .apiConnection }
                        )
                    case .apiConnection:
                        APIConnectionView(model: backendHealthModel)
                    case .settings:
                        SettingsHomeView(onOpenBrokers: { showingBrokers = true })
                            .sheet(isPresented: $showingBrokers) {
                                BrokerManagementView(model: brokerManagementModel)
                                    .frame(minWidth: 760, minHeight: 560)
                            }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()
                    .overlay(ATHEERDesignTokens.ColorRole.separator)

                OperationalStatusStrip(model: backendHealthModel)
            }
            .frame(minWidth: 620, minHeight: 520)
            .background(ATHEERDesignTokens.ColorRole.canvas)
            .navigationTitle((selection ?? .workspace).title)
        }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $isInstrumentQuickSearchPresented) {
            InstrumentQuickSearchView(client: URLSessionMarketSearchClient()) { instrument in
                pendingMarketSearchTerm = InstrumentQuickSearchRouting.marketSearchTerm(for: instrument)
                selection = .markets
            }
        }
        .task {
            await backendHealthModel.refresh()
        }
    }
}
