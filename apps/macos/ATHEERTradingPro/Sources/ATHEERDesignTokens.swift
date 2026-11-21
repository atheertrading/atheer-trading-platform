import AppKit
import SwiftUI

/// Shared semantic tokens for the ATHEER Trading Pro native macOS workstation.
/// Existing role names are retained for source compatibility with current screens.
enum ATHEERDesignTokens {
    /// Raw source palette. The current turquoise value is preserved pending owner resolution
    /// of the documented #40E0D0 versus #00CEC8 source conflict.
    enum PrimitiveColor {
        static let graphiteBlack: UInt32 = 0x121212
        static let deepTeal: UInt32 = 0x093732
        static let midnightNavy: UInt32 = 0x001F3F
        static let teal: UInt32 = 0x008080
        static let currentTurquoise: UInt32 = 0x00CEC8
        static let gold: UInt32 = 0xFFD700
        static let slateBlue: UInt32 = 0x384959
        static let mutedTeal: UInt32 = 0x3C635F
        static let softTurquoise: UInt32 = 0x81D8D0
        static let positive: UInt32 = 0x00C853
        static let negative: UInt32 = 0xD32F2F
    }

    enum Palette {
        static let graphite = ColorRole.rgb(PrimitiveColor.graphiteBlack)
        static let deepTeal = ColorRole.rgb(PrimitiveColor.deepTeal)
        static let midnightNavy = ColorRole.rgb(PrimitiveColor.midnightNavy)
        static let teal = ColorRole.rgb(PrimitiveColor.teal)
        static let currentTurquoise = ColorRole.rgb(PrimitiveColor.currentTurquoise)
        static let gold = ColorRole.rgb(PrimitiveColor.gold)
        static let slate = ColorRole.rgb(PrimitiveColor.slateBlue)
        static let mutedTeal = ColorRole.rgb(PrimitiveColor.mutedTeal)
        static let softTurquoise = ColorRole.rgb(PrimitiveColor.softTurquoise)
        static let positive = ColorRole.rgb(PrimitiveColor.positive)
        static let negative = ColorRole.rgb(PrimitiveColor.negative)
    }

    /// Appearance-aware roles. Feature views should consume these roles, not raw hex values.
    enum ColorRole {
        static let canvas = adaptive(dark: 0x121212, light: 0xF4F7F7)
        static let deepTeal = adaptive(dark: 0x093732, light: 0xE7F0EE)
        static let navy = adaptive(dark: 0x001F3F, light: 0xEAF0F5)
        static let teal = adaptive(dark: 0x008080, light: 0x006D6B)
        static let accent = adaptive(dark: 0x00CEC8, light: 0x007D78)
        static let brandTurquoise = rgb(PrimitiveColor.currentTurquoise)
        static let brandGold = rgb(PrimitiveColor.gold)
        static let onAccent = adaptive(dark: 0x001F3F, light: 0xFFFFFF)
        static let attention = adaptive(dark: 0xFFD700, light: 0x8A6200)
        static let danger = adaptive(dark: 0xEF5350, light: 0xB42318)
        static let success = adaptive(dark: 0x00C853, light: 0x15803D)
        static let information = adaptive(dark: 0x4EA5FF, light: 0x005DAA)
        static let neutral = adaptive(dark: 0x384959, light: 0x52616B)
        static let neutralText = adaptive(dark: 0xAAB6B8, light: 0x52616A)
        static let onDanger = adaptive(dark: 0x001F3F, light: 0xFFFFFF)
        static let panel = adaptive(dark: 0x1A1E1F, light: 0xFFFFFF)
        static let panelElevated = adaptive(dark: 0x242A2B, light: 0xF0F4F4)
        static let separator = adaptive(dark: 0x354044, light: 0xD9E1E3)
        static let primaryText = adaptive(dark: 0xF1F5F5, light: 0x172126)
        static let secondaryText = adaptive(dark: 0xAAB6B8, light: 0x52636A)
        static let focus = accent
        static let border = separator
        static let warning = attention
        static let error = danger
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

    /// Native system typography is the default; monospaced numerals stabilize financial columns.
    enum Typography {
        static let brand = Font.system(size: 18, weight: .semibold)
        static let display = Font.system(size: 28, weight: .semibold)
        static let screenTitle = Font.system(size: 25, weight: .semibold)
        static let sectionTitle = Font.system(size: 16, weight: .semibold)
        static let standardBody = Font.system(size: 13, weight: .regular)
        static let panelTitle = Font.system(size: 13, weight: .semibold)
        static let controlLabel = Font.system(size: 13, weight: .medium)
        static let body = Font.system(size: 12)
        static let caption = Font.system(size: 10, weight: .medium)
        static let metadata = Font.system(size: 10, weight: .regular)
        static let numeric = Font.system(size: 15, weight: .semibold, design: .monospaced)
        static let tableNumeric = Font.system(size: 12, weight: .medium, design: .monospaced)
        static let diagnostic = Font.system(size: 11, weight: .regular, design: .monospaced)
    }

    /// Legacy token values are retained. New semantic names are additive.
    enum Spacing {
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let compact: CGFloat = 6
        static let standard: CGFloat = 12
        static let content: CGFloat = 16
        static let section: CGFloat = 18
        static let large: CGFloat = 24
        static let page: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 6
        static let standard: CGFloat = 8
        static let large: CGFloat = 12
        static let capsule: CGFloat = 999
    }

    enum Stroke {
        static let standard: CGFloat = 1
        static let focus: CGFloat = 2
    }

    /// Project targets informed by Apple's macOS accessibility guidance.
    /// Touch expansion is separate and must not permanently enlarge desktop controls.
    enum ControlMetrics {
        static let macOSDefaultTarget: CGFloat = 28
        static let macOSMinimumTarget: CGFloat = 20
        static let touchExpandedTarget: CGFloat = 44
        static let compactButtonHeight: CGFloat = 28
        static let regularButtonHeight: CGFloat = 32
        static let prominentButtonHeight: CGFloat = 40
        static let criticalActionHeight: CGFloat = 44
        static let iconButtonWidth: CGFloat = 28
    }

    enum Motion {
        static let quick: Double = 0.12
        static let standard: Double = 0.18
        static let deliberate: Double = 0.24
    }
}
