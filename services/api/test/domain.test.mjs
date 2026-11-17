import assert from "node:assert/strict";
import test from "node:test";
import {
  assetClassCode,
  brokerAccountId,
  brokerAccountReference,
  brokerId,
  brokerInstrumentId,
  compareDecimal,
  createAuditEvent,
  createBrokerOrderRecord,
  createDataProvenance,
  createExecutionEvent,
  createExecutionFill,
  createOrderIntentEnvelope,
  createReconciliationEvent,
  createRiskAssessment,
  createPositionSnapshot,
  currencyCode,
  decimalValue,
  idempotencyKey,
  instrumentId,
  instrumentSpecificationId,
  isMultipleOfIncrement,
  orderId,
  orderIntentId,
  positionId,
  quantity,
  price,
  sourceId,
  tradingEnvironment,
  unitCode,
  utcTimestamp,
  utcTimestampFromIso,
  validateAccountBalanceSnapshot,
  validateBrokerAccountIdentity,
  validateExecutionFill,
  validateBrokerOrderRecord,
  validatePositionSnapshot,
  validateInstrumentIdentity,
  validateInstrumentSpecification,
  assertTransitionAllowed,
  isTransitionAllowed,
} from "../dist/domain/index.js";

function brokerProvenance(environment = "DEMO") {
  return createDataProvenance({
    source: { sourceId: sourceId("capital.com"), sourceType: "BROKER" },
    environment: tradingEnvironment(environment),
    eventAt: utcTimestamp(1_800_000_000_000),
    receivedAt: utcTimestamp(1_800_000_000_100),
    schemaVersion: "capital-market-v1",
    normalizationVersion: "1.0.0",
    validationCode: "VALID",
    sourceRecordReference: "market:GOLD",
  });
}

function instrumentSpecification(overrides = {}) {
  const provenance = brokerProvenance();
  return {
    id: instrumentSpecificationId("spec-GOLD-v1"),
    instrumentId: instrumentId("instrument-GOLD"),
    brokerReference: {
      brokerId: brokerId("capital.com"),
      environment: "DEMO",
      brokerInstrumentId: brokerInstrumentId("GOLD"),
    },
    version: 1,
    retrievedAt: provenance.receivedAt,
    provenance,
    pricePrecision: 2,
    quantityPrecision: 2,
    priceIncrement: price("0.01", unitCode("QUOTE_TICK")),
    minimumDealSize: quantity("0.1", unitCode("CONTRACT")),
    maximumDealSize: quantity("10", unitCode("CONTRACT")),
    quantityIncrement: quantity("0.1", unitCode("CONTRACT")),
    lotSize: quantity("1", unitCode("LOT")),
    contractSize: quantity("100", unitCode("UNDERLYING_UNIT")),
    constraints: [],
    ...overrides,
  };
}

test("UTC timestamp parsing rejects impossible calendar dates and clock values", () => {
  assert.equal(
    utcTimestampFromIso("2024-02-29T23:59:59.123Z"),
    Date.parse("2024-02-29T23:59:59.123Z"),
  );
  assert.throws(() => utcTimestampFromIso("2025-02-29T12:00:00Z"), { code: "invalid_utc_timestamp" });
  assert.throws(() => utcTimestampFromIso("2026-02-31T12:00:00Z"), { code: "invalid_utc_timestamp" });
  assert.throws(() => utcTimestampFromIso("2026-04-31T12:00:00Z"), { code: "invalid_utc_timestamp" });
  assert.throws(() => utcTimestampFromIso("2026-13-01T12:00:00Z"), { code: "invalid_utc_timestamp" });
  assert.throws(() => utcTimestampFromIso("2026-01-01T24:00:00Z"), { code: "invalid_utc_timestamp" });
  assert.throws(() => utcTimestampFromIso("2026-01-01T12:60:00Z"), { code: "invalid_utc_timestamp" });
});

test("decimal values preserve exact base-10 precision without floating-point coercion", () => {
  assert.equal(decimalValue("0.1000"), "0.1");
  assert.equal(decimalValue("-0.000"), "0");
  assert.equal(compareDecimal(decimalValue("0.3"), decimalValue("0.20")), 1);
  assert.equal(isMultipleOfIncrement(decimalValue("0.30"), decimalValue("0.1")), true);
  assert.equal(isMultipleOfIncrement(decimalValue("0.35"), decimalValue("0.1")), false);
  assert.throws(() => decimalValue("1e-8"), { code: "invalid_decimal" });
  assert.throws(() => decimalValue("01.25"), { code: "invalid_decimal" });
});

test("instrument identity and broker specification keep precision, tick size, lot size and contract size distinct", () => {
  const instrument = {
    id: instrumentId("instrument-GOLD"),
    canonicalCode: "XAUUSD",
    displayName: "Gold",
    assetClassCode: assetClassCode("COMMODITY"),
  };
  validateInstrumentIdentity(instrument);
  const specification = instrumentSpecification();
  validateInstrumentSpecification(specification);
  assert.equal(specification.pricePrecision, 2);
  assert.equal(specification.priceIncrement.value, "0.01");
  assert.equal(specification.lotSize.value, "1");
  assert.equal(specification.contractSize.value, "100");
  assert.notEqual(specification.lotSize.unit, specification.contractSize.unit);
});

