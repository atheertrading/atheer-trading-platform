import SwiftUI

/// Workspace-scoped panel lifecycle and layout controls.
struct WorkspacePanelManagementView: View {
    @ObservedObject var engine: WorkspaceEngine

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
        .frame(minWidth: 540, minHeight: 560)
        .background(ATHEERDesignTokens.ColorRole.canvas)
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
