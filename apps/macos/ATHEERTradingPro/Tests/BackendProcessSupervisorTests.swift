import Foundation
import XCTest
@testable import ATHEERTradingPro

@MainActor
private struct ProcessSupervisorTestResolver: BackendRuntimeResolving {
    let artifacts: BackendRuntimeArtifacts

    func resolve() throws -> BackendRuntimeArtifacts {
        artifacts
    }
}

final class BackendProcessSupervisorTests: XCTestCase {
    @MainActor
    func testCapabilityIsCanonicalBase64URLAndClears() throws {
        let capability = try BackendIPCCapability(testBytes: Data(repeating: 7, count: 32))
        let token = try XCTUnwrap(capability.base64URL)

        XCTAssertEqual(token.count, 43)
        XCTAssertFalse(token.contains("="))
        XCTAssertFalse(token.contains("+"))
        XCTAssertFalse(token.contains("/"))
        XCTAssertEqual(capability.authorizationHeaderValue, "Bearer " + token)

        let bootstrap = try capability.bootstrapPayload()
        XCTAssertEqual(bootstrap.last, 0x0A)
        XCTAssertEqual(String(decoding: bootstrap.dropLast(), as: UTF8.self), token)

        capability.clear()
        XCTAssertNil(capability.base64URL)
        XCTAssertNil(capability.authorizationHeaderValue)
        XCTAssertThrowsError(try capability.bootstrapPayload())
    }

    @MainActor
    func testStopDuringStartupWaitsForChildTerminationAndIsIdempotent() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ATHEER-BackendSupervisor-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let socketPathFile = directory.appendingPathComponent("credential-socket-path.txt")
        let tradingFlagFile = directory.appendingPathComponent("trading-flag.txt")
        let credentialEnvironmentFile = directory.appendingPathComponent("credential-environment.txt")
        let scriptURL = directory.appendingPathComponent("wait-for-signal.sh")
        let script = """
        printf '%s\\n' "$ATHEER_CREDENTIAL_SOCKET_PATH" > "\(socketPathFile.path)"
        printf '%s\\n' "$CAP_ALLOW_TRADING" > "\(tradingFlagFile.path)"
        printf '%s|%s|%s\\n' "${CAPITAL_COM_DEMO_API_KEY-unset}" "${CAPITAL_COM_DEMO_IDENTIFIER-unset}" "${CAPITAL_COM_DEMO_PASSWORD-unset}" > "\(credentialEnvironmentFile.path)"
        trap 'exit 0' TERM
        while true; do /bin/sleep 1; done
        """
        try Data(script.utf8).write(to: scriptURL)

        let artifacts = BackendRuntimeArtifacts(
            nodeExecutableURL: URL(fileURLWithPath: "/bin/sh"),
            entrypointURL: scriptURL
        )
        let supervisor = BackendProcessSupervisor(
            resolver: ProcessSupervisorTestResolver(artifacts: artifacts),
            startupTimeoutNanoseconds: 60_000_000_000,
            gracefulShutdownTimeoutNanoseconds: 2_000_000_000,
            forcedShutdownTimeoutNanoseconds: 500_000_000
        )
        var unexpectedTerminationCount = 0
        supervisor.onUnexpectedTermination = { _ in unexpectedTerminationCount += 1 }

        let startTask = Task { try await supervisor.start() }
        let startupDeadline = Date().addingTimeInterval(3)
        while !supervisor.isManagedProcessRunning && Date() < startupDeadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertTrue(supervisor.isManagedProcessRunning)

