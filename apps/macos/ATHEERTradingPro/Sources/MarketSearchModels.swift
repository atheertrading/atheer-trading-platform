import Foundation

enum MarketDataBackendConnectionState: Equatable {
    case notConfigured
    case disconnected
    case connecting
    case connected
    case degraded
    case stale
    case error

    var displayLabel: String {
        switch self {
        case .notConfigured: return "NOT CONFIGURED"
        case .disconnected: return "DISCONNECTED"
        case .connecting: return "CONNECTING"
        case .connected: return "CONNECTED"
        case .degraded: return "DEGRADED"
        case .stale: return "STALE"
        case .error: return "ERROR"
        }
    }
}

enum MarketDataStreamConnectionState: String, Decodable, Equatable {
    case disconnected
    case connecting
    case connected
    case degraded

    var displayLabel: String {
        switch self {
        case .disconnected: return "DISCONNECTED"
        case .connecting: return "CONNECTING"
        case .connected: return "CONNECTED"
        case .degraded: return "DEGRADED"
        }
    }
}

struct MarketDataStreamingStatus: Equatable {
    let state: MarketDataStreamConnectionState
    let activeInstrumentCount: Int
    let lastMessageAtMs: Double?
    let lastError: String?
    let invalidQuoteCount: Int
    let outOfOrderQuoteCount: Int
    let duplicateQuoteCount: Int
}

struct MarketDataBackendStatus: Equatable {
    let provider: String
    let environment: String
    let state: MarketDataBackendConnectionState
    let streaming: MarketDataStreamingStatus?

    init(
        provider: String,
        environment: String,
        state: MarketDataBackendConnectionState,
        streaming: MarketDataStreamingStatus? = nil
    ) {
        self.provider = provider
        self.environment = environment
        self.state = state
        self.streaming = streaming
    }
}

struct MarketInstrumentSummary: Equatable, Identifiable {
    let epic: String
    let name: String?
    let marketStatus: String?
    let currency: String?

    var id: String { epic }
}

enum MarketSearchError: Error, LocalizedError, Equatable {
    case invalidResponse
    case unexpectedHTTPStatus(Int)
    case backendUnavailable
    case backendNotConnected

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The market-data API returned an invalid response."
        case .unexpectedHTTPStatus(let code):
            return "The market-data API returned HTTP \(code)."
        case .backendUnavailable:
            return "The backend market-data service is unavailable."
        case .backendNotConnected:
            return "The Capital.com DEMO market-data session is not connected."
        }
    }
}
