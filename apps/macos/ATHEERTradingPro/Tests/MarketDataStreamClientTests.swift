import Foundation
import XCTest
@testable import ATHEERTradingPro

@MainActor
private final class MockMarketDataStreamClient: MarketDataStreamClient {
    private(set) var requestedEpics: [String] = []
    private var continuation: AsyncThrowingStream<MarketDataStreamEvent, Error>.Continuation?
    var isReady: Bool { continuation != nil }

    func events(for epics: [String]) -> AsyncThrowingStream<MarketDataStreamEvent, Error> {
        requestedEpics = epics
        return AsyncThrowingStream { [weak self] continuation in
            Task { @MainActor in
                self?.continuation = continuation
            }
        }
    }

    func yield(_ event: MarketDataStreamEvent) {
        continuation?.yield(event)
    }

    func finish() {
        continuation?.finish()
    }
}

final class MarketDataStreamClientTests: XCTestCase {
    func testStreamRequestUsesLoopbackAndBearerCapability() throws {
        let request = try MarketDataStreamRequestBuilder.makeRequest(
            baseURL: URL(string: "http://127.0.0.1:43127")!,
            epics: ["WTI", "EURUSD", "WTI"],
            authorization: "Bearer capability-token"
        )

        XCTAssertEqual(request.url?.host, "127.0.0.1")
        XCTAssertEqual(request.url?.path, "/market-data/stream")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer capability-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "text/event-stream")
        let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        XCTAssertEqual(
            components?.queryItems?.first(where: { $0.name == "epics" })?.value,
            "EURUSD,WTI"
        )

