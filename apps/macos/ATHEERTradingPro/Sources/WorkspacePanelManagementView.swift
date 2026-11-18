import SwiftUI

/// Workspace-scoped panel lifecycle and layout controls.
struct WorkspacePanelManagementView: View {
    @ObservedObject var engine: WorkspaceEngine
    @State private var workspaceAlert: WorkspaceManagementAlert?

    private var canDeleteActiveWorkspace: Bool {
        let activeWorkspaceID = engine.activeWorkspace.id
        guard engine.snapshot.workspaces.count > 1 else { return false }
        let referencingProfiles = engine.snapshot.profiles.filter {
            $0.workspaceIDs.contains(activeWorkspaceID)
        }
        return !referencingProfiles.isEmpty &&
            referencingProfiles.allSatisfy { $0.workspaceIDs.count > 1 }
    }

    private var primaryPanels: [WorkspacePanelConfiguration] {
        engine.orderedPanels.filter { $0.panelID.isPrimaryRegion }
    }

    private var secondaryPanels: [WorkspacePanelConfiguration] {
        engine.orderedPanels.filter { !$0.panelID.isPrimaryRegion }
    }

    private var availablePanels: [WorkspacePanelID] {
        WorkspacePanelID.allCases.filter { panelID in
            !engine.activeWorkspace.panels.contains { $0.panelID == panelID }
        }
    }

    /// Defer mutations of List-backed data until AppKit has left its NSTableView delegate callback.
    private func schedulePanelMutation(_ mutation: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            await Task.yield()
            mutation()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Panel Management")
                    .font(.system(size: 20, weight: .semibold))
                Text("Configure the active workspace. Changes are saved automatically.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)

            List {
                Section("Primary workspace") {
                    ForEach(primaryPanels) { configuration in
                        panelRow(configuration, in: primaryPanels)
                    }
                }

                Section("Side workspace") {
                    ForEach(secondaryPanels) { configuration in
                        panelRow(configuration, in: secondaryPanels)
                    }
                }

                Section("Available panels") {
                    if availablePanels.isEmpty {
                        Text("All supported panels are already in this workspace.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(availablePanels) { panelID in
                            HStack {
                                Label(panelID.title, systemImage: "rectangle")
                                Spacer()
                                Button {
                                    schedulePanelMutation {
                                        _ = engine.addPanel(panelID)
                                    }
                                } label: {
                                    Label("Add", systemImage: "plus")
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .listStyle(.inset)

            Divider()

            workspaceLifecycleControls

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Side region width")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("\(Int(engine.activeWorkspace.layout.sidebarWidth)) pt")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Slider(
                    value: Binding(
                        get: { engine.activeWorkspace.layout.sidebarWidth },
                        set: { _ = engine.resizeSidebar(to: $0) }
                    ),
                    in: 220...640,
                    step: 8
                )
                .accessibilityLabel("Side region width")
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .frame(minWidth: 540, minHeight: 600)
        .background(ATHEERDesignTokens.ColorRole.canvas)
        .alert(item: $workspaceAlert) { alert in
            switch alert {
            case .confirmDelete:
                return Alert(
                    title: Text("Delete workspace?"),
                    message: Text(
                        "Delete \(engine.activeWorkspace.name) from every profile that references it? Each profile will switch to its first remaining workspace. This removes only saved workspace configuration; broker and market-data services are not stopped."
                    ),
                    primaryButton: .destructive(Text("Delete")) {
                        let workspaceID = engine.activeWorkspace.id
                        if !engine.deleteWorkspace(workspaceID) {
                            workspaceAlert = .deletionFailed
                        }
                    },
                    secondaryButton: .cancel()
                )
            case .deletionFailed:
                return Alert(
                    title: Text("Workspace not deleted"),
                    message: Text("Each profile must retain at least one workspace. No workspace was removed."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private var workspaceLifecycleControls: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Workspace lifecycle")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Button(role: .destructive) {
                    workspaceAlert = .confirmDelete
                } label: {
                    Label("Delete active workspace", systemImage: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(!canDeleteActiveWorkspace)
                .help("Delete this workspace from all profiles that reference it")
                .accessibilityIdentifier("workspace.delete-active")
            }

            Text(
                canDeleteActiveWorkspace
                    ? "Deletes the active workspace layout from its associated profiles only."
                    : "This is the last workspace in at least one associated profile. Create another workspace before deleting it."
            )
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
    }

    private enum WorkspaceManagementAlert: String, Identifiable {
        case confirmDelete
        case deletionFailed

        var id: String { rawValue }
    }

    @ViewBuilder
    private func panelRow(
        _ configuration: WorkspacePanelConfiguration,
        in regionPanels: [WorkspacePanelConfiguration]
    ) -> some View {
        let regionIndex = regionPanels.firstIndex(where: { $0.panelID == configuration.panelID }) ?? 0
        let globalIndex = engine.orderedPanels.firstIndex(where: { $0.panelID == configuration.panelID }) ?? 0

        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
            Text(configuration.panelID.title)
                .lineLimit(1)
            Spacer(minLength: 8)

            Toggle(
                "Visible",
                isOn: Binding(
                    get: { configuration.isVisible },
                    set: { isVisible in
                        schedulePanelMutation {
                            engine.setPanelVisibility(configuration.panelID, isVisible: isVisible)
                        }
                    }
                )
            )
            .labelsHidden()
            .accessibilityLabel("Show \(configuration.panelID.title)")

            Button {
                guard regionIndex > 0 else { return }
                let previous = regionPanels[regionIndex - 1].panelID
                let destination = engine.orderedPanels.firstIndex(where: { $0.panelID == previous }) ?? globalIndex
                schedulePanelMutation {
                    _ = engine.movePanel(configuration.panelID, to: destination)
                }
            } label: {
                Image(systemName: "arrow.up")
            }
            .buttonStyle(.borderless)
            .disabled(regionIndex == 0)
            .help("Move panel up")

            Button {
                guard regionIndex + 1 < regionPanels.count else { return }
                let next = regionPanels[regionIndex + 1].panelID
                let destination = engine.orderedPanels.firstIndex(where: { $0.panelID == next }) ?? globalIndex
                schedulePanelMutation {
                    _ = engine.movePanel(configuration.panelID, to: destination)
                }
            } label: {
                Image(systemName: "arrow.down")
            }
            .buttonStyle(.borderless)
            .disabled(regionIndex + 1 >= regionPanels.count)
            .help("Move panel down")

            Button(role: .destructive) {
                schedulePanelMutation {
                    _ = engine.removePanel(configuration.panelID)
                }
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
            .help("Remove panel from this workspace")
        }
        .padding(.vertical, 3)
    }
}
