export type HistoricalPriceResolution =
  | "MINUTE"
  | "MINUTE_5"
  | "MINUTE_15"
  | "MINUTE_30"
  | "HOUR"
  | "HOUR_4"
  | "DAY"
  | "WEEK";

export interface HistoricalOHLC {
  readonly open: number;
  readonly high: number;
  readonly low: number;
  readonly close: number;
}

export interface NormalizedHistoricalCandle {
  readonly provider: "capital.com";
  readonly environment: "DEMO";
  readonly instrumentId: string;
  readonly resolution: HistoricalPriceResolution;
  readonly timestampMs: number;
  readonly bid: HistoricalOHLC;
  readonly ask: HistoricalOHLC;
  /** Raw provider-reported lastTradedVolume; no inferred volume semantics. */
  readonly providerVolume?: number;
  readonly providerVolumeField?: "lastTradedVolume";
  readonly receivedAtMs: number;
}

export interface ObservedCandleGap {
  readonly previousTimestampMs: number;
  readonly nextTimestampMs: number;
  readonly nominalIntervalsMissing: number;
  readonly classification: "requires_market_session_calendar";
}

export interface HistoricalCandleQuality {
  readonly receivedCount: number;
  readonly normalizedCount: number;
  readonly duplicateCount: number;
  readonly observedGaps: readonly ObservedCandleGap[];
}

export interface HistoricalCandleBatch {
  readonly provider: "capital.com";
  readonly environment: "DEMO";
  readonly instrumentId: string;
  readonly resolution: HistoricalPriceResolution;
  readonly candles: readonly NormalizedHistoricalCandle[];
  readonly quality: HistoricalCandleQuality;
}

const RESOLUTION_INTERVAL_MS: Readonly<Record<HistoricalPriceResolution, number>> = {
  MINUTE: 60_000,
  MINUTE_5: 5 * 60_000,
  MINUTE_15: 15 * 60_000,
  MINUTE_30: 30 * 60_000,
  HOUR: 60 * 60_000,
  HOUR_4: 4 * 60 * 60_000,
  DAY: 24 * 60 * 60_000,
  WEEK: 7 * 24 * 60 * 60_000,
};

type UnknownRecord = Readonly<Record<string, unknown>>;

export function normalizeCapitalHistoricalPrices(
  epic: string,
  resolution: HistoricalPriceResolution,
  prices: readonly UnknownRecord[],
  receivedAtMs: number,
): HistoricalCandleBatch {
  const instrumentId = epic.trim();
  if (!/^[A-Za-z0-9_.-]{1,64}$/.test(instrumentId)) {
    throw new Error("Historical price instrument epic is invalid.");
  }
  if (!Number.isSafeInteger(receivedAtMs) || receivedAtMs <= 0) {
    throw new Error("Historical price receipt timestamp is invalid.");
  }

  const byTimestamp = new Map<number, NormalizedHistoricalCandle>();
  let duplicateCount = 0;

  for (const price of prices) {
    const candle = normalizeCandle(instrumentId, resolution, price, receivedAtMs);
    const existing = byTimestamp.get(candle.timestampMs);
    if (existing) {
      if (!sameCandle(existing, candle)) {
        throw new Error("Capital.com returned conflicting historical candles for the same UTC timestamp.");
      }
      duplicateCount += 1;
      continue;
    }
    byTimestamp.set(candle.timestampMs, candle);
  }

  const candles = [...byTimestamp.values()].sort((left, right) => left.timestampMs - right.timestampMs);
  const intervalMs = RESOLUTION_INTERVAL_MS[resolution];
  const observedGaps: ObservedCandleGap[] = [];

  for (let index = 1; index < candles.length; index += 1) {
    const previousTimestampMs = candles[index - 1].timestampMs;
    const nextTimestampMs = candles[index].timestampMs;
    const elapsedMs = nextTimestampMs - previousTimestampMs;
    if (elapsedMs > intervalMs) {
      observedGaps.push({
        previousTimestampMs,
        nextTimestampMs,
        nominalIntervalsMissing: Math.max(1, Math.round(elapsedMs / intervalMs) - 1),
        classification: "requires_market_session_calendar",
      });
    }
  }

  return {
    provider: "capital.com",
    environment: "DEMO",
    instrumentId,
    resolution,
    candles,
    quality: {
      receivedCount: prices.length,
      normalizedCount: candles.length,
      duplicateCount,
      observedGaps,
    },
  };
}

