import SwiftUI

/// Persistent, read-only operational context for the native workstation shell.
/// It reports only states supplied by the backend health model and never infers broker readiness.
struct OperationalStatusStrip: View {
    @ObservedObject var model: BackendHealthViewModel

    private var apiStatus: (title: String, symbol: String, tint: Color) {
        switch model.state {
        case .idle:
            return ("NOT CHECKED", "questionmark.circle", .secondary)
        case .checking:
            return ("CHECKING", "arrow.triangle.2.circlepath", ATHEERDesignTokens.ColorRole.attention)
        case .disconnected:
            return ("UNREACHABLE", "xmark.circle", ATHEERDesignTokens.ColorRole.danger)
        case .invalidResponse:
            return ("INVALID RESPONSE", "exclamationmark.triangle", ATHEERDesignTokens.ColorRole.attention)
        case .serverError(let statusCode):
            return ("HTTP \(statusCode)", "exclamationmark.triangle", ATHEERDesignTokens.ColorRole.attention)
        case .connected:
            return ("REACHABLE", "checkmark.circle", ATHEERDesignTokens.ColorRole.success)
        }
    }

    private var platformStatus: (title: String, symbol: String, tint: Color) {
        guard case .connected(let snapshot) = model.state else {
            return ("NOT VERIFIED", "questionmark.circle", .secondary)
        }

        if snapshot.readinessFailure != nil {
            return ("UNAVAILABLE", "exclamationmark.triangle", ATHEERDesignTokens.ColorRole.attention)
        }

        guard let ready = snapshot.platformReady else {
            return ("UNKNOWN", "questionmark.circle", .secondary)
        }

        return ready
            ? ("READY", "checkmark.circle", ATHEERDesignTokens.ColorRole.success)
            : ("NOT READY", "exclamationmark.triangle", ATHEERDesignTokens.ColorRole.attention)
    }

    private var tradingStatus: (title: String, symbol: String, tint: Color) {
        guard case .connected(let snapshot) = model.state,
              let enabled = snapshot.tradingEnabled else {
            return ("NOT VERIFIED", "questionmark.circle", .secondary)
        }

        return enabled
            ? ("ENABLED", "exclamationmark.triangle", ATHEERDesignTokens.ColorRole.attention)
            : ("DISABLED", "lock.circle", ATHEERDesignTokens.ColorRole.success)
    }

    var body: some View {
        HStack(spacing: 18) {
            statusItem(title: "LOCAL API", status: apiStatus)
            Divider()
                .frame(height: 20)
            statusItem(title: "PLATFORM", status: platformStatus)
            Divider()
                .frame(height: 20)
            statusItem(title: "TRADING GATE", status: tradingStatus)

            Spacer(minLength: 8)

            Text("STATUS FROM BACKEND HEALTH")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(0.5)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .accessibilityElement(children: .contain)
    }

    private func statusItem(
        title: String,
        status: (title: String, symbol: String, tint: Color)
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
    }
}
