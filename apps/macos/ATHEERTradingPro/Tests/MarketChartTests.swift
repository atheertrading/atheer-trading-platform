import SwiftUI
import XCTest
@testable import ATHEERTradingPro

@MainActor
private final class StubMarketHistoryClient: MarketHistoryClient {
    let result: Result<HistoricalCandleBatch, Error>
    private(set) var requestedInstrumentId: String?
    private(set) var requestedResolution: HistoricalPriceResolution?
    private(set) var requestedMaximum: Int?

    init(result: Result<HistoricalCandleBatch, Error>) { self.result = result }

    func fetchHistory(instrumentId: String, resolution: HistoricalPriceResolution, maximum: Int) async throws -> HistoricalCandleBatch {
        requestedInstrumentId = instrumentId
        requestedResolution = resolution
        requestedMaximum = maximum
        return try result.get()
    }
}

final class MarketChartTests: XCTestCase {
    private let validPayload = """
    {
      "provider": "capital.com",
      "environment": "DEMO",
      "instrumentId": "GOLD",
      "resolution": "MINUTE",
      "candles": [{
        "provider": "capital.com",
        "environment": "DEMO",
        "instrumentId": "GOLD",
        "resolution": "MINUTE",
        "timestampMs": 1795000000000,
        "bid": {"open": 100.0, "high": 103.0, "low": 99.0, "close": 102.0},
        "ask": {"open": 100.2, "high": 103.2, "low": 99.2, "close": 102.2},
        "providerVolume": 18.0,
        "providerVolumeField": "lastTradedVolume",
        "receivedAtMs": 1795000001000
      }],
      "quality": {"receivedCount": 2, "normalizedCount": 1, "duplicateCount": 1, "observedGaps": []}
    }
    """

    func testHistoricalDecoderPreservesSeparateBidAskAndProviderLineage() throws {
        let batch = try MarketHistoryPayloadDecoder().decode(Data(validPayload.utf8), expectedInstrumentId: "GOLD", expectedResolution: .minute, maximum: 500)
        XCTAssertEqual(batch.provider, "capital.com")
        XCTAssertEqual(batch.environment, "DEMO")
        XCTAssertEqual(batch.candles.count, 1)
        XCTAssertEqual(batch.candles[0].bid.close, 102.0)
        XCTAssertEqual(batch.candles[0].ask.close, 102.2)
        XCTAssertEqual(batch.candles[0].providerVolumeField, "lastTradedVolume")
        XCTAssertEqual(batch.quality.duplicateCount, 1)
        XCTAssertNotEqual(batch.candles[0].bid, batch.candles[0].ask)
    }

    func testHistoricalDecoderRejectsWrongInstrumentAndCrossedBidAsk() {
        let decoder = MarketHistoryPayloadDecoder()
        XCTAssertThrowsError(try decoder.decode(Data(validPayload.utf8), expectedInstrumentId: "EURUSD", expectedResolution: .minute, maximum: 500))
        let crossed = validPayload.replacingOccurrences(of: "\"ask\": {\"open\": 100.2", with: "\"ask\": {\"open\": 99.2")
        XCTAssertThrowsError(try decoder.decode(Data(crossed.utf8), expectedInstrumentId: "GOLD", expectedResolution: .minute, maximum: 500))
    }

    func testHistoricalDecoderRejectsUnsupportedProviderAndInvalidOHLC() {
        let wrongProvider = validPayload.replacingOccurrences(of: "\"provider\": \"capital.com\"", with: "\"provider\": \"other-provider\"")
        XCTAssertThrowsError(try MarketHistoryPayloadDecoder().decode(Data(wrongProvider.utf8), expectedInstrumentId: "GOLD", expectedResolution: .minute, maximum: 500))
        let invalidOHLC = validPayload.replacingOccurrences(of: "\"high\": 103.0", with: "\"high\": 98.0")
        XCTAssertThrowsError(try MarketHistoryPayloadDecoder().decode(Data(invalidOHLC.utf8), expectedInstrumentId: "GOLD", expectedResolution: .minute, maximum: 500))
    }

