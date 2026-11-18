import SwiftUI
import XCTest

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
}
