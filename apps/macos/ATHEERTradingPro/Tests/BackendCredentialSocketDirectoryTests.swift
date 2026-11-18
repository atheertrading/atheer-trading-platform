import Foundation
import XCTest
@testable import ATHEERTradingPro

final class BackendCredentialSocketDirectoryTests: XCTestCase {
    func testCreatesOwnerOnlyDirectoryAndSocketPathWithinDarwinLimit() throws {
        let directory = try BackendCredentialSocketDirectory.create()
        defer { directory.remove() }

        let attributes = try FileManager.default.attributesOfItem(atPath: directory.directoryURL.path)
        let permissions = (attributes[.posixPermissions] as? NSNumber)?.intValue ?? -1

        XCTAssertEqual(permissions & 0o777, 0o700)
        XCTAssertLessThanOrEqual(
            directory.socketURL.path.utf8.count,
            BackendCredentialSocketDirectory.maximumUnixSocketPathBytes
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.socketURL.path))
    }

    func testRemoveDeletesPrivateSocketDirectory() throws {
        let directory = try BackendCredentialSocketDirectory.create()
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.directoryURL.path))

        directory.remove()

        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.directoryURL.path))
    }
}