    func testHistoricalDecoderRejectsIncompleteProviderVolumeLineage() {
        let incompleteLineage = validPayload.replacingOccurrences(
            of: "\"providerVolumeField\": \"lastTradedVolume\"",
            with: "\"providerVolumeField\": null"
        )
        XCTAssertThrowsError(try MarketHistoryPayloadDecoder().decode(
            Data(incompleteLineage.utf8),
            expectedInstrumentId: "GOLD",
            expectedResolution: .minute,
            maximum: 500
        ))
    }

    @MainActor
    func testChartViewModelLoadsOnlyTheSelectedWatchlistInstrument() async throws {
        let batch = try MarketHistoryPayloadDecoder().decode(Data(validPayload.utf8), expectedInstrumentId: "GOLD", expectedResolution: .minute, maximum: 500)
        let client = StubMarketHistoryClient(result: .success(batch))
        let model = MarketChartViewModel(client: client)
        model.synchronizeWatchlist(["GOLD", "US500"])
        await model.load()
        XCTAssertEqual(model.selectedInstrumentId, "GOLD")
        XCTAssertEqual(model.state, .loaded)
        XCTAssertEqual(model.candles.count, 1)
        XCTAssertEqual(client.requestedInstrumentId, "GOLD")
        XCTAssertEqual(client.requestedResolution, .minute)
        XCTAssertEqual(client.requestedMaximum, 500)
    }

    private func makeHistoricalCandle(timestampMs: Int64) -> NormalizedHistoricalCandle {
        NormalizedHistoricalCandle(
            provider: "capital.com", environment: "DEMO", instrumentId: "GOLD",
            resolution: .minute, timestampMs: timestampMs,
            bid: HistoricalOHLC(open: 100, high: 102, low: 99, close: 101),
            ask: HistoricalOHLC(open: 100.2, high: 102.2, low: 99.2, close: 101.2),
            providerVolume: nil, providerVolumeField: nil, receivedAtMs: timestampMs + 100
        )
    }

    private func makeQuote(
        timestampMs: Int64, bid: Double, ask: Double, instrumentId: String = "GOLD",
        environment: String = "DEMO", freshnessState: String = "fresh",
        automatedDecisionsAllowed: Bool = true, ageMs: Double? = 100,
        receivedAtOffsetMs: Int64 = 100
    ) -> MarketDataStreamQuote {
        MarketDataStreamQuote(
            provider: "capital.com", environment: environment, instrumentId: instrumentId,
            bid: bid, ask: ask, providerTimestampMs: timestampMs,
            receivedAtMs: timestampMs + receivedAtOffsetMs, receivedAtMonotonicMs: 1_000,
            freshness: MarketDataQuoteFreshness(
                state: freshnessState, ageMs: ageMs,
                automatedDecisionsAllowed: automatedDecisionsAllowed,
                reason: freshnessState == "fresh" ? "within_policy" : "quote_too_old"
            )
        )
    }

    func testLiveAggregatorUpdatesBidAskOHLCIndependentlyWithinExistingBucket() {
        let interval: Int64 = 60_000
        let bucket = (1_800_000_000_000 / interval) * interval
        var candles = [MarketChartCandle(historical: makeHistoricalCandle(timestampMs: bucket))]
        var aggregator = LiveCandleAggregator()
        XCTAssertTrue(aggregator.ingest(makeQuote(timestampMs: bucket + 10_000, bid: 103, ask: 103.2),
                                        instrumentId: "GOLD", resolution: .minute, candles: &candles))
        XCTAssertEqual(candles.count, 1)
        XCTAssertEqual(candles[0].source, .historicalUpdatedByLive)
        XCTAssertEqual(candles[0].bid.open, 100)
        XCTAssertEqual(candles[0].bid.high, 103)
        XCTAssertEqual(candles[0].bid.low, 99)
        XCTAssertEqual(candles[0].bid.close, 103)
        XCTAssertEqual(candles[0].ask.high, 103.2)
        XCTAssertEqual(candles[0].ask.close, 103.2)
    }

