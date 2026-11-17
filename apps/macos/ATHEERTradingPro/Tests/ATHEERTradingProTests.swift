import XCTest
@testable import ATHEERTradingPro

final class ATHEERTradingProTests: XCTestCase {
    @MainActor
    func testApplicationShellCanBeInstantiated() {
        let view = ContentView()
        XCTAssertNotNil(view)
    }

    func testNavigationExposesOnlyImplementedDestinations() {
        XCTAssertEqual(AppSection.allCases, [.workspace, .apiConnection, .settings])
        XCTAssertEqual(AppSection.settings.title, "Settings")
    }

    @MainActor
    func testWorkspaceEngineRestoresDefaultPanelsWithoutChangingWorkspaceLayout() {
        let persistence = InMemoryWorkspacePersistence()
        let engine = WorkspaceEngine(persistence: persistence)
        let originalName = engine.activeWorkspace.name
        let customLayout = WorkspaceLayoutConfiguration(
            style: .stacked,
            sidebarWidth: 420,
            minimumPrimaryWidth: 560
        )
        XCTAssertTrue(engine.updateActiveLayout(customLayout))
        XCTAssertTrue(engine.removePanel(.platformHealth))
        engine.setPanelVisibility(.marketWatch, isVisible: false)

        engine.restoreDefaultPanels()

        XCTAssertEqual(engine.activeWorkspace.name, originalName)
        XCTAssertEqual(engine.activeWorkspace.layout, customLayout)
        XCTAssertEqual(engine.visiblePanels, WorkspacePanelID.defaultVisible)
        XCTAssertEqual(engine.orderedPanels.map(\.panelID), WorkspacePanelID.allCases)
        XCTAssertEqual(engine.orderedPanels.map(\.order), Array(0..<WorkspacePanelID.allCases.count))
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
        engine.setPanelVisibility(.marketWatch, isVisible: false)

        let restored = WorkspaceEngine(persistence: persistence)
        XCTAssertEqual(restored.activeWorkspace.id, secondWorkspaceID)
        XCTAssertEqual(restored.activeWorkspace.name, "Execution")
        XCTAssertFalse(restored.visiblePanels.contains(.marketWatch))
    }

    @MainActor
    func testWorkspaceEnginePersistsProfilesAndLayoutConfiguration() {
        let persistence = InMemoryWorkspacePersistence()
        let engine = WorkspaceEngine(persistence: persistence)
        let profileID = engine.createProfile(name: "Research")
        XCTAssertNotNil(profileID)

        let layout = WorkspaceLayoutConfiguration(
            style: .stacked,
            sidebarWidth: 360,
            minimumPrimaryWidth: 540
        )
        XCTAssertTrue(engine.updateActiveLayout(layout))

        let restored = WorkspaceEngine(persistence: persistence)
        XCTAssertEqual(restored.snapshot.activeProfileID, restored.snapshot.profiles.last?.id)
        XCTAssertEqual(restored.activeWorkspace.layout, layout)
    }

    @MainActor
    func testWorkspaceEngineRejectsOutOfRangeLayoutWithoutMutatingState() {
        let persistence = InMemoryWorkspacePersistence()
        let engine = WorkspaceEngine(persistence: persistence)
        let originalLayout = engine.activeWorkspace.layout
        let invalidLayout = WorkspaceLayoutConfiguration(
            style: .adaptiveColumns,
            sidebarWidth: 900,
            minimumPrimaryWidth: 500
        )

        XCTAssertFalse(engine.updateActiveLayout(invalidLayout))
        XCTAssertEqual(engine.activeWorkspace.layout, originalLayout)
    }

