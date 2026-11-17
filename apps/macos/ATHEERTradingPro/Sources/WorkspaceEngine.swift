import Foundation
import Combine

enum WorkspaceLayoutStyle: String, Codable, CaseIterable {
    case adaptiveColumns
    case stacked
}

struct WorkspacePanelConfiguration: Codable, Equatable, Identifiable {
    let panelID: WorkspacePanelID
    var isVisible: Bool
    var order: Int

    var id: WorkspacePanelID { panelID }
}

struct WorkspaceLayoutConfiguration: Codable, Equatable {
    var style: WorkspaceLayoutStyle
    var sidebarWidth: Double
    var minimumPrimaryWidth: Double

    static let standard = WorkspaceLayoutConfiguration(
        style: .adaptiveColumns,
        sidebarWidth: 304,
        minimumPrimaryWidth: 500
    )
}

struct WorkspaceDocument: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var panels: [WorkspacePanelConfiguration]
    var layout: WorkspaceLayoutConfiguration
    var updatedAt: Date

    static func standard(id: UUID = UUID(), name: String = "Default") -> WorkspaceDocument {
        WorkspaceDocument(
            id: id,
            name: name,
            panels: WorkspacePanelID.allCases.enumerated().map {
                WorkspacePanelConfiguration(
                    panelID: $0.element,
                    isVisible: true,
                    order: $0.offset
                )
            },
            layout: .standard,
            updatedAt: Date(timeIntervalSince1970: 0)
        )
    }
}

struct WorkspaceProfile: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var workspaceIDs: [UUID]
    var activeWorkspaceID: UUID
}

struct WorkspaceSnapshot: Codable, Equatable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var profiles: [WorkspaceProfile]
    var workspaces: [WorkspaceDocument]
    var activeProfileID: UUID
    var activeWorkspaceID: UUID

    static func standard() -> WorkspaceSnapshot {
        let workspace = WorkspaceDocument.standard()
        let profile = WorkspaceProfile(
            id: UUID(),
            name: "Default Profile",
            workspaceIDs: [workspace.id],
            activeWorkspaceID: workspace.id
        )
        return WorkspaceSnapshot(
            schemaVersion: currentSchemaVersion,
            profiles: [profile],
            workspaces: [workspace],
            activeProfileID: profile.id,
            activeWorkspaceID: workspace.id
        )
    }
}

enum WorkspacePersistenceError: Error, Equatable {
    case unsupportedSchema(Int)
    case invalidSnapshot(String)
}

protocol WorkspacePersistence {
    func load() throws -> WorkspaceSnapshot?
    func save(_ snapshot: WorkspaceSnapshot) throws
}

struct UserDefaultsWorkspacePersistence: WorkspacePersistence {
    private let defaults: UserDefaults
    private let key: String

    init(
        defaults: UserDefaults = .standard,
        key: String = "com.atheertrading.workspace.snapshot.v1"
    ) {
        self.defaults = defaults
        self.key = key
    }

    func load() throws -> WorkspaceSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(WorkspaceSnapshot.self, from: data)
    }

    func save(_ snapshot: WorkspaceSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: key)
    }
}

@MainActor
final class WorkspaceEngine: ObservableObject {
    enum RecoveryState: Equatable {
        case clean
        case restoredDefaults(String)
        case persistenceFailure(String)
    }

    @Published private(set) var snapshot: WorkspaceSnapshot
    @Published private(set) var recoveryState: RecoveryState = .clean

    private let persistence: WorkspacePersistence

    var activeWorkspace: WorkspaceDocument {
        snapshot.workspaces.first(where: { $0.id == snapshot.activeWorkspaceID })
            ?? WorkspaceDocument.standard()
    }

    var visiblePanels: Set<WorkspacePanelID> {
        Set(activeWorkspace.panels.filter(\.isVisible).map(\.panelID))
    }

    init(persistence: WorkspacePersistence = UserDefaultsWorkspacePersistence()) {
        self.persistence = persistence

        do {
            if let stored = try persistence.load() {
                do {
                    try Self.validate(stored)
                    snapshot = stored
                } catch {
                    snapshot = .standard()
                    recoveryState = .restoredDefaults(String(describing: error))
                    try? persistence.save(snapshot)
                }
            } else {
                snapshot = .standard()
                try persistence.save(snapshot)
            }
        } catch {
            snapshot = .standard()
            recoveryState = .persistenceFailure(String(describing: error))
        }
    }

