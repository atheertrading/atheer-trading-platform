import assert from "node:assert/strict";
import test from "node:test";
import { RiskEngine } from "../dist/risk/risk-engine.js";
import {
  brokerAccountId,
  brokerAccountReference,
  brokerId,
  brokerInstrumentId,
  commandId,
  correlationId,
  createDataProvenance,
  currencyCode,
  decimalValue,
  idempotencyKey,
  instrumentId,
  instrumentSpecificationId,
  orderIntentId,
  price,
  quantity,
  riskAssessmentId,
  sourceId,
  tradingEnvironment,
  unitCode,
  utcTimestamp,
} from "../dist/domain/index.js";

const timestamp = 1_800_000_000_000;
const money = (amount) => ({ amount: decimalValue(amount), currency: currencyCode("USD") });
const provenance = (id, sourceType, time) => createDataProvenance({
  source: { sourceId: sourceId(id), sourceType },
  environment: tradingEnvironment("DEMO"),
  eventAt: utcTimestamp(time),
  receivedAt: utcTimestamp(time),
  schemaVersion: "1.0",
  normalizationVersion: "1.0",
  validationCode: "VALID",
});

function fixtures() {
  const account = {
    id: brokerAccountId("risk-account"),
    brokerId: brokerId("capital-com"),
    environment: tradingEnvironment("DEMO"),
    brokerAccountReference: brokerAccountReference("demo-account"),
    accountCurrency: currencyCode("USD"),
  };
  const instrument = {
    id: instrumentId("risk-instrument"),
    canonicalCode: "EURUSD",
    displayName: "EUR/USD",
    assetClassCode: "FX",
  };
  const specification = {
    id: instrumentSpecificationId("risk-spec"),
    instrumentId: instrument.id,
    brokerReference: {
      brokerId: account.brokerId,
      environment: tradingEnvironment("DEMO"),
      brokerInstrumentId: brokerInstrumentId("EURUSD"),
    },
    version: 1,
    retrievedAt: utcTimestamp(timestamp - 60_000),
    provenance: provenance("capital-com", "BROKER", timestamp - 60_000),
    pricePrecision: 2,
    quantityPrecision: 2,
    priceIncrement: price("0.01", unitCode("USD_PER_UNIT"), currencyCode("USD")),
    minimumDealSize: quantity("0.01", unitCode("CONTRACT")),
    maximumDealSize: quantity("10", unitCode("CONTRACT")),
    quantityIncrement: quantity("0.01", unitCode("CONTRACT")),
    constraints: [],
  };
  const intent = {
    id: orderIntentId("risk-intent"),
    commandId: commandId("risk-command"),
    correlationId: correlationId("risk-correlation"),
    idempotencyKey: idempotencyKey("risk-idempotency"),
    accountId: account.id,
    instrumentId: instrument.id,
    instrumentSpecificationId: specification.id,
    environment: tradingEnvironment("DEMO"),
    origin: { kind: "HUMAN", sourceId: sourceId("operator") },
    createdAt: utcTimestamp(timestamp - 1_000),
    intentVersion: 1,
    schemaVersion: "1.0",
    marketDataReference: "risk-quote",
    marketDataSnapshotAt: utcTimestamp(timestamp - 500),
    payload: {
      operationCode: "OPEN",
      direction: "BUY",
      quantity: quantity("1.00", unitCode("CONTRACT")),
      priceParameters: [{
        code: "STOP_LOSS",
        price: price("99.00", unitCode("USD_PER_UNIT"), currencyCode("USD")),
      }],
    },
  };
  const accountSnapshot = {
    accountId: account.id,
    environment: tradingEnvironment("DEMO"),
    asOf: utcTimestamp(timestamp - 1_000),
    provenance: provenance("capital-com", "BROKER", timestamp - 1_000),
    equity: money("10000"),
    availableFunds: money("8000"),
    usedMargin: money("2000"),
    availableMargin: money("8000"),
  };
  const marketQuote = {
    id: "risk-quote",
    instrumentId: instrument.id,
    environment: tradingEnvironment("DEMO"),
    bid: price("100.00", unitCode("USD_PER_UNIT"), currencyCode("USD")),
    ask: price("100.02", unitCode("USD_PER_UNIT"), currencyCode("USD")),
    provenance: {
      ...provenance("capital-market-data", "MARKET_DATA_PROVIDER", timestamp - 500),
      receivedAt: utcTimestamp(timestamp - 100),
    },
  };
  const portfolioRisk = {
    id: "risk-portfolio",
    intentId: intent.id,
    accountId: account.id,
    instrumentId: instrument.id,
    environment: tradingEnvironment("DEMO"),
    asOf: utcTimestamp(timestamp - 500),
    valuationModelVersion: "test-valuation-v1",
    projectedOpenPositions: 1,
    projectedOpenInstrumentPositions: 1,
    projectedPerTradeRisk: money("50"),
    projectedAccountGrossExposure: money("1000"),
    projectedInstrumentGrossExposure: money("500"),
    projectedDailyLoss: money("0"),
    projectedDrawdown: money("0"),
    provenance: provenance("portfolio-service", "INTERNAL", timestamp - 500),
  };
  const policy = {
    version: "risk-policy-v1",
    environment: tradingEnvironment("DEMO"),
    accountCurrency: "USD",
    allowedIntentOrigins: ["HUMAN"],
    allowedPermissionProfileReferences: [],
    riskIncreasingOperationCodes: ["OPEN"],
    requiredAccountFields: ["equity"],
    maximumOrderQuantity: quantity("5", unitCode("CONTRACT")),
    maximumOpenPositions: 3,
    maximumOpenPositionsPerInstrument: 2,
    maximumPerTradeRisk: money("100"),
    maximumAccountGrossExposure: money("5000"),
    maximumInstrumentGrossExposure: money("2000"),
    maximumDailyLoss: money("300"),
    maximumDrawdown: money("500"),
    maximumSpread: price("0.05", unitCode("USD_PER_UNIT"), currencyCode("USD")),
    freshness: {
      normalQuoteAgeMs: 5_000,
      automatedEntryBlockAfterMs: 10_000,
      staleQuoteAfterMs: 15_000,
      accountSnapshotMaxAgeMs: 5_000,
      portfolioSnapshotMaxAgeMs: 3_000,
      maximumFutureClockSkewMs: 100,
    },
    requireBrokerPriceIncrement: true,
    requireStopLoss: true,
    stopLossParameterCode: "STOP_LOSS",
    minimumAvailableFunds: money("100"),
    minimumAvailableMargin: money("100"),
    maximumUsedMargin: money("9000"),
  };
  return { account, instrument, specification, intent, accountSnapshot, marketQuote, portfolioRisk, policy };
}

