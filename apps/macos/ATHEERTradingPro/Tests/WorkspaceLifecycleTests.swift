import XCTest
@testable import ATHEERTradingPro

final class WorkspaceLifecycleTests: XCTestCase {
    @MainActor
    func testDeletingActiveWorkspaceSelectsAndPersistsRemainingWorkspace() {
        let persistence = InMemoryWorkspaceLifecyclePersistence()
        let engine = WorkspaceEngine(persistence: persistence)
        let defaultWorkspaceID = engine.activeWorkspace.id

        let createdWorkspaceID = engine.createWorkspace(name: "Execution")
        XCTAssertNotNil(createdWorkspaceID)
        XCTAssertEqual(engine.snapshot.activeWorkspaceID, createdWorkspaceID)

        XCTAssertTrue(engine.deleteWorkspace(createdWorkspaceID!))

        XCTAssertEqual(engine.snapshot.workspaces.map(\.id), [defaultWorkspaceID])
        XCTAssertEqual(engine.snapshot.activeWorkspaceID, defaultWorkspaceID)
        XCTAssertEqual(engine.snapshot.profiles.first?.workspaceIDs, [defaultWorkspaceID])
        XCTAssertEqual(persistence.storedSnapshot, engine.snapshot)
        XCTAssertEqual(engine.recoveryState, .clean)
    }

    @MainActor
    func testDeletingLastWorkspaceIsRejectedWithoutMutation() {
        let persistence = InMemoryWorkspaceLifecyclePersistence()
        let engine = WorkspaceEngine(persistence: persistence)
        let before = engine.snapshot

        XCTAssertFalse(engine.deleteWorkspace(engine.activeWorkspace.id))

        XCTAssertEqual(engine.snapshot, before)
        XCTAssertEqual(persistence.storedSnapshot, before)
    }

    @MainActor
    func testDeletingSharedWorkspaceRepairsEveryProfileAndPreservesActiveSelections() {
        var snapshot = WorkspaceSnapshot.standard()
        let sharedWorkspace = snapshot.workspaces[0]
        let fallbackA = WorkspaceDocument.standard(name: "Profile A fallback")
        let fallbackB = WorkspaceDocument.standard(name: "Profile B fallback")

        snapshot.workspaces.append(contentsOf: [fallbackA, fallbackB])
        snapshot.profiles[0].workspaceIDs.append(fallbackA.id)
        snapshot.profiles[0].activeWorkspaceID = sharedWorkspace.id
        let profileB = WorkspaceProfile(
            id: UUID(),
            name: "Profile B",
            workspaceIDs: [sharedWorkspace.id, fallbackB.id],
            activeWorkspaceID: fallbackB.id
        )
        snapshot.profiles.append(profileB)
        snapshot.activeProfileID = snapshot.profiles[0].id
        snapshot.activeWorkspaceID = sharedWorkspace.id

        let persistence = InMemoryWorkspaceLifecyclePersistence(snapshot: snapshot)
        let engine = WorkspaceEngine(persistence: persistence)

        XCTAssertTrue(engine.deleteWorkspace(sharedWorkspace.id))

        XCTAssertFalse(engine.snapshot.workspaces.contains { $0.id == sharedWorkspace.id })
        XCTAssertEqual(engine.snapshot.activeWorkspaceID, fallbackA.id)
        XCTAssertEqual(engine.snapshot.profiles[0].workspaceIDs, [fallbackA.id])
        XCTAssertEqual(engine.snapshot.profiles[0].activeWorkspaceID, fallbackA.id)
        XCTAssertEqual(engine.snapshot.profiles[1].workspaceIDs, [fallbackB.id])
        XCTAssertEqual(engine.snapshot.profiles[1].activeWorkspaceID, fallbackB.id)
        XCTAssertEqual(persistence.storedSnapshot, engine.snapshot)
        XCTAssertEqual(engine.recoveryState, .clean)
    }

    @MainActor
    func testDeletingWorkspaceIsRejectedWhenAnyProfileWouldBecomeEmpty() {
        var snapshot = WorkspaceSnapshot.standard()
        let sharedWorkspace = snapshot.workspaces[0]
        let fallback = WorkspaceDocument.standard(name: "Default fallback")
        snapshot.workspaces.append(fallback)
        snapshot.profiles[0].workspaceIDs.append(fallback.id)

        let singleWorkspaceProfile = WorkspaceProfile(
            id: UUID(),
            name: "Single workspace profile",
            workspaceIDs: [sharedWorkspace.id],
            activeWorkspaceID: sharedWorkspace.id
        )
        snapshot.profiles.append(singleWorkspaceProfile)

        let persistence = InMemoryWorkspaceLifecyclePersistence(snapshot: snapshot)
        let engine = WorkspaceEngine(persistence: persistence)
        let before = engine.snapshot

        XCTAssertFalse(engine.deleteWorkspace(sharedWorkspace.id))

        XCTAssertEqual(engine.snapshot, before)
        XCTAssertEqual(persistence.storedSnapshot, before)
    }
}

private final class InMemoryWorkspaceLifecyclePersistence: WorkspacePersistence {
    private(set) var storedSnapshot: WorkspaceSnapshot?

    init(snapshot: WorkspaceSnapshot? = nil) {
        storedSnapshot = snapshot
    }

    func load() throws -> WorkspaceSnapshot? {
        storedSnapshot
    }

    func save(_ snapshot: WorkspaceSnapshot) throws {
        storedSnapshot = snapshot
    }
}
