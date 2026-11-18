import Foundation
import Combine

struct MarketWatchlistSnapshot: Codable, Equatable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let epics: [String]

    static let empty = MarketWatchlistSnapshot(
        schemaVersion: currentSchemaVersion,
        epics: []
    )
}

enum MarketWatchlistPersistenceError: Error, Equatable {
    case unsupportedSchema(Int)
    case invalidSnapshot(String)
    case corruptData(String)
}

protocol MarketWatchlistPersistence {
    func load() throws -> MarketWatchlistSnapshot?
    func save(_ snapshot: MarketWatchlistSnapshot) throws
}

struct UserDefaultsMarketWatchlistPersistence: MarketWatchlistPersistence {
    private let defaults: UserDefaults
    private let key: String

    init(
        defaults: UserDefaults = .standard,
        key: String = "com.atheertrading.market-watchlist.v1"
    ) {
        self.defaults = defaults
        self.key = key
    }

    func load() throws -> MarketWatchlistSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(MarketWatchlistSnapshot.self, from: data)
        } catch {
            throw MarketWatchlistPersistenceError.corruptData(String(describing: error))
        }
    }

    func save(_ snapshot: MarketWatchlistSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: key)
    }
}

@MainActor
final class MarketWatchlistStore: ObservableObject {
    static let maximumInstrumentCount = 40

    @Published private(set) var epics: [String] = []
    @Published private(set) var recoveryMessage: String?
    @Published private(set) var errorMessage: String?

    private let persistence: MarketWatchlistPersistence

    init(persistence: MarketWatchlistPersistence = UserDefaultsMarketWatchlistPersistence()) {
        self.persistence = persistence
        do {
            guard let snapshot = try persistence.load() else { return }
            try Self.validate(snapshot)
            epics = snapshot.epics
        } catch {
            recoveryMessage = String(describing: error)
        }
    }

    func contains(_ rawEpic: String) -> Bool {
        epics.contains(Self.normalize(rawEpic))
    }

    @discardableResult
    func add(_ rawEpic: String) -> Bool {
        let epic = Self.normalize(rawEpic)
        guard Self.isValidEpic(epic) else {
            errorMessage = "The instrument identifier is invalid."
            return false
        }
        guard !epics.contains(epic) else {
            errorMessage = nil
            return true
        }
        guard epics.count < Self.maximumInstrumentCount else {
            errorMessage = "The watchlist supports up to \(Self.maximumInstrumentCount) instruments in this release."
            return false
        }

        var next = epics
        next.append(epic)
        return persist(next)
    }

    @discardableResult
    func remove(_ rawEpic: String) -> Bool {
        let epic = Self.normalize(rawEpic)
        guard epics.contains(epic) else { return true }
        return persist(epics.filter { $0 != epic })
    }

    @discardableResult
    func move(_ rawEpic: String, to targetIndex: Int) -> Bool {
        var next = epics
        guard let sourceIndex = next.firstIndex(of: Self.normalize(rawEpic)) else { return false }
        let destination = min(max(0, targetIndex), next.count - 1)
        guard sourceIndex != destination else { return true }
        let moving = next.remove(at: sourceIndex)
        next.insert(moving, at: destination)
        return persist(next)
    }

    private func persist(_ next: [String]) -> Bool {
        do {
            try persistence.save(MarketWatchlistSnapshot(
                schemaVersion: MarketWatchlistSnapshot.currentSchemaVersion,
                epics: next
            ))
            epics = next
            errorMessage = nil
            return true
        } catch {
            errorMessage = "The watchlist could not be saved: \(error.localizedDescription)"
            return false
        }
    }

    private static func validate(_ snapshot: MarketWatchlistSnapshot) throws {
        guard snapshot.schemaVersion == MarketWatchlistSnapshot.currentSchemaVersion else {
            throw MarketWatchlistPersistenceError.unsupportedSchema(snapshot.schemaVersion)
        }
        guard snapshot.epics.count <= maximumInstrumentCount else {
            throw MarketWatchlistPersistenceError.invalidSnapshot("Watchlist exceeds the supported instrument limit.")
        }
        guard Set(snapshot.epics).count == snapshot.epics.count else {
            throw MarketWatchlistPersistenceError.invalidSnapshot("Watchlist contains duplicate instrument identifiers.")
        }
        guard snapshot.epics.allSatisfy(isValidEpic) else {
            throw MarketWatchlistPersistenceError.invalidSnapshot("Watchlist contains an invalid instrument identifier.")
        }
    }

    private static func normalize(_ epic: String) -> String {
        epic.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isValidEpic(_ epic: String) -> Bool {
        guard !epic.isEmpty, epic.count <= 64 else { return false }
        return epic.unicodeScalars.allSatisfy { scalar in
            let value = scalar.value
            return (48...57).contains(value)
                || (65...90).contains(value)
                || (97...122).contains(value)
                || value == 45
                || value == 46
                || value == 95
        }
    }
}
