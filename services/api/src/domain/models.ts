import { Decimal, DomainError, Money, UtcTimestamp, requiredText, currency } from "./shared.js";

export type TradingEnvironment = "DEMO" | "SIMULATION" | "BACKTEST" | "LIVE";
export type AssetClass = "FOREX" | "EQUITY" | "ETF" | "INDEX" | "COMMODITY" | "CRYPTO" | "BOND" | "OPTION" | "FUTURE" | "OTHER";
export type OrderSide = "BUY" | "SELL";
export type OrderType = "MARKET" | "LIMIT" | "STOP" | "STOP_LIMIT";
export type IntentOperation = "OPEN" | "INCREASE" | "REDUCE" | "CLOSE";
export type OrderSourceType = "MANUAL" | "STRATEGY" | "ALGORITHM" | "AI_AGENT" | "POSITION_MANAGEMENT" | "RISK_CONTROL" | "EXTERNAL";
export type ProvenanceKind = "BROKER" | "INTERNAL" | "HISTORICAL" | "SIMULATION" | "BACKTEST";

export type Identifier<Kind extends string> = string & { readonly __identifier: Kind };
export function identifier<Kind extends string>(value: string, kind: Kind): Identifier<Kind> {
  const normalized = requiredText(value, `${kind} identifier`);
  if (normalized.length > 128) throw new DomainError("INVALID_IDENTIFIER", `${kind} identifier exceeds 128 characters.`);
  return normalized as Identifier<Kind>;
}

export type InstrumentId = Identifier<"InstrumentId">;
export type AccountId = Identifier<"AccountId">;
export type OrderId = Identifier<"OrderId">;
export type IntentId = Identifier<"IntentId">;
export type PositionId = Identifier<"PositionId">;
export type ExecutionId = Identifier<"ExecutionId">;
export type SessionId = Identifier<"SessionId">;
export type PortfolioId = Identifier<"PortfolioId">;
export type TradeId = Identifier<"TradeId">;
export type BrokerId = Identifier<"BrokerId">;

export interface DataProvenance {
  readonly kind: ProvenanceKind;
  readonly sourceId: string;
  readonly observedAt: UtcTimestamp;
  readonly normalizationVersion: string;
}

export interface InstrumentSpecificationInput {
  readonly pricePrecision: number;
  readonly quantityPrecision: number;
  readonly priceTick: Decimal | string;
  readonly quantityStep: Decimal | string;
  readonly minimumQuantity: Decimal | string;
  readonly maximumQuantity?: Decimal | string;
  readonly contractMultiplier: Decimal | string;
  readonly valuationModel: "LINEAR" | "BROKER_REPORTED";
  readonly effectiveFrom: UtcTimestamp;
  readonly provenance: DataProvenance;
}

export class InstrumentSpecification {
  readonly priceTick: Decimal;
  readonly quantityStep: Decimal;
  readonly minimumQuantity: Decimal;
  readonly maximumQuantity?: Decimal;
  readonly contractMultiplier: Decimal;
  readonly input: InstrumentSpecificationInput;

  constructor(input: InstrumentSpecificationInput) {
    const { pricePrecision, quantityPrecision } = input;
    if (!Number.isInteger(pricePrecision) || pricePrecision < 0 || pricePrecision > 18 || !Number.isInteger(quantityPrecision) || quantityPrecision < 0 || quantityPrecision > 18) {
      throw new DomainError("INVALID_PRECISION", "Instrument precision must be an integer from 0 through 18.");
    }
    this.priceTick = Decimal.parse(input.priceTick);
    this.quantityStep = Decimal.parse(input.quantityStep);
    this.minimumQuantity = Decimal.parse(input.minimumQuantity);
    this.maximumQuantity = input.maximumQuantity === undefined ? undefined : Decimal.parse(input.maximumQuantity);
    this.contractMultiplier = Decimal.parse(input.contractMultiplier);
    if (!this.priceTick.isPositive || !this.quantityStep.isPositive || !this.minimumQuantity.isPositive || !this.contractMultiplier.isPositive) {
      throw new DomainError("INVALID_SPECIFICATION", "Ticks, steps, minimum quantity and contract multiplier must be positive.");
    }
    if (this.maximumQuantity && this.maximumQuantity.compare(this.minimumQuantity) < 0) throw new DomainError("INVALID_SPECIFICATION", "Maximum quantity cannot be below minimum quantity.");
    if (this.priceTick.scale > pricePrecision || this.quantityStep.scale > quantityPrecision || this.minimumQuantity.scale > quantityPrecision || (this.maximumQuantity && this.maximumQuantity.scale > quantityPrecision)) {
      throw new DomainError("INVALID_PRECISION", "Instrument specification values exceed declared precision.");
    }
    if (!input.provenance.sourceId.trim() || !input.provenance.normalizationVersion.trim()) throw new DomainError("INVALID_PROVENANCE", "Instrument specification provenance is required.");
    this.input = Object.freeze({ ...input, priceTick: this.priceTick, quantityStep: this.quantityStep, minimumQuantity: this.minimumQuantity, maximumQuantity: this.maximumQuantity, contractMultiplier: this.contractMultiplier, provenance: Object.freeze({ ...input.provenance }) });
    Object.freeze(this);
  }