    @MainActor
    func testWorkspaceEngineRecoversFromDuplicatePanelIdentity() {
        let persistence = InMemoryWorkspacePersistence()
        var invalid = WorkspaceSnapshot.standard()
        invalid.workspaces[0].panels.append(invalid.workspaces[0].panels[0])
        persistence.snapshot = invalid

        let engine = WorkspaceEngine(persistence: persistence)

        if case .restoredDefaults(let reason) = engine.recoveryState {
            XCTAssertTrue(reason.contains("duplicate panel identities"))
        } else {
            XCTFail("Expected duplicate panel identities to trigger safe recovery.")
        }
        XCTAssertEqual(engine.visiblePanels, WorkspacePanelID.defaultVisible)
        XCTAssertEqual(persistence.snapshot?.schemaVersion, WorkspaceSnapshot.currentSchemaVersion)
    }

    @MainActor
    func testWorkspaceEngineRecoversFromInvalidPanelOrdering() {
        let persistence = InMemoryWorkspacePersistence()
        var invalid = WorkspaceSnapshot.standard()
        invalid.workspaces[0].panels[0].order = -1
        persistence.snapshot = invalid

        let engine = WorkspaceEngine(persistence: persistence)

        XCTAssertEqual(engine.visiblePanels, WorkspacePanelID.defaultVisible)
        if case .restoredDefaults(let reason) = engine.recoveryState {
            XCTAssertTrue(reason.contains("Panel order values"))
        } else {
            XCTFail("Invalid panel ordering should recover to the default workspace.")
        }
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
    func testWorkspaceEngineRecoversWhenStoredDataCannotBeDecoded() {
        let persistence = InMemoryWorkspacePersistence()
        persistence.loadError = WorkspacePersistenceError.corruptData("invalid JSON")

        let engine = WorkspaceEngine(persistence: persistence)

        XCTAssertEqual(engine.visiblePanels, WorkspacePanelID.defaultVisible)
        if case .restoredDefaults(let reason) = engine.recoveryState {
            XCTAssertTrue(reason.contains("invalid JSON"))
        } else {
            XCTFail("Unreadable persisted workspace data should recover to defaults.")
        }
        XCTAssertNotNil(persistence.snapshot)
    }

    @MainActor
    func testWorkspaceEngineMovesPanelsAndPersistsVisualOrder() {
        let persistence = InMemoryWorkspacePersistence()
        let engine = WorkspaceEngine(persistence: persistence)

        XCTAssertTrue(engine.movePanel(.marketWatch, to: 0))
        XCTAssertEqual(engine.orderedPanels.map(\.panelID).first, .marketWatch)
        XCTAssertEqual(engine.orderedPanels.map(\.order), Array(0..<engine.orderedPanels.count))

        let restored = WorkspaceEngine(persistence: persistence)
        XCTAssertEqual(restored.orderedPanels.map(\.panelID), engine.orderedPanels.map(\.panelID))
    }

    @MainActor
    func testWorkspaceEngineAddsAndRemovesPanelConfigurationsIdempotently() {
        let persistence = InMemoryWorkspacePersistence()
        let engine = WorkspaceEngine(persistence: persistence)

        XCTAssertTrue(engine.removePanel(.platformHealth))
        XCTAssertFalse(engine.activeWorkspace.panels.contains { $0.panelID == .platformHealth })
        XCTAssertFalse(engine.removePanel(.platformHealth))

        XCTAssertTrue(engine.addPanel(.platformHealth))
        XCTAssertTrue(engine.visiblePanels.contains(.platformHealth))
        XCTAssertFalse(engine.addPanel(.platformHealth))

        let restored = WorkspaceEngine(persistence: persistence)
        XCTAssertTrue(restored.visiblePanels.contains(.platformHealth))
    }

    @MainActor
    func testWorkspaceEngineResizesSidebarWithinSupportedBoundsAndPersistsWidth() {
        let persistence = InMemoryWorkspacePersistence()
        let engine = WorkspaceEngine(persistence: persistence)

        XCTAssertTrue(engine.resizeSidebar(to: 480))
        XCTAssertEqual(engine.activeWorkspace.layout.sidebarWidth, 480)
        XCTAssertTrue(engine.resizeSidebar(to: 900))
        XCTAssertEqual(engine.activeWorkspace.layout.sidebarWidth, 640)

        let restored = WorkspaceEngine(persistence: persistence)
        XCTAssertEqual(restored.activeWorkspace.layout.sidebarWidth, 640)
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

    func testBrokerCredentialStorePersistsAndRetrievesCredentials() throws {
        let keychain = InMemoryKeychainAccess()
        let store = KeychainBrokerCredentialStore(keychain: keychain)
        let credential = BrokerCredential(apiKey: "api-key-value", identifier: "demo-login", password: "secret")
        try store.save(credential, brokerID: "capital.com", environment: .demo)
        XCTAssertEqual(try store.load(brokerID: "capital.com", environment: .demo), credential)
        XCTAssertEqual(keychain.itemCount, 1)
    }

    func testBrokerCredentialStoreIsolatesBrokerAndEnvironment() throws {
        let keychain = InMemoryKeychainAccess()
        let store = KeychainBrokerCredentialStore(keychain: keychain)
        let demo = BrokerCredential(apiKey: "demo-key", identifier: "demo-user", password: "demo-password")
        let live = BrokerCredential(apiKey: "live-key", identifier: "live-user", password: "live-password")
        try store.save(demo, brokerID: "capital.com", environment: .demo)
        try store.save(live, brokerID: "capital.com", environment: .live)
        XCTAssertEqual(try store.load(brokerID: "capital.com", environment: .demo), demo)
        XCTAssertEqual(try store.load(brokerID: "capital.com", environment: .live), live)
        XCTAssertEqual(keychain.itemCount, 2)
    }

    func testBrokerCredentialStoreDeletesOnlySelectedEnvironment() throws {
        let keychain = InMemoryKeychainAccess()
        let store = KeychainBrokerCredentialStore(keychain: keychain)
        let demo = BrokerCredential(apiKey: "demo-key", identifier: "demo-user", password: "demo-password")
        let live = BrokerCredential(apiKey: "live-key", identifier: "live-user", password: "live-password")
        try store.save(demo, brokerID: "capital.com", environment: .demo)
        try store.save(live, brokerID: "capital.com", environment: .live)
        try store.delete(brokerID: "capital.com", environment: .demo)
        XCTAssertNil(try store.load(brokerID: "capital.com", environment: .demo))
        XCTAssertEqual(try store.load(brokerID: "capital.com", environment: .live), live)
    }

    func testBrokerCredentialStoreSeparatesAccountsWithinTheSameEnvironment() throws {
        let keychain = InMemoryKeychainAccess()
        let store = KeychainBrokerCredentialStore(keychain: keychain)
        let first = BrokerCredential(apiKey: "first-key", identifier: "first-login@example.invalid", password: "first-password")
        let second = BrokerCredential(apiKey: "second-key", identifier: "second-login@example.invalid", password: "second-password")

        try store.save(first, brokerID: "capital.com", environment: .demo)
        try store.save(second, brokerID: "capital.com", environment: .demo)

        XCTAssertEqual(
            try store.load(brokerID: "capital.com", environment: .demo, accountIdentity: "first-login@example.invalid"),
            first
        )
        XCTAssertEqual(
            try store.load(brokerID: "capital.com", environment: .demo, accountIdentity: "second-login@example.invalid"),
            second
        )
        XCTAssertEqual(try store.load(brokerID: "capital.com", environment: .demo), second)

        try store.delete(brokerID: "capital.com", environment: .demo, accountIdentity: "first-login@example.invalid")
        XCTAssertNil(try store.load(brokerID: "capital.com", environment: .demo, accountIdentity: "first-login@example.invalid"))
        XCTAssertEqual(try store.load(brokerID: "capital.com", environment: .demo), second)
    }

    func testBrokerCredentialStoreRejectsIncompleteCredentials() {
        let store = KeychainBrokerCredentialStore(keychain: InMemoryKeychainAccess())
        let invalid = BrokerCredential(apiKey: "", identifier: "demo-user", password: "secret")
        XCTAssertThrowsError(try store.save(invalid, brokerID: "capital.com", environment: .demo))
    }

    @MainActor
    func testBrokerManagementViewModelConstructsDefaultAuthenticationDependency() {
        let store = KeychainBrokerCredentialStore(keychain: InMemoryKeychainAccess())
        let model = BrokerManagementViewModel(credentialStore: store)

        XCTAssertEqual(model.state, .notConfigured)
        XCTAssertFalse(model.hasSavedCredentials)
        XCTAssertNil(model.account)
    }

    @MainActor
    func testBrokerManagementViewModelDoesNotReportConnectedBeforeAuthentication() async throws {
        let store = KeychainBrokerCredentialStore(keychain: InMemoryKeychainAccess())
        let model = BrokerManagementViewModel(
            credentialStore: store,
            authentication: StubBrokerAuthenticationService(result: .failure(BrokerAuthenticationError.invalidCredentials))
        )
        XCTAssertEqual(model.state, .notConfigured)
        try await model.saveCredentials(BrokerCredential(apiKey: "key", identifier: "login", password: "password"))
        XCTAssertEqual(model.state, .credentialsSaved)
        XCTAssertNotEqual(model.state, .connected)
    }

    @MainActor
    func testBrokerManagementViewModelReportsAuthenticationFailure() async throws {
        let store = KeychainBrokerCredentialStore(keychain: InMemoryKeychainAccess())
        try store.save(
            BrokerCredential(apiKey: "key", identifier: "login", password: "password"),
            brokerID: "capital.com",
            environment: .demo
        )
        let model = BrokerManagementViewModel(
            credentialStore: store,
            authentication: StubBrokerAuthenticationService(result: .failure(BrokerAuthenticationError.invalidCredentials))
        )
        await model.testConnection()
        XCTAssertEqual(model.state, .authenticationFailed(BrokerAuthenticationError.invalidCredentials.localizedDescription))
        XCTAssertNil(model.account)
    }

    @MainActor
    func testBrokerManagementViewModelPublishesAccountOnlyAfterAuthentication() async throws {
        let store = KeychainBrokerCredentialStore(keychain: InMemoryKeychainAccess())
        try store.save(
            BrokerCredential(apiKey: "key", identifier: "login", password: "password"),
            brokerID: "capital.com",
            environment: .demo
        )
        let account = BrokerAccountSnapshot(accountIdentifier: "DEMO-ACCOUNT-123", currencyCode: "USD", authenticatedAt: Date())
        let model = BrokerManagementViewModel(
            credentialStore: store,
            authentication: StubBrokerAuthenticationService(result: .success(account))
        )
        await model.testConnection()
        XCTAssertEqual(model.state, .connected)
        XCTAssertEqual(model.account, account)
        XCTAssertEqual(model.lastSuccessfulConnection, account.authenticatedAt)
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
    var loadError: Error?

    func load() throws -> WorkspaceSnapshot? {
        if let loadError {
            throw loadError
        }
        return snapshot
    }

    func save(_ snapshot: WorkspaceSnapshot) throws {
        self.snapshot = snapshot
    }
}


private struct StubBrokerAuthenticationService: BrokerAuthenticationService {
    let result: Result<BrokerAccountSnapshot, Error>

    @MainActor
    func authenticate(_ credential: BrokerCredential, environment: BrokerEnvironment) async throws -> BrokerAccountSnapshot {
        try result.get()
    }

    @MainActor
    func validateSession() async throws -> BrokerAccountSnapshot { try result.get() }

    @MainActor
    func disconnect() async {}
}

private final class InMemoryKeychainAccess: KeychainAccessing {
    private var values: [String: Data] = [:]
    var itemCount: Int { values.count }

    func read(service: String, account: String) throws -> Data? {
        values["\(service):\(account)"]
    }

    func write(_ data: Data, service: String, account: String) throws {
        values["\(service):\(account)"] = data
    }

    func delete(service: String, account: String) throws {
        values.removeValue(forKey: "\(service):\(account)")
    }
}