test("instrument specifications reject mixed quantity units and inconsistent min/max constraints", () => {
  assert.throws(
    () => validateInstrumentSpecification(
      instrumentSpecification({ quantityIncrement: quantity("0.1", unitCode("SHARES")) }),
    ),
    { code: "quantity_unit_mismatch" },
  );
  assert.throws(
    () => validateInstrumentSpecification(
      instrumentSpecification({
        minimumDealSize: quantity("5", unitCode("CONTRACT")),
        maximumDealSize: quantity("2", unitCode("CONTRACT")),
      }),
    ),
    { code: "invalid_deal_size_range" },
  );
  assert.throws(
    () => validateInstrumentSpecification(
      instrumentSpecification({ brokerReference: { ...instrumentSpecification().brokerReference, environment: "LIVE" } }),
    ),
    { code: "environment_provenance_mismatch" },
  );
});

test("broker account snapshots require matching account, environment and broker provenance", () => {
  const account = {
    id: brokerAccountId("account-demo-1"),
    brokerId: brokerId("capital.com"),
    environment: "DEMO",
    brokerAccountReference: brokerAccountReference("broker-account-ref"),
    accountCurrency: currencyCode("USD"),
  };
  validateBrokerAccountIdentity(account);
  const provenance = brokerProvenance();
  const snapshot = {
    accountId: account.id,
    environment: "DEMO",
    asOf: provenance.eventAt,
    provenance,
    balance: { amount: decimalValue("1000.25"), currency: currencyCode("USD") },
    equity: { amount: decimalValue("1012.50"), currency: currencyCode("USD") },
    availableFunds: { amount: decimalValue("900"), currency: currencyCode("USD") },
    usedMargin: { amount: decimalValue("112.50"), currency: currencyCode("USD") },
  };
  validateAccountBalanceSnapshot(account, snapshot);
  assert.throws(
    () => validateAccountBalanceSnapshot(account, { ...snapshot, environment: "LIVE" }),
    { code: "account_environment_mismatch" },
  );
});

test("order intents are immutable, versioned envelopes with a common origin and idempotency identity", () => {
  const payload = {
    operationCode: "OPEN",
    direction: "BUY",
    quantity: quantity("0.2", unitCode("CONTRACT")),
    orderTypeCode: "MARKET",
    priceParameters: [{ code: "REFERENCE_PRICE", price: price("2345.67", unitCode("USD_PER_OUNCE"), currencyCode("USD")) }],
  };
  const intent = createOrderIntentEnvelope({
    id: orderIntentId("intent-001"),
    commandId: "command-001",
    correlationId: "correlation-001",
    idempotencyKey: idempotencyKey("idempotency-001"),
    accountId: brokerAccountId("account-demo-1"),
    instrumentId: instrumentId("instrument-GOLD"),
    instrumentSpecificationId: instrumentSpecificationId("spec-GOLD-v1"),
    environment: "DEMO",
    origin: {
      kind: "AI_AGENT",
      sourceId: sourceId("agent-market-analysis"),
      agentReference: "agent-market-analysis",
      strategyReference: "strategy-breakout",
      strategyVersion: "3.2.0",
    },
    createdAt: utcTimestamp(1_800_000_000_200),
    intentVersion: 1,
    schemaVersion: "1.0.0",
    marketDataReference: "quote-snapshot-123",
    marketDataSnapshotAt: utcTimestamp(1_800_000_000_150),
    signalAt: utcTimestamp(1_800_000_000_175),
    payload,
  });
  assert.equal(intent.payload.operationCode, "OPEN");
  assert.equal(Object.isFrozen(intent), true);
  assert.equal(Object.isFrozen(intent.payload), true);
  assert.equal(Object.isFrozen(intent.payload.priceParameters), true);
  assert.throws(
    () => createOrderIntentEnvelope({
      ...intent,
      payload: { ...intent.payload, quantity: quantity("0", unitCode("CONTRACT")) },
    }),
    { code: "invalid_intent_quantity" },
  );
  assert.throws(
    () => createOrderIntentEnvelope({ ...intent, idempotencyKey: "" }),
    { code: "invalid_idempotency_key" },
  );
});

test("risk decisions are bound to an intent, policy version and source evidence", () => {
  const provenance = createDataProvenance({
    source: { sourceId: sourceId("risk-engine"), sourceType: "INTERNAL" },
    environment: "DEMO",
    eventAt: utcTimestamp(1_800_000_000_300),
    receivedAt: utcTimestamp(1_800_000_000_300),
    schemaVersion: "risk-assessment-v1",
    normalizationVersion: "1.0.0",
    validationCode: "VALID",
  });
  const assessment = createRiskAssessment({
    id: "risk-001",
    intentId: orderIntentId("intent-001"),
    policyVersion: "risk-policy-2026-11",
    outcome: "AUTHORIZED",
    evaluatedAt: provenance.eventAt,
    reasonCodes: [],
    inputReferences: ["quote-snapshot-123", "account-snapshot-456"],
    provenance,
  });
  assert.equal(assessment.outcome, "AUTHORIZED");
  assert.equal(Object.isFrozen(assessment), true);
  assert.throws(
    () => createRiskAssessment({ ...assessment, policyVersion: "" }),
    { code: "invalid_risk_policy_version" },
  );
});

