import {
  type BrokerAccountId,
  type CorrelationId,
  type InstrumentId,
  type OrderId,
  type OrderIntentId,
  type RiskAssessmentId,
  type SourceId,
  type TradingEnvironment,
  type UtcTimestamp,
  DomainValidationError,
  assertPositiveDecimal,
  deepFreeze,
  nonEmptyString,
  tradingEnvironment,
  utcTimestamp,
} from "./shared.ts";
import { type Quantity, quantity } from "./instrument.ts";
import {
  createOrderIntentEnvelope,
  createRiskAssessment,
  type OrderIntentEnvelope,
  type RiskAssessment,
} from "./trading.ts";

export const ORDER_LIFECYCLE_STATES = [
  "CREATED",
  "VALIDATING",
  "RISK_CHECKING",
  "AUTHORIZED",
  "PERSISTED",
  "SUBMITTED",
  "PENDING",
  "ACCEPTED",
  "WORKING",
  "PARTIALLY_FILLED",
  "FILLED",
  "CANCEL_PENDING",
  "CANCELLED",
  "REJECTED",
  "EXPIRED",
  "UNKNOWN",
  "RECONCILIATION_REQUIRED",
] as const;

export type OrderLifecycleState = (typeof ORDER_LIFECYCLE_STATES)[number];
export type OrderLifecycleSourceKind = "OMS" | "EXECUTION_GATEWAY" | "BROKER" | "RECONCILIATION";

const OMS_TRANSITIONS: Readonly<Partial<Record<OrderLifecycleState, readonly OrderLifecycleState[]>>> = {
  CREATED: ["VALIDATING", "REJECTED"],
  VALIDATING: ["RISK_CHECKING", "REJECTED"],
  RISK_CHECKING: ["AUTHORIZED", "REJECTED"],
  AUTHORIZED: ["PERSISTED"],
  ACCEPTED: ["CANCEL_PENDING"],
  WORKING: ["CANCEL_PENDING"],
  PARTIALLY_FILLED: ["CANCEL_PENDING"],
};

const GATEWAY_TRANSITIONS: Readonly<Partial<Record<OrderLifecycleState, readonly OrderLifecycleState[]>>> = {
  PERSISTED: ["SUBMITTED"],
  CANCEL_PENDING: ["CANCEL_PENDING"],
};

const BROKER_TRANSITIONS: Readonly<Partial<Record<OrderLifecycleState, readonly OrderLifecycleState[]>>> = {
  SUBMITTED: ["PENDING", "ACCEPTED", "WORKING", "PARTIALLY_FILLED", "FILLED", "REJECTED", "EXPIRED", "UNKNOWN", "RECONCILIATION_REQUIRED"],
  PENDING: ["ACCEPTED", "WORKING", "PARTIALLY_FILLED", "FILLED", "REJECTED", "EXPIRED", "UNKNOWN", "RECONCILIATION_REQUIRED"],
  ACCEPTED: ["WORKING", "PARTIALLY_FILLED", "FILLED", "REJECTED", "EXPIRED", "UNKNOWN", "RECONCILIATION_REQUIRED"],
  WORKING: ["PARTIALLY_FILLED", "FILLED", "CANCELLED", "EXPIRED", "UNKNOWN", "RECONCILIATION_REQUIRED"],
  PARTIALLY_FILLED: ["PARTIALLY_FILLED", "FILLED", "CANCELLED", "EXPIRED", "UNKNOWN", "RECONCILIATION_REQUIRED"],
  CANCEL_PENDING: ["WORKING", "PARTIALLY_FILLED", "FILLED", "CANCELLED", "UNKNOWN", "RECONCILIATION_REQUIRED"],
  UNKNOWN: ["RECONCILIATION_REQUIRED"],
  FILLED: ["RECONCILIATION_REQUIRED"],
  CANCELLED: ["RECONCILIATION_REQUIRED"],
  REJECTED: ["RECONCILIATION_REQUIRED"],
  EXPIRED: ["RECONCILIATION_REQUIRED"],
};

const RECONCILIATION_TRANSITIONS: Readonly<Partial<Record<OrderLifecycleState, readonly OrderLifecycleState[]>>> = {
  UNKNOWN: ["PENDING", "ACCEPTED", "WORKING", "PARTIALLY_FILLED", "FILLED", "CANCELLED", "REJECTED", "EXPIRED", "RECONCILIATION_REQUIRED"],
  RECONCILIATION_REQUIRED: ["PENDING", "ACCEPTED", "WORKING", "PARTIALLY_FILLED", "FILLED", "CANCELLED", "REJECTED", "EXPIRED", "UNKNOWN"],
};

export interface OrderLifecycleTransition {
  readonly eventId: string;
  readonly orderId: OrderId;
  readonly fromState: OrderLifecycleState;
  readonly toState: OrderLifecycleState;
  readonly sourceKind: OrderLifecycleSourceKind;
  readonly sourceId: SourceId;
  readonly occurredAt: UtcTimestamp;
  readonly correlationId: CorrelationId;
  readonly reasonCode?: string;
  readonly evidenceReference?: string;
  readonly orderVersion: number;
}