  validateQuantity(quantity: Decimal): void {
    if (quantity.compare(this.minimumQuantity) < 0) throw new DomainError("QUANTITY_BELOW_MINIMUM", "Order quantity is below the instrument minimum.");
    if (this.maximumQuantity && quantity.compare(this.maximumQuantity) > 0) throw new DomainError("QUANTITY_ABOVE_MAXIMUM", "Order quantity exceeds the instrument maximum.");
    if (quantity.scale > this.input.quantityPrecision) throw new DomainError("INVALID_QUANTITY_PRECISION", "Order quantity exceeds instrument precision.");
    if (quantity.divide(this.quantityStep, 36, "toward-zero").scale !== 0) {
      throw new DomainError("INVALID_QUANTITY_STEP", "Order quantity is not aligned to the instrument quantity step.");
    }
  }

  validatePrice(price: Decimal): void {
    if (!price.isPositive) throw new DomainError("INVALID_PRICE", "Price must be positive.");
    if (price.scale > this.input.pricePrecision) throw new DomainError("INVALID_PRICE_PRECISION", "Price exceeds instrument precision.");
    if (price.divide(this.priceTick, 36, "toward-zero").scale !== 0) {
      throw new DomainError("INVALID_PRICE_TICK", "Price is not aligned to the instrument price tick.");
    }
  }
}

export interface BrokerInstrumentReference {
  readonly brokerId: BrokerId;
  readonly instrumentReference: string;
  readonly activeFrom: UtcTimestamp;
  readonly activeUntil?: UtcTimestamp;
}

export class TradingInstrument {
  readonly id: InstrumentId;
  readonly symbol: string;
  readonly baseCurrency?: string;
  readonly quoteCurrency?: string;
  constructor(input: { id: string; symbol: string; name: string; assetClass: AssetClass; baseCurrency?: string; quoteCurrency?: string; specification: InstrumentSpecification; brokerReferences?: readonly BrokerInstrumentReference[]; active: boolean }) {
    this.id = identifier(input.id, "InstrumentId");
    this.symbol = requiredText(input.symbol, "Instrument symbol").toUpperCase();
    this.name = requiredText(input.name, "Instrument name");
    this.assetClass = input.assetClass;
    this.baseCurrency = input.baseCurrency ? currency(input.baseCurrency) : undefined;
    this.quoteCurrency = input.quoteCurrency ? currency(input.quoteCurrency) : undefined;
    this.specification = input.specification;
    this.brokerReferences = Object.freeze([...(input.brokerReferences ?? [])].map(reference => Object.freeze({ ...reference })));
    if (new Set(this.brokerReferences.map(reference => `${reference.brokerId}:${reference.instrumentReference}`)).size !== this.brokerReferences.length) throw new DomainError("DUPLICATE_BROKER_INSTRUMENT_REFERENCE", "Broker instrument references must be unique.");
    this.active = input.active;
    Object.freeze(this);
  }
  readonly name: string;
  readonly assetClass: AssetClass;
  readonly specification: InstrumentSpecification;
  readonly brokerReferences: readonly BrokerInstrumentReference[];
  readonly active: boolean;
}

export class MarketQuote {
  readonly bid: Decimal;
  readonly ask: Decimal;
  readonly input: { instrumentId: InstrumentId; bid: Decimal | string; ask: Decimal | string; source: string; sourceEventTime: UtcTimestamp; receivedAt: UtcTimestamp; sequence?: string };
  constructor(input: { instrumentId: InstrumentId; bid: Decimal | string; ask: Decimal | string; source: string; sourceEventTime: UtcTimestamp; receivedAt: UtcTimestamp; sequence?: string }) {
    this.bid = Decimal.parse(input.bid);
    this.ask = Decimal.parse(input.ask);
    if (!this.bid.isPositive || !this.ask.isPositive || this.bid.compare(this.ask) > 0) throw new DomainError("INVALID_QUOTE", "Quote requires positive bid and ask with bid no greater than ask.");
    if (input.receivedAt.isBefore(input.sourceEventTime)) throw new DomainError("INVALID_QUOTE_TIME", "Quote receipt time cannot precede source event time.");
    requiredText(input.source, "Quote source");
    this.input = Object.freeze({ ...input, bid: this.bid, ask: this.ask });
    Object.freeze(this);
  }
  isFreshAt(now: UtcTimestamp, maximumAgeMilliseconds: number): boolean {
    if (!Number.isSafeInteger(maximumAgeMilliseconds) || maximumAgeMilliseconds < 0) throw new DomainError("INVALID_FRESHNESS_LIMIT", "Maximum quote age must be a non-negative integer.");
    const age = this.input.sourceEventTime.ageMillisecondsAt(now);
    return age >= 0 && age <= maximumAgeMilliseconds;
  }
  executablePrice(side: OrderSide): Decimal { return side === "BUY" ? this.ask : this.bid; }
}

