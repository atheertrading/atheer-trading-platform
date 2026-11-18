import Darwin
import Foundation

struct BrokerCredentialIPCStatus: Decodable, Sendable {
    let provider: String
    let environment: String
    let state: String
    let connectedAtMs: Double?
    let lastError: String?
}

@MainActor
protocol BrokerCredentialIPCTransport: AnyObject {
    func connect(credentials: BrokerCredential) async throws -> BrokerCredentialIPCStatus
    func disconnect() async throws
}

@MainActor
final class UnixDomainSocketBrokerCredentialIPCClient: BrokerCredentialIPCTransport {
    private let socketURL: URL
    private let capability: BackendIPCCapability

    init(socketURL: URL, capability: BackendIPCCapability) {
        self.socketURL = socketURL
        self.capability = capability
    }

    func connect(credentials: BrokerCredential) async throws -> BrokerCredentialIPCStatus {
        guard let capabilityValue = capability.base64URL else {
            throw BackendProcessSupervisorError.capabilityCleared
        }
        let request = BrokerCredentialIPCRequest(
            requestId: UUID().uuidString,
            capability: capabilityValue,
            action: "connect",
            credentials: BrokerCredentialIPCRequestCredentials(
                apiKey: credentials.apiKey,
                identifier: credentials.identifier,
                password: credentials.password
            )
        )
        let response = try await send(request)
        guard response.ok, let status = response.status else {
            throw BrokerCredentialIPCError.requestRejected(response.errorCode ?? "broker_session_unavailable")
        }
        return status
    }

    func disconnect() async throws {
        guard let capabilityValue = capability.base64URL else {
            throw BackendProcessSupervisorError.capabilityCleared
        }
        let request = BrokerCredentialIPCRequest(
            requestId: UUID().uuidString,
            capability: capabilityValue,
            action: "disconnect",
            credentials: nil
        )
        let response = try await send(request)
        guard response.ok else {
            throw BrokerCredentialIPCError.requestRejected(response.errorCode ?? "broker_session_disconnect_failed")
        }
    }

    private func send(_ request: BrokerCredentialIPCRequest) async throws -> BrokerCredentialIPCResponse {
        let socketPath = socketURL.path
        var payload = try JSONEncoder().encode(request)
        payload.append(0x0A)
        defer {
            if !payload.isEmpty {
                payload.resetBytes(in: 0..<payload.count)
            }
        }

        let response = try await Task.detached(priority: .userInitiated) {
            try Self.exchange(socketPath: socketPath, payload: payload)
        }.value

        guard response.requestId == request.requestId else {
            throw BrokerCredentialIPCError.invalidResponse
        }
        return response
    }

