import SwiftUI

/// Compatibility entry point retained for the existing application navigation.
/// The primary workspace is implemented by CommandCenterView.
@MainActor
struct WorkspaceHomeView: View {
    @ObservedObject var backendHealthModel: BackendHealthViewModel
    let marketHistoryClient: MarketHistoryClient? = nil
    let selectedChartInstrumentId: String? = nil
    let onOpenAPIConnection: () -> Void
    let onOpenMarkets: () -> Void = {}

    var body: some View {
        CommandCenterView(
            backendHealthModel: backendHealthModel,
            marketHistoryClient: marketHistoryClient,
            selectedChartInstrumentId: selectedChartInstrumentId,
            onOpenAPIConnection: onOpenAPIConnection,
            onOpenMarkets: onOpenMarkets
        )
    }
}
