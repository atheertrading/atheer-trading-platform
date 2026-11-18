import Combine
import Foundation

struct MarketDataStreamQuoteSnapshot: Identifiable {
    let quote: MarketDataStreamQuote
    let receivedAtUptime: TimeInterval

    var id: String { quote.instrumentId }

    var ageMilliseconds: Double? {
        guard let providerAge = quote.freshness.ageMs else { return nil }
        let elapsed = max(0, ProcessInfo.processInfo.systemUptime - receivedAtUptime) * 1_000
        return providerAge + elapsed
    }
}

@MainActor
final class MarketDataStreamViewModel: ObservableObject {
    @Published private(set) var status: MarketDataStreamStatus?
    @Published private(set) var quotes: [String: MarketDataStreamQuoteSnapshot] = [:]
    @Published private(set) var selectedEpics: Set<String> = []
    @Published private(set) var connectionState: MarketDataStreamConnectionState = .disconnected
    @Published private(set) var isMonitoring = false
    @Published private(set) var lastError: String?
    @Published private(set) var ageRevision = 0

    private let client: MarketDataStreamClient
    private let maximumInstrumentCount = 40
    private var streamTask: Task<Void, Never>?
    private var ageTask: Task<Void, Never>?
    private var generation = 0

    init(client: MarketDataStreamClient) {
        self.client = client
    }

    var selectedCount: Int { selectedEpics.count }

    var canStartMonitoring: Bool {
        !selectedEpics.isEmpty && !isMonitoring
    }

    func isSelected(_ epic: String) -> Bool {
        selectedEpics.contains(epic)
    }

    func canSelect(_ epic: String) -> Bool {
        isSelected(epic) || selectedEpics.count < maximumInstrumentCount
    }

    func toggleSelection(_ epic: String) {
        let normalized = epic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }

        let shouldRestart = isMonitoring
        if selectedEpics.contains(normalized) {
            selectedEpics.remove(normalized)
            quotes.removeValue(forKey: normalized)
        } else {
            guard selectedEpics.count < maximumInstrumentCount else {
                lastError = "A maximum of 40 instruments can be monitored at once."
                return
            }
            selectedEpics.insert(normalized)
        }

        if shouldRestart {
            stopMonitoring()
            if !selectedEpics.isEmpty {
                startMonitoring()
            }
        }
        stopAgeTickerIfNoQuotes()
    }

    func startMonitoring() {
        guard !selectedEpics.isEmpty else {
            lastError = "Select at least one instrument before starting the live quote monitor."
            return
        }
        guard !isMonitoring else { return }

        streamTask?.cancel()
        generation += 1
        let requestGeneration = generation
        let epics = selectedEpics.sorted()

        isMonitoring = true
        status = nil
        connectionState = .connecting
        lastError = nil
        streamTask = Task { [weak self] in
            guard let self else { return }
            await self.consumeStream(epics: epics, generation: requestGeneration)
        }
    }

    func stopMonitoring(clearQuotes: Bool = false) {
        generation += 1
        streamTask?.cancel()
        streamTask = nil
        isMonitoring = false
        status = nil
        connectionState = .disconnected
        lastError = nil

        if clearQuotes {
            quotes.removeAll()
            status = nil
            stopAgeTicker()
        }
    }

    func clearSelection() {
        stopMonitoring(clearQuotes: true)
        selectedEpics.removeAll()
    }

    private func consumeStream(epics: [String], generation requestGeneration: Int) async {
        defer {
            if requestGeneration == generation {
                streamTask = nil
            }
        }

        var retryAttempt = 0
        while !Task.isCancelled && requestGeneration == generation {
            do {
                for try await event in client.events(for: epics) {
                    guard !Task.isCancelled, requestGeneration == generation else { return }
                    apply(event)
                }

                guard !Task.isCancelled, requestGeneration == generation else { return }
                throw MarketDataStreamError.streamEnded
            } catch {
                guard !Task.isCancelled, requestGeneration == generation else { return }

                lastError = error.localizedDescription
                connectionState = .degraded
                guard shouldRetry(error) else {
                    isMonitoring = false
                    return
                }

                let delaySeconds = min(1 << min(retryAttempt, 5), 30)
                retryAttempt += 1
                do {
                    try await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
                } catch {
                    return
                }
                guard !Task.isCancelled, requestGeneration == generation else { return }
                connectionState = .connecting
            }
        }
    }

    private func apply(_ event: MarketDataStreamEvent) {
        switch event {
        case .status(let newStatus):
            status = newStatus
            connectionState = newStatus.state
            if newStatus.state == .connected {
                lastError = nil
            } else {
                lastError = newStatus.lastError
            }

        case .quote(let quote):
            guard selectedEpics.contains(quote.instrumentId) else { return }
            if connectionState == .connecting {
                connectionState = .connected
            }
            quotes[quote.instrumentId] = MarketDataStreamQuoteSnapshot(
                quote: quote,
                receivedAtUptime: ProcessInfo.processInfo.systemUptime
            )
            startAgeTickerIfNeeded()
        }
    }

    private func shouldRetry(_ error: Error) -> Bool {
        guard let streamError = error as? MarketDataStreamError else {
            if let urlError = error as? URLError {
                return urlError.code != .cancelled
            }
            return true
        }

        switch streamError {
        case .streamEnded:
            return true
        case .unexpectedHTTPStatus(let status):
            return status == 429 || status >= 500 && status != 503
        case .invalidURL, .invalidResponse, .providerUnavailable:
            return false
        }
    }

    private func startAgeTickerIfNeeded() {
        guard ageTask == nil else { return }
        ageTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                self?.ageRevision += 1
            }
        }
    }

    private func stopAgeTickerIfNoQuotes() {
        guard quotes.isEmpty else { return }
        stopAgeTicker()
    }

    private func stopAgeTicker() {
        ageTask?.cancel()
        ageTask = nil
    }
}