    private static func exchange(socketPath: String, payload: Data) throws -> BrokerCredentialIPCResponse {
        guard socketPath.utf8.count <= BackendCredentialSocketDirectory.maximumUnixSocketPathBytes else {
            throw BrokerCredentialIPCError.invalidSocketPath
        }

        let descriptor = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else {
            throw BrokerCredentialIPCError.socketCreationFailed(errno)
        }
        defer { _ = Darwin.close(descriptor) }

        var noSignalPipe: Int32 = 1
        _ = setsockopt(
            descriptor,
            SOL_SOCKET,
            SO_NOSIGPIPE,
            &noSignalPipe,
            socklen_t(MemoryLayout<Int32>.size)
        )

        var timeout = timeval(tv_sec: 35, tv_usec: 0)
        _ = setsockopt(
            descriptor,
            SOL_SOCKET,
            SO_RCVTIMEO,
            &timeout,
            socklen_t(MemoryLayout<timeval>.size)
        )
        _ = setsockopt(
            descriptor,
            SOL_SOCKET,
            SO_SNDTIMEO,
            &timeout,
            socklen_t(MemoryLayout<timeval>.size)
        )

        var address = sockaddr_un()
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        address.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = Array(socketPath.utf8CString)
        guard pathBytes.count <= MemoryLayout.size(ofValue: address.sun_path) else {
            throw BrokerCredentialIPCError.invalidSocketPath
        }
        withUnsafeMutableBytes(of: &address.sun_path) { destination in
            destination.initializeMemory(as: UInt8.self, repeating: 0)
            for (index, byte) in pathBytes.enumerated() {
                destination[index] = UInt8(bitPattern: byte)
            }
        }

        let connectResult = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(
                    descriptor,
                    $0,
                    socklen_t(MemoryLayout<sockaddr_un>.size)
                )
            }
        }
        guard connectResult == 0 else {
            throw BrokerCredentialIPCError.connectionFailed(errno)
        }

        var mutablePayload = payload
        defer {
            if !mutablePayload.isEmpty {
                mutablePayload.resetBytes(in: 0..<mutablePayload.count)
            }
        }
        try writeAll(descriptor: descriptor, data: mutablePayload)
        let responseData = try readLine(descriptor: descriptor, maximumBytes: 8 * 1_024)
        do {
            return try JSONDecoder().decode(BrokerCredentialIPCResponse.self, from: responseData)
        } catch {
            throw BrokerCredentialIPCError.invalidResponse
        }
    }

    private static func writeAll(descriptor: Int32, data: Data) throws {
        try data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else {
                throw BrokerCredentialIPCError.invalidResponse
            }
            var offset = 0
            while offset < buffer.count {
                let written = Darwin.send(
                    descriptor,
                    baseAddress.advanced(by: offset),
                    buffer.count - offset,
                    0
                )
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

    private static func readLine(descriptor: Int32, maximumBytes: Int) throws -> Data {
        var response = Data()
        var chunk = [UInt8](repeating: 0, count: 4_096)

        while response.count <= maximumBytes {
            let count = chunk.withUnsafeMutableBytes { buffer in
                Darwin.recv(descriptor, buffer.baseAddress, buffer.count, 0)
            }
            if count < 0 {
                if errno == EINTR { continue }
                throw BrokerCredentialIPCError.readFailed(errno)
            }
            guard count > 0 else {
                throw BrokerCredentialIPCError.invalidResponse
            }

            if let newline = chunk[..<count].firstIndex(of: 0x0A) {
                response.append(contentsOf: chunk[..<newline])
                guard newline == count - 1 else {
                    throw BrokerCredentialIPCError.invalidResponse
                }
                return response
            }
            response.append(contentsOf: chunk[..<count])
        }

        throw BrokerCredentialIPCError.responseTooLarge
    }
}

private struct BrokerCredentialIPCRequest: Encodable, Sendable {
    let requestId: String
    let capability: String
    let action: String
    let credentials: BrokerCredentialIPCRequestCredentials?
}

private struct BrokerCredentialIPCRequestCredentials: Encodable, Sendable {
    let apiKey: String
    let identifier: String
    let password: String
}

private struct BrokerCredentialIPCResponse: Decodable, Sendable {
    let requestId: String
    let ok: Bool
    let status: BrokerCredentialIPCStatus?
    let errorCode: String?
}

enum BrokerCredentialIPCError: Error, LocalizedError, Sendable {
    case invalidSocketPath
    case socketCreationFailed(Int32)
    case connectionFailed(Int32)
    case writeFailed(Int32)
    case readFailed(Int32)
    case responseTooLarge
    case invalidResponse
    case requestRejected(String)

    var errorDescription: String? {
        switch self {
        case .invalidSocketPath:
            return "The private broker credential socket path is invalid."
        case .socketCreationFailed:
            return "The private broker credential channel could not be created."
        case .connectionFailed:
            return "The private broker credential channel is unavailable."
        case .writeFailed, .readFailed:
            return "The private broker credential channel failed during exchange."
        case .responseTooLarge, .invalidResponse:
            return "The private broker credential channel returned an invalid response."
        case .requestRejected(let code):
            return "The private broker credential request was rejected ((code))."
        }
    }
}
