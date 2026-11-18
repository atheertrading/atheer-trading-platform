import assert from "node:assert/strict";
import test from "node:test";
import { PreTradeAuthorizationService } from "../dist/trading/pre-trade-authorization.js";
import {
  createDataProvenance,
  sourceId,
  tradingEnvironment,
  utcTimestamp,
} from "../dist/domain/shared.js";

const evaluatedAt = 1_800_000_000_500;

function makeIntent(overrides = {}) {
  return {
    id: "intent-pretrade-001",
    commandId: "command-pretrade-001",
    correlationId: "correlation-pretrade-001",
    idempotencyKey: "idempotency-pretrade-001",
    accountId: "account-demo-001",
    instrumentId: "instrument-eurusd",
    instrumentSpecificationId: "spec-eurusd-v1",
    environment: "DEMO",
    origin: { kind: "HUMAN", sourceId: "operator-001" },
    createdAt: evaluatedAt - 1_000,
    intentVersion: 1,
    schemaVersion: "1.0.0",
    payload: {
      operationCode: "OPEN",
      direction: "BUY",
      quantity: { value: "1.00", unit: "CONTRACT" },
      orderTypeCode: "MARKET",
    },
    ...overrides,
  };
}

function makeAssessment(intent, outcome = "AUTHORIZED", overrides = {}) {
  const environment = overrides.environment ?? intent.environment;
  const provenance = createDataProvenance({
    source: { sourceId: sourceId("risk-engine"), sourceType: "INTERNAL" },
    environment: tradingEnvironment(environment),
    eventAt: utcTimestamp(evaluatedAt),
    receivedAt: utcTimestamp(evaluatedAt),
    schemaVersion: "risk-assessment-v1",
    normalizationVersion: "1.0.0",
    validationCode: "VALID",
  });

  return {
    id: "risk-assessment-pretrade-001",
    intentId: overrides.intentId ?? intent.id,
    policyVersion: "risk-policy-demo-v1",
    outcome,
    evaluatedAt: utcTimestamp(evaluatedAt),
    reasonCodes: outcome === "AUTHORIZED" ? [] : ["TEST_DECISION"],
    inputReferences: ["quote-001", "account-snapshot-001"],
    provenance,
  };
}

function receipt(overrides = {}) {
  return {
    intentInserted: true,
    riskAssessmentInserted: true,
    replayed: false,
    ...overrides,
  };
}

test("persists an authorized decision before returning it", async () => {
  const intent = makeIntent();
  const assessment = makeAssessment(intent);
  const calls = [];
  let evaluatedIntent;
  let persistedIntent;
  let persistedAssessment;

  const service = new PreTradeAuthorizationService(
    {
      async evaluate(value) {
        calls.push("risk");
        evaluatedIntent = value;
        return assessment;
      },
    },
    {
      async persistIntentAndRiskAssessment(value, decision) {
        calls.push("persist");
        persistedIntent = value;
        persistedAssessment = decision;
        return receipt();
      },
    },
  );

  const result = await service.evaluateAndPersist(intent);

  assert.deepEqual(calls, ["risk", "persist"]);
  assert.equal(Object.isFrozen(evaluatedIntent), true);
  assert.equal(Object.isFrozen(evaluatedIntent.payload), true);
  assert.equal(persistedIntent.id, intent.id);
  assert.equal(persistedAssessment.id, assessment.id);
  assert.equal(result.kind, "PRE_TRADE_DECISION_PERSISTED");
  assert.equal(result.riskOutcome, "AUTHORIZED");
  assert.equal(result.intentId, intent.id);
  assert.equal(result.environment, "DEMO");
  assert.deepEqual(result.persistence, receipt());
  assert.equal(Object.isFrozen(result), true);
  assert.equal(Object.isFrozen(result.persistence), true);
  assert.equal("order" in result, false);
  assert.equal("brokerCommand" in result, false);
});

