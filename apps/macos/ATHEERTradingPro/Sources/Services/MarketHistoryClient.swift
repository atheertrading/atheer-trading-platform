@preconcurrency import Foundation

enum HistoricalPriceResolution: String, CaseIterable, Decodable, Equatable, Identifiable {
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
        case .fiveMinutes: return 5 * 60_000
        case .fifteenMinutes: return 15 * 60_000
        case .thirtyMinutes: return 30 * 60_000
        case .hour: return 60 * 60_000
        case .fourHours: return 4 * 60 * 60_000
        case .day: return 24 * 60 * 60_000
        case .week: return 7 * 24 * 60 * 60_000
        }
    }
}

enum HistoricalPriceSide: String, CaseIterable, Decodable, Equatable, Identifiable {
    case bid
    case ask
    var id: String { rawValue }
    var title: String { rawValue.uppercased() }
}

struct HistoricalOHLC: Decodable, Equatable {
    let open: Double
    let high: Double
    let low: Double
    let close: Double

    func isValid() -> Bool {
        [open, high, low, close].allSatisfy { $0.isFinite && $0 > 0 } &&
            high >= max(open, close) && low <= min(open, close) && high >= low
    }
}

struct NormalizedHistoricalCandle: Decodable, Equatable, Identifiable {
    let provider: String
    let environment: String
    let instrumentId: String
    let resolution: HistoricalPriceResolution
    let timestampMs: Int64
    let bid: HistoricalOHLC
    let ask: HistoricalOHLC
    let providerVolume: Double?
    let providerVolumeField: String?
    let receivedAtMs: Int64

    var id: Int64 { timestampMs }
    var date: Date { Date(timeIntervalSince1970: Double(timestampMs) / 1_000) }
    func values(for side: HistoricalPriceSide) -> HistoricalOHLC { side == .bid ? bid : ask }
}

struct HistoricalCandleGap: Decodable, Equatable {
    let previousTimestampMs: Int64
    let nextTimestampMs: Int64
    let nominalIntervalsMissing: Int
    let classification: String
}

struct HistoricalCandleQuality: Decodable, Equatable {
    let receivedCount: Int
    let normalizedCount: Int
    let duplicateCount: Int
    let observedGaps: [HistoricalCandleGap]
}

struct HistoricalCandleBatch: Decodable, Equatable {
    let provider: String
    let environment: String
    let instrumentId: String
    let resolution: HistoricalPriceResolution
    let candles: [NormalizedHistoricalCandle]
    let quality: HistoricalCandleQuality
}

enum MarketHistoryError: Error, LocalizedError, Equatable {
    case invalidRequest
    case invalidResponse
    case backendNotConnected
    case backendUnavailable
    case unexpectedHTTPStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidRequest: return "The historical market-data request is invalid."
        case .invalidResponse: return "The backend returned invalid or inconsistent historical candle data."
        case .backendNotConnected: return "The Capital.com DEMO market-data session is not connected."
        case .backendUnavailable: return "The historical market-data service is unavailable."
        case .unexpectedHTTPStatus(let status): return "The historical market-data API returned HTTP \(status)."
        }
    }
}

@MainActor
protocol MarketHistoryClient {
    func fetchHistory(instrumentId: String, resolution: HistoricalPriceResolution, maximum: Int) async throws -> HistoricalCandleBatch
}

struct MarketHistoryPayloadDecoder {
    func decode(_ data: Data, expectedInstrumentId: String, expectedResolution: HistoricalPriceResolution, maximum: Int) throws -> HistoricalCandleBatch {
        guard maximum >= 1, maximum <= 1_000,
              expectedInstrumentId.range(of: "^[A-Za-z0-9_.-]{1,64}$", options: .regularExpression) != nil else {
            throw MarketHistoryError.invalidRequest
        }

        let batch: HistoricalCandleBatch
        do {
            batch = try JSONDecoder().decode(HistoricalCandleBatch.self, from: data)
        } catch {
            throw MarketHistoryError.invalidResponse
        }

        guard batch.provider == "capital.com",
              batch.environment == "DEMO",
              batch.instrumentId == expectedInstrumentId,
              batch.resolution == expectedResolution,
              batch.candles.count <= maximum,
              batch.quality.receivedCount >= batch.quality.normalizedCount,
              batch.quality.normalizedCount == batch.candles.count,
              batch.quality.duplicateCount == batch.quality.receivedCount - batch.quality.normalizedCount,
              batch.quality.observedGaps.allSatisfy({
                  $0.previousTimestampMs > 0 &&
                      $0.nextTimestampMs > $0.previousTimestampMs &&
                      $0.nominalIntervalsMissing > 0 &&
                      $0.classification == "requires_market_session_calendar"
              }) else {
            throw MarketHistoryError.invalidResponse
        }

        var previousTimestamp: Int64?
        for candle in batch.candles {
            guard candle.provider == batch.provider,
                  candle.environment == batch.environment,
                  candle.instrumentId == batch.instrumentId,
                  candle.resolution == batch.resolution,
                  candle.timestampMs > 0,
                  candle.receivedAtMs > 0,
                  candle.bid.isValid(),
                  candle.ask.isValid(),
                  candle.providerVolume.map({ $0.isFinite && $0 >= 0 }) ?? true,
                  (candle.providerVolume == nil && candle.providerVolumeField == nil)
                    || (candle.providerVolume != nil && candle.providerVolumeField == "lastTradedVolume"),
                  candle.ask.open >= candle.bid.open,
                  candle.ask.high >= candle.bid.high,
                  candle.ask.low >= candle.bid.low,
                  candle.ask.close >= candle.bid.close else {
                throw MarketHistoryError.invalidResponse
            }
            if let previousTimestamp, candle.timestampMs <= previousTimestamp {
                throw MarketHistoryError.invalidResponse
            }
            previousTimestamp = candle.timestampMs
        }
        return batch
    }
}

struct URLSessionMarketHistoryClient: MarketHistoryClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder = MarketHistoryPayloadDecoder()

    init(session: URLSession = .shared, baseURLString: String = URLSessionBackendHealthClient.baseURLString) {
        self.session = session
        self.baseURL = URL(string: baseURLString)!
    }

    func fetchHistory(instrumentId: String, resolution: HistoricalPriceResolution, maximum: Int) async throws -> HistoricalCandleBatch {
        let epic = instrumentId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard epic.range(of: "^[A-Za-z0-9_.-]{1,64}$", options: .regularExpression) != nil,
              maximum >= 1, maximum <= 1_000 else {
            throw MarketHistoryError.invalidRequest
        }

        let historyURL = ["market-data", "history"].reduce(baseURL) { $0.appendingPathComponent($1) }
        var components = URLComponents(url: historyURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "epic", value: epic),
            URLQueryItem(name: "resolution", value: resolution.rawValue),
            URLQueryItem(name: "max", value: String(maximum))
        ]
        guard let url = components?.url else { throw MarketHistoryError.invalidRequest }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw MarketHistoryError.invalidResponse }
            guard http.statusCode == 200 else {
                if http.statusCode == 502 || http.statusCode == 503 {
                    throw MarketHistoryError.backendNotConnected
                }
                throw MarketHistoryError.unexpectedHTTPStatus(http.statusCode)
            }
            return try decoder.decode(data, expectedInstrumentId: epic, expectedResolution: resolution, maximum: maximum)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as MarketHistoryError {
            throw error
        } catch {
            throw MarketHistoryError.backendUnavailable
        }
    }
}
