import SwiftUI

struct BackendStatusPanel: View {
    @ObservedObject var model: BackendHealthViewModel
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("BACKEND STATUS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.1)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    Task { await model.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.system(size: 11, weight: .medium))
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
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            case .disconnected(let message):
                statusRow("API", value: "Disconnected", color: .red)
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            case .invalidResponse(let message):
                statusRow("API", value: "Invalid liveness response", color: .orange)
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            case .serverError(let statusCode):
                statusRow("API", value: "HTTP \(statusCode)", color: .orange)
            case .connected(let snapshot):
                statusRow("API", value: "Connected", color: accent)
                if let failure = snapshot.readinessFailure {
                    statusRow("Platform readiness", value: "Unavailable", color: .orange)
                    Text(failure.message)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
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
                        statusRow("Trading", value: tradingEnabled ? "Enabled" : "Disabled", color: .secondary)
                    }
                }
                Text("API version \(snapshot.version) · \(snapshot.livenessTimestamp)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.035))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func statusRow(_ title: String, value: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .textSelection(.enabled)
        }
    }

    private func display(_ value: String) -> String {
        value.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
