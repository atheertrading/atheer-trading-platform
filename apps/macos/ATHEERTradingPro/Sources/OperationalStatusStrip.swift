import SwiftUI

enum OperationalStatusTone: Equatable {
    case neutral
    case positive
    case attention
    case danger
}

struct OperationalStatusValue: Equatable {
    let title: String
    let symbol: String
    let tone: OperationalStatusTone

    var tint: Color {
        switch tone {
        case .neutral:
            return .secondary
        case .positive:
            return ATHEERDesignTokens.ColorRole.success
        case .attention:
            return ATHEERDesignTokens.ColorRole.attention
        case .danger:
            return ATHEERDesignTokens.ColorRole.danger
        }
    }
}

/// Pure presentation mapping for backend liveness, readiness, and trading-gate state.
/// The UI never infers platform readiness or execution permission from API liveness alone.
struct OperationalStatusPresentation: Equatable {
    let localAPI: OperationalStatusValue
    let platform: OperationalStatusValue
    let tradingGate: OperationalStatusValue

    init(state: BackendHealthViewState) {
        switch state {
        case .idle:
            localAPI = Self.value("NOT CHECKED", "questionmark.circle", .neutral)
            platform = Self.value("NOT VERIFIED", "questionmark.circle", .neutral)
            tradingGate = Self.value("NOT VERIFIED", "questionmark.circle", .neutral)

        case .checking:
            localAPI = Self.value("CHECKING", "arrow.triangle.2.circlepath", .attention)
            platform = Self.value("NOT VERIFIED", "questionmark.circle", .neutral)
            tradingGate = Self.value("NOT VERIFIED", "questionmark.circle", .neutral)

        case .disconnected:
            localAPI = Self.value("UNREACHABLE", "xmark.circle", .danger)
            platform = Self.value("NOT VERIFIED", "questionmark.circle", .neutral)
            tradingGate = Self.value("NOT VERIFIED", "questionmark.circle", .neutral)

        case .invalidResponse:
            localAPI = Self.value("INVALID RESPONSE", "exclamationmark.triangle", .attention)
            platform = Self.value("NOT VERIFIED", "questionmark.circle", .neutral)
            tradingGate = Self.value("NOT VERIFIED", "questionmark.circle", .neutral)

        case .serverError(let statusCode):
            localAPI = Self.value("HTTP \(statusCode)", "exclamationmark.triangle", .attention)
            platform = Self.value("NOT VERIFIED", "questionmark.circle", .neutral)
            tradingGate = Self.value("NOT VERIFIED", "questionmark.circle", .neutral)

        case .connected(let snapshot):
            localAPI = Self.value("REACHABLE", "checkmark.circle", .positive)

            if snapshot.readinessFailure != nil {
                platform = Self.value("UNAVAILABLE", "exclamationmark.triangle", .attention)
            } else if let ready = snapshot.platformReady {
                platform = ready
                    ? Self.value("READY", "checkmark.circle", .positive)
                    : Self.value("NOT READY", "exclamationmark.triangle", .attention)
            } else {
                platform = Self.value("UNKNOWN", "questionmark.circle", .neutral)
            }

            guard snapshot.readinessFailure == nil,
                  let enabled = snapshot.tradingEnabled else {
                tradingGate = Self.value("NOT VERIFIED", "questionmark.circle", .neutral)
                break
            }

            // A backend snapshot that advertises trading while the platform is not
            // ready is surfaced as unverified rather than as an enabled permission.
            if enabled && snapshot.platformReady != true {
                tradingGate = Self.value("NOT VERIFIED", "exclamationmark.triangle", .attention)
            } else if enabled {
                tradingGate = Self.value("ENABLED", "exclamationmark.triangle", .attention)
            } else {
                tradingGate = Self.value("DISABLED", "lock.circle", .neutral)
            }
        }
    }

    private static func value(
        _ title: String,
        _ symbol: String,
        _ tone: OperationalStatusTone
    ) -> OperationalStatusValue {
        OperationalStatusValue(title: title, symbol: symbol, tone: tone)
    }
}

/// Persistent, read-only operational context for the native workstation shell.
/// It reports only states supplied by the backend health model and never infers broker readiness.
struct OperationalStatusStrip: View {
    @ObservedObject var model: BackendHealthViewModel

    private var presentation: OperationalStatusPresentation {
        OperationalStatusPresentation(state: model.state)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            expandedLayout
            compactLayout
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .accessibilityElement(children: .contain)
    }

    private var expandedLayout: some View {
        HStack(spacing: 18) {
            statusItem(
                title: "LOCAL API",
                status: presentation.localAPI,
                identifier: "status.local-api"
            )
            Divider()
                .frame(height: 20)
            statusItem(
                title: "PLATFORM",
                status: presentation.platform,
                identifier: "status.platform-readiness"
            )
            Divider()
                .frame(height: 20)
            statusItem(
                title: "TRADING GATE",
                status: presentation.tradingGate,
                identifier: "status.trading-gate"
            )

            Spacer(minLength: 8)
            sourceLabel
        }
    }

    /// Two-row fallback keeps the three critical states legible at narrower window widths.
    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 18) {
                statusItem(
                    title: "LOCAL API",
                    status: presentation.localAPI,
                    identifier: "status.local-api"
                )
                statusItem(
                    title: "PLATFORM",
                    status: presentation.platform,
                    identifier: "status.platform-readiness"
                )
            }

            HStack {
                statusItem(
                    title: "TRADING GATE",
                    status: presentation.tradingGate,
                    identifier: "status.trading-gate"
                )
                Spacer(minLength: 8)
                sourceLabel
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sourceLabel: some View {
        Text("STATUS FROM BACKEND HEALTH")
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .tracking(0.5)
            .foregroundColor(.secondary)
            .lineLimit(1)
            .accessibilityLabel("Operational states are derived from backend health")
    }

    private func statusItem(
        title: String,
        status: OperationalStatusValue,
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.7)
                .foregroundColor(.secondary)

            Label(status.title, systemImage: status.symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(status.tint)
                .lineLimit(1)
                .textSelection(.enabled)
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}