    func testLiveAggregatorAppendsOneBarWithoutSyntheticGapFilling() {
        let interval: Int64 = 60_000
        let bucket = (1_800_000_000_000 / interval) * interval
        var candles = [MarketChartCandle(historical: makeHistoricalCandle(timestampMs: bucket))]
        var aggregator = LiveCandleAggregator()
        XCTAssertTrue(aggregator.ingest(
            makeQuote(timestampMs: bucket + interval * 3 + 5_000, bid: 104, ask: 104.2),
            instrumentId: "GOLD", resolution: .minute, candles: &candles
        ))
        XCTAssertEqual(candles.count, 2, "The aggregator must not synthesize missing intervals.")
        XCTAssertEqual(candles[1].timestampMs, bucket + interval * 3)
        XCTAssertEqual(candles[1].source, .liveAggregated)
        XCTAssertEqual(candles[1].bid.open, 104)
        XCTAssertNil(candles[1].providerVolume)
        XCTAssertNil(candles[1].providerVolumeField)
    }

    func testLiveAggregatorRejectsStaleFutureAndOutOfOrderQuotes() {
        let interval: Int64 = 60_000
        let bucket = (1_800_000_000_000 / interval) * interval
        var candles = [MarketChartCandle(historical: makeHistoricalCandle(timestampMs: bucket))]
        var aggregator = LiveCandleAggregator()
        XCTAssertFalse(aggregator.ingest(
            makeQuote(timestampMs: bucket + 10_000, bid: 101, ask: 101.2,
                      freshnessState: "stale", automatedDecisionsAllowed: false),
            instrumentId: "GOLD", resolution: .minute, candles: &candles
        ))
        XCTAssertFalse(aggregator.ingest(
            makeQuote(timestampMs: bucket + 10_000, bid: 101, ask: 101.2, receivedAtOffsetMs: -500),
            instrumentId: "GOLD", resolution: .minute, candles: &candles
        ))
        XCTAssertTrue(aggregator.ingest(
            makeQuote(timestampMs: bucket + 20_000, bid: 103, ask: 103.2),
            instrumentId: "GOLD", resolution: .minute, candles: &candles
        ))
        XCTAssertFalse(aggregator.ingest(
            makeQuote(timestampMs: bucket + 15_000, bid: 99, ask: 99.2),
            instrumentId: "GOLD", resolution: .minute, candles: &candles
        ))
        XCTAssertEqual(candles.count, 1)
        XCTAssertEqual(candles[0].bid.low, 99)
    }

    func testLiveAggregatorDefersSessionAlignedResolutionsUntilCalendarContractExists() {
        var candles: [MarketChartCandle] = []
        var aggregator = LiveCandleAggregator()
        let quote = makeQuote(timestampMs: 1_800_000_000_000, bid: 100, ask: 100.2)
        XCTAssertFalse(aggregator.ingest(quote, instrumentId: "GOLD", resolution: .fourHours, candles: &candles))
        XCTAssertFalse(aggregator.ingest(quote, instrumentId: "GOLD", resolution: .day, candles: &candles))
        XCTAssertFalse(aggregator.ingest(quote, instrumentId: "GOLD", resolution: .week, candles: &candles))
        XCTAssertTrue(candles.isEmpty)
    }

