import SwiftUI

/// A labelled preference row using the native macOS switch control.
/// State ownership and persistence remain with the caller/ViewModel.
struct ATHEERToggleRow: View {
    let title: String
    let detail: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(ATHEERDesignTokens.Typography.controlLabel)
                    .foregroundColor(ATHEERDesignTokens.ColorRole.primaryText)
                if let detail = detail, !detail.isEmpty {
                    Text(detail)
                        .font(ATHEERDesignTokens.Typography.caption)
                        .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: ATHEERDesignTokens.ColorRole.accent))
        .accessibilityValue(Text(isOn ? "On" : "Off"))
    }
}
