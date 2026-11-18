import Combine
import Foundation

enum MarketChartLoadState: Equatable {
    case idle, loading, loaded, empty
    case unavailable(String)
    case failed(String)

    var statusTitle: String {
        switch self {
        case .idle: return "SELECT INSTRUMENT"
        case .loading: return "LOADING"
        case .loaded: return "HISTORICAL DEMO"
        case .empty: return "NO CANDLES"
        case .unavailable: return "UNAVAILABLE"
        case .failed: return "ERROR"
        }
    }
}

@MainActor
final class MarketChartViewModel: ObservableObject {
    @Published private(set) var selectedInstrumentId: String?
    @Published private(set) var resolution: HistoricalPriceResolution = .minute
    @Published var priceSide: HistoricalPriceSide = .bid
    @Published private(set) var candles: [NormalizedHistoricalCandle] = []
    @Published private(set) var batch: HistoricalCandleBatch?
    @Published private(set) var state: MarketChartLoadState = .idle
    @Published private(set) var lastUpdatedAt: Date?

    private let client: MarketHistoryClient
    private var requestGeneration: UInt64 = 0

    init(client: MarketHistoryClient? = nil) {
        self.client = client ?? URLSessionMarketHistoryClient()
    }

    var requestKey: String { "\(selectedInstrumentId ?? "none")|\(resolution.rawValue)" }

    func synchronizeWatchlist(_ epics: [String]) {
        let validEpics = epics.filter {
            $0.range(of: "^[A-Za-z0-9_.-]{1,64}$", options: .regularExpression) != nil
        }
        if let selectedInstrumentId, validEpics.contains(selectedInstrumentId) { return }
        selectInstrument(validEpics.first)
    }

    func selectInstrument(_ instrumentId: String?) {
        let normalized = instrumentId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let valid = normalized.flatMap {
            $0.range(of: "^[A-Za-z0-9_.-]{1,64}$", options: .regularExpression) != nil ? $0 : nil
        }
        guard selectedInstrumentId != valid else { return }
        requestGeneration &+= 1
        selectedInstrumentId = valid
        candles = []
        batch = nil
        lastUpdatedAt = nil
        state = valid == nil
            ? .unavailable("Add an instrument to Market Watch before loading historical chart data.")
            : .idle
    }

    func selectResolution(_ newResolution: HistoricalPriceResolution) {
        guard resolution != newResolution else { return }
        requestGeneration &+= 1
        resolution = newResolution
        candles = []
        batch = nil
        lastUpdatedAt = nil
        state = .idle
    }

    func load() async {
        guard let instrumentId = selectedInstrumentId else {
            state = .unavailable("Add an instrument to Market Watch before loading historical chart data.")
            return
        }
        requestGeneration &+= 1
        let generation = requestGeneration
        let requestedResolution = resolution
        state = .loading
        do {
            let result = try await client.fetchHistory(
                instrumentId: instrumentId,
                resolution: requestedResolution,
                maximum: 500
            )
            guard generation == requestGeneration,
                  selectedInstrumentId == instrumentId,
                  resolution == requestedResolution else { return }
            batch = result
            candles = result.candles
            lastUpdatedAt = Date()
            state = result.candles.isEmpty ? .empty : .loaded
        } catch {
            guard generation == requestGeneration else { return }
            if error is CancellationError || (error as? URLError)?.code == .cancelled {
                state = .idle
                return
            }
            candles = []
            batch = nil
            lastUpdatedAt = nil
            if let historyError = error as? MarketHistoryError,
               historyError == .backendNotConnected || historyError == .backendUnavailable {
                state = .unavailable(error.localizedDescription)
            } else {
                state = .failed(error.localizedDescription)
            }
        }
    }
}
