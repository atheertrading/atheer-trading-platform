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

    func testWorkspacePanelInventoryAndDefaultVisibility() {
        XCTAssertEqual(
            WorkspacePanelID.allCases,
            [.marketWatch, .charts, .accountRisk, .platformHealth]
        )
        XCTAssertEqual(WorkspacePanelID.defaultVisible, Set(WorkspacePanelID.allCases))
    }

    @MainActor
    func testWorkspaceEnginePersistsVisibilityAndRestoresActiveWorkspace() {
        let persistence = InMemoryWorkspacePersistence()
        let engine = WorkspaceEngine(persistence: persistence)

        engine.setPanelVisibility(.marketWatch, isVisible: false)
        XCTAssertFalse(engine.visiblePanels.contains(.marketWatch))

        let secondWorkspaceID = engine.createWorkspace(name: "Execution")!
        XCTAssertEqual(engine.activeWorkspace.name, "Execution")

        let restored = WorkspaceEngine(persistence: persistence)
        XCTAssertEqual(restored.activeWorkspace.id, secondWorkspaceID)
        XCTAssertEqual(restored.activeWorkspace.name, "Execution")
        XCTAssertEqual(restored.visiblePanels, WorkspacePanelID.defaultVisible)
    }

    @MainActor
    func testWorkspaceEngineRecoversFromDuplicatePanelIdentity() {
        let persistence = InMemoryWorkspacePersistence()
        var invalid = WorkspaceSnapshot.standard()
        invalid.workspaces[0].panels.append(invalid.workspaces[0].panels[0])
        persistence.snapshot = invalid

        let engine = WorkspaceEngine(persistence: persistence)

        XCTAssertEqual(engine.recoveryState, .restoredDefaults(
            String(describing: WorkspacePersistenceError.invalidSnapshot(
                "A workspace cannot contain duplicate panel identities."
            ))
        ))
        XCTAssertEqual(engine.visiblePanels, WorkspacePanelID.defaultVisible)
        XCTAssertEqual(persistence.snapshot?.schemaVersion, WorkspaceSnapshot.currentSchemaVersion)
    }

    @MainActor
    func testWorkspaceEngineRejectsUnsupportedSchemaAndUsesDefaults() {
        let persistence = InMemoryWorkspacePersistence()
        var invalid = WorkspaceSnapshot.standard()
        invalid.schemaVersion = WorkspaceSnapshot.currentSchemaVersion + 1
        persistence.snapshot = invalid

        let engine = WorkspaceEngine(persistence: persistence)

        XCTAssertEqual(engine.visiblePanels, WorkspacePanelID.defaultVisible)
        if case .restoredDefaults = engine.recoveryState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected unsupported workspace schema to recover to defaults.")
        }
    }

    @MainActor
    func testCommandCenterCanBeInstantiatedWithInjectedHealthModel() {
        let model = BackendHealthViewModel(
            client: StubBackendHealthClient(result: .failure(StubBackendHealthError.unavailable))
        )
        let view = CommandCenterView(
            backendHealthModel: model,
            onOpenAPIConnection: {}
        )

        XCTAssertNotNil(view)
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

        XCTAssertEqual(snapshot.platformReady, false)
        XCTAssertEqual(snapshot.persistenceStatus, "not_configured")
        XCTAssertEqual(snapshot.brokerStatus, "not_configured")
        XCTAssertEqual(snapshot.tradingEnabled, false)
        XCTAssertEqual(snapshot.tradingStatus, "disabled")
        XCTAssertEqual(snapshot.readinessHTTPStatus, 503)
        XCTAssertEqual(snapshot.livenessTimestamp, "2026-11-16T10:00:00.000Z")
        XCTAssertEqual(snapshot.readinessTimestamp, "2026-11-16T10:00:01.000Z")
        XCTAssertNil(snapshot.readinessFailure)
    }

    func testHealthPayloadDecoderPreservesLivenessWhenReadinessIsUnavailable() throws {
        let livenessData = Data("""
        {"status":"ok","service":"atheer-api","version":"0.1.0","timestamp":"2026-11-16T10:00:00.000Z"}
        """.utf8)
        let liveness = try BackendHealthPayloadDecoder().decodeLiveness(data: livenessData, statusCode: 200)
        let snapshot = BackendHealthPayloadDecoder().snapshot(
            liveness: liveness,
            readinessFailure: .transport("Readiness request timed out.")
        )

        XCTAssertEqual(snapshot.version, "0.1.0")
        XCTAssertEqual(snapshot.livenessTimestamp, "2026-11-16T10:00:00.000Z")
        XCTAssertNil(snapshot.platformReady)
        XCTAssertEqual(snapshot.readinessFailure, .transport("Readiness request timed out."))
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
            livenessTimestamp: "2026-11-16T10:00:00.000Z",
            platformReady: false,
            persistenceStatus: "not_configured",
            brokerStatus: "not_configured",
            tradingEnabled: false,
            tradingStatus: "disabled",
            readinessHTTPStatus: 503,
            readinessTimestamp: "2026-11-16T10:00:01.000Z",
            readinessFailure: nil
        )
        let model = BackendHealthViewModel(client: StubBackendHealthClient(result: .success(snapshot)))

        await model.refresh()

        XCTAssertEqual(model.state, .connected(snapshot))
    }

    @MainActor
    func testViewModelReportsDisconnectedWhenLivenessCannotBeReached() async {
        let model = BackendHealthViewModel(client: StubBackendHealthClient(result: .failure(StubBackendHealthError.unavailable)))

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

private final class InMemoryWorkspacePersistence: WorkspacePersistence {
    var snapshot: WorkspaceSnapshot?

    func load() throws -> WorkspaceSnapshot? {
        snapshot
    }

    func save(_ snapshot: WorkspaceSnapshot) throws {
        self.snapshot = snapshot
    }
}
