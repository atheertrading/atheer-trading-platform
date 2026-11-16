import { Decimal, DomainError, UtcTimestamp } from "./shared.js";
import { MarketQuote, OrderIntent, TradingAccount, TradingInstrument, TradingPosition, TradingSession, identifier } from "./models.js";
import type { AccountId, InstrumentId } from "./models.js";

export interface RiskViolation {
  readonly code: string;
  readonly message: string;
  readonly severity: "BLOCK";
}

export interface RiskContext {
  readonly account: TradingAccount;
  readonly session: TradingSession;
  readonly instrument: TradingInstrument;
  readonly quote: MarketQuote;
  readonly positions: readonly TradingPosition[];
  readonly existingGrossExposureByCurrency: ReadonlyMap<string, Decimal>;
  readonly exposureSnapshotComplete: boolean;
  readonly assessedAt: UtcTimestamp;
  readonly emergencyHalt: boolean;
}

export interface RiskPolicy {
  readonly id: string;
  readonly version: string;
  evaluate(intent: OrderIntent, context: RiskContext): readonly RiskViolation[];
}

export interface RiskDecision {
  readonly decisionId: string;
  readonly intentId: string;
  readonly accountId: AccountId;
  readonly instrumentId: InstrumentId;
  readonly authorized: boolean;
  readonly policyVersion: string;
  readonly assessedAt: UtcTimestamp;
  readonly violations: readonly RiskViolation[];
}

export class MaximumOrderQuantityPolicy implements RiskPolicy {
  private readonly maximum: Decimal;
  constructor(readonly id: string, readonly version: string, maximumQuantity: Decimal | string) {
    this.maximum = Decimal.parse(maximumQuantity);
    if (!this.maximum.isPositive) throw new DomainError("INVALID_RISK_LIMIT", "Maximum order quantity must be positive.");
  }
  evaluate(intent: OrderIntent): readonly RiskViolation[] {
    return intent.quantity.compare(this.maximum) > 0
      ? [{ code: "MAX_ORDER_QUANTITY_EXCEEDED", message: `Order quantity exceeds configured maximum ${this.maximum}.`, severity: "BLOCK" }]
      : [];
  }
}

export class MaximumInstrumentExposurePolicy implements RiskPolicy {
  private readonly maximum: Decimal;
  constructor(readonly id: string, readonly version: string, maximumExposure: Decimal | string) {
    this.maximum = Decimal.parse(maximumExposure);
    if (!this.maximum.isPositive) throw new DomainError("INVALID_RISK_LIMIT", "Maximum instrument exposure must be positive.");
  }
  evaluate(intent: OrderIntent, context: RiskContext): readonly RiskViolation[] {
    if (intent.input.operation === "REDUCE" || intent.input.operation === "CLOSE") return [];
    if (context.instrument.specification.input.valuationModel !== "LINEAR") {
      return [{ code: "UNSUPPORTED_EXPOSURE_MODEL", message: "No approved exposure calculator exists for this instrument valuation model.", severity: "BLOCK" }];
    }
    const mark = context.quote.executablePrice(intent.input.side);
    const proposed = intent.quantity.multiply(mark).multiply(context.instrument.specification.contractMultiplier);
    const existing = context.positions
      .filter(position => position.input.instrumentId === intent.input.instrumentId && position.input.status !== "CLOSED")
      .reduce((total, position) => total.add(position.quantity.multiply(mark).multiply(context.instrument.specification.contractMultiplier)), Decimal.zero());
    return existing.add(proposed).compare(this.maximum) > 0
      ? [{ code: "MAX_INSTRUMENT_EXPOSURE_EXCEEDED", message: `Proposed exposure exceeds configured instrument limit ${this.maximum}.`, severity: "BLOCK" }]
      : [];
  }
}

export class MaximumAccountExposurePolicy implements RiskPolicy {
  private readonly maximum: Decimal;
  constructor(readonly id: string, readonly version: string, maximumExposureInAccountCurrency: Decimal | string) {
    this.maximum = Decimal.parse(maximumExposureInAccountCurrency);
    if (!this.maximum.isPositive) throw new DomainError("INVALID_RISK_LIMIT", "Maximum account exposure must be positive.");
  }
  evaluate(intent: OrderIntent, context: RiskContext): readonly RiskViolation[] {
    if (intent.input.operation === "REDUCE" || intent.input.operation === "CLOSE") return [];
    if (context.instrument.specification.input.valuationModel !== "LINEAR") {
      return [{ code: "UNSUPPORTED_ACCOUNT_EXPOSURE_MODEL", message: "No approved account exposure calculator exists for this instrument valuation model.", severity: "BLOCK" }];
    }
    const currency = context.instrument.quoteCurrency;
    if (!currency || currency !== context.account.currency) {
      return [{ code: "ACCOUNT_EXPOSURE_FX_REQUIRED", message: "Account-level exposure cannot be aggregated without an approved FX conversion rate.", severity: "BLOCK" }];
    }
    const multiplier = context.instrument.specification.contractMultiplier;
    const mark = context.quote.executablePrice(intent.input.side);
    if (!context.exposureSnapshotComplete) {
      return [{ code: "ACCOUNT_EXPOSURE_SNAPSHOT_INCOMPLETE", message: "Account-wide exposure snapshot is incomplete; authorization fails closed.", severity: "BLOCK" }];
    }
    const existing = context.existingGrossExposureByCurrency.get(currency) ?? Decimal.zero();
    const proposed = intent.quantity.multiply(mark).multiply(multiplier);
    return existing.add(proposed).compare(this.maximum) > 0
      ? [{ code: "MAX_ACCOUNT_EXPOSURE_EXCEEDED", message: `Proposed account exposure exceeds configured limit ${this.maximum}.`, severity: "BLOCK" }]
      : [];
  }
}