function normalizeCandle(
  instrumentId: string,
  resolution: HistoricalPriceResolution,
  payload: UnknownRecord,
  receivedAtMs: number,
): NormalizedHistoricalCandle {
  const timestampMs = parseProviderUtcTimestamp(payload.snapshotTimeUTC);
  const bid = normalizeSide(payload, "bid");
  const ask = normalizeSide(payload, "ask");

  for (const point of ["open", "high", "low", "close"] as const) {
    if (ask[point] < bid[point]) {
      throw new Error("Capital.com historical candle contains a crossed bid/ask " + point + ".");
    }
  }

  validateOHLC(bid, "bid");
  validateOHLC(ask, "ask");

  const volume = payload.lastTradedVolume;
  if (volume !== undefined && (typeof volume !== "number" || !Number.isFinite(volume) || volume < 0)) {
    throw new Error("Capital.com historical candle contains invalid lastTradedVolume.");
  }

  return {
    provider: "capital.com",
    environment: "DEMO",
    instrumentId,
    resolution,
    timestampMs,
    bid,
    ask,
    ...(typeof volume === "number"
      ? { providerVolume: volume, providerVolumeField: "lastTradedVolume" as const }
      : {}),
    receivedAtMs,
  };
}

function normalizeSide(payload: UnknownRecord, side: "bid" | "ask"): HistoricalOHLC {
  const open = readPrice(payload.openPrice, side, "openPrice");
  const high = readPrice(payload.highPrice, side, "highPrice");
  const low = readPrice(payload.lowPrice, side, "lowPrice");
  const close = readPrice(payload.closePrice, side, "closePrice");
  return { open, high, low, close };
}

function readPrice(value: unknown, side: "bid" | "ask", field: string): number {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new Error("Capital.com historical candle is missing " + field + ".");
  }
  const price = (value as Record<string, unknown>)[side];
  if (typeof price !== "number" || !Number.isFinite(price) || price <= 0) {
    throw new Error("Capital.com historical candle contains invalid " + field + "." + side + ".");
  }
  return price;
}

function validateOHLC(value: HistoricalOHLC, side: "bid" | "ask"): void {
  if (
    value.high < Math.max(value.open, value.close, value.low) ||
    value.low > Math.min(value.open, value.close, value.high)
  ) {
    throw new Error("Capital.com historical candle contains inconsistent " + side + " OHLC values.");
  }
}

function parseProviderUtcTimestamp(value: unknown): number {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?$/.test(value)) {
    throw new Error("Capital.com historical candle is missing snapshotTimeUTC.");
  }
  const timestampMs = Date.parse(value + "Z");
  if (!Number.isFinite(timestampMs)) {
    throw new Error("Capital.com historical candle has an invalid UTC timestamp.");
  }
  return timestampMs;
}

function sameCandle(left: NormalizedHistoricalCandle, right: NormalizedHistoricalCandle): boolean {
  return left.instrumentId === right.instrumentId &&
    left.resolution === right.resolution &&
    left.timestampMs === right.timestampMs &&
    left.bid.open === right.bid.open &&
    left.bid.high === right.bid.high &&
    left.bid.low === right.bid.low &&
    left.bid.close === right.bid.close &&
    left.ask.open === right.ask.open &&
    left.ask.high === right.ask.high &&
    left.ask.low === right.ask.low &&
    left.ask.close === right.ask.close &&
    left.providerVolume === right.providerVolume;
}

/**
 * API callers express date bounds as explicit UTC ISO seconds. Capital.com
 * expects the same wall-clock UTC value without the trailing Z.
 */
export function toCapitalProviderUtcDateTime(value: string): string {
  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/.test(value)) {
    throw new Error("Historical date bounds must use UTC ISO format YYYY-MM-DDTHH:mm:ssZ.");
  }
  const timestampMs = Date.parse(value);
  if (!Number.isFinite(timestampMs)) {
    throw new Error("Historical date bound is invalid.");
  }
  return value.slice(0, -1);
}

export function validateHistoricalDateRange(from: string, to: string): {
  readonly providerFrom: string;
  readonly providerTo: string;
} {
  const providerFrom = toCapitalProviderUtcDateTime(from);
  const providerTo = toCapitalProviderUtcDateTime(to);
  if (Date.parse(from) >= Date.parse(to)) {
    throw new Error("Historical date range must have from earlier than to.");
  }
  return { providerFrom, providerTo };
}
