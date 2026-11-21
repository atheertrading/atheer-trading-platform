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

/// Semantic wrapper that retains native macOS Button activation, keyboard, and focus behavior.
/// Prefer native toolbar items and system styles for commands placed in the window toolbar.
struct ATHEERButton<Label: View>: View {
    let variant: ATHEERButtonVariant
    let size: ATHEERButtonSize
    let isEnabled: Bool
    let isLoading: Bool
    private let action: () -> Void
    private let label: Label

    init(
        variant: ATHEERButtonVariant = .secondary,
        size: ATHEERButtonSize = .regular,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.variant = variant
        self.size = size
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
        self.label = label()
    }

    private var buttonContent: some View {
        HStack(spacing: ATHEERDesignTokens.Spacing.small) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel(Text("Loading"))
            }
            label
        }
    }

    @ViewBuilder
    var body: some View {
        switch variant {
        case .primary:
            Button(action: action, label: { buttonContent })
                .buttonStyle(.borderedProminent)
                .tint(ATHEERDesignTokens.ColorRole.accent)
                .foregroundColor(ATHEERDesignTokens.ColorRole.onAccent)
                .controlSize(size.controlSize)
                .frame(minHeight: size.minimumHeight)
                .disabled(!isEnabled || isLoading)
        case .secondary:
            Button(action: action, label: { buttonContent })
                .buttonStyle(.bordered)
                .controlSize(size.controlSize)
                .frame(minHeight: size.minimumHeight)
                .disabled(!isEnabled || isLoading)
        case .tertiary:
            Button(action: action, label: { buttonContent })
                .buttonStyle(.plain)
                .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
                .controlSize(size.controlSize)
                .frame(minHeight: size.minimumHeight)
                .disabled(!isEnabled || isLoading)
        case .destructive:
            Button(role: .destructive, action: action, label: { buttonContent })
                .buttonStyle(.borderedProminent)
                .tint(ATHEERDesignTokens.ColorRole.danger)
                .foregroundColor(ATHEERDesignTokens.ColorRole.onDanger)
                .controlSize(size.controlSize)
                .frame(minHeight: size.minimumHeight)
                .disabled(!isEnabled || isLoading)
        }
    }
}
