import {
  type BrokerAccountId,
  type BrokerId,
  type CorrelationId,
  type DataProvenance,
  type ExecutionEventId,
  type ExecutionFillId,
  type IdempotencyKey,
  type InstrumentId,
  type InstrumentSpecificationId,
  type OrderId,
  type OrderIntentId,
  type PositionId,
  type ReconciliationEventId,
  type RiskAssessmentId,
  type SourceId,
  type TradingEnvironment,
  type UtcTimestamp,
  DomainValidationError,
  assertPositiveDecimal,
  compareDecimal,
  decimalValue,
  deepFreeze,
  nonEmptyString,
  tradingEnvironment,
  utcTimestamp,
} from "./shared.ts";
import type { Price, Quantity } from "./instrument.ts";
import type { AccountBalanceSnapshot } from "./account.ts";

export type IntentOriginKind =
  | "HUMAN"
  | "STRATEGY"
  | "ALGORITHM"
  | "POSITION_MANAGEMENT"
  | "RISK_MANAGEMENT"
  | "AI_AGENT"
  | "SYSTEM";

export interface IntentOrigin {
  readonly kind: IntentOriginKind;
  readonly sourceId: SourceId;
  readonly permissionProfileReference?: string;
}

export type OrderDirection = "BUY" | "SELL";

export interface PriceParameter {
  readonly code: string;
  readonly price: Price;
}

export interface OrderIntentPayload {
  readonly operationCode: string;
  readonly direction?: OrderDirection;
  readonly quantity?: Quantity;
  readonly orderTypeCode?: string;
  readonly priceParameters?: readonly PriceParameter[];
  readonly timeInForceCode?: string;
  readonly targetOrderId?: OrderId;
  readonly targetPositionId?: PositionId;
}

export interface OrderIntentEnvelope<TPayload extends OrderIntentPayload = OrderIntentPayload> {
  readonly id: OrderIntentId;
  readonly commandId: import("./shared.ts").CommandId;
  readonly correlationId: CorrelationId;
  readonly idempotencyKey: IdempotencyKey;
  readonly accountId: BrokerAccountId;
  readonly instrumentId: InstrumentId;
  readonly instrumentSpecificationId: InstrumentSpecificationId;
  readonly environment: TradingEnvironment;
  readonly origin: IntentOrigin;
  readonly createdAt: UtcTimestamp;
  readonly intentVersion: number;
  readonly schemaVersion: string;
  readonly marketDataReference?: string;
  readonly payload: Readonly<TPayload>;
}

export function createOrderIntentEnvelope<TPayload extends OrderIntentPayload>(
  input: OrderIntentEnvelope<TPayload>,
): OrderIntentEnvelope<Readonly<TPayload>> {
  nonEmptyString(input.id, "order_intent_id");
  nonEmptyString(input.commandId, "command_id");
  nonEmptyString(input.correlationId, "correlation_id");
  nonEmptyString(input.idempotencyKey, "idempotency_key");
  nonEmptyString(input.accountId, "broker_account_id");
  nonEmptyString(input.instrumentId, "instrument_id");
  nonEmptyString(input.instrumentSpecificationId, "instrument_specification_id");
  nonEmptyString(input.origin.sourceId, "intent_origin_source_id");
  if (!["HUMAN", "STRATEGY", "ALGORITHM", "POSITION_MANAGEMENT", "RISK_MANAGEMENT", "AI_AGENT", "SYSTEM"].includes(input.origin.kind)) {
    throw new DomainValidationError("invalid_intent_origin", "Intent origin kind is not supported.");
  }
  tradingEnvironment(input.environment);
  utcTimestamp(input.createdAt);
  nonEmptyString(input.schemaVersion, "intent_schema_version");
  nonEmptyString(input.payload.operationCode, "intent_operation_code");
  if (input.payload.direction !== undefined && input.payload.direction !== "BUY" && input.payload.direction !== "SELL") {
    throw new DomainValidationError("invalid_order_direction", "Order direction must be BUY or SELL.");
  }
  if (input.payload.quantity !== undefined) {
    assertPositiveDecimal(input.payload.quantity.value, "intent_quantity");
    nonEmptyString(input.payload.quantity.unit, "intent_quantity_unit");
  }
  if (input.payload.orderTypeCode !== undefined) nonEmptyString(input.payload.orderTypeCode, "order_type_code");
  if (input.payload.timeInForceCode !== undefined) nonEmptyString(input.payload.timeInForceCode, "time_in_force_code");
  for (const parameter of input.payload.priceParameters ?? []) {
    nonEmptyString(parameter.code, "price_parameter_code");
    nonEmptyString(parameter.price.unit, "price_parameter_unit");
  }
  if (!Number.isSafeInteger(input.intentVersion) || input.intentVersion < 1) {
    throw new DomainValidationError("invalid_intent_version", "Intent version must be a positive integer.");
  }
  if (input.origin.permissionProfileReference !== undefined) {
    nonEmptyString(input.origin.permissionProfileReference, "permission_profile_reference");
  }
  if (input.marketDataReference !== undefined) {
    nonEmptyString(input.marketDataReference, "market_data_reference");
  }
  if (input.payload === null || typeof input.payload !== "object") {
    throw new DomainValidationError("invalid_intent_payload", "Order intent payload must be a structured object.");
  }
  return deepFreeze({ ...input }) as OrderIntentEnvelope<Readonly<TPayload>>;
}

