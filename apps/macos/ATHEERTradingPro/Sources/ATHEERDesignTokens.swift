import AppKit
import SwiftUI

/// Shared, semantic design tokens for the ATHEER Trading Pro workstation.
/// Existing public role names are retained to keep current feature views source-compatible.
enum ATHEERDesignTokens {
    enum Palette {
        static let graphite = ColorRole.rgb(0x121212)
        static let deepTeal = ColorRole.rgb(0x093732)
        static let midnightNavy = ColorRole.rgb(0x001F3F)
        static let teal = ColorRole.rgb(0x008080)
        static let currentTurquoise = ColorRole.rgb(0x00CEC8)
        static let gold = ColorRole.rgb(0xFFD700)
        static let slate = ColorRole.rgb(0x384959)
        static let mutedTeal = ColorRole.rgb(0x3C635F)
        static let softTurquoise = ColorRole.rgb(0x81D8D0)
        static let positive = ColorRole.rgb(0x00C853)
        static let negative = ColorRole.rgb(0xD32F2F)
    }

    enum ColorRole {
        static let canvas = adaptive(dark: 0x121212, light: 0xF4F7F7)
        static let deepTeal = adaptive(dark: 0x093732, light: 0xE7F0EE)
        static let navy = adaptive(dark: 0x001F3F, light: 0xEAF0F5)
        static let teal = adaptive(dark: 0x008080, light: 0x006D6B)

        /// Interactive accent is theme-mapped for legibility.
        /// The canonical raw brand turquoise remains under source reconciliation.
        static let accent = adaptive(dark: 0x00CEC8, light: 0x007D78)
        static let brandTurquoise = rgb(0x00CEC8)
        static let brandGold = rgb(0xFFD700)

        static let attention = adaptive(dark: 0xFFD700, light: 0x8A6200)
        static let danger = adaptive(dark: 0xEF5350, light: 0xB42318)
        static let success = adaptive(dark: 0x00C853, light: 0x15803D)
        static let neutral = adaptive(dark: 0x384959, light: 0x52616B)

        static let panel = adaptive(dark: 0x1A1E1F, light: 0xFFFFFF)
        static let panelElevated = adaptive(dark: 0x242A2B, light: 0xF0F4F4)
        static let separator = adaptive(dark: 0x354044, light: 0xD9E1E3)
        static let primaryText = adaptive(dark: 0xF1F5F5, light: 0x172126)
        static let secondaryText = adaptive(dark: 0xAAB6B8, light: 0x52636A)

        /// Compatibility role used by existing screen components.
        static let secondaryTextCompatibility = Color.secondary

        private static func adaptive(dark: UInt32, light: UInt32) -> Color {
            let darkColor = nsColor(dark)
            let lightColor = nsColor(light)
            let dynamicColor = NSColor(
                name: nil,
                dynamicProvider: { appearance in
                    let match = appearance.bestMatch(from: [.darkAqua, .aqua])
                    return match == .darkAqua ? darkColor : lightColor
                }
            )
            return Color(nsColor: dynamicColor)
        }

        private static func nsColor(_ hex: UInt32) -> NSColor {
            NSColor(
                calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255.0,
                green: CGFloat((hex >> 8) & 0xFF) / 255.0,
                blue: CGFloat(hex & 0xFF) / 255.0,
                alpha: 1.0
            )
        }

        fileprivate static func rgb(_ hex: UInt32) -> Color {
            Color(nsColor: nsColor(hex))
        }
    }

    enum Typography {
        static let brand = Font.system(size: 18, weight: .semibold)
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

    enum Radius {
        static let small: CGFloat = 6
        static let standard: CGFloat = 8
        static let large: CGFloat = 12
    }
}
