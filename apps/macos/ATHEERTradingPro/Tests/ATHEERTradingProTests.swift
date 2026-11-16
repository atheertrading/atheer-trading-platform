import XCTest
@testable import ATHEERTradingPro

final class ATHEERTradingProTests: XCTestCase {
    @MainActor
    func testApplicationShellCanBeInstantiated() {
        let view = ContentView()
        XCTAssertNotNil(view)
    }

    func testHealthPayloadDecoderKeepsTradingDisabledWhenPlatformIsNotReady() throws {
        let liveness = Data("""
        {"status":"ok","service":"atheer-api","version":"0.1.0","timestamp":"2026-11-16T10:00:00.000Z"}
        """.utf8)
        let readiness = Data("""
        {"status":"not_ready","service":"atheer-api","timestamp":"2026-11-16T10:00:00.000Z","dependencies":{"persistence":"not_configured","broker":"not_configured"},"trading":{"enabled":false,"status":"disabled"}}
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
    }

    func testHealthPayloadDecoderRejectsInconsistentReadinessStatusCode() {
        let liveness = Data("""
        {"status":"ok","service":"atheer-api","version":"0.1.0","timestamp":"2026-11-16T10:00:00.000Z"}
        """.utf8)
        let readiness = Data("""
        {"status":"not_ready","service":"atheer-api","timestamp":"2026-11-16T10:00:00.000Z","dependencies":{"persistence":"not_configured","broker":"not_configured"},"trading":{"enabled":false,"status":"disabled"}}
        """.utf8)

        XCTAssertThrowsError(try BackendHealthPayloadDecoder().decode(
            livenessData: liveness,
            livenessStatusCode: 200,
            readinessData: readiness,
            readinessStatusCode: 200
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
            lastCheckedAt: "2026-11-16T10:00:00.000Z"
        )
        let model = BackendHealthViewModel(client: StubBackendHealthClient(result: .success(snapshot)))

        await model.refresh()

        XCTAssertEqual(model.state, .connected(snapshot))
    }

    @MainActor
    func testViewModelReportsDisconnectedWhenBackendCannotBeReached() async {
        let model = BackendHealthViewModel(client: StubBackendHealthClient(result: .failure(.unavailable)))

        await model.refresh()

        XCTAssertEqual(model.state, .disconnected)
    }
}

private struct StubBackendHealthClient: BackendHealthClient {
    let result: Result<BackendHealthSnapshot, StubBackendHealthError>

    func fetchSnapshot() async throws -> BackendHealthSnapshot {
        try result.get()
    }
}

private enum StubBackendHealthError: Error {
    case unavailable
}