        let socketPath = try String(contentsOf: socketPathFile, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertFalse(socketPath.isEmpty)
        XCTAssertEqual(
            try String(contentsOf: tradingFlagFile, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines),
            "false"
        )
        XCTAssertEqual(
            try String(contentsOf: credentialEnvironmentFile, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines),
            "unset|unset|unset"
        )
        let socketDirectoryURL = URL(fileURLWithPath: socketPath).deletingLastPathComponent()
        let socketDirectoryAttributes = try FileManager.default.attributesOfItem(atPath: socketDirectoryURL.path)
        let socketDirectoryPermissions = (socketDirectoryAttributes[.posixPermissions] as? NSNumber)?.intValue ?? -1
        XCTAssertEqual(socketDirectoryPermissions & 0o777, 0o700)

        async let firstStop: Void = supervisor.stop()
        async let secondStop: Void = supervisor.stop()
        try await firstStop
        try await secondStop

        do {
            _ = try await startTask.value
            XCTFail("Startup must fail when shutdown is requested before readiness.")
        } catch {
            XCTAssertFalse(supervisor.isManagedProcessRunning)
        }

        XCTAssertEqual(unexpectedTerminationCount, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: socketDirectoryURL.path))
        try await supervisor.stop()
        XCTAssertFalse(supervisor.isManagedProcessRunning)
    }

    @MainActor
    func testForcedTerminationIsReportedAsUncleanAndClearsSupervisorState() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ATHEER-BackendSupervisor-Force-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let scriptURL = directory.appendingPathComponent("ignore-term.sh")
        try Data("trap '' TERM\nexec /bin/sleep 30\n".utf8).write(to: scriptURL)

        let artifacts = BackendRuntimeArtifacts(
            nodeExecutableURL: URL(fileURLWithPath: "/bin/sh"),
            entrypointURL: scriptURL
        )
        let supervisor = BackendProcessSupervisor(
            resolver: ProcessSupervisorTestResolver(artifacts: artifacts),
            startupTimeoutNanoseconds: 60_000_000_000,
            gracefulShutdownTimeoutNanoseconds: 100_000_000,
            forcedShutdownTimeoutNanoseconds: 2_000_000_000
        )

        let startTask = Task { try await supervisor.start() }
        let startupDeadline = Date().addingTimeInterval(3)
        while !supervisor.isManagedProcessRunning && Date() < startupDeadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertTrue(supervisor.isManagedProcessRunning)

        do {
            try await supervisor.stop()
            XCTFail("Forced SIGKILL must be reported as an unclean shutdown.")
        } catch let error as BackendProcessSupervisorError {
            guard case .childExitedUncleanly(let signal) = error else {
                XCTFail("Unexpected shutdown error: \(error.localizedDescription)")
                return
            }
            XCTAssertEqual(signal, SIGKILL)
        }

        do {
            _ = try await startTask.value
            XCTFail("Startup must fail when shutdown is requested before readiness.")
        } catch {
            XCTAssertFalse(supervisor.isManagedProcessRunning)
        }

        try await supervisor.stop()
        XCTAssertFalse(supervisor.isManagedProcessRunning)
    }

    @MainActor
    func testNonZeroBackendExitIsReportedAfterShutdownAndClearsState() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ATHEER-BackendSupervisor-Exit-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let scriptURL = directory.appendingPathComponent("fail-on-term.sh")
        try Data("trap 'exit 7' TERM\nwhile true; do /bin/sleep 1; done\n".utf8).write(to: scriptURL)

        let artifacts = BackendRuntimeArtifacts(
            nodeExecutableURL: URL(fileURLWithPath: "/bin/sh"),
            entrypointURL: scriptURL
        )
        let supervisor = BackendProcessSupervisor(
            resolver: ProcessSupervisorTestResolver(artifacts: artifacts),
            startupTimeoutNanoseconds: 60_000_000_000,
            gracefulShutdownTimeoutNanoseconds: 2_000_000_000,
            forcedShutdownTimeoutNanoseconds: 1_000_000_000
        )

        let startTask = Task { try await supervisor.start() }
        let startupDeadline = Date().addingTimeInterval(3)
        while !supervisor.isManagedProcessRunning && Date() < startupDeadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertTrue(supervisor.isManagedProcessRunning)

        do {
            try await supervisor.stop()
            XCTFail("A non-zero backend shutdown status must be surfaced.")
        } catch let error as BackendProcessSupervisorError {
            guard case .childExitedWithFailure(let status) = error else {
                XCTFail("Unexpected shutdown error: \(error.localizedDescription)")
                return
            }
            XCTAssertEqual(status, 7)
        }

        do {
            _ = try await startTask.value
            XCTFail("Startup must fail when shutdown is requested before readiness.")
        } catch {
            XCTAssertFalse(supervisor.isManagedProcessRunning)
        }

        try await supervisor.stop()
        XCTAssertFalse(supervisor.isManagedProcessRunning)
    }

    @MainActor
    func testReadinessMarkerAcceptsOnlyCanonicalBoundPorts() {
        XCTAssertEqual(
            BackendProcessSupervisor.parseReadyPort("ATHEER_BACKEND_READY 41023"),
            41023
        )
        XCTAssertNil(BackendProcessSupervisor.parseReadyPort("ATHEER_BACKEND_READY 0"))
        XCTAssertNil(BackendProcessSupervisor.parseReadyPort("ATHEER_BACKEND_READY 65536"))
        XCTAssertNil(BackendProcessSupervisor.parseReadyPort("ATHEER_BACKEND_READY 041023"))
        XCTAssertNil(BackendProcessSupervisor.parseReadyPort("ATHEER_BACKEND_READY 41023 "))
        XCTAssertNil(BackendProcessSupervisor.parseReadyPort("ATHEER API listening on 41023"))
    }
}
