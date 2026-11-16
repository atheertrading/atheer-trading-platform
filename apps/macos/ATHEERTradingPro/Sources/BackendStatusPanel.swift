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
                statusRow("API", value: "Checking…", color: .secondary)
            case .disconnected:
                statusRow("API", value: "Disconnected", color: .secondary)
                Text("Start the local service from services/api to connect this workspace.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            case .connected(let snapshot):
                statusRow("API", value: "Connected", color: accent)
                statusRow("Platform readiness", value: snapshot.platformReady ? "Ready" : "Not ready", color: .secondary)
                statusRow("Persistence", value: display(snapshot.persistenceStatus), color: .secondary)
                statusRow("Broker", value: display(snapshot.brokerStatus), color: .secondary)
                statusRow("Trading", value: snapshot.tradingEnabled ? "Enabled" : "Disabled", color: .secondary)
                Text("API version \(snapshot.version) · \(snapshot.lastCheckedAt)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
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
        }
    }

    private func display(_ value: String) -> String {
        value.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
