import SwiftUI

/// Workspace-scoped panel lifecycle and layout controls.
struct WorkspacePanelManagementView: View {
    @ObservedObject var engine: WorkspaceEngine
    @State private var workspaceAlert: WorkspaceManagementAlert?
    @State private var targetedPanelID: WorkspacePanelID?
    @State private var transferFeedback: String?

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
            .textSelection(.enabled)
            .pasteDestination(for: ATHEERWorkspacePanelTransfer.self) { transfers in
                guard transfers.count == 1 else {
                    transferFeedback = "Paste one panel reference at a time."
                    return
                }
                pastePanelReference(transfers[0])
            }
            .pasteDestination(for: ATHEERWorkspaceLayoutTransfer.self) { transfers in
                guard transfers.count == 1 else {
                    transferFeedback = "Paste one workspace layout at a time."
                    return
                }
                importWorkspaceLayout(transfers[0])
            }
            .dropDestination(for: ATHEERWorkspaceLayoutTransfer.self) { transfers, _ in
                guard transfers.count == 1 else { return false }
                importWorkspaceLayout(transfers[0])
                return true
            }

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

            HStack(spacing: 10) {
                Button {
                    let transfer = ATHEERWorkspaceLayoutTransfer(workspace: engine.activeWorkspace)
                    if ATHEERClipboardService.copyJSON(
                        transfer,
                        contentType: .atheerWorkspaceLayout
                    ) {
                        transferFeedback = "Workspace layout copied as versioned JSON."
                    } else {
                        transferFeedback = "Workspace layout could not be copied."
                    }
                } label: {
                    Label("Copy Layout JSON", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .help("Copy the active workspace presentation layout. No broker or trading state is included.")

                Text("Paste or drop a compatible layout into the panel list to import it as a new workspace.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Panel references can be copied, pasted into another workspace, or dragged to reorder.")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let transferFeedback {
                Text(transferFeedback)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ATHEERDesignTokens.ColorRole.information)
                    .accessibilityLabel(transferFeedback)
            }
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

        let transfer = ATHEERWorkspacePanelTransfer(
            sourceWorkspaceID: engine.activeWorkspace.id,
            panelID: configuration.panelID
        )
        let isDropTarget = Binding<Bool>(
            get: { targetedPanelID == configuration.panelID },
            set: { isTargeted in
                targetedPanelID = isTargeted ? configuration.panelID : nil
            }
        )

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
        .draggable(transfer)
        .copyable([transfer])
        .dropDestination(
            for: ATHEERWorkspacePanelTransfer.self,
            action: { transfers, location in
                acceptPanelDrop(
                    transfers,
                    on: configuration,
                    in: regionPanels,
                    location: location
                )
            },
            isTargeted: isDropTarget
        )
        .overlay {
            if targetedPanelID == configuration.panelID {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(ATHEERDesignTokens.ColorRole.accent, lineWidth: 2)
                    .allowsHitTesting(false)
            }
        }
        .contextMenu {
            Button("Copy Panel Reference") {
                let transfer = ATHEERWorkspacePanelTransfer(
                    sourceWorkspaceID: engine.activeWorkspace.id,
                    panelID: configuration.panelID
                )
                let copied = ATHEERClipboardService.copyJSON(
                    transfer,
                    contentType: .atheerWorkspacePanel
                )
                transferFeedback = copied
                    ? "Panel reference copied."
                    : "Panel reference could not be copied."
            }
            Button("Move Up") {
                guard regionIndex > 0 else { return }
                let previous = regionPanels[regionIndex - 1].panelID
                let destination = engine.orderedPanels.firstIndex(where: { $0.panelID == previous }) ?? globalIndex
                schedulePanelMutation { _ = engine.movePanel(configuration.panelID, to: destination) }
            }
            .disabled(regionIndex == 0)
            Button("Move Down") {
                guard regionIndex + 1 < regionPanels.count else { return }
                let next = regionPanels[regionIndex + 1].panelID
                let destination = engine.orderedPanels.firstIndex(where: { $0.panelID == next }) ?? globalIndex
                schedulePanelMutation { _ = engine.movePanel(configuration.panelID, to: destination) }
            }
            .disabled(regionIndex + 1 >= regionPanels.count)
        }
        .accessibilityIdentifier("workspace.panel-row.\(configuration.panelID.rawValue)")
    }

    private func acceptPanelDrop(
        _ transfers: [ATHEERWorkspacePanelTransfer],
        on target: WorkspacePanelConfiguration,
        in regionPanels: [WorkspacePanelConfiguration],
        location: CGPoint
    ) -> Bool {
        guard transfers.count == 1,
              let transfer = transfers.first,
              let sourcePanelID = transfer.panelID,
              sourcePanelID.isPrimaryRegion == target.panelID.isPrimaryRegion else {
            transferFeedback = "This destination does not accept that panel reference."
            return false
        }

        let destinationWorkspaceID = engine.activeWorkspace.id
        let destinationIndex = engine.orderedPanels.firstIndex(
            where: { $0.panelID == target.panelID }
        ) ?? engine.orderedPanels.count

        if transfer.sourceWorkspaceID == destinationWorkspaceID {
            guard regionPanels.contains(where: { $0.panelID == sourcePanelID }),
                  let sourceIndex = engine.orderedPanels.firstIndex(
                    where: { $0.panelID == sourcePanelID }
                  ) else {
                return false
            }

            var insertionIndex = destinationIndex + (location.y > 18 ? 1 : 0)
            if sourceIndex < insertionIndex {
                insertionIndex -= 1
            }

            let regionIndices = engine.orderedPanels.enumerated()
                .filter { $0.element.panelID.isPrimaryRegion == target.panelID.isPrimaryRegion }
                .map(\.offset)
            guard let firstRegionIndex = regionIndices.first,
                  let lastRegionIndex = regionIndices.last else {
                return false
            }
            insertionIndex = min(max(insertionIndex, firstRegionIndex), lastRegionIndex)

            schedulePanelMutation {
                _ = engine.movePanel(sourcePanelID, to: insertionIndex)
            }
            transferFeedback = "Panel move accepted."
            return true
        }

        let insertionIndex = min(
            destinationIndex + (location.y > 18 ? 1 : 0),
            engine.orderedPanels.count
        )
        schedulePanelMutation {
            let copied = engine.copyPanelConfiguration(
                sourcePanelID,
                from: transfer.sourceWorkspaceID,
                to: destinationWorkspaceID,
                at: insertionIndex
            )
            transferFeedback = copied
                ? "Panel copied into the active workspace."
                : "Panel could not be copied. Check the source and destination workspaces."
        }
        return true
    }

    private func pastePanelReference(_ transfer: ATHEERWorkspacePanelTransfer) {
        let destinationWorkspaceID = engine.activeWorkspace.id
        guard transfer.sourceWorkspaceID != destinationWorkspaceID,
              let panelID = transfer.panelID else {
            transferFeedback = "Switch to another workspace to paste this panel reference."
            return
        }

        schedulePanelMutation {
            let copied = engine.copyPanelConfiguration(
                panelID,
                from: transfer.sourceWorkspaceID,
                to: destinationWorkspaceID
            )
            transferFeedback = copied
                ? "Panel copied into the active workspace."
                : "Panel could not be pasted into this workspace."
        }
    }

    private func importWorkspaceLayout(_ transfer: ATHEERWorkspaceLayoutTransfer) {
        schedulePanelMutation {
            if engine.importWorkspaceLayout(transfer) != nil {
                transferFeedback = "Workspace layout imported as a new workspace."
            } else {
                transferFeedback = "Workspace layout is invalid or could not be imported."
            }
        }
    }
}
