import SwiftUI

struct APIConnectionView: View {
    @ObservedObject var model: BackendHealthViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("API Connection")
                            .font(.system(size: 25, weight: .semibold))
                        Text("Local middleware diagnostics")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        Task { await model.refresh() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(model.isRefreshing)
                    .keyboardShortcut("r", modifiers: [.command])
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("SERVICE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.1)
                        .foregroundColor(.secondary)
                    CopyableValueRow(title: "Base URL", value: URLSessionBackendHealthClient.baseURLString)
                    Divider()
                    healthDetails
                }
                .padding(16)
                .background(Color.white.opacity(0.035))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text("This interface performs read-only health requests. It does not start or stop the API process, authenticate a broker, submit orders, or change trading permissions.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .frame(maxWidth: 900, alignment: .leading)
        }
    }

    @ViewBuilder
    private var healthDetails: some View {
        switch model.state {
        case .idle:
            Label("Not checked", systemImage: "questionmark.circle")
                .foregroundColor(.secondary)
        case .checking:
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text("Checking local API…")
                    .foregroundColor(.secondary)
            }
        case .disconnected(let message):
            statusLine("Process liveness", value: "Unreachable", symbol: "xmark.circle", color: .red)
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .textSelection(.enabled)
        case .invalidResponse(let message):
            statusLine("Process liveness", value: "Response received", symbol: "exclamationmark.triangle", color: .orange)
            statusLine("Liveness contract", value: "Invalid response", symbol: "exclamationmark.triangle", color: .orange)
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .textSelection(.enabled)
        case .serverError(let statusCode):
            statusLine("Process liveness", value: "Response received", symbol: "exclamationmark.triangle", color: .orange)
            statusLine("Liveness endpoint", value: "HTTP \(statusCode)", symbol: "exclamationmark.triangle", color: .orange)
        case .connected(let snapshot):
            statusLine("Process liveness", value: "Alive · HTTP 200", symbol: "checkmark.circle", color: .green)
            if let failure = snapshot.readinessFailure {
                statusLine("Platform readiness", value: "Unavailable", symbol: "exclamationmark.triangle", color: .orange)
                Text(failure.message)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            } else {
                if let platformReady = snapshot.platformReady {
                    statusLine(
                        "Platform readiness",
                        value: platformReady ? "Ready" : "Not ready",
                        symbol: platformReady ? "checkmark.circle" : "exclamationmark.circle",
                        color: platformReady ? .green : .orange
                    )
                }
                if let statusCode = snapshot.readinessHTTPStatus {
                    statusLine("Readiness response", value: "HTTP \(statusCode)", symbol: "network", color: .secondary)
                }
                if let persistence = snapshot.persistenceStatus {
                    statusLine("Persistence", value: display(persistence), symbol: "externaldrive", color: .secondary)
                }
                if let broker = snapshot.brokerStatus {
                    statusLine("Broker", value: display(broker), symbol: "building.columns", color: .secondary)
                }
                if let tradingEnabled = snapshot.tradingEnabled {
                    statusLine("Trading", value: tradingEnabled ? "Enabled" : "Disabled", symbol: "lock", color: tradingEnabled ? .orange : .secondary)
                }
            }
            Divider()
            CopyableValueRow(title: "API version", value: snapshot.version)
            CopyableValueRow(title: "Liveness timestamp", value: snapshot.livenessTimestamp)
            if let readinessTimestamp = snapshot.readinessTimestamp {
                CopyableValueRow(title: "Readiness timestamp", value: readinessTimestamp)
            }
        }
    }

    private func statusLine(_ title: String, value: String, symbol: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Spacer(minLength: 12)
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
