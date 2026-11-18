import Combine
import Foundation

enum CommandCenterMarketDataState: Equatable {
    case notChecked
    case checking
    case available(MarketDataBackendStatus)
    case unavailable(String)
}

/// Owns the Command Center's read-only market-data status request.
/// It consumes the existing market-data status contract and never creates a broker session.
@MainActor
final class CommandCenterStatusViewModel: ObservableObject {
    @Published private(set) var marketDataState: CommandCenterMarketDataState = .notChecked

    private let client: MarketSearchClient

    init(client: MarketSearchClient) {
        self.client = client
    }

    func refresh() async {
        guard marketDataState != .checking else { return }
        marketDataState = .checking

        do {
            let status = try await client.fetchBackendStatus()
            guard !Task.isCancelled else {
                marketDataState = .notChecked
                return
            }
            marketDataState = .available(status)
        } catch {
            if Task.isCancelled {
                marketDataState = .notChecked
            } else {
                marketDataState = .unavailable(error.localizedDescription)
            }
        }
    }
}

enum CommandCenterStatusTone: Equatable {
    case neutral
    case positive
    case attention
    case danger
}

struct CommandCenterStatusCard: Equatable, Identifiable {
    let id: String
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let tone: CommandCenterStatusTone
}

/// Pure projection of existing backend contracts into the four Command Center status cards.
/// Missing account, broker or authorization facts remain explicitly unverified.
struct CommandCenterStatusPresentation: Equatable {
    let marketData: CommandCenterStatusCard
    let broker: CommandCenterStatusCard
    let account: CommandCenterStatusCard
    let execution: CommandCenterStatusCard

    init(
        marketDataState: CommandCenterMarketDataState,
        backendHealthState: BackendHealthViewState
    ) {
        marketData = Self.marketDataCard(for: marketDataState)
        broker = Self.brokerCard(for: backendHealthState)
        account = CommandCenterStatusCard(
            id: "account",
            title: "ACCOUNT",
            value: "NO SNAPSHOT",
            detail: "The current backend health contract does not expose an account snapshot.",
            symbol: "person.crop.rectangle",
            tone: .neutral
        )
        execution = Self.executionCard(for: backendHealthState)
    }

    private static func marketDataCard(
        for state: CommandCenterMarketDataState
    ) -> CommandCenterStatusCard {
        switch state {
        case .notChecked:
            return CommandCenterStatusCard(
                id: "market-data",
                title: "MARKET DATA",
                value: "NOT CHECKED",
                detail: "Backend market-data session status has not been requested.",
                symbol: "questionmark.circle",
                tone: .neutral
            )
        case .checking:
            return CommandCenterStatusCard(
                id: "market-data",
                title: "MARKET DATA",
                value: "CHECKING",
                detail: "Requesting the existing backend market-data status contract.",
                symbol: "arrow.triangle.2.circlepath",
                tone: .attention
            )
        case .unavailable(let message):
            return CommandCenterStatusCard(
                id: "market-data",
                title: "MARKET DATA",
                value: "UNAVAILABLE",
                detail: message,
                symbol: "exclamationmark.triangle",
                tone: .attention
            )
        case .available(let status):
            let provenance = "\(status.provider) · \(status.environment)"
            let value: String
            let detail: String
            let symbol: String
            let tone: CommandCenterStatusTone

            switch status.state {
            case .notConfigured:
                value = "NOT CONFIGURED"
                detail = "\(provenance) credentials are not configured in the backend."
                symbol = "exclamationmark.triangle"
                tone = .attention
            case .disconnected:
                value = "DISCONNECTED"
                detail = "\(provenance) REST session is disconnected."
                symbol = "xmark.circle"
                tone = .danger
            case .connecting:
                value = "CONNECTING"
                detail = "\(provenance) REST session is connecting."
                symbol = "arrow.triangle.2.circlepath"
                tone = .attention
            case .connected:
                value = "REST CONNECTED"
                detail = "\(provenance) REST session is connected; streaming is a separate capability."
                symbol = "checkmark.circle"
                tone = .positive
            case .degraded:
                value = "DEGRADED"
                detail = "\(provenance) backend reports a degraded market-data session."
                symbol = "exclamationmark.triangle"
                tone = .attention
            case .stale:
                value = "STALE"
                detail = "\(provenance) backend reports stale market-data state."
                symbol = "clock.badge.exclamationmark"
                tone = .attention
            case .error:
                value = "ERROR"
                detail = "\(provenance) backend reports a market-data session error."
                symbol = "xmark.octagon"
                tone = .danger
            }

            return CommandCenterStatusCard(
                id: "market-data",
                title: "MARKET DATA",
                value: value,
                detail: detail,
                symbol: symbol,
                tone: tone
            )
        }
    }

    private static func brokerCard(
        for state: BackendHealthViewState
    ) -> CommandCenterStatusCard {
        guard case .connected(let snapshot) = state,
              snapshot.readinessFailure == nil,
              let rawStatus = snapshot.brokerStatus?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawStatus.isEmpty else {
            return CommandCenterStatusCard(
                id: "broker",
                title: "BROKER",
                value: "NOT VERIFIED",
                detail: "No verified broker status is available from backend readiness.",
                symbol: "questionmark.circle",
                tone: .neutral
            )
        }

        let normalized = rawStatus.lowercased().replacingOccurrences(of: " ", with: "_")
        let value: String
        let detail: String
        let symbol: String
        let tone: CommandCenterStatusTone

        switch normalized {
        case "connected":
            value = "CONNECTED"
            detail = "Backend readiness reports the broker session connected."
            symbol = "checkmark.circle"
            tone = .positive
        case "not_configured":
            value = "NOT CONFIGURED"
            detail = "Backend readiness reports no broker session configured."
            symbol = "exclamationmark.triangle"
            tone = .attention
        case "disconnected":
            value = "DISCONNECTED"
            detail = "Backend readiness reports the broker session disconnected."
            symbol = "xmark.circle"
            tone = .danger
        case "connecting":
            value = "CONNECTING"
            detail = "Backend readiness reports the broker session connecting."
            symbol = "arrow.triangle.2.circlepath"
            tone = .attention
        case "degraded":
            value = "DEGRADED"
            detail = "Backend readiness reports a degraded broker session."
            symbol = "exclamationmark.triangle"
            tone = .attention
        default:
            value = "UNKNOWN"
            detail = "Backend readiness returned an unrecognized broker state: \(rawStatus)."
            symbol = "questionmark.circle"
            tone = .neutral
        }

        return CommandCenterStatusCard(
            id: "broker",
            title: "BROKER",
            value: value,
            detail: detail,
            symbol: symbol,
            tone: tone
        )
    }

    private static func executionCard(
        for state: BackendHealthViewState
    ) -> CommandCenterStatusCard {
        let gate = OperationalStatusPresentation(state: state).tradingGate
        let tone: CommandCenterStatusTone
        switch gate.tone {
        case .neutral: tone = .neutral
        case .positive: tone = .positive
        case .attention: tone = .attention
        case .danger: tone = .danger
        }

        let detail: String
        switch gate.title {
        case "DISABLED":
            detail = "Backend readiness reports the trading gate disabled."
        case "ENABLED":
            detail = "Backend readiness reports enabled; this screen exposes no dealing action."
        default:
            detail = "Trading authorization is not verified by the available backend readiness response."
        }

        return CommandCenterStatusCard(
            id: "execution",
            title: "EXECUTION",
            value: gate.title,
            detail: detail,
            symbol: gate.symbol,
            tone: tone
        )
    }
}