    @MainActor
    func testChartModelConsumesEveryQuoteEventFromAppScopedBus() async throws {
        let interval: Int64 = 60_000
        let bucket = (1_800_000_000_000 / interval) * interval
        let historical = makeHistoricalCandle(timestampMs: bucket)
        let batch = HistoricalCandleBatch(
            provider: "capital.com", environment: "DEMO", instrumentId: "GOLD", resolution: .minute,
            candles: [historical],
            quality: HistoricalCandleQuality(receivedCount: 1, normalizedCount: 1, duplicateCount: 0, observedGaps: [])
        )
        let bus = MarketDataQuoteEventBus()
        let model = MarketChartViewModel(client: StubMarketHistoryClient(result: .success(batch)), quoteEventBus: bus)
        model.selectInstrument("GOLD")
        await model.load()
        bus.publish(makeQuote(timestampMs: bucket + 5_000, bid: 110, ask: 110.2))
        bus.publish(makeQuote(timestampMs: bucket + 10_000, bid: 101, ask: 101.2))
        XCTAssertEqual(model.liveCandleUpdateCount, 0, "Stream ingestion must not publish every tick to SwiftUI.")
        try await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertEqual(model.candles.count, 1)
        XCTAssertEqual(model.candles[0].bid.high, 110)
        XCTAssertEqual(model.candles[0].bid.close, 101)
        XCTAssertEqual(model.liveCandleUpdateCount, 2)
        XCTAssertNotNil(model.liveUpdatedAt)
    }

    @MainActor
    func testChartViewModelCancellationDoesNotBecomeBackendFailure() async throws {
        let client = StubMarketHistoryClient(result: .failure(CancellationError()))
        let model = MarketChartViewModel(client: client)
        model.synchronizeWatchlist(["GOLD"])
        await model.load()
        XCTAssertEqual(model.state, .idle)
        XCTAssertTrue(model.candles.isEmpty)
    }

    @MainActor
    func testChartViewModelClearsSeriesWhenSelectedInstrumentLeavesWatchlist() async throws {
        let batch = try MarketHistoryPayloadDecoder().decode(Data(validPayload.utf8), expectedInstrumentId: "GOLD", expectedResolution: .minute, maximum: 500)
        let model = MarketChartViewModel(client: StubMarketHistoryClient(result: .success(batch)))
        model.synchronizeWatchlist(["GOLD"])
        await model.load()
        model.synchronizeWatchlist([])
        XCTAssertNil(model.selectedInstrumentId)
        XCTAssertTrue(model.candles.isEmpty)
        if case .unavailable = model.state { XCTAssertTrue(true) }
        else { XCTFail("Removing the selected instrument must clear the historical series.") }
    }

    @MainActor
    func testChartWorkspaceAcceptsSharedAppScopedModelAndWatchlist() {
        let view = ChartWorkspaceView(model: MarketChartViewModel(), watchlistStore: MarketWatchlistStore(), onOpenMarkets: {})
        XCTAssertNotNil(view)
    }

    func testLiveAggregatorRetainsOnlyTheMostRecent500Candles() {
        let interval: Int64 = 60_000
        let start: Int64 = 1_800_000_000_000
        var candles: [MarketChartCandle] = []
        var aggregator = LiveCandleAggregator()

        for index in 0...500 {
            let timestamp = start + Int64(index) * interval + 1_000
            let bid = 100.0 + Double(index)
            XCTAssertTrue(aggregator.ingest(
                makeQuote(timestampMs: timestamp, bid: bid, ask: bid + 0.2),
                instrumentId: "GOLD",
                resolution: .minute,
                candles: &candles
            ))
        }

        XCTAssertEqual(candles.count, 500)
        XCTAssertEqual(candles.first?.timestampMs, start + interval)
        XCTAssertEqual(candles.last?.timestampMs, start + 500 * interval)
        XCTAssertEqual(candles.first?.bid.open, 101.0)
        XCTAssertEqual(candles.last?.bid.close, 600.0)
        XCTAssertEqual(candles.first?.source, .liveAggregated)
        XCTAssertEqual(candles.last?.source, .liveAggregated)
    }

}