export class TradingAccount {
  readonly id: AccountId;
  readonly brokerId: BrokerId;
  readonly currency: string;
  readonly input: { id: string; brokerId: string; environment: TradingEnvironment; currency: string; status: "ACTIVE" | "SUSPENDED" | "CLOSED"; brokerAccountReference?: string; brokerTradingEnabled: boolean; platformTradingEnabled: boolean; provenance: DataProvenance };
  constructor(input: { id: string; brokerId: string; environment: TradingEnvironment; currency: string; status: "ACTIVE" | "SUSPENDED" | "CLOSED"; brokerAccountReference?: string; brokerTradingEnabled: boolean; platformTradingEnabled: boolean; provenance: DataProvenance }) {
    this.id = identifier(input.id, "AccountId");
    this.brokerId = identifier(input.brokerId, "BrokerId");
    this.currency = currency(input.currency);
    if (input.environment === "LIVE" && input.platformTradingEnabled) throw new DomainError("LIVE_TRADING_DISABLED", "Platform LIVE trading is disabled by the current safety baseline.");
    if (input.status !== "ACTIVE" && input.platformTradingEnabled) throw new DomainError("ACCOUNT_NOT_ACTIVE", "Non-active accounts cannot be platform-enabled for trading.");
    if (!input.provenance.sourceId.trim()) throw new DomainError("INVALID_PROVENANCE", "Account provenance is required.");
    this.input = Object.freeze({ ...input, provenance: Object.freeze({ ...input.provenance }) });
    Object.freeze(this);
  }
  get environment(): TradingEnvironment { return this.input.environment; }
  get canTrade(): boolean { return this.input.status === "ACTIVE" && this.input.platformTradingEnabled && this.input.environment !== "LIVE"; }
}

export class TradingBalance {
  readonly input: { accountId: AccountId; cash: Money; equity: Money; available: Money; usedMargin: Money; unrealizedPnl: Money; realizedPnl: Money; observedAt: UtcTimestamp; provenance: DataProvenance };
  constructor(input: { accountId: AccountId; cash: Money; equity: Money; available: Money; usedMargin: Money; unrealizedPnl: Money; realizedPnl: Money; observedAt: UtcTimestamp; provenance: DataProvenance }) {
    const amounts = [input.equity, input.available, input.usedMargin, input.unrealizedPnl, input.realizedPnl];
    if (amounts.some(value => value.currency !== input.cash.currency)) throw new DomainError("BALANCE_CURRENCY_MISMATCH", "All account balance values must use the account currency.");
    if (input.usedMargin.amount.isNegative) throw new DomainError("INVALID_MARGIN", "Used margin cannot be negative.");
    this.input = Object.freeze({ ...input, provenance: Object.freeze({ ...input.provenance }) });
    Object.freeze(this);
  }
}

export class TradingSession {
  readonly id: SessionId;
  readonly input: { id: string; accountId: AccountId; environment: TradingEnvironment; startedAt: UtcTimestamp; endedAt?: UtcTimestamp; state: "ACTIVE" | "HALTED" | "CLOSED"; haltReason?: string };
  private constructor(input: { id: string; accountId: AccountId; environment: TradingEnvironment; startedAt: UtcTimestamp; endedAt?: UtcTimestamp; state: "ACTIVE" | "HALTED" | "CLOSED"; haltReason?: string }) {
    this.id = identifier(input.id, "SessionId");
    if (input.endedAt && input.endedAt.isBefore(input.startedAt)) throw new DomainError("INVALID_SESSION_TIME", "Session end cannot precede its start.");
    this.input = Object.freeze({ ...input });
    Object.freeze(this);
  }
  static start(input: { id: string; accountId: AccountId; environment: TradingEnvironment; startedAt: UtcTimestamp }): TradingSession {
    return new TradingSession({ ...input, state: "ACTIVE" });
  }
  halt(reason: string): TradingSession {
    if (this.input.state !== "ACTIVE") throw new DomainError("INVALID_SESSION_TRANSITION", "Only an active session can be halted.");
    return new TradingSession({ ...this.input, state: "HALTED", haltReason: requiredText(reason, "Halt reason") });
  }
  close(at: UtcTimestamp): TradingSession {
    if (this.input.state === "CLOSED") throw new DomainError("INVALID_SESSION_TRANSITION", "Session is already closed.");
    if (at.isBefore(this.input.startedAt)) throw new DomainError("INVALID_SESSION_TIME", "Session cannot close before it starts.");
    return new TradingSession({ ...this.input, state: "CLOSED", endedAt: at });
  }
}

export interface OrderIntentInput {
  readonly id: string;
  readonly accountId: AccountId;
  readonly instrumentId: InstrumentId;
  readonly environment: TradingEnvironment;
  readonly sourceType: OrderSourceType;
  readonly sourceId: string;
  readonly operation: IntentOperation;
  readonly side: OrderSide;
  readonly orderType: OrderType;
  readonly quantity: Decimal | string;
  readonly limitPrice?: Decimal | string;
  readonly stopPrice?: Decimal | string;
  readonly stopLossPrice?: Decimal | string;
  readonly takeProfitPrice?: Decimal | string;
  readonly idempotencyKey: string;
  readonly correlationId: string;
  readonly causationId?: string;
  readonly createdAt: UtcTimestamp;
  readonly strategyId?: string;
  readonly positionId?: PositionId;
}

