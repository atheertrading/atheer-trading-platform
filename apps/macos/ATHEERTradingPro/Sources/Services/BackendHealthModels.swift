import Foundation

struct BackendHealthSnapshot: Equatable {
    let version: String
    let platformReady: Bool
    let persistenceStatus: String
    let brokerStatus: String
    let tradingEnabled: Bool
    let tradingStatus: String
    let lastCheckedAt: String
}

enum BackendHealthViewState: Equatable {
    case idle
    case checking
    case connected(BackendHealthSnapshot)
    case disconnected
}

enum BackendHealthError: Error {
    case unexpectedHTTPStatus(Int)
    case invalidPayload
}

struct BackendHealthPayloadDecoder {
    func decode(
        livenessData: Data,
        livenessStatusCode: Int,
        readinessData: Data,
        readinessStatusCode: Int
    ) throws -> BackendHealthSnapshot {
        guard livenessStatusCode == 200 else {
            throw BackendHealthError.unexpectedHTTPStatus(livenessStatusCode)
        }

        let liveness = try JSONDecoder().decode(LivenessPayload.self, from: livenessData)
        guard liveness.status == "ok", liveness.service == "atheer-api" else {
            throw BackendHealthError.invalidPayload
        }

        guard readinessStatusCode == 200 || readinessStatusCode == 503 else {
            throw BackendHealthError.unexpectedHTTPStatus(readinessStatusCode)
        }

        let readiness = try JSONDecoder().decode(ReadinessPayload.self, from: readinessData)
        guard readiness.service == liveness.service else {
            throw BackendHealthError.invalidPayload
        }

        let expectedStatusCode: Int
        switch readiness.status {
        case "ready": expectedStatusCode = 200
        case "not_ready": expectedStatusCode = 503
        default: throw BackendHealthError.invalidPayload
        }

        guard readinessStatusCode == expectedStatusCode else {
            throw BackendHealthError.invalidPayload
        }

        return BackendHealthSnapshot(
            version: liveness.version,
            platformReady: readiness.status == "ready",
            persistenceStatus: readiness.dependencies.persistence,
            brokerStatus: readiness.dependencies.broker,
            tradingEnabled: readiness.trading.enabled,
            tradingStatus: readiness.trading.status,
            lastCheckedAt: readiness.timestamp
        )
    }
}

private struct LivenessPayload: Decodable {
    let status: String
    let service: String
    let version: String
    let timestamp: String
}

private struct ReadinessPayload: Decodable {
    let status: String
    let service: String
    let timestamp: String
    let dependencies: Dependencies
    let trading: Trading

    struct Dependencies: Decodable {
        let persistence: String
        let broker: String
    }

    struct Trading: Decodable {
        let enabled: Bool
        let status: String
    }
}
