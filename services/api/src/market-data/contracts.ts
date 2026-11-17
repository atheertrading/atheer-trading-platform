import { compareDecimal, decimalValue, type DecimalValue } from "../domain/shared.ts";
export const MARKET_DATA_SCHEMA_VERSION = "2.0.0" as const;
export const MARKET_DATA_NORMALIZATION_VERSION = "2.0.0" as const;
export type MarketDataEnvironment = "DEMO";
export type MarketDataConnectionState = "disconnected" | "connecting" | "connected" | "degraded" | "stale";
export interface NormalizedQuote {
  readonly schemaVersion: typeof MARKET_DATA_SCHEMA_VERSION;
  readonly normalizationVersion: typeof MARKET_DATA_NORMALIZATION_VERSION;
  readonly provider: "capital.com";
  readonly environment: MarketDataEnvironment;
  readonly instrumentId: string;
  /** Canonical base-10 decimal strings. Never convert these to JS Number. */
  readonly bid: DecimalValue;
  readonly ask: DecimalValue;
  readonly providerTimestampMs: number;
  readonly receivedAtMs: number;
}
export interface QuoteFreshnessPolicy { readonly maximumAgeMs: number; readonly maximumFutureSkewMs: number; }
export interface QuoteFreshnessResult {
  readonly state: "fresh" | "stale" | "invalid";
  readonly ageMs: number | null;
  readonly automatedDecisionsAllowed: boolean;
  readonly reason: "within_policy" | "quote_too_old" | "provider_timestamp_in_future" | "invalid_clock" | "invalid_policy" | "invalid_quote";
}
export function normalizeCapitalQuote(payload: Readonly<Record<string, unknown>>, receivedAtMs: number): NormalizedQuote {
  const instrumentId = payload.epic;
  const bid = readPositiveDecimal(payload.bid, "bid");
  const ask = readPositiveDecimal(payload.ofr, "ask");
  const providerTimestampMs = parseProviderTimestamp(payload.timestamp);
  if (typeof instrumentId !== "string" || instrumentId.trim().length === 0) throw new Error("Capital.com quote is missing a valid epic.");
  if (compareDecimal(ask, bid) < 0) throw new Error("Capital.com quote contains an invalid ask.");
  if (!Number.isSafeInteger(receivedAtMs) || receivedAtMs <= 0) throw new Error("Local quote receipt time is invalid.");
  return { schemaVersion: MARKET_DATA_SCHEMA_VERSION, normalizationVersion: MARKET_DATA_NORMALIZATION_VERSION, provider: "capital.com", environment: "DEMO", instrumentId: instrumentId.trim(), bid, ask, providerTimestampMs, receivedAtMs };
}
export function evaluateQuoteFreshness(quote: NormalizedQuote, nowMs: number, policy: QuoteFreshnessPolicy): QuoteFreshnessResult {
  if (!Number.isSafeInteger(policy.maximumAgeMs) || policy.maximumAgeMs <= 0 || !Number.isSafeInteger(policy.maximumFutureSkewMs) || policy.maximumFutureSkewMs < 0) return { state: "invalid", ageMs: null, automatedDecisionsAllowed: false, reason: "invalid_policy" };
  if (!Number.isSafeInteger(nowMs) || nowMs <= 0) return { state: "invalid", ageMs: null, automatedDecisionsAllowed: false, reason: "invalid_clock" };
  const bid = tryPositiveDecimal(quote.bid);
  const ask = tryPositiveDecimal(quote.ask);
  if (quote.schemaVersion !== MARKET_DATA_SCHEMA_VERSION || quote.normalizationVersion !== MARKET_DATA_NORMALIZATION_VERSION || quote.provider !== "capital.com" || quote.environment !== "DEMO" || typeof quote.instrumentId !== "string" || quote.instrumentId.trim().length === 0 || bid === null || ask === null || compareDecimal(ask, bid) < 0 || !Number.isSafeInteger(quote.providerTimestampMs) || quote.providerTimestampMs <= 0 || !Number.isSafeInteger(quote.receivedAtMs) || quote.receivedAtMs <= 0 || quote.receivedAtMs > nowMs + policy.maximumFutureSkewMs) return { state: "invalid", ageMs: null, automatedDecisionsAllowed: false, reason: "invalid_quote" };
  const ageMs = nowMs - quote.providerTimestampMs;
  if (ageMs < -policy.maximumFutureSkewMs) return { state: "invalid", ageMs, automatedDecisionsAllowed: false, reason: "provider_timestamp_in_future" };
  if (ageMs > policy.maximumAgeMs) return { state: "stale", ageMs, automatedDecisionsAllowed: false, reason: "quote_too_old" };
  return { state: "fresh", ageMs: Math.max(0, ageMs), automatedDecisionsAllowed: true, reason: "within_policy" };
}
function readPositiveDecimal(value: unknown, field: string): DecimalValue {
  if (typeof value !== "string") throw new Error("Capital.com quote contains an invalid " + field + ".");
  const decimal = decimalValue(value);
  if (compareDecimal(decimal, decimalValue("0")) <= 0) throw new Error("Capital.com quote contains an invalid " + field + ".");
  return decimal;
}
function tryPositiveDecimal(value: unknown): DecimalValue | null {
  if (typeof value !== "string") return null;
  try { const decimal = decimalValue(value); return compareDecimal(decimal, decimalValue("0")) > 0 ? decimal : null; } catch { return null; }
}
function parseProviderTimestamp(value: unknown): number {
  if (typeof value !== "string" || !/^\d{1,16}$/.test(value)) throw new Error("Capital.com quote contains an invalid provider timestamp.");
  const timestamp = Number(value);
  if (!Number.isSafeInteger(timestamp) || timestamp <= 0) throw new Error("Capital.com quote contains an invalid provider timestamp.");
  return timestamp;
}
