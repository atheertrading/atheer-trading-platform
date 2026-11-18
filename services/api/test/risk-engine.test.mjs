import assert from "node:assert/strict";
import test from "node:test";
import { RiskEngine, DisabledRiskTradingControls } from "../dist/risk/risk-engine.js";
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

const NOW = 1_800_000_000_000;

function money(amount) {
  return { amount: decimalValue(amount), currency: currencyCode("USD") };
}

function provenance(source, sourceType, environment, eventAt, receivedAt = eventAt) {
  return createDataProvenance({
    source: { sourceId: sourceId(source), sourceType },
    environment: tradingEnvironment(environment),
    eventAt: utcTimestamp(eventAt),
    receivedAt: utcTimestamp(receivedAt),
    schemaVersion: "test-schema-v1",
    normalizationVersion: "1.0.0",
    validationCode: "VALID",
    sourceRecordReference: source + ":" + eventAt,
  });
}

function makeFixtures(options = {}) {
  const now = options.now ?? NOW;
  const broker = brokerId("capital-com");
  const account = {
    id: brokerAccountId("account-demo-1"),
    brokerId: broker,
    environment: tradingEnvironment("DEMO"),
    brokerAccountReference: brokerAccountReference("demo-account-reference"),
    accountCurrency: currencyCode("USD"),
  };
  const instrument = {
    id: instrumentId("instrument-eurusd"),
    canonicalCode: "EURUSD",
    displayName: "EUR/USD",
    assetClassCode: "FX",
  };
  const specificationTime = now - 60_000;
  const specification = {
    id: instrumentSpecificationId("spec-eurusd-v1"),
    instrumentId: instrument.id,
    brokerReference: {
      brokerId: broker,
      environment: tradingEnvironment("DEMO"),
      brokerInstrumentId: brokerInstrumentId("EURUSD"),
    },
    version: 1,
    retrievedAt: utcTimestamp(specificationTime),
    provenance: provenance("capital-com", "BROKER", "DEMO", specificationTime),
    pricePrecision: 2,
    quantityPrecision: 2,
    priceIncrement: price("0.01", unitCode("USD_PER_UNIT"), currencyCode("USD")),
    minimumDealSize: quantity("0.01", unitCode("CONTRACT")),
    maximumDealSize: quantity("100", unitCode("CONTRACT")),
    quantityIncrement: quantity("0.01", unitCode("CONTRACT")),
    constraints: [],
  };

  const quoteAgeMs = options.quoteAgeMs ?? 500;
  const quoteTime = now - quoteAgeMs;
  const quoteReceivedAt = Math.max(quoteTime, now - 100);
  const intent = {
    id: orderIntentId("intent-demo-1"),
    commandId: commandId("command-demo-1"),
    correlationId: correlationId("correlation-demo-1"),
    idempotencyKey: idempotencyKey("idempotency-demo-1"),
    accountId: account.id,
    instrumentId: instrument.id,
    instrumentSpecificationId: specification.id,
    environment: tradingEnvironment("DEMO"),
    origin: {
      kind: options.originKind ?? "HUMAN",
      sourceId: sourceId("test-origin"),
      ...(options.originKind && options.originKind !== "HUMAN"
        ? { permissionProfileReference: options.permissionProfileReference ?? "permission-profile-demo" }
        : {}),
    },
    createdAt: utcTimestamp(now - 1_000),
    intentVersion: 1,
    schemaVersion: "1.0.0",
    marketDataReference: "market-quote-1",
    marketDataSnapshotAt: utcTimestamp(quoteTime),
    payload: {
      operationCode: options.operationCode ?? "OPEN",
      direction: options.direction ?? "BUY",
      quantity: quantity(options.quantityValue ?? "1.00", unitCode("CONTRACT")),
      orderTypeCode: "MARKET",
      priceParameters: options.stopLoss === null ? [] : [{
        code: "STOP_LOSS",
        price: price(options.stopLoss ?? "99.00", unitCode("USD_PER_UNIT"), currencyCode("USD")),
      }],
    },
  };

  const accountTime = now - (options.accountSnapshotAgeMs ?? 1_000);
  const accountSnapshot = {
    accountId: account.id,
    environment: tradingEnvironment("DEMO"),
    asOf: utcTimestamp(accountTime),
    provenance: provenance("capital-com", "BROKER", "DEMO", accountTime),
    balance: money("10000"),
    equity: money("10000"),
    availableFunds: options.availableFunds === undefined ? money("8000") : options.availableFunds,
    usedMargin: money("2000"),
    availableMargin: money("8000"),
    realizedPnl: money("0"),
    unrealizedPnl: money("0"),
    ...options.accountSnapshotOverrides,
  };

  const bid = "100.00";
  const ask = options.ask ?? "100.02";
  const marketQuote = {
    id: "market-quote-1",
    instrumentId: instrument.id,
    environment: tradingEnvironment("DEMO"),
    bid: price(bid, unitCode("USD_PER_UNIT"), currencyCode("USD")),
    ask: price(ask, unitCode("USD_PER_UNIT"), currencyCode("USD")),
    provenance: provenance("capital-com-market-data", "MARKET_DATA_PROVIDER", "DEMO", quoteTime, quoteReceivedAt),
  };

  const portfolioTime = now - (options.portfolioSnapshotAgeMs ?? 500);
  const portfolioRisk = {
    id: "portfolio-risk-1",
    intentId: intent.id,
    accountId: account.id,
    instrumentId: instrument.id,
    environment: tradingEnvironment("DEMO"),
    asOf: utcTimestamp(portfolioTime),
    valuationModelVersion: "portfolio-valuation-v1",
    projectedOpenPositions: 2,
    projectedOpenInstrumentPositions: 1,
    projectedPerTradeRisk: money("50"),
    projectedAccountGrossExposure: money("1000"),
    projectedInstrumentGrossExposure: money("500"),
    projectedDailyLoss: money("25"),
    projectedDrawdown: money("50"),
    provenance: provenance("portfolio-risk-service", "INTERNAL", "DEMO", portfolioTime),
    ...options.portfolioOverrides,
  };

  const context = {
    account,
    accountSnapshot,
    instrument,
    instrumentSpecification: {
      ...specification,
      ...options.specificationOverrides,
    },
    marketQuote,
    portfolioRisk,
  };

  const policy = {
    version: "risk-policy-demo-v1",
    environment: tradingEnvironment("DEMO"),
    accountCurrency: "USD",
    allowedIntentOrigins: ["HUMAN", "STRATEGY", "ALGORITHM", "POSITION_MANAGEMENT", "RISK_MANAGEMENT", "AI_AGENT", "SYSTEM"],
    allowedPermissionProfileReferences: ["permission-profile-demo"],
    riskIncreasingOperationCodes: ["OPEN", "INCREASE"],
    requiredAccountFields: ["equity", "availableFunds", "availableMargin"],
    maximumOrderQuantity: quantity("5", unitCode("CONTRACT")),
    maximumOpenPositions: 3,
    maximumOpenPositionsPerInstrument: 2,
    maximumPerTradeRisk: money("100"),
    maximumAccountGrossExposure: money("5000"),
    maximumInstrumentGrossExposure: money("2000"),
    maximumDailyLoss: money("300"),
    maximumDrawdown: money("500"),
    maximumSpread: price("0.05", unitCode("USD_PER_UNIT"), currencyCode("USD")),
    minimumAvailableFunds: money("100"),
    minimumAvailableMargin: money("100"),
    maximumUsedMargin: money("9000"),
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
  };

  return { now, intent, context, policy };
}

