import SwiftUI

struct SettingsHomeView: View {
    let onOpenBrokers: () -> Void

    @AppStorage(ATHEERAppearance.storageKey)
    private var appearancePreference = ATHEERAppearance.dark.rawValue

    private var selectedAppearance: ATHEERAppearance {
        ATHEERAppearance.resolve(appearancePreference)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(ATHEERDesignTokens.Typography.screenTitle)

            appearanceSection

            Button(action: onOpenBrokers) {
                HStack(spacing: 12) {
                    Image(systemName: "building.columns")
                        .font(.system(size: 18))
                        .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
                        .frame(width: 34)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Brokers")
                            .font(.system(size: 13, weight: .semibold))
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
                .clipShape(RoundedRectangle(cornerRadius: ATHEERDesignTokens.Radius.standard))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Brokers, manage broker integrations and credentials")

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: 800, alignment: .leading)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Appearance")
                    .font(ATHEERDesignTokens.Typography.panelTitle)
                Text("Dark is the default. Your selection is saved automatically.")
                    .font(ATHEERDesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
            }

            Picker(
                "Application appearance",
                selection: $appearancePreference
            ) {
                ForEach(ATHEERAppearance.allCases) { appearance in
                    Text(appearance.title)
                        .tag(appearance.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Application appearance")
            .accessibilityValue(selectedAppearance.title)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .clipShape(RoundedRectangle(cornerRadius: ATHEERDesignTokens.Radius.standard))
    }
}
