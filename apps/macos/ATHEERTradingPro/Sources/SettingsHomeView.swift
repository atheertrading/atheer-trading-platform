import SwiftUI

struct SettingsHomeView: View {
    let onOpenBrokers: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(ATHEERDesignTokens.Typography.screenTitle)
            Button(action: onOpenBrokers) {
                HStack(spacing: 12) {
                    Image(systemName: "building.columns")
                        .font(.system(size: 18))
                        .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
                        .frame(width: 34)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Brokers").font(.system(size: 13, weight: .semibold))
                        Text("Manage broker integrations and credentials")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .background(ATHEERDesignTokens.ColorRole.panel)
                .clipShape(RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Brokers, manage broker integrations and credentials")
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: 800, alignment: .leading)
    }
}
