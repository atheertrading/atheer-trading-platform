import Darwin
import Foundation
import XCTest
@testable import ATHEERTradingPro

private final class UnixDomainSocketFixtureServer {
    private let descriptor: Int32
    private let socketPath: String

    init(socketURL: URL) throws {
        socketPath = socketURL.path
        descriptor = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else {
            throw BrokerCredentialIPCError.socketCreationFailed(errno)
        }

        var address = sockaddr_un()
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        address.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = Array(socketPath.utf8CString)
        guard pathBytes.count <= MemoryLayout.size(ofValue: address.sun_path) else {
            _ = Darwin.close(descriptor)
            throw BrokerCredentialIPCError.invalidSocketPath
        }
        withUnsafeMutableBytes(of: &address.sun_path) { destination in
            destination.initializeMemory(as: UInt8.self, repeating: 0)
            for (index, byte) in pathBytes.enumerated() {
                destination[index] = UInt8(bitPattern: byte)
            }
        }

        let bindResult = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(descriptor, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard bindResult == 0 else {
            _ = Darwin.close(descriptor)
            throw BrokerCredentialIPCError.connectionFailed(errno)
        }
        guard Darwin.listen(descriptor, 1) == 0 else {
            _ = Darwin.close(descriptor)
            _ = Darwin.unlink(socketPath)
            throw BrokerCredentialIPCError.connectionFailed(errno)
        }
        _ = chmod(socketPath, 0o600)
    }

    deinit {
        _ = Darwin.close(descriptor)
        _ = Darwin.unlink(socketPath)
    }

    func serveOneRequest() async throws -> [String: Any] {
        try await Task.detached(priority: .utility) {
            let client = Darwin.accept(self.descriptor, nil, nil)
            guard client >= 0 else {
                throw BrokerCredentialIPCError.connectionFailed(errno)
            }
            defer { _ = Darwin.close(client) }

            var requestData = Data()
            var chunk = [UInt8](repeating: 0, count: 4_096)
            while requestData.count <= 8 * 1_024 {
                let count = chunk.withUnsafeMutableBytes { buffer in
                    Darwin.recv(client, buffer.baseAddress, buffer.count, 0)
                }
                if count < 0 {
                    if errno == EINTR { continue }
                    throw BrokerCredentialIPCError.readFailed(errno)
                }
                guard count > 0 else {
                    throw BrokerCredentialIPCError.invalidResponse
                }
                if let newline = chunk[..<count].firstIndex(of: 0x0A) {
                    requestData.append(contentsOf: chunk[..<newline])
                    guard newline == count - 1 else {
                        throw BrokerCredentialIPCError.invalidResponse
                    }
                    break
                }
                requestData.append(contentsOf: chunk[..<count])
            }

            guard let request = try JSONSerialization.jsonObject(with: requestData) as? [String: Any],
                  let requestId = request["requestId"] as? String else {
                throw BrokerCredentialIPCError.invalidResponse
            }
            let response: [String: Any] = [
                "requestId": requestId,
                "ok": true,
                "status": [
                    "provider": "capital.com",
                    "environment": "DEMO",
                    "state": "connected",
                    "connectedAtMs": 1_800_000_000_000
                ]
            ]
            var responseData = try JSONSerialization.data(withJSONObject: response)
            responseData.append(0x0A)
            try Self.writeAll(client, data: responseData)
            return request
        }.value
    }

    private static func writeAll(_ descriptor: Int32, data: Data) throws {
        try data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else {
                throw BrokerCredentialIPCError.invalidResponse
            }
            var offset = 0
            while offset < buffer.count {
                let written = Darwin.send(descriptor, baseAddress.advanced(by: offset), buffer.count - offset, 0)
                if written < 0 {
                    if errno == EINTR { continue }
                    throw BrokerCredentialIPCError.writeFailed(errno)
                }
                guard written > 0 else {
                    throw BrokerCredentialIPCError.writeFailed(EPIPE)
                }
                offset += written
            }
        }
    }
}

@MainActor
final class UnixDomainSocketBrokerCredentialIPCClientTests: XCTestCase {
    func testClientSendsDEMOOnlyCredentialRequestOverPrivateUnixSocket() async throws {
        let directory = try BackendCredentialSocketDirectory.create()
        defer { directory.remove() }
        let server = try UnixDomainSocketFixtureServer(socketURL: directory.socketURL)
        let capabilityBytes = Data(repeating: 41, count: 32)
        let capability = try BackendIPCCapability(testBytes: capabilityBytes)
        let client = UnixDomainSocketBrokerCredentialIPCClient(
            socketURL: directory.socketURL,
            capability: capability
        )

        let serverTask = Task.detached {
            try await server.serveOneRequest()
        }
        let status = try await client.connect(
            credentials: BrokerCredential(
                apiKey: "synthetic-demo-api-key",
                identifier: "synthetic.demo.user",
                password: "synthetic-demo-password"
            )
        )
        let request = try await serverTask.value

        XCTAssertEqual(status.provider, "capital.com")
        XCTAssertEqual(status.environment, "DEMO")
        XCTAssertEqual(status.state, "connected")
        XCTAssertEqual(request["action"] as? String, "connect")
        XCTAssertEqual(request["capability"] as? String, capability.base64URL)
        XCTAssertNil(request["environment"])
        let credentials = try XCTUnwrap(request["credentials"] as? [String: String])
        XCTAssertEqual(credentials["apiKey"], "synthetic-demo-api-key")
        XCTAssertEqual(credentials["identifier"], "synthetic.demo.user")
        XCTAssertEqual(credentials["password"], "synthetic-demo-password")
    }
}
