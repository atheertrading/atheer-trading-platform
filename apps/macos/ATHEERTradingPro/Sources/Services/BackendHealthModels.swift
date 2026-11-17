import Foundation

struct BackendHealthSnapshot: Equatable {
    let version: String
    let platformReady: Bool
    let persistenceStatus: String
    let brokerStatus: String
    let tradingEnabled: Bool
    let tradingStatus: String
    let livenessTimestamp: String
    let readinessHTTPStatus: Int
    let lastCheckedAt: String
}

enum BackendHealthViewState: Equatable {
    case idle
    case checking
    case connected(BackendHealthSnapshot)
    case disconnected(String)
    case invalidResponse(String)
    case serverError(Int)
}

enum BackendHealthError: Error, LocalizedError {
    case unexpectedHTTPStatus(Int)
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .unexpectedHTTPStatus(let statusCode):
            return "The health endpoint returned unexpected HTTP status \(statusCode)."
        case .invalidPayload:
            return "The health API returned an invalid or inconsistent response."
        }
    }
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

        let liveness: LivenessPayload
        do {
            liveness = try JSONDecoder().decode(LivenessPayload.self, from: livenessData)
        } catch {
            throw BackendHealthError.invalidPayload
        }
        guard liveness.status == "ok", liveness.service == "atheer-api" else {
            throw BackendHealthError.invalidPayload
        }

        guard readinessStatusCode == 200 || readinessStatusCode == 503 else {
            throw BackendHealthError.unexpectedHTTPStatus(readinessStatusCode)
        }

        let readiness: ReadinessPayload
        do {
            readiness = try JSONDecoder().decode(ReadinessPayload.self, from: readinessData)
        } catch {
            throw BackendHealthError.invalidPayload
        }
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

        // A not-ready platform must never advertise trading as enabled.
        if readiness.status == "not_ready" {
            guard !readiness.trading.enabled, readiness.trading.status == "disabled" else {
                throw BackendHealthError.invalidPayload
            }
        }

        return BackendHealthSnapshot(
            version: liveness.version,
            platformReady: readiness.status == "ready",
            persistenceStatus: readiness.dependencies.persistence,
            brokerStatus: readiness.dependencies.broker,
            tradingEnabled: readiness.trading.enabled,
            tradingStatus: readiness.trading.status,
            livenessTimestamp: liveness.timestamp,
            readinessHTTPStatus: readinessStatusCode,
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