export class OrderIntent {
  readonly id: IntentId;
  readonly input: OrderIntentInput;
  readonly quantity: Decimal;
  readonly limitPrice?: Decimal;
  readonly stopPrice?: Decimal;
  readonly stopLossPrice?: Decimal;
  readonly takeProfitPrice?: Decimal;
  readonly idempotencyKey: string;
  constructor(input: OrderIntentInput) {
    this.id = identifier(input.id, "IntentId");
    this.quantity = Decimal.parse(input.quantity);
    this.limitPrice = input.limitPrice === undefined ? undefined : Decimal.parse(input.limitPrice);
    this.stopPrice = input.stopPrice === undefined ? undefined : Decimal.parse(input.stopPrice);
    this.stopLossPrice = input.stopLossPrice === undefined ? undefined : Decimal.parse(input.stopLossPrice);
    this.takeProfitPrice = input.takeProfitPrice === undefined ? undefined : Decimal.parse(input.takeProfitPrice);
    this.idempotencyKey = requiredText(input.idempotencyKey, "Idempotency key");
    requiredText(input.sourceId, "Order source ID");
    requiredText(input.correlationId, "Correlation ID");
    if (!this.quantity.isPositive) throw new DomainError("INVALID_ORDER_QUANTITY", "Order quantity must be positive.");
    if ((input.orderType === "LIMIT" || input.orderType === "STOP_LIMIT") && !this.limitPrice) throw new DomainError("LIMIT_PRICE_REQUIRED", "Limit order types require a limit price.");
    if (input.orderType === "MARKET" && (this.limitPrice || this.stopPrice)) throw new DomainError("UNEXPECTED_ORDER_PRICE", "Market orders cannot carry limit or stop trigger prices.");
    if (input.orderType === "LIMIT" && this.stopPrice) throw new DomainError("UNEXPECTED_STOP_PRICE", "Limit orders cannot carry a stop trigger price.");
    if (input.orderType === "STOP" && this.limitPrice) throw new DomainError("UNEXPECTED_LIMIT_PRICE", "Stop orders cannot carry a limit price.");
    if ((input.orderType === "STOP" || input.orderType === "STOP_LIMIT") && !this.stopPrice) throw new DomainError("STOP_PRICE_REQUIRED", "Stop order types require a stop price.");
    if (this.limitPrice && !this.limitPrice.isPositive) throw new DomainError("INVALID_LIMIT_PRICE", "Limit price must be positive.");
    if (this.stopPrice && !this.stopPrice.isPositive) throw new DomainError("INVALID_STOP_PRICE", "Stop price must be positive.");
    if (this.stopLossPrice && !this.stopLossPrice.isPositive) throw new DomainError("INVALID_STOP_LOSS", "Stop-loss price must be positive.");
    if (this.takeProfitPrice && !this.takeProfitPrice.isPositive) throw new DomainError("INVALID_TAKE_PROFIT", "Take-profit price must be positive.");
    if ((input.operation === "REDUCE" || input.operation === "CLOSE") && !input.positionId) throw new DomainError("POSITION_REQUIRED", "Reduce and close intents require a position identifier.");
    this.input = Object.freeze({ ...input, quantity: this.quantity, limitPrice: this.limitPrice, stopPrice: this.stopPrice, stopLossPrice: this.stopLossPrice, takeProfitPrice: this.takeProfitPrice });
    Object.freeze(this);
  }

  fingerprint(): string {
    return [this.input.accountId, this.input.instrumentId, this.input.environment, this.input.sourceType, this.input.sourceId,
      this.input.operation, this.input.side, this.input.orderType, this.quantity.toString(), this.limitPrice?.toString() ?? "",
      this.stopPrice?.toString() ?? "", this.stopLossPrice?.toString() ?? "", this.takeProfitPrice?.toString() ?? "", this.input.positionId ?? "", this.input.strategyId ?? ""].join("|");
  }
}

export type OrderStatus = "INTENT_RECEIVED" | "RISK_AUTHORIZED" | "RISK_REJECTED" | "SUBMISSION_PENDING" | "SUBMISSION_UNKNOWN" | "BROKER_ACCEPTED" | "PARTIALLY_FILLED" | "FILLED" | "CANCEL_PENDING" | "CANCELLED" | "REJECTED" | "RECONCILIATION_REQUIRED";
export type TransitionActor = "RISK_ENGINE" | "EXECUTION_GATEWAY" | "BROKER_REPORT" | "OMS" | "BROKER_RECONCILIATION";

