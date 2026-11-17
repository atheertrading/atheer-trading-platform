export type MarketDataEnvironment = "DEMO";

export type MarketDataConnectionState =
  | "disconnected"
  | "connecting"
  | "connected"
  | "degraded"
  | "stale";

export interface NormalizedQuote {
  readonly provider: "capital.com";
  readonly environment: MarketDataEnvironment;
  readonly instrumentId: string;
  readonly bid: number;
  readonly ask: number;
  readonly providerTimestampMs: number;
  readonly receivedAtMs: number;
}

export interface QuoteFreshnessPolicy {
  readonly maximumAgeMs: number;
  readonly maximumFutureSkewMs: number;
}

export interface QuoteFreshnessResult {
  readonly state: "fresh" | "stale" | "invalid";
  readonly ageMs: number | null;
  readonly automatedDecisionsAllowed: boolean;
  readonly reason:
    | "within_policy"
    | "quote_too_old"
    | "provider_timestamp_in_future"
    | "invalid_clock"
    | "invalid_policy"
    | "invalid_quote";
}

/**
 * Normalizes the documented Capital.com marketData quote payload.
 * Provider timestamps are milliseconds since Unix epoch; receivedAtMs is
 * captured locally and must never be substituted for provider time.
 */
export function normalizeCapitalQuote(
  payload: Readonly<Record<string, unknown>>,
  receivedAtMs: number,
): NormalizedQuote {
  const instrumentId = payload.epic;
  const bid = payload.bid;
  const ask = payload.ofr;
  const providerTimestampMs = payload.timestamp;

  if (typeof instrumentId !== "string" || instrumentId.trim().length === 0) {
    throw new Error("Capital.com quote is missing a valid epic.");
  }
  if (typeof bid !== "number" || !Number.isFinite(bid) || bid <= 0) {
    throw new Error("Capital.com quote contains an invalid bid.");
  }
  if (typeof ask !== "number" || !Number.isFinite(ask) || ask <= 0 || ask < bid) {
    throw new Error("Capital.com quote contains an invalid ask.");
  }
  if (
    typeof providerTimestampMs !== "number" ||
    !Number.isSafeInteger(providerTimestampMs) ||
    providerTimestampMs <= 0
  ) {
    throw new Error("Capital.com quote contains an invalid provider timestamp.");
  }
  if (!Number.isSafeInteger(receivedAtMs) || receivedAtMs <= 0) {
    throw new Error("Local quote receipt time is invalid.");
  }

  return {
    provider: "capital.com",
    environment: "DEMO",
    instrumentId: instrumentId.trim(),
    bid,
    ask,
    providerTimestampMs,
    receivedAtMs,
  };
}

export function evaluateQuoteFreshness(
  quote: NormalizedQuote,
  nowMs: number,
  policy: QuoteFreshnessPolicy,
): QuoteFreshnessResult {
  if (
    !Number.isSafeInteger(policy.maximumAgeMs) ||
    policy.maximumAgeMs <= 0 ||
    !Number.isSafeInteger(policy.maximumFutureSkewMs) ||
    policy.maximumFutureSkewMs < 0
  ) {
    return {
      state: "invalid",
      ageMs: null,
      automatedDecisionsAllowed: false,
      reason: "invalid_policy",
    };
  }
  if (!Number.isSafeInteger(nowMs) || nowMs <= 0) {
    return {
      state: "invalid",
      ageMs: null,
      automatedDecisionsAllowed: false,
      reason: "invalid_clock",
    };
  }
  if (
    quote.provider !== "capital.com" ||
    quote.environment !== "DEMO" ||
    typeof quote.instrumentId !== "string" ||
    quote.instrumentId.trim().length === 0 ||
    !Number.isFinite(quote.bid) ||
    quote.bid <= 0 ||
    !Number.isFinite(quote.ask) ||
    quote.ask < quote.bid ||
    !Number.isSafeInteger(quote.providerTimestampMs) ||
    quote.providerTimestampMs <= 0 ||
    !Number.isSafeInteger(quote.receivedAtMs) ||
    quote.receivedAtMs <= 0 ||
    quote.receivedAtMs > nowMs + policy.maximumFutureSkewMs
  ) {
    return {
      state: "invalid",
      ageMs: null,
      automatedDecisionsAllowed: false,
      reason: "invalid_quote",
    };
  }

  const ageMs = nowMs - quote.providerTimestampMs;
  if (ageMs < -policy.maximumFutureSkewMs) {
    return {
      state: "invalid",
      ageMs,
      automatedDecisionsAllowed: false,
      reason: "provider_timestamp_in_future",
    };
  }
  if (ageMs > policy.maximumAgeMs) {
    return {
      state: "stale",
      ageMs,
      automatedDecisionsAllowed: false,
      reason: "quote_too_old",
    };
  }
  return {
    state: "fresh",
    ageMs: Math.max(0, ageMs),
    automatedDecisionsAllowed: true,
    reason: "within_policy",
  };
}
