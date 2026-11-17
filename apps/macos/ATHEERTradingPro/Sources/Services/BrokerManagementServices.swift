import SwiftUI
import Security

enum BrokerEnvironment: String, CaseIterable, Identifiable {
    case demo = "DEMO"
    case live = "LIVE"

    var id: String { rawValue }
    var displayName: String { rawValue }
    var isEnabled: Bool { self == .demo }
}

struct BrokerCredential: Codable, Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    let apiKey: String
    let identifier: String
    let password: String

    var description: String { "BrokerCredential(<redacted>)" }
    var debugDescription: String { description }

    var isValid: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    var maskedAPIKey: String {
        guard apiKey.count > 4 else { return "••••" }
        return "••••••••" + apiKey.suffix(4)
    }
}

enum BrokerConnectionState: Equatable {
    case notConfigured
    case credentialsSaved
    case connecting
    case authenticated
    case connected
    case authenticationFailed(String)
    case connectionFailed(String)
    case sessionExpired
    case disconnected

    var title: String {
        switch self {
        case .notConfigured: return "Not Configured"
        case .credentialsSaved: return "Credentials Saved"
        case .connecting: return "Connecting"
        case .authenticated: return "Authenticated"
        case .connected: return "Connected"
        case .authenticationFailed: return "Authentication Failed"
        case .connectionFailed: return "Connection Failed"
        case .sessionExpired: return "Session Expired"
        case .disconnected: return "Disconnected"
        }
    }

    var message: String? {
        switch self {
        case .authenticationFailed(let message), .connectionFailed(let message): return message
        case .sessionExpired: return "The provider session expired. Test the connection again."
        default: return nil
        }
    }
}

struct BrokerAccountSnapshot: Equatable {
    let accountIdentifier: String
    let currencyCode: String?
    let authenticatedAt: Date
}

enum BrokerCredentialStoreError: Error, LocalizedError {
    case invalidCredential
    case unavailable
    case encodingFailure
    case storageFailure(Int32)

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Enter the API key, account login, and API key password."
        case .unavailable: return "The macOS Keychain is unavailable."
        case .encodingFailure: return "Credentials could not be securely encoded."
        case .storageFailure: return "The macOS Keychain operation failed."
        }
    }
}

protocol BrokerCredentialStore {
    func load(brokerID: String, environment: BrokerEnvironment, accountIdentity: String?) throws -> BrokerCredential?
    func save(_ credential: BrokerCredential, brokerID: String, environment: BrokerEnvironment) throws
    func delete(brokerID: String, environment: BrokerEnvironment, accountIdentity: String?) throws
}

extension BrokerCredentialStore {
    func load(brokerID: String, environment: BrokerEnvironment) throws -> BrokerCredential? {
        try load(brokerID: brokerID, environment: environment, accountIdentity: nil)
    }

    func delete(brokerID: String, environment: BrokerEnvironment) throws {
        try delete(brokerID: brokerID, environment: environment, accountIdentity: nil)
    }
}

private struct StoredBrokerCredentials: Codable {
    var activeAccountIdentity: String?
    var credentialsByIdentity: [String: BrokerCredential]
}

protocol KeychainAccessing {
    func read(service: String, account: String) throws -> Data?
    func write(_ data: Data, service: String, account: String) throws
    func delete(service: String, account: String) throws
}

struct SystemKeychainAccess: KeychainAccessing {
    func read(service: String, account: String) throws -> Data? {
        var query = baseQuery(service: service, account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw BrokerCredentialStoreError.storageFailure(status) }
        return result as? Data
    }

