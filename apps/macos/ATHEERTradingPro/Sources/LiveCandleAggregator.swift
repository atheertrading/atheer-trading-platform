import Foundation

enum MarketChartCandleSource: String, Equatable {
    case historical
    case historicalUpdatedByLive
    case liveAggregated
}

/// Chart projection that distinguishes provider historical bars from locally aggregated bars.
struct MarketChartCandle: Identifiable, Equatable {
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
    let source: MarketChartCandleSource

    var id: Int64 { timestampMs }
    var date: Date { Date(timeIntervalSince1970: Double(timestampMs) / 1_000) }
    func values(for side: HistoricalPriceSide) -> HistoricalOHLC { side == .bid ? bid : ask }

    init(historical candle: NormalizedHistoricalCandle) {
        provider = candle.provider
        environment = candle.environment
        instrumentId = candle.instrumentId
        resolution = candle.resolution
        timestampMs = candle.timestampMs
        bid = candle.bid
        ask = candle.ask
        providerVolume = candle.providerVolume
        providerVolumeField = candle.providerVolumeField
        receivedAtMs = candle.receivedAtMs
        source = .historical
    }

    fileprivate init(
        provider: String, environment: String, instrumentId: String,
        resolution: HistoricalPriceResolution, timestampMs: Int64,
        bid: HistoricalOHLC, ask: HistoricalOHLC,
        providerVolume: Double?, providerVolumeField: String?,
        receivedAtMs: Int64, source: MarketChartCandleSource
    ) {
        self.provider = provider
        self.environment = environment
        self.instrumentId = instrumentId
        self.resolution = resolution
        self.timestampMs = timestampMs
        self.bid = bid
        self.ask = ask
        self.providerVolume = providerVolume
        self.providerVolumeField = providerVolumeField
        self.receivedAtMs = receivedAtMs
        self.source = source
    }
}

/// Deterministic in-memory quote-to-OHLC aggregation. It consumes every validated
/// stream event, not the throttled Market Watch presentation cache.
struct LiveCandleAggregator {
    private(set) var lastAcceptedProviderTimestampMs: Int64?

    mutating func reset() {
        lastAcceptedProviderTimestampMs = nil
    }

    @discardableResult
    mutating func ingest(
        _ quote: MarketDataStreamQuote,
        instrumentId: String,
        resolution: HistoricalPriceResolution,
        candles: inout [MarketChartCandle]
    ) -> Bool {
        guard supportsFixedUTCInterval(resolution),
              quote.provider == "capital.com",
              quote.environment == "DEMO",
              quote.instrumentId == instrumentId,
              quote.bid.isFinite, quote.ask.isFinite,
              quote.bid > 0, quote.ask >= quote.bid,
              quote.providerTimestampMs > 0, quote.receivedAtMs > 0,
              quote.providerTimestampMs <= quote.receivedAtMs + 250,
              quote.freshness.state == "fresh",
              quote.freshness.automatedDecisionsAllowed,
              let ageMs = quote.freshness.ageMs,
              ageMs.isFinite, ageMs >= -250, ageMs <= 5_000 else {
            return false
        }

        if let lastAcceptedProviderTimestampMs,
           quote.providerTimestampMs <= lastAcceptedProviderTimestampMs {
            return false
        }

        let intervalMs = resolution.intervalMilliseconds
        guard intervalMs > 0 else { return false }
        let bucketTimestampMs = (quote.providerTimestampMs / intervalMs) * intervalMs

        if let last = candles.last {
            guard last.provider == "capital.com",
                  last.environment == "DEMO",
                  last.instrumentId == instrumentId,
                  last.resolution == resolution,
                  bucketTimestampMs >= last.timestampMs else {
                return false
            }

            if bucketTimestampMs == last.timestampMs {
                let source: MarketChartCandleSource =
                    last.source == .historical ? .historicalUpdatedByLive : last.source
                candles[candles.count - 1] = MarketChartCandle(
                    provider: last.provider, environment: last.environment,
                    instrumentId: last.instrumentId, resolution: last.resolution,
                    timestampMs: last.timestampMs,
                    bid: Self.updated(last.bid, with: quote.bid),
                    ask: Self.updated(last.ask, with: quote.ask),
                    providerVolume: last.providerVolume,
                    providerVolumeField: last.providerVolumeField,
                    receivedAtMs: quote.receivedAtMs, source: source
                )
            } else {
                candles.append(Self.newCandle(
                    quote, instrumentId: instrumentId,
                    resolution: resolution, timestampMs: bucketTimestampMs
                ))
            }
        } else {
            candles.append(Self.newCandle(
                quote, instrumentId: instrumentId,
                resolution: resolution, timestampMs: bucketTimestampMs
            ))
        }

        lastAcceptedProviderTimestampMs = quote.providerTimestampMs
        return true
    }

    private func supportsFixedUTCInterval(_ resolution: HistoricalPriceResolution) -> Bool {
        switch resolution {
        case .minute, .fiveMinutes, .fifteenMinutes, .thirtyMinutes, .hour:
            return true
        case .fourHours, .day, .week:
            return false
        }
    }

    private static func updated(_ previous: HistoricalOHLC, with price: Double) -> HistoricalOHLC {
        HistoricalOHLC(
            open: previous.open, high: max(previous.high, price),
            low: min(previous.low, price), close: price
        )
    }

    private static func newCandle(
        _ quote: MarketDataStreamQuote, instrumentId: String,
        resolution: HistoricalPriceResolution, timestampMs: Int64
    ) -> MarketChartCandle {
        MarketChartCandle(
            provider: "capital.com", environment: "DEMO",
            instrumentId: instrumentId, resolution: resolution,
            timestampMs: timestampMs,
            bid: HistoricalOHLC(open: quote.bid, high: quote.bid, low: quote.bid, close: quote.bid),
            ask: HistoricalOHLC(open: quote.ask, high: quote.ask, low: quote.ask, close: quote.ask),
            providerVolume: nil, providerVolumeField: nil,
            receivedAtMs: quote.receivedAtMs, source: .liveAggregated
        )
    }
}