export class OrderExecution {
  readonly id: ExecutionId;
  readonly input: { id: string; orderId: OrderId; brokerExecutionReference: string; quantity: Decimal | string; price: Decimal | string; occurredAt: UtcTimestamp; receivedAt: UtcTimestamp; commission?: Money; provenance: DataProvenance };
  readonly quantity: Decimal;
  readonly price: Decimal;
  constructor(input: { id: string; orderId: OrderId; brokerExecutionReference: string; quantity: Decimal | string; price: Decimal | string; occurredAt: UtcTimestamp; receivedAt: UtcTimestamp; commission?: Money; provenance: DataProvenance }) {
    this.id = identifier(input.id, "ExecutionId");
    this.quantity = Decimal.parse(input.quantity);
    this.price = Decimal.parse(input.price);
    if (!this.quantity.isPositive || !this.price.isPositive) throw new DomainError("INVALID_EXECUTION", "Execution quantity and price must be positive.");
    if (input.receivedAt.isBefore(input.occurredAt)) throw new DomainError("INVALID_EXECUTION_TIME", "Execution receipt cannot precede broker event time.");
    requiredText(input.brokerExecutionReference, "Broker execution reference");
    this.input = Object.freeze({ ...input, quantity: this.quantity, price: this.price, provenance: Object.freeze({ ...input.provenance }) });
    Object.freeze(this);
  }
}

const allowedTransitions: Record<OrderStatus, Partial<Record<OrderStatus, TransitionActor>>> = {
  INTENT_RECEIVED: { RISK_AUTHORIZED: "RISK_ENGINE", RISK_REJECTED: "RISK_ENGINE" },
  RISK_AUTHORIZED: { SUBMISSION_PENDING: "EXECUTION_GATEWAY" },
  RISK_REJECTED: {},
  SUBMISSION_PENDING: { BROKER_ACCEPTED: "BROKER_REPORT", REJECTED: "BROKER_REPORT", SUBMISSION_UNKNOWN: "OMS" },
  SUBMISSION_UNKNOWN: { RECONCILIATION_REQUIRED: "OMS" },
  BROKER_ACCEPTED: { PARTIALLY_FILLED: "BROKER_REPORT", FILLED: "BROKER_REPORT", CANCEL_PENDING: "EXECUTION_GATEWAY", RECONCILIATION_REQUIRED: "OMS" },
  PARTIALLY_FILLED: { PARTIALLY_FILLED: "BROKER_REPORT", FILLED: "BROKER_REPORT", CANCEL_PENDING: "EXECUTION_GATEWAY", RECONCILIATION_REQUIRED: "OMS" },
  CANCEL_PENDING: { CANCELLED: "BROKER_REPORT", PARTIALLY_FILLED: "BROKER_REPORT", FILLED: "BROKER_REPORT", RECONCILIATION_REQUIRED: "OMS" },
  RECONCILIATION_REQUIRED: { BROKER_ACCEPTED: "BROKER_RECONCILIATION", PARTIALLY_FILLED: "BROKER_RECONCILIATION", FILLED: "BROKER_RECONCILIATION", REJECTED: "BROKER_RECONCILIATION", CANCELLED: "BROKER_RECONCILIATION" },
  FILLED: {}, CANCELLED: {}, REJECTED: {},
};

export class TradingOrder {
  readonly id: OrderId;
  readonly input: { id: string; intent: OrderIntent; status: OrderStatus; createdAt: UtcTimestamp; updatedAt: UtcTimestamp; filledQuantity: Decimal; averageFillPrice?: Decimal; executions: readonly OrderExecution[]; rejectionReason?: string };
  readonly filledQuantity: Decimal;
  readonly averageFillPrice?: Decimal;
  readonly executions: readonly OrderExecution[];
  private constructor(input: { id: string; intent: OrderIntent; status: OrderStatus; createdAt: UtcTimestamp; updatedAt: UtcTimestamp; filledQuantity: Decimal; averageFillPrice?: Decimal; executions: readonly OrderExecution[]; rejectionReason?: string }) {
    this.id = identifier(input.id, "OrderId");
    this.filledQuantity = input.filledQuantity;
    this.averageFillPrice = input.averageFillPrice;
    this.executions = Object.freeze([...input.executions]);
    this.input = Object.freeze({ ...input, executions: this.executions });
    Object.freeze(this);
  }
  static fromIntent(id: string, intent: OrderIntent): TradingOrder {
    return new TradingOrder({ id, intent, status: "INTENT_RECEIVED", createdAt: intent.input.createdAt, updatedAt: intent.input.createdAt, filledQuantity: Decimal.zero(), executions: [] });
  }
  transition(next: OrderStatus, actor: TransitionActor, at: UtcTimestamp, reason?: string): TradingOrder {
    const expectedActor = allowedTransitions[this.input.status][next];
    if (!expectedActor || expectedActor !== actor) throw new DomainError("INVALID_ORDER_TRANSITION", `Transition ${this.input.status} -> ${next} is not permitted for ${actor}.`);
    if (at.isBefore(this.input.updatedAt)) throw new DomainError("INVALID_ORDER_TIME", "Order transitions must be chronological.");
    if ((next === "REJECTED" || next === "RISK_REJECTED") && !reason?.trim()) throw new DomainError("REJECTION_REASON_REQUIRED", "Broker rejection requires a reason.");
    return new TradingOrder({ ...this.input, status: next, updatedAt: at, rejectionReason: reason });
  }
  applyExecution(execution: OrderExecution): TradingOrder {
    if (execution.input.orderId !== this.id) throw new DomainError("EXECUTION_ORDER_MISMATCH", "Execution belongs to a different order.");
    if (this.executions.some(existing => existing.id === execution.id || existing.input.brokerExecutionReference === execution.input.brokerExecutionReference)) return this;
    if (!["BROKER_ACCEPTED", "PARTIALLY_FILLED", "CANCEL_PENDING", "RECONCILIATION_REQUIRED"].includes(this.input.status)) {
      throw new DomainError("ORDER_NOT_EXECUTABLE", `Cannot apply a broker fill while order is ${this.input.status}.`);
    }
    if (execution.input.receivedAt.isBefore(this.input.updatedAt)) throw new DomainError("INVALID_EXECUTION_TIME", "Execution report must not predate the current order state.");
    const total = this.filledQuantity.add(execution.quantity);
    if (total.compare(this.input.intent.quantity) > 0) throw new DomainError("OVERFILL", "Cumulative execution quantity exceeds the order quantity.");
    const weighted = (this.averageFillPrice ?? Decimal.zero()).multiply(this.filledQuantity).add(execution.price.multiply(execution.quantity));
    const average = weighted.divide(total, 18, "half-up");
    const status: OrderStatus = total.compare(this.input.intent.quantity) === 0 ? "FILLED" : "PARTIALLY_FILLED";
    return new TradingOrder({ ...this.input, status, updatedAt: execution.input.receivedAt, filledQuantity: total, averageFillPrice: average, executions: [...this.executions, execution] });
  }
}

