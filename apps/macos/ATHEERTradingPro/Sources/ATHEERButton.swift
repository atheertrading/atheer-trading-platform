import SwiftUI

enum ATHEERButtonVariant {
    case primary
    case secondary
    case tertiary
    case destructive
}

enum ATHEERButtonSize {
    case compact
    case regular
    case prominent
    case critical

    var minimumHeight: CGFloat {
        switch self {
        case .compact: return ATHEERDesignTokens.ControlMetrics.compactButtonHeight
        case .regular: return ATHEERDesignTokens.ControlMetrics.regularButtonHeight
        case .prominent: return ATHEERDesignTokens.ControlMetrics.prominentButtonHeight
        case .critical: return ATHEERDesignTokens.ControlMetrics.criticalActionHeight
        }
    }

    var controlSize: ControlSize {
        switch self {
        case .compact: return .small
        case .regular: return .regular
        case .prominent, .critical: return .large
        }
    }
}

/// Semantic button wrapper that retains native macOS Button behavior and focus treatment.
/// Prefer native toolbar items and system styles for commands placed in the window toolbar.
struct ATHEERButton<Label: View>: View {
    let variant: ATHEERButtonVariant
    let size: ATHEERButtonSize
    private let action: () -> Void
    private let label: Label

    init(
        variant: ATHEERButtonVariant = .secondary,
        size: ATHEERButtonSize = .regular,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.variant = variant
        self.size = size
        self.action = action
        self.label = label()
    }

    @ViewBuilder
    var body: some View {
        switch variant {
        case .primary:
            Button(action: action, label: { label })
                .buttonStyle(.borderedProminent)
                .tint(ATHEERDesignTokens.ColorRole.accent)
                .controlSize(size.controlSize)
                .frame(minHeight: size.minimumHeight)
        case .secondary:
            Button(action: action, label: { label })
                .buttonStyle(.bordered)
                .controlSize(size.controlSize)
                .frame(minHeight: size.minimumHeight)
        case .tertiary:
            Button(action: action, label: { label })
                .buttonStyle(.plain)
                .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
                .controlSize(size.controlSize)
                .frame(minHeight: size.minimumHeight)
        case .destructive:
            Button(role: .destructive, action: action, label: { label })
                .buttonStyle(.borderedProminent)
                .tint(ATHEERDesignTokens.ColorRole.danger)
                .controlSize(size.controlSize)
                .frame(minHeight: size.minimumHeight)
        }
    }
}
