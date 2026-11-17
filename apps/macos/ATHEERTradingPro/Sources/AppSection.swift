import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case workspace
    case apiConnection

    var id: String { rawValue }

    var title: String {
        switch self {
        case .workspace: return "Workspace"
        case .apiConnection: return "API Connection"
        }
    }

    var systemImage: String {
        switch self {
        case .workspace: return "square.grid.2x2"
        case .apiConnection: return "network"
        }
    }
}