export function assertOrderLifecycleTransitionAllowed(
  fromState: OrderLifecycleState,
  toState: OrderLifecycleState,
  sourceKind: OrderLifecycleSourceKind,
): void {
  const policy = sourceKind === "OMS"
    ? OMS_TRANSITIONS
    : sourceKind === "EXECUTION_GATEWAY"
      ? GATEWAY_TRANSITIONS
      : sourceKind === "BROKER"
        ? BROKER_TRANSITIONS
        : RECONCILIATION_TRANSITIONS;
  if (!(policy[fromState] ?? []).includes(toState)) {
    throw new DomainValidationError(
      "invalid_order_lifecycle_transition",
      sourceKind + " cannot transition an order from " + fromState + " to " + toState + ".",
    );
  }
}

export function createOrderLifecycleTransition(input: OrderLifecycleTransition): OrderLifecycleTransition {
  nonEmptyString(input.eventId, "order_lifecycle_event_id");
  nonEmptyString(input.orderId, "order_lifecycle_order_id");
  nonEmptyString(input.sourceId, "order_lifecycle_source_id");
  nonEmptyString(input.correlationId, "order_lifecycle_correlation_id");
  if (!ORDER_LIFECYCLE_STATES.includes(input.fromState) || !ORDER_LIFECYCLE_STATES.includes(input.toState)) {
    throw new DomainValidationError("invalid_order_lifecycle_state", "Order lifecycle state is not recognized.");
  }
  if (!["OMS", "EXECUTION_GATEWAY", "BROKER", "RECONCILIATION"].includes(input.sourceKind)) {
    throw new DomainValidationError("invalid_order_lifecycle_source", "Order lifecycle source kind is not recognized.");
  }
  assertOrderLifecycleTransitionAllowed(input.fromState, input.toState, input.sourceKind);
  utcTimestamp(input.occurredAt);
  if (!Number.isSafeInteger(input.orderVersion) || input.orderVersion < 1) {
    throw new DomainValidationError("invalid_order_version", "Order version must be a positive integer.");
  }
  if (input.reasonCode !== undefined) nonEmptyString(input.reasonCode, "order_lifecycle_reason_code");
  if (input.evidenceReference !== undefined) nonEmptyString(input.evidenceReference, "order_lifecycle_evidence_reference");
  return deepFreeze({ ...input }) as OrderLifecycleTransition;
}

export interface OmsOrder {
  readonly id: OrderId;
  readonly intentId: OrderIntentId;
  readonly riskAssessmentId: RiskAssessmentId;
  readonly accountId: BrokerAccountId;
  readonly instrumentId: InstrumentId;
  readonly environment: TradingEnvironment;
  readonly correlationId: CorrelationId;
  readonly requestedQuantity: Quantity;
  readonly filledQuantity: Quantity;
  readonly remainingQuantity: Quantity;
  readonly state: "PERSISTED";
  readonly version: 1;
  readonly createdAt: UtcTimestamp;
  readonly updatedAt: UtcTimestamp;
}

export function createOmsOrder(input: {
  readonly id: OrderId;
  readonly intent: OrderIntentEnvelope;
  readonly riskAssessment: RiskAssessment;
  readonly createdAt: UtcTimestamp;
}): OmsOrder {
  createOrderIntentEnvelope(input.intent);
  createRiskAssessment(input.riskAssessment);
  nonEmptyString(input.id, "order_id");
  utcTimestamp(input.createdAt);
  if (input.riskAssessment.outcome !== "AUTHORIZED") {
    throw new DomainValidationError("order_risk_not_authorized", "An OMS order requires an AUTHORIZED risk assessment.");
  }
  if (input.riskAssessment.intentId !== input.intent.id) {
    throw new DomainValidationError("order_risk_intent_mismatch", "Risk assessment must authorize the exact order intent.");
  }
  if (input.riskAssessment.provenance.environment !== input.intent.environment) {
    throw new DomainValidationError("order_risk_environment_mismatch", "Risk assessment and order intent environments must match.");
  }
  if (input.intent.payload.quantity === undefined) {
    throw new DomainValidationError("order_quantity_required", "An OMS order requires an explicit validated quantity.");
  }
  const requestedQuantity = input.intent.payload.quantity;
  assertPositiveDecimal(requestedQuantity.value, "order_requested_quantity");
  const zero = quantity("0", requestedQuantity.unit);
  return deepFreeze({
    id: input.id,
    intentId: input.intent.id,
    riskAssessmentId: input.riskAssessment.id,
    accountId: input.intent.accountId,
    instrumentId: input.intent.instrumentId,
    environment: tradingEnvironment(input.intent.environment),
    correlationId: input.intent.correlationId,
    requestedQuantity,
    filledQuantity: zero,
    remainingQuantity: requestedQuantity,
    state: "PERSISTED",
    version: 1,
    createdAt: input.createdAt,
    updatedAt: input.createdAt,
  }) as OmsOrder;
}
