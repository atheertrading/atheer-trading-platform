import SwiftUI

/// Routes a selected provider catalogue record into the existing Markets search flow.
enum InstrumentQuickSearchRouting {
    static func marketSearchTerm(for instrument: MarketInstrumentSummary) -> String {
        if let name = instrument.name?.trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            return name
        }
        return instrument.epic
    }
}

/// Global instrument discovery surface. It reuses the Markets ViewModel and its
/// authenticated, read-only MarketSearchClient instead of introducing another API path.
@MainActor
struct InstrumentQuickSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: MarketExplorerViewModel
    @FocusState private var searchFieldIsFocused: Bool

    let onSelect: (MarketInstrumentSummary) -> Void

    init(
        client: MarketSearchClient,
        onSelect: @escaping (MarketInstrumentSummary) -> Void
    ) {
        _model = StateObject(wrappedValue: MarketExplorerViewModel(client: client))
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            searchField
            Divider()
                .overlay(ATHEERDesignTokens.ColorRole.separator)
            resultsContent
            Divider()
                .overlay(ATHEERDesignTokens.ColorRole.separator)
            footer
        }
        .frame(minWidth: 560, minHeight: 420)
        .background(ATHEERDesignTokens.ColorRole.canvas)
        .task {
            searchFieldIsFocused = true
            await model.refreshBackendStatus()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Instrument Quick Search")
                    .font(ATHEERDesignTokens.Typography.screenTitle)
                Text("Find an instrument in the authenticated broker catalogue.")
                    .font(ATHEERDesignTokens.Typography.body)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Close instrument search")
            .accessibilityLabel("Close instrument search")
        }
        .padding(20)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ATHEERDesignTokens.ColorRole.accent)

            TextField("Instrument name or EPIC", text: $model.searchTerm)
                .textFieldStyle(.plain)
                .focused($searchFieldIsFocused)
                .onSubmit {
                    Task { await model.search() }
                }
                .dropDestination(for: ATHEERInstrumentReferenceTransfer.self) { transfers, _ in
                    guard transfers.count == 1, let transfer = transfers.first else { return false }
                    return applyInstrumentTransfer(transfer)
                }
                .pasteDestination(for: ATHEERInstrumentReferenceTransfer.self) { transfers in
                    guard transfers.count == 1, let transfer = transfers.first else { return }
                    _ = applyInstrumentTransfer(transfer)
                }
                .accessibilityIdentifier("instrument-quick-search.query")
                .accessibilityLabel("Search instruments by name or EPIC")

            if !model.searchTerm.isEmpty {
                Button {
                    model.searchTerm = ""
                    searchFieldIsFocused = true
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
                if case .searching = model.state {
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

            if case .unavailable = model.state {
                Button {
                    Task { await model.refreshBackendStatus() }
                } label: {
                    Label("Retry connection", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Recheck the authenticated backend session")
                .accessibilityIdentifier("instrument-quick-search.retry")
            }
        }
        .padding(12)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var resultsContent: some View {
        switch model.state {
        case .idle:
            stateMessage(
                title: "Search the instrument catalogue",
                message: "Enter an instrument name or provider EPIC to find a matching market.",
                symbol: "text.magnifyingglass"
            )
        case .searching:
            HStack(spacing: 10) {
                ProgressView()
                Text("Querying the provider-backed catalogue…")
                    .font(ATHEERDesignTokens.Typography.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .results:
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.results) { instrument in
                        instrumentResultButton(instrument)

                        if instrument.id != model.results.last?.id {
                            Divider()
                                .overlay(ATHEERDesignTokens.ColorRole.separator)
                                .padding(.leading, 16)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        case .empty:
            stateMessage(
                title: "No matching instruments",
                message: "The provider returned no catalogue records for this search.",
                symbol: "line.3.horizontal.decrease.circle"
            )
        case .unavailable(let message):
            stateMessage(
                title: "Instrument search unavailable",
                message: message,
                symbol: "exclamationmark.triangle"
            )
        case .failed(let message):
            stateMessage(
                title: "Search failed",
                message: message,
                symbol: "xmark.octagon"
            )
        }
    }

    @ViewBuilder
    private func instrumentResultButton(_ instrument: MarketInstrumentSummary) -> some View {
        let button = Button {
            onSelect(instrument)
            dismiss()
        } label: {
            instrumentRow(instrument)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("instrument-quick-search.result.\(instrument.epic)")

        if let transfer = instrumentTransfer(for: instrument) {
            button
                .draggable(transfer)
                .copyable([transfer])
        } else {
            button
        }
    }

    private func instrumentTransfer(
        for instrument: MarketInstrumentSummary
    ) -> ATHEERInstrumentReferenceTransfer? {
        guard let status = model.backendStatus,
              status.provider == "capital.com",
              status.environment == "DEMO",
              status.state == .connected else {
            return nil
        }
        return ATHEERInstrumentReferenceTransfer(
            identifier: instrument.epic,
            identifierKind: .epic,
            providerIdentifier: status.provider
        )
    }

    @discardableResult
    private func applyInstrumentTransfer(
        _ transfer: ATHEERInstrumentReferenceTransfer
    ) -> Bool {
        guard transfer.isValid,
              transfer.identifierKind == .epic,
              let status = model.backendStatus,
              status.provider == "capital.com",
              status.environment == "DEMO",
              status.state == .connected,
              transfer.providerIdentifier == status.provider else {
            return false
        }
        model.searchTerm = transfer.identifier
        searchFieldIsFocused = true
        return true
    }

    private func instrumentRow(_ instrument: MarketInstrumentSummary) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(displayName(for: instrument))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(instrument.epic)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                    if let currency = instrument.currency, !currency.isEmpty {
                        Text(currency)
                            .font(ATHEERDesignTokens.Typography.caption)
                    }
                    if let marketStatus = instrument.marketStatus, !marketStatus.isEmpty {
                        Text(marketStatus.uppercased())
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    }
                }
                .foregroundColor(.secondary)
            }

            Spacer(minLength: 12)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private func displayName(for instrument: MarketInstrumentSummary) -> String {
        if let name = instrument.name?.trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            return name
        }
        return instrument.epic
    }

    private func stateMessage(
        title: String,
        message: String,
        symbol: String
    ) -> some View {
        VStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundColor(.secondary)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
            Text(message)
                .font(ATHEERDesignTokens.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                if let status = model.backendStatus {
                    Text("\(status.provider.uppercased()) · \(status.environment) · CATALOGUE METADATA")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                } else {
                    Text("BROKER CATALOGUE STATUS NOT VERIFIED")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Text("No prices, account values, positions, or trading actions are presented here.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
