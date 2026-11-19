import Foundation

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case workspace
    case markets
    case apiConnection
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .workspace: return "Command Center"
        case .markets: return "Markets"
        case .apiConnection: return "API Connection"
        case .settings: return "System & Administration"
        }
    }

    var groupTitle: String {
        switch self {
        case .workspace: return "WORKSPACE"
        case .markets: return "MARKETS"
        case .apiConnection: return "SYSTEM"
        case .settings: return "SYSTEM"
        }
    }

    var systemImage: String {
        switch self {
        case .workspace: return "square.grid.2x2"
        case .markets: return "chart.xyaxis.line"
        case .apiConnection: return "network"
        case .settings: return "gearshape"
        }
    }
}
