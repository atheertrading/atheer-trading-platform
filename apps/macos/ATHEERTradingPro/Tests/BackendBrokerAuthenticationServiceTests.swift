import Foundation
import XCTest
@testable import ATHEERTradingPro

private final class BrokerAuthenticationURLProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var responseStatus = 200
    private static var responseBody = Data()
    private static var captured: [URLRequest] = []
    private static var capturedBodies: [Data?] = []

    static func configure(status: Int, body: Data) {
        lock.lock()
        responseStatus = status
        responseBody = body
        captured = []
        capturedBodies = []
        lock.unlock()
    }

    static func capturedRequests() -> [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return captured
    }

    static func capturedRequestBody(at index: Int = 0) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        guard capturedBodies.indices.contains(index) else { return nil }
        return capturedBodies[index]
    }

    private static func readBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var body = Data()
        var buffer = [UInt8](repeating: 0, count: 4_096)
        while true {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count < 0 { return nil }
            if count == 0 { break }
            body.append(buffer, count: count)
            if body.count > 8 * 1_024 { return nil }
        }
        return body
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        let status = Self.responseStatus
        let body = Self.responseBody
        let requestBody = Self.readBody(from: request)
        Self.captured.append(request)
        Self.capturedBodies.append(requestBody)
        Self.lock.unlock()

        guard let url = request.url,
              let response = HTTPURLResponse(
                url: url,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
              ) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@MainActor
private final class MockBrokerCredentialIPCTransport: BrokerCredentialIPCTransport {
    var status = BrokerCredentialIPCStatus(
        provider: "capital.com",
        environment: "DEMO",
        state: "connected",
        connectedAtMs: 1_800_000_000_000,
        lastError: nil
    )
    var capturedCredentials: BrokerCredential?
    var connectCount = 0
    var disconnectCount = 0
    var disconnectError: Error?

    func connect(credentials: BrokerCredential) async throws -> BrokerCredentialIPCStatus {
        connectCount += 1
        capturedCredentials = credentials
        return status
    }

    func disconnect() async throws {
        disconnectCount += 1
        if let disconnectError {
            throw disconnectError
        }
    }
}

@MainActor
final class BackendBrokerAuthenticationServiceTests: XCTestCase {
    private let credential = BrokerCredential(
        apiKey: "demo-api-key",
        identifier: "trader.identity.1234",
        password: "demo-secret-password"
    )