test("lifecycle transitions are validated only against an explicitly supplied policy", () => {
  const policy = {
    initialStates: ["CREATED"],
    transitions: {
      CREATED: ["VALIDATED"],
      VALIDATED: ["AUTHORIZED", "REJECTED"],
    },
  };
  assert.equal(isTransitionAllowed(policy, null, "CREATED"), true);
  assert.equal(isTransitionAllowed(policy, "CREATED", "VALIDATED"), true);
  assert.equal(isTransitionAllowed(policy, "CREATED", "AUTHORIZED"), false);
  assert.throws(() => assertTransitionAllowed(policy, "CREATED", "FILLED"), {
    code: "invalid_lifecycle_transition",
  });
});

test("execution, reconciliation and audit events retain immutable provenance", () => {
  const provenance = brokerProvenance();
  const fill = {
    id: "fill-001",
    brokerId: brokerId("capital.com"),
    orderId: orderId("order-001"),
    brokerExecutionReference: "deal-001",
    environment: "DEMO",
    quantity: quantity("0.1", unitCode("CONTRACT")),
    executionPrice: price("2345.70", unitCode("USD_PER_OUNCE"), currencyCode("USD")),
    executedAt: provenance.eventAt,
    receivedAt: provenance.receivedAt,
    provenance,
  };
  const immutableFill = createExecutionFill(fill);
  validateExecutionFill(immutableFill);
  assert.equal(Object.isFrozen(immutableFill), true);

  const executionEvent = createExecutionEvent({
    id: "execution-event-001",
    aggregateId: fill.orderId,
    eventCode: "BROKER_FILL_REPORTED",
    occurredAt: provenance.eventAt,
    receivedAt: provenance.receivedAt,
    environment: "DEMO",
    provenance,
    payload: { fillId: fill.id, quantity: fill.quantity.value },
  });
  assert.equal(Object.isFrozen(executionEvent.payload), true);

  const reconciliation = createReconciliationEvent({
    id: "reconciliation-001",
    aggregateType: "ORDER",
    aggregateId: fill.orderId,
    outcomeCode: "MATCHED",
    occurredAt: provenance.eventAt,
    environment: "DEMO",
    discrepancyCodes: [],
    provenance,
  });
  assert.equal(Object.isFrozen(reconciliation), true);

  const audit = createAuditEvent({
    id: "audit-001",
    actorKind: "BROKER",
    actorId: sourceId("capital.com"),
    actionCode: "EXECUTION_RECONCILED",
    subjectType: "ORDER",
    subjectId: fill.orderId,
    outcomeCode: "SUCCESS",
    occurredAt: provenance.eventAt,
    correlationId: "correlation-001",
    environment: "DEMO",
    reasonCodes: [],
    provenance,
  });
  assert.equal(Object.isFrozen(audit), true);
});

test("broker order and position observations require matching broker provenance", () => {
  const provenance = brokerProvenance();
  const order = {
    id: orderId("order-002"),
    brokerId: brokerId("capital.com"),
    intentId: orderIntentId("intent-002"),
    accountId: brokerAccountId("account-demo-1"),
    instrumentId: instrumentId("instrument-GOLD"),
    environment: "DEMO",
    brokerOrderReference: "broker-order-002",
    brokerStatusCode: "WORKING",
    orderedQuantity: quantity("0.2", unitCode("CONTRACT")),
    filledQuantity: quantity("0", unitCode("CONTRACT")),
    observedAt: provenance.eventAt,
    provenance,
  };
  const immutableOrder = createBrokerOrderRecord(order);
  validateBrokerOrderRecord(immutableOrder);
  assert.equal(Object.isFrozen(immutableOrder), true);

  const position = {
    id: positionId("position-001"),
    brokerId: brokerId("capital.com"),
    accountId: brokerAccountId("account-demo-1"),
    instrumentId: instrumentId("instrument-GOLD"),
    environment: "DEMO",
    brokerPositionReference: "broker-position-001",
    brokerStatusCode: "OPEN",
    quantity: quantity("-0.2", unitCode("CONTRACT")),
    observedAt: provenance.eventAt,
    provenance,
  };
  const immutablePosition = createPositionSnapshot(position);
  validatePositionSnapshot(immutablePosition);
  assert.equal(Object.isFrozen(immutablePosition), true);
  assert.throws(
    () => validatePositionSnapshot({ ...position, brokerId: brokerId("other-broker") }),
    { code: "position_provenance_mismatch" },
  );
});