        XCTAssertThrowsError(try MarketDataStreamRequestBuilder.makeRequest(
            baseURL: URL(string: "http://example.com:43127")!,
            epics: ["WTI"],
            authorization: "Bearer capability-token"
        ))
        XCTAssertThrowsError(try MarketDataStreamRequestBuilder.makeRequest(
            baseURL: URL(string: "http://127.0.0.1:43127")!,
            epics: ["WTI"],
            authorization: "invalid-token"
        ))
    }

    func testParserDecodesDEMOStatusEvent() throws {
        var parser = ServerSentEventParser()
        let payload = """
        {"provider":"capital.com","environment":"DEMO","state":"connected","activeInstrumentCount":2,"lastMessageAtMs":1800000000000,"lastError":null,"invalidQuoteCount":0,"outOfOrderQuoteCount":1,"duplicateQuoteCount":0}
        """

        XCTAssertNil(try parser.consume("event: status"))
        XCTAssertNil(try parser.consume("data: \(payload)"))
        let event = try parser.consume("")

        guard case .status(let status) = event else {
            return XCTFail("Expected a status event.")
        }
        XCTAssertEqual(status.provider, "capital.com")
        XCTAssertEqual(status.environment, "DEMO")
        XCTAssertEqual(status.state, .connected)
        XCTAssertEqual(status.activeInstrumentCount, 2)
        XCTAssertEqual(status.outOfOrderQuoteCount, 1)
    }

    func testParserDecodesFreshDEMOQuoteEvent() throws {
        var parser = ServerSentEventParser()
        let payload = """
        {"provider":"capital.com","environment":"DEMO","instrumentId":"AAPL","bid":100.0,"ask":100.1,"providerTimestampMs":1800000000000,"receivedAtMs":1800000000010,"receivedAtMonotonicMs":123.0,"freshness":{"state":"fresh","ageMs":100.0,"maximumAgeMs":5000,"automatedDecisionsAllowed":true,"reason":"within_policy"}}
        """

        XCTAssertNil(try parser.consume("event: quote"))
        XCTAssertNil(try parser.consume("data: \(payload)"))
        let event = try parser.consume("")

        guard case .quote(let quote) = event else {
            return XCTFail("Expected a quote event.")
        }
        XCTAssertEqual(quote.instrumentId, "AAPL")
        XCTAssertEqual(quote.bid, 100.0)
        XCTAssertEqual(quote.ask, 100.1)
        XCTAssertEqual(quote.freshness.state, .fresh)
        XCTAssertTrue(quote.freshness.automatedDecisionsAllowed)
    }

    func testParserRejectsOversizedEventPayload() throws {
        var parser = ServerSentEventParser()
        _ = try parser.consume("event: status")
        let oversized = "data: " + String(repeating: "x", count: 65_536)
        XCTAssertThrowsError(try parser.consume(oversized))
    }

    func testParserRejectsUnboundedFreshnessThreshold() throws {
        var parser = ServerSentEventParser()
        _ = try parser.consume("event: quote")
        let payload = #"{"provider":"capital.com","environment":"DEMO","instrumentId":"AAPL","bid":1,"ask":2,"providerTimestampMs":1800000000000,"receivedAtMs":1800000000000,"receivedAtMonotonicMs":1,"freshness":{"state":"fresh","ageMs":0,"maximumAgeMs":60001,"reason":"within_threshold","automatedDecisionsAllowed":true}}"#
        _ = try parser.consume("data: \(payload)")
        XCTAssertThrowsError(try parser.consume(""))
    }

    func testParserRejectsCrossedQuoteAndInconsistentFreshnessPolicy() {
        var crossedParser = ServerSentEventParser()
        let crossedQuote = """
        {"provider":"capital.com","environment":"DEMO","instrumentId":"AAPL","bid":100.2,"ask":100.1,"providerTimestampMs":1800000000000,"receivedAtMs":1800000000010,"receivedAtMonotonicMs":123.0,"freshness":{"state":"fresh","ageMs":100.0,"automatedDecisionsAllowed":true,"reason":"within_policy"}}
        """
        XCTAssertNil(try? crossedParser.consume("event: quote"))
        XCTAssertNil(try? crossedParser.consume("data: \(crossedQuote)"))
        XCTAssertThrowsError(try crossedParser.consume(""))

        var freshnessParser = ServerSentEventParser()
        let inconsistentFreshness = """
        {"provider":"capital.com","environment":"DEMO","instrumentId":"AAPL","bid":100.0,"ask":100.1,"providerTimestampMs":1800000000000,"receivedAtMs":1800000000010,"receivedAtMonotonicMs":123.0,"freshness":{"state":"stale","ageMs":9000.0,"maximumAgeMs":5000,"automatedDecisionsAllowed":true,"reason":"quote_too_old"}}
        """
        XCTAssertNil(try? freshnessParser.consume("event: quote"))
        XCTAssertNil(try? freshnessParser.consume("data: \(inconsistentFreshness)"))
        XCTAssertThrowsError(try freshnessParser.consume(""))
    }

    func testParserPreservesInvalidFutureTimestampQuoteForQualityDisplay() throws {
        var parser = ServerSentEventParser()
        let payload = """
        {"provider":"capital.com","environment":"DEMO","instrumentId":"WTI","bid":80.0,"ask":80.1,"providerTimestampMs":1800000000020,"receivedAtMs":1800000000010,"receivedAtMonotonicMs":123.0,"freshness":{"state":"invalid","ageMs":-10.0,"maximumAgeMs":5000,"automatedDecisionsAllowed":false,"reason":"provider_timestamp_in_future"}}
        """

        XCTAssertNil(try parser.consume("event: quote"))
        XCTAssertNil(try parser.consume("data: \(payload)"))
        guard case .quote(let quote) = try parser.consume("") else {
            return XCTFail("Expected an invalid quote to remain visible for diagnostics.")
        }
        XCTAssertEqual(quote.freshness.state, .invalid)
        XCTAssertFalse(quote.freshness.automatedDecisionsAllowed)
    }

    func testQuoteBecomesLocallyStaleAfterBackendFreshnessWindow() {
        let quote = MarketDataStreamQuote(
            provider: "capital.com",
            environment: "DEMO",
            instrumentId: "AAPL",
            bid: 100,
            ask: 100.1,
            providerTimestampMs: 1_800_000_000_000,
            receivedAtMs: 1_800_000_000_010,
            receivedAtMonotonicMs: 123,
            freshness: MarketDataQuoteFreshness(
                state: .fresh,
                ageMs: 100,
                maximumAgeMs: 5_000,
                automatedDecisionsAllowed: true,
                reason: "within_policy"
            )
        )
        let snapshot = MarketDataStreamQuoteSnapshot(
            quote: quote,
            receivedAtUptime: ProcessInfo.processInfo.systemUptime - 6
        )
        XCTAssertEqual(snapshot.effectiveFreshnessState, .stale)
    }

    @MainActor
    func testViewModelStreamsSelectedInstrumentQuotesAndStopsCleanly() async {
        let client = MockMarketDataStreamClient()
        let model = MarketDataStreamViewModel(client: client)
        model.toggleSelection(" AAPL ")
        model.startMonitoring()

        let subscriptionDeadline = Date().addingTimeInterval(1)
        while !client.isReady && Date() < subscriptionDeadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertEqual(client.requestedEpics, ["AAPL"])

        client.yield(.status(MarketDataStreamStatus(
            provider: "capital.com",
            environment: "DEMO",
            state: .connected,
            activeInstrumentCount: 1,
            lastMessageAtMs: 1_800_000_000_000,
            lastError: nil,
            invalidQuoteCount: 0,
            outOfOrderQuoteCount: 0,
            duplicateQuoteCount: 0
        )))
        client.yield(.quote(MarketDataStreamQuote(
            provider: "capital.com",
            environment: "DEMO",
            instrumentId: "AAPL",
            bid: 100,
            ask: 100.1,
            providerTimestampMs: 1_800_000_000_000,
            receivedAtMs: 1_800_000_000_010,
            receivedAtMonotonicMs: 123,
            freshness: MarketDataQuoteFreshness(
                state: .fresh,
                ageMs: 100,
                maximumAgeMs: 5_000,
                automatedDecisionsAllowed: true,
                reason: "within_policy"
            )
        )))

        let quoteDeadline = Date().addingTimeInterval(1)
        while model.quotes["AAPL"] == nil && Date() < quoteDeadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTAssertEqual(model.connectionState, .connected)
        XCTAssertEqual(model.quotes["AAPL"]?.quote.bid, 100)
        XCTAssertEqual(model.selectedCount, 1)

        model.stopMonitoring(clearQuotes: true)
        client.finish()
        XCTAssertFalse(model.isMonitoring)
        XCTAssertTrue(model.quotes.isEmpty)
        XCTAssertEqual(model.connectionState, .disconnected)
    }

    @MainActor
    func testViewModelEnforcesFortyInstrumentSubscriptionLimit() {
        let model = MarketDataStreamViewModel(client: MockMarketDataStreamClient())
        for index in 0..<40 {
            model.toggleSelection("EPIC_\(index)")
        }

        XCTAssertEqual(model.selectedCount, 40)
        XCTAssertFalse(model.canSelect("EPIC_40"))
        model.toggleSelection("EPIC_0")
        XCTAssertEqual(model.selectedCount, 39)
        XCTAssertTrue(model.canSelect("EPIC_40"))
    }
}
