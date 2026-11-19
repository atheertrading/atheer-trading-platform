import SwiftUI

struct SettingsHomeView: View {
    @ObservedObject var backendHealthModel: BackendHealthViewModel
    @ObservedObject var marketDataStatusModel: CommandCenterStatusViewModel

    let onOpenBrokers: () -> Void
    let onOpenAPIConnection: () -> Void

    @AppStorage(ATHEERAppearance.storageKey)
    private var appearancePreference = ATHEERAppearance.dark.rawValue

    private var selectedAppearance: ATHEERAppearance {
        ATHEERAppearance.resolve(appearancePreference)
    }

    private var presentation: SystemAdministrationPresentation {
        SystemAdministrationPresentation(
            marketDataState: marketDataStatusModel.marketDataState,
            backendHealthState: backendHealthModel.state
        )
    }

    private var isRefreshing: Bool {
        backendHealthModel.isRefreshing || marketDataStatusModel.marketDataState == .checking
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 330, maximum: 620), spacing: 14)],
                    alignment: .leading,
                    spacing: 14
                ) {
                    applicationPreferencesPanel
                    brokerAndEnvironmentPanel
                    systemHealthPanel
                    securityAndAuditPanel
                }
            }
            .padding(24)
            .frame(maxWidth: 1_320, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(ATHEERDesignTokens.ColorRole.canvas)
        .task {
            await refreshStatuses()
        }
        .accessibilityIdentifier("screen.system-administration")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("System & Administration")
                    .font(ATHEERDesignTokens.Typography.screenTitle)
                    .foregroundColor(ATHEERDesignTokens.ColorRole.primaryText)

                Text("Application configuration, broker connectivity, runtime diagnostics and security posture.")
                    .font(ATHEERDesignTokens.Typography.body)
                    .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                Label("READ ONLY", systemImage: "lock.fill")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(ATHEERDesignTokens.ColorRole.panelElevated)
                    .clipShape(Capsule())

                Button {
                    Task { await refreshStatuses() }
                } label: {
                    if isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                        Text("Refreshing")
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isRefreshing)
                .accessibilityIdentifier("system-administration.refresh")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var applicationPreferencesPanel: some View {
        AdministrationPanel(
            title: "Application Preferences",
            subtitle: "Appearance, locale, density and accessibility",
            symbol: "slider.horizontal.3"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("APPEARANCE")
                        .font(ATHEERDesignTokens.Typography.caption)
                        .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)

                    Picker("Application appearance", selection: $appearancePreference) {
                        ForEach(ATHEERAppearance.allCases) { appearance in
                            Text(appearance.title).tag(appearance.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Application appearance")
                    .accessibilityValue(selectedAppearance.title)
                    .accessibilityIdentifier("system-administration.appearance")
                }

                AdministrationFactRow(
                    title: "Locale and direction",
                    value: "English · LTR",
                    detail: "Arabic localization and full right-to-left behavior are pending."
                )

                AdministrationFactRow(
                    title: "Information density",
                    value: "Adaptive layout",
                    detail: "Compact, balanced and spacious user profiles are not yet exposed."
                )

                AdministrationFactRow(
                    title: "Accessibility",
                    value: "Qualification pending",
                    detail: "Keyboard traversal, focus order and VoiceOver behavior require screen-level verification."
                )
            }
        }
    }

    private var brokerAndEnvironmentPanel: some View {
        AdministrationPanel(
            title: "Broker & Environments",
            subtitle: "Provider and session state from existing backend contracts",
            symbol: "building.columns"
        ) {
            VStack(alignment: .leading, spacing: 13) {
                AdministrationStatusRow(
                    title: "Broker readiness",
                    value: presentation.broker.value,
                    detail: presentation.broker.detail,
                    tint: tint(for: presentation.broker.tone)
                )

                Divider().overlay(ATHEERDesignTokens.ColorRole.separator)

                AdministrationStatusRow(
                    title: "Market data REST session",
                    value: presentation.marketData.value,
                    detail: presentation.marketData.detail,
                    tint: tint(for: presentation.marketData.tone)
                )

                HStack(spacing: 14) {
                    AdministrationFactRow(
                        title: "Provider",
                        value: presentation.provider,
                        detail: "Backend-reported market-data provider."
                    )
                    AdministrationFactRow(
                        title: "Environment",
                        value: presentation.environment,
                        detail: "Backend-reported market-data environment."
                    )
                }

                AdministrationFactRow(
                    title: "Account snapshot",
                    value: presentation.account.value,
                    detail: presentation.account.detail
                )

                Button(action: onOpenBrokers) {
                    Label("Manage broker configuration", systemImage: "key.horizontal")
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("system-administration.open-brokers")
            }
        }
    }

    private var systemHealthPanel: some View {
        AdministrationPanel(
            title: "System Health",
            subtitle: "Readiness, diagnostics and runtime configuration",
            symbol: "waveform.path.ecg"
        ) {
            VStack(alignment: .leading, spacing: 13) {
                AdministrationOperationalRow(title: "Local API", status: presentation.localAPI)
                Divider().overlay(ATHEERDesignTokens.ColorRole.separator)
                AdministrationOperationalRow(title: "Platform readiness", status: presentation.platform)
                Divider().overlay(ATHEERDesignTokens.ColorRole.separator)
                AdministrationOperationalRow(title: "Trading gate", status: presentation.tradingGate)

                AdministrationFactRow(
                    title: "Backend version",
                    value: presentation.backendVersion,
                    detail: "Reported by the existing liveness contract when available."
                )

                Button(action: onOpenAPIConnection) {
                    Label("Open API diagnostics", systemImage: "network")
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("system-administration.open-api-diagnostics")
            }
        }
    }

    private var securityAndAuditPanel: some View {
        AdministrationPanel(
            title: "Security & Audit",
            subtitle: "Credential handling, permissions and traceable events",
            symbol: "lock.shield"
        ) {
            VStack(alignment: .leading, spacing: 13) {
                AdministrationFactRow(
                    title: "Credential storage",
                    value: "Existing Keychain-backed client",
                    detail: "The current native broker settings flow uses macOS Keychain."
                )

                AdministrationFactRow(
                    title: "Broker session authority",
                    value: "Integration gate pending",
                    detail: "The single backend-owned credential and broker-session authority remains an unresolved integration requirement."
                )

                AdministrationFactRow(
                    title: "Secret presentation",
                    value: "Masked",
                    detail: "This screen does not display credential values."
                )

                AdministrationFactRow(
                    title: "Audit events",
                    value: "NOT AVAILABLE",
                    detail: "No backend audit-read contract is exposed to this screen."
                )

                AdministrationFactRow(
                    title: "Permission administration",
                    value: "NOT EXPOSED",
                    detail: "No permission-changing controls are provided by the current UI contract."
                )

                Label(
                    "No broker-dealing or risk-policy controls are available from this screen.",
                    systemImage: "checkmark.shield"
                )
                .font(ATHEERDesignTokens.Typography.caption)
                .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @MainActor
    private func refreshStatuses() async {
        await backendHealthModel.refresh()
        await marketDataStatusModel.refresh()
    }

    private func tint(for tone: CommandCenterStatusTone) -> Color {
        switch tone {
        case .neutral:
            return ATHEERDesignTokens.ColorRole.neutral
        case .positive:
            return ATHEERDesignTokens.ColorRole.success
        case .attention:
            return ATHEERDesignTokens.ColorRole.attention
        case .danger:
            return ATHEERDesignTokens.ColorRole.danger
        }
    }
}

private struct AdministrationPanel<Content: View>: View {
    let title: String
    let subtitle: String
    let symbol: String
    private let content: Content

    init(
        title: String,
        subtitle: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
                    .frame(width: 30, height: 30)
                    .background(ATHEERDesignTokens.ColorRole.accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(ATHEERDesignTokens.Typography.panelTitle)
                        .foregroundColor(ATHEERDesignTokens.ColorRole.primaryText)

                    Text(subtitle)
                        .font(ATHEERDesignTokens.Typography.caption)
                        .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)
            }

            Divider().overlay(ATHEERDesignTokens.ColorRole.separator)

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 260, alignment: .topLeading)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .overlay(
            RoundedRectangle(cornerRadius: ATHEERDesignTokens.Radius.large, style: .continuous)
                .stroke(ATHEERDesignTokens.ColorRole.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ATHEERDesignTokens.Radius.large, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

private struct AdministrationFactRow: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(ATHEERDesignTokens.Typography.caption)
                    .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)

                Spacer(minLength: 8)

                Text(value)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(ATHEERDesignTokens.ColorRole.primaryText)
                    .multilineTextAlignment(.trailing)
                    .textSelection(.enabled)
            }

            Text(detail)
                .font(.system(size: 10))
                .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct AdministrationStatusRow: View {
    let title: String
    let value: String
    let detail: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(ATHEERDesignTokens.Typography.caption)
                    .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)

                Spacer(minLength: 8)

                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(tint)
                    .multilineTextAlignment(.trailing)
                    .accessibilityLabel("\(title): \(value)")
            }

            Text(detail)
                .font(.system(size: 10))
                .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct AdministrationOperationalRow: View {
    let title: String
    let status: OperationalStatusValue

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: status.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(status.tint)
                .frame(width: 18)
                .accessibilityHidden(true)

            Text(title)
                .font(ATHEERDesignTokens.Typography.caption)
                .foregroundColor(ATHEERDesignTokens.ColorRole.secondaryText)

            Spacer(minLength: 8)

            Text(status.title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(status.tint)
                .accessibilityLabel("\(title): \(status.title)")
        }
        .accessibilityElement(children: .combine)
    }
}
