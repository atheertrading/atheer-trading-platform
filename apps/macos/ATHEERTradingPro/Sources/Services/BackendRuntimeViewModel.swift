import Combine
import Foundation

enum BackendRuntimeViewState: Equatable {
    case stopped
    case starting
    case ready
    case failed(String)

    var message: String {
        switch self {
        case .stopped:
            return "The local backend has not been started."
        case .starting:
            return "Starting the authenticated local backend."
        case .ready:
            return "The local backend process and authenticated IPC channel are ready."
        case .failed(let reason):
            return reason
        }
    }
}

@MainActor
final class BackendRuntimeViewModel: ObservableObject {
    @Published private(set) var state: BackendRuntimeViewState = .stopped
    @Published private(set) var marketSearchClient: MarketSearchClient?
    @Published private(set) var marketDataStreamClient: MarketDataStreamClient?
    @Published private(set) var marketDataStreamModel: MarketDataStreamViewModel?
    @Published private(set) var marketHistoryClient: MarketHistoryClient?

    let healthModel: BackendHealthViewModel
    let brokerManagementModel: BrokerManagementViewModel
    private let marketWatchlistPersistence: MarketWatchlistPersistence
    private var supervisor: BackendProcessManaging

    init(
        supervisor: BackendProcessManaging? = nil,
        healthModel: BackendHealthViewModel = BackendHealthViewModel(),
        brokerManagementModel: BrokerManagementViewModel? = nil,
        marketWatchlistPersistence: MarketWatchlistPersistence = UserDefaultsMarketWatchlistPersistence()
    ) {
        self.supervisor = supervisor ?? BackendProcessSupervisor()
        self.healthModel = healthModel
        self.brokerManagementModel = brokerManagementModel ?? BrokerManagementViewModel()
        self.marketWatchlistPersistence = marketWatchlistPersistence
        self.supervisor.onUnexpectedTermination = { [weak self] message in
            self?.marketDataStreamModel?.stopMonitoring(clearQuotes: true)
            self?.marketDataStreamModel = nil
            self?.marketSearchClient = nil
            self?.marketDataStreamClient = nil
            self?.marketHistoryClient = nil
            self?.healthModel.setUnavailable(message)
            self?.brokerManagementModel.backendUnavailable(message)
            self?.state = .failed(message)
        }
    }

    func start() async {
        guard state != .starting, state != .ready else { return }
        state = .starting
        do {
            let connection = try await supervisor.start()
            healthModel.configure(
                client: URLSessionBackendHealthClient(baseURL: connection.baseURL)
            )
            brokerManagementModel.configure(
                authentication: BackendBrokerAuthenticationService(connection: connection)
            )
            marketSearchClient = URLSessionMarketSearchClient(connection: connection)
            let streamClient = URLSessionMarketDataStreamClient(connection: connection)
            marketDataStreamClient = streamClient
            marketDataStreamModel = MarketDataStreamViewModel(
                client: streamClient,
                persistence: marketWatchlistPersistence
            )
            marketHistoryClient = URLSessionMarketHistoryClient(connection: connection)
            await healthModel.refresh()
            state = .ready
        } catch {
            try? await supervisor.stop()
            marketDataStreamModel?.stopMonitoring(clearQuotes: true)
            marketDataStreamModel = nil
            marketSearchClient = nil
            marketDataStreamClient = nil
            marketHistoryClient = nil
            healthModel.setUnavailable(error.localizedDescription)
            brokerManagementModel.backendUnavailable(error.localizedDescription)
            state = .failed(error.localizedDescription)
        }
    }

    func stop() async throws {
        marketDataStreamModel?.stopMonitoring(clearQuotes: true)
        marketDataStreamModel = nil
        marketSearchClient = nil
        marketDataStreamClient = nil
        marketHistoryClient = nil
        healthModel.setUnavailable("Stopping the managed backend process.")
        do {
            try await supervisor.stop()
            let message = "The managed backend process has stopped."
            healthModel.setUnavailable(message)
            brokerManagementModel.backendUnavailable(message)
            state = .stopped
        } catch {
            let message = "The managed backend could not be confirmed stopped: \(error.localizedDescription)"
            healthModel.setUnavailable(message)
            brokerManagementModel.backendUnavailable(message)
            state = .failed(message)
            throw error
        }
    }
}
