import XCTest
@testable import ATHEERTradingPro

final class WorkspaceContentTransferTests: XCTestCase {
    @MainActor
    func testCopyPanelConfigurationDuplicatesIntoDestinationWithoutChangingSource() {
        var snapshot = WorkspaceSnapshot.standard()
        let sourceWorkspace = snapshot.workspaces[0]
        let destinationID = UUID()
        let destination = WorkspaceDocument(
            id: destinationID,
            name: "Execution",
            panels: [
                WorkspacePanelConfiguration(panelID: .marketWatch, isVisible: true, order: 0)
            ],
            layout: .standard,
            updatedAt: Date()
        )
        snapshot.workspaces.append(destination)
        snapshot.profiles[0].workspaceIDs.append(destinationID)

        let persistence = InMemoryWorkspaceTransferPersistence(snapshot: snapshot)
        let engine = WorkspaceEngine(persistence: persistence)
        let sourceBefore = engine.snapshot.workspaces.first { $0.id == sourceWorkspace.id }!

        XCTAssertTrue(
            engine.copyPanelConfiguration(
                .charts,
                from: sourceWorkspace.id,
                to: destinationID,
                at: 0
            )
        )

        let sourceAfter = engine.snapshot.workspaces.first { $0.id == sourceWorkspace.id }
        let destinationAfter = engine.snapshot.workspaces.first { $0.id == destinationID }
        XCTAssertEqual(sourceAfter, sourceBefore)
        XCTAssertEqual(destinationAfter?.panels.map(\.panelID), [.charts, .marketWatch])
        XCTAssertEqual(destinationAfter?.panels.map(\.order), [0, 1])
        XCTAssertEqual(persistence.snapshot, engine.snapshot)
        XCTAssertEqual(engine.recoveryState, .clean)
    }

    @MainActor
    func testCopyPanelConfigurationRejectsSameWorkspaceDuplicateAndForeignProfile() {
        var snapshot = WorkspaceSnapshot.standard()
        let foreignWorkspace = WorkspaceDocument.standard(name: "Foreign")
        snapshot.workspaces.append(foreignWorkspace)
        snapshot.profiles.append(
            WorkspaceProfile(
                id: UUID(),
                name: "Other Profile",
                workspaceIDs: [foreignWorkspace.id],
                activeWorkspaceID: foreignWorkspace.id
            )
        )

        let persistence = InMemoryWorkspaceTransferPersistence(snapshot: snapshot)
        let engine = WorkspaceEngine(persistence: persistence)
        let before = engine.snapshot

        XCTAssertFalse(
            engine.copyPanelConfiguration(
                .charts,
                from: engine.activeWorkspace.id,
                to: engine.activeWorkspace.id
            )
        )
        XCTAssertFalse(
            engine.copyPanelConfiguration(
                .charts,
                from: engine.activeWorkspace.id,
                to: foreignWorkspace.id
            )
        )
        XCTAssertEqual(engine.snapshot, before)
        XCTAssertEqual(persistence.snapshot, before)
    }

    @MainActor
    func testImportWorkspaceLayoutCreatesNewWorkspaceInActiveProfile() throws {
        let persistence = InMemoryWorkspaceTransferPersistence()
        let engine = WorkspaceEngine(persistence: persistence)
        let source = WorkspaceDocument.standard(name: "Imported Research")
        let transfer = ATHEERWorkspaceLayoutTransfer(workspace: source)

        let importedID = engine.importWorkspaceLayout(transfer)

        XCTAssertNotNil(importedID)
        XCTAssertNotEqual(importedID, source.id)
        XCTAssertEqual(engine.activeWorkspace.id, importedID)
        XCTAssertEqual(engine.activeWorkspace.name, source.name)
        XCTAssertEqual(engine.activeWorkspace.panels, source.panels)
        XCTAssertEqual(engine.snapshot.profiles.first?.workspaceIDs.count, 2)
        XCTAssertEqual(persistence.snapshot, engine.snapshot)
        XCTAssertEqual(engine.recoveryState, .clean)
    }

    @MainActor
    func testImportInvalidWorkspaceLayoutDoesNotMutateSnapshotOrPersistence() {
        let persistence = InMemoryWorkspaceTransferPersistence()
        let engine = WorkspaceEngine(persistence: persistence)
        let before = engine.snapshot
        let invalidTransfer = ATHEERWorkspaceLayoutTransfer(
            schemaVersion: 99,
            workspaceName: "Invalid",
            panels: [],
            layout: .standard
        )

        XCTAssertNil(engine.importWorkspaceLayout(invalidTransfer))
        XCTAssertEqual(engine.snapshot, before)
        XCTAssertEqual(persistence.snapshot, before)
    }
}

private final class InMemoryWorkspaceTransferPersistence: WorkspacePersistence {
    private(set) var snapshot: WorkspaceSnapshot?
    var shouldFailSave = false

    init(snapshot: WorkspaceSnapshot? = nil) {
        self.snapshot = snapshot
    }

    func setInitialSnapshot(_ snapshot: WorkspaceSnapshot) {
        self.snapshot = snapshot
    }

    func load() throws -> WorkspaceSnapshot? {
        snapshot
    }

    func save(_ snapshot: WorkspaceSnapshot) throws {
        guard !shouldFailSave else {
            throw WorkspacePersistenceError.corruptData("Simulated persistence failure")
        }
        self.snapshot = snapshot
    }
}