    private func makeService() throws -> (
        BackendBrokerAuthenticationService,
        MockBrokerCredentialIPCTransport,
        String
    ) {
        let rawCapability = Data(repeating: 7, count: 32)
        let capability = try BackendIPCCapability(testBytes: rawCapability)
        let encoded = rawCapability.base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
        let connection = BackendIPCConnection(
            baseURL: URL(string: "http://127.0.0.1:41023")!,
            capability: capability,
            credentialSocketURL: URL(fileURLWithPath: "/tmp/atheer-test/broker.sock")
        )
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [BrokerAuthenticationURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let transport = MockBrokerCredentialIPCTransport()
        let service = BackendBrokerAuthenticationService(
            connection: connection,
            session: session,
            credentialTransport: transport
        )
        return (service, transport, "Bearer " + encoded)
    }

    func testCredentialHandoffUsesPrivateIPCAndNeverPostsSecretsOverHTTP() async throws {
        BrokerAuthenticationURLProtocol.configure(status: 200, body: Data())
        let (service, transport, _) = try makeService()

        let account = try await service.authenticate(credential, environment: .demo)

        XCTAssertEqual(account.maskedLoginIdentifier, "••••1234")
        XCTAssertNil(account.currencyCode)
        XCTAssertEqual(transport.connectCount, 1)
        XCTAssertEqual(transport.capturedCredentials?.apiKey, credential.apiKey)
        XCTAssertEqual(transport.capturedCredentials?.identifier, credential.identifier)
        XCTAssertEqual(transport.capturedCredentials?.password, credential.password)
        XCTAssertTrue(BrokerAuthenticationURLProtocol.capturedRequests().isEmpty)
    }

    func testLIVEAuthenticationIsRejectedBeforeAnyIPCRequest() async throws {
        BrokerAuthenticationURLProtocol.configure(status: 200, body: Data())
        let (service, transport, _) = try makeService()

        do {
            _ = try await service.authenticate(credential, environment: .live)
            XCTFail("LIVE authentication must remain disabled.")
        } catch let error as BrokerAuthenticationError {
            if case .liveDisabled = error {
                XCTAssertEqual(transport.connectCount, 0)
                XCTAssertTrue(BrokerAuthenticationURLProtocol.capturedRequests().isEmpty)
            } else {
                XCTFail("Unexpected broker authentication error: \(error)")
            }
        }
    }

    func testProviderAuthenticationFailureMapsToInvalidCredentials() async throws {
        BrokerAuthenticationURLProtocol.configure(status: 200, body: Data())
        let (service, transport, _) = try makeService()
        transport.status = BrokerCredentialIPCStatus(
            provider: "capital.com",
            environment: "DEMO",
            state: "error",
            connectedAtMs: nil,
            lastError: "Capital.com DEMO session creation failed with HTTP 401."
        )

        do {
            _ = try await service.authenticate(credential, environment: .demo)
            XCTFail("Invalid provider credentials must not be reported as connected.")
        } catch let error as BrokerAuthenticationError {
            if case .invalidCredentials = error {
                XCTAssertEqual(transport.connectCount, 1)
                XCTAssertTrue(BrokerAuthenticationURLProtocol.capturedRequests().isEmpty)
            } else {
                XCTFail("Unexpected broker authentication error: \(error)")
            }
        }
    }

    func testProviderPermissionFailureIsNotMisclassifiedAsInvalidCredentials() async throws {
        BrokerAuthenticationURLProtocol.configure(status: 200, body: Data())
        let (service, transport, _) = try makeService()
        transport.status = BrokerCredentialIPCStatus(
            provider: "capital.com",
            environment: "DEMO",
            state: "error",
            connectedAtMs: nil,
            lastError: "Capital.com DEMO session creation failed with HTTP 403."
        )

        do {
            _ = try await service.authenticate(credential, environment: .demo)
            XCTFail("Provider permission denial must not be reported as invalid credentials.")
        } catch let error as BrokerAuthenticationError {
            if case .providerRejected(let status) = error {
                XCTAssertEqual(status, 403)
            } else {
                XCTFail("Unexpected broker authentication error: \(error)")
            }
        }
    }

    func testSessionStatusUsesAuthenticatedHTTPReadAndPreservesRateLimitClassification() async throws {
        BrokerAuthenticationURLProtocol.configure(
            status: 200,
            body: Data(#"{"provider":"capital.com","environment":"DEMO","state":"error","lastError":"Capital.com DEMO session creation failed with HTTP 429."}"#.utf8)
        )
        let (service, transport, expectedAuthorization) = try makeService()

        do {
            _ = try await service.validateSession()
            XCTFail("Rate-limited session status must not be reported as connected.")
        } catch let error as BrokerAuthenticationError {
            if case .rateLimited = error {
                XCTAssertEqual(transport.connectCount, 0)
                let request = try XCTUnwrap(BrokerAuthenticationURLProtocol.capturedRequests().first)
                XCTAssertEqual(request.httpMethod, "GET")
                XCTAssertEqual(request.url?.path, "/broker-session/status")
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), expectedAuthorization)
            } else {
                XCTFail("Unexpected broker authentication error: \(error)")
            }
        }
    }

    func testDisconnectUsesPrivateIPCAndRequiresAcknowledgement() async throws {
        BrokerAuthenticationURLProtocol.configure(status: 200, body: Data())
        let (service, transport, _) = try makeService()

        try await service.disconnect()

        XCTAssertEqual(transport.disconnectCount, 1)
        XCTAssertTrue(BrokerAuthenticationURLProtocol.capturedRequests().isEmpty)
    }

    func testDisconnectFailureIsSurfacedWithoutHTTPFallback() async throws {
        BrokerAuthenticationURLProtocol.configure(status: 200, body: Data())
        let (service, transport, _) = try makeService()
        transport.disconnectError = BrokerCredentialIPCError.requestRejected("broker_session_disconnect_failed")

        do {
            try await service.disconnect()
            XCTFail("Private IPC disconnect failure must not silently succeed.")
        } catch let error as BrokerAuthenticationError {
            if case .unavailable = error {
                XCTAssertEqual(transport.disconnectCount, 1)
                XCTAssertTrue(BrokerAuthenticationURLProtocol.capturedRequests().isEmpty)
            } else {
                XCTFail("Unexpected broker authentication error: \(error)")
            }
        }
    }
}
