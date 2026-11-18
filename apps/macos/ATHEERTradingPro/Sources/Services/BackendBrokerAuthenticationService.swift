import Foundation

@MainActor
final class BackendBrokerAuthenticationService: BrokerAuthenticationService {
    private let connection: BackendIPCConnection
    private let credentialTransport: BrokerCredentialIPCTransport
    private let requestExecutor: URLSessionRequestExecutor
    private var maskedLoginIdentifier: String?
    private var authenticatedAt: Date?

    init(
        connection: BackendIPCConnection,
        session: URLSession? = nil,
        credentialTransport: BrokerCredentialIPCTransport? = nil
    ) {
        self.connection = connection
        self.credentialTransport = credentialTransport ?? UnixDomainSocketBrokerCredentialIPCClient(
            socketURL: connection.credentialSocketURL,
            capability: connection.capability
        )
        let resolvedSession: URLSession
        if let session {
            resolvedSession = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.urlCache = nil
            configuration.httpCookieStorage = nil
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            resolvedSession = URLSession(configuration: configuration)
        }
        self.requestExecutor = URLSessionRequestExecutor(session: resolvedSession)
    }

    func authenticate(
        _ credential: BrokerCredential,
        environment: BrokerEnvironment
    ) async throws -> BrokerAccountSnapshot {
        guard environment == .demo else { throw BrokerAuthenticationError.liveDisabled }
        guard credential.isValid else { throw BrokerCredentialStoreError.invalidCredential }

        do {
            let payload = try await credentialTransport.connect(credentials: credential)
            guard payload.provider == "capital.com",
                  payload.environment == "DEMO" else {
                throw BrokerAuthenticationError.invalidResponse
            }
            guard payload.state == "connected" else {
                throw authenticationError(providerError: payload.lastError)
            }

            let timestamp = payload.connectedAtMs.map {
                Date(timeIntervalSince1970: $0 / 1_000)
            } ?? Date()
            maskedLoginIdentifier = Self.maskIdentifier(credential.identifier)
            authenticatedAt = timestamp
            return BrokerAccountSnapshot(
                maskedLoginIdentifier: maskedLoginIdentifier ?? "Capital.com DEMO",
                currencyCode: nil,
                authenticatedAt: timestamp
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as BrokerAuthenticationError {
            throw error
        } catch {
            if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                throw CancellationError()
            }
            throw BrokerAuthenticationError.unavailable
        }
    }

    func validateSession() async throws -> BrokerAccountSnapshot {
        let request = try makeRequest(path: "/broker-session/status", method: "GET")
        do {
            let (data, response) = try await requestExecutor.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw BrokerAuthenticationError.unavailable
            }
            let payload = try decodeStatus(data)
            guard payload.provider == "capital.com", payload.environment == "DEMO" else {
                throw BrokerAuthenticationError.invalidResponse
            }

            guard payload.state == "connected" else {
                throw authenticationError(providerError: payload.lastError)
            }

            let timestamp = payload.connectedAtMs.map {
                Date(timeIntervalSince1970: $0 / 1_000)
            } ?? authenticatedAt ?? Date()
            authenticatedAt = timestamp
            return BrokerAccountSnapshot(
                maskedLoginIdentifier: maskedLoginIdentifier ?? "Capital.com DEMO",
                currencyCode: nil,
                authenticatedAt: timestamp
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as BrokerAuthenticationError {
            throw error
        } catch {
            if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                throw CancellationError()
            }
            throw BrokerAuthenticationError.unavailable
        }
    }

    func disconnect() async throws {
        do {
            try await credentialTransport.disconnect()
            clearLocalState()
        } catch {
            if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                throw CancellationError()
            }
            throw BrokerAuthenticationError.unavailable
        }
    }

    private func makeRequest(path: String, method: String) throws -> URLRequest {
        guard let authorization = connection.capability.authorizationHeaderValue else {
            throw BrokerAuthenticationError.unavailable
        }
        let endpoint = path.split(separator: "/").reduce(connection.baseURL) {
            $0.appendingPathComponent(String($1))
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.timeoutInterval = 12
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        return request
    }

    private func decodeStatus(_ data: Data) throws -> BrokerCredentialIPCStatus {
        do {
            return try JSONDecoder().decode(BrokerCredentialIPCStatus.self, from: data)
        } catch {
            throw BrokerAuthenticationError.invalidResponse
        }
    }

    private func authenticationError(providerError: String?) -> BrokerAuthenticationError {
        let message = providerError ?? ""
        if message.contains("HTTP 401") ||
            message.localizedCaseInsensitiveContains("rejected or expired") {
            return .invalidCredentials
        }
        if message.contains("HTTP 403") {
            return .providerRejected(403)
        }
        if message.contains("HTTP 429") ||
            message.localizedCaseInsensitiveContains("rate-limited") {
            return .rateLimited
        }
        return .unavailable
    }

    private func clearLocalState() {
        maskedLoginIdentifier = nil
        authenticatedAt = nil
    }

    private static func maskIdentifier(_ identifier: String) -> String {
        let suffix = identifier.suffix(4)
        return identifier.count > 4 ? "••••" + suffix : "••••"
    }
}

@MainActor
final class UnavailableBrokerAuthenticationService: BrokerAuthenticationService {
    func authenticate(_ credential: BrokerCredential, environment: BrokerEnvironment) async throws -> BrokerAccountSnapshot {
        throw BrokerAuthenticationError.unavailable
    }

    func validateSession() async throws -> BrokerAccountSnapshot {
        throw BrokerAuthenticationError.unavailable
    }

    func disconnect() async throws {}
}
