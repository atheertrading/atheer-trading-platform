import SwiftUI

@MainActor
struct MarketExplorerView: View {
    @StateObject private var model: MarketExplorerViewModel
    @ObservedObject private var streamModel: MarketDataStreamViewModel
    let onOpenAPIConnection: () -> Void
    let onOpenChart: (String) -> Void

    init(
        client: MarketSearchClient,
        streamModel: MarketDataStreamViewModel,
        onOpenAPIConnection: @escaping () -> Void,
        onOpenChart: @escaping (String) -> Void = { _ in }
    ) {
        _model = StateObject(wrappedValue: MarketExplorerViewModel(client: client))
        _streamModel = ObservedObject(wrappedValue: streamModel)
        self.onOpenAPIConnection = onOpenAPIConnection
        self.onOpenChart = onOpenChart
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ATHEERDesignTokens.Spacing.section) {
                header
                connectionPanel
                searchPanel
                resultsPanel
                streamPanel
                integrationBoundary
            }
            .padding(ATHEERDesignTokens.Spacing.page)
            .frame(maxWidth: 1120, alignment: .leading)
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
        .background(ATHEERDesignTokens.ColorRole.canvas)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Market Explorer")
                        .font(ATHEERDesignTokens.Typography.screenTitle)
                    Text("Discover instruments from the authenticated Capital.com DEMO market catalogue.")
                        .font(ATHEERDesignTokens.Typography.body)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("DEMO")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(ATHEERDesignTokens.ColorRole.attention)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ATHEERDesignTokens.ColorRole.attention.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var connectionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Backend Market Data", systemImage: "server.rack")
                    .font(ATHEERDesignTokens.Typography.panelTitle)
                Spacer()
                Button(action: onOpenAPIConnection) {
                    Label("API Diagnostics", systemImage: "network")
                }
                .buttonStyle(.borderless)
                Button {
                    Task { await model.refreshBackendStatus() }
                } label: {
                    Label("Refresh Status", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(model.state == .searching)
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 112), alignment: .leading)],
                alignment: .leading,
                spacing: 14
            ) {
                statusMetric(
                    title: "PROVIDER",
                    value: model.backendStatus?.provider.uppercased() ?? "UNAVAILABLE"
                )
                statusMetric(
                    title: "ENVIRONMENT",
                    value: model.backendStatus?.environment ?? "—",
                    tint: ATHEERDesignTokens.ColorRole.attention
                )
                statusMetric(
                    title: "REST SESSION",
                    value: model.backendStatus?.state.displayLabel ?? "UNKNOWN",
                    tint: model.backendStatus?.state == .connected
                        ? ATHEERDesignTokens.ColorRole.success
                        : ATHEERDesignTokens.ColorRole.attention
                )
                statusMetric(
                    title: "STREAMING",
                    value: model.backendStatus?.streaming?.state.displayLabel ?? "UNKNOWN",
                    tint: streamingTint
                )
                statusMetric(
                    title: "SUBSCRIPTIONS",
                    value: "\(model.backendStatus?.streaming?.activeInstrumentCount ?? 0)/40",
                    tint: .secondary
                )
                statusMetric(
                    title: "TRADING",
                    value: "DISABLED",
                    tint: .secondary
                )
            }

            if model.backendStatus?.state != .connected {
                Label(
                    "Instrument search requires an active backend DEMO REST session. Credentials are stored in macOS Keychain and provisioned over authenticated private IPC; provider session tokens remain backend-only.",
                    systemImage: "info.circle"
                )
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(ATHEERDesignTokens.ColorRole.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("INSTRUMENT SEARCH")
                .font(ATHEERDesignTokens.Typography.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search by instrument name or provider search term", text: $model.searchTerm)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task { await model.search() }
                    }
                    .accessibilityLabel("Search Capital.com DEMO instruments")
                if !model.searchTerm.isEmpty {
                    Button {
                        model.searchTerm = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear instrument search")
                }
                Button {
                    Task { await model.search() }
                } label: {
                    if model.state == .searching {
                        ProgressView()
                            .controlSize(.small)
                        Text("Searching")
                    } else {
                        Label("Search", systemImage: "arrow.right")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(ATHEERDesignTokens.ColorRole.teal)
                .disabled(!model.canSearch)
            }
            .padding(12)
            .background(ATHEERDesignTokens.ColorRole.panelElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Text("Read-only REST catalogue search. Search results are instrument metadata, not live quotes.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer(minLength: 8)
                Text("\(model.searchTerm.count)/100")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(model.searchTerm.count > 100
                        ? ATHEERDesignTokens.ColorRole.attention
                        : .secondary)
                    .accessibilityLabel("Search query length: \(model.searchTerm.count) of 100 characters")
            }
        }
        .padding(16)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var resultsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("INSTRUMENTS")
                    .font(ATHEERDesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if !model.results.isEmpty {
                    Text("\(model.results.count) results")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }

            switch model.state {
            case .idle:
                emptyState(
                    title: "Search the instrument catalogue",
                    message: "Enter an instrument name or symbol to retrieve provider-backed DEMO catalogue results.",
                    symbol: "magnifyingglass"
                )
            case .searching:
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Querying Capital.com DEMO market catalogue…")
                        .font(ATHEERDesignTokens.Typography.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
            case .results:
                VStack(spacing: 0) {
                    resultHeader
                    ForEach(model.results.indices, id: \.self) { index in
                        instrumentRow(model.results[index])
                        if index < model.results.count - 1 {
                            Divider().overlay(ATHEERDesignTokens.ColorRole.separator)
                        }
                    }
                }
                .background(ATHEERDesignTokens.ColorRole.panel)
                .clipShape(RoundedRectangle(cornerRadius: 9))
            case .empty:
                emptyState(
                    title: "No matching instruments",
                    message: "The provider returned no instruments for this search term.",
                    symbol: "line.3.horizontal.decrease.circle"
                )
            case .unavailable(let message):
                emptyState(
                    title: "Market search unavailable",
                    message: message,
                    symbol: "exclamationmark.triangle"
                )
            case .failed(let message):
                emptyState(
                    title: "Search failed",
                    message: message,
                    symbol: "xmark.octagon"
                )
            }
        }
    }

    private var resultHeader: some View {
        HStack(spacing: 12) {
            Text("INSTRUMENT")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("EPIC")
                .frame(width: 150, alignment: .leading)
            Text("MARKET STATUS")
                .frame(width: 150, alignment: .leading)
            Text("CURRENCY")
                .frame(width: 90, alignment: .leading)
            Text("MONITOR")
                .frame(width: 96, alignment: .trailing)
        }
        .font(.system(size: 9, weight: .semibold))
        .tracking(0.6)
        .foregroundColor(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(ATHEERDesignTokens.ColorRole.panelElevated)
    }

    private func instrumentRow(_ instrument: MarketInstrumentSummary) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(instrument.name ?? instrument.epic)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text("Capital.com · DEMO")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(instrument.epic)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .frame(width: 150, alignment: .leading)
                .textSelection(.enabled)

            Text(instrument.marketStatus ?? "Not supplied")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 150, alignment: .leading)

            Text(instrument.currency ?? "—")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .frame(width: 90, alignment: .leading)

            Button {
                streamModel.toggleSelection(instrument.epic)
            } label: {
                Label(
                    streamModel.isSelected(instrument.epic) ? "Selected" : "Monitor",
                    systemImage: streamModel.isSelected(instrument.epic)
                        ? "checkmark.circle.fill"
                        : "plus.circle"
                )
                .font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .disabled(!streamModel.canSelect(instrument.epic))
            .frame(width: 96, alignment: .trailing)
            .help("Add or remove this instrument from the live quote monitor")
            .accessibilityLabel(
                streamModel.isSelected(instrument.epic)
                    ? "Remove \(instrument.epic) from live quote monitor"
                    : "Add \(instrument.epic) to live quote monitor"
            )

            Button {
                onOpenChart(instrument.epic)
            } label: {
                Label("Chart", systemImage: "chart.xyaxis.line")
                    .font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .frame(width: 62, alignment: .trailing)
            .help("Open historical DEMO candles for this instrument")
            .accessibilityLabel("Open chart for \(instrument.epic)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
    }

    private var streamPanel: some View {
        VStack(alignment: .leading, spacing: ATHEERDesignTokens.Spacing.standard) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIVE QUOTE MONITOR")
                        .font(ATHEERDesignTokens.Typography.panelTitle)
                        .tracking(0.8)
                    Text("Selected instruments: \(streamModel.selectedCount)/40")
                        .font(ATHEERDesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Clear Selection") {
                    streamModel.clearSelection()
                }
                .buttonStyle(.bordered)
                .disabled(streamModel.selectedEpics.isEmpty)
                .accessibilityLabel("Clear all monitored instruments")

                Button {
                    if streamModel.isMonitoring {
                        streamModel.stopMonitoring()
                        Task { await model.refreshBackendStatus() }
                    } else {
                        streamModel.startMonitoring()
                    }
                } label: {
                    Label(
                        streamModel.isMonitoring ? "Stop Monitoring" : "Start Monitoring",
                        systemImage: streamModel.isMonitoring ? "stop.fill" : "waveform.path"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(ATHEERDesignTokens.ColorRole.teal)
                .disabled(
                    !streamModel.isMonitoring &&
                    (!streamModel.canStartMonitoring || model.backendStatus?.state != .connected)
                )
                .accessibilityLabel(streamModel.isMonitoring ? "Stop live quote monitoring" : "Start live quote monitoring")
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 145), alignment: .leading)],
                alignment: .leading,
                spacing: ATHEERDesignTokens.Spacing.standard
            ) {
                statusMetric(
                    title: "STREAM",
                    value: streamModel.connectionState.displayLabel,
                    tint: streamStatusTint
                )
                statusMetric(
                    title: "PROVIDER CONFIRMED",
                    value: "\(streamModel.status?.activeInstrumentCount ?? model.backendStatus?.streaming?.activeInstrumentCount ?? 0)/40",
                    tint: streamStatusTint
                )
                statusMetric(title: "LAST MESSAGE", value: lastMessageLabel)
                statusMetric(
                    title: "INVALID / OUT OF ORDER / DUPLICATE",
                    value: "\(streamModel.status?.invalidQuoteCount ?? model.backendStatus?.streaming?.invalidQuoteCount ?? 0) / \(streamModel.status?.outOfOrderQuoteCount ?? model.backendStatus?.streaming?.outOfOrderQuoteCount ?? 0) / \(streamModel.status?.duplicateQuoteCount ?? model.backendStatus?.streaming?.duplicateQuoteCount ?? 0)"
                )
            }

            if let error = streamModel.lastError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(ATHEERDesignTokens.Typography.caption)
                    .foregroundColor(ATHEERDesignTokens.ColorRole.attention)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if streamModel.quotes.isEmpty {
                Text(streamModel.isMonitoring
                     ? "Waiting for verified Capital.com DEMO quote events…"
                     : "Select instruments from the catalogue, then start monitoring to receive timestamped broker quotes.")
                    .font(ATHEERDesignTokens.Typography.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, ATHEERDesignTokens.Spacing.standard)
            } else {
                ScrollView(.horizontal) {
                    VStack(spacing: 0) {
                        quoteHeader
                        ForEach(streamModel.quotes.values.sorted { $0.id < $1.id }) { snapshot in
                            quoteRow(snapshot)
                        }
                    }
                    .frame(minWidth: 760, alignment: .leading)
                }
                .accessibilityLabel("Live market quote table")
            }

            Text("Display-only market data. Quotes are normal through 5s, aging through 10s, block new automated entries above 10s, and are stale above 15s. Position management remains a separate risk decision; this monitor has no order or execution authority.")
                .font(ATHEERDesignTokens.Typography.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(ATHEERDesignTokens.ColorRole.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .accessibilityHidden(true)
    }

    private func quoteRow(_ snapshot: MarketDataStreamQuoteSnapshot) -> some View {
        let quote = snapshot.quote
        let quality = snapshot.effectiveFreshnessState
        let instrumentName = model.results.first(where: { $0.epic == quote.instrumentId })?.name ?? quote.instrumentId
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(instrumentName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
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
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ATHEERDesignTokens.ColorRole.separator)
                .frame(height: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(instrumentName), bid \(formatPrice(quote.bid)), ask \(formatPrice(quote.ask)), spread \(formatPrice(quote.ask - quote.bid)), age \(formatAge(snapshot.ageMilliseconds)), quality \(quality.rawValue)"
        )
    }

    private var lastMessageLabel: String {
        if let timestamp = streamModel.status?.lastMessageAtMs {
            return Date(timeIntervalSince1970: Double(timestamp) / 1_000)
                .formatted(date: .omitted, time: .standard)
        }
        if let timestamp = model.backendStatus?.streaming?.lastMessageAtMs {
            return Date(timeIntervalSince1970: timestamp / 1_000)
                .formatted(date: .omitted, time: .standard)
        }
        return "—"
    }

    private var streamStatusTint: Color {
        switch streamModel.connectionState {
        case .connected:
            return ATHEERDesignTokens.ColorRole.success
        case .connecting, .degraded:
            return ATHEERDesignTokens.ColorRole.attention
        case .disconnected:
            return .secondary
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
        case .aging:
            return ATHEERDesignTokens.ColorRole.attention
        case .entryBlocked, .stale:
            return ATHEERDesignTokens.ColorRole.danger
        case .invalid:
            return ATHEERDesignTokens.ColorRole.danger
        }
    }

    private var integrationBoundary: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Data and execution boundary")
                    .font(.system(size: 11, weight: .semibold))
                Text("Catalogue search is metadata-only. Live bid/ask values appear only from timestamped DEMO stream events with provider freshness classification. Charting, strategy input, order intent, and execution remain separate governed milestones; no order or dealing action is exposed.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ATHEERDesignTokens.ColorRole.panelElevated)
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private var streamingTint: Color {
        switch model.backendStatus?.streaming?.state {
        case .some(.connected):
            return ATHEERDesignTokens.ColorRole.success
        case .some(.connecting), .some(.degraded):
            return ATHEERDesignTokens.ColorRole.attention
        case .some(.disconnected), .none:
            return .secondary
        }
    }

    private func statusMetric(title: String, value: String, tint: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(tint)
                .lineLimit(1)
        }
        .frame(maxWidth: 150, alignment: .leading)
    }

    private func emptyState(title: String, message: String, symbol: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundColor(.secondary)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
            Text(message)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 440)
        }
        .frame(maxWidth: .infinity, minHeight: 132)
        .padding(14)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}
