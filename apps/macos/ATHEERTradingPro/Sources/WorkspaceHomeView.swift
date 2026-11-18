import SwiftUI

struct WorkspaceHomeView: View {
    @ObservedObject var backendHealthModel: BackendHealthViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Workspace")
                        .font(.system(size: 25, weight: .semibold))
                    Text("Application overview")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                BackendStatusPanel(model: backendHealthModel, accent: Color(red: 0.0, green: 206.0 / 255.0, blue: 200.0 / 255.0))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Available capability")
                        .font(.system(size: 14, weight: .semibold))
                    Label("Local API health diagnostics", systemImage: "checkmark.circle")
                        .font(.system(size: 13))
                    Text("Broker connectivity, market data, portfolio, risk, strategies, and order execution are not implemented in this application build.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.035))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(24)
            .frame(maxWidth: 900, alignment: .leading)
        }
    }
}
