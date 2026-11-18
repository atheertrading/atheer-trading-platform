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

        let scriptURL = directory.appendingPathComponent("wait-for-signal.sh")
        try Data("exec /bin/sleep 30\n".utf8).write(to: scriptURL)

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
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(supervisor.isManagedProcessRunning)

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