    func setPanelVisibility(_ panelID: WorkspacePanelID, isVisible: Bool) {
        updateActiveWorkspace { workspace in
            guard let index = workspace.panels.firstIndex(where: { $0.panelID == panelID }) else { return }
            workspace.panels[index].isVisible = isVisible
        }
    }

    func selectWorkspace(_ workspaceID: UUID) {
        guard snapshot.workspaces.contains(where: { $0.id == workspaceID }) else { return }
        snapshot.activeWorkspaceID = workspaceID
        if let profileIndex = snapshot.profiles.firstIndex(where: { $0.id == snapshot.activeProfileID }) {
            snapshot.profiles[profileIndex].activeWorkspaceID = workspaceID
        }
        persist()
    }

    @discardableResult
    func createWorkspace(name: String) -> UUID? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        let workspace = WorkspaceDocument.standard(name: trimmedName)
        snapshot.workspaces.append(workspace)
        if let profileIndex = snapshot.profiles.firstIndex(where: { $0.id == snapshot.activeProfileID }) {
            snapshot.profiles[profileIndex].workspaceIDs.append(workspace.id)
            snapshot.profiles[profileIndex].activeWorkspaceID = workspace.id
        }
        snapshot.activeWorkspaceID = workspace.id
        persist()
        return workspace.id
    }

    func renameActiveWorkspace(to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        updateActiveWorkspace { $0.name = trimmedName }
    }

    func resetActiveWorkspace() {
        let replacement = WorkspaceDocument.standard(
            id: activeWorkspace.id,
            name: activeWorkspace.name
        )
        replaceActiveWorkspace(with: replacement)
    }

    func save() {
        persist()
    }

    func restoreDefaults() {
        snapshot = .standard()
        persist()
    }

    private func updateActiveWorkspace(_ update: (inout WorkspaceDocument) -> Void) {
        guard let index = snapshot.workspaces.firstIndex(where: { $0.id == snapshot.activeWorkspaceID }) else { return }
        update(&snapshot.workspaces[index])
        snapshot.workspaces[index].updatedAt = Date()
        persist()
    }

    private func replaceActiveWorkspace(with workspace: WorkspaceDocument) {
        guard let index = snapshot.workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }
        snapshot.workspaces[index] = workspace
        persist()
    }

    private func persist() {
        do {
            try Self.validate(snapshot)
            try persistence.save(snapshot)
            recoveryState = .clean
        } catch {
            recoveryState = .persistenceFailure(String(describing: error))
        }
    }

    private static func validate(_ snapshot: WorkspaceSnapshot) throws {
        guard snapshot.schemaVersion == WorkspaceSnapshot.currentSchemaVersion else {
            throw WorkspacePersistenceError.unsupportedSchema(snapshot.schemaVersion)
        }
        guard !snapshot.profiles.isEmpty, !snapshot.workspaces.isEmpty else {
            throw WorkspacePersistenceError.invalidSnapshot("A workspace snapshot must contain a profile and workspace.")
        }
        guard snapshot.workspaces.contains(where: { $0.id == snapshot.activeWorkspaceID }) else {
            throw WorkspacePersistenceError.invalidSnapshot("The active workspace reference is missing.")
        }
        guard let activeProfile = snapshot.profiles.first(where: { $0.id == snapshot.activeProfileID }) else {
            throw WorkspacePersistenceError.invalidSnapshot("The active profile reference is missing.")
        }
        guard activeProfile.workspaceIDs.contains(snapshot.activeWorkspaceID) else {
            throw WorkspacePersistenceError.invalidSnapshot("The active workspace is not part of the active profile.")
        }

        for workspace in snapshot.workspaces {
            guard !workspace.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw WorkspacePersistenceError.invalidSnapshot("Workspace names cannot be empty.")
            }
            let panelIDs = workspace.panels.map(\.panelID)
            guard Set(panelIDs).count == panelIDs.count else {
                throw WorkspacePersistenceError.invalidSnapshot("A workspace cannot contain duplicate panel identities.")
            }
            guard workspace.layout.sidebarWidth >= 220,
                  workspace.layout.sidebarWidth <= 640,
                  workspace.layout.minimumPrimaryWidth >= 320,
                  workspace.layout.minimumPrimaryWidth <= 1200 else {
                throw WorkspacePersistenceError.invalidSnapshot("Workspace layout constraints are outside supported bounds.")
            }
        }
    }
}