export class TradingPosition {
  readonly id: PositionId;
  readonly input: { id: string; accountId: AccountId; instrumentId: InstrumentId; side: "LONG" | "SHORT"; quantity: Decimal; averageEntryPrice: Decimal; realizedPnl: Money; stopLoss?: Decimal; takeProfit?: Decimal; status: "OPEN" | "PARTIALLY_CLOSED" | "CLOSED"; openedAt: UtcTimestamp; updatedAt: UtcTimestamp; provenance: DataProvenance };
  readonly quantity: Decimal;
  readonly averageEntryPrice: Decimal;
  readonly calculatedRealizedPnl: Money;
  private constructor(input: { id: string; accountId: AccountId; instrumentId: InstrumentId; side: "LONG" | "SHORT"; quantity: Decimal; averageEntryPrice: Decimal; realizedPnl: Money; stopLoss?: Decimal; takeProfit?: Decimal; status: "OPEN" | "PARTIALLY_CLOSED" | "CLOSED"; openedAt: UtcTimestamp; updatedAt: UtcTimestamp; provenance: DataProvenance }) {
    this.id = identifier(input.id, "PositionId");
    this.quantity = input.quantity;
    this.averageEntryPrice = input.averageEntryPrice;
    this.calculatedRealizedPnl = input.realizedPnl;
    this.input = Object.freeze({ ...input, provenance: Object.freeze({ ...input.provenance }) });
    Object.freeze(this);
  }
  static open(input: { id: string; accountId: AccountId; instrumentId: InstrumentId; side: "LONG" | "SHORT"; quantity: Decimal | string; averageEntryPrice: Decimal | string; quoteCurrency: string; openedAt: UtcTimestamp; provenance: DataProvenance; stopLoss?: Decimal | string; takeProfit?: Decimal | string }): TradingPosition {
    const quantity = Decimal.parse(input.quantity), price = Decimal.parse(input.averageEntryPrice);
    if (!quantity.isPositive || !price.isPositive) throw new DomainError("INVALID_POSITION", "Position quantity and entry price must be positive.");
    const stopLoss = input.stopLoss === undefined ? undefined : Decimal.parse(input.stopLoss);
    const takeProfit = input.takeProfit === undefined ? undefined : Decimal.parse(input.takeProfit);
    if ((stopLoss && !stopLoss.isPositive) || (takeProfit && !takeProfit.isPositive)) throw new DomainError("INVALID_POSITION_PROTECTION", "Stop-loss and take-profit prices must be positive.");
    return new TradingPosition({ ...input, quantity, averageEntryPrice: price, realizedPnl: new Money("0", input.quoteCurrency), status: "OPEN", updatedAt: input.openedAt, stopLoss, takeProfit });
  }
  increase(quantityValue: Decimal | string, fillPriceValue: Decimal | string, at: UtcTimestamp): TradingPosition {
    if (this.input.status === "CLOSED") throw new DomainError("POSITION_CLOSED", "A closed position cannot be increased.");
    const quantity = Decimal.parse(quantityValue), price = Decimal.parse(fillPriceValue);
    if (!quantity.isPositive || !price.isPositive) throw new DomainError("INVALID_POSITION_FILL", "Position increase quantity and price must be positive.");
    const total = this.quantity.add(quantity);
    const average = this.averageEntryPrice.multiply(this.quantity).add(price.multiply(quantity)).divide(total, 18, "half-up");
    return new TradingPosition({ ...this.input, quantity: total, averageEntryPrice: average, updatedAt: at });
  }
  unrealizedPnl(markPriceValue: Decimal | string, contractMultiplierValue: Decimal | string): Money {
    if (this.input.status === "CLOSED") return new Money("0", this.calculatedRealizedPnl.currency);
    const mark = Decimal.parse(markPriceValue), multiplier = Decimal.parse(contractMultiplierValue);
    if (!mark.isPositive || !multiplier.isPositive) throw new DomainError("INVALID_VALUATION_INPUT", "Mark price and contract multiplier must be positive.");
    const delta = this.input.side === "LONG" ? mark.subtract(this.averageEntryPrice) : this.averageEntryPrice.subtract(mark);
    return new Money(delta.multiply(this.quantity).multiply(multiplier), this.calculatedRealizedPnl.currency);
  }