    func write(_ data: Data, service: String, account: String) throws {
        let query = baseQuery(service: service, account: account)
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]
        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw BrokerCredentialStoreError.storageFailure(updateStatus)
        }
        var insertion = query
        insertion[kSecValueData as String] = data
        insertion[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let addStatus = SecItemAdd(insertion as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw BrokerCredentialStoreError.storageFailure(addStatus)
        }
    }

    func delete(service: String, account: String) throws {
        let status = SecItemDelete(baseQuery(service: service, account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw BrokerCredentialStoreError.storageFailure(status)
        }
    }

    private func baseQuery(service: String, account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

struct KeychainBrokerCredentialStore: BrokerCredentialStore {
    static let service = "com.atheertrading.desktop.broker-credentials"
    private let keychain: KeychainAccessing

    init(keychain: KeychainAccessing = SystemKeychainAccess()) {
        self.keychain = keychain
    }

    func load(
        brokerID: String,
        environment: BrokerEnvironment,
        accountIdentity: String?
    ) throws -> BrokerCredential? {
        guard let collection = try loadCollection(brokerID: brokerID, environment: environment) else {
            return nil
        }
        let identity = accountIdentity.map(normalizedIdentity) ?? collection.activeAccountIdentity
        guard let identity else { return nil }
        return collection.credentialsByIdentity[identity]
    }

    func save(_ credential: BrokerCredential, brokerID: String, environment: BrokerEnvironment) throws {
        guard credential.isValid else { throw BrokerCredentialStoreError.invalidCredential }
        var collection = try loadCollection(brokerID: brokerID, environment: environment) ?? StoredBrokerCredentials(
            activeAccountIdentity: nil,
            credentialsByIdentity: [:]
        )
        let identity = normalizedIdentity(credential.identifier)
        collection.credentialsByIdentity[identity] = credential
        collection.activeAccountIdentity = identity
        guard let data = try? JSONEncoder().encode(collection) else {
            throw BrokerCredentialStoreError.encodingFailure
        }
        try keychain.write(data, service: Self.service, account: key(brokerID, environment))
    }

    func delete(
        brokerID: String,
        environment: BrokerEnvironment,
        accountIdentity: String?
    ) throws {
        guard let accountIdentity else {
            try keychain.delete(service: Self.service, account: key(brokerID, environment))
            return
        }
        guard var collection = try loadCollection(brokerID: brokerID, environment: environment) else {
            return
        }
        let identity = normalizedIdentity(accountIdentity)
        collection.credentialsByIdentity.removeValue(forKey: identity)
        if collection.activeAccountIdentity == identity {
            collection.activeAccountIdentity = collection.credentialsByIdentity.keys.sorted().first
        }
        if collection.credentialsByIdentity.isEmpty {
            try keychain.delete(service: Self.service, account: key(brokerID, environment))
        } else {
            guard let data = try? JSONEncoder().encode(collection) else {
                throw BrokerCredentialStoreError.encodingFailure
            }
            try keychain.write(data, service: Self.service, account: key(brokerID, environment))
        }
    }

    private func loadCollection(brokerID: String, environment: BrokerEnvironment) throws -> StoredBrokerCredentials? {
        guard let data = try keychain.read(service: Self.service, account: key(brokerID, environment)) else {
            return nil
        }
        guard let collection = try? JSONDecoder().decode(StoredBrokerCredentials.self, from: data) else {
            throw BrokerCredentialStoreError.encodingFailure
        }
        return collection
    }

    private func normalizedIdentity(_ identity: String) -> String {
        identity.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func key(_ brokerID: String, _ environment: BrokerEnvironment) -> String {
        "\(brokerID.lowercased()).\(environment.rawValue.lowercased())"
    }
}

enum BrokerAuthenticationError: Error, LocalizedError {
    case invalidCredentials
    case rateLimited
    case providerRejected(Int)
    case invalidResponse
    case unavailable
    case liveDisabled

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Capital.com rejected the credentials. Check the API key, login, and API key password."
        case .rateLimited: return "Capital.com is rate-limiting session creation. Wait before trying again."
        case .providerRejected(let code): return "Capital.com returned HTTP \(code) during authentication."
        case .invalidResponse: return "Capital.com returned an incomplete or invalid session response."
        case .unavailable: return "Capital.com could not be reached. Check the network and try again."
        case .liveDisabled: return "LIVE broker connectivity is disabled in ATHEER Trading Pro."
        }
    }
}

@MainActor
protocol BrokerAuthenticationService {
    func authenticate(_ credential: BrokerCredential, environment: BrokerEnvironment) async throws -> BrokerAccountSnapshot
    func validateSession() async throws -> BrokerAccountSnapshot
    func disconnect() async
}

@MainActor
final class CapitalComAuthenticationService: BrokerAuthenticationService {
    private struct SessionPayload: Decodable {
        let accountId: String?
        let currentAccountId: String?
        let currency: String?
        let currencyIsoCode: String?
    }

    private let session: URLSession
    private let baseURL = URL(string: "https://demo-api-capital.backend-capital.com/api/v1")!
    private var cst: String?
    private var securityToken: String?

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.urlCache = nil
            configuration.httpCookieStorage = nil
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: configuration)
        }
    }

    func authenticate(_ credential: BrokerCredential, environment: BrokerEnvironment) async throws -> BrokerAccountSnapshot {
        guard environment == .demo else { throw BrokerAuthenticationError.liveDisabled }
        guard credential.isValid else { throw BrokerCredentialStoreError.invalidCredential }
        await disconnect()

        var request = URLRequest(url: baseURL.appendingPathComponent("session"))
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(credential.apiKey, forHTTPHeaderField: "X-CAP-API-KEY")
        let body: [String: Any] = [
            "identifier": credential.identifier,
            "password": credential.password,
            "encryptedPassword": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw BrokerAuthenticationError.invalidResponse }
            try validate(http.statusCode)
            guard let newCST = http.value(forHTTPHeaderField: "CST"),
                  let newSecurityToken = http.value(forHTTPHeaderField: "X-SECURITY-TOKEN"),
                  !newCST.isEmpty, !newSecurityToken.isEmpty else {
                throw BrokerAuthenticationError.invalidResponse
            }
            cst = newCST
            securityToken = newSecurityToken

            var verify = URLRequest(url: baseURL.appendingPathComponent("session"))
            verify.httpMethod = "GET"
            verify.timeoutInterval = 10
            verify.cachePolicy = .reloadIgnoringLocalCacheData
            verify.setValue("no-store", forHTTPHeaderField: "Cache-Control")
            verify.setValue(newCST, forHTTPHeaderField: "CST")
            verify.setValue(newSecurityToken, forHTTPHeaderField: "X-SECURITY-TOKEN")
            let (data, verifyResponse) = try await session.data(for: verify)
            guard let verifyHTTP = verifyResponse as? HTTPURLResponse else {
                throw BrokerAuthenticationError.invalidResponse
            }
            try validate(verifyHTTP.statusCode)
            let payload = try JSONDecoder().decode(SessionPayload.self, from: data)
            guard let accountID = payload.currentAccountId ?? payload.accountId,
                  !accountID.isEmpty else {
                throw BrokerAuthenticationError.invalidResponse
            }
            return BrokerAccountSnapshot(
                accountIdentifier: accountID,
                currencyCode: payload.currencyIsoCode ?? payload.currency,
                authenticatedAt: Date()
            )
        } catch is CancellationError {
            await disconnect()
            throw CancellationError()
        } catch let error as BrokerAuthenticationError {
            await disconnect()
            throw error
        } catch {
            await disconnect()
            if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                throw CancellationError()
            }
            throw BrokerAuthenticationError.unavailable
        }
    }

    func validateSession() async throws -> BrokerAccountSnapshot {
        guard let currentCST = cst, let currentToken = securityToken else {
            throw BrokerAuthenticationError.invalidResponse
        }
        var request = URLRequest(url: baseURL.appendingPathComponent("session"))
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue(currentCST, forHTTPHeaderField: "CST")
        request.setValue(currentToken, forHTTPHeaderField: "X-SECURITY-TOKEN")
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw BrokerAuthenticationError.invalidResponse }
            try validate(http.statusCode)
            let payload = try JSONDecoder().decode(SessionPayload.self, from: data)
            guard let accountID = payload.currentAccountId ?? payload.accountId, !accountID.isEmpty else {
                throw BrokerAuthenticationError.invalidResponse
            }
            return BrokerAccountSnapshot(
                accountIdentifier: accountID,
                currencyCode: payload.currencyIsoCode ?? payload.currency,
                authenticatedAt: Date()
            )
        } catch let error as BrokerAuthenticationError {
            if case .invalidCredentials = error { await disconnect() }
            throw error
        } catch {
            if Task.isCancelled || (error as? URLError)?.code == .cancelled { throw CancellationError() }
            throw BrokerAuthenticationError.unavailable
        }
    }

    func disconnect() async {
        guard let currentCST = cst, let currentToken = securityToken else {
            cst = nil
            securityToken = nil
            return
        }
        cst = nil
        securityToken = nil
        var request = URLRequest(url: baseURL.appendingPathComponent("session"))
        request.httpMethod = "DELETE"
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue(currentCST, forHTTPHeaderField: "CST")
        request.setValue(currentToken, forHTTPHeaderField: "X-SECURITY-TOKEN")
        _ = try? await session.data(for: request)
    }

    private func validate(_ statusCode: Int) throws {
        switch statusCode {
        case 200...299: return
        case 401, 403: throw BrokerAuthenticationError.invalidCredentials
        case 429: throw BrokerAuthenticationError.rateLimited
        default: throw BrokerAuthenticationError.providerRejected(statusCode)
        }
    }
}

