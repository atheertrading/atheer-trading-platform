import Foundation

enum MarketDataQuoteFreshnessState: String, Decodable, Equatable {
    case fresh
    case stale
    case invalid
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
    let state: MarketDataQuoteFreshnessState
    let ageMs: Double?
    let maximumAgeMs: Int
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
    case streamEnded

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
        case .streamEnded:
            return "The market-data event stream ended unexpectedly."
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
                guard status.provider == "capital.com",
                      status.environment == "DEMO",
                      (0...40).contains(status.activeInstrumentCount),
                      status.invalidQuoteCount >= 0,
                      status.outOfOrderQuoteCount >= 0,
                      status.duplicateQuoteCount >= 0,
                      status.lastMessageAtMs.map({ $0 >= 0 }) ?? true,
                      status.lastError.map({ $0.count <= 512 }) ?? true else {
                    throw MarketDataStreamError.invalidResponse
                }
                return .status(status)
            case "quote":
                let quote = try decoder.decode(MarketDataStreamQuote.self, from: data)
                let freshness = quote.freshness
                guard quote.provider == "capital.com",
                      quote.environment == "DEMO",
                      !quote.instrumentId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      quote.instrumentId.count <= 64,
                      quote.bid.isFinite,
                      quote.ask.isFinite,
                      quote.bid > 0,
                      quote.ask >= quote.bid,
                      quote.providerTimestampMs > 0,
                      quote.receivedAtMs > 0,
                      quote.receivedAtMonotonicMs.isFinite,
                      quote.receivedAtMonotonicMs >= 0,
                      freshness.ageMs.map({ $0.isFinite && $0 >= 0 }) ?? true,
                      freshness.maximumAgeMs > 0,
                      !freshness.reason.isEmpty,
                      freshness.reason.count <= 128,
                      (freshness.state == .fresh) == freshness.automatedDecisionsAllowed else {
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

@MainActor
struct URLSessionMarketDataStreamClient: MarketDataStreamClient {
    private let baseURL: URL
    private let capability: BackendIPCCapability
    private let session: URLSession

    init(connection: BackendIPCConnection, session: URLSession? = nil) {
        self.baseURL = connection.baseURL
        self.capability = connection.capability

        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.httpCookieStorage = nil
            configuration.urlCache = nil
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: configuration)
        }
    }

    func events(for epics: [String]) -> AsyncThrowingStream<MarketDataStreamEvent, Error> {
        let normalized = Array(
            Set(epics.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        ).sorted()
        let baseURL = self.baseURL
        let session = self.session
        let authorization = capability.authorizationHeaderValue

        return AsyncThrowingStream(bufferingPolicy: .bufferingNewest(256)) { continuation in
            guard !normalized.isEmpty,
                  normalized.count <= 40,
                  normalized.allSatisfy({ !$0.isEmpty }) else {
                continuation.finish(throwing: MarketDataStreamError.invalidResponse)
                return
            }
            guard let authorization else {
                continuation.finish(throwing: MarketDataStreamError.providerUnavailable)
                return
            }

            let task = Task.detached(priority: .userInitiated) {
                do {
                    let streamURL = ["market-data", "stream"].reduce(baseURL) {
                        $0.appendingPathComponent($1)
                    }
                    var components = URLComponents(
                        url: streamURL,
                        resolvingAgainstBaseURL: false
                    )
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
                    request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
                    request.setValue("macOS", forHTTPHeaderField: "X-ATHEER-LOCAL-CLIENT")
                    request.setValue(authorization, forHTTPHeaderField: "Authorization")

                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw MarketDataStreamError.invalidResponse
                    }
                    guard http.statusCode == 200 else {
                        throw MarketDataStreamError.unexpectedHTTPStatus(http.statusCode)
                    }
                    guard http.mimeType?.lowercased() == "text/event-stream" else {
                        throw MarketDataStreamError.invalidResponse
                    }

                    var parser = ServerSentEventParser()
                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        if let event = try parser.consume(line) {
                            continuation.yield(event)
                        }
                    }

                    if Task.isCancelled {
                        continuation.finish()
                    } else {
                        continuation.finish(throwing: MarketDataStreamError.streamEnded)
                    }
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
