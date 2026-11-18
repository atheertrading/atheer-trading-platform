import SwiftUI

/// Command Center presentation over the runtime-owned Capital.com DEMO quote monitor.
/// This view observes the shared stream model; its appearance and disappearance do not
/// start, stop, or otherwise own the market-data subscription lifecycle.
@MainActor
struct LiveMarketWatchPanel: View {
    @ObservedObject var model: MarketDataStreamViewModel
    let onOpenMarkets: () -> Void

    private var statusTitle: String {
        if model.selectedEpics.isEmpty {
            return "NO WATCHLIST"
        }

        switch model.connectionState {
        case .connected:
            return "STREAMING"
        case .connecting:
            return "CONNECTING"
        case .degraded:
            return "DEGRADED"
        case .disconnected:
            return model.isMonitoring ? "DISCONNECTED" : "STOPPED"
        }
    }

    private var statusTint: Color {
        switch model.connectionState {
        case .connected:
            return ATHEERDesignTokens.ColorRole.success
        case .connecting, .degraded:
            return ATHEERDesignTokens.ColorRole.attention
        case .disconnected:
            return .secondary
        }
    }

    private var visibleEpics: [String] {
        Array(model.selectedEpics.sorted().prefix(5))
    }

    var body: some View {
        WorkspacePanelCard(
            title: "Market Watch",
            subtitle: "Capital.com DEMO · broker quote stream",
            symbol: "list.bullet.rectangle",
            status: statusTitle,
            statusColor: statusTint
        ) {
            VStack(alignment: .leading, spacing: 10) {
                controls

                if let error = model.lastError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(ATHEERDesignTokens.Typography.caption)
                        .foregroundColor(ATHEERDesignTokens.ColorRole.attention)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if model.selectedEpics.isEmpty {
                    emptyWatchlist
                } else if model.quotes.isEmpty {
                    waitingState
                } else {
                    quoteList
                }

                HStack(spacing: 5) {
                    Image(systemName: "shield.lefthalf.filled")
                    Text("Read-only DEMO data · no dealing or order authority")
                }
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Text("WATCHLIST  \(model.selectedCount)/40")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(.secondary)

            Spacer(minLength: 4)

            Button(action: onOpenMarkets) {
                Label("Markets", systemImage: "magnifyingglass")
            }
            .buttonStyle(.borderless)
            .help("Discover instruments and manage the watchlist")

            Button {
                if model.isMonitoring {
                    model.stopMonitoring()
                } else {
                    model.startMonitoring()
                }
            } label: {
                Label(
                    model.isMonitoring ? "Stop" : "Start",
                    systemImage: model.isMonitoring ? "stop.fill" : "waveform.path"
                )
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(ATHEERDesignTokens.ColorRole.teal)
            .disabled(!model.isMonitoring && !model.canStartMonitoring)
            .help(model.isMonitoring ? "Stop the shared quote subscription" : "Start the shared quote subscription")
        }
    }

    private var emptyWatchlist: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("No instruments selected", systemImage: "antenna.radiowaves.left.and.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            Text("Open Markets, search the authenticated DEMO catalogue, and add instruments to this watchlist.")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
    }

    private var waitingState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(model.isMonitoring ? "Waiting for timestamped broker quotes…" : "Monitoring is stopped")
                .font(.system(size: 11, weight: .semibold))
            Text(model.isMonitoring
                 ? "Selected instruments remain subscribed. No quote is displayed until a provider event is received."
                 : "Your selected instrument list is preserved. Start monitoring to request current DEMO quotes.")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
    }

    private var quoteList: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(visibleEpics, id: \.self) { epic in
                        quoteRow(for: epic)
                        if epic != visibleEpics.last {
                            Divider()
                                .overlay(ATHEERDesignTokens.ColorRole.separator)
                        }
                    }
                }
            }
            .frame(maxHeight: 250)

            if model.selectedCount > visibleEpics.count {
                Text("Showing \(visibleEpics.count) of \(model.selectedCount) selected instruments")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 5)
            }
        }
    }

    @ViewBuilder
    private func quoteRow(for epic: String) -> some View {
        if let snapshot = model.quotes[epic] {
            let quote = snapshot.quote
            let freshness = snapshot.effectiveFreshnessState

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(epic)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary)
                        Text("CAPITAL.COM · DEMO")
                            .font(.system(size: 8, weight: .medium))
                            .tracking(0.5)
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 6)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("BID  \(formatPrice(quote.bid))")
                            .foregroundColor(.primary)
                        Text("ASK  \(formatPrice(quote.ask))")
                            .foregroundColor(.primary)
                    }
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .lineLimit(1)
                }

                HStack(spacing: 10) {
                    Text("SPREAD \(formatPrice(quote.ask - quote.bid))")
                    Text("AGE \(formatAge(snapshot.ageMilliseconds))")
                    Spacer(minLength: 4)
                    Text(freshness.rawValue.uppercased())
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(freshnessTint(freshness))
                }
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)

                Text("Provider time · \(quote.providerDate.formatted(date: .omitted, time: .standard))")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "\(epic), Capital.com DEMO, bid \(formatPrice(quote.bid)), ask \(formatPrice(quote.ask)), age \(formatAge(snapshot.ageMilliseconds)), freshness \(freshness.rawValue)"
            )
        } else {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(epic)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    Text("Waiting for provider quote")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                Spacer()
                ProgressView()
                    .controlSize(.small)
            }
            .padding(.vertical, 9)
            .accessibilityElement(children: .combine)
        }
    }

    private func formatPrice(_ value: Double) -> String {
        value.formatted(.number.precision(.significantDigits(1...8)))
    }

    private func formatAge(_ milliseconds: Double?) -> String {
        guard let milliseconds, milliseconds.isFinite, milliseconds >= 0 else { return "—" }
        if milliseconds < 1_000 {
            return "\(Int(milliseconds.rounded())) ms"
        }
        if milliseconds < 60_000 {
            return String(format: "%.1f s", milliseconds / 1_000)
        }
        return String(format: "%.1f m", milliseconds / 60_000)
    }

    private func freshnessTint(_ state: MarketDataQuoteFreshnessState) -> Color {
        switch state {
        case .fresh:
            return ATHEERDesignTokens.ColorRole.success
        case .aging:
            return ATHEERDesignTokens.ColorRole.attention
        case .entryBlocked, .stale, .invalid:
            return ATHEERDesignTokens.ColorRole.danger
        }
    }
}
