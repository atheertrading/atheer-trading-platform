import SwiftUI

struct ContentView: View {
    @State private var selection: AppSection = .workspace
    @StateObject private var backendHealthModel = BackendHealthViewModel()
    @StateObject private var brokerManagementModel = BrokerManagementViewModel()
    @State private var showingBrokers = false
    @State private var isInstrumentQuickSearchPresented = false
    @State private var pendingMarketSearchTerm: String?
    @State private var marketSearchClient = URLSessionMarketSearchClient()

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            VStack(spacing: 0) {
                commandBar

                Group {
                    switch selection {
                    case .workspace:
                        WorkspaceHomeView(
                            backendHealthModel: backendHealthModel,
                            marketSearchClient: marketSearchClient,
                            onOpenAPIConnection: { selection = .apiConnection }
                        )
                    case .markets:
                        MarketExplorerView(
                            client: marketSearchClient,
                            requestedSearchTerm: $pendingMarketSearchTerm,
                            onOpenAPIConnection: { selection = .apiConnection }
                        )
                    case .apiConnection:
                        APIConnectionView(model: backendHealthModel)
                    case .settings:
                        SettingsHomeView(onOpenBrokers: { showingBrokers = true })
                            .sheet(isPresented: $showingBrokers) {
                                BrokerManagementView(model: brokerManagementModel)
                                    .frame(minWidth: IPDSViewportMetrics.brokerManagementSheetSize.width, minHeight: IPDSViewportMetrics.brokerManagementSheetSize.height)
                            }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()
                    .overlay(ATHEERDesignTokens.ColorRole.separator)

                // The operational strip belongs to the application shell, not to a
                // workspace panel. Panel customization must never hide this state.
                OperationalStatusStrip(model: backendHealthModel)
            }
            .frame(minWidth: IPDSViewportMetrics.minimumDetailSize.width, minHeight: IPDSViewportMetrics.minimumDetailSize.height)
            .background(ATHEERDesignTokens.ColorRole.canvas)
            .navigationTitle(selection.title)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: IPDSViewportMetrics.minimumWindowSize.width, minHeight: IPDSViewportMetrics.minimumWindowSize.height)
        .sheet(isPresented: $isInstrumentQuickSearchPresented) {
            InstrumentQuickSearchView(client: marketSearchClient) { instrument in
                pendingMarketSearchTerm = InstrumentQuickSearchRouting.marketSearchTerm(for: instrument)
                selection = .markets
            }
        }
        .task {
            await backendHealthModel.refresh()
        }
    }

    // MARK: - Application navigation

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            brandHeader
                .padding(.horizontal, 18)
                .padding(.top, 22)
                .padding(.bottom, 20)