@MainActor
final class BrokerManagementViewModel: ObservableObject {
    @Published private(set) var state: BrokerConnectionState
    @Published private(set) var hasSavedCredentials: Bool
    @Published private(set) var maskedAPIKey: String?
    @Published private(set) var account: BrokerAccountSnapshot?
    @Published private(set) var lastSuccessfulConnection: Date?
    @Published private(set) var lastSessionVerification: Date?
    @Published private(set) var isWorking = false

    private let credentialStore: BrokerCredentialStore
    private let authentication: BrokerAuthenticationService
    private let brokerID = "capital.com"
    private let environment: BrokerEnvironment = .demo

    init(
        credentialStore: BrokerCredentialStore = KeychainBrokerCredentialStore(),
        authentication: BrokerAuthenticationService? = nil
    ) {
        self.credentialStore = credentialStore
        self.authentication = authentication ?? CapitalComAuthenticationService()
        do {
            let credential = try credentialStore.load(brokerID: brokerID, environment: environment)
            hasSavedCredentials = credential != nil
            maskedAPIKey = credential?.maskedAPIKey
            state = credential == nil ? .notConfigured : .credentialsSaved
        } catch {
            hasSavedCredentials = false
            maskedAPIKey = nil
            state = .connectionFailed("Saved credentials could not be read from Keychain.")
        }
    }