function createEngine(fixtures, options = {}) {
  let sequence = 0;
  const policyProvider = {
    async getPolicy() {
      if (options.policyThrows) throw new Error("sensitive policy provider error");
      return options.policy === null ? undefined : (options.policy ?? fixtures.policy);
    },
  };
  const contextProvider = {
    async loadContext() {
      if (options.contextThrows) throw new Error("sensitive context provider error");
      return options.context === null ? undefined : (options.context ?? fixtures.context);
    },
  };
  const controls = options.controls ?? {
    isTradingEnabled: () => options.tradingEnabled ?? true,
    isEmergencyHalted: () => options.emergencyHalted ?? false,
  };
  return new RiskEngine(
    policyProvider,
    contextProvider,
    controls,
    { now: () => utcTimestamp(fixtures.now) },
    { next: () => riskAssessmentId("risk-assessment-" + (++sequence)) },
  );
}

test("RiskEngine authorizes only a complete, fresh, policy-compliant DEMO intent", async () => {
  const fixtures = makeFixtures();
  const assessment = await createEngine(fixtures).evaluate(fixtures.intent);

  assert.equal(assessment.outcome, "AUTHORIZED");
  assert.deepEqual(assessment.reasonCodes, []);
  assert.equal(assessment.intentId, fixtures.intent.id);
  assert.equal(assessment.policyVersion, fixtures.policy.version);
  assert.equal(assessment.provenance.source.sourceType, "INTERNAL");
  assert.equal(assessment.provenance.source.sourceId, "atheer-risk-engine");
  assert.ok(assessment.inputReferences.includes("market-quote:market-quote-1"));
  assert.ok(assessment.inputReferences.includes("portfolio-risk-snapshot:portfolio-risk-1"));
});

