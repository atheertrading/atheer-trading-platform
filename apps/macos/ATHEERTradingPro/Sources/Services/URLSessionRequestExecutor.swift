import Foundation

/// Isolates URLSession's async transport API from UI actors.
///
/// URLSession is thread-safe. This wrapper owns one immutable session reference
/// and exposes only request execution, keeping URLSessionTaskDelegate's
/// non-Sendable default argument out of actor-isolated call sites on Swift 5.8.
final class URLSessionRequestExecutor: @unchecked Sendable {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request, delegate: nil)
    }
}
