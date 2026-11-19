import XCTest
@testable import ATHEERTradingPro

final class SystemAdministrationPresentationTests: XCTestCase {
    func testUnavailableSourcesRemainExplicitlyUnverified() {
        let presentation = SystemAdministrationPresentation(
            marketDataState: .notChecked,
            backendHealthState: .idle
        )

        XCTAssertEqual(presentation.marketData.value, "NOT CHECKED")
        XCTAssertEqual(presentation.broker.value, "NOT VERIFIED")
        XCTAssertEqual(presentation.account.value, "NO SNAPSHOT")
        XCTAssertEqual(presentation.localAPI.title, "NOT CHECKED")
        XCTAssertEqual(presentation.platform.title, "NOT VERIFIED")
        XCTAssertEqual(presentation.tradingGate.title, "NOT VERIFIED")
        XCTAssertEqual(presentation.provider, "NOT VERIFIED")
        XCTAssertEqual(presentation.environment, "NOT VERIFIED")
        XCTAssertEqual(presentation.backendVersion, "NOT VERIFIED")
    }

    func testPresentationUsesExistingBackendStatusWithoutInferringStreamingOrAccountData() {
        let marketData = MarketDataBackendStatus(
            provider: "capital.com",
            environment: "DEMO",
            state: .connected
        )
        let health = BackendHealthSnapshot(
            version: "0.1.0",
            livenessTimestamp: "2026-11-20T10:00:00.000Z",
            platformReady: false,
            persistenceStatus: "not_configured",
            brokerStatus: "not_configured",
            tradingEnabled: false,
            tradingStatus: "disabled",
            readinessHTTPStatus: 503,
            readinessTimestamp: "2026-11-20T10:00:01.000Z",
            readinessFailure: nil
        )

        let presentation = SystemAdministrationPresentation(
            marketDataState: .available(marketData),
            backendHealthState: .connected(health)
        )

        XCTAssertEqual(presentation.provider, "capital.com")
        XCTAssertEqual(presentation.environment, "DEMO")
        XCTAssertEqual(presentation.marketData.value, "REST CONNECTED")
        XCTAssertTrue(presentation.marketData.detail.contains("streaming is a separate capability"))
        XCTAssertEqual(presentation.broker.value, "NOT CONFIGURED")
        XCTAssertEqual(presentation.account.value, "NO SNAPSHOT")
        XCTAssertEqual(presentation.localAPI.title, "REACHABLE")
        XCTAssertEqual(presentation.platform.title, "NOT READY")
        XCTAssertEqual(presentation.tradingGate.title, "DISABLED")
        XCTAssertEqual(presentation.backendVersion, "0.1.0")
    }

    func testReadinessFailureDoesNotBecomeBrokerOrTradingAuthorization() {
        let health = BackendHealthSnapshot(
            version: "0.1.0",
            livenessTimestamp: "2026-11-20T10:00:00.000Z",
            platformReady: nil,
            persistenceStatus: nil,
            brokerStatus: nil,
            tradingEnabled: nil,
            tradingStatus: nil,
            readinessHTTPStatus: nil,
            readinessTimestamp: nil,
            readinessFailure: .transport("Readiness unavailable.")
        )

        let presentation = SystemAdministrationPresentation(
            marketDataState: .unavailable("Market-data status unavailable."),
            backendHealthState: .connected(health)
        )

        XCTAssertEqual(presentation.broker.value, "NOT VERIFIED")
        XCTAssertEqual(presentation.tradingGate.title, "NOT VERIFIED")
        XCTAssertEqual(presentation.platform.title, "UNAVAILABLE")
        XCTAssertEqual(presentation.marketData.value, "UNAVAILABLE")
        XCTAssertEqual(presentation.provider, "NOT VERIFIED")
        XCTAssertEqual(presentation.environment, "NOT VERIFIED")
    }

    func testEnabledTradingWithoutReadyPlatformIsNotPresentedAsSuccess() {
        let health = BackendHealthSnapshot(
            version: "0.1.0",
            livenessTimestamp: "2026-11-20T10:00:00.000Z",
            platformReady: false,
            persistenceStatus: "not_configured",
            brokerStatus: "connected",
            tradingEnabled: true,
            tradingStatus: "enabled",
            readinessHTTPStatus: 503,
            readinessTimestamp: "2026-11-20T10:00:01.000Z",
            readinessFailure: nil
        )

        let presentation = SystemAdministrationPresentation(
            marketDataState: .notChecked,
            backendHealthState: .connected(health)
        )

        XCTAssertEqual(presentation.tradingGate.title, "NOT VERIFIED")
        XCTAssertEqual(presentation.tradingGate.tone, .attention)
    }
}
