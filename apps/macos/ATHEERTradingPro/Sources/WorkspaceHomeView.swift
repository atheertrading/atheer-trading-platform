import SwiftUI

/// Compatibility entry point for the implemented Command Center destination.
struct WorkspaceHomeView: View {
    @ObservedObject var backendHealthModel: BackendHealthViewModel
    let marketSearchClient: MarketSearchClient
    let onOpenAPIConnection: () -> Void

    var body: some View {
        CommandCenterView(
            backendHealthModel: backendHealthModel,
            marketSearchClient: marketSearchClient,
            onOpenAPIConnection: onOpenAPIConnection
        )
    }
}
