import SwiftUI

/// Compatibility entry point retained for the existing application navigation.
/// The primary workspace is implemented by CommandCenterView.
@MainActor
struct WorkspaceHomeView: View {
    @ObservedObject var backendHealthModel: BackendHealthViewModel
    let marketHistoryClient: MarketHistoryClient?
    let marketDataStreamModel: MarketDataStreamViewModel?
    let selectedChartInstrumentId: String?
    let onOpenAPIConnection: () -> Void
    let onOpenMarkets: () -> Void

    init(
        backendHealthModel: BackendHealthViewModel,
        marketHistoryClient: MarketHistoryClient? = nil,
        marketDataStreamModel: MarketDataStreamViewModel? = nil,
        selectedChartInstrumentId: String? = nil,
        onOpenAPIConnection: @escaping () -> Void,
        onOpenMarkets: @escaping () -> Void = {}
    ) {
        _backendHealthModel = ObservedObject(wrappedValue: backendHealthModel)
        self.marketHistoryClient = marketHistoryClient
        self.marketDataStreamModel = marketDataStreamModel
        self.selectedChartInstrumentId = selectedChartInstrumentId
        self.onOpenAPIConnection = onOpenAPIConnection
        self.onOpenMarkets = onOpenMarkets
    }

    var body: some View {
        CommandCenterView(
            backendHealthModel: backendHealthModel,
            marketHistoryClient: marketHistoryClient,
            marketDataStreamModel: marketDataStreamModel,
            selectedChartInstrumentId: selectedChartInstrumentId,
            onOpenAPIConnection: onOpenAPIConnection,
            onOpenMarkets: onOpenMarkets
        )
    }
}
