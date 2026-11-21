import CoreTransferable
import Foundation
import UniformTypeIdentifiers

extension UTType {
    /// Versioned ATHEER payloads are JSON-conforming for controlled interoperability.
    static let atheerWorkspacePanel = UTType(
        exportedAs: "com.atheertrading.workspace-panel",
        conformingTo: .json
    )
    static let atheerWorkspaceLayout = UTType(
        exportedAs: "com.atheertrading.workspace-layout",
        conformingTo: .json
    )
    static let atheerInstrumentReference = UTType(
        exportedAs: "com.atheertrading.instrument-reference",
        conformingTo: .json
    )
}

/// An inert reference to a panel configuration. It contains no panel data or service state.
struct ATHEERWorkspacePanelTransfer: Codable, Equatable, Transferable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let sourceWorkspaceID: UUID
    let panelIdentifier: String

    init(sourceWorkspaceID: UUID, panelID: WorkspacePanelID) {
        schemaVersion = Self.currentSchemaVersion
        self.sourceWorkspaceID = sourceWorkspaceID
        panelIdentifier = panelID.rawValue
    }

    var panelID: WorkspacePanelID? {
        guard schemaVersion == Self.currentSchemaVersion else { return nil }
        return WorkspacePanelID(rawValue: panelIdentifier)
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .atheerWorkspacePanel)
        ProxyRepresentation(exporting: \.panelIdentifier)
    }
}

/// A safe, versioned export of workspace presentation configuration only.
struct ATHEERWorkspaceLayoutTransfer: Codable, Equatable, Transferable {
    static let currentSchemaVersion = 1

    struct Panel: Codable, Equatable {
        let panelIdentifier: String
        let isVisible: Bool
        let order: Int
    }

    enum ValidationError: Error, Equatable {
        case unsupportedSchema
        case invalidWorkspaceName
        case tooManyPanels
        case unsupportedPanel(String)
        case duplicatePanel(String)
        case invalidPanelOrder
        case invalidLayout
    }

    let schemaVersion: Int
    let workspaceName: String
    let panels: [Panel]
    let layout: WorkspaceLayoutConfiguration

    init(
        schemaVersion: Int,
        workspaceName: String,
        panels: [Panel],
        layout: WorkspaceLayoutConfiguration
    ) {
        self.schemaVersion = schemaVersion
        self.workspaceName = workspaceName
        self.panels = panels
        self.layout = layout
    }

    init(workspace: WorkspaceDocument) {
        schemaVersion = Self.currentSchemaVersion
        workspaceName = workspace.name
        panels = workspace.panels.map {
            Panel(
                panelIdentifier: $0.panelID.rawValue,
                isVisible: $0.isVisible,
                order: $0.order
            )
        }
        layout = workspace.layout
    }

    func makeWorkspaceDocument(
        id: UUID = UUID(),
        updatedAt: Date = Date()
    ) throws -> WorkspaceDocument {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw ValidationError.unsupportedSchema
        }

        let trimmedName = workspaceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, trimmedName.count <= 64 else {
            throw ValidationError.invalidWorkspaceName
        }
        guard panels.count <= WorkspacePanelID.allCases.count else {
            throw ValidationError.tooManyPanels
        }

        var seen = Set<WorkspacePanelID>()
        var convertedPanels: [WorkspacePanelConfiguration] = []
        convertedPanels.reserveCapacity(panels.count)

        for panel in panels {
            guard let panelID = WorkspacePanelID(rawValue: panel.panelIdentifier) else {
                throw ValidationError.unsupportedPanel(panel.panelIdentifier)
            }
            guard seen.insert(panelID).inserted else {
                throw ValidationError.duplicatePanel(panel.panelIdentifier)
            }
            guard panel.order >= 0 else {
                throw ValidationError.invalidPanelOrder
            }
            convertedPanels.append(
                WorkspacePanelConfiguration(
                    panelID: panelID,
                    isVisible: panel.isVisible,
                    order: panel.order
                )
            )
        }

        let orders = convertedPanels.map(\.order)
        guard Set(orders).count == orders.count else {
            throw ValidationError.invalidPanelOrder
        }

        guard layout.sidebarWidth.isFinite,
              layout.minimumPrimaryWidth.isFinite,
              (220...640).contains(layout.sidebarWidth),
              (320...1200).contains(layout.minimumPrimaryWidth) else {
            throw ValidationError.invalidLayout
        }

        return WorkspaceDocument(
            id: id,
            name: trimmedName,
            panels: convertedPanels.sorted { $0.order < $1.order },
            layout: layout,
            updatedAt: updatedAt
        )
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .atheerWorkspaceLayout)
        ProxyRepresentation(exporting: \.workspaceName)
    }
}

enum ATHEERInstrumentIdentifierKind: String, Codable {
    case epic
    case symbol
}

/// Provider-grounded instrument identity only; never carries quotes, account state, or orders.
struct ATHEERInstrumentReferenceTransfer: Codable, Equatable, Transferable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let identifier: String
    let identifierKind: ATHEERInstrumentIdentifierKind
    let providerIdentifier: String?

    init(
        identifier: String,
        identifierKind: ATHEERInstrumentIdentifierKind,
        providerIdentifier: String? = nil
    ) {
        schemaVersion = Self.currentSchemaVersion
        self.identifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        self.identifierKind = identifierKind
        self.providerIdentifier = providerIdentifier?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        guard schemaVersion == Self.currentSchemaVersion,
              !identifier.isEmpty,
              identifier.count <= 128,
              !identifier.contains(where: \.isNewline) else {
            return false
        }
        if let providerIdentifier {
            return !providerIdentifier.isEmpty &&
                providerIdentifier.count <= 64 &&
                !providerIdentifier.contains(where: \.isNewline)
        }
        return true
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .atheerInstrumentReference)
        ProxyRepresentation(exporting: \.identifier)
    }
}
