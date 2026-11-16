import { createDomainEvent } from "./events.js";
import type { DomainEvent } from "./events.js";
import { OrderIntent, TradingOrder } from "./models.js";
import type { OrderId } from "./models.js";
import { RiskEngine } from "./risk.js";
import type { RiskContext, RiskDecision } from "./risk.js";

export type IntentRegistration =
  | { readonly kind: "REGISTERED"; readonly order: TradingOrder }
  | { readonly kind: "DUPLICATE"; readonly order: TradingOrder; readonly decision?: RiskDecision }
  | { readonly kind: "CONFLICT" };

/**
 * Persistence adapter contract. register must atomically store intent, order and its outbox event,
 * enforcing a unique idempotency key. recordRiskDecisionAndEvents must atomically store the
 * decision, updated order and corresponding outbox events. No in-memory adapter is production-ready.
 */
export interface OrderIntentRegistry {
  register(intent: OrderIntent, fingerprint: string, order: TradingOrder, createdEvent: DomainEvent): Promise<IntentRegistration>;
  recordRiskDecisionAndEvents(orderId: OrderId, order: TradingOrder, decision: RiskDecision, events: readonly DomainEvent[]): Promise<void>;
  findByIdempotencyKey(key: string): Promise<TradingOrder | undefined>;
  findByOrderId(orderId: OrderId): Promise<TradingOrder | undefined>;
  listByAccount(accountId: string, limit: number, before?: string): Promise<readonly TradingOrder[]>;
}

export interface OrderAuthorizationResult {
  readonly order: TradingOrder;
  readonly decision?: RiskDecision;
  readonly events: readonly DomainEvent[];
  readonly duplicate: boolean;
  readonly pending: boolean;
}

/** Centralized intent intake and risk authorization. This service has no broker transport or dealing method. */
export class OrderManagementService {
  constructor(private readonly registry: OrderIntentRegistry, private readonly riskEngine: RiskEngine) {}

  async registerAndAuthorize(intent: OrderIntent, context: RiskContext, orderId: string): Promise<OrderAuthorizationResult> {
    const initial = TradingOrder.fromIntent(orderId, intent);
    const createdEvent = createDomainEvent({
      eventId: `evt-${intent.id}-created`, eventType: "OrderIntentCreated", aggregateId: initial.id,
      aggregateVersion: 1, occurredAt: intent.input.createdAt, correlationId: intent.input.correlationId,
      causationId: intent.input.causationId, payload: { intentId: intent.id, accountId: intent.input.accountId, instrumentId: intent.input.instrumentId, sourceType: intent.input.sourceType },
    });
    const registration = await this.registry.register(intent, intent.fingerprint(), initial, createdEvent);
    if (registration.kind === "CONFLICT") throw new DomainError("IDEMPOTENCY_KEY_CONFLICT", "Idempotency key was reused with a different intent payload.");
    if (registration.kind === "DUPLICATE") {
      const completed = registration.order.input.status === "RISK_AUTHORIZED" || registration.order.input.status === "RISK_REJECTED";
      return Object.freeze({ order: registration.order, decision: registration.decision, events: Object.freeze([]), duplicate: true, pending: !completed });
    }

    const decision = this.riskEngine.assess(intent, context);
    const status = decision.authorized ? "RISK_AUTHORIZED" : "RISK_REJECTED";
    const reason = decision.authorized ? undefined : decision.violations.map(v => v.code).join(", ");
    const order = initial.transition(status, "RISK_ENGINE", decision.assessedAt, reason);
    const decisionEvent = createDomainEvent({
      eventId: `evt-${intent.id}-${decision.authorized ? "validated" : "rejected"}`,
      eventType: decision.authorized ? "OrderValidated" : "OrderRejected", aggregateId: order.id,
      aggregateVersion: 2, occurredAt: decision.assessedAt, correlationId: intent.input.correlationId,
      causationId: createdEvent.eventId, payload: { intentId: intent.id, decisionId: decision.decisionId, violations: decision.violations },
    });
    await this.registry.recordRiskDecisionAndEvents(order.id, order, decision, [decisionEvent]);
    return Object.freeze({ order, decision, events: Object.freeze([createdEvent, decisionEvent]), duplicate: false, pending: false });
  }
}
