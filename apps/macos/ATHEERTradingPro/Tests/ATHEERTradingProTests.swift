import XCTest
@testable import ATHEERTradingPro

final class ATHEERTradingProTests: XCTestCase {
    @MainActor
    func testApplicationShellCanBeInstantiated() {
        let view = ContentView()
        XCTAssertNotNil(view)
    }

    func testNavigationExposesOnlyImplementedDestinations() {
        XCTAssertEqual(AppSection.allCases, [.workspace, .apiConnection])
        XCTAssertEqual(AppSection.apiConnection.title, "API Connection")
    }

    func testHealthPayloadDecoderKeepsTradingDisabledWhenPlatformIsNotReady() throws {
        let liveness = Data("""
        {"status":"ok","service":"atheer-api","version":"0.1.0","timestamp":"2026-11-16T10:00:00.000Z"}
        """.utf8)
        let readiness = Data("""
        {"status":"not_ready","service":"atheer-api","timestamp":"2026-11-16T10:00:01.000Z","dependencies":{"persistence":"not_configured","broker":"not_configured"},"trading":{"enabled":false,"status":"disabled"}}
        """.utf8)

        let snapshot = try BackendHealthPayloadDecoder().decode(
            livenessData: liveness,
            livenessStatusCode: 200,
            readinessData: readiness,
            readinessStatusCode: 503
        )

        XCTAssertFalse(snapshot.platformReady)
        XCTAssertEqual(snapshot.persistenceStatus, "not_configured")
        XCTAssertEqual(snapshot.brokerStatus, "not_configured")
        XCTAssertFalse(snapshot.tradingEnabled)
        XCTAssertEqual(snapshot.tradingStatus, "disabled")
        XCTAssertEqual(snapshot.readinessHTTPStatus, 503)
        XCTAssertEqual(snapshot.livenessTimestamp, "2026-11-16T10:00:00.000Z")
        XCTAssertEqual(snapshot.lastCheckedAt, "2026-11-16T10:00:01.000Z")
    }

    func testHealthPayloadDecoderRejectsInconsistentReadinessStatusCode() {
        let liveness = Data("""
        {"status":"ok","service":"atheer-api","version":"0.1.0","timestamp":"2026-11-16T10:00:00.000Z"}
        """.utf8)
        let readiness = Data("""
        {"status":"not_ready","service":"atheer-api","timestamp":"2026-11-16T10:00:01.000Z","dependencies":{"persistence":"not_configured","broker":"not_configured"},"trading":{"enabled":false,"status":"disabled"}}
        """.utf8)

        XCTAssertThrowsError(try BackendHealthPayloadDecoder().decode(
            livenessData: liveness,
            livenessStatusCode: 200,
            readinessData: readiness,
            readinessStatusCode: 200
        ))
    }

    func testHealthPayloadDecoderRejectsTradingEnabledWhenPlatformIsNotReady() {
        let liveness = Data("""
        {"status":"ok","service":"atheer-api","version":"0.1.0","timestamp":"2026-11-16T10:00:00.000Z"}
        """.utf8)
        let readiness = Data("""
        {"status":"not_ready","service":"atheer-api","timestamp":"2026-11-16T10:00:01.000Z","dependencies":{"persistence":"not_configured","broker":"not_configured"},"trading":{"enabled":true,"status":"enabled"}}
        """.utf8)

        XCTAssertThrowsError(try BackendHealthPayloadDecoder().decode(
            livenessData: liveness,
            livenessStatusCode: 200,
            readinessData: readiness,
            readinessStatusCode: 503
        ))
    }

    @MainActor
    func testViewModelPublishesConnectedButNotReadyState() async {
        let snapshot = BackendHealthSnapshot(
            version: "0.1.0",
            platformReady: false,
            persistenceStatus: "not_configured",
            brokerStatus: "not_configured",
            tradingEnabled: false,
            tradingStatus: "disabled",
            livenessTimestamp: "2026-11-16T10:00:00.000Z",
            readinessHTTPStatus: 503,
            lastCheckedAt: "2026-11-16T10:00:01.000Z"
        )
        let model = BackendHealthViewModel(client: StubBackendHealthClient(result: .success(snapshot)))

        await model.refresh()

        XCTAssertEqual(model.state, .connected(snapshot))
    }

    @MainActor
    func testViewModelReportsDisconnectedWhenBackendCannotBeReached() async {
        let model = BackendHealthViewModel(client: StubBackendHealthClient(result: .failure(.unavailable)))

        await model.refresh()

        if case .disconnected = model.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected a transport-level disconnected state.")
        }
    }

    @MainActor
    func testViewModelDistinguishesInvalidHealthPayloadFromTransportFailure() async {
        let model = BackendHealthViewModel(client: StubBackendHealthClient(result: .failure(BackendHealthError.invalidPayload)))

        await model.refresh()

        XCTAssertEqual(model.state, .invalidResponse("The health API returned an invalid or inconsistent response."))
    }

    @MainActor
    func testViewModelPreservesUnexpectedHTTPStatusAsServerResponse() async {
        let model = BackendHealthViewModel(client: StubBackendHealthClient(result: .failure(BackendHealthError.unexpectedHTTPStatus(502))))

        await model.refresh()

        XCTAssertEqual(model.state, .serverError(502))
    }
}

private struct StubBackendHealthClient: BackendHealthClient {
    let result: Result<BackendHealthSnapshot, Error>

    @MainActor
    func fetchSnapshot() async throws -> BackendHealthSnapshot {
        try result.get()
    }
}

private enum StubBackendHealthError: Error {
    case unavailable
}