export interface RiskEngineOptions {
  readonly policyVersion: string;
  readonly maximumQuoteAgeMilliseconds: number;
  readonly policies: readonly RiskPolicy[];
}

/** Fail-closed risk authority. No policy means no authorization; LIVE is unconditionally blocked. */
export class RiskEngine {
  constructor(private readonly options: RiskEngineOptions) {
    if (!options.policyVersion.trim()) throw new DomainError("INVALID_POLICY_VERSION", "Risk policy version is required.");
    if (!Number.isSafeInteger(options.maximumQuoteAgeMilliseconds) || options.maximumQuoteAgeMilliseconds <= 0) throw new DomainError("INVALID_FRESHNESS_LIMIT", "Risk quote age limit must be a positive integer.");
    if (new Set(options.policies.map(policy => policy.id)).size !== options.policies.length) throw new DomainError("DUPLICATE_RISK_POLICY", "Risk policy identifiers must be unique.");
  }

  assess(intent: OrderIntent, context: RiskContext): RiskDecision {
    const violations: RiskViolation[] = [];
    const block = (code: string, message: string): void => { violations.push({ code, message, severity: "BLOCK" }); };

    if (context.account.id !== intent.input.accountId) block("ACCOUNT_MISMATCH", "Intent account does not match the risk context account.");
    if (context.instrument.id !== intent.input.instrumentId) block("INSTRUMENT_MISMATCH", "Intent instrument does not match the risk context instrument.");
    if (context.account.environment !== intent.input.environment || context.session.input.environment !== intent.input.environment) block("ENVIRONMENT_MISMATCH", "Intent, account and session environments must match.");
    if (context.session.input.accountId !== intent.input.accountId) block("SESSION_ACCOUNT_MISMATCH", "Trading session does not belong to the intent account.");
    if (context.account.input.status !== "ACTIVE" || !context.account.input.platformTradingEnabled) block("ACCOUNT_NOT_AUTHORIZED", "Account is not enabled by platform authorization.");
    if (intent.input.environment === "LIVE") block("LIVE_TRADING_DISABLED", "LIVE trading is disabled by the current platform safety baseline.");
    const exposureIncreasing = intent.input.operation === "OPEN" || intent.input.operation === "INCREASE";
    if (context.session.input.state === "CLOSED") block("SESSION_CLOSED", "Closed trading sessions cannot accept new order intents.");
    else if (context.session.input.state !== "ACTIVE" && exposureIncreasing) block("SESSION_NOT_ACTIVE", "Trading session is not active for exposure-increasing intents.");
    if (context.emergencyHalt && exposureIncreasing) block("TRADING_HALTED", "Emergency halt blocks exposure-increasing intents.");
    if (!context.instrument.active) block("INSTRUMENT_INACTIVE", "Instrument is not active for trading.");
    if (context.quote.input.instrumentId !== intent.input.instrumentId) block("QUOTE_INSTRUMENT_MISMATCH", "Market quote does not match the intent instrument.");
    if (!context.quote.isFreshAt(context.assessedAt, this.options.maximumQuoteAgeMilliseconds)) block("MARKET_DATA_STALE", "Market quote is stale or has a future source timestamp.");

    try {
      context.instrument.specification.validateQuantity(intent.quantity);
      if (intent.limitPrice) context.instrument.specification.validatePrice(intent.limitPrice);
      if (intent.stopPrice) context.instrument.specification.validatePrice(intent.stopPrice);
      if (intent.stopLossPrice) context.instrument.specification.validatePrice(intent.stopLossPrice);
      if (intent.takeProfitPrice) context.instrument.specification.validatePrice(intent.takeProfitPrice);
    } catch (error) {
      block(error instanceof DomainError ? error.code : "INSTRUMENT_VALIDATION_FAILED", error instanceof Error ? error.message : "Instrument validation failed.");
    }

    if (this.options.policies.length === 0) block("RISK_POLICY_UNAVAILABLE", "No active risk policies are configured; authorization fails closed.");
    for (const policy of this.options.policies) violations.push(...policy.evaluate(intent, context));

    return Object.freeze({
      decisionId: identifier(`risk-${intent.id}-${context.assessedAt.epochMilliseconds}`, "RiskDecisionId"),
      intentId: intent.id,
      accountId: intent.input.accountId,
      instrumentId: intent.input.instrumentId,
      authorized: violations.length === 0,
      policyVersion: this.options.policyVersion,
      assessedAt: context.assessedAt,
      violations: Object.freeze(violations),
    });
  }
}