  grossExposure(markPriceValue: Decimal | string, contractMultiplierValue: Decimal | string): Money {
    const mark = Decimal.parse(markPriceValue), multiplier = Decimal.parse(contractMultiplierValue);
    if (!mark.isPositive || !multiplier.isPositive) throw new DomainError("INVALID_VALUATION_INPUT", "Mark price and contract multiplier must be positive.");
    return new Money(mark.multiply(this.quantity).multiply(multiplier), this.calculatedRealizedPnl.currency);
  }

  close(quantityValue: Decimal | string, exitPriceValue: Decimal | string, contractMultiplier: Decimal | string, at: UtcTimestamp): TradingPosition {
    if (this.input.status === "CLOSED") throw new DomainError("POSITION_CLOSED", "Position is already closed.");
    const quantity = Decimal.parse(quantityValue), exitPrice = Decimal.parse(exitPriceValue), multiplier = Decimal.parse(contractMultiplier);
    if (!quantity.isPositive || !exitPrice.isPositive || !multiplier.isPositive) throw new DomainError("INVALID_POSITION_CLOSE", "Close quantity, exit price and multiplier must be positive.");
    if (quantity.compare(this.quantity) > 0) throw new DomainError("POSITION_OVER_CLOSE", "Close quantity exceeds the open position quantity.");
    const priceDelta = this.input.side === "LONG" ? exitPrice.subtract(this.averageEntryPrice) : this.averageEntryPrice.subtract(exitPrice);
    const realized = new Money(priceDelta.multiply(quantity).multiply(multiplier), this.calculatedRealizedPnl.currency);
    const remaining = this.quantity.subtract(quantity);
    return new TradingPosition({ ...this.input, quantity: remaining, realizedPnl: this.calculatedRealizedPnl.add(realized), status: remaining.isZero ? "CLOSED" : "PARTIALLY_CLOSED", updatedAt: at });
  }
}

export class Portfolio {
  readonly positions: readonly TradingPosition[];
  readonly input: { id: string; accountId: AccountId; baseCurrency: string; positions: readonly TradingPosition[]; observedAt: UtcTimestamp; provenance: DataProvenance };
  constructor(input: { id: string; accountId: AccountId; baseCurrency: string; positions: readonly TradingPosition[]; observedAt: UtcTimestamp; provenance: DataProvenance }) {
    identifier(input.id, "PortfolioId");
    currency(input.baseCurrency);
    if (input.positions.some(p => p.input.accountId !== input.accountId)) throw new DomainError("PORTFOLIO_ACCOUNT_MISMATCH", "All portfolio positions must belong to its account.");
    if (new Set(input.positions.map(p => p.id)).size !== input.positions.length) throw new DomainError("DUPLICATE_POSITION", "Portfolio cannot contain duplicate position identifiers.");
    this.positions = Object.freeze([...input.positions]);
    this.input = Object.freeze({ ...input, positions: this.positions, provenance: Object.freeze({ ...input.provenance }) });
    Object.freeze(this);
  }
  grossExposureByQuoteCurrency(instruments: ReadonlyMap<InstrumentId, TradingInstrument>, marks: ReadonlyMap<InstrumentId, Decimal>): ReadonlyMap<string, Decimal> {
    const totals = new Map<string, Decimal>();
    for (const position of this.positions.filter(p => p.input.status !== "CLOSED")) {
      const instrument = instruments.get(position.input.instrumentId);
      const mark = marks.get(position.input.instrumentId);
      if (!instrument || !mark || !instrument.quoteCurrency) throw new DomainError("VALUATION_INPUT_MISSING", "Portfolio exposure requires instrument metadata, mark price and quote currency.");
      if (instrument.specification.input.valuationModel !== "LINEAR") throw new DomainError("VALUATION_UNSUPPORTED", "Exposure calculation is not defined for this instrument valuation model.");
      const exposure = position.quantity.multiply(mark).multiply(instrument.specification.contractMultiplier);
      totals.set(instrument.quoteCurrency, (totals.get(instrument.quoteCurrency) ?? Decimal.zero()).add(exposure));
    }
    return totals;
  }
}

