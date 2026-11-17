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
    @Published var searchTerm = ""

    private let client: MarketSearchClient

    init(client: MarketSearchClient = URLSessionMarketSearchClient()) {
        self.client = client
    }

    var canSearch: Bool {
        backendStatus?.state == .connected &&
        !searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        state != .searching
    }

    func refreshBackendStatus() async {
        do {
            let status = try await client.fetchBackendStatus()
            backendStatus = status
            if status.state != .connected {
                state = .unavailable(statusMessage(for: status.state))
            } else if results.isEmpty {
                state = .idle
            }
        } catch {
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

        state = .searching
        do {
            results = try await client.searchMarkets(query)
            state = results.isEmpty ? .empty : .results
        } catch {
            let failureMessage = error.localizedDescription
            results = []
            await refreshBackendStatus()
            if backendStatus?.state != .connected {
                state = .unavailable("The backend market-data session is no longer connected. Recheck the DEMO service status.")
            } else {
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
