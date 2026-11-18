import SwiftUI

struct BackendRuntimeUnavailableView: View {
    let state: BackendRuntimeViewState
    let onRetry: () -> Void
    let onOpenAPIConnection: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Backend Runtime", systemImage: "server.rack")
                .font(ATHEERDesignTokens.Typography.screenTitle)

            HStack(spacing: 10) {
                Image(systemName: state == .starting ? "hourglass" : "exclamationmark.triangle")
                    .foregroundColor(ATHEERDesignTokens.ColorRole.attention)
                Text(state == .starting ? "Starting" : "Unavailable")
                    .font(ATHEERDesignTokens.Typography.panelTitle)
            }

            Text(state.message)
                .font(ATHEERDesignTokens.Typography.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button(action: onRetry) {
                    Label("Retry Backend", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .tint(ATHEERDesignTokens.ColorRole.teal)
                .disabled(state == .starting)

                Button(action: onOpenAPIConnection) {
                    Label("API Diagnostics", systemImage: "network")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(28)
        .frame(maxWidth: 720, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(ATHEERDesignTokens.ColorRole.canvas)
    }
}
