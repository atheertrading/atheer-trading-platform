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
    private let supervisor: BackendProcessManaging

    init(
        supervisor: BackendProcessManaging? = nil,
        healthModel: BackendHealthViewModel = BackendHealthViewModel()
    ) {
        self.supervisor = supervisor ?? BackendProcessSupervisor()
        self.healthModel = healthModel
        self.supervisor.onUnexpectedTermination = { [weak self] message in
            self?.marketSearchClient = nil
            self?.healthModel.setUnavailable(message)
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
            marketSearchClient = URLSessionMarketSearchClient(connection: connection)
            await healthModel.refresh()
            state = .ready
        } catch {
            marketSearchClient = nil
            healthModel.setUnavailable(error.localizedDescription)
            state = .failed(error.localizedDescription)
        }
    }

    func stop() async throws {
        marketSearchClient = nil
        healthModel.setUnavailable("Stopping the managed backend process.")
        do {
            try await supervisor.stop()
            healthModel.setUnavailable("The managed backend process has stopped.")
            state = .stopped
        } catch {
            let message = "The managed backend could not be confirmed stopped: \(error.localizedDescription)"
            healthModel.setUnavailable(message)
            state = .failed(message)
            throw error
        }
    }
}
