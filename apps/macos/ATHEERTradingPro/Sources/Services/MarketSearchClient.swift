import Combine
import Foundation

enum MarketDataBackendConnectionState: String, Decodable, Equatable {
    case notConfigured = "not_configured"
    case disconnected
    case connecting
    case connected
    case degraded
    case stale
    case error
}

struct MarketDataBackendStatus: Decodable, Equatable {
    let provider: String
    let environment: String
    let state: MarketDataBackendConnectionState
}

struct MarketSearchInstrument: Decodable, Equatable, Identifiable {
    let epic: String
    let instrumentName: String?
    let marketStatus: String?
    let currency: String?

    var id: String { epic }
}

struct MarketSearchPayload: Decodable {
    let provider: String
    let environment: String
    let markets: [MarketSearchInstrument]
}

enum MarketSearchError: Error, LocalizedError, Equatable {
    case invalidResponse
    case unexpectedHTTPStatus(Int)
    case backendUnavailable
    case backendNotConnected

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The market-data API returned an invalid response."
        case .unexpectedHTTPStatus(let code):
            return "The market-data API returned HTTP \(code)."
        case .backendUnavailable:
            return "The backend market-data service is unavailable."
        case .backendNotConnected:
            return "The Capital.com DEMO market-data session is not connected."
        }
    }
}

@MainActor
protocol MarketSearchClient {
    func fetchBackendStatus() async throws -> MarketDataBackendStatus
    func searchMarkets(_ searchTerm: String) async throws -> [MarketSearchInstrument]
}

struct MarketSearchPayloadDecoder {
    func decodeStatus(_ data: Data) throws -> MarketDataBackendStatus {
        let status: MarketDataBackendStatus
        do {
            status = try JSONDecoder().decode(MarketDataBackendStatus.self, from: data)
        } catch {
            throw MarketSearchError.invalidResponse
        }
        guard status.provider == "capital.com", status.environment == "DEMO" else {
            throw MarketSearchError.invalidResponse
        }
        return status
    }

    func decodeMarkets(_ data: Data) throws -> [MarketSearchInstrument] {
        let payload: MarketSearchPayload
        do {
            payload = try JSONDecoder().decode(MarketSearchPayload.self, from: data)
        } catch {
            throw MarketSearchError.invalidResponse
        }
        guard payload.provider == "capital.com",
              payload.environment == "DEMO",
              payload.markets.allSatisfy({ !$0.epic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw MarketSearchError.invalidResponse
        }
        return payload.markets
    }
}

struct URLSessionMarketSearchClient: MarketSearchClient {
    private let baseURL = URL(string: URLSessionBackendHealthClient.baseURLString)!
    private let session: URLSession
    private let decoder = MarketSearchPayloadDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchBackendStatus() async throws -> MarketDataBackendStatus {
        let (data, response) = try await get(path: ["market-data", "status"])
        guard response.statusCode == 200 else {
            throw MarketSearchError.unexpectedHTTPStatus(response.statusCode)
        }
        return try decoder.decodeStatus(data)
    }

    func searchMarkets(_ searchTerm: String) async throws -> [MarketSearchInstrument] {
        let normalized = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, normalized.count <= 100 else {
            throw MarketSearchError.invalidResponse
        }

        var components = URLComponents(
            url: ["market-data", "markets"].reduce(baseURL) { $0.appendingPathComponent($1) },
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "searchTerm", value: normalized)]
        guard let url = components?.url else {
            throw MarketSearchError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 8
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw MarketSearchError.invalidResponse
        }
        guard http.statusCode == 200 else {
            if http.statusCode == 502 || http.statusCode == 503 {
                throw MarketSearchError.backendNotConnected
            }
            throw MarketSearchError.unexpectedHTTPStatus(http.statusCode)
        }
        return try decoder.decodeMarkets(data)
    }

