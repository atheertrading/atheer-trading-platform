import Foundation
import Security

@MainActor
final class BackendIPCCapability {
    private var storage: Data

    init() throws {
        var bytes = Data(count: 32)
        let status = bytes.withUnsafeMutableBytes { buffer -> OSStatus in
            guard let address = buffer.baseAddress else { return errSecParam }
            return SecRandomCopyBytes(kSecRandomDefault, buffer.count, address)
        }
        guard status == errSecSuccess else {
            throw BackendProcessSupervisorError.capabilityGenerationFailed(status)
        }
        self.storage = bytes
    }

    init(testBytes: Data) throws {
        guard testBytes.count == 32 else {
            throw BackendProcessSupervisorError.invalidCapabilityLength
        }
        self.storage = testBytes
    }

    var base64URL: String? {
        guard storage.count == 32 else { return nil }
        return storage.base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }

    var authorizationHeaderValue: String? {
        base64URL.map { "Bearer " + $0 }
    }

    func bootstrapPayload() throws -> Data {
        guard let encoded = base64URL else {
            throw BackendProcessSupervisorError.capabilityCleared
        }
        var payload = Data(encoded.utf8)
        payload.append(0x0A)
        return payload
    }

    func clear() {
        guard !storage.isEmpty else { return }
        storage.resetBytes(in: 0..<storage.count)
        storage.removeAll(keepingCapacity: false)
    }
}

@MainActor
struct BackendIPCConnection {
    let baseURL: URL
    let capability: BackendIPCCapability
}

struct BackendRuntimeArtifacts {
    let nodeExecutableURL: URL
    let entrypointURL: URL
}

@MainActor
protocol BackendRuntimeResolving {
    func resolve() throws -> BackendRuntimeArtifacts
}

@MainActor
struct BundledBackendRuntimeResolver: BackendRuntimeResolving {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func resolve() throws -> BackendRuntimeArtifacts {
        guard let node = bundle.url(
            forResource: "node",
            withExtension: nil,
            subdirectory: "Runtime"
        ),
        let entrypoint = bundle.url(
            forResource: "main",
            withExtension: "js",
            subdirectory: "Backend/dist"
        ),
        FileManager.default.isExecutableFile(atPath: node.path) else {
            throw BackendProcessSupervisorError.runtimeNotBundled
        }

        return BackendRuntimeArtifacts(
            nodeExecutableURL: node,
            entrypointURL: entrypoint
        )
    }
}

@MainActor
protocol BackendProcessManaging {
    var onUnexpectedTermination: ((String) -> Void)? { get set }
    func start() async throws -> BackendIPCConnection
    func stop()
}

enum BackendProcessSupervisorError: Error, LocalizedError {
    case unsupportedOperatingSystem
    case runtimeNotBundled
    case capabilityGenerationFailed(OSStatus)
    case invalidCapabilityLength
    case capabilityCleared
    case launchFailed
    case startupTimedOut
    case readinessOutputClosed
    case processExited(Int32)
    case authenticationProbeFailed(Int)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedOperatingSystem:
            return "The bundled Node.js 24 runtime requires macOS 13.5 or later."
        case .runtimeNotBundled:
            return "The managed backend runtime is missing from the application bundle."
        case .capabilityGenerationFailed:
            return "The operating system could not generate a secure backend capability."
        case .invalidCapabilityLength:
            return "The backend capability must contain exactly 256 bits."
        case .capabilityCleared:
            return "The backend capability is no longer available."
        case .launchFailed:
            return "The managed backend process could not be launched."
        case .startupTimedOut:
            return "The managed backend did not report a listening port before the startup deadline."
        case .readinessOutputClosed:
            return "The managed backend closed its startup channel before becoming ready."
        case .processExited(let status):
            return "The managed backend exited during startup (status \(status))."
        case .authenticationProbeFailed(let status):
            return "The managed backend failed its authenticated startup probe (HTTP \(status))."
        }
    }
}

@MainActor
final class BackendProcessSupervisor: BackendProcessManaging {
    private let resolver: BackendRuntimeResolving
    private let startupTimeoutNanoseconds: UInt64

    private var process: Process?
    private var outputHandle: FileHandle?
    private var capability: BackendIPCCapability?
    private var connection: BackendIPCConnection?
    private var readyPort: Int?
    private var outputBuffer = Data()
    private var readyContinuation: CheckedContinuation<Int, Error>?
    private var startupTimeoutTask: Task<Void, Never>?

    var onUnexpectedTermination: ((String) -> Void)?

    init(
        resolver: BackendRuntimeResolving = BundledBackendRuntimeResolver(),
        startupTimeoutNanoseconds: UInt64 = 15_000_000_000
    ) {
        self.resolver = resolver
        self.startupTimeoutNanoseconds = startupTimeoutNanoseconds
    }

    func start() async throws -> BackendIPCConnection {
        if let connection, process?.isRunning == true {
            return connection
        }
        guard process?.isRunning != true else {
            throw BackendProcessSupervisorError.launchFailed
        }
        guard #available(macOS 13.5, *) else {
            throw BackendProcessSupervisorError.unsupportedOperatingSystem
        }

        do {
            let artifacts = try resolver.resolve()
            let newCapability = try BackendIPCCapability()
            let inputPipe = Pipe()
            let outputPipe = Pipe()
            let child = Process()

            child.executableURL = artifacts.nodeExecutableURL
            child.arguments = [artifacts.entrypointURL.path]
            child.currentDirectoryURL = artifacts.entrypointURL.deletingLastPathComponent()
            child.environment = [
                "HOST": "127.0.0.1",
                "PORT": "0",
                "NODE_ENV": "production",
                "CAP_ALLOW_TRADING": "false",
                "PATH": "/usr/bin:/bin"
            ]
            child.standardInput = inputPipe
            child.standardOutput = outputPipe
            child.standardError = FileHandle.nullDevice

            child.terminationHandler = { [weak self] terminatedProcess in
                let status = terminatedProcess.terminationStatus
                Task { @MainActor [weak self] in
                    self?.handleTermination(status: status)
                }
            }

            outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                let didClose = data.isEmpty
                Task { @MainActor [weak self] in
                    self?.consumeOutput(data, didClose: didClose)
                }
            }

