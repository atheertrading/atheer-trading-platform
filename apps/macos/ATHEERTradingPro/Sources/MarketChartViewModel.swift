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
    @Published private(set) var candles: [MarketChartCandle] = []
    @Published private(set) var batch: HistoricalCandleBatch?
    @Published private(set) var state: MarketChartLoadState = .idle
    @Published private(set) var lastUpdatedAt: Date?
    @Published private(set) var liveUpdatedAt: Date?
    @Published private(set) var liveCandleUpdateCount = 0

    private let client: MarketHistoryClient
    private let quoteEventBus: MarketDataQuoteEventBus?
    private var quoteSubscriptionID: UUID?
    private var liveCandleAggregator = LiveCandleAggregator()
    private var workingCandles: [MarketChartCandle] = []
    private var livePresentationTask: Task<Void, Never>?
    private var pendingLiveUpdatedAt: Date?
    private var pendingLiveUpdateCount = 0
    private var requestGeneration: UInt64 = 0

    init(
        client: MarketHistoryClient? = nil,
        quoteEventBus: MarketDataQuoteEventBus? = nil
    ) {
        self.client = client ?? URLSessionMarketHistoryClient()
        self.quoteEventBus = quoteEventBus
        if let quoteEventBus {
            quoteSubscriptionID = quoteEventBus.subscribe { [weak self] quote in
                self?.ingestLiveQuote(quote)
            }
        }
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
        workingCandles = []
        batch = nil
        lastUpdatedAt = nil
        resetLivePresentation()
        state = valid == nil
            ? .unavailable("Add an instrument to Market Watch before loading historical chart data.")
            : .idle
    }

    func selectResolution(_ newResolution: HistoricalPriceResolution) {
        guard resolution != newResolution else { return }
        requestGeneration &+= 1
        resolution = newResolution
        candles = []
        workingCandles = []
        batch = nil
        lastUpdatedAt = nil
        resetLivePresentation()
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
        resetLivePresentation()
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
            workingCandles = result.candles.map(MarketChartCandle.init(historical:))
            candles = workingCandles
            lastUpdatedAt = Date()
            state = result.candles.isEmpty ? .empty : .loaded
        } catch {
            guard generation == requestGeneration else { return }
            if error is CancellationError || (error as? URLError)?.code == .cancelled {
                state = .idle
                return
            }
            candles = []
            workingCandles = []
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
    
    private func ingestLiveQuote(_ quote: MarketDataStreamQuote) {
        guard state == .loaded || state == .empty,
              let instrumentId = selectedInstrumentId,
              liveCandleAggregator.ingest(
                  quote,
                  instrumentId: instrumentId,
                  resolution: resolution,
                  candles: &workingCandles
              ) else {
            return
        }
        pendingLiveUpdatedAt = Date(timeIntervalSince1970: Double(quote.receivedAtMs) / 1_000)
        pendingLiveUpdateCount += 1
        scheduleLivePresentation()
    }

    private func scheduleLivePresentation() {
        guard livePresentationTask == nil else { return }
        livePresentationTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 100_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            self?.flushLivePresentation()
        }
    }

    private func flushLivePresentation() {
        livePresentationTask = nil
        guard pendingLiveUpdateCount > 0 else { return }
        candles = workingCandles
        liveUpdatedAt = pendingLiveUpdatedAt
        liveCandleUpdateCount += pendingLiveUpdateCount
        pendingLiveUpdatedAt = nil
        pendingLiveUpdateCount = 0
        state = .loaded
    }

    private func resetLivePresentation() {
        livePresentationTask?.cancel()
        livePresentationTask = nil
        pendingLiveUpdatedAt = nil
        pendingLiveUpdateCount = 0
        liveUpdatedAt = nil
        liveCandleUpdateCount = 0
        liveCandleAggregator.reset()
    }

}