export type RiskDecisionOutcome = "AUTHORIZED" | "REJECTED" | "HELD";

export interface RiskAssessment {
  readonly id: RiskAssessmentId;
  readonly intentId: OrderIntentId;
  readonly policyVersion: string;
  readonly outcome: RiskDecisionOutcome;
  readonly evaluatedAt: UtcTimestamp;
  readonly reasonCodes: readonly string[];
  readonly inputReferences: readonly string[];
  readonly provenance: DataProvenance;
}

export function createRiskAssessment(input: RiskAssessment): RiskAssessment {
  nonEmptyString(input.id, "risk_assessment_id");
  nonEmptyString(input.intentId, "risk_intent_id");
  nonEmptyString(input.policyVersion, "risk_policy_version");
  if (input.outcome !== "AUTHORIZED" && input.outcome !== "REJECTED" && input.outcome !== "HELD") {
    throw new DomainValidationError("invalid_risk_outcome", "Risk outcome must be AUTHORIZED, REJECTED, or HELD.");
  }
  for (const code of input.reasonCodes) nonEmptyString(code, "risk_reason_code");
  for (const reference of input.inputReferences) nonEmptyString(reference, "risk_input_reference");
  if (input.provenance.source.sourceType !== "INTERNAL") {
    throw new DomainValidationError("invalid_risk_source", "Risk assessments must originate from the internal Risk Engine boundary.");
  }
  if (input.provenance.eventAt !== input.evaluatedAt) {
    throw new DomainValidationError("risk_timestamp_mismatch", "Risk assessment time must match its provenance event time.");
  }
  return deepFreeze({ ...input, reasonCodes: [...input.reasonCodes], inputReferences: [...input.inputReferences] }) as RiskAssessment;
}

export interface StateTransitionPolicy<TState extends string> {
  readonly initialStates: readonly TState[];
  readonly transitions: Readonly<Partial<Record<TState, readonly TState[]>>>;
}

export interface LifecycleTransition<TEntityId extends string, TState extends string> {
  readonly entityId: TEntityId;
  readonly fromState: TState | null;
  readonly toState: TState;
  readonly occurredAt: UtcTimestamp;
  readonly correlationId: CorrelationId;
  readonly sourceId: SourceId;
  readonly reasonCode?: string;
}

export function isTransitionAllowed<TState extends string>(
  policy: StateTransitionPolicy<TState>,
  fromState: TState | null,
  toState: TState,
): boolean {
  if (fromState === null) return policy.initialStates.includes(toState);
  return policy.transitions[fromState]?.includes(toState) ?? false;
}

export function assertTransitionAllowed<TState extends string>(
  policy: StateTransitionPolicy<TState>,
  fromState: TState | null,
  toState: TState,
): void {
  if (!isTransitionAllowed(policy, fromState, toState)) {
    throw new DomainValidationError("invalid_lifecycle_transition", "The requested lifecycle transition is not permitted by the supplied policy.");
  }
}

export interface BrokerOrderRecord {
  readonly id: OrderId;
  readonly brokerId: BrokerId;
  readonly intentId: OrderIntentId;
  readonly accountId: BrokerAccountId;
  readonly instrumentId: InstrumentId;
  readonly environment: TradingEnvironment;
  readonly brokerOrderReference: string;
  readonly brokerStatusCode: string;
  readonly orderedQuantity: Quantity;
  readonly filledQuantity: Quantity;
  readonly observedAt: UtcTimestamp;
  readonly provenance: DataProvenance;
}