    private func get(path: [String]) async throws -> (Data, HTTPURLResponse) {
        let url = path.reduce(baseURL) { $0.appendingPathComponent($1) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw MarketSearchError.invalidResponse
            }
            return (data, http)
        } catch let error as MarketSearchError {
            throw error
        } catch {
            throw MarketSearchError.backendUnavailable
        }
    }
}

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
    @Published private(set) var results: [MarketSearchInstrument] = []
    @Published private(set) var state: MarketExplorerViewState = .idle
    @Published private(set) var streamingState: MarketDataStreamConnectionState = .disconnected
    @Published private(set) var streamingQuotes: [String: MarketDataStreamQuote] = [:]
    @Published private(set) var selectedEpics: Set<String> = []
    @Published private(set) var streamingError: String?
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
    private let streamClient: MarketDataStreamClient
    private var streamTask: Task<Void, Never>?
    private var displayThrottleTask: Task<Void, Never>?
    private var pendingStreamingQuotes: [String: MarketDataStreamQuote] = [:]
    private var streamingRequested = false
    private var searchGeneration: UInt64 = 0
    private var statusRefreshGeneration: UInt64 = 0
    private static let epicValidationPattern = "^[A-Za-z0-9_.-]{1,64}$"

    init(
        client: MarketSearchClient? = nil,
        streamClient: MarketDataStreamClient? = nil
    ) {
        self.client = client ?? URLSessionMarketSearchClient()
        self.streamClient = streamClient ?? URLSessionMarketDataStreamClient()
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
                pauseStream()
                state = .unavailable(statusMessage(for: status.state))
            } else {
                if results.isEmpty && state != .searching {
                    state = .idle
                }
                startStreamIfNeeded()
            }
        } catch {
            guard requestGeneration == statusRefreshGeneration else { return }
            searchGeneration &+= 1
            backendStatus = nil
            pauseStream()
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

    func isSubscribed(to epic: String) -> Bool {
        selectedEpics.contains(epic)
    }

    var canStartStreaming: Bool {
        backendStatus?.state == .connected && !selectedEpics.isEmpty
    }

    var isStreamingRequested: Bool {
        streamingRequested
    }

    func canSubscribe(to epic: String) -> Bool {
        isValidEpic(epic) && (isSubscribed(to: epic) || selectedEpics.count < 40)
    }

    func toggleStreamSubscription(for epic: String) {
        guard isValidEpic(epic) else {
            streamingError = "The instrument identifier contains unsupported characters or exceeds 64 characters."
            return
        }
        if selectedEpics.contains(epic) {
            selectedEpics.remove(epic)
            streamingQuotes.removeValue(forKey: epic)
            pendingStreamingQuotes.removeValue(forKey: epic)
            streamingError = nil
            if streamingRequested { restartStream() }
            return
        }

        guard selectedEpics.count < 40 else {
            streamingError = "The provider stream supports a maximum of 40 selected instruments."
            return
        }

        selectedEpics.insert(epic)
        streamingError = nil
        if streamingRequested { restartStream() }
    }

    func clearStreamSelection() {
        selectedEpics.removeAll()
        streamingQuotes.removeAll()
        pendingStreamingQuotes.removeAll()
        streamingError = nil
        if streamingRequested { restartStream() }
    }

    func startStreaming() {
        guard canStartStreaming else {
            streamingError = "Connect the backend DEMO session and select at least one instrument."
            return
        }
        streamingRequested = true
        restartStream()
    }

    func resumeStreamIfNeeded() {
        guard streamingRequested else { return }
        startStreamIfNeeded()
    }

    func pauseStream() {
        flushPendingQuotes()
        streamTask?.cancel()
        streamTask = nil
        displayThrottleTask?.cancel()
        displayThrottleTask = nil
        streamingState = .disconnected
    }

    func stopStream() {
        streamingRequested = false
        pauseStream()
    }

    private func startStreamIfNeeded() {
        guard streamingRequested,
              streamTask == nil,
              !selectedEpics.isEmpty,
              backendStatus?.state == .connected else {
            return
        }
        restartStream()
    }

    private func restartStream() {
        streamTask?.cancel()
        streamTask = nil

        guard streamingRequested,
              !selectedEpics.isEmpty,
              backendStatus?.state == .connected else {
            pauseStream()
            return
        }

        let epics = selectedEpics.sorted()
        streamingState = .connecting
        streamTask = Task { [weak self] in
            guard let self else { return }
            var retryDelay: UInt64 = 1_000_000_000

            while !Task.isCancelled {
                do {
                    for try await event in streamClient.events(for: epics) {
                        guard !Task.isCancelled else { return }
                        switch event {
                        case .status(let status):
                            streamingState = status.state
                            if status.state == .connected {
                                streamingError = nil
                                retryDelay = 1_000_000_000
                            } else if let message = status.lastError {
                                streamingError = message
                            }
                        case .quote(let quote):
                            guard selectedEpics.contains(quote.instrumentId) else { continue }
                            queueQuoteForPresentation(quote)
                            if streamingState != .connected {
                                streamingState = .connected
                            }
                            if streamingError != nil {
                                streamingError = nil
                            }
                        }
                    }
                    if Task.isCancelled { return }
                    streamingState = .degraded
                } catch {
                    if Task.isCancelled { return }
                    streamingState = .degraded
                    streamingError = error.localizedDescription
                }

                do {
                    try await Task.sleep(nanoseconds: retryDelay)
                } catch {
                    return
                }
                retryDelay = min(retryDelay * 2, 30_000_000_000)
            }
        }
    }

    private func isValidEpic(_ epic: String) -> Bool {
        epic.range(of: Self.epicValidationPattern, options: .regularExpression) != nil
    }

    private func queueQuoteForPresentation(_ quote: MarketDataStreamQuote) {
        pendingStreamingQuotes[quote.instrumentId] = quote
        guard displayThrottleTask == nil else { return }

        displayThrottleTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 100_000_000)
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                flushPendingQuotes()
            }
        }
    }

    private func flushPendingQuotes() {
        guard !pendingStreamingQuotes.isEmpty else { return }
        var nextQuotes = streamingQuotes
        for (epic, quote) in pendingStreamingQuotes where selectedEpics.contains(epic) {
            nextQuotes[epic] = quote
        }
        pendingStreamingQuotes.removeAll(keepingCapacity: true)
        streamingQuotes = nextQuotes
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