    func saveCredentials(_ credential: BrokerCredential) async throws {
        await authentication.disconnect()
        account = nil
        state = hasSavedCredentials ? .credentialsSaved : .notConfigured
        try credentialStore.save(credential, brokerID: brokerID, environment: environment)
        hasSavedCredentials = true
        maskedAPIKey = credential.maskedAPIKey
        account = nil
        state = .credentialsSaved
    }

    func testConnection() async {
        guard !isWorking else { return }
        if state == .connected {
            await refreshSessionStatus()
            return
        }
        isWorking = true
        state = .connecting
        defer { isWorking = false }
        do {
            guard let credential = try credentialStore.load(brokerID: brokerID, environment: environment) else {
                state = .notConfigured
                return
            }
            let snapshot = try await authentication.authenticate(credential, environment: environment)
            account = snapshot
            lastSuccessfulConnection = snapshot.authenticatedAt
            lastSessionVerification = snapshot.authenticatedAt
            state = .connected
        } catch is CancellationError {
            state = .disconnected
        } catch let error as BrokerAuthenticationError {
            state = .authenticationFailed(error.localizedDescription)
        } catch {
            state = .connectionFailed(error.localizedDescription)
        }
    }

    func refreshSessionStatus() async {
        guard state == .connected else { return }
        do {
            let snapshot = try await authentication.validateSession()
            account = snapshot
            lastSessionVerification = snapshot.authenticatedAt
        } catch is CancellationError {
            return
        } catch let error as BrokerAuthenticationError {
            if case .invalidCredentials = error {
                state = .sessionExpired
                account = nil
            } else {
                account = nil
                state = .connectionFailed(error.localizedDescription)
            }
        } catch {
            account = nil
            state = .connectionFailed("The Capital.com session could not be verified.")
        }
    }

    func monitorSession() async {
        await refreshSessionStatus()
        while !Task.isCancelled {
            do {
                try await Task.sleep(nanoseconds: 60_000_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await refreshSessionStatus()
        }
    }

    func disconnect() async {
        await authentication.disconnect()
        account = nil
        state = hasSavedCredentials ? .credentialsSaved : .disconnected
    }

    func clearCredentials() async throws {
        await authentication.disconnect()
        account = nil
        state = hasSavedCredentials ? .credentialsSaved : .disconnected
        do {
            try credentialStore.delete(brokerID: brokerID, environment: environment)
        } catch {
            state = .connectionFailed("Credentials could not be removed from Keychain and remain configured.")
            throw error
        }
        hasSavedCredentials = false
        maskedAPIKey = nil
        account = nil
        lastSuccessfulConnection = nil
        lastSessionVerification = nil
        state = .notConfigured
    }
}
