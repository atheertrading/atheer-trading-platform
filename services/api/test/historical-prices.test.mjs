import assert from "node:assert/strict";
import { test } from "node:test";
import {
  normalizeCapitalHistoricalPrices,
  toCapitalProviderUtcDateTime,
  validateHistoricalDateRange,
} from "../dist/market-data/historical-prices.js";

const receivedAtMs = Date.UTC(2026, 10, 17, 10, 2, 0);

function providerCandle(snapshotTimeUTC, offset = 0) {
  return {
    snapshotTimeUTC,
    openPrice: { bid: 100 + offset, ask: 100.2 + offset },
    highPrice: { bid: 103 + offset, ask: 103.2 + offset },
    lowPrice: { bid: 99 + offset, ask: 99.2 + offset },
    closePrice: { bid: 102 + offset, ask: 102.2 + offset },
    lastTradedVolume: 18,
  };
}

test("normalizes bid and ask OHLC independently, sorts UTC candles, and preserves provider volume lineage", () => {
  const later = providerCandle("2026-11-17T10:01:00");
  const earlier = providerCandle("2026-11-17T10:00:00");

  const batch = normalizeCapitalHistoricalPrices(
    "AAPL",
    "MINUTE",
    [later, earlier, { ...earlier }],
    receivedAtMs,
  );

  assert.equal(batch.provider, "capital.com");
  assert.equal(batch.environment, "DEMO");
  assert.equal(batch.instrumentId, "AAPL");
  assert.equal(batch.candles.length, 2);
  assert.equal(batch.candles[0].timestampMs, Date.UTC(2026, 10, 17, 10, 0, 0));
  assert.deepEqual(batch.candles[0].bid, { open: 100, high: 103, low: 99, close: 102 });
  assert.deepEqual(batch.candles[0].ask, { open: 100.2, high: 103.2, low: 99.2, close: 102.2 });
  assert.equal(batch.candles[0].providerVolume, 18);
  assert.equal(batch.candles[0].providerVolumeField, "lastTradedVolume");
  assert.equal(batch.candles[0].receivedAtMs, receivedAtMs);
  assert.equal(batch.quality.receivedCount, 3);
  assert.equal(batch.quality.normalizedCount, 2);
  assert.equal(batch.quality.duplicateCount, 1);
});

test("rejects malformed timestamps, crossed bid/ask, and inconsistent OHLC ranges", () => {
  assert.throws(
    () => normalizeCapitalHistoricalPrices("AAPL", "MINUTE", [providerCandle("2026-02-30T10:00:00")], receivedAtMs),
    /invalid UTC timestamp/,
  );

  const crossed = providerCandle("2026-11-17T10:00:00");
  crossed.closePrice.ask = 101;
  assert.throws(
    () => normalizeCapitalHistoricalPrices("AAPL", "MINUTE", [crossed], receivedAtMs),
    /crossed bid\/ask close/,
  );

  const inconsistent = providerCandle("2026-11-17T10:00:00");
  inconsistent.highPrice.bid = 98;
  assert.throws(
    () => normalizeCapitalHistoricalPrices("AAPL", "MINUTE", [inconsistent], receivedAtMs),
    /inconsistent bid OHLC/,
  );
});

test("drops exact duplicate candles but rejects conflicting duplicate timestamps", () => {
  const first = providerCandle("2026-11-17T10:00:00");
  const conflicting = providerCandle("2026-11-17T10:00:00", 1);
  assert.throws(
    () => normalizeCapitalHistoricalPrices("AAPL", "MINUTE", [first, conflicting], receivedAtMs),
    /conflicting historical candles/,
  );
});

test("reports observed time gaps without assuming market closures are missing data", () => {
  const batch = normalizeCapitalHistoricalPrices(
    "AAPL",
    "MINUTE",
    [
      providerCandle("2026-11-17T10:00:00"),
      providerCandle("2026-11-17T10:03:00"),
    ],
    receivedAtMs,
  );

  assert.equal(batch.quality.observedGaps.length, 1);
  assert.equal(batch.quality.observedGaps[0].nominalIntervalsMissing, 2);
  assert.equal(batch.quality.observedGaps[0].classification, "requires_market_session_calendar");
});

test("converts strict UTC range bounds to Capital.com UTC date-time format", () => {
  assert.equal(
    toCapitalProviderUtcDateTime("2026-11-17T10:00:00Z"),
    "2026-11-17T10:00:00",
  );
  assert.deepEqual(
    validateHistoricalDateRange("2026-11-17T10:00:00Z", "2026-11-17T11:00:00Z"),
    { providerFrom: "2026-11-17T10:00:00", providerTo: "2026-11-17T11:00:00" },
  );
  assert.throws(
    () => validateHistoricalDateRange("2026-11-17T11:00:00Z", "2026-11-17T10:00:00Z"),
    /from earlier than to/,
  );
  assert.throws(
    () => toCapitalProviderUtcDateTime("2026-11-17T10:00:00"),
    /UTC ISO format/,
  );
  assert.throws(
    () => toCapitalProviderUtcDateTime("2026-02-30T10:00:00Z"),
    /date bound is invalid/,
  );
});
