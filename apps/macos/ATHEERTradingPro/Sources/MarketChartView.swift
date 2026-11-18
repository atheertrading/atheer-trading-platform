import Charts
import SwiftUI

struct ChartWorkspaceView: View {
    @ObservedObject var model: MarketChartViewModel
    @ObservedObject var watchlistStore: MarketWatchlistStore
    let onOpenMarkets: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ATHEERDesignTokens.Spacing.section) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Charts & Analysis").font(ATHEERDesignTokens.Typography.screenTitle)
                        Text("Provider-normalized historical candles from the Capital.com DEMO market-data service.")
                            .font(ATHEERDesignTokens.Typography.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("DEMO · READ ONLY")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(0.6)
                        .foregroundColor(ATHEERDesignTokens.ColorRole.attention)
                }
                MarketChartSurfaceView(model: model, watchlistStore: watchlistStore, onOpenMarkets: onOpenMarkets)
            }
            .padding(ATHEERDesignTokens.Spacing.page)
            .frame(maxWidth: 1500, alignment: .leading)
        }
        .background(ATHEERDesignTokens.ColorRole.canvas)
    }
}

struct MarketChartSurfaceView: View {
    @ObservedObject var model: MarketChartViewModel
    @ObservedObject var watchlistStore: MarketWatchlistStore
    let onOpenMarkets: () -> Void
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            controls
            chartContent
            qualityFooter
        }
        .padding(compact ? 12 : 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ATHEERDesignTokens.ColorRole.panel)
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
            .stroke(ATHEERDesignTokens.ColorRole.separator, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .onAppear { model.synchronizeWatchlist(watchlistStore.epics) }
        .onChange(of: watchlistStore.epics) { epics in model.synchronizeWatchlist(epics) }
        .task(id: model.requestKey) { await model.load() }
    }

    private var controls: some View {
        HStack(alignment: .center, spacing: 10) {
            Picker("Instrument", selection: Binding(
                get: { model.selectedInstrumentId ?? "" },
                set: { model.selectInstrument($0.isEmpty ? nil : $0) }
            )) {
                Text("Select instrument").tag("")
                ForEach(watchlistStore.epics, id: \.self) { epic in Text(epic).tag(epic) }
            }
            .labelsHidden()
            .frame(minWidth: 150, maxWidth: 220)
            .disabled(watchlistStore.epics.isEmpty)
            .accessibilityLabel("Chart instrument")

            Picker("Resolution", selection: Binding(
                get: { model.resolution },
                set: { model.selectResolution($0) }
            )) {
                ForEach(HistoricalPriceResolution.allCases) { resolution in Text(resolution.title).tag(resolution) }
            }
            .labelsHidden()
            .frame(width: 82)
            .accessibilityLabel("Candle timeframe")

            Picker("Price side", selection: $model.priceSide) {
                ForEach(HistoricalPriceSide.allCases) { side in Text(side.title).tag(side) }
            }
            .pickerStyle(.segmented)
            .frame(width: 118)
            .accessibilityLabel("Bid or Ask candle series")

            Spacer(minLength: 4)
            Button {
                Task { await model.load() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(model.selectedInstrumentId == nil || model.state == .loading)
            .help("Reload historical DEMO candles")
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        switch model.state {
        case .loaded:
            historicalChart
        case .loading:
            VStack(spacing: 10) {
                ProgressView()
                Text("Loading timestamped DEMO candles…")
                    .font(ATHEERDesignTokens.Typography.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: compact ? 230 : 390)
        case .empty:
            emptyState(title: "No historical candles returned",
                       message: "The provider returned no candles for this instrument and timeframe. No synthetic bars are substituted.",
                       symbol: "chart.xyaxis.line")
        case .unavailable(let message), .failed(let message):
            unavailableState(message)
        case .idle:
            emptyState(title: "Select a watchlist instrument",
                       message: "Add an instrument through Market Explorer, then select it here to request its historical DEMO candles.",
                       symbol: "chart.xyaxis.line")
        }
    }

    private var historicalChart: some View {
        Chart(model.candles) { candle in
            let values = candle.values(for: model.priceSide)
            let isRising = values.close >= values.open
            let candleColor = isRising
                ? ATHEERDesignTokens.ColorRole.success
                : ATHEERDesignTokens.ColorRole.attention
            let halfWidth = Double(model.resolution.intervalMilliseconds) / 1_000 * 0.34

            RuleMark(x: .value("Time", candle.date),
                     yStart: .value("Low", values.low),
                     yEnd: .value("High", values.high))
                .foregroundStyle(candleColor)
                .lineStyle(StrokeStyle(lineWidth: 1))

            RectangleMark(
                xStart: .value("Candle start", candle.date.addingTimeInterval(-halfWidth)),
                xEnd: .value("Candle end", candle.date.addingTimeInterval(halfWidth)),
                yStart: .value("Open", max(values.open, values.close)),
                yEnd: .value("Close", min(values.open, values.close))
            )
            .foregroundStyle(candleColor)
            .cornerRadius(1)
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) {
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day().hour().minute())
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) {
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .frame(height: compact ? 260 : 430)
        .accessibilityLabel("Capital.com DEMO \(model.priceSide.title) historical candlestick chart")
    }

    private var qualityFooter: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("CAPITAL.COM · DEMO · \(model.priceSide.title) OHLC")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(ATHEERDesignTokens.ColorRole.accent)
            if let batch = model.batch {
                Text("\(batch.candles.count) CANDLES")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("\(batch.quality.duplicateCount) DUPLICATES")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("\(batch.quality.observedGaps.count) OBSERVED GAPS")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 4)
            if let lastUpdatedAt = model.lastUpdatedAt {
                Text("UPDATED \(lastUpdatedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .accessibilityElement(children: .combine)
    }

    private func emptyState(title: String, message: String, symbol: String) -> some View {
        VStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .light))
                .foregroundColor(ATHEERDesignTokens.ColorRole.accent.opacity(0.8))
            Text(title).font(.system(size: 14, weight: .semibold))
            Text(message)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 480)
            if watchlistStore.epics.isEmpty {
                Button("Open Market Explorer", action: onOpenMarkets).buttonStyle(.link)
            }
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 210 : 350)
        .padding(18)
    }

    private func unavailableState(_ message: String) -> some View {
        VStack(spacing: 9) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 25))
                .foregroundColor(ATHEERDesignTokens.ColorRole.attention)
            Text("Historical data unavailable").font(.system(size: 13, weight: .semibold))
            Text(message)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
            Button {
                Task { await model.load() }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(model.selectedInstrumentId == nil || model.state == .loading)
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 210 : 350)
        .padding(18)
    }
}
