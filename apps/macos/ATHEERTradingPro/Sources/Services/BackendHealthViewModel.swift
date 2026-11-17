import Combine

final class BackendHealthViewModel: ObservableObject {
    @Published private(set) var state: BackendHealthViewState = .idle
    @Published private(set) var isRefreshing = false

    private let client: BackendHealthClient

    init(client: BackendHealthClient = URLSessionBackendHealthClient()) {
        self.client = client
    }

    @MainActor
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        state = .checking
        defer { isRefreshing = false }

        do {
            state = .connected(try await client.fetchSnapshot())
        } catch let error as BackendHealthError {
            switch error {
            case .unexpectedHTTPStatus(let statusCode):
                state = .serverError(statusCode)
            case .invalidPayload:
                state = .invalidResponse(error.localizedDescription)
            }
        } catch {
            state = .disconnected(error.localizedDescription)
        }
    }
}