            Rectangle()
                .fill(ATHEERDesignTokens.ColorRole.separator.opacity(0.72))
                .frame(height: 1)
                .padding(.horizontal, 16)

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 22) {
                    navigationGroup("WORKSPACE", sections: [.workspace])
                    navigationGroup("MARKETS", sections: [.markets])
                    navigationGroup("SYSTEM", sections: [.apiConnection])
                    navigationGroup("PREFERENCES", sections: [.settings])
                }
                .padding(.horizontal, 10)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }

            Spacer(minLength: 8)

            sidebarFooter
        }
        .frame(minWidth: IPDSViewportMetrics.sidebarMinimumWidth, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ATHEERDesignTokens.ColorRole.deepTeal)
        .navigationSplitViewColumnWidth(min: IPDSViewportMetrics.sidebarMinimumWidth, ideal: IPDSViewportMetrics.sidebarIdealWidth, max: IPDSViewportMetrics.sidebarMaximumWidth)
        .accessibilityIdentifier("navigation.sidebar")
    }

    private var brandHeader: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(ATHEERDesignTokens.ColorRole.panelElevated)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(ATHEERDesignTokens.ColorRole.separator, lineWidth: 1)
                Text("A")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
            }
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("ATHEER")
                    .font(.system(size: 15, weight: .bold))
                    .tracking(1.9)
                    .foregroundColor(ATHEERDesignTokens.ColorRole.primaryText)

                Text("TRADING PRO")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.45)
                    .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ATHEER Trading Pro")
    }

    private func navigationGroup(_ title: String, sections: [AppSection]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.1)
                .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)
                .padding(.horizontal, 12)
                .padding(.bottom, 2)

            ForEach(sections) { section in
                SidebarNavigationButton(
                    section: section,
                    isSelected: selection == section
                ) {
                    selection = section
                }
            }
        }
    }

    private var sidebarFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(ATHEERDesignTokens.ColorRole.separator.opacity(0.72))
                .frame(height: 1)

            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ATHEERDesignTokens.ColorRole.attention)

                VStack(alignment: .leading, spacing: 2) {
                    Text("READ-ONLY FOUNDATION")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.55)
                        .foregroundColor(ATHEERDesignTokens.ColorRole.primaryText)

                    Text("Dealing controls remain gated")
                        .font(.system(size: 9))
                        .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 17)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Global command region

    private var commandBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ATHEER TRADING PRO")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(ATHEERDesignTokens.ColorRole.accent)

                HStack(spacing: 7) {
                    Text(selection.groupTitle)
                        .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)
                    Text(selection.title)
                        .foregroundColor(ATHEERDesignTokens.ColorRole.primaryText)
                }
                .font(.system(size: 12, weight: .semibold))
            }

            Spacer(minLength: 12)

            HStack(spacing: 5) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9, weight: .semibold))
                Text("READ ONLY")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.55)
            }
            .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(ATHEERDesignTokens.ColorRole.panelElevated)
            .clipShape(Capsule())
            .accessibilityLabel("Read-only trading foundation")

            Button {
                isInstrumentQuickSearchPresented = true
            } label: {
                HStack(spacing: 10) {
                    Label("Search instruments", systemImage: "magnifyingglass")
                        .font(.system(size: 11, weight: .medium))
                    Text("⌘K")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(ATHEERDesignTokens.ColorRole.panelElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.bordered)
            .tint(ATHEERDesignTokens.ColorRole.accent)
            .keyboardShortcut("k", modifiers: [.command])
            .help("Search the authenticated instrument catalogue")
            .accessibilityIdentifier("navigation.instrument-quick-search")

            if selection != .workspace && selection != .apiConnection {
                Button {
                    selection = .apiConnection
                } label: {
                    Label("Connections", systemImage: "network")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .help("Open API connection diagnostics")
                .accessibilityIdentifier("navigation.open-connections")
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, minHeight: IPDSViewportMetrics.commandBarHeight, maxHeight: IPDSViewportMetrics.commandBarHeight)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ATHEERDesignTokens.ColorRole.separator)
                .frame(height: 1)
        }
        .accessibilityIdentifier("shell.command-bar")
    }
}

private struct SidebarNavigationButton: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .frame(width: 18)

                Text(section.title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)

                Spacer(minLength: 4)

                if isSelected {
                    Circle()
                        .fill(ATHEERDesignTokens.ColorRole.accent)
                        .frame(width: 5, height: 5)
                        .accessibilityHidden(true)
                }
            }
            .foregroundColor(
                isSelected
                    ? ATHEERDesignTokens.ColorRole.primaryText
                    : ATHEERDesignTokens.ColorRole.secondaryText
            )
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        isSelected
                            ? ATHEERDesignTokens.ColorRole.accent.opacity(0.13)
                            : Color.clear
                    )
            }
            .overlay(alignment: .leading) {
                if isSelected {
                    Capsule()
                        .fill(ATHEERDesignTokens.ColorRole.accent)
                        .frame(width: 3, height: 20)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityIdentifier("navigation.section.\(section.id)")
        .help(section.title)
    }
}
