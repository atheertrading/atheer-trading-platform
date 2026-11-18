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
  readonly normalAgeMs: number;
  readonly automatedEntryBlockAgeMs: number;
  readonly staleAgeMs: number;
  readonly maximumFutureSkewMs: number;
}

export interface QuoteFreshnessResult {
  readonly state: "fresh" | "aging" | "entry_blocked" | "stale" | "invalid";
  readonly ageMs: number | null;
  /** Entry-specific gate; position management requires separate risk handling. */
  readonly newAutomatedEntriesAllowed: boolean;
  readonly reason:
    | "within_normal_range"
    | "quote_aging"
    | "automated_entries_blocked"
    | "quote_stale"
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

function invalidFreshness(
  reason: "invalid_policy" | "invalid_clock" | "invalid_quote" | "provider_timestamp_in_future",
  ageMs: number | null = null,
): QuoteFreshnessResult {
  return {
    state: "invalid",
    ageMs,
    newAutomatedEntriesAllowed: false,
    reason,
  };
}

export function evaluateQuoteFreshness(
  quote: NormalizedQuote,
  nowMs: number,
  policy: QuoteFreshnessPolicy,
): QuoteFreshnessResult {
  const policyIsValid =
    Number.isSafeInteger(policy.normalAgeMs) &&
    policy.normalAgeMs > 0 &&
    Number.isSafeInteger(policy.automatedEntryBlockAgeMs) &&
    policy.automatedEntryBlockAgeMs > policy.normalAgeMs &&
    Number.isSafeInteger(policy.staleAgeMs) &&
    policy.staleAgeMs > policy.automatedEntryBlockAgeMs &&
    Number.isSafeInteger(policy.maximumFutureSkewMs) &&
    policy.maximumFutureSkewMs >= 0;

  if (!policyIsValid) return invalidFreshness("invalid_policy");
  if (!Number.isSafeInteger(nowMs) || nowMs <= 0) {
    return invalidFreshness("invalid_clock");
  }

  const quoteIsValid =
    quote.provider === "capital.com" &&
    quote.environment === "DEMO" &&
    typeof quote.instrumentId === "string" &&
    quote.instrumentId.trim().length > 0 &&
    Number.isFinite(quote.bid) &&
    quote.bid > 0 &&
    Number.isFinite(quote.ask) &&
    quote.ask >= quote.bid &&
    Number.isSafeInteger(quote.providerTimestampMs) &&
    quote.providerTimestampMs > 0 &&
    Number.isSafeInteger(quote.receivedAtMs) &&
    quote.receivedAtMs > 0 &&
    quote.receivedAtMs <= nowMs + policy.maximumFutureSkewMs;

  if (!quoteIsValid) return invalidFreshness("invalid_quote");

  const rawAgeMs = nowMs - quote.providerTimestampMs;
  if (rawAgeMs < -policy.maximumFutureSkewMs) {
    return invalidFreshness("provider_timestamp_in_future", rawAgeMs);
  }

  const ageMs = Math.max(0, rawAgeMs);
  if (ageMs > policy.staleAgeMs) {
    return {
      state: "stale",
      ageMs,
      newAutomatedEntriesAllowed: false,
      reason: "quote_stale",
    };
  }
  if (ageMs > policy.automatedEntryBlockAgeMs) {
    return {
      state: "entry_blocked",
      ageMs,
      newAutomatedEntriesAllowed: false,
      reason: "automated_entries_blocked",
    };
  }
  if (ageMs > policy.normalAgeMs) {
    return {
      state: "aging",
      ageMs,
      newAutomatedEntriesAllowed: true,
      reason: "quote_aging",
    };
  }

  return {
    state: "fresh",
    ageMs,
    newAutomatedEntriesAllowed: true,
    reason: "within_normal_range",
  };
}
