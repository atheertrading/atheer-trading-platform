import Foundation
import XCTest
@testable import ATHEERTradingPro

final class CapitalComAuthenticationTests: XCTestCase {
    @MainActor
    func testDemoAuthenticationUsesOfficialRequestContractAndVerifiesSession() async throws {
        let recorder = RequestRecorder()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        StubURLProtocol.handler = { request in
            switch request.httpMethod {
            case "POST":
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["CST": "test-cst", "X-SECURITY-TOKEN": "test-security-token"]
                )!
                return (response, Data())
            case "GET":
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, Data(#"{"accountId":"DEMO-ACCOUNT-42","currency":"USD"}"#.utf8))
            case "DELETE":
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, Data())
            default:
                let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
                return (response, Data())
            }
        }
        StubURLProtocol.requestObserver = { request, body in
            recorder.append(request, body: body)
        }
        defer {
            StubURLProtocol.handler = nil
            StubURLProtocol.requestObserver = nil
            session.invalidateAndCancel()
        }

        let service = CapitalComAuthenticationService(session: session)
        let credential = BrokerCredential(
            apiKey: "test-api-key",
            identifier: "demo@example.invalid",
            password: "test-api-password"
        )

        let account = try await service.authenticate(credential, environment: .demo)

        XCTAssertEqual(account.accountIdentifier, "DEMO-ACCOUNT-42")
        XCTAssertEqual(account.currencyCode, "USD")

        let requests = recorder.requests
        XCTAssertEqual(requests.count, 2)
        let createRecord = try XCTUnwrap(requests.first)
        let createRequest = createRecord.request
        XCTAssertEqual(createRequest.httpMethod, "POST")
        XCTAssertEqual(createRequest.url?.absoluteString, "https://demo-api-capital.backend-capital.com/api/v1/session")
        XCTAssertEqual(createRequest.value(forHTTPHeaderField: "X-CAP-API-KEY"), "test-api-key")
        let bodyData = try XCTUnwrap(createRecord.body, "The URLProtocol recorder must capture the outgoing POST body.")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        XCTAssertEqual(body["identifier"] as? String, "demo@example.invalid")
        XCTAssertEqual(body["password"] as? String, "test-api-password")
        XCTAssertEqual(body["encryptedPassword"] as? Bool, false)

        let verifyRequest = try XCTUnwrap(requests.last?.request)
        XCTAssertEqual(verifyRequest.httpMethod, "GET")
        XCTAssertEqual(verifyRequest.value(forHTTPHeaderField: "CST"), "test-cst")
        XCTAssertEqual(verifyRequest.value(forHTTPHeaderField: "X-SECURITY-TOKEN"), "test-security-token")

        await service.disconnect()
        XCTAssertEqual(recorder.requests.last?.request.httpMethod, "DELETE")
    }

    @MainActor
    func testDemoAuthenticationMapsUnauthorizedResponseWithoutExposingSecrets() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data("sensitive provider response must not be surfaced".utf8))
        }
        defer {
            StubURLProtocol.handler = nil
            session.invalidateAndCancel()
        }

        let service = CapitalComAuthenticationService(session: session)
        let credential = BrokerCredential(apiKey: "private-key", identifier: "private-login", password: "private-password")

        do {
            _ = try await service.authenticate(credential, environment: .demo)
            XCTFail("Unauthorized credentials must not establish a broker connection.")
        } catch let error as BrokerAuthenticationError {
            if case .invalidCredentials = error {
                XCTAssertFalse(error.localizedDescription.contains("private-key"))
                XCTAssertFalse(error.localizedDescription.contains("private-password"))
                XCTAssertFalse(error.localizedDescription.contains("sensitive provider response"))
            } else {
                XCTFail("Expected invalidCredentials, received \(error.localizedDescription)")
            }
        } catch {
            XCTFail("Expected a typed authentication error.")
        }
    }

    @MainActor
    func testLiveEnvironmentIsRejectedBeforeNetworkAccess() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let recorder = RequestRecorder()
        StubURLProtocol.handler = { request in
            recorder.append(request, body: nil)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        defer {
            StubURLProtocol.handler = nil
            session.invalidateAndCancel()
        }

        let service = CapitalComAuthenticationService(session: session)
        do {
            _ = try await service.authenticate(
                BrokerCredential(apiKey: "key", identifier: "login", password: "password"),
                environment: .live
            )
            XCTFail("LIVE authentication must remain disabled.")
        } catch let error as BrokerAuthenticationError {
            if case .liveDisabled = error {
                XCTAssertTrue(recorder.requests.isEmpty)
            } else {
                XCTFail("Expected LIVE-disabled error.")
            }
        } catch {
            XCTFail("Expected typed LIVE-disabled error.")
        }
    }
}

private final class RequestRecorder {
    struct RecordedRequest {
        let request: URLRequest
        let body: Data?
    }

    private let lock = NSLock()
    private var storage: [RecordedRequest] = []

    var requests: [RecordedRequest] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ request: URLRequest, body: Data?) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(RecordedRequest(request: request, body: body))
    }
}

private final class StubURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var requestObserver: ((URLRequest, Data?) -> Void)?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            guard let handler = Self.handler else {
                throw URLError(.badServerResponse)
            }
            Self.requestObserver?(request, try Self.bodyData(from: request))
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    private static func bodyData(from request: URLRequest) throws -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return nil
        }

        stream.open()
        defer { stream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4_096)
        while true {
            let bytesRead = stream.read(&buffer, maxLength: buffer.count)
            if bytesRead < 0 {
                throw stream.streamError ?? URLError(.cannotDecodeContentData)
            }
            if bytesRead == 0 {
                break
            }
            data.append(contentsOf: buffer.prefix(bytesRead))
        }
        return data
    }
}