export class Trade {
  readonly id: TradeId;
  readonly input: { id: string; positionId: PositionId; accountId: AccountId; instrumentId: InstrumentId; openedAt: UtcTimestamp; closedAt?: UtcTimestamp; status: "OPEN" | "CLOSED"; realizedPnl: Money };
  constructor(input: { id: string; positionId: PositionId; accountId: AccountId; instrumentId: InstrumentId; openedAt: UtcTimestamp; closedAt?: UtcTimestamp; status: "OPEN" | "CLOSED"; realizedPnl: Money }) {
    this.id = identifier(input.id, "TradeId");
    if ((input.status === "CLOSED") !== Boolean(input.closedAt)) throw new DomainError("INVALID_TRADE_STATE", "Closed trades require a close timestamp; open trades must not have one.");
    if (input.closedAt && input.closedAt.isBefore(input.openedAt)) throw new DomainError("INVALID_TRADE_TIME", "Trade cannot close before it opens.");
    this.input = Object.freeze({ ...input });
    Object.freeze(this);
  }
}

export interface BrokerPositionSnapshot {
  readonly positionId: PositionId;
  readonly accountId: AccountId;
  readonly instrumentId: InstrumentId;
  readonly side: "LONG" | "SHORT";
  readonly quantity: Decimal;
  readonly averageEntryPrice: Decimal;
  readonly realizedPnl: Money;
  readonly unrealizedPnl: Money;
  readonly observedAt: UtcTimestamp;
  readonly provenance: DataProvenance;
}

export function reconcilePosition(local: TradingPosition, broker: BrokerPositionSnapshot): { readonly matched: boolean; readonly discrepancies: readonly string[]; readonly authoritative: BrokerPositionSnapshot } {
  const discrepancies: string[] = [];
  if (local.id !== broker.positionId) discrepancies.push("POSITION_ID_MISMATCH");
  if (local.input.accountId !== broker.accountId) discrepancies.push("ACCOUNT_MISMATCH");
  if (local.input.instrumentId !== broker.instrumentId) discrepancies.push("INSTRUMENT_MISMATCH");
  if (local.input.side !== broker.side) discrepancies.push("SIDE_MISMATCH");
  if (local.quantity.compare(broker.quantity) !== 0) discrepancies.push("QUANTITY_MISMATCH");
  if (local.averageEntryPrice.compare(broker.averageEntryPrice) !== 0) discrepancies.push("AVERAGE_ENTRY_PRICE_MISMATCH");
  if (local.calculatedRealizedPnl.currency !== broker.realizedPnl.currency || local.calculatedRealizedPnl.amount.compare(broker.realizedPnl.amount) !== 0) discrepancies.push("REALIZED_PNL_MISMATCH");
  return Object.freeze({ matched: discrepancies.length === 0, discrepancies: Object.freeze(discrepancies), authoritative: broker });
}


export interface BrokerOrderSnapshot {
  readonly orderId: OrderId;
  readonly brokerOrderReference: string;
  readonly status: "ACCEPTED" | "PARTIALLY_FILLED" | "FILLED" | "REJECTED" | "CANCELLED" | "UNKNOWN";
  readonly filledQuantity: Decimal;
  readonly averageFillPrice?: Decimal;
  readonly observedAt: UtcTimestamp;
  readonly provenance: DataProvenance;
}

export function reconcileOrder(local: TradingOrder, broker: BrokerOrderSnapshot): { readonly matched: boolean; readonly discrepancies: readonly string[]; readonly authoritative: BrokerOrderSnapshot } {
  const discrepancies: string[] = [];
  if (local.id !== broker.orderId) discrepancies.push("ORDER_ID_MISMATCH");
  if (local.filledQuantity.compare(broker.filledQuantity) !== 0) discrepancies.push("FILLED_QUANTITY_MISMATCH");
  if (local.averageFillPrice && broker.averageFillPrice && local.averageFillPrice.compare(broker.averageFillPrice) !== 0) discrepancies.push("AVERAGE_FILL_PRICE_MISMATCH");
  const expectedBrokerStatuses: Partial<Record<OrderStatus, BrokerOrderSnapshot["status"][]>> = {
    BROKER_ACCEPTED: ["ACCEPTED"], PARTIALLY_FILLED: ["PARTIALLY_FILLED"], FILLED: ["FILLED"],
    CANCELLED: ["CANCELLED"], REJECTED: ["REJECTED"], SUBMISSION_UNKNOWN: ["UNKNOWN"],
    RECONCILIATION_REQUIRED: ["UNKNOWN", "ACCEPTED", "PARTIALLY_FILLED", "FILLED", "REJECTED", "CANCELLED"],
  };
  const expected = expectedBrokerStatuses[local.input.status];
  if (expected && !expected.includes(broker.status)) discrepancies.push("ORDER_STATUS_MISMATCH");
  return Object.freeze({ matched: discrepancies.length === 0, discrepancies: Object.freeze(discrepancies), authoritative: broker });
}