for (const outcome of ["REJECTED", "HELD"]) {
  test("durably records " + outcome + " decisions without an OMS result", async () => {
    const intent = makeIntent();
    const assessment = makeAssessment(intent, outcome);
    let persistCalls = 0;
    const service = new PreTradeAuthorizationService(
      { async evaluate() { return assessment; } },
      {
        async persistIntentAndRiskAssessment(value, decision) {
          persistCalls += 1;
          assert.equal(value.id, intent.id);
          assert.equal(decision.outcome, outcome);
          return receipt();
        },
      },
    );

    const result = await service.evaluateAndPersist(intent);
    assert.equal(persistCalls, 1);
    assert.equal(result.riskOutcome, outcome);
    assert.equal("order" in result, false);
  });
}

test("manual, strategy, algorithmic, and AI intents use the same risk and journal boundary", async () => {
  const observedOrigins = [];
  const service = new PreTradeAuthorizationService(
    {
      async evaluate(intent) {
        observedOrigins.push(intent.origin.kind);
        return makeAssessment(intent);
      },
    },
    {
      async persistIntentAndRiskAssessment() {
        return receipt();
      },
    },
  );

  for (const kind of ["HUMAN", "STRATEGY", "ALGORITHM", "AI_AGENT"]) {
    await service.evaluateAndPersist(makeIntent({
      id: "intent-" + kind.toLowerCase(),
      origin: { kind, sourceId: "source-" + kind.toLowerCase() },
    }));
  }

  assert.deepEqual(observedOrigins, ["HUMAN", "STRATEGY", "AI_AGENT"]);
});

test("rejects an assessment for another intent before it reaches persistence", async () => {
  const intent = makeIntent();
  let persistCalls = 0;
  const service = new PreTradeAuthorizationService(
    {
      async evaluate(value) {
        return makeAssessment(value, "AUTHORIZED", { intentId: "different-intent" });
      },
    },
    {
      async persistIntentAndRiskAssessment() {
        persistCalls += 1;
        return receipt();
      },
    },
  );

  await assert.rejects(
    service.evaluateAndPersist(intent),
    { code: "risk_intent_mismatch" },
  );
  assert.equal(persistCalls, 0);
});

test("rejects an environment-mismatched assessment before persistence", async () => {
  const intent = makeIntent();
  let persistCalls = 0;
  const service = new PreTradeAuthorizationService(
    {
      async evaluate(value) {
        return makeAssessment(value, "AUTHORIZED", { environment: "SIMULATION" });
      },
    },
    {
      async persistIntentAndRiskAssessment() {
        persistCalls += 1;
        return receipt();
      },
    },
  );

  await assert.rejects(
    service.evaluateAndPersist(intent),
    { code: "risk_environment_mismatch" },
  );
  assert.equal(persistCalls, 0);
});

test("invalid intent input is rejected before risk evaluation", async () => {
  let riskCalls = 0;
  let persistCalls = 0;
  const service = new PreTradeAuthorizationService(
    { async evaluate() { riskCalls += 1; return makeAssessment(makeIntent()); } },
    {
      async persistIntentAndRiskAssessment() {
        persistCalls += 1;
        return receipt();
      },
    },
  );

  await assert.rejects(
    service.evaluateAndPersist(makeIntent({ payload: null })),
  );
  assert.equal(riskCalls, 0);
  assert.equal(persistCalls, 0);
});

test("risk evaluator failures fail closed and are never converted into authorization", async () => {
  let persistCalls = 0;
  const failure = new Error("risk context unavailable");
  const service = new PreTradeAuthorizationService(
    { async evaluate() { throw failure; } },
    {
      async persistIntentAndRiskAssessment() {
        persistCalls += 1;
        return receipt();
      },
    },
  );

  await assert.rejects(service.evaluateAndPersist(makeIntent()), failure);
  assert.equal(persistCalls, 0);
});

test("journal failure prevents a persisted-decision result from being returned", async () => {
  const failure = new Error("database transaction failed");
  const service = new PreTradeAuthorizationService(
    { async evaluate(intent) { return makeAssessment(intent); } },
    {
      async persistIntentAndRiskAssessment() { throw failure; },
    },
  );

  await assert.rejects(service.evaluateAndPersist(makeIntent()), failure);
});
