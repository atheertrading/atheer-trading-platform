import Foundation

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case workspace
    case markets
    case charts
    case apiConnection
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .workspace: return "Workspace"
        case .markets: return "Markets"
        case .charts: return "Charts"
        case .apiConnection: return "API Connection"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .workspace: return "square.grid.2x2"
        case .markets: return "chart.xyaxis.line"
        case .charts: return "chart.xyaxis.line"
        case .apiConnection: return "network"
        case .settings: return "gearshape"
        }
    }
}
