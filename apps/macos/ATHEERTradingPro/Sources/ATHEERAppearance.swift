import SwiftUI

enum ATHEERAppearance: String, CaseIterable, Equatable, Identifiable {
    case dark
    case light

    static let storageKey = "atheer.appearance.preference"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .dark: return .dark
        case .light: return .light
        }
    }

    static func resolve(_ rawValue: String) -> ATHEERAppearance {
        ATHEERAppearance(rawValue: rawValue) ?? .dark
    }
}
