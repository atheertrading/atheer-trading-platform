import Foundation

enum MarketDataStreamConnectionState: String, Decodable, Equatable {
    case disconnected
    case connecting
    case connected
    case degraded
}

struct MarketDataStreamStatus: Decodable, Equatable {
    let provider: String
    let environment: String
    let state: MarketDataStreamConnectionState
    let activeInstrumentCount: Int
    let lastMessageAtMs: Int64?
    let lastError: String?
    let invalidQuoteCount: Int
    let outOfOrderQuoteCount: Int
    let duplicateQuoteCount: Int
}

struct MarketDataQuoteFreshness: Decodable, Equatable {
    let state: String
    let ageMs: Double?
    let automatedDecisionsAllowed: Bool
    let reason: String
}

struct MarketDataStreamQuote: Decodable, Equatable, Identifiable {
    let provider: String
    let environment: String
    let instrumentId: String
    let bid: Double
    let ask: Double
    let providerTimestampMs: Int64
    let receivedAtMs: Int64
    let receivedAtMonotonicMs: Double
    let freshness: MarketDataQuoteFreshness

    var id: String { instrumentId }

    var providerDate: Date {
        Date(timeIntervalSince1970: Double(providerTimestampMs) / 1_000)
    }

    var currentAgeMilliseconds: Double {
        max(0, Date().timeIntervalSince1970 * 1_000 - Double(providerTimestampMs))
    }
}

enum MarketDataStreamEvent: Equatable {
    case status(MarketDataStreamStatus)
    case quote(MarketDataStreamQuote)
}

enum MarketDataStreamError: Error, LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case unexpectedHTTPStatus(Int)
    case providerUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The market-data stream URL is invalid."
        case .invalidResponse:
            return "The market-data stream returned an invalid event."
        case .unexpectedHTTPStatus(let status):
            return "The market-data stream returned HTTP \(status)."
        case .providerUnavailable:
            return "The Capital.com DEMO market-data stream is unavailable."
        }
    }
}

@MainActor
protocol MarketDataStreamClient {
    func events(for epics: [String]) -> AsyncThrowingStream<MarketDataStreamEvent, Error>
}

struct ServerSentEventParser {
    private var eventName: String?
    private var dataLines: [String] = []

    mutating func consume(_ line: String) throws -> MarketDataStreamEvent? {
        if line.isEmpty {
            defer {
                eventName = nil
                dataLines = []
            }
            guard let eventName, !dataLines.isEmpty else { return nil }
            let data = Data(dataLines.joined(separator: "\n").utf8)
            let decoder = JSONDecoder()

            switch eventName {
            case "status":
                let status = try decoder.decode(MarketDataStreamStatus.self, from: data)
                guard status.provider == "capital.com", status.environment == "DEMO" else {
                    throw MarketDataStreamError.invalidResponse
                }
                return .status(status)
            case "quote":
                let quote = try decoder.decode(MarketDataStreamQuote.self, from: data)
                guard quote.provider == "capital.com",
                      quote.environment == "DEMO",
                      !quote.instrumentId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      quote.bid.isFinite,
                      quote.ask.isFinite,
                      quote.bid > 0,
                      quote.ask >= quote.bid,
                      quote.providerTimestampMs > 0,
                      quote.receivedAtMs > 0 else {
                    throw MarketDataStreamError.invalidResponse
                }
                return .quote(quote)
            case "error":
                throw MarketDataStreamError.providerUnavailable
            default:
                return nil
            }
        }

        if line.hasPrefix(":") {
            return nil
        }
        if line.hasPrefix("event:") {
            eventName = String(line.dropFirst("event:".count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else if line.hasPrefix("data:") {
            var value = String(line.dropFirst("data:".count))
            if value.first == " " { value.removeFirst() }
            dataLines.append(value)
        }
        return nil
    }
}

struct URLSessionMarketDataStreamClient: MarketDataStreamClient {
    private let baseURL: URL
    private let session: URLSession

    init(
        session: URLSession = .shared,
        baseURLString: String = URLSessionBackendHealthClient.baseURLString
    ) {
        self.session = session
        self.baseURL = URL(string: baseURLString)!
    }

    func events(for epics: [String]) -> AsyncThrowingStream<MarketDataStreamEvent, Error> {
        let normalized = Array(Set(epics.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })).sorted()
        return AsyncThrowingStream { continuation in
            let session = self.session
            let baseURL = self.baseURL
            let task = Task.detached(priority: .userInitiated) {
                do {
                    guard !normalized.isEmpty,
                          normalized.count <= 40,
                          normalized.allSatisfy({ !$0.isEmpty }) else {
                        throw MarketDataStreamError.invalidResponse
                    }

                    let streamURL = ["market-data", "stream"].reduce(baseURL) {
                        $0.appendingPathComponent($1)
                    }
                    var components = URLComponents(url: streamURL, resolvingAgainstBaseURL: false)
                    components?.queryItems = [
                        URLQueryItem(name: "epics", value: normalized.joined(separator: ","))
                    ]
                    guard let url = components?.url else {
                        throw MarketDataStreamError.invalidURL
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.timeoutInterval = 60
                    request.cachePolicy = .reloadIgnoringLocalCacheData
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw MarketDataStreamError.invalidResponse
                    }
                    guard http.statusCode == 200 else {
                        throw MarketDataStreamError.unexpectedHTTPStatus(http.statusCode)
                    }

                    var parser = ServerSentEventParser()
                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        if let event = try parser.consume(line) {
                            continuation.yield(event)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
