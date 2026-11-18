import Foundation
import XCTest
@testable import ATHEERTradingPro

private final class BrokerAuthenticationURLProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var responseStatus = 200
    private static var responseBody = Data()
    private static var captured: [URLRequest] = []

    static func configure(status: Int, body: Data) {
        lock.lock()
        responseStatus = status
        responseBody = body
        captured = []
        lock.unlock()
    }

    static func capturedRequests() -> [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return captured
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        let status = Self.responseStatus
        let body = Self.responseBody
        Self.captured.append(request)
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

        XCTAssertEqual(account.accountIdentifier, "••••1234")
        XCTAssertNil(account.currencyCode)
        let request = try XCTUnwrap(BrokerAuthenticationURLProtocol.capturedRequests().first)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/broker-session/connect")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), expectedAuthorization)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Cache-Control"), "no-store")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(request.httpBody)
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