test("trading-disabled control fails closed without granting an AUTHORIZED assessment", async () => {
  const fixtures = makeFixtures();
  const assessment = await createEngine(fixtures, { tradingEnabled: false }).evaluate(fixtures.intent);

  assert.equal(assessment.outcome, "HELD");
  assert.ok(assessment.reasonCodes.includes("TRADING_DISABLED"));
});

test("emergency halt rejects an otherwise valid risk-increasing intent", async () => {
  const fixtures = makeFixtures();
  const assessment = await createEngine(fixtures, { emergencyHalted: true }).evaluate(fixtures.intent);

  assert.equal(assessment.outcome, "REJECTED");
  assert.ok(assessment.reasonCodes.includes("EMERGENCY_TRADING_HALT_ACTIVE"));
});

test("missing policy or unavailable context produces HELD rather than implicit authorization", async () => {
  const fixtures = makeFixtures();
  const missingPolicy = await createEngine(fixtures, { policy: null }).evaluate(fixtures.intent);
  const failedPolicy = await createEngine(fixtures, { policyThrows: true }).evaluate(fixtures.intent);
  const missingContext = await createEngine(fixtures, { context: null }).evaluate(fixtures.intent);
  const failedContext = await createEngine(fixtures, { contextThrows: true }).evaluate(fixtures.intent);

  for (const assessment of [missingPolicy, failedPolicy, missingContext, failedContext]) {
    assert.equal(assessment.outcome, "HELD");
    assert.notEqual(assessment.outcome, "AUTHORIZED");
  }
  assert.ok(missingPolicy.reasonCodes.includes("RISK_POLICY_UNAVAILABLE"));
  assert.ok(missingContext.reasonCodes.includes("RISK_CONTEXT_UNAVAILABLE"));
});

test("order quantity maximum, broker minimum, precision and increment are enforced", async () => {
  const tooLarge = makeFixtures({ quantityValue: "6.00" });
  const overLimit = await createEngine(tooLarge).evaluate(tooLarge.intent);
  assert.equal(overLimit.outcome, "REJECTED");
  assert.ok(overLimit.reasonCodes.includes("MAXIMUM_ORDER_QUANTITY_EXCEEDED"));

  const offIncrement = makeFixtures({ quantityValue: "1.005" });
  const invalidStep = await createEngine(offIncrement).evaluate(offIncrement.intent);
  assert.equal(invalidStep.outcome, "REJECTED");
  assert.ok(invalidStep.reasonCodes.includes("ORDER_QUANTITY_PRECISION_EXCEEDED"));
  assert.ok(invalidStep.reasonCodes.includes("ORDER_QUANTITY_NOT_ALIGNED_TO_INCREMENT"));

  const belowMinimum = makeFixtures({ quantityValue: "0.001" });
  const invalidMinimum = await createEngine(belowMinimum).evaluate(belowMinimum.intent);
  assert.equal(invalidMinimum.outcome, "REJECTED");
  assert.ok(invalidMinimum.reasonCodes.includes("BELOW_BROKER_MINIMUM_DEAL_SIZE"));
});

