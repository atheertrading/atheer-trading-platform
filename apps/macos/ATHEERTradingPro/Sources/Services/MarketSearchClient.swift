import Foundation

/// Application-facing market search port. It exposes stable semantic models,
/// never provider response DTOs or transport-specific payloads.
@MainActor
protocol MarketSearchClient {
    func fetchBackendStatus() async throws -> MarketDataBackendStatus
    func searchMarkets(_ searchTerm: String) async throws -> [MarketInstrumentSummary]
}

// MARK: - Provider DTOs (infrastructure boundary)

private struct MarketDataBackendStatusDTO: Decodable {
    let provider: String
    let environment: String
    let state: String
}

private struct MarketSearchInstrumentDTO: Decodable {
    let epic: String
    let instrumentName: String?
    let marketStatus: String?
    let currency: String?
}

private struct MarketSearchPayloadDTO: Decodable {
    let provider: String
    let environment: String
    let markets: [MarketSearchInstrumentDTO]
}

// MARK: - Provider decoding and mapping

struct MarketSearchPayloadDecoder {
    func decodeStatus(_ data: Data) throws -> MarketDataBackendStatus {
        let dto: MarketDataBackendStatusDTO
        do {
            dto = try JSONDecoder().decode(MarketDataBackendStatusDTO.self, from: data)
        } catch {
            throw MarketSearchError.invalidResponse
        }

        guard dto.provider == "capital.com", dto.environment == "DEMO" else {
            throw MarketSearchError.invalidResponse
        }

        return MarketDataBackendStatus(
            provider: dto.provider,
            environment: dto.environment,
            state: try mapConnectionState(dto.state)
        )
    }

    func decodeMarkets(_ data: Data) throws -> [MarketInstrumentSummary] {
        let dto: MarketSearchPayloadDTO
        do {
            dto = try JSONDecoder().decode(MarketSearchPayloadDTO.self, from: data)
        } catch {
            throw MarketSearchError.invalidResponse
        }

        guard dto.provider == "capital.com",
              dto.environment == "DEMO",
              dto.markets.allSatisfy({
                  !$0.epic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              }) else {
            throw MarketSearchError.invalidResponse
        }

        return dto.markets.map {
            MarketInstrumentSummary(
                epic: $0.epic,
                name: $0.instrumentName,
                marketStatus: $0.marketStatus,
                currency: $0.currency
            )
        }
    }

    private func mapConnectionState(_ value: String) throws -> MarketDataBackendConnectionState {
        switch value {
        case "not_configured": return .notConfigured
        case "disconnected": return .disconnected
        case "connecting": return .connecting
        case "connected": return .connected
        case "degraded": return .degraded
        case "stale": return .stale
        case "error": return .error
        default: throw MarketSearchError.invalidResponse
        }
    }
}

// MARK: - Capital.com DEMO backend adapter

struct URLSessionMarketSearchClient: MarketSearchClient {
    private let baseURL = URL(string: URLSessionBackendHealthClient.baseURLString)!
    private let requestExecutor: URLSessionRequestExecutor
    private let decoder = MarketSearchPayloadDecoder()

    init(session: URLSession? = nil) {
        let resolvedSession = session ?? Self.makeEphemeralSession()
        self.requestExecutor = URLSessionRequestExecutor(session: resolvedSession)
    }

    private static func makeEphemeralSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }

    func fetchBackendStatus() async throws -> MarketDataBackendStatus {
        let (data, response) = try await get(path: ["market-data", "status"])
        guard response.statusCode == 200 else {
            throw MarketSearchError.unexpectedHTTPStatus(response.statusCode)
        }
        return try decoder.decodeStatus(data)
    }

    func searchMarkets(_ searchTerm: String) async throws -> [MarketInstrumentSummary] {
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

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await requestExecutor.data(for: request)
        } catch let error as MarketSearchError {
            throw error
        } catch {
            throw MarketSearchError.backendUnavailable
        }

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
            let (data, response) = try await requestExecutor.data(for: request)
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
