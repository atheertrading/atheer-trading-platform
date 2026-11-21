import SwiftUI

enum ATHEERStatusTone {
    case positive
    case warning
    case negative
    case information
    case neutral

    var color: Color {
        switch self {
        case .positive: return ATHEERDesignTokens.ColorRole.success
        case .warning: return ATHEERDesignTokens.ColorRole.warning
        case .negative: return ATHEERDesignTokens.ColorRole.error
        case .information: return ATHEERDesignTokens.ColorRole.information
        case .neutral: return ATHEERDesignTokens.ColorRole.neutralText
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .positive: return "Positive status"
        case .warning: return "Warning status"
        case .negative: return "Error status"
        case .information: return "Information status"
        case .neutral: return "Neutral status"
        }
    }
}

/// Read-only status presentation. It intentionally has no action or button semantics.
struct ATHEERStatusBadge: View {
    let title: String
    let tone: ATHEERStatusTone

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tone.color)
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)
            Text(title)
                .font(ATHEERDesignTokens.Typography.caption)
                .foregroundColor(ATHEERDesignTokens.ColorRole.primaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tone.color.opacity(0.12))
        .overlay(
            Capsule().stroke(tone.color.opacity(0.32), lineWidth: ATHEERDesignTokens.Stroke.standard)
        )
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(tone.accessibilityDescription))
    }
}
