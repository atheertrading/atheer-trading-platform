import Foundation
import XCTest
@testable import ATHEERTradingPro

@MainActor
private final class CountingBackendProcessManager: BackendProcessManaging {
    var onUnexpectedTermination: ((String) -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0

    private let connection: BackendIPCConnection

    init() throws {
        let capability = try BackendIPCCapability(
            testBytes: Data(repeating: 0x42, count: 32)
        )
        connection = BackendIPCConnection(
            baseURL: URL(string: "http://127.0.0.1:43127")!,
            capability: capability,
            credentialSocketURL: URL(fileURLWithPath: "/tmp/atheer-runtime-test.sock")
        )
    }

    func start() async throws -> BackendIPCConnection {
        startCount += 1
        return connection
    }

    func stop() async throws {
        stopCount += 1
    }
}

private struct UnavailableBackendHealthClient: BackendHealthClient {
    @MainActor
    func fetchSnapshot() async throws -> BackendHealthSnapshot {
        throw URLError(.cannotConnectToHost)
    }
}

private final class InMemoryRuntimeWatchlistPersistence: MarketWatchlistPersistence {
    private var selectedEpics: [String] = []

    func loadSelectedEpics() -> [String] {
        selectedEpics
    }

    func saveSelectedEpics(_ epics: [String]) {
        selectedEpics = epics
    }
}

final class BackendRuntimeViewModelTests: XCTestCase {
    @MainActor
    func testStartingReadyRuntimeIsIdempotentAndRetainsItsSharedStreamModel() async throws {
        let processManager = try CountingBackendProcessManager()
        let runtime = BackendRuntimeViewModel(
            supervisor: processManager,
            healthModel: BackendHealthViewModel(client: UnavailableBackendHealthClient()),
            marketWatchlistPersistence: InMemoryRuntimeWatchlistPersistence()
        )

        await runtime.start()

        XCTAssertEqual(runtime.state, .ready)
        XCTAssertEqual(processManager.startCount, 1)
        let firstStreamModel = try XCTUnwrap(runtime.marketDataStreamModel)

        // A repeated start must not replace the runtime-owned stream model or launch
        // another backend process while the existing managed runtime is ready.
        await runtime.start()

        let secondStreamModel = try XCTUnwrap(runtime.marketDataStreamModel)
        XCTAssertEqual(processManager.startCount, 1)
        XCTAssertTrue(firstStreamModel === secondStreamModel)

        try await runtime.stop()

        XCTAssertEqual(processManager.stopCount, 1)
        XCTAssertNil(runtime.marketDataStreamModel)
        XCTAssertEqual(runtime.state, .stopped)
    }
}
