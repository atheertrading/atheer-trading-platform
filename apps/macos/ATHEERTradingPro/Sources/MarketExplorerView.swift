import SwiftUI

@MainActor
struct MarketExplorerView: View {
    @StateObject private var model: MarketExplorerViewModel
    @StateObject private var streamModel: MarketDataStreamViewModel
    private let onOpenAPIConnection: () -> Void

    init(
        client: MarketSearchClient,
        streamClient: MarketDataStreamClient,
        onOpenAPIConnection: @escaping () -> Void
    ) {
        _model = StateObject(wrappedValue: MarketExplorerViewModel(client: client))
        _streamModel = StateObject(wrappedValue: MarketDataStreamViewModel(client: streamClient))
        self.onOpenAPIConnection = onOpenAPIConnection
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                backendStatus
                searchPanel
                resultsPanel
                streamPanel
                integrationBoundary
            }
            .padding(24)
            .frame(maxWidth: 1120, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .task {
            await model.refreshBackendStatus()
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 15_000_000_000)
                } catch {
                    return
                }
                await model.refreshBackendStatus()
            }
        }
        .onChange(of: model.backendStatus?.state) { newState in
            if newState != .connected {
                streamModel.stopMonitoring()
            }
        }
        .onDisappear {
            streamModel.stopMonitoring(clearQuotes: true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MARKET EXPLORER")
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundColor(ATHEERDesignTokens.ColorRole.primaryText)
            Text("Search broker instruments, select markets, and monitor verified DEMO quotes.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }

    private var backendStatus: some View {
        HStack(spacing: 16) {
            statusMetric("PROVIDER", value: model.backendStatus?.provider.uppercased() ?? "—")
            statusMetric("ENVIRONMENT", value: model.backendStatus?.environment ?? "—")
            statusMetric("REST SESSION", value: model.backendStatus?.state.displayLabel ?? "UNKNOWN")
            statusMetric(
                "WEBSOCKET",
                value: model.backendStatus?.streaming?.state.displayLabel ?? "UNKNOWN"
            )
            statusMetric(
                "SUBSCRIPTIONS",
                value: "\(model.backendStatus?.streaming?.activeInstrumentCount ?? 0)/40"
            )
            Spacer(minLength: 0)
            Button {
                Task { await model.refreshBackendStatus() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh backend status")
        }
        .padding(14)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(ATHEERDesignTokens.ColorRole.border, lineWidth: 1)
        }
    }

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("INSTRUMENT SEARCH")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.1)
                    .foregroundColor(.secondary)
                Spacer()
                Text("CAPITAL.COM DEMO")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search by instrument name or epic", text: $model.searchTerm)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task { await model.search() }
                    }
                Button("Search") {
                    Task { await model.search() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isSearching || !model.canSearch)
            }

            if let message = model.errorMessage {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 12))
                    .foregroundColor(ATHEERDesignTokens.ColorRole.warning)
            }
        }
        .padding(16)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(ATHEERDesignTokens.ColorRole.border, lineWidth: 1)
        }
    }

    private var resultsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("BROKER INSTRUMENTS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.1)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(model.results.count) RESULTS")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            if model.isSearching {
                ProgressView("Searching Capital.com DEMO…")
                    .controlSize(.small)
                    .padding(.vertical, 12)
            } else if model.results.isEmpty {
                emptyResults
            } else {
                resultHeader
                ForEach(model.results) { instrument in
                    instrumentRow(instrument)
                }
            }
        }
        .padding(16)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(ATHEERDesignTokens.ColorRole.border, lineWidth: 1)
        }
    }

    private var emptyResults: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No instruments loaded")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ATHEERDesignTokens.ColorRole.primaryText)
            Text("Search the connected DEMO catalogue. No synthetic instruments or prices are generated.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
    }

    private var resultHeader: some View {
        HStack(spacing: 12) {
            Text("INSTRUMENT").frame(maxWidth: .infinity, alignment: .leading)
            Text("EPIC").frame(width: 150, alignment: .leading)
            Text("STATUS").frame(width: 100, alignment: .leading)
            Text("CURRENCY").frame(width: 75, alignment: .leading)
            Text("MONITOR").frame(width: 96, alignment: .trailing)
        }
        .font(.system(size: 9, weight: .bold))
        .tracking(0.8)
        .foregroundColor(.secondary)
        .padding(.vertical, 8)
    }

    private func instrumentRow(_ instrument: MarketInstrumentSummary) -> some View {
        HStack(spacing: 12) {
            Text(instrument.name ?? instrument.epic)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ATHEERDesignTokens.ColorRole.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            Text(instrument.epic)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 150, alignment: .leading)
                .lineLimit(1)
            Text(instrument.marketStatus ?? "UNKNOWN")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
                .lineLimit(1)
            Text(instrument.currency ?? "—")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 75, alignment: .leading)
            Button {
                streamModel.toggleSelection(instrument.epic)
            } label: {
                Label(
                    streamModel.isSelected(instrument.epic) ? "Selected" : "Monitor",
                    systemImage: streamModel.isSelected(instrument.epic) ? "checkmark.circle.fill" : "plus.circle"
                )
                .font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .disabled(!streamModel.canSelect(instrument.epic))
            .frame(width: 96, alignment: .trailing)
            .help("Add or remove this instrument from the live quote monitor")
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ATHEERDesignTokens.ColorRole.border)
                .frame(height: 1)
        }
    }

    private var streamPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("LIVE QUOTE MONITOR")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.1)
                        .foregroundColor(.secondary)
                    Text("Selected instruments: \(streamModel.selectedCount)/40")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Clear") {
                    streamModel.clearSelection()
                }
                .buttonStyle(.bordered)
                .disabled(streamModel.selectedEpics.isEmpty)
                Button(streamModel.isMonitoring ? "Stop" : "Start Monitoring") {
                    if streamModel.isMonitoring {
                        streamModel.stopMonitoring()
                        Task { await model.refreshBackendStatus() }
                    } else {
                        streamModel.startMonitoring()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    !streamModel.isMonitoring &&
                    (!streamModel.canStartMonitoring || model.backendStatus?.state != .connected)
                )
            }

            HStack(spacing: 18) {
                statusMetric("STREAM", value: streamModel.connectionState.displayLabel)
                statusMetric(
                    "ACTIVE",
                    value: "\(streamModel.status?.activeInstrumentCount ?? model.backendStatus?.streaming?.activeInstrumentCount ?? 0)/40"
                )
                statusMetric(
                    "LAST MESSAGE",
                    value: lastMessageLabel
                )
                statusMetric(
                    "INVALID / OUT OF ORDER / DUPLICATE",
                    value: "\(streamModel.status?.invalidQuoteCount ?? model.backendStatus?.streaming?.invalidQuoteCount ?? 0) / \(streamModel.status?.outOfOrderQuoteCount ?? model.backendStatus?.streaming?.outOfOrderQuoteCount ?? 0) / \(streamModel.status?.duplicateQuoteCount ?? model.backendStatus?.streaming?.duplicateQuoteCount ?? 0)"
                )
                Spacer(minLength: 0)
            }

            if let error = streamModel.lastError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 11))
                    .foregroundColor(ATHEERDesignTokens.ColorRole.warning)
            }

            if streamModel.quotes.isEmpty {
                Text(streamModel.isMonitoring
                     ? "Waiting for verified Capital.com DEMO quote events…"
                     : "Select instruments above, then start monitoring to receive live broker quotes.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)
            } else {
                quoteHeader
                ForEach(streamModel.quotes.values.sorted { $0.id < $1.id }) { snapshot in
                    quoteRow(snapshot)
                }
            }

            Text("Display-only market data. Freshness is provider-evaluated; this monitor has no order or execution authority.")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(ATHEERDesignTokens.ColorRole.border, lineWidth: 1)
        }
    }

    private var quoteHeader: some View {
        HStack(spacing: 12) {
            Text("INSTRUMENT / EPIC").frame(maxWidth: .infinity, alignment: .leading)
            Text("BID").frame(width: 105, alignment: .trailing)
            Text("ASK").frame(width: 105, alignment: .trailing)
            Text("SPREAD").frame(width: 90, alignment: .trailing)
            Text("AGE").frame(width: 80, alignment: .trailing)
            Text("QUALITY").frame(width: 90, alignment: .trailing)
        }
        .font(.system(size: 9, weight: .bold))
        .tracking(0.8)
        .foregroundColor(.secondary)
        .padding(.vertical, 8)
    }

    private func quoteRow(_ snapshot: MarketDataStreamQuoteSnapshot) -> some View {
        let quote = snapshot.quote
        let quality = snapshot.effectiveFreshnessState
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.results.first(where: { $0.epic == quote.instrumentId })?.name ?? quote.instrumentId)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(ATHEERDesignTokens.ColorRole.primaryText)
                    .lineLimit(1)
                Text(quote.instrumentId)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(formatPrice(quote.bid))
                .frame(width: 105, alignment: .trailing)
            Text(formatPrice(quote.ask))
                .frame(width: 105, alignment: .trailing)
            Text(formatPrice(quote.ask - quote.bid))
                .frame(width: 90, alignment: .trailing)
            Text(formatAge(snapshot.ageMilliseconds))
                .frame(width: 80, alignment: .trailing)
            Text(quality.rawValue.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(qualityColor(quality))
                .frame(width: 90, alignment: .trailing)
        }
        .font(.system(size: 11, design: .monospaced))
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ATHEERDesignTokens.ColorRole.border)
                .frame(height: 1)
        }
    }

    private var integrationBoundary: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield")
                .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("INTEGRATION BOUNDARY")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.9)
                Text("Instrument search and quote streaming use the authenticated local backend and the same backend-owned Capital.com DEMO session. Provider tokens remain server-side. No mock prices, order submission, or LIVE trading are available in this module.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Connection Settings", action: onOpenAPIConnection)
                .buttonStyle(.bordered)
        }
        .padding(14)
        .background(ATHEERDesignTokens.ColorRole.deepTeal.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var lastMessageLabel: String {
        if let timestamp = streamModel.status?.lastMessageAtMs {
            return Date(timeIntervalSince1970: Double(timestamp) / 1_000).formatted(date: .omitted, time: .standard)
        }
        if let timestamp = model.backendStatus?.streaming?.lastMessageAtMs {
            return Date(timeIntervalSince1970: timestamp / 1_000).formatted(date: .omitted, time: .standard)
        }
        return "—"
    }

    private func statusMetric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .tracking(0.7)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(ATHEERDesignTokens.ColorRole.primaryText)
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

    private func qualityColor(_ quality: MarketDataQuoteFreshnessState) -> Color {
        switch quality {
        case .fresh:
            return ATHEERDesignTokens.ColorRole.success
        case .stale:
            return ATHEERDesignTokens.ColorRole.warning
        case .invalid:
            return ATHEERDesignTokens.ColorRole.danger
        }
    }
}
