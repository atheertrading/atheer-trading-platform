import SwiftUI

struct BackendStatusPanel: View {
    @ObservedObject var model: BackendHealthViewModel
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PLATFORM HEALTH")
                    .font(ATHEERDesignTokens.Typography.caption)
                    .tracking(1.1)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    Task { await model.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(ATHEERDesignTokens.Typography.caption)
                }
                .buttonStyle(.borderless)
                .disabled(model.isRefreshing)
            }

            Divider()

            switch model.state {
            case .idle:
                statusRow("API", value: "Not checked", color: .secondary)
            case .checking:
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Checking…")
                        .font(ATHEERDesignTokens.Typography.body)
                        .foregroundColor(.secondary)
                }
            case .disconnected(let message):
                statusRow("API", value: "Disconnected", color: ATHEERDesignTokens.ColorRole.danger)
                diagnostic(message)
            case .invalidResponse(let message):
                statusRow("API", value: "Invalid liveness response", color: ATHEERDesignTokens.ColorRole.attention)
                diagnostic(message)
            case .serverError(let statusCode):
                statusRow("API", value: "HTTP \(statusCode)", color: ATHEERDesignTokens.ColorRole.attention)
            case .connected(let snapshot):
                statusRow("API", value: "Connected", color: accent)
                if let failure = snapshot.readinessFailure {
                    statusRow("Platform readiness", value: "Unavailable", color: ATHEERDesignTokens.ColorRole.attention)
                    diagnostic(failure.message)
                } else {
                    if let platformReady = snapshot.platformReady {
                        statusRow("Platform readiness", value: platformReady ? "Ready" : "Not ready", color: .secondary)
                    }
                    if let persistence = snapshot.persistenceStatus {
                        statusRow("Persistence", value: display(persistence), color: .secondary)
                    }
                    if let broker = snapshot.brokerStatus {
                        statusRow("Broker", value: display(broker), color: .secondary)
                    }
                    if let tradingEnabled = snapshot.tradingEnabled {
                        statusRow("Trading", value: tradingEnabled ? "Enabled" : "Disabled", color: tradingEnabled ? ATHEERDesignTokens.ColorRole.attention : .secondary)
                    }
                }
                Text("API version \(snapshot.version) · \(snapshot.livenessTimestamp)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(ATHEERDesignTokens.ColorRole.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func statusRow(_ title: String, value: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(ATHEERDesignTokens.Typography.body)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
                .textSelection(.enabled)
        }
    }

    private func diagnostic(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .textSelection(.enabled)
    }

    private func display(_ value: String) -> String {
        value.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
