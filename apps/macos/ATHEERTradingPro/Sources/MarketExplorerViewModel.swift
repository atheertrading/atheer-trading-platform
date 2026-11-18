import Combine
import Foundation

enum MarketExplorerViewState: Equatable {
    case idle
    case searching
    case results
    case empty
    case unavailable(String)
    case failed(String)
}

@MainActor
final class MarketExplorerViewModel: ObservableObject {
    @Published private(set) var backendStatus: MarketDataBackendStatus?
    @Published private(set) var results: [MarketInstrumentSummary] = []
    @Published private(set) var state: MarketExplorerViewState = .idle
    @Published var searchTerm = "" {
        didSet {
            guard oldValue != searchTerm else { return }
            searchGeneration &+= 1
            if case .unavailable = state {
                return
            }
            results = []
            state = .idle
        }
    }

    private let client: MarketSearchClient
    private var searchGeneration: UInt64 = 0
    private var statusRefreshGeneration: UInt64 = 0

    init(client: MarketSearchClient) {
        self.client = client
    }

    var canSearch: Bool {
        let query = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        return backendStatus?.state == .connected &&
            !query.isEmpty &&
            query.count <= 100 &&
            state != .searching
    }

    func refreshBackendStatus() async {
        statusRefreshGeneration &+= 1
        let requestGeneration = statusRefreshGeneration

        do {
            let status = try await client.fetchBackendStatus()
            guard requestGeneration == statusRefreshGeneration else { return }

            backendStatus = status
            if status.state != .connected {
                searchGeneration &+= 1
                state = .unavailable(statusMessage(for: status.state))
            } else if results.isEmpty && state != .searching {
                state = .idle
            }
        } catch {
            guard requestGeneration == statusRefreshGeneration else { return }
            searchGeneration &+= 1
            backendStatus = nil
            state = .unavailable(error.localizedDescription)
        }
    }

    func search() async {
        let query = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, query.count <= 100 else {
            state = .failed("Enter an instrument name or search term (1–100 characters).")
            return
        }
        guard backendStatus?.state == .connected else {
            state = .unavailable("The backend Capital.com DEMO market-data session is not connected.")
            return
        }

        searchGeneration &+= 1
        let requestGeneration = searchGeneration
        state = .searching

        do {
            let fetchedResults = try await client.searchMarkets(query)
            guard requestGeneration == searchGeneration else { return }

            results = fetchedResults
            state = results.isEmpty ? .empty : .results
        } catch {
            guard requestGeneration == searchGeneration else { return }

            let failureMessage = error.localizedDescription
            await refreshBackendStatus()
            guard requestGeneration == searchGeneration else { return }

            if backendStatus?.state != .connected {
                state = .unavailable("The backend market-data session is no longer connected. Recheck the DEMO service status.")
            } else {
                results = []
                state = .failed(failureMessage)
            }
        }
    }

    private func statusMessage(for state: MarketDataBackendConnectionState) -> String {
        switch state {
        case .notConfigured:
            return "The backend DEMO market-data credentials are not configured."
        case .disconnected:
            return "The backend Capital.com DEMO market-data session is disconnected."
        case .connecting:
            return "The backend Capital.com DEMO market-data session is connecting."
        case .connected:
            return "The backend Capital.com DEMO market-data session is connected."
        case .degraded:
            return "The backend market-data service is degraded."
        case .stale:
            return "The backend market-data service reports stale data."
        case .error:
            return "The backend market-data service reports an error."
        }
    }
}
