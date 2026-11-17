import SwiftUI

struct MarketExplorerView: View {
    @StateObject private var model: MarketExplorerViewModel
    let onOpenAPIConnection: () -> Void

    init(
        client: MarketSearchClient = URLSessionMarketSearchClient(),
        streamClient: MarketDataStreamClient = URLSessionMarketDataStreamClient(),
        onOpenAPIConnection: @escaping () -> Void
    ) {
        _model = StateObject(wrappedValue: MarketExplorerViewModel(
            client: client,
            streamClient: streamClient
        ))
        self.onOpenAPIConnection = onOpenAPIConnection
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ATHEERDesignTokens.Spacing.section) {
                header
                connectionPanel
                searchPanel
                resultsPanel
                integrationBoundary
            }
            .padding(ATHEERDesignTokens.Spacing.page)
            .frame(maxWidth: 1120, alignment: .leading)
        }
        .task {
            await model.refreshBackendStatus()
            model.resumeStreamIfNeeded()
        }
        .onDisappear {
            model.pauseStream()
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

                Button {
                    if model.isStreamingRequested {
                        model.stopStream()
                    } else {
                        model.startStreaming()
                    }
                } label: {
                    Label(
                        model.isStreamingRequested ? "Stop Stream" : "Start Stream",
                        systemImage: model.isStreamingRequested ? "stop.fill" : "waveform"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(ATHEERDesignTokens.ColorRole.teal)
                .disabled(!model.isStreamingRequested && !model.canStartStreaming)
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
                    value: model.backendStatus?.state.rawValue.uppercased() ?? "UNKNOWN",
                    tint: model.backendStatus?.state == .connected
                        ? ATHEERDesignTokens.ColorRole.success
                        : ATHEERDesignTokens.ColorRole.attention
                )
                statusMetric(
                    title: "STREAMING",
                    value: model.streamingState.rawValue.uppercased(),
                    tint: model.streamingState == .connected
                        ? ATHEERDesignTokens.ColorRole.success
                        : model.streamingState == .degraded
                            ? ATHEERDesignTokens.ColorRole.attention
                            : .secondary
                )
                statusMetric(
                    title: "SUBSCRIBED",
                    value: "\(model.selectedEpics.count)/40"
                )
                statusMetric(
                    title: "TRADING",
                    value: "DISABLED",
                    tint: .secondary
                )
            }

            if !model.selectedEpics.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Text("SELECTED: " + model.selectedEpics.sorted().joined(separator: ", "))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Clear Selection") {
                        model.clearStreamSelection()
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 10, weight: .medium))
                }
            }

            if let message = model.streamingError {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 11))
                    .foregroundColor(ATHEERDesignTokens.ColorRole.attention)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if model.backendStatus?.state != .connected {
                Label(
                    "Instrument search requires an active backend DEMO REST session. The app's Keychain broker session is separate and is not automatically transferred to the backend.",
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
                Text("Read-only catalogue search. Select instruments below to receive timestamped DEMO Bid/Ask quotes.")
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
                    Text("\(model.results.count) results · \(model.selectedEpics.count) streaming")
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
                .frame(width: 70, alignment: .leading)
            Text("LIVE BID")
                .frame(width: 88, alignment: .trailing)
            Text("LIVE ASK")
                .frame(width: 88, alignment: .trailing)
            Text("QUOTE AGE")
                .frame(width: 72, alignment: .trailing)
            Text("STREAM")
                .frame(width: 76, alignment: .trailing)
        }
        .font(.system(size: 9, weight: .semibold))
        .tracking(0.6)
        .foregroundColor(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(ATHEERDesignTokens.ColorRole.panelElevated)
    }

    private func instrumentRow(_ instrument: MarketSearchInstrument) -> some View {
        let quote = model.streamingQuotes[instrument.epic]
        let isSubscribed = model.isSubscribed(to: instrument.epic)

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(instrument.instrumentName ?? instrument.epic)
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
                .frame(width: 70, alignment: .leading)

            Text(quote.map { $0.bid.formatted(.number.precision(.fractionLength(0...5))) } ?? "—")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(quote == nil ? .secondary : ATHEERDesignTokens.ColorRole.success)
                .frame(width: 88, alignment: .trailing)

            Text(quote.map { $0.ask.formatted(.number.precision(.fractionLength(0...5))) } ?? "—")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(quote == nil ? .secondary : ATHEERDesignTokens.ColorRole.success)
                .frame(width: 88, alignment: .trailing)

            VStack(alignment: .trailing, spacing: 2) {
                Text(quote.map { String(format: "%.1fs", $0.currentAgeMilliseconds / 1_000) } ?? "—")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(quote?.freshness.state == "fresh"
                        ? ATHEERDesignTokens.ColorRole.success
                        : ATHEERDesignTokens.ColorRole.attention)
                Text(quote?.providerDate.formatted(date: .omitted, time: .standard) ?? (isSubscribed ? "WAITING" : ""))
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .frame(width: 72, alignment: .trailing)

            Button {
                model.toggleStreamSubscription(for: instrument.epic)
            } label: {
                Label(
                    isSubscribed ? "REMOVE" : "SELECT",
                    systemImage: isSubscribed ? "minus.circle" : "plus.circle"
                )
                .labelStyle(.titleAndIcon)
                .font(.system(size: 9, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .disabled(!model.canSubscribe(to: instrument.epic))
            .frame(width: 76, alignment: .trailing)
            .accessibilityLabel(
                isSubscribed
                    ? "Remove \(instrument.epic) from live quote selection"
                    : "Select \(instrument.epic) for live quote streaming"
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
    }

    private var integrationBoundary: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Data and execution boundary")
                    .font(.system(size: 11, weight: .semibold))
                Text("Bid/Ask values are shown only after an explicit instrument subscription and a timestamped Capital.com DEMO quote. Streaming is read-only; no order or dealing action is exposed. Charting and RiskEngine integration remain separate qualification milestones.")
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
