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
        for _ in 0..<3 {
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
final class BackendBrokerAuthenticationServiceTests: XCTestCase {
    private let credential = BrokerCredential(
        apiKey: "demo-api-key",
        identifier: "trader.identity.1234",
        password: "demo-secret-password"
    )

    private func makeService() throws -> (BackendBrokerAuthenticationService, String) {
        let capability = try BackendIPCCapability(testBytes: Data(repeating: 7, count: 32))
        let encoded = Data(repeating: 7, count: 32).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
        let connection = BackendIPCConnection(
            baseURL: URL(string: "http://127.0.0.1:41023")!,
            capability: capability
        )
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [BrokerAuthenticationURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return (BackendBrokerAuthenticationService(connection: connection, session: session), "Bearer " + encoded)
    }

    func testCredentialHandoffUsesAuthenticatedLoopbackAndSendsOnlyDEMOFields() async throws {
        BrokerAuthenticationURLProtocol.configure(
            status: 200,
            body: Data(#"{"provider":"capital.com","environment":"DEMO","state":"connected","connectedAtMs":1800000000000}"#.utf8)
        )
        let (service, expectedAuthorization) = try makeService()

        let account = try await service.authenticate(credential, environment: .demo)

        XCTAssertEqual(account.maskedLoginIdentifier, "••••1234")
        XCTAssertNil(account.currencyCode)
        let request = try XCTUnwrap(BrokerAuthenticationURLProtocol.capturedRequests().first)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/broker-session/connect")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), expectedAuthorization)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Cache-Control"), "no-store")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(BrokerAuthenticationURLProtocol.capturedRequestBody())
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
        XCTAssertEqual(payload["apiKey"], credential.apiKey)
        XCTAssertEqual(payload["identifier"], credential.identifier)
        XCTAssertEqual(payload["password"], credential.password)
        XCTAssertNil(payload["environment"])
    }

    func testLIVEAuthenticationIsRejectedBeforeAnyIPCRequest() async throws {
        BrokerAuthenticationURLProtocol.configure(status: 200, body: Data())
        let (service, _) = try makeService()

        do {
            _ = try await service.authenticate(credential, environment: .live)
            XCTFail("LIVE authentication must remain disabled.")
        } catch let error as BrokerAuthenticationError {
            if case .liveDisabled = error {
                XCTAssertTrue(BrokerAuthenticationURLProtocol.capturedRequests().isEmpty)
            } else {
                XCTFail("Unexpected broker authentication error: \(error)")
            }
        }
    }

    func testProviderAuthenticationFailureMapsToInvalidCredentials() async throws {
        BrokerAuthenticationURLProtocol.configure(
            status: 401,
            body: Data(#"{"provider":"capital.com","environment":"DEMO","state":"error","lastError":"Capital.com DEMO session creation failed with HTTP 401."}"#.utf8)
        )
        let (service, _) = try makeService()

        do {
            _ = try await service.authenticate(credential, environment: .demo)
            XCTFail("Invalid provider credentials must not be reported as connected.")
        } catch let error as BrokerAuthenticationError {
            if case .invalidCredentials = error {
                XCTAssertEqual(BrokerAuthenticationURLProtocol.capturedRequests().count, 1)
            } else {
                XCTFail("Unexpected broker authentication error: \(error)")
            }
        }
    }

    func testProviderPermissionFailureIsNotMisclassifiedAsInvalidCredentials() async throws {
        BrokerAuthenticationURLProtocol.configure(
            status: 403,
            body: Data(#"{"provider":"capital.com","environment":"DEMO","state":"error","lastError":"Capital.com DEMO session creation failed with HTTP 403."}"#.utf8)
        )
        let (service, _) = try makeService()

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

    func testSessionStatusPreservesRateLimitClassification() async throws {
        BrokerAuthenticationURLProtocol.configure(
            status: 200,
            body: Data(#"{"provider":"capital.com","environment":"DEMO","state":"error","lastError":"Capital.com DEMO session creation failed with HTTP 429."}"#.utf8)
        )
        let (service, _) = try makeService()

        do {
            _ = try await service.validateSession()
            XCTFail("Rate-limited session status must not be reported as connected.")
        } catch let error as BrokerAuthenticationError {
            if case .rateLimited = error {
                XCTAssertEqual(BrokerAuthenticationURLProtocol.capturedRequests().count, 1)
            } else {
                XCTFail("Unexpected broker authentication error: \(error)")
            }
        }
    }

    func testDisconnectRequiresSuccessfulBackendAcknowledgement() async throws {
        BrokerAuthenticationURLProtocol.configure(
            status: 200,
            body: Data(#"{"provider":"capital.com","environment":"DEMO","state":"disconnected"}"#.utf8)
        )
        let (service, expectedAuthorization) = try makeService()

        try await service.disconnect()

        let request = try XCTUnwrap(BrokerAuthenticationURLProtocol.capturedRequests().first)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/broker-session/disconnect")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), expectedAuthorization)
    }
}
