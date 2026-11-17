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
            updatedAt: Date()
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
    case corruptData(String)
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
        do {
            return try JSONDecoder().decode(WorkspaceSnapshot.self, from: data)
        } catch {
            throw WorkspacePersistenceError.corruptData(String(describing: error))
        }
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

        var initialSnapshot: WorkspaceSnapshot
        var initialRecoveryState: RecoveryState = .clean

        do {
            if let stored = try persistence.load() {
                do {
                    try Self.validate(stored)
                    initialSnapshot = stored
                } catch {
                    initialSnapshot = .standard()
                    initialRecoveryState = .restoredDefaults(String(describing: error))
                    do {
                        try persistence.save(initialSnapshot)
                    } catch {
                        initialRecoveryState = .persistenceFailure(String(describing: error))
                    }
                }
            } else {
                initialSnapshot = .standard()
                do {
                    try persistence.save(initialSnapshot)
                } catch {
                    initialRecoveryState = .persistenceFailure(String(describing: error))
                }
            }
        } catch WorkspacePersistenceError.corruptData(let reason) {
            initialSnapshot = .standard()
            initialRecoveryState = .restoredDefaults("Stored workspace data was unreadable: \(reason)")
            do {
                try persistence.save(initialSnapshot)
            } catch {
                initialRecoveryState = .persistenceFailure(String(describing: error))
            }
        } catch {
            initialSnapshot = .standard()
            initialRecoveryState = .persistenceFailure(String(describing: error))
        }

        snapshot = initialSnapshot
        recoveryState = initialRecoveryState
    }

    func setPanelVisibility(_ panelID: WorkspacePanelID, isVisible: Bool) {
        updateActiveWorkspace { workspace in
            guard let index = workspace.panels.firstIndex(where: { $0.panelID == panelID }) else { return }
            workspace.panels[index].isVisible = isVisible
        }
    }

    /// Panels are returned in persisted visual order, including hidden panels.
    var orderedPanels: [WorkspacePanelConfiguration] {
        activeWorkspace.panels.sorted { $0.order < $1.order }
    }

    /// Moves an existing panel to a zero-based position and normalizes all order values.
    @discardableResult
    func movePanel(_ panelID: WorkspacePanelID, to targetIndex: Int) -> Bool {
        var panels = orderedPanels
        guard let sourceIndex = panels.firstIndex(where: { $0.panelID == panelID }),
              !panels.isEmpty else { return false }

        let destination = min(max(0, targetIndex), panels.count - 1)
        guard sourceIndex != destination else { return true }

        let movingPanel = panels.remove(at: sourceIndex)
        panels.insert(movingPanel, at: destination)
        updateActiveWorkspace { workspace in
            workspace.panels = panels.enumerated().map { index, configuration in
                var updated = configuration
                updated.order = index
                return updated
            }
        }
        return recoveryState == .clean
    }

    /// Adds a panel from the supported panel catalogue. Existing identities are left unchanged.
    @discardableResult
    func addPanel(_ panelID: WorkspacePanelID) -> Bool {
        guard !activeWorkspace.panels.contains(where: { $0.panelID == panelID }) else { return false }
        updateActiveWorkspace { workspace in
            let nextOrder = (workspace.panels.map(\.order).max() ?? -1) + 1
            workspace.panels.append(
                WorkspacePanelConfiguration(panelID: panelID, isVisible: true, order: nextOrder)
            )
        }
        return recoveryState == .clean
    }

    /// Removes a panel configuration from the active workspace without affecting other workspaces.
    @discardableResult
    func removePanel(_ panelID: WorkspacePanelID) -> Bool {
        guard activeWorkspace.panels.contains(where: { $0.panelID == panelID }) else { return false }
        updateActiveWorkspace { workspace in
            workspace.panels.removeAll { $0.panelID == panelID }
            workspace.panels.sort { $0.order < $1.order }
            for index in workspace.panels.indices {
                workspace.panels[index].order = index
            }
        }
        return recoveryState == .clean
    }

    /// Resizes the Command Center sidebar while enforcing the engine's supported width range.
    @discardableResult
    func resizeSidebar(to proposedWidth: Double) -> Bool {
        guard proposedWidth.isFinite else { return false }
        var layout = activeWorkspace.layout
        layout.sidebarWidth = min(max(proposedWidth, 220), 640)
        return updateActiveLayout(layout)
    }

    func selectWorkspace(_ workspaceID: UUID) {
        guard snapshot.workspaces.contains(where: { $0.id == workspaceID }) else { return }
        var updatedSnapshot = snapshot
        updatedSnapshot.activeWorkspaceID = workspaceID
        if let profileIndex = updatedSnapshot.profiles.firstIndex(where: { $0.id == updatedSnapshot.activeProfileID }) {
            updatedSnapshot.profiles[profileIndex].activeWorkspaceID = workspaceID
        }
        snapshot = updatedSnapshot
        persist()
    }

    @discardableResult
    func createProfile(name: String) -> UUID? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        let workspace = WorkspaceDocument.standard()
        let profile = WorkspaceProfile(
            id: UUID(),
            name: trimmedName,
            workspaceIDs: [workspace.id],
            activeWorkspaceID: workspace.id
        )
        var updatedSnapshot = snapshot
        updatedSnapshot.workspaces.append(workspace)
        updatedSnapshot.profiles.append(profile)
        updatedSnapshot.activeProfileID = profile.id
        updatedSnapshot.activeWorkspaceID = workspace.id
        snapshot = updatedSnapshot
        persist()
        return profile.id
    }

    func selectProfile(_ profileID: UUID) {
        guard let profile = snapshot.profiles.first(where: { $0.id == profileID }),
              profile.workspaceIDs.contains(profile.activeWorkspaceID) else { return }
        var updatedSnapshot = snapshot
        updatedSnapshot.activeProfileID = profile.id
        updatedSnapshot.activeWorkspaceID = profile.activeWorkspaceID
        snapshot = updatedSnapshot
        persist()
    }

    @discardableResult
    func updateActiveLayout(_ layout: WorkspaceLayoutConfiguration) -> Bool {
        guard let index = snapshot.workspaces.firstIndex(where: { $0.id == snapshot.activeWorkspaceID }) else {
            return false
        }
        var updatedSnapshot = snapshot
        updatedSnapshot.workspaces[index].layout = layout
        updatedSnapshot.workspaces[index].updatedAt = Date()
        do {
            try Self.validate(updatedSnapshot)
        } catch {
            return false
        }
        snapshot = updatedSnapshot
        persist()
        return recoveryState == .clean
    }

    @discardableResult
    func createWorkspace(name: String) -> UUID? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        let workspace = WorkspaceDocument.standard(name: trimmedName)
        var updatedSnapshot = snapshot
        updatedSnapshot.workspaces.append(workspace)
        if let profileIndex = updatedSnapshot.profiles.firstIndex(where: { $0.id == updatedSnapshot.activeProfileID }) {
            updatedSnapshot.profiles[profileIndex].workspaceIDs.append(workspace.id)
            updatedSnapshot.profiles[profileIndex].activeWorkspaceID = workspace.id
        }
        updatedSnapshot.activeWorkspaceID = workspace.id
        snapshot = updatedSnapshot
        persist()
        return workspace.id
    }

    func renameActiveWorkspace(to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        updateActiveWorkspace { $0.name = trimmedName }
    }

    /// Restores the active workspace's default panel catalogue without changing its name or layout.
    func restoreDefaultPanels() {
        updateActiveWorkspace { workspace in
            workspace.panels = WorkspacePanelID.allCases.enumerated().map { index, panelID in
                WorkspacePanelConfiguration(
                    panelID: panelID,
                    isVisible: true,
                    order: index
                )
            }
        }
    }

    func resetActiveWorkspace() {
        var replacement = WorkspaceDocument.standard(
            id: activeWorkspace.id,
            name: activeWorkspace.name
        )
        replacement.updatedAt = Date()
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
        var updatedSnapshot = snapshot
        update(&updatedSnapshot.workspaces[index])
        updatedSnapshot.workspaces[index].updatedAt = Date()
        snapshot = updatedSnapshot
        persist()
    }

    private func replaceActiveWorkspace(with workspace: WorkspaceDocument) {
        guard let index = snapshot.workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }
        var updatedSnapshot = snapshot
        updatedSnapshot.workspaces[index] = workspace
        snapshot = updatedSnapshot
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
        let workspaceIDs = snapshot.workspaces.map(\.id)
        guard Set(workspaceIDs).count == workspaceIDs.count else {
            throw WorkspacePersistenceError.invalidSnapshot("Workspace identities must be unique.")
        }
        let profileIDs = snapshot.profiles.map(\.id)
        guard Set(profileIDs).count == profileIDs.count else {
            throw WorkspacePersistenceError.invalidSnapshot("Profile identities must be unique.")
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
        guard !activeProfile.workspaceIDs.isEmpty,
              activeProfile.workspaceIDs.allSatisfy({ workspaceIDs.contains($0) }),
              activeProfile.workspaceIDs.contains(activeProfile.activeWorkspaceID),
              snapshot.workspaces.contains(where: { $0.id == activeProfile.activeWorkspaceID }) else {
            throw WorkspacePersistenceError.invalidSnapshot("The active profile contains invalid workspace references.")
        }
        guard activeProfile.activeWorkspaceID == snapshot.activeWorkspaceID else {
            throw WorkspacePersistenceError.invalidSnapshot("The active profile and snapshot must reference the same active workspace.")
        }
        for profile in snapshot.profiles {
            let profileWorkspaceIDs = profile.workspaceIDs
            guard !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !profileWorkspaceIDs.isEmpty,
                  Set(profileWorkspaceIDs).count == profileWorkspaceIDs.count,
                  profileWorkspaceIDs.allSatisfy({ workspaceIDs.contains($0) }),
                  profileWorkspaceIDs.contains(profile.activeWorkspaceID) else {
                throw WorkspacePersistenceError.invalidSnapshot("A workspace profile contains invalid identity or workspace references.")
            }
        }

        for workspace in snapshot.workspaces {
            guard !workspace.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw WorkspacePersistenceError.invalidSnapshot("Workspace names cannot be empty.")
            }
            let panelIDs = workspace.panels.map(\.panelID)
            let panelOrders = workspace.panels.map(\.order)
            guard Set(panelIDs).count == panelIDs.count else {
                throw WorkspacePersistenceError.invalidSnapshot("A workspace cannot contain duplicate panel identities.")
            }
            guard panelOrders.allSatisfy({ $0 >= 0 }),
                  Set(panelOrders).count == panelOrders.count else {
                throw WorkspacePersistenceError.invalidSnapshot("Panel order values must be unique and non-negative.")
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