export interface PositionSnapshot {
  readonly id: PositionId;
  readonly brokerId: BrokerId;
  readonly accountId: BrokerAccountId;
  readonly instrumentId: InstrumentId;
  readonly environment: TradingEnvironment;
  readonly brokerPositionReference: string;
  readonly brokerStatusCode: string;
  readonly quantity: Quantity;
  readonly averageOpenPrice?: Price;
  readonly observedAt: UtcTimestamp;
  readonly provenance: DataProvenance;
}

export interface ExecutionFill {
  readonly id: ExecutionFillId;
  readonly brokerId: BrokerId;
  readonly orderId: OrderId;
  readonly brokerExecutionReference: string;
  readonly environment: TradingEnvironment;
  readonly quantity: Quantity;
  readonly executionPrice: Price;
  readonly executedAt: UtcTimestamp;
  readonly receivedAt: UtcTimestamp;
  readonly provenance: DataProvenance;
}

export function validateBrokerOrderRecord(order: BrokerOrderRecord): void {
  nonEmptyString(order.id, "order_id");
  nonEmptyString(order.brokerId, "order_broker_id");
  nonEmptyString(order.brokerOrderReference, "broker_order_reference");
  nonEmptyString(order.brokerStatusCode, "broker_order_status_code");
  if (
    order.provenance.source.sourceType !== "BROKER" ||
    String(order.provenance.source.sourceId) !== String(order.brokerId) ||
    order.environment !== order.provenance.environment
  ) {
    throw new DomainValidationError("order_provenance_mismatch", "Broker order and source provenance must identify the same broker and environment.");
  }
  if (order.observedAt !== order.provenance.eventAt) {
    throw new DomainValidationError("order_timestamp_mismatch", "Order observation time must match its broker event time.");
  }
  assertPositiveDecimal(order.orderedQuantity.value, "ordered_quantity");
  if (compareDecimal(order.filledQuantity.value, decimalValue("0")) < 0) {
    throw new DomainValidationError("invalid_filled_quantity", "Filled quantity cannot be negative.");
  }
  if (order.orderedQuantity.unit !== order.filledQuantity.unit) {
    throw new DomainValidationError("order_quantity_unit_mismatch", "Ordered and filled quantities must use the same unit.");
  }
}

export function validatePositionSnapshot(position: PositionSnapshot): void {
  nonEmptyString(position.id, "position_id");
  nonEmptyString(position.brokerId, "position_broker_id");
  nonEmptyString(position.brokerPositionReference, "broker_position_reference");
  nonEmptyString(position.brokerStatusCode, "broker_position_status_code");
  if (
    position.provenance.source.sourceType !== "BROKER" ||
    String(position.provenance.source.sourceId) !== String(position.brokerId) ||
    position.environment !== position.provenance.environment
  ) {
    throw new DomainValidationError("position_provenance_mismatch", "Position snapshot and source provenance must identify the same broker and environment.");
  }
  if (position.observedAt !== position.provenance.eventAt) {
    throw new DomainValidationError("position_timestamp_mismatch", "Position observation time must match its broker event time.");
  }
  nonEmptyString(position.quantity.unit, "position_quantity_unit");
}

export function validateExecutionFill(fill: ExecutionFill): void {
  nonEmptyString(fill.id, "execution_fill_id");
  nonEmptyString(fill.brokerId, "execution_broker_id");
  nonEmptyString(fill.orderId, "execution_order_id");
  nonEmptyString(fill.brokerExecutionReference, "broker_execution_reference");
  assertPositiveDecimal(fill.quantity.value, "execution_quantity");
  nonEmptyString(fill.quantity.unit, "execution_quantity_unit");
  nonEmptyString(fill.executionPrice.unit, "execution_price_unit");
  if (
    fill.provenance.source.sourceType !== "BROKER" ||
    String(fill.provenance.source.sourceId) !== String(fill.brokerId)
  ) {
    throw new DomainValidationError("execution_broker_mismatch", "Execution fill must retain matching broker provenance.");
  }
  if (fill.environment !== fill.provenance.environment) {
    throw new DomainValidationError("execution_environment_mismatch", "Execution fill and provenance environments must match.");
  }
  if (fill.executedAt !== fill.provenance.eventAt || fill.receivedAt !== fill.provenance.receivedAt) {
    throw new DomainValidationError("execution_timestamp_mismatch", "Execution event and receipt times must match provenance.");
  }
}

