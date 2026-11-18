import Foundation

enum HistoricalPriceResolution: String, CaseIterable, Identifiable, Codable {
    case minute = "MINUTE"
    case fiveMinutes = "MINUTE_5"
    case fifteenMinutes = "MINUTE_15"
    case thirtyMinutes = "MINUTE_30"
    case hour = "HOUR"
    case fourHours = "HOUR_4"
    case day = "DAY"
    case week = "WEEK"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .minute: return "1m"
        case .fiveMinutes: return "5m"
        case .fifteenMinutes: return "15m"
        case .thirtyMinutes: return "30m"
        case .hour: return "1h"
        case .fourHours: return "4h"
        case .day: return "1D"
        case .week: return "1W"
        }
    }

    var intervalMilliseconds: Int64 {
        switch self {
        case .minute: return 60_000
        case .fiveMinutes: return 300_000
        case .fifteenMinutes: return 900_000
        case .thirtyMinutes: return 1_800_000
        case .hour: return 3_600_000
        case .fourHours: return 14_400_000
        case .day: return 86_400_000
        case .week: return 604_800_000
        }
    }
}

enum HistoricalPriceSide: String, CaseIterable, Identifiable {
    case bid
    case ask

    var id: String { rawValue }
    var title: String { rawValue.uppercased() }
}

struct HistoricalCandleOHLC: Decodable, Equatable {
    let open: Double
    let high: Double
    let low: Double
    let close: Double
}

struct NormalizedHistoricalCandle: Decodable, Equatable, Identifiable {
    let provider: String
    let environment: String
    let instrumentId: String
    let resolution: HistoricalPriceResolution
    let timestampMs: Int64
    let bid: HistoricalCandleOHLC
    let ask: HistoricalCandleOHLC
    let providerVolume: Double?
    let providerVolumeField: String?
    let receivedAtMs: Int64

    var id: Int64 { timestampMs }
    var date: Date { Date(timeIntervalSince1970: Double(timestampMs) / 1_000) }

    func values(for side: HistoricalPriceSide) -> HistoricalCandleOHLC {
        side == .bid ? bid : ask
    }
}

struct HistoricalCandleQuality: Decodable, Equatable {
    let receivedCount: Int
    let normalizedCount: Int
    let duplicateCount: Int
    let observedGaps: [Int64]
}

struct HistoricalCandleRequest: Decodable, Equatable {
    let from: String?
    let to: String?
    let max: Int
}

struct HistoricalCandlePagination: Decodable, Equatable {
    let limitReached: Bool
}

struct HistoricalCandleBatch: Decodable, Equatable {
    let provider: String
    let environment: String
    let instrumentId: String
    let resolution: HistoricalPriceResolution
    let receivedAtMs: Int64
    let candles: [NormalizedHistoricalCandle]
    let quality: HistoricalCandleQuality
    let request: HistoricalCandleRequest
    let pagination: HistoricalCandlePagination
}

@MainActor
protocol MarketHistoryClient {
    func fetchHistory(
        instrumentId: String,
        resolution: HistoricalPriceResolution,
        maximum: Int
    ) async throws -> HistoricalCandleBatch
}

enum MarketHistoryError: Error, Equatable, LocalizedError {
    case invalidRequest
    case invalidURL
    case invalidResponse
    case invalidPayload
    case unauthorized
    case backendNotConnected
    case providerUnavailable
    case unexpectedHTTPStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "The historical market-data request is invalid."
        case .invalidURL:
            return "The authenticated backend history URL could not be constructed."
        case .invalidResponse:
            return "The backend returned an invalid historical market-data response."
        case .invalidPayload:
            return "The backend historical candle payload failed contract validation."
        case .unauthorized:
            return "The local backend IPC capability was rejected. Restart the managed backend."
        case .backendNotConnected:
            return "The Capital.com DEMO broker session is not connected."
        case .providerUnavailable:
            return "Capital.com DEMO historical data is temporarily unavailable."
        case .unexpectedHTTPStatus(let status):
            return "The historical market-data request failed with HTTP \(status)."
        }
    }
}

@MainActor
enum MarketHistoryRequestBuilder {
    static func makeRequest(
        connection: BackendIPCConnection,
        instrumentId: String,
        resolution: HistoricalPriceResolution,
        maximum: Int
    ) throws -> URLRequest {
        guard instrumentId.range(of: "^[A-Za-z0-9_.-]{1,64}$", options: .regularExpression) != nil,
              (1...1_000).contains(maximum),
              let authorization = connection.capability.authorizationHeaderValue else {
            throw MarketHistoryError.invalidRequest
        }

        let endpoint = connection.baseURL.appendingPathComponent("market-data/history")
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw MarketHistoryError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "epic", value: instrumentId),
            URLQueryItem(name: "resolution", value: resolution.rawValue),
            URLQueryItem(name: "max", value: String(maximum)),
        ]
        guard let url = components.url else { throw MarketHistoryError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 8
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.setValue("macOS", forHTTPHeaderField: "X-ATHEER-LOCAL-CLIENT")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        return request
    }
}