function engine(data, controls = undefined) {
  let id = 0;
  return new RiskEngine(
    { async getPolicy() { return data.policy; } },
    { async loadContext() { return {
      account: data.account,
      accountSnapshot: data.accountSnapshot,
      instrument: data.instrument,
      instrumentSpecification: data.specification,
      marketQuote: data.marketQuote,
      portfolioRisk: data.portfolioRisk,
    }; } },
    controls ?? { isTradingEnabled: () => true, isEmergencyHalted: () => false },
    { now: () => utcTimestamp(timestamp) },
    { next: () => riskAssessmentId("risk-assessment-" + (++id)) },
  );
}

test("policy environment mismatch is held, not misclassified as malformed policy", async () => {
  const data = fixtures();
  data.policy.environment = tradingEnvironment("SIMULATION");
  const result = await engine(data).evaluate(data.intent);
  assert.equal(result.outcome, "HELD");
  assert.deepEqual(result.reasonCodes, ["RISK_POLICY_ENVIRONMENT_MISMATCH"]);
});

test("unauthorized origin, permission profile and operation are rejected before risk-context loading", async () => {
  const data = fixtures();
  data.intent.origin = { kind: "AI_AGENT", sourceId: sourceId("agent"), permissionProfileReference: "unapproved" };
  const result = await engine(data).evaluate(data.intent);
  assert.equal(result.outcome, "REJECTED");
  assert.ok(result.reasonCodes.includes("INTENT_ORIGIN_NOT_PERMITTED"));

  const operation = fixtures();
  operation.intent.payload.operationCode = "CLOSE_ALL";
  const operationResult = await engine(operation).evaluate(operation.intent);
  assert.equal(operationResult.outcome, "REJECTED");
  assert.ok(operationResult.reasonCodes.includes("UNSUPPORTED_RISK_OPERATION"));
});

test("missing margin fields are mandatory when corresponding policy limits are configured", async () => {
  const data = fixtures();
  data.accountSnapshot.availableFunds = undefined;
  data.policy.requiredAccountFields = ["equity"];
  const result = await engine(data).evaluate(data.intent);
  assert.equal(result.outcome, "HELD");
  assert.ok(result.reasonCodes.includes("ACCOUNT_FIELD_UNAVAILABLE:availableFunds"));
});

test("margin thresholds reject below-minimum funds/margin or above-maximum used margin", async () => {
  for (const [field, amount, code] of [
    ["availableFunds", "99.99", "MINIMUM_AVAILABLE_FUNDS_NOT_MET"],
    ["availableMargin", "99.99", "MINIMUM_AVAILABLE_MARGIN_NOT_MET"],
    ["usedMargin", "9000.01", "MAXIMUM_USED_MARGIN_EXCEEDED"],
  ]) {
    const data = fixtures();
    data.accountSnapshot[field] = money(amount);
    const result = await engine(data).evaluate(data.intent);
    assert.equal(result.outcome, "REJECTED");
    assert.ok(result.reasonCodes.includes(code));
  }
});

test("trading control provider exceptions hold the intent", async () => {
  const data = fixtures();
  const controls = {
    isEmergencyHalted: () => false,
    isTradingEnabled() { throw new Error("control service unavailable"); },
  };
  const result = await engine(data, controls).evaluate(data.intent);
  assert.equal(result.outcome, "HELD");
  assert.ok(result.reasonCodes.includes("TRADING_CONTROLS_UNAVAILABLE"));
});

test("missing broker minimum deal size and explicit order direction prevent authorization", async () => {
  const noMinimum = fixtures();
  noMinimum.specification.minimumDealSize = undefined;
  const minimumResult = await engine(noMinimum).evaluate(noMinimum.intent);
  assert.equal(minimumResult.outcome, "HELD");
  assert.ok(minimumResult.reasonCodes.includes("BROKER_MINIMUM_DEAL_SIZE_UNAVAILABLE"));

  const noDirection = fixtures();
  noDirection.intent.payload.direction = undefined;
  const directionResult = await engine(noDirection).evaluate(noDirection.intent);
  assert.equal(directionResult.outcome, "REJECTED");
  assert.ok(directionResult.reasonCodes.includes("ORDER_DIRECTION_REQUIRED"));
});
