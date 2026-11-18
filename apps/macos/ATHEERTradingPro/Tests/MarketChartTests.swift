import SwiftUI
import XCTest
@testable import ATHEERTradingPro

@MainActor
private final class StubMarketHistoryClient: MarketHistoryClient {
    let result: Result<HistoricalCandleBatch, Error>
    private(set) var requestedInstrumentId: String?
    private(set) var requestedResolution: HistoricalPriceResolution?
    private(set) var requestedMaximum: Int?

    init(result: Result<HistoricalCandleBatch, Error>) {
        self.result = result
    }

    func fetchHistory(
        instrumentId: String,
        resolution: HistoricalPriceResolution,
        maximum: Int
    ) async throws -> HistoricalCandleBatch {
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
      "receivedAtMs": 1795000001000,
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
      "quality": {"receivedCount": 1, "normalizedCount": 1, "duplicateCount": 0, "observedGaps": []},
      "request": {"from": null, "to": null, "max": 500},
      "pagination": {"limitReached": false}
    }
    """

    private var validBatch: HistoricalCandleBatch {
        get throws {
            try MarketHistoryPayloadDecoder().decode(
                Data(validPayload.utf8),
                expectedInstrumentId: "GOLD",
                expectedResolution: .minute,
                maximum: 500
            )
        }
    }

    func testHistoricalDecoderPreservesSeparateBidAskAndProviderLineage() throws {
        let batch = try validBatch
        XCTAssertEqual(batch.provider, "capital.com")
        XCTAssertEqual(batch.environment, "DEMO")
        XCTAssertEqual(batch.candles.count, 1)
        XCTAssertEqual(batch.candles[0].bid.close, 102.0)
        XCTAssertEqual(batch.candles[0].ask.close, 102.2)
        XCTAssertEqual(batch.candles[0].providerVolumeField, "lastTradedVolume")
        XCTAssertEqual(batch.quality.duplicateCount, 0)
        XCTAssertEqual(batch.receivedAtMs, 1795000001000)
        XCTAssertNotEqual(batch.candles[0].bid, batch.candles[0].ask)
    }

    func testHistoricalDecoderRejectsWrongInstrumentAndCrossedBidAsk() {
        let decoder = MarketHistoryPayloadDecoder()
        XCTAssertThrowsError(try decoder.decode(
            Data(validPayload.utf8),
            expectedInstrumentId: "EURUSD",
            expectedResolution: .minute,
            maximum: 500
        ))
        let crossed = validPayload.replacingOccurrences(
            of: "\"ask\": {\"open\": 100.2",
            with: "\"ask\": {\"open\": 99.2"
        )
        XCTAssertThrowsError(try decoder.decode(
            Data(crossed.utf8),
            expectedInstrumentId: "GOLD",
            expectedResolution: .minute,
            maximum: 500
        ))
    }

    func testHistoricalDecoderRejectsUnsupportedProviderAndInvalidOHLC() {
        let wrongProvider = validPayload.replacingOccurrences(
            of: "\"provider\": \"capital.com\"",
            with: "\"provider\": \"other-provider\""
        )
        XCTAssertThrowsError(try MarketHistoryPayloadDecoder().decode(
            Data(wrongProvider.utf8),
            expectedInstrumentId: "GOLD",
            expectedResolution: .minute,
            maximum: 500
        ))
        let invalidOHLC = validPayload.replacingOccurrences(
            of: "\"high\": 103.0",
            with: "\"high\": 98.0"
        )
        XCTAssertThrowsError(try MarketHistoryPayloadDecoder().decode(
            Data(invalidOHLC.utf8),
            expectedInstrumentId: "GOLD",
            expectedResolution: .minute,
            maximum: 500
        ))
    }

    func testHistoricalDecoderRejectsRawCountAboveRequestedMaximum() {
        let overLimit = validPayload
            .replacingOccurrences(of: "\"receivedCount\": 1", with: "\"receivedCount\": 501")
            .replacingOccurrences(of: "\"duplicateCount\": 0", with: "\"duplicateCount\": 500")
            .replacingOccurrences(of: "\"limitReached\": false", with: "\"limitReached\": true")
        XCTAssertThrowsError(try MarketHistoryPayloadDecoder().decode(
            Data(overLimit.utf8),
            expectedInstrumentId: "GOLD",
            expectedResolution: .minute,
            maximum: 500
        ))
    }

    func testHistoricalDecoderRejectsInconsistentPaginationMetadata() {
        let inconsistent = validPayload.replacingOccurrences(
            of: "\"limitReached\": false",
            with: "\"limitReached\": true"
        )
        XCTAssertThrowsError(try MarketHistoryPayloadDecoder().decode(
            Data(inconsistent.utf8),
            expectedInstrumentId: "GOLD",
            expectedResolution: .minute,
            maximum: 500
        ))
    }

    func testHistoricalDecoderRejectsFutureDatedCandleTimestamp() {
        let futureDated = validPayload.replacingOccurrences(
            of: "\"timestampMs\": 1795000000000",
            with: "\"timestampMs\": 1795000002000"
        )
        XCTAssertThrowsError(try MarketHistoryPayloadDecoder().decode(
            Data(futureDated.utf8),
            expectedInstrumentId: "GOLD",
            expectedResolution: .minute,
            maximum: 500
        ))
    }

    func testHistoricalDecoderAcceptsCandleTimestampEqualToReceiptTime() throws {
        let receiptTimeCandle = validPayload.replacingOccurrences(
            of: "\"timestampMs\": 1795000000000",
            with: "\"timestampMs\": 1795000001000"
        )
        let batch = try MarketHistoryPayloadDecoder().decode(
            Data(receiptTimeCandle.utf8),
            expectedInstrumentId: "GOLD",
            expectedResolution: .minute,
            maximum: 500
        )
        XCTAssertEqual(batch.candles.count, 1)
    }

    @MainActor
    func testRequestBuilderUsesDynamicBackendPortAndPrivateCapability() throws {
        let capability = try BackendIPCCapability(testBytes: Data(repeating: 0x42, count: 32))
        let connection = BackendIPCConnection(
            baseURL: URL(string: "http://127.0.0.1:45123")!,
            capability: capability,
            credentialSocketURL: URL(fileURLWithPath: "/tmp/atheer-test-broker.sock")
        )
        let request = try MarketHistoryRequestBuilder.makeRequest(
            connection: connection,
            instrumentId: "GOLD",
            resolution: .minute,
            maximum: 500
        )

        XCTAssertEqual(request.url?.host, "127.0.0.1")
        XCTAssertEqual(request.url?.port, 45123)
        XCTAssertEqual(request.url?.path, "/market-data/history")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), capability.authorizationHeaderValue)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-ATHEER-LOCAL-CLIENT"), "macOS")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Cache-Control"), "no-store")
        let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(query.first(where: { $0.name == "epic" })?.value, "GOLD")
        XCTAssertEqual(query.first(where: { $0.name == "resolution" })?.value, "MINUTE")
        XCTAssertEqual(query.first(where: { $0.name == "max" })?.value, "500")
        capability.clear()
    }

    @MainActor
    func testRequestBuilderRejectsInvalidInstrumentAndMaximum() throws {
        let capability = try BackendIPCCapability(testBytes: Data(repeating: 0x11, count: 32))
        let connection = BackendIPCConnection(
            baseURL: URL(string: "http://127.0.0.1:45123")!,
            capability: capability,
            credentialSocketURL: URL(fileURLWithPath: "/tmp/atheer-test-broker.sock")
        )
        XCTAssertThrowsError(try MarketHistoryRequestBuilder.makeRequest(
            connection: connection,
            instrumentId: "GOLD/../../orders",
            resolution: .minute,
            maximum: 500
        ))
        XCTAssertThrowsError(try MarketHistoryRequestBuilder.makeRequest(
            connection: connection,
            instrumentId: "GOLD",
            resolution: .minute,
            maximum: 0
        ))
        capability.clear()
    }

    @MainActor
    func testChartViewModelLoadsSelectedInstrumentAndUsesProviderReceiptTime() async throws {
        let batch = try validBatch
        let client = StubMarketHistoryClient(result: .success(batch))
        let model = MarketChartViewModel(client: client, initialInstrumentId: "GOLD")
        await model.load()

        XCTAssertEqual(model.selectedInstrumentId, "GOLD")
        XCTAssertEqual(model.state, .loaded)
        XCTAssertEqual(model.candles.count, 1)
        XCTAssertEqual(client.requestedInstrumentId, "GOLD")
        XCTAssertEqual(client.requestedResolution, .minute)
        XCTAssertEqual(client.requestedMaximum, 500)
        XCTAssertEqual(model.lastUpdatedAt, Date(timeIntervalSince1970: 1_795_000_001))
    }

    @MainActor
    func testChartViewModelCancellationDoesNotBecomeBackendFailure() async throws {
        let model = MarketChartViewModel(
            client: StubMarketHistoryClient(result: .failure(CancellationError())),
            initialInstrumentId: "GOLD"
        )
        await model.load()
        XCTAssertEqual(model.state, .idle)
        XCTAssertTrue(model.candles.isEmpty)
    }

    @MainActor
    func testChartViewModelClearsSeriesWhenInstrumentIsCleared() async throws {
        let batch = try validBatch
        let model = MarketChartViewModel(
            client: StubMarketHistoryClient(result: .success(batch)),
            initialInstrumentId: "GOLD"
        )
        await model.load()
        model.selectInstrument(nil)
        XCTAssertNil(model.selectedInstrumentId)
        XCTAssertTrue(model.candles.isEmpty)
        XCTAssertEqual(model.state, .idle)
    }
}