            try child.run()
            process = child
            outputHandle = outputPipe.fileHandleForReading
            capability = newCapability

            var bootstrap = try newCapability.bootstrapPayload()
            do {
                try inputPipe.fileHandleForWriting.write(contentsOf: bootstrap)
            } catch {
                bootstrap.resetBytes(in: 0..<bootstrap.count)
                throw BackendProcessSupervisorError.launchFailed
            }
            bootstrap.resetBytes(in: 0..<bootstrap.count)
            inputPipe.fileHandleForWriting.closeFile()

            let port = try await waitForReadyPort()
            let baseURL = URL(string: "http://127.0.0.1:\(port)")!
            let newConnection = BackendIPCConnection(
                baseURL: baseURL,
                capability: newCapability
            )
            try await verifyConnection(newConnection)
            guard process?.isRunning == true,
                  newCapability.authorizationHeaderValue != nil else {
                throw BackendProcessSupervisorError.processExited(-1)
            }
            connection = newConnection
            return newConnection
        } catch {
            stop()
            throw error
        }
    }

    func stop() {
        startupTimeoutTask?.cancel()
        startupTimeoutTask = nil
        if readyContinuation != nil {
            finishStartup(.failure(BackendProcessSupervisorError.launchFailed))
        }

        outputHandle?.readabilityHandler = nil
        outputHandle = nil

        if let process, process.isRunning {
            process.terminationHandler = nil
            process.terminate()
        }
        process = nil

        capability?.clear()
        capability = nil
        connection = nil
        readyPort = nil
        outputBuffer.resetBytes(in: 0..<outputBuffer.count)
        outputBuffer.removeAll(keepingCapacity: false)
    }

    static func parseReadyPort(_ line: String) -> Int? {
        let prefix = "ATHEER_BACKEND_READY "
        guard line.hasPrefix(prefix) else { return nil }
        let rawPort = String(line.dropFirst(prefix.count))
        guard let port = Int(rawPort),
              (1...65_535).contains(port),
              String(port) == rawPort else {
            return nil
        }
        return port
    }

    private func waitForReadyPort() async throws -> Int {
        if let readyPort { return readyPort }

        return try await withCheckedThrowingContinuation { continuation in
            readyContinuation = continuation
            startupTimeoutTask = Task { [weak self] in
                guard let self else { return }
                do {
                    try await Task.sleep(nanoseconds: self.startupTimeoutNanoseconds)
                } catch {
                    return
                }
                self.finishStartup(.failure(BackendProcessSupervisorError.startupTimedOut))
            }
        }
    }

    private func consumeOutput(_ data: Data, didClose: Bool) {
        if didClose {
            if readyContinuation != nil {
                finishStartup(.failure(BackendProcessSupervisorError.readinessOutputClosed))
            }
            return
        }

        outputBuffer.append(data)
        guard outputBuffer.count <= 16_384 else {
            finishStartup(.failure(BackendProcessSupervisorError.readinessOutputClosed))
            return
        }

        while let newline = outputBuffer.firstIndex(of: 0x0A) {
            let lineData = outputBuffer.subdata(in: 0..<newline)
            outputBuffer.removeSubrange(0...newline)
            guard let line = String(data: lineData, encoding: .utf8) else { continue }
            guard let port = Self.parseReadyPort(line) else { continue }
            readyPort = port
            finishStartup(.success(port))
            return
        }
    }

    private func finishStartup(_ result: Result<Int, Error>) {
        startupTimeoutTask?.cancel()
        startupTimeoutTask = nil
        guard let continuation = readyContinuation else { return }
        readyContinuation = nil
        continuation.resume(with: result)
    }

    private func verifyConnection(_ connection: BackendIPCConnection) async throws {
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }

        let healthURL = connection.baseURL
            .appendingPathComponent("health")
            .appendingPathComponent("live")
        let (healthData, healthResponse) = try await session.data(from: healthURL)
        guard let healthHTTP = healthResponse as? HTTPURLResponse,
              healthHTTP.statusCode == 200,
              !healthData.isEmpty else {
            throw BackendProcessSupervisorError.authenticationProbeFailed(
                (healthResponse as? HTTPURLResponse)?.statusCode ?? -1
            )
        }

        let marketStatusURL = connection.baseURL
            .appendingPathComponent("market-data")
            .appendingPathComponent("status")
        var request = URLRequest(url: marketStatusURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 4
        guard let authorization = connection.capability.authorizationHeaderValue else {
            throw BackendProcessSupervisorError.capabilityCleared
        }
        request.setValue(authorization, forHTTPHeaderField: "Authorization")

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw BackendProcessSupervisorError.authenticationProbeFailed(
                (response as? HTTPURLResponse)?.statusCode ?? -1
            )
        }
    }

    private func handleTermination(status: Int32) {
        let wasReady = connection != nil
        if readyContinuation != nil {
            finishStartup(.failure(BackendProcessSupervisorError.processExited(status)))
        }
        outputHandle?.readabilityHandler = nil
        outputHandle = nil
        process = nil
        capability?.clear()
        capability = nil
        connection = nil

        if wasReady {
            onUnexpectedTermination?("The managed backend exited unexpectedly (status \(status)).")
        }
    }
}