test("spread and crossed-market constraints are enforced with exact decimal arithmetic", async () => {
  const wideSpread = makeFixtures({ ask: "100.06" });
  const rejectedSpread = await createEngine(wideSpread).evaluate(wideSpread.intent);
  assert.equal(rejectedSpread.outcome, "REJECTED");
  assert.ok(rejectedSpread.reasonCodes.includes("MAXIMUM_SPREAD_EXCEEDED"));

  const crossed = makeFixtures({ ask: "99.99" });
  const rejectedCrossed = await createEngine(crossed).evaluate(crossed.intent);
  assert.equal(rejectedCrossed.outcome, "REJECTED");
  assert.ok(rejectedCrossed.reasonCodes.includes("MARKET_QUOTE_INVALID_OR_CROSSED"));
});

test("freshness policy blocks automated entries after the configured threshold and all entries when stale", async () => {
  const automated = makeFixtures({ originKind: "STRATEGY", quoteAgeMs: 10_001 });
  const blockedAutomated = await createEngine(automated).evaluate(automated.intent);
  assert.equal(blockedAutomated.outcome, "REJECTED");
  assert.ok(blockedAutomated.reasonCodes.includes("AUTOMATED_ENTRY_BLOCKED_BY_QUOTE_AGE"));

  const manualStale = makeFixtures({ originKind: "HUMAN", quoteAgeMs: 15_001 });
  const blockedStale = await createEngine(manualStale).evaluate(manualStale.intent);
  assert.equal(blockedStale.outcome, "REJECTED");
  assert.ok(blockedStale.reasonCodes.includes("MARKET_DATA_STALE"));

  const agedButWithinThreshold = makeFixtures({ originKind: "HUMAN", quoteAgeMs: 6_000 });
  const advisory = await createEngine(agedButWithinThreshold).evaluate(agedButWithinThreshold.intent);
  assert.equal(advisory.outcome, "AUTHORIZED");
  assert.ok(advisory.reasonCodes.includes("MARKET_DATA_ABOVE_NORMAL_AGE"));
});

test("account and portfolio evidence must be present, current and currency-consistent", async () => {
  const missingFunds = makeFixtures({ accountSnapshotOverrides: { availableFunds: undefined } });
  const noFundsEvidence = await createEngine(missingFunds).evaluate(missingFunds.intent);
  assert.equal(noFundsEvidence.outcome, "HELD");
  assert.ok(noFundsEvidence.reasonCodes.includes("ACCOUNT_FIELD_UNAVAILABLE:availableFunds"));

  const stalePortfolio = makeFixtures({ portfolioSnapshotAgeMs: 4_000 });
  const stalePortfolioAssessment = await createEngine(stalePortfolio).evaluate(stalePortfolio.intent);
  assert.equal(stalePortfolioAssessment.outcome, "HELD");
  assert.ok(stalePortfolioAssessment.reasonCodes.includes("PORTFOLIO_RISK_SNAPSHOT_STALE"));

  const mismatchedCurrency = makeFixtures({
    portfolioOverrides: { projectedAccountGrossExposure: { amount: decimalValue("1000"), currency: currencyCode("EUR") } },
  });
  const currencyAssessment = await createEngine(mismatchedCurrency).evaluate(mismatchedCurrency.intent);
  assert.equal(currencyAssessment.outcome, "HELD");
  assert.ok(currencyAssessment.reasonCodes.includes("PORTFOLIO_RISK_CURRENCY_MISMATCH"));
});

