import Foundation

@MainActor
final class BackendBrokerAuthenticationService: BrokerAuthenticationService {
    private struct ConnectPayload: Encodable {
        let apiKey: String
        let identifier: String
        let password: String
    }

    private struct SessionStatusPayload: Decodable {
        let provider: String
        let environment: String
        let state: String
        let connectedAtMs: Double?
        let lastError: String?
    }

    private let connection: BackendIPCConnection
    private let requestExecutor: URLSessionRequestExecutor
    private var maskedLoginIdentifier: String?
    private var authenticatedAt: Date?

    init(connection: BackendIPCConnection, session: URLSession? = nil) {
        self.connection = connection
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

        var request = try makeRequest(path: "/broker-session/connect", method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var body = try JSONEncoder().encode(
            ConnectPayload(
                apiKey: credential.apiKey,
                identifier: credential.identifier,
                password: credential.password
            )
        )
        request.httpBody = body
        defer {
            body.resetBytes(in: 0..<body.count)
            request.httpBody = nil
        }

        do {
            let (data, response) = try await requestExecutor.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw BrokerAuthenticationError.invalidResponse
            }
            guard http.statusCode == 200 else {
                throw authenticationError(statusCode: http.statusCode)
            }

            let payload = try decodeStatus(data)
            guard payload.provider == "capital.com",
                  payload.environment == "DEMO",
                  payload.state == "connected" else {
                throw BrokerAuthenticationError.invalidResponse
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
                let providerError = payload.lastError ?? ""
                if providerError.contains("HTTP 401") ||
                    providerError.localizedCaseInsensitiveContains("rejected or expired") {
                    throw BrokerAuthenticationError.invalidCredentials
                }
                if providerError.contains("HTTP 403") {
                    throw BrokerAuthenticationError.providerRejected(403)
                }
                if providerError.contains("HTTP 429") ||
                    providerError.localizedCaseInsensitiveContains("rate-limited") {
                    throw BrokerAuthenticationError.rateLimited
                }
                throw BrokerAuthenticationError.unavailable
            }

            let timestamp = payload.connectedAtMs.map {
                Date(timeIntervalSince1970: $0 / 1_000)
            } ?? authenticatedAt ?? Date()
            authenticatedAt = timestamp
            return BrokerAccountSnapshot(
                accountIdentifier: maskedLoginIdentifier ?? "Capital.com DEMO",
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
        let request = try makeRequest(path: "/broker-session/disconnect", method: "POST")
        let (_, response) = try await requestExecutor.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw BrokerAuthenticationError.unavailable
        }
        clearLocalState()
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

    private func decodeStatus(_ data: Data) throws -> SessionStatusPayload {
        do {
            return try JSONDecoder().decode(SessionStatusPayload.self, from: data)
        } catch {
            throw BrokerAuthenticationError.invalidResponse
        }
    }

    private func authenticationError(statusCode: Int) -> BrokerAuthenticationError {
        switch statusCode {
        case 400, 401: return .invalidCredentials
        case 403: return .providerRejected(403)
        case 429: return .rateLimited
        case 503: return .unavailable
        default: return .providerRejected(statusCode)
        }
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
