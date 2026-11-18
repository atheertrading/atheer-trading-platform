import Foundation

struct BackendCredentialSocketDirectory {
    static let maximumUnixSocketPathBytes = 103

    let directoryURL: URL
    let socketURL: URL

    static func create(fileManager: FileManager = .default) throws -> BackendCredentialSocketDirectory {
        let directoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("atheer-\(UUID().uuidString.prefix(12))", isDirectory: true)
        let socketURL = directoryURL.appendingPathComponent("broker.sock", isDirectory: false)

        guard socketURL.path.utf8.count <= maximumUnixSocketPathBytes else {
            throw BackendProcessSupervisorError.invalidCredentialSocketPath
        }

        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700]
        )
        try fileManager.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: directoryURL.path
        )

        return BackendCredentialSocketDirectory(
            directoryURL: directoryURL,
            socketURL: socketURL
        )
    }

    func remove(fileManager: FileManager = .default) {
        try? fileManager.removeItem(at: directoryURL)
    }
}