struct MarketHistoryPayloadDecoder {
    func decode(
        _ data: Data,
        expectedInstrumentId: String,
        expectedResolution: HistoricalPriceResolution,
        maximum: Int
    ) throws -> HistoricalCandleBatch {
        guard (1...1_000).contains(maximum) else { throw MarketHistoryError.invalidRequest }
        let batch: HistoricalCandleBatch
        do {
            batch = try JSONDecoder().decode(HistoricalCandleBatch.self, from: data)
        } catch {
            throw MarketHistoryError.invalidPayload
        }

        let quality = batch.quality
        guard batch.provider == "capital.com",
              batch.environment == "DEMO",
              batch.instrumentId == expectedInstrumentId,
              batch.resolution == expectedResolution,
              batch.receivedAtMs > 0,
              batch.request.max == maximum,
              (batch.request.from == nil) == (batch.request.to == nil),
              batch.candles.count <= maximum,
              quality.receivedCount >= batch.candles.count,
              quality.receivedCount <= maximum,
              quality.normalizedCount == batch.candles.count,
              quality.duplicateCount == quality.receivedCount - batch.candles.count,
              batch.pagination.limitReached == (quality.receivedCount == maximum),
              quality.observedGaps.allSatisfy({ $0 > 0 }) else {
            throw MarketHistoryError.invalidPayload
        }

        var previousTimestamp: Int64?
        for candle in batch.candles {
            guard candle.provider == batch.provider,
                  candle.environment == batch.environment,
                  candle.instrumentId == expectedInstrumentId,
                  candle.resolution == expectedResolution,
                  candle.timestampMs > 0,
                  candle.receivedAtMs > 0,
                  candle.receivedAtMs <= batch.receivedAtMs,
                  previousTimestamp.map({ candle.timestampMs > $0 }) ?? true,
                  isValid(candle.bid),
                  isValid(candle.ask),
                  candle.ask.open >= candle.bid.open,
                  candle.ask.high >= candle.bid.high,
                  candle.ask.low >= candle.bid.low,
                  candle.ask.close >= candle.bid.close else {
                throw MarketHistoryError.invalidPayload
            }
            if let volume = candle.providerVolume {
                guard volume.isFinite, volume >= 0,
                      let field = candle.providerVolumeField,
                      !field.isEmpty else {
                    throw MarketHistoryError.invalidPayload
                }
            } else if candle.providerVolumeField != nil {
                throw MarketHistoryError.invalidPayload
            }
            previousTimestamp = candle.timestampMs
        }
        return batch
    }

    private func isValid(_ value: HistoricalCandleOHLC) -> Bool {
        let values = [value.open, value.high, value.low, value.close]
        return values.allSatisfy { $0.isFinite && $0 > 0 }
            && value.high >= max(value.open, value.close, value.low)
            && value.low <= min(value.open, value.close, value.high)
    }
}

@MainActor
struct URLSessionMarketHistoryClient: MarketHistoryClient {
    private let connection: BackendIPCConnection
    private let session: URLSession
    private let decoder = MarketHistoryPayloadDecoder()

    init(connection: BackendIPCConnection, session: URLSession? = nil) {
        self.connection = connection
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.httpCookieStorage = nil
            configuration.httpShouldSetCookies = false
            configuration.urlCache = nil
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: configuration)
        }
    }

    func fetchHistory(
        instrumentId: String,
        resolution: HistoricalPriceResolution,
        maximum: Int
    ) async throws -> HistoricalCandleBatch {
        let request = try MarketHistoryRequestBuilder.makeRequest(
            connection: connection,
            instrumentId: instrumentId,
            resolution: resolution,
            maximum: maximum
        )
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw MarketHistoryError.invalidResponse
            }
            switch http.statusCode {
            case 200:
                return try decoder.decode(
                    data,
                    expectedInstrumentId: instrumentId,
                    expectedResolution: resolution,
                    maximum: maximum
                )
            case 401:
                throw MarketHistoryError.unauthorized
            case 503:
                throw MarketHistoryError.backendNotConnected
            case 502:
                throw MarketHistoryError.providerUnavailable
            default:
                throw MarketHistoryError.unexpectedHTTPStatus(http.statusCode)
            }
        } catch let error as MarketHistoryError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw MarketHistoryError.providerUnavailable
        }
    }
}