export function createExecutionFill(input: ExecutionFill): ExecutionFill {
  validateExecutionFill(input);
  return deepFreeze({ ...input }) as ExecutionFill;
}

export interface ExecutionEvent<TPayload extends object = Readonly<Record<string, unknown>>> {
  readonly id: ExecutionEventId;
  readonly aggregateId: OrderId | PositionId;
  readonly eventCode: string;
  readonly occurredAt: UtcTimestamp;
  readonly receivedAt: UtcTimestamp;
  readonly environment: TradingEnvironment;
  readonly provenance: DataProvenance;
  readonly payload: Readonly<TPayload>;
}

export function createExecutionEvent<TPayload extends object>(input: ExecutionEvent<TPayload>): ExecutionEvent<Readonly<TPayload>> {
  nonEmptyString(input.id, "execution_event_id");
  nonEmptyString(input.aggregateId, "execution_aggregate_id");
  nonEmptyString(input.eventCode, "execution_event_code");
  if (input.environment !== input.provenance.environment) {
    throw new DomainValidationError("execution_event_environment_mismatch", "Execution event and provenance environments must match.");
  }
  if (input.occurredAt !== input.provenance.eventAt || input.receivedAt !== input.provenance.receivedAt) {
    throw new DomainValidationError("execution_event_timestamp_mismatch", "Execution event timestamps must match provenance.");
  }
  return deepFreeze({ ...input }) as ExecutionEvent<Readonly<TPayload>>;
}

export interface ReconciliationEvent {
  readonly id: ReconciliationEventId;
  readonly aggregateType: "ACCOUNT" | "ORDER" | "POSITION" | "EXECUTION";
  readonly aggregateId: string;
  readonly outcomeCode: string;
  readonly occurredAt: UtcTimestamp;
  readonly environment: TradingEnvironment;
  readonly discrepancyCodes: readonly string[];
  readonly provenance: DataProvenance;
}

export function createReconciliationEvent(input: ReconciliationEvent): ReconciliationEvent {
  nonEmptyString(input.id, "reconciliation_event_id");
  nonEmptyString(input.aggregateId, "reconciliation_aggregate_id");
  nonEmptyString(input.outcomeCode, "reconciliation_outcome_code");
  if (input.environment !== input.provenance.environment || input.occurredAt !== input.provenance.eventAt) {
    throw new DomainValidationError("reconciliation_provenance_mismatch", "Reconciliation event must match its source environment and event time.");
  }
  for (const code of input.discrepancyCodes) nonEmptyString(code, "reconciliation_discrepancy_code");
  return deepFreeze({ ...input, discrepancyCodes: [...input.discrepancyCodes] }) as ReconciliationEvent;
}

export interface AuditEvent {
  readonly id: import("./shared.ts").AuditEventId;
  readonly actorKind: "USER" | "SYSTEM" | "STRATEGY" | "AI_AGENT" | "BROKER";
  readonly actorId: SourceId;
  readonly actionCode: string;
  readonly subjectType: string;
  readonly subjectId: string;
  readonly outcomeCode: string;
  readonly occurredAt: UtcTimestamp;
  readonly correlationId: CorrelationId;
  readonly environment: TradingEnvironment;
  readonly reasonCodes: readonly string[];
  readonly provenance?: DataProvenance;
}

export function createAuditEvent(input: AuditEvent): AuditEvent {
  nonEmptyString(input.id, "audit_event_id");
  nonEmptyString(input.actorId, "audit_actor_id");
  nonEmptyString(input.actionCode, "audit_action_code");
  nonEmptyString(input.subjectType, "audit_subject_type");
  nonEmptyString(input.subjectId, "audit_subject_id");
  nonEmptyString(input.outcomeCode, "audit_outcome_code");
  nonEmptyString(input.correlationId, "audit_correlation_id");
  if (input.provenance !== undefined && input.provenance.environment !== input.environment) {
    throw new DomainValidationError("audit_provenance_mismatch", "Audit event and provenance environments must match.");
  }
  for (const code of input.reasonCodes) nonEmptyString(code, "audit_reason_code");
  return deepFreeze({ ...input, reasonCodes: [...input.reasonCodes] }) as AuditEvent;
}

export interface OrderLifecycleTransition extends LifecycleTransition<OrderId, string> {}
export interface PositionLifecycleTransition extends LifecycleTransition<PositionId, string> {}

export type AccountSnapshotReference = AccountBalanceSnapshot;
