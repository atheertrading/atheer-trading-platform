import XCTest
@testable import ATHEERTradingPro

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
