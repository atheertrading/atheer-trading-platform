import XCTest
@testable import ATHEERTradingPro

final class ATHEERContentTransferTests: XCTestCase {
    func testWorkspacePanelTransferCarriesOnlyVersionedPanelReference() throws {
        let workspaceID = UUID()
        let transfer = ATHEERWorkspacePanelTransfer(
            sourceWorkspaceID: workspaceID,
            panelID: .charts
        )

        let data = try JSONEncoder().encode(transfer)
        let decoded = try JSONDecoder().decode(ATHEERWorkspacePanelTransfer.self, from: data)

        XCTAssertEqual(decoded, transfer)
        XCTAssertEqual(decoded.panelID, .charts)
        XCTAssertEqual(decoded.sourceWorkspaceID, workspaceID)
        XCTAssertEqual(decoded.schemaVersion, ATHEERWorkspacePanelTransfer.currentSchemaVersion)
    }

    func testWorkspacePanelTransferRejectsUnknownPanelIdentifierAndSchema() throws {
        let unknownPanelJSON = Data("""
        {
          "schemaVersion": 1,
          "sourceWorkspaceID": "\(UUID().uuidString)",
          "panelIdentifier": "brokerCredentials"
        }
        """.utf8)
        let unknownPanel = try JSONDecoder().decode(
            ATHEERWorkspacePanelTransfer.self,
            from: unknownPanelJSON
        )
        XCTAssertNil(unknownPanel.panelID)

        let unsupportedSchemaJSON = Data("""
        {
          "schemaVersion": 99,
          "sourceWorkspaceID": "\(UUID().uuidString)",
          "panelIdentifier": "charts"
        }
        """.utf8)
        let unsupportedSchema = try JSONDecoder().decode(
            ATHEERWorkspacePanelTransfer.self,
            from: unsupportedSchemaJSON
        )
        XCTAssertNil(unsupportedSchema.panelID)
    }

    func testWorkspaceLayoutTransferRoundTripsPresentationOnlyConfiguration() throws {
        let source = WorkspaceDocument.standard(name: "Research")
        let transfer = ATHEERWorkspaceLayoutTransfer(workspace: source)
        let data = try JSONEncoder().encode(transfer)
        let decoded = try JSONDecoder().decode(ATHEERWorkspaceLayoutTransfer.self, from: data)
        let newIdentity = UUID()
        let restored = try decoded.makeWorkspaceDocument(id: newIdentity)

        XCTAssertEqual(restored.id, newIdentity)
        XCTAssertNotEqual(restored.id, source.id)
        XCTAssertEqual(restored.name, source.name)
        XCTAssertEqual(restored.panels, source.panels)
        XCTAssertEqual(restored.layout, source.layout)
    }

    func testWorkspaceLayoutTransferRejectsUnsupportedSchemaAndUnknownPanels() throws {
        let source = WorkspaceDocument.standard(name: "Layout")
        let valid = ATHEERWorkspaceLayoutTransfer(workspace: source)

        let unsupported = ATHEERWorkspaceLayoutTransfer(
            schemaVersion: 99,
            workspaceName: valid.workspaceName,
            panels: valid.panels,
            layout: valid.layout
        )
        XCTAssertThrowsError(try unsupported.makeWorkspaceDocument()) { error in
            XCTAssertEqual(
                error as? ATHEERWorkspaceLayoutTransfer.ValidationError,
                .unsupportedSchema
            )
        }

        let unknownPanel = ATHEERWorkspaceLayoutTransfer(
            schemaVersion: 1,
            workspaceName: "Untrusted",
            panels: [
                .init(panelIdentifier: "riskBypass", isVisible: true, order: 0)
            ],
            layout: .standard
        )
        XCTAssertThrowsError(try unknownPanel.makeWorkspaceDocument()) { error in
            XCTAssertEqual(
                error as? ATHEERWorkspaceLayoutTransfer.ValidationError,
                .unsupportedPanel("riskBypass")
            )
        }
    }

    func testWorkspaceLayoutTransferRejectsDuplicatePanelsAndInvalidGeometry() throws {
        let duplicatePanels = ATHEERWorkspaceLayoutTransfer(
            schemaVersion: 1,
            workspaceName: "Duplicate",
            panels: [
                .init(panelIdentifier: WorkspacePanelID.charts.rawValue, isVisible: true, order: 0),
                .init(panelIdentifier: WorkspacePanelID.charts.rawValue, isVisible: false, order: 1)
            ],
            layout: .standard
        )
        XCTAssertThrowsError(try duplicatePanels.makeWorkspaceDocument()) { error in
            XCTAssertEqual(
                error as? ATHEERWorkspaceLayoutTransfer.ValidationError,
                .duplicatePanel(WorkspacePanelID.charts.rawValue)
            )
        }

        let invalidLayout = WorkspaceLayoutConfiguration(
            style: .adaptiveColumns,
            sidebarWidth: .infinity,
            minimumPrimaryWidth: 500
        )
        let invalidGeometry = ATHEERWorkspaceLayoutTransfer(
            schemaVersion: 1,
            workspaceName: "Invalid Geometry",
            panels: [],
            layout: invalidLayout
        )
        XCTAssertThrowsError(try invalidGeometry.makeWorkspaceDocument()) { error in
            XCTAssertEqual(
                error as? ATHEERWorkspaceLayoutTransfer.ValidationError,
                .invalidLayout
            )
        }
    }

    func testInstrumentReferenceTransferRejectsEmptyAndUnboundedIdentifiers() {
        XCTAssertTrue(
            ATHEERInstrumentReferenceTransfer(
                identifier: "UK100",
                identifierKind: .symbol,
                providerIdentifier: "capital.com"
            ).isValid
        )
        XCTAssertFalse(
            ATHEERInstrumentReferenceTransfer(
                identifier: "   ",
                identifierKind: .epic
            ).isValid
        )
        XCTAssertFalse(
            ATHEERInstrumentReferenceTransfer(
                identifier: String(repeating: "X", count: 129),
                identifierKind: .epic
            ).isValid
        )
        XCTAssertFalse(
            ATHEERInstrumentReferenceTransfer(
                identifier: "WTI\nM1",
                identifierKind: .symbol
            ).isValid
        )
    }
}
