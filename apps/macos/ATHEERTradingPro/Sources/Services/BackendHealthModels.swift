import Foundation

struct BackendLivenessSnapshot: Equatable {
    let version: String
    let timestamp: String
}

enum BackendHealthFailure: Equatable {
    case transport(String)
    case invalidResponse(String)
    case serverError(Int)

    var message: String {
        switch self {
        case .transport(let message):
            return message
        case .invalidResponse(let message):
            return message
        case .serverError(let statusCode):
            return "The readiness endpoint returned unexpected HTTP status \(statusCode)."
        }
    }
}

struct BackendHealthSnapshot: Equatable {
    let version: String
    let livenessTimestamp: String
    let platformReady: Bool?
    let persistenceStatus: String?
    let brokerStatus: String?
    let tradingEnabled: Bool?
    let tradingStatus: String?
    let readinessHTTPStatus: Int?
    let readinessTimestamp: String?
    let readinessFailure: BackendHealthFailure?
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

    var failure: BackendHealthFailure {
        switch self {
        case .unexpectedHTTPStatus(let statusCode):
            return .serverError(statusCode)
        case .invalidPayload:
            return .invalidResponse(localizedDescription)
        }
    }
}

struct BackendHealthPayloadDecoder {
    func decodeLiveness(data: Data, statusCode: Int) throws -> BackendLivenessSnapshot {
        guard statusCode == 200 else {
            throw BackendHealthError.unexpectedHTTPStatus(statusCode)
        }

        let payload: LivenessPayload
        do {
            payload = try JSONDecoder().decode(LivenessPayload.self, from: data)
        } catch {
            throw BackendHealthError.invalidPayload
        }
        guard payload.status == "ok", payload.service == "atheer-api" else {
            throw BackendHealthError.invalidPayload
        }

        return BackendLivenessSnapshot(version: payload.version, timestamp: payload.timestamp)
    }

    func decodeReadiness(
        liveness: BackendLivenessSnapshot,
        data: Data,
        statusCode: Int
    ) throws -> BackendHealthSnapshot {
        guard statusCode == 200 || statusCode == 503 else {
            throw BackendHealthError.unexpectedHTTPStatus(statusCode)
        }

        let payload: ReadinessPayload
        do {
            payload = try JSONDecoder().decode(ReadinessPayload.self, from: data)
        } catch {
            throw BackendHealthError.invalidPayload
        }
        guard payload.service == "atheer-api" else {
            throw BackendHealthError.invalidPayload
        }

        let expectedStatusCode: Int
        switch payload.status {
        case "ready": expectedStatusCode = 200
        case "not_ready": expectedStatusCode = 503
        default: throw BackendHealthError.invalidPayload
        }

        guard statusCode == expectedStatusCode else {
            throw BackendHealthError.invalidPayload
        }

        // A not-ready platform must never advertise trading as enabled.
        if payload.status == "not_ready" {
            guard !payload.trading.enabled, payload.trading.status == "disabled" else {
                throw BackendHealthError.invalidPayload
            }
        }

        return BackendHealthSnapshot(
            version: liveness.version,
            livenessTimestamp: liveness.timestamp,
            platformReady: payload.status == "ready",
            persistenceStatus: payload.dependencies.persistence,
            brokerStatus: payload.dependencies.broker,
            tradingEnabled: payload.trading.enabled,
            tradingStatus: payload.trading.status,
            readinessHTTPStatus: statusCode,
            readinessTimestamp: payload.timestamp,
            readinessFailure: nil
        )
    }

    func snapshot(
        liveness: BackendLivenessSnapshot,
        readinessFailure: BackendHealthFailure
    ) -> BackendHealthSnapshot {
        BackendHealthSnapshot(
            version: liveness.version,
            livenessTimestamp: liveness.timestamp,
            platformReady: nil,
            persistenceStatus: nil,
            brokerStatus: nil,
            tradingEnabled: nil,
            tradingStatus: nil,
            readinessHTTPStatus: nil,
            readinessTimestamp: nil,
            readinessFailure: readinessFailure
        )
    }

    func decode(
        livenessData: Data,
        livenessStatusCode: Int,
        readinessData: Data,
        readinessStatusCode: Int
    ) throws -> BackendHealthSnapshot {
        let liveness = try decodeLiveness(data: livenessData, statusCode: livenessStatusCode)
        return try decodeReadiness(liveness: liveness, data: readinessData, statusCode: readinessStatusCode)
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
