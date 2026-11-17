import SwiftUI

/// Shared visual primitives for the native ATHEER Trading Pro interface.
/// Values preserve the owner-provided brand palette and the existing shell treatment.
enum ATHEERDesignTokens {
    enum ColorRole {
        static let canvas = Color(red: 18.0 / 255.0, green: 18.0 / 255.0, blue: 18.0 / 255.0)
        static let deepTeal = Color(red: 9.0 / 255.0, green: 55.0 / 255.0, blue: 50.0 / 255.0)
        static let navy = Color(red: 0.0, green: 31.0 / 255.0, blue: 63.0 / 255.0)
        static let teal = Color(red: 0.0, green: 128.0 / 255.0, blue: 128.0 / 255.0)
        static let accent = Color(red: 0.0, green: 206.0 / 255.0, blue: 200.0 / 255.0)
        static let attention = Color(red: 1.0, green: 215.0 / 255.0, blue: 0.0)
        static let danger = Color(red: 211.0 / 255.0, green: 47.0 / 255.0, blue: 47.0 / 255.0)
        static let success = Color(red: 0.0, green: 200.0 / 255.0, blue: 83.0 / 255.0)
        static let panel = Color.white.opacity(0.035)
        static let panelElevated = Color.white.opacity(0.055)
        static let separator = Color.white.opacity(0.08)
        static let secondaryText = Color.secondary
    }

    enum Typography {
        static let brand = Font.system(size: 18, weight: .bold, design: .rounded)
        static let screenTitle = Font.system(size: 25, weight: .semibold)
        static let panelTitle = Font.system(size: 13, weight: .semibold)
        static let body = Font.system(size: 12)
        static let caption = Font.system(size: 10, weight: .medium)
        static let numeric = Font.system(size: 15, weight: .semibold, design: .monospaced)
    }

    enum Spacing {
        static let compact: CGFloat = 6
        static let standard: CGFloat = 12
        static let section: CGFloat = 18
        static let page: CGFloat = 24
    }
}
