import Foundation

/// Source-grounded presentation state for the System & Administration screen.
/// This type projects existing backend contracts and never invents missing state.
struct SystemAdministrationPresentation: Equatable {
    let marketData: CommandCenterStatusCard
    let broker: CommandCenterStatusCard
    let account: CommandCenterStatusCard
    let localAPI: OperationalStatusValue
    let platform: OperationalStatusValue
    let tradingGate: OperationalStatusValue
    let provider: String
    let environment: String
    let backendVersion: String

    init(
        marketDataState: CommandCenterMarketDataState,
        backendHealthState: BackendHealthViewState
    ) {
        let commandCenter = CommandCenterStatusPresentation(
            marketDataState: marketDataState,
            backendHealthState: backendHealthState
        )
        let operational = OperationalStatusPresentation(state: backendHealthState)

        marketData = commandCenter.marketData
        broker = commandCenter.broker
        account = commandCenter.account
        localAPI = operational.localAPI
        platform = operational.platform
        tradingGate = operational.tradingGate

        switch marketDataState {
        case .available(let status):
            provider = status.provider
            environment = status.environment
        case .notChecked, .checking, .unavailable:
            provider = "NOT VERIFIED"
            environment = "NOT VERIFIED"
        }

        if case .connected(let snapshot) = backendHealthState {
            backendVersion = snapshot.version
        } else {
            backendVersion = "NOT VERIFIED"
        }
    }
}
