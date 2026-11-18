import assert from "node:assert/strict";
import test from "node:test";
import {
  assertOrderLifecycleTransitionAllowed,
  brokerAccountId,
  commandId,
  correlationId,
  createDataProvenance,
  createOmsOrder,
  createOrderIntentEnvelope,
  createOrderLifecycleTransition,
  createRiskAssessment,
  idempotencyKey,
  instrumentId,
  instrumentSpecificationId,
  orderIntentId,
  orderId,
  quantity,
  riskAssessmentId,
  sourceId,
  tradingEnvironment,
  unitCode,
  utcTimestamp,
} from "../dist/domain/index.js";

function authorizedFixtures(outcome = "AUTHORIZED") {
  const intent = createOrderIntentEnvelope({
    id: orderIntentId("oms-intent-001"),
    commandId: commandId("oms-command-001"),
    correlationId: correlationId("oms-correlation-001"),
    idempotencyKey: idempotencyKey("oms-idempotency-001"),
    accountId: brokerAccountId("oms-account-001"),
    instrumentId: instrumentId("oms-instrument-001"),
    instrumentSpecificationId: instrumentSpecificationId("oms-specification-001"),
    environment: tradingEnvironment("DEMO"),
    origin: { kind: "HUMAN", sourceId: sourceId("operator-001") },
    createdAt: utcTimestamp(1_800_000_000_000),
    intentVersion: 1,
    schemaVersion: "1.0.0",
    payload: {
      operationCode: "OPEN",
      direction: "BUY",
      quantity: quantity("0.2500", unitCode("CONTRACT")),
      orderTypeCode: "MARKET",
    },
  });
  const provenance = createDataProvenance({
    source: { sourceId: sourceId("risk-engine"), sourceType: "INTERNAL" },
    environment: tradingEnvironment("DEMO"),
    eventAt: utcTimestamp(1_800_000_000_100),
    receivedAt: utcTimestamp(1_800_000_000_100),
    schemaVersion: "risk-assessment-v1",
    normalizationVersion: "1.0.0",
    validationCode: "VALID",
  });
  const assessment = createRiskAssessment({
    id: riskAssessmentId("oms-risk-001"),
    intentId: intent.id,
    policyVersion: "risk-policy-v1",
    outcome,
    evaluatedAt: provenance.eventAt,
    reasonCodes: outcome === "AUTHORIZED" ? [] : ["POLICY_REJECTED"],
    inputReferences: ["market-snapshot-001", "account-snapshot-001"],
    provenance,
  });
  return { intent, assessment };
}

test("OMS order creation requires an exact, environment-matched AUTHORIZED assessment", () => {
  const { intent, assessment } = authorizedFixtures();
  const order = createOmsOrder({
    id: orderId("oms-order-001"),
    intent,
    riskAssessment: assessment,
    createdAt: utcTimestamp(1_800_000_000_200),
  });

  assert.equal(order.state, "PERSISTED");
  assert.equal(order.version, 1);
  assert.equal(order.requestedQuantity.value, "0.25");
  assert.equal(order.filledQuantity.value, "0");
  assert.equal(order.remainingQuantity.value, "0.25");
  assert.equal(order.environment, "DEMO");
  assert.equal(Object.isFrozen(order), true);
  assert.equal(Object.isFrozen(order.requestedQuantity), true);
});

test("OMS order creation rejects rejected risk, mismatched intent, and missing quantity", () => {
  const rejected = authorizedFixtures("REJECTED");
  assert.throws(
    () => createOmsOrder({
      id: orderId("oms-order-rejected"),
      intent: rejected.intent,
      riskAssessment: rejected.assessment,
      createdAt: utcTimestamp(1_800_000_000_200),
    }),
    { code: "order_risk_not_authorized" },
  );

  const authorized = authorizedFixtures();
  assert.throws(
    () => createOmsOrder({
      id: orderId("oms-order-wrong-risk"),
      intent: authorized.intent,
      riskAssessment: { ...authorized.assessment, intentId: orderIntentId("different-intent") },
      createdAt: utcTimestamp(1_800_000_000_200),
    }),
    { code: "order_risk_intent_mismatch" },
  );

  const noQuantity = createOrderIntentEnvelope({
    ...authorized.intent,
    id: orderIntentId("oms-intent-no-quantity"),
    idempotencyKey: idempotencyKey("oms-idempotency-no-quantity"),
    payload: { operationCode: "CLOSE_ALL" },
  });
  assert.throws(
    () => createOmsOrder({
      id: orderId("oms-order-no-quantity"),
      intent: noQuantity,
      riskAssessment: { ...authorized.assessment, intentId: noQuantity.id },
      createdAt: utcTimestamp(1_800_000_000_200),
    }),
    { code: "order_quantity_required" },
  );
});

test("order lifecycle transitions enforce source authority and uncertain-outcome recovery", () => {
  assertOrderLifecycleTransitionAllowed("AUTHORIZED", "PERSISTED", "OMS");
  assertOrderLifecycleTransitionAllowed("PERSISTED", "SUBMITTED", "EXECUTION_GATEWAY");
  assertOrderLifecycleTransitionAllowed("SUBMITTED", "UNKNOWN", "BROKER");
  assertOrderLifecycleTransitionAllowed("UNKNOWN", "WORKING", "RECONCILIATION");
  assertOrderLifecycleTransitionAllowed("WORKING", "CANCEL_PENDING", "OMS");
  assertOrderLifecycleTransitionAllowed("CANCEL_PENDING", "PARTIALLY_FILLED", "BROKER");

  assert.throws(
    () => assertOrderLifecycleTransitionAllowed("PERSISTED", "SUBMITTED", "OMS"),
    { code: "invalid_order_lifecycle_transition" },
  );
  assert.throws(
    () => assertOrderLifecycleTransitionAllowed("UNKNOWN", "SUBMITTED", "BROKER"),
    { code: "invalid_order_lifecycle_transition" },
  );
  assert.throws(
    () => assertOrderLifecycleTransitionAllowed("FILLED", "WORKING", "BROKER"),
    { code: "invalid_order_lifecycle_transition" },
  );

  const transition = createOrderLifecycleTransition({
    eventId: "oms-event-001",
    orderId: orderId("oms-order-001"),
    fromState: "AUTHORIZED",
    toState: "PERSISTED",
    sourceKind: "OMS",
    sourceId: sourceId("atheer-oms"),
    occurredAt: utcTimestamp(1_800_000_000_200),
    correlationId: correlationId("oms-correlation-001"),
    orderVersion: 1,
  });
  assert.equal(transition.toState, "PERSISTED");
  assert.equal(Object.isFrozen(transition), true);
});
