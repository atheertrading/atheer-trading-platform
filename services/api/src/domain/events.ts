import { UtcTimestamp, requiredText } from "./shared.js";
import { identifier } from "./models.js";

export type TradingDomainEventType =
  | "OrderIntentCreated" | "OrderValidated" | "OrderRejected" | "OrderSubmitted" | "OrderAccepted"
  | "OrderPartiallyFilled" | "OrderFilled" | "OrderCancelled" | "PositionOpened" | "PositionUpdated"
  | "PositionClosed" | "RiskLimitBreached" | "TradingHalted" | "OrderSubmissionUnknown" | "ReconciliationRequired";

export interface DomainEvent<TPayload = Readonly<Record<string, unknown>>> {
  readonly eventId: string;
  readonly eventType: TradingDomainEventType;
  readonly aggregateId: string;
  readonly aggregateVersion: number;
  readonly occurredAt: UtcTimestamp;
  readonly correlationId: string;
  readonly causationId?: string;
  readonly schemaVersion: 1;
  readonly payload: TPayload;
}

export function createDomainEvent<TPayload extends Readonly<Record<string, unknown>>>(input: {
  eventId: string; eventType: TradingDomainEventType; aggregateId: string; aggregateVersion: number;
  occurredAt: UtcTimestamp; correlationId: string; causationId?: string; payload: TPayload;
}): DomainEvent<TPayload> {
  if (!Number.isInteger(input.aggregateVersion) || input.aggregateVersion < 1) throw new Error("Aggregate version must be a positive integer.");
  return Object.freeze({
    eventId: requiredText(input.eventId, "Event ID"), eventType: input.eventType,
    aggregateId: requiredText(input.aggregateId, "Aggregate ID"), aggregateVersion: input.aggregateVersion,
    occurredAt: input.occurredAt, correlationId: requiredText(input.correlationId, "Correlation ID"),
    causationId: input.causationId ? requiredText(input.causationId, "Causation ID") : undefined,
    schemaVersion: 1, payload: Object.freeze({ ...input.payload }),
  });
}