test("projected per-trade risk, exposure, open-position, daily-loss and drawdown limits are enforced", async () => {
  const cases = [
    [{ projectedPerTradeRisk: money("101") }, "MAXIMUM_PER_TRADE_RISK_EXCEEDED"],
    [{ projectedAccountGrossExposure: money("5001") }, "MAXIMUM_ACCOUNT_GROSS_EXPOSURE_EXCEEDED"],
    [{ projectedInstrumentGrossExposure: money("2001") }, "MAXIMUM_INSTRUMENT_GROSS_EXPOSURE_EXCEEDED"],
    [{ projectedDailyLoss: money("301") }, "MAXIMUM_DAILY_LOSS_EXCEEDED"],
    [{ projectedDrawdown: money("501") }, "MAXIMUM_DRAWDOWN_EXCEEDED"],
    [{ projectedOpenPositions: 4 }, "MAXIMUM_OPEN_POSITION_COUNT_EXCEEDED"],
    [{ projectedOpenInstrumentPositions: 3 }, "MAXIMUM_OPEN_POSITION_COUNT_EXCEEDED"],
  ];

  for (const [portfolioOverrides, expectedCode] of cases) {
    const fixtures = makeFixtures({ portfolioOverrides });
    const assessment = await createEngine(fixtures).evaluate(fixtures.intent);
    assert.equal(assessment.outcome, "REJECTED");
    assert.ok(assessment.reasonCodes.includes(expectedCode));
  }
});

test("required stop loss is present and protective relative to the provider quote", async () => {
  const absent = makeFixtures({ stopLoss: null });
  const absentAssessment = await createEngine(absent).evaluate(absent.intent);
  assert.equal(absentAssessment.outcome, "REJECTED");
  assert.ok(absentAssessment.reasonCodes.includes("REQUIRED_STOP_LOSS_MISSING"));

  const nonProtective = makeFixtures({ stopLoss: "100.01" });
  const nonProtectiveAssessment = await createEngine(nonProtective).evaluate(nonProtective.intent);
  assert.equal(nonProtectiveAssessment.outcome, "REJECTED");
  assert.ok(nonProtectiveAssessment.reasonCodes.includes("STOP_LOSS_NOT_PROTECTIVE"));
});

test("invalid portfolio provenance and missing broker price increments fail closed", async () => {
  const invalidPortfolio = makeFixtures({
    portfolioOverrides: { intentId: orderIntentId("different-intent") },
  });
  const invalidEvidence = await createEngine(invalidPortfolio).evaluate(invalidPortfolio.intent);
  assert.equal(invalidEvidence.outcome, "HELD");
  assert.ok(invalidEvidence.reasonCodes.includes("RISK_CONTEXT_INVALID"));

  const noPriceIncrement = makeFixtures({ specificationOverrides: { priceIncrement: undefined } });
  const noIncrementAssessment = await createEngine(noPriceIncrement).evaluate(noPriceIncrement.intent);
  assert.equal(noIncrementAssessment.outcome, "HELD");
  assert.ok(noIncrementAssessment.reasonCodes.includes("BROKER_PRICE_INCREMENT_UNAVAILABLE"));
});

test("disabled production trading controls cannot authorize", async () => {
  const fixtures = makeFixtures();
  const assessment = await createEngine(fixtures, { controls: new DisabledRiskTradingControls() }).evaluate(fixtures.intent);
  assert.equal(assessment.outcome, "HELD");
  assert.ok(assessment.reasonCodes.includes("TRADING_DISABLED"));
});
test("policy environment mismatch and unsupported intent authority never authorize", async () => {
  const environmentMismatch = makeFixtures();
  environmentMismatch.policy.environment = tradingEnvironment("SIMULATION");
  const mismatch = await createEngine(environmentMismatch).evaluate(environmentMismatch.intent);
  assert.equal(mismatch.outcome, "HELD");
  assert.ok(mismatch.reasonCodes.includes("RISK_POLICY_ENVIRONMENT_MISMATCH"));

  const unsupportedOperation = makeFixtures({ operationCode: "CLOSE_ALL" });
  const operationAssessment = await createEngine(unsupportedOperation).evaluate(unsupportedOperation.intent);
  assert.equal(operationAssessment.outcome, "REJECTED");
  assert.ok(operationAssessment.reasonCodes.includes("UNSUPPORTED_RISK_OPERATION"));

  const disallowedOrigin = makeFixtures({ originKind: "AI_AGENT", permissionProfileReference: "unapproved-profile" });
  const originAssessment = await createEngine(disallowedOrigin).evaluate(disallowedOrigin.intent);
  assert.equal(originAssessment.outcome, "REJECTED");
  assert.ok(originAssessment.reasonCodes.includes("PERMISSION_PROFILE_NOT_AUTHORIZED"));

  const originNotAllowed = makeFixtures();
  originNotAllowed.policy.allowedIntentOrigins = ["STRATEGY"];
  const deniedHuman = await createEngine(originNotAllowed).evaluate(originNotAllowed.intent);
  assert.equal(deniedHuman.outcome, "REJECTED");
  assert.ok(deniedHuman.reasonCodes.includes("INTENT_ORIGIN_NOT_PERMITTED"));
});

