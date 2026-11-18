import Combine
import Foundation

/// App-scoped in-process fan-out for validated provider quote events.
/// Consumers receive every event before presentation-level coalescing.
@MainActor
final class MarketDataQuoteEventBus: ObservableObject {
    typealias Observer = (MarketDataStreamQuote) -> Void
    private var observers: [UUID: Observer] = [:]

    @discardableResult
    func subscribe(_ observer: @escaping Observer) -> UUID {
        let identifier = UUID()
        observers[identifier] = observer
        return identifier
    }

    func unsubscribe(_ identifier: UUID) {
        observers.removeValue(forKey: identifier)
    }

    func publish(_ quote: MarketDataStreamQuote) {
        let currentObservers = Array(observers.values)
        currentObservers.forEach { $0(quote) }
    }
}
