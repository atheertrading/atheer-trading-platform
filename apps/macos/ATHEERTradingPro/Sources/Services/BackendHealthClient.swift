import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol BackendHealthClient {
    @MainActor
    func fetchSnapshot() async throws -> BackendHealthSnapshot
}

struct URLSessionBackendHealthClient: BackendHealthClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder = BackendHealthPayloadDecoder()

    init(
        baseURL: URL = URL(string: "http://127.0.0.1:4100")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    @MainActor
    func fetchSnapshot() async throws -> BackendHealthSnapshot {
        let (livenessData, livenessStatusCode) = try await get(path: ["health", "live"])
        let (readinessData, readinessStatusCode) = try await get(path: ["health", "ready"])

        return try decoder.decode(
            livenessData: livenessData,
            livenessStatusCode: livenessStatusCode,
            readinessData: readinessData,
            readinessStatusCode: readinessStatusCode
        )
    }

    private func get(path: [String]) async throws -> (Data, Int) {
        let url = path.reduce(baseURL) { $0.appendingPathComponent($1) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 3
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendHealthError.invalidPayload
        }
        return (data, httpResponse.statusCode)
    }
}
