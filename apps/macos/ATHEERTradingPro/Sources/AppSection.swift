import Foundation

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case workspace
    case apiConnection
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .workspace: return "Workspace"
        case .apiConnection: return "API Connection"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .workspace: return "square.grid.2x2"
        case .apiConnection: return "network"
        case .settings: return "gearshape"
        }
    }
}
