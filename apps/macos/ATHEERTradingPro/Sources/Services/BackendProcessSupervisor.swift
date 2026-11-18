import Darwin
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
    let credentialSocketURL: URL
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
protocol BackendProcessManaging: AnyObject {
    var onUnexpectedTermination: ((String) -> Void)? { get set }
    func start() async throws -> BackendIPCConnection
    func stop() async throws
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
    case childExitedWithFailure(Int32)
    case childExitedUncleanly(Int32)
    case authenticationProbeFailed(Int)
    case startupInProgress
    case terminationTimedOut
    case invalidCredentialSocketPath
    
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
        case .childExitedWithFailure(let status):
            return "The managed backend exited with a shutdown failure (status \(status))."
        case .childExitedUncleanly(let signal):
            return "The managed backend required signal termination (signal \(signal)); graceful cleanup was not confirmed."
        case .authenticationProbeFailed(let status):
            return "The managed backend failed its authenticated startup probe (HTTP \(status))."
        case .startupInProgress:
            return "The managed backend is already starting."
        case .terminationTimedOut:
            return "The managed backend did not exit after graceful and forced shutdown deadlines."
        case .invalidCredentialSocketPath:
            return "A private broker credential socket path could not be created within the macOS Unix-domain socket limit."
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
    private var credentialSocketDirectory: BackendCredentialSocketDirectory?
    private var readyPort: Int?
    private var outputBuffer = Data()
    private var readyContinuation: CheckedContinuation<Int, Error>?
    private var startupTimeoutTask: Task<Void, Never>?
    private var stopTask: Task<Void, Error>?
    private var stoppingProcessIdentifier: ObjectIdentifier?
    private var terminationWaiters: [ObjectIdentifier: CheckedContinuation<Bool, Never>] = [:]
    private var terminationTimeoutTasks: [ObjectIdentifier: Task<Void, Never>] = [:]
    private let gracefulShutdownTimeoutNanoseconds: UInt64
    private let forcedShutdownTimeoutNanoseconds: UInt64

    var onUnexpectedTermination: ((String) -> Void)?
    var isManagedProcessRunning: Bool { process?.isRunning ?? false }

    init(
        resolver: BackendRuntimeResolving? = nil,
        startupTimeoutNanoseconds: UInt64 = 15_000_000_000,
        gracefulShutdownTimeoutNanoseconds: UInt64 = 25_000_000_000,
        forcedShutdownTimeoutNanoseconds: UInt64 = 2_000_000_000
    ) {
        self.resolver = resolver ?? BundledBackendRuntimeResolver()
        self.startupTimeoutNanoseconds = startupTimeoutNanoseconds
        self.gracefulShutdownTimeoutNanoseconds = gracefulShutdownTimeoutNanoseconds
        self.forcedShutdownTimeoutNanoseconds = forcedShutdownTimeoutNanoseconds
    }

    func start() async throws -> BackendIPCConnection {
        if let stopTask {
            try await stopTask.value
        }
        if let connection, process?.isRunning == true {
            return connection
        }
        if process?.isRunning == true {
            throw BackendProcessSupervisorError.startupInProgress
        }
        if let process, !process.isRunning {
            capability?.clear()
            capability = nil
            connection = nil
            self.process = nil
        }
        guard #available(macOS 13.5, *) else {
            throw BackendProcessSupervisorError.unsupportedOperatingSystem
        }

        do {
            let artifacts = try resolver.resolve()
            let newCapability = try BackendIPCCapability()
            let socketDirectory = try BackendCredentialSocketDirectory.create()
            credentialSocketDirectory = socketDirectory
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
                "ATHEER_CREDENTIAL_SOCKET_PATH": socketDirectory.socketURL.path,
                "PATH": "/usr/bin:/bin"
            ]
            child.standardInput = inputPipe
            child.standardOutput = outputPipe
            child.standardError = FileHandle.nullDevice

