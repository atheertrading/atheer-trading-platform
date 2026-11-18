import SwiftUI

/// Compatibility entry point retained for the existing application navigation.
/// The primary workspace is implemented by CommandCenterView.
struct WorkspaceHomeView: View {
    @ObservedObject var backendHealthModel: BackendHealthViewModel
    @ObservedObject var marketExplorerModel: MarketExplorerViewModel
    @ObservedObject var marketWatchlistStore: MarketWatchlistStore
    let onOpenMarkets: () -> Void
    let onOpenAPIConnection: () -> Void

    var body: some View {
        CommandCenterView(
            backendHealthModel: backendHealthModel,
            marketExplorerModel: marketExplorerModel,
            marketWatchlistStore: marketWatchlistStore,
            onOpenMarkets: onOpenMarkets,
            onOpenAPIConnection: onOpenAPIConnection
        )
    }
}
