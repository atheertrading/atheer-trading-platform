import SwiftUI

/// Live, read-only Market Watch panel shared with the full Market Explorer screen.
/// Panel visibility does not own or cancel the app-scoped market-data stream.
struct MarketWatchPanelView: View {
    @ObservedObject var model: MarketExplorerViewModel
    @ObservedObject var watchlistStore: MarketWatchlistStore
    let onOpenMarkets: () -> Void
    let onOpenAPIConnection: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            searchControl

            if let recoveryMessage = watchlistStore.recoveryMessage {
                messageRow(recoveryMessage, symbol: "exclamationmark.triangle", tint: ATHEERDesignTokens.ColorRole.attention)
            }
            if let errorMessage = watchlistStore.errorMessage {
                messageRow(errorMessage, symbol: "exclamationmark.triangle", tint: ATHEERDesignTokens.ColorRole.attention)
            }
            if let streamError = model.streamingError {
                messageRow(streamError, symbol: "waveform.path", tint: ATHEERDesignTokens.ColorRole.attention)
            }

            watchlistContent

            HStack(spacing: 8) {
                Text("\(watchlistStore.epics.count)/\(MarketWatchlistStore.maximumInstrumentCount) WATCHLIST")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(model.selectedEpics.count) STREAM SUBSCRIPTIONS")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(ATHEERDesignTokens.ColorRole.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "list.bullet.rectangle")
                .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Market Watch")
                    .font(ATHEERDesignTokens.Typography.panelTitle)
                Text("Capital.com · DEMO · Read only")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 4)
            Text(model.streamingState.rawValue.uppercased())
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(streamingTint)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(streamingTint.opacity(0.10))
                .clipShape(Capsule())
            Button {
                Task { await model.refreshBackendStatus() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh authenticated DEMO market-data status")
            .accessibilityLabel("Refresh market-data status")
            Button {
                if model.isStreamingRequested {
                    model.stopStream()
                } else {
                    for epic in watchlistStore.epics where !model.isSubscribed(to: epic) {
                        model.toggleStreamSubscription(for: epic)
                    }
                    model.startStreaming()
                }
            } label: {
                Label(
                    model.isStreamingRequested ? "Stop" : "Stream",
                    systemImage: model.isStreamingRequested ? "stop.fill" : "waveform"
                )
                .font(.system(size: 9, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .disabled(!model.isStreamingRequested && watchlistStore.epics.isEmpty && model.selectedEpics.isEmpty)
            .help(model.isStreamingRequested ? "Stop market-data streaming" : "Stream watchlist instruments")
            Button(action: onOpenAPIConnection) {
                Image(systemName: "network")
            }
            .buttonStyle(.borderless)
            .help("Open API connection diagnostics")
            .accessibilityLabel("Open API diagnostics")
            Button(action: onOpenMarkets) {
                Image(systemName: "arrow.up.right.square")
            }
            .buttonStyle(.borderless)
            .help("Open full Market Explorer")
            .accessibilityLabel("Open Market Explorer")
        }
    }

    private var searchControl: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search instruments", text: $model.searchTerm)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .onSubmit { Task { await model.search() } }
                    .accessibilityLabel("Search DEMO market instruments")
                Button {
                    Task { await model.search() }
                } label: {
                    if model.state == .searching {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(ATHEERDesignTokens.ColorRole.teal)
                .disabled(!model.canSearch)
                .help("Search provider instrument catalogue")
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(ATHEERDesignTokens.ColorRole.panelElevated)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            if model.state == .results && !model.results.isEmpty {
                VStack(spacing: 0) {
                    ForEach(model.results.prefix(4)) { instrument in
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(instrument.instrumentName ?? instrument.epic)
                                    .font(.system(size: 10, weight: .semibold))
                                    .lineLimit(1)
                                Text(instrument.epic)
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Spacer(minLength: 4)
                            Button {
                                _ = watchlistStore.add(instrument.epic)
                            } label: {
                                Label(
                                    watchlistStore.contains(instrument.epic) ? "Saved" : "Add",
                                    systemImage: watchlistStore.contains(instrument.epic) ? "bookmark.fill" : "bookmark"
                                )
                                .font(.system(size: 9, weight: .medium))
                            }
                            .buttonStyle(.borderless)
                            .disabled(
                                watchlistStore.contains(instrument.epic) ||
                                watchlistStore.epics.count >= MarketWatchlistStore.maximumInstrumentCount
                            )
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                        if instrument.id != model.results.prefix(4).last?.id {
                            Divider().overlay(ATHEERDesignTokens.ColorRole.separator)
                        }
                    }
                }
                .background(ATHEERDesignTokens.ColorRole.panelElevated)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else if case .failed(let message) = model.state {
                messageRow(message, symbol: "exclamationmark.triangle", tint: ATHEERDesignTokens.ColorRole.attention)
            } else if case .unavailable(let message) = model.state {
                messageRow(message, symbol: "wifi.slash", tint: ATHEERDesignTokens.ColorRole.attention)
            }
        }
    }

    @ViewBuilder
    private var watchlistContent: some View {
        if watchlistStore.epics.isEmpty {
            VStack(spacing: 7) {
                Image(systemName: "waveform.path")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.secondary)
                Text("Watchlist is empty")
                    .font(.system(size: 11, weight: .semibold))
                Text("Search the authenticated DEMO catalogue and add instruments to monitor.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("Open Market Explorer", action: onOpenMarkets)
                    .buttonStyle(.link)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity, minHeight: 112)
        } else {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Text("INSTRUMENT")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("BID")
                        .frame(width: 68, alignment: .trailing)
                    Text("ASK")
                        .frame(width: 68, alignment: .trailing)
                    Text("AGE")
                        .frame(width: 46, alignment: .trailing)
                    Text("FEED")
                        .frame(width: 54, alignment: .trailing)
                }
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 7)

                ForEach(watchlistStore.epics, id: \.self) { epic in
                    watchlistRow(epic)
                    if epic != watchlistStore.epics.last {
                        Divider().overlay(ATHEERDesignTokens.ColorRole.separator)
                    }
                }
            }
            .background(ATHEERDesignTokens.ColorRole.panelElevated)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }

    private func watchlistRow(_ epic: String) -> some View {
        let quote = model.streamingQuotes[epic]
        let instrument = model.results.first(where: { $0.epic == epic })
        let isSubscribed = model.isSubscribed(to: epic)

        return HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(instrument?.instrumentName ?? epic)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                Text(epic)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(quote.map { $0.bid.formatted(.number.precision(.fractionLength(0...5))) } ?? "—")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(quote == nil ? .secondary : quote?.freshness.state == "fresh"
                    ? ATHEERDesignTokens.ColorRole.success
                    : ATHEERDesignTokens.ColorRole.attention)
                .frame(width: 68, alignment: .trailing)

            Text(quote.map { $0.ask.formatted(.number.precision(.fractionLength(0...5))) } ?? "—")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(quote == nil ? .secondary : ATHEERDesignTokens.ColorRole.success)
                .frame(width: 68, alignment: .trailing)

            Text(quote.map { String(format: "%.1f", $0.currentAgeMilliseconds / 1_000) } ?? "—")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 46, alignment: .trailing)

            Button {
                if isSubscribed {
                    model.toggleStreamSubscription(for: epic)
                } else {
                    model.toggleStreamSubscription(for: epic)
                    if !model.isStreamingRequested { model.startStreaming() }
                }
            } label: {
                Text(isSubscribed ? "ON" : "ADD")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
            }
            .buttonStyle(.borderless)
            .frame(width: 54, alignment: .trailing)
            .accessibilityLabel(isSubscribed ? "Unsubscribe \(epic) from streaming" : "Subscribe \(epic) to streaming")

            Button {
                _ = watchlistStore.remove(epic)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Remove \(epic) from watchlist")
            .accessibilityLabel("Remove \(epic) from watchlist")
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
    }

    private var streamingTint: Color {
        switch model.streamingState {
        case .connected:
            return ATHEERDesignTokens.ColorRole.success
        case .connecting, .degraded:
            return ATHEERDesignTokens.ColorRole.attention
        case .disconnected:
            return .secondary
        }
    }

    private func messageRow(_ message: String, symbol: String, tint: Color) -> some View {
        Label(message, systemImage: symbol)
            .font(.system(size: 9))
            .foregroundColor(tint)
            .fixedSize(horizontal: false, vertical: true)
    }
}