            child.terminationHandler = { [weak self] terminatedProcess in
                let status = terminatedProcess.terminationStatus
                let processIdentifier = ObjectIdentifier(terminatedProcess)
                Task { @MainActor [weak self] in
                    self?.handleTermination(processIdentifier: processIdentifier, status: status)
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
                capability: newCapability,
                credentialSocketURL: socketDirectory.socketURL
            )
            try await verifyConnection(newConnection)
            guard process?.isRunning == true,
                  newCapability.authorizationHeaderValue != nil else {
                throw BackendProcessSupervisorError.processExited(-1)
            }
            connection = newConnection
            return newConnection
        } catch {
            let startupError = error
            try await stop()
            throw startupError
        }
    }

    func stop() async throws {
        if let stopTask {
            try await stopTask.value
            return
        }

        let task = Task { @MainActor in
            try await self.performStop()
        }
        stopTask = task

        do {
            try await task.value
            stopTask = nil
        } catch {
            stopTask = nil
            throw error
        }
    }

    private func performStop() async throws {
        startupTimeoutTask?.cancel()
        startupTimeoutTask = nil
        if readyContinuation != nil {
            finishStartup(.failure(BackendProcessSupervisorError.launchFailed))
        }

        outputHandle?.readabilityHandler = nil
        outputHandle = nil

        guard let child = process else {
            clearSupervisorState()
            return
        }

        let identifier = ObjectIdentifier(child)
        stoppingProcessIdentifier = identifier

        if child.isRunning {
            let exitedGracefully = await signalAndWait(
                child,
                signal: SIGTERM,
                timeoutNanoseconds: gracefulShutdownTimeoutNanoseconds
            )
            if !exitedGracefully {
                let exitedAfterForce = await signalAndWait(
                    child,
                    signal: SIGKILL,
                    timeoutNanoseconds: forcedShutdownTimeoutNanoseconds
                )
                guard exitedAfterForce else {
                    throw BackendProcessSupervisorError.terminationTimedOut
                }
            }
        }

        guard !child.isRunning else {
            throw BackendProcessSupervisorError.terminationTimedOut
        }

        let terminationReason = child.terminationReason
        let terminationStatus = child.terminationStatus

        if self.process === child {
            self.process = nil
        }
        clearSupervisorState()

        switch terminationReason {
        case .exit where terminationStatus != 0:
            throw BackendProcessSupervisorError.childExitedWithFailure(terminationStatus)
        case .uncaughtSignal:
            throw BackendProcessSupervisorError.childExitedUncleanly(terminationStatus)
        default:
            break
        }
    }

    private func signalAndWait(
        _ child: Process,
        signal: Int32,
        timeoutNanoseconds: UInt64
    ) async -> Bool {
        if !child.isRunning { return true }
        let identifier = ObjectIdentifier(child)

        return await withCheckedContinuation { continuation in
            terminationWaiters[identifier] = continuation
            terminationTimeoutTasks[identifier] = Task { @MainActor [weak self] in
                do {
                    try await Task.sleep(nanoseconds: timeoutNanoseconds)
                } catch {
                    return
                }
                guard let self,
                      let waiter = self.terminationWaiters.removeValue(forKey: identifier) else {
                    return
                }
                self.terminationTimeoutTasks.removeValue(forKey: identifier)
                waiter.resume(returning: false)
            }

            if signal == SIGTERM {
                child.terminate()
            } else {
                _ = kill(child.processIdentifier, signal)
            }

            if !child.isRunning {
                completeTerminationWait(identifier, terminated: true)
            }
        }
    }

    private func completeTerminationWait(_ identifier: ObjectIdentifier, terminated: Bool) {
        terminationTimeoutTasks.removeValue(forKey: identifier)?.cancel()
        guard let waiter = terminationWaiters.removeValue(forKey: identifier) else { return }
        waiter.resume(returning: terminated)
    }

    private func clearSupervisorState() {
        capability?.clear()
        capability = nil
        connection = nil
        credentialSocketDirectory?.remove()
        credentialSocketDirectory = nil
        readyPort = nil
        outputBuffer.resetBytes(in: 0..<outputBuffer.count)
        outputBuffer.removeAll(keepingCapacity: false)
        stoppingProcessIdentifier = nil
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

    private func handleTermination(processIdentifier: ObjectIdentifier, status: Int32) {
        guard let process,
              ObjectIdentifier(process) == processIdentifier else {
            completeTerminationWait(processIdentifier, terminated: true)
            return
        }
        let wasReady = connection != nil
        let wasExpectedStop = stoppingProcessIdentifier == processIdentifier
        completeTerminationWait(processIdentifier, terminated: true)
        if readyContinuation != nil {
            finishStartup(.failure(BackendProcessSupervisorError.processExited(status)))
        }
        outputHandle?.readabilityHandler = nil
        outputHandle = nil
        self.process = nil
        clearSupervisorState()

        if wasReady && !wasExpectedStop {
            onUnexpectedTermination?("The managed backend exited unexpectedly (status \(status)).")
        }
    }
}
