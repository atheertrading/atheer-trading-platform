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

    let healthModel: BackendHealthViewModel
    let brokerManagementModel: BrokerManagementViewModel
    private var supervisor: BackendProcessManaging

    init(
        supervisor: BackendProcessManaging? = nil,
        healthModel: BackendHealthViewModel = BackendHealthViewModel(),
        brokerManagementModel: BrokerManagementViewModel? = nil
    ) {
        self.supervisor = supervisor ?? BackendProcessSupervisor()
        self.healthModel = healthModel
        self.brokerManagementModel = brokerManagementModel ?? BrokerManagementViewModel()
        self.supervisor.onUnexpectedTermination = { [weak self] message in
            self?.marketSearchClient = nil
            self?.healthModel.setUnavailable(message)
            self?.brokerManagementModel.backendUnavailable(message)
            self?.state = .failed(message)
        }
    }

    func start() async {
        guard state != .starting else { return }
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
            await healthModel.refresh()
            state = .ready
        } catch {
            marketSearchClient = nil
            healthModel.setUnavailable(error.localizedDescription)
            brokerManagementModel.backendUnavailable(error.localizedDescription)
            state = .failed(error.localizedDescription)
        }
    }

    func stop() {
        supervisor.stop()
        marketSearchClient = nil
        healthModel.setUnavailable("The managed backend process has stopped.")
        brokerManagementModel.backendUnavailable("The managed backend process has stopped.")
        state = .stopped
    }
}