test("margin and available-funds constraints are explicit policy inputs", async () => {
  const lowFunds = makeFixtures({ availableFunds: money("99.99") });
  const fundsAssessment = await createEngine(lowFunds).evaluate(lowFunds.intent);
  assert.equal(fundsAssessment.outcome, "REJECTED");
  assert.ok(fundsAssessment.reasonCodes.includes("MINIMUM_AVAILABLE_FUNDS_NOT_MET"));

  const lowMargin = makeFixtures({ accountSnapshotOverrides: { availableMargin: money("99.99") } });
  const marginAssessment = await createEngine(lowMargin).evaluate(lowMargin.intent);
  assert.equal(marginAssessment.outcome, "REJECTED");
  assert.ok(marginAssessment.reasonCodes.includes("MINIMUM_AVAILABLE_MARGIN_NOT_MET"));

  const highUsedMargin = makeFixtures({ accountSnapshotOverrides: { usedMargin: money("9000.01") } });
  const usedMarginAssessment = await createEngine(highUsedMargin).evaluate(highUsedMargin.intent);
  assert.equal(usedMarginAssessment.outcome, "REJECTED");
  assert.ok(usedMarginAssessment.reasonCodes.includes("MAXIMUM_USED_MARGIN_EXCEEDED"));
});

test("broker minimum-deal-size metadata is required before authorization", async () => {
  const missingMinimum = makeFixtures({ specificationOverrides: { minimumDealSize: undefined } });
  const assessment = await createEngine(missingMinimum).evaluate(missingMinimum.intent);
  assert.equal(assessment.outcome, "HELD");
  assert.ok(assessment.reasonCodes.includes("BROKER_MINIMUM_DEAL_SIZE_UNAVAILABLE"));
});

test("trading-control provider failures fail closed", async () => {
  const fixtures = makeFixtures();
  const controls = {
    isTradingEnabled() { throw new Error("control service unavailable"); },
    isEmergencyHalted() { return false; },
  };
  const assessment = await createEngine(fixtures, { controls }).evaluate(fixtures.intent);
  assert.equal(assessment.outcome, "HELD");
  assert.ok(assessment.reasonCodes.includes("TRADING_CONTROLS_UNAVAILABLE"));
});
test("risk-increasing operations require an explicit BUY or SELL direction", async () => {
  const fixtures = makeFixtures();
  fixtures.intent.payload.direction = undefined;
  const assessment = await createEngine(fixtures).evaluate(fixtures.intent);
  assert.equal(assessment.outcome, "REJECTED");
  assert.ok(assessment.reasonCodes.includes("ORDER_DIRECTION_REQUIRED"));
});

test("margin policy constraints force account evidence to be present", async () => {
  const fixtures = makeFixtures({ accountSnapshotOverrides: { availableFunds: undefined } });
  fixtures.policy.requiredAccountFields = ["equity"];
  const assessment = await createEngine(fixtures).evaluate(fixtures.intent);
  assert.equal(assessment.outcome, "HELD");
  assert.ok(assessment.reasonCodes.includes("ACCOUNT_FIELD_UNAVAILABLE:availableFunds"));
});
