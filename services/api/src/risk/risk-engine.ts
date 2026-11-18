import {
  assertArray,
  assertRecord,
  compareDecimal,
  createDataProvenance,
  currencyCode,
  decimalValue,
  DomainValidationError,
  isMultipleOfIncrement,
  nonEmptyString,
  sourceId,
  tradingEnvironment,
  unitCode,
  utcTimestamp,
  type DataProvenance,
  type RiskAssessmentId,
  type TradingEnvironment,
  type UtcTimestamp,
} from "../domain/shared.ts";
import {
  validateAccountBalanceSnapshot,
  validateBrokerAccountIdentity,
  type AccountBalanceSnapshot,
  type BrokerAccountIdentity,
  type Money,
} from "../domain/account.ts";
import {
  validateInstrumentIdentity,
  validateInstrumentSpecification,
  type InstrumentIdentity,
  type InstrumentSpecification,
  type Price,
  type Quantity,
} from "../domain/instrument.ts";
import {
  createOrderIntentEnvelope,
  createRiskAssessment,
  type IntentOriginKind,
  type OrderIntentEnvelope,
  type RiskAssessment,
  type RiskDecisionOutcome,
} from "../domain/trading.ts";

export type AccountBalanceField =
  | "balance"
  | "equity"
  | "availableFunds"
  | "usedMargin"
  | "availableMargin"
  | "realizedPnl"
  | "unrealizedPnl";

export interface RiskFreshnessPolicy {
  /** Quotes at or below this age are classified as normal. */
  readonly normalQuoteAgeMs: number;
  /** New automated entries are blocked above this age. */
  readonly automatedEntryBlockAfterMs: number;
  /** New risk-increasing entries are blocked for all origins above this age. */
  readonly staleQuoteAfterMs: number;
  readonly accountSnapshotMaxAgeMs: number;
  readonly portfolioSnapshotMaxAgeMs: number;
  readonly maximumFutureClockSkewMs: number;
}

export interface RiskPolicy {
  readonly version: string;
  readonly environment: TradingEnvironment;
  readonly accountCurrency: string;
  readonly allowedIntentOrigins: readonly IntentOriginKind[];
  readonly allowedPermissionProfileReferences: readonly string[];
  /** This first increment intentionally supports only configured risk-increasing operations. */
  readonly riskIncreasingOperationCodes: readonly string[];
  readonly requiredAccountFields: readonly AccountBalanceField[];
  readonly minimumAvailableFunds?: Money;
  readonly minimumAvailableMargin?: Money;
  readonly maximumUsedMargin?: Money;
  readonly maximumOrderQuantity: Quantity;
  readonly maximumOpenPositions: number;
  readonly maximumOpenPositionsPerInstrument: number;
  readonly maximumPerTradeRisk: Money;
  readonly maximumAccountGrossExposure: Money;
  readonly maximumInstrumentGrossExposure: Money;
  readonly maximumDailyLoss: Money;
  readonly maximumDrawdown: Money;
  readonly maximumSpread: Price;
  readonly freshness: RiskFreshnessPolicy;
  readonly requireBrokerPriceIncrement: boolean;
  readonly requireStopLoss: boolean;
  /** Provider/domain code is policy-defined; no global stop-loss parameter name is assumed. */
  readonly stopLossParameterCode?: string;
}

export interface RiskMarketQuoteSnapshot {
  readonly id: string;
  readonly instrumentId: string;
  readonly environment: TradingEnvironment;
  readonly bid: Price;
  readonly ask: Price;
  readonly provenance: DataProvenance;
}

export interface PortfolioRiskSnapshot {
  readonly id: string;
  readonly intentId: string;
  readonly accountId: string;
  readonly instrumentId: string;
  readonly environment: TradingEnvironment;
  readonly asOf: UtcTimestamp;
  readonly valuationModelVersion: string;
  readonly projectedOpenPositions: number;
  readonly projectedOpenInstrumentPositions: number;
  /** Values are projected for this exact intent by the injected portfolio/valuation boundary. */
  readonly projectedPerTradeRisk: Money;
  readonly projectedAccountGrossExposure: Money;
  readonly projectedInstrumentGrossExposure: Money;
  readonly projectedDailyLoss: Money;
  readonly projectedDrawdown: Money;
  readonly provenance: DataProvenance;
}

export interface PreTradeRiskContext {
  readonly account: BrokerAccountIdentity;
  readonly accountSnapshot: AccountBalanceSnapshot;
  readonly instrument: InstrumentIdentity;
  readonly instrumentSpecification: InstrumentSpecification;
  readonly marketQuote: RiskMarketQuoteSnapshot;
  readonly portfolioRisk: PortfolioRiskSnapshot;
}

export interface RiskPolicyProvider {
  getPolicy(accountId: string, environment: TradingEnvironment): Promise<RiskPolicy | undefined>;
}

export interface RiskContextProvider {
  loadContext(intent: OrderIntentEnvelope): Promise<PreTradeRiskContext | undefined>;
}

export interface RiskClock {
  now(): UtcTimestamp;
}

export interface RiskAssessmentIdGenerator {
  next(): RiskAssessmentId;
}

export interface RiskTradingControls {
  isTradingEnabled(environment: TradingEnvironment): boolean;
  isEmergencyHalted(environment: TradingEnvironment): boolean;
}

interface DecimalParts {
  readonly coefficient: bigint;
  readonly scale: number;
}

function decimalParts(value: string): DecimalParts {
  const normalized = decimalValue(value);
  const negative = normalized.startsWith("-");
  const unsigned = negative ? normalized.slice(1) : normalized;
  const [whole, fraction = ""] = unsigned.split(".");
  return {
    coefficient: BigInt(whole + fraction) * (negative ? -1n : 1n),
    scale: fraction.length,
  };
}

/** Exact base-10 subtraction; no binary floating-point conversion is used. */
function subtractDecimal(left: string, right: string): string {
  const a = decimalParts(left);
  const b = decimalParts(right);
  const scale = Math.max(a.scale, b.scale);
  const coefficient =
    a.coefficient * 10n ** BigInt(scale - a.scale) -
    b.coefficient * 10n ** BigInt(scale - b.scale);
  const negative = coefficient < 0n;
  const digits = (negative ? -coefficient : coefficient).toString().padStart(scale + 1, "0");
  const whole = scale === 0 ? digits : digits.slice(0, -scale);
  const fraction = scale === 0 ? "" : digits.slice(-scale).replace(/0+$/, "");
  return decimalValue((negative ? "-" : "") + whole + (fraction.length > 0 ? "." + fraction : ""));
}

function decimalPlaces(value: string): number {
  const normalized = decimalValue(value);
  const point = normalized.indexOf(".");
  return point < 0 ? 0 : normalized.length - point - 1;
}

function positiveInteger(value: number, field: string): void {
  if (!Number.isSafeInteger(value) || value < 1) {
    throw new DomainValidationError("invalid_risk_policy", field + " must be a positive safe integer.");
  }
}

function nonNegativeInteger(value: number, field: string): void {
  if (!Number.isSafeInteger(value) || value < 0) {
    throw new DomainValidationError("invalid_risk_policy", field + " must be a non-negative safe integer.");
  }
}

function validateMoney(value: Money, field: string): void {
  assertRecord(value, field);
  const amount = decimalValue(value.amount);
  currencyCode(value.currency);
  if (compareDecimal(amount, decimalValue("0")) < 0) {
    throw new DomainValidationError("invalid_risk_money", field + " cannot be negative.");
  }
}

function validatePolicy(policy: RiskPolicy): void {
  assertRecord(policy, "risk_policy");
  assertArray(policy.allowedIntentOrigins, "risk_policy_origins");
  assertArray(policy.allowedPermissionProfileReferences, "risk_permission_profiles");
  assertArray(policy.riskIncreasingOperationCodes, "risk_policy_operations");
  assertArray(policy.requiredAccountFields, "risk_required_account_fields");
  assertRecord(policy.maximumOrderQuantity, "risk_maximum_order_quantity");
  assertRecord(policy.maximumSpread, "risk_maximum_spread");
  assertRecord(policy.freshness, "risk_freshness_policy");
  nonEmptyString(policy.version, "risk_policy_version");
  tradingEnvironment(policy.environment);
  currencyCode(policy.accountCurrency);

  if (policy.allowedIntentOrigins.length === 0 || policy.riskIncreasingOperationCodes.length === 0) {
    throw new DomainValidationError("incomplete_risk_policy", "Risk policy must declare allowed intent origins and risk-increasing operations.");
  }
  for (const reference of policy.allowedPermissionProfileReferences) {
    nonEmptyString(reference, "risk_permission_profile_reference");
  }
  for (const value of [policy.minimumAvailableFunds, policy.minimumAvailableMargin, policy.maximumUsedMargin]) {
    if (value !== undefined) validateMoney(value, "risk_margin_constraint");
    if (value !== undefined && value.currency !== policy.accountCurrency) {
      throw new DomainValidationError("risk_policy_currency_mismatch", "Account and margin policy values must use the configured account currency.");
    }
  }
  for (const origin of policy.allowedIntentOrigins) {
    if (!["HUMAN", "STRATEGY", "ALGORITHM", "POSITION_MANAGEMENT", "RISK_MANAGEMENT", "AI_AGENT", "SYSTEM"].includes(origin)) {
      throw new DomainValidationError("invalid_risk_policy_origin", "Risk policy contains an unsupported intent origin.");
    }
  }
  for (const operation of policy.riskIncreasingOperationCodes) nonEmptyString(operation, "risk_operation_code");
  for (const field of policy.requiredAccountFields) {
    if (!["balance", "equity", "availableFunds", "usedMargin", "availableMargin", "realizedPnl", "unrealizedPnl"].includes(field)) {
      throw new DomainValidationError("invalid_required_account_field", "Risk policy contains an unsupported account field.");
    }
  }

  decimalValue(policy.maximumOrderQuantity.value);
  unitCode(policy.maximumOrderQuantity.unit);
  if (compareDecimal(policy.maximumOrderQuantity.value, decimalValue("0")) <= 0) {
    throw new DomainValidationError("invalid_maximum_order_quantity", "Maximum order quantity must be positive.");
  }
  decimalValue(policy.maximumSpread.value);
  unitCode(policy.maximumSpread.unit);
  if (policy.maximumSpread.currency === undefined) {
    throw new DomainValidationError("missing_maximum_spread_currency", "Maximum spread must declare its price currency.");
  }
  currencyCode(policy.maximumSpread.currency);
  if (compareDecimal(policy.maximumSpread.value, decimalValue("0")) <= 0) {
    throw new DomainValidationError("invalid_maximum_spread", "Maximum spread must be positive.");
  }

  nonNegativeInteger(policy.maximumOpenPositions, "maximumOpenPositions");
  nonNegativeInteger(policy.maximumOpenPositionsPerInstrument, "maximumOpenPositionsPerInstrument");
  validateMoney(policy.maximumPerTradeRisk, "maximumPerTradeRisk");
  validateMoney(policy.maximumAccountGrossExposure, "maximumAccountGrossExposure");
  validateMoney(policy.maximumInstrumentGrossExposure, "maximumInstrumentGrossExposure");
  validateMoney(policy.maximumDailyLoss, "maximumDailyLoss");
  validateMoney(policy.maximumDrawdown, "maximumDrawdown");

  const freshness = policy.freshness;
  positiveInteger(freshness.normalQuoteAgeMs, "normalQuoteAgeMs");
  positiveInteger(freshness.automatedEntryBlockAfterMs, "automatedEntryBlockAfterMs");
  positiveInteger(freshness.staleQuoteAfterMs, "staleQuoteAfterMs");
  positiveInteger(freshness.accountSnapshotMaxAgeMs, "accountSnapshotMaxAgeMs");
  positiveInteger(freshness.portfolioSnapshotMaxAgeMs, "portfolioSnapshotMaxAgeMs");
  nonNegativeInteger(freshness.maximumFutureClockSkewMs, "maximumFutureClockSkewMs");
  if (
    freshness.normalQuoteAgeMs > freshness.automatedEntryBlockAfterMs ||
    freshness.automatedEntryBlockAfterMs > freshness.staleQuoteAfterMs
  ) {
    throw new DomainValidationError("invalid_quote_freshness_policy", "Quote-age thresholds must be ordered normal ≤ automated-entry-block ≤ stale.");
  }
  if (typeof policy.requireBrokerPriceIncrement !== "boolean" || typeof policy.requireStopLoss !== "boolean") {
    throw new DomainValidationError("invalid_risk_policy_flags", "Risk policy requirement flags must be boolean values.");
  }
  if (policy.requireStopLoss) nonEmptyString(policy.stopLossParameterCode ?? "", "stop_loss_parameter_code");
}

function validateContext(context: PreTradeRiskContext, intent: OrderIntentEnvelope): void {
  assertRecord(context, "pre_trade_risk_context");
  validateBrokerAccountIdentity(context.account);
  validateAccountBalanceSnapshot(context.account, context.accountSnapshot);
  validateInstrumentIdentity(context.instrument);
  validateInstrumentSpecification(context.instrumentSpecification);
  assertRecord(context.marketQuote, "risk_market_quote");
  assertRecord(context.marketQuote.bid, "risk_market_bid");
  assertRecord(context.marketQuote.ask, "risk_market_ask");
  assertRecord(context.portfolioRisk, "portfolio_risk_snapshot");
  createDataProvenance(context.marketQuote.provenance);
  createDataProvenance(context.portfolioRisk.provenance);

  nonEmptyString(context.marketQuote.id, "risk_market_quote_id");
  nonEmptyString(context.portfolioRisk.id, "portfolio_risk_snapshot_id");
  nonEmptyString(context.portfolioRisk.valuationModelVersion, "valuation_model_version");
  tradingEnvironment(context.marketQuote.environment);
  tradingEnvironment(context.portfolioRisk.environment);
  utcTimestamp(context.portfolioRisk.asOf);

  if (context.account.id !== intent.accountId || context.account.environment !== intent.environment) {
    throw new DomainValidationError("risk_account_identity_mismatch", "Risk context account does not match the order intent.");
  }
  if (
    context.instrument.id !== intent.instrumentId ||
    context.instrumentSpecification.instrumentId !== intent.instrumentId ||
    context.instrumentSpecification.id !== intent.instrumentSpecificationId ||
    context.instrumentSpecification.brokerReference.environment !== intent.environment
  ) {
    throw new DomainValidationError("risk_instrument_identity_mismatch", "Risk context instrument/specification does not match the order intent.");
  }
  if (
    context.marketQuote.instrumentId !== intent.instrumentId ||
    context.marketQuote.environment !== intent.environment ||
    context.marketQuote.provenance.environment !== intent.environment ||
    !["BROKER", "MARKET_DATA_PROVIDER"].includes(context.marketQuote.provenance.source.sourceType)
  ) {
    throw new DomainValidationError("risk_market_provenance_mismatch", "Market quote must identify the intent instrument, environment and an approved provider source.");
  }
  if (
    context.marketQuote.provenance.eventAt <= 0 ||
    context.marketQuote.provenance.receivedAt <= 0
  ) {
    throw new DomainValidationError("invalid_market_quote_timestamp", "Market quote timestamps must be positive UTC epoch milliseconds.");
  }
  if (
    context.portfolioRisk.intentId !== intent.id ||
    context.portfolioRisk.accountId !== intent.accountId ||
    context.portfolioRisk.instrumentId !== intent.instrumentId ||
    context.portfolioRisk.environment !== intent.environment ||
    context.portfolioRisk.provenance.environment !== intent.environment ||
    context.portfolioRisk.provenance.source.sourceType !== "INTERNAL" ||
    context.portfolioRisk.provenance.eventAt !== context.portfolioRisk.asOf
  ) {
    throw new DomainValidationError("risk_portfolio_provenance_mismatch", "Portfolio risk snapshot must be internally derived and bound to the exact intent, account, instrument and environment.");
  }
  if (
    context.portfolioRisk.asOf > context.portfolioRisk.provenance.receivedAt ||
    context.accountSnapshot.asOf > context.accountSnapshot.provenance.receivedAt
  ) {
    throw new DomainValidationError("risk_context_timestamp_mismatch", "Snapshot receipt timestamps cannot precede their source valuation/event times.");
  }

  decimalValue(context.marketQuote.bid.value);
  decimalValue(context.marketQuote.ask.value);
  unitCode(context.marketQuote.bid.unit);
  unitCode(context.marketQuote.ask.unit);
  if (context.marketQuote.bid.currency !== undefined) currencyCode(context.marketQuote.bid.currency);
  if (context.marketQuote.ask.currency !== undefined) currencyCode(context.marketQuote.ask.currency);

  for (const value of [
    context.portfolioRisk.projectedPerTradeRisk,
    context.portfolioRisk.projectedAccountGrossExposure,
    context.portfolioRisk.projectedInstrumentGrossExposure,
    context.portfolioRisk.projectedDailyLoss,
    context.portfolioRisk.projectedDrawdown,
  ]) validateMoney(value, "projected_portfolio_risk");
  nonNegativeInteger(context.portfolioRisk.projectedOpenPositions, "projectedOpenPositions");
  nonNegativeInteger(context.portfolioRisk.projectedOpenInstrumentPositions, "projectedOpenInstrumentPositions");
}

function moneyCurrencyMatches(value: Money, currency: string): boolean {
  return value.currency === currency;
}

function moneyAbove(value: Money, limit: Money): boolean {
  return compareDecimal(decimalValue(value.amount), decimalValue(limit.amount)) > 0;
}

function isAutomatedOrigin(origin: IntentOriginKind): boolean {
  return origin !== "HUMAN";
}

function inputReferences(intent: OrderIntentEnvelope, context?: PreTradeRiskContext, policy?: RiskPolicy): string[] {
  const references = ["intent:" + intent.id];
  if (policy) references.push("risk-policy:" + policy.version);
  if (context) {
    references.push(
      "account:" + context.account.id,
      "account-snapshot:" + context.accountSnapshot.asOf,
      "instrument-specification:" + context.instrumentSpecification.id,
      "market-quote:" + context.marketQuote.id,
      "portfolio-risk-snapshot:" + context.portfolioRisk.id,
      "valuation-model:" + context.portfolioRisk.valuationModelVersion,
    );
  }
  return references;
}

export class RiskEngine {
  constructor(
    private readonly policies: RiskPolicyProvider,
    private readonly contexts: RiskContextProvider,
    private readonly controls: RiskTradingControls,
    private readonly clock: RiskClock,
    private readonly assessmentIds: RiskAssessmentIdGenerator,
  ) {}

  async evaluate(intentInput: OrderIntentEnvelope): Promise<RiskAssessment> {
    const intent = createOrderIntentEnvelope(intentInput);
    const evaluatedAt = utcTimestamp(this.clock.now());

    let policy: RiskPolicy | undefined;
    try {
      policy = await this.policies.getPolicy(intent.accountId, intent.environment);
    } catch {
      return this.createAssessment(intent, evaluatedAt, "HELD", ["RISK_POLICY_UNAVAILABLE"], ["intent:" + intent.id], "unavailable");
    }
    if (policy === undefined) {
      return this.createAssessment(intent, evaluatedAt, "HELD", ["RISK_POLICY_UNAVAILABLE"], ["intent:" + intent.id], "unavailable");
    }

    try {
      validatePolicy(policy);
    } catch {
      return this.createAssessment(
        intent,
        evaluatedAt,
        "HELD",
        ["RISK_POLICY_INVALID"],
        inputReferences(intent, undefined, policy),
        policy.version || "invalid",
      );
    }

    if (policy.environment !== intent.environment) {
      return this.createAssessment(intent, evaluatedAt, "HELD", ["RISK_POLICY_ENVIRONMENT_MISMATCH"], inputReferences(intent, undefined, policy), policy.version);
    }
    if (!policy.allowedIntentOrigins.includes(intent.origin.kind)) {
      return this.createAssessment(intent, evaluatedAt, "REJECTED", ["INTENT_ORIGIN_NOT_PERMITTED"], inputReferences(intent, undefined, policy), policy.version);
    }
    if (!policy.riskIncreasingOperationCodes.includes(intent.payload.operationCode)) {
      return this.createAssessment(intent, evaluatedAt, "REJECTED", ["UNSUPPORTED_RISK_OPERATION"], inputReferences(intent, undefined, policy), policy.version);
    }
    if (
      intent.origin.kind !== "HUMAN" &&
      (intent.origin.permissionProfileReference === undefined ||
        !policy.allowedPermissionProfileReferences.includes(intent.origin.permissionProfileReference))
    ) {
      return this.createAssessment(intent, evaluatedAt, "REJECTED", ["PERMISSION_PROFILE_NOT_AUTHORIZED"], inputReferences(intent, undefined, policy), policy.version);
    }

    let context: PreTradeRiskContext | undefined;
    try {
      context = await this.contexts.loadContext(intent);
    } catch {
      return this.createAssessment(intent, evaluatedAt, "HELD", ["RISK_CONTEXT_UNAVAILABLE"], inputReferences(intent, undefined, policy), policy.version);
    }
    if (context === undefined) {
      return this.createAssessment(intent, evaluatedAt, "HELD", ["RISK_CONTEXT_UNAVAILABLE"], inputReferences(intent, undefined, policy), policy.version);
    }

    try {
      validateContext(context, intent);
    } catch {
      return this.createAssessment(intent, evaluatedAt, "HELD", ["RISK_CONTEXT_INVALID"], inputReferences(intent, undefined, policy), policy.version);
    }

    const rejected: string[] = [];
    const held: string[] = [];
    const advisory: string[] = [];
    const references = inputReferences(intent, context, policy);
    const freshness = policy.freshness;
    const accountCurrency = context.account.accountCurrency;

    if (accountCurrency === undefined || accountCurrency !== policy.accountCurrency) {
      held.push("ACCOUNT_CURRENCY_UNAVAILABLE_OR_MISMATCHED");
    }

    const snapshotFields: readonly AccountBalanceField[] = [
      "balance", "equity", "availableFunds", "usedMargin", "availableMargin", "realizedPnl", "unrealizedPnl",
    ];
    for (const field of snapshotFields) {
      const value = context.accountSnapshot[field];
      if (value === undefined) continue;
      if (value.currency !== policy.accountCurrency) {
        held.push("ACCOUNT_FIELD_CURRENCY_MISMATCH:" + field);
      }
    }

    const requiredAccountFields = new Set<AccountBalanceField>(policy.requiredAccountFields);
    if (policy.minimumAvailableFunds !== undefined) requiredAccountFields.add("availableFunds");
    if (policy.minimumAvailableMargin !== undefined) requiredAccountFields.add("availableMargin");
    if (policy.maximumUsedMargin !== undefined) requiredAccountFields.add("usedMargin");
    for (const field of requiredAccountFields) {
      if (context.accountSnapshot[field] === undefined) {
        held.push("ACCOUNT_FIELD_UNAVAILABLE:" + field);
      }
    }

    if (evaluatedAt < context.accountSnapshot.asOf) {
      held.push("ACCOUNT_SNAPSHOT_FUTURE_DATED");
    } else if (evaluatedAt - context.accountSnapshot.asOf > freshness.accountSnapshotMaxAgeMs) {
      held.push("ACCOUNT_SNAPSHOT_STALE");
    }
    if (evaluatedAt < context.portfolioRisk.asOf) {
      held.push("PORTFOLIO_RISK_SNAPSHOT_FUTURE_DATED");
    } else if (evaluatedAt - context.portfolioRisk.asOf > freshness.portfolioSnapshotMaxAgeMs) {
      held.push("PORTFOLIO_RISK_SNAPSHOT_STALE");
    }

    const quoteAgeMs = evaluatedAt - context.marketQuote.provenance.eventAt;
    if (quoteAgeMs < 0) {
      const skew = -quoteAgeMs;
      held.push(skew > freshness.maximumFutureClockSkewMs
        ? "MARKET_DATA_FUTURE_DATED"
        : "MARKET_DATA_CLOCK_SKEW");
    } else if (quoteAgeMs > freshness.staleQuoteAfterMs) {
      rejected.push("MARKET_DATA_STALE");
    } else if (isAutomatedOrigin(intent.origin.kind) && quoteAgeMs > freshness.automatedEntryBlockAfterMs) {
      rejected.push("AUTOMATED_ENTRY_BLOCKED_BY_QUOTE_AGE");
    } else if (quoteAgeMs > freshness.normalQuoteAgeMs) {
      advisory.push("MARKET_DATA_ABOVE_NORMAL_AGE");
    }

    const bid = decimalValue(context.marketQuote.bid.value);
    const ask = decimalValue(context.marketQuote.ask.value);
    if (
      compareDecimal(bid, decimalValue("0")) <= 0 ||
      compareDecimal(ask, decimalValue("0")) <= 0 ||
      compareDecimal(ask, bid) < 0
    ) {
      rejected.push("MARKET_QUOTE_INVALID_OR_CROSSED");
    } else {
      const quoteUnit = context.marketQuote.bid.unit;
      const quoteCurrency = context.marketQuote.bid.currency;
      if (
        context.marketQuote.ask.unit !== quoteUnit ||
        context.marketQuote.ask.currency !== quoteCurrency ||
        policy.maximumSpread.unit !== quoteUnit ||
        policy.maximumSpread.currency !== quoteCurrency
      ) {
        held.push("MARKET_QUOTE_OR_SPREAD_UNIT_MISMATCH");
      } else {
        const spread = subtractDecimal(ask, bid);
        if (compareDecimal(decimalValue(spread), decimalValue(policy.maximumSpread.value)) > 0) {
          rejected.push("MAXIMUM_SPREAD_EXCEEDED");
        }
      }
    }

    const specification = context.instrumentSpecification;
    const requestedQuantity = intent.payload.quantity;
    if (specification.minimumDealSize === undefined) {
      held.push("BROKER_MINIMUM_DEAL_SIZE_UNAVAILABLE");
    }
    if (requestedQuantity === undefined) {
      rejected.push("ORDER_QUANTITY_REQUIRED");
    } else {
      const quantityUnit = requestedQuantity.unit;
      if (
        quantityUnit !== policy.maximumOrderQuantity.unit ||
        (specification.minimumDealSize !== undefined && quantityUnit !== specification.minimumDealSize.unit) ||
        (specification.maximumDealSize !== undefined && quantityUnit !== specification.maximumDealSize.unit) ||
        (specification.quantityIncrement !== undefined && quantityUnit !== specification.quantityIncrement.unit)
      ) {
        rejected.push("ORDER_QUANTITY_UNIT_MISMATCH");
      } else {
        const quantityValue = decimalValue(requestedQuantity.value);
        if (decimalPlaces(quantityValue) > specification.quantityPrecision) {
          rejected.push("ORDER_QUANTITY_PRECISION_EXCEEDED");
        }
        if (compareDecimal(quantityValue, decimalValue(policy.maximumOrderQuantity.value)) > 0) {
          rejected.push("MAXIMUM_ORDER_QUANTITY_EXCEEDED");
        }
        if (
          specification.minimumDealSize !== undefined &&
          compareDecimal(quantityValue, decimalValue(specification.minimumDealSize.value)) < 0
        ) {
          rejected.push("BELOW_BROKER_MINIMUM_DEAL_SIZE");
        }
        if (
          specification.maximumDealSize !== undefined &&
          compareDecimal(quantityValue, decimalValue(specification.maximumDealSize.value)) > 0
        ) {
          rejected.push("ABOVE_BROKER_MAXIMUM_DEAL_SIZE");
        }
        if (specification.quantityIncrement === undefined) {
          held.push("BROKER_QUANTITY_INCREMENT_UNAVAILABLE");
        } else if (!isMultipleOfIncrement(quantityValue, decimalValue(specification.quantityIncrement.value))) {
          rejected.push("ORDER_QUANTITY_NOT_ALIGNED_TO_INCREMENT");
        }
      }
    }

    if (
      decimalPlaces(context.marketQuote.bid.value) > specification.pricePrecision ||
      decimalPlaces(context.marketQuote.ask.value) > specification.pricePrecision
    ) {
      rejected.push("MARKET_PRICE_PRECISION_EXCEEDED");
    }
    if (policy.requireBrokerPriceIncrement && specification.priceIncrement === undefined) {
      held.push("BROKER_PRICE_INCREMENT_UNAVAILABLE");
    } else if (specification.priceIncrement !== undefined) {
      if (
        specification.priceIncrement.unit !== context.marketQuote.bid.unit ||
        specification.priceIncrement.currency !== context.marketQuote.bid.currency
      ) {
        held.push("BROKER_PRICE_INCREMENT_UNIT_MISMATCH");
      } else if (
        !isMultipleOfIncrement(decimalValue(context.marketQuote.bid.value), decimalValue(specification.priceIncrement.value)) ||
        !isMultipleOfIncrement(decimalValue(context.marketQuote.ask.value), decimalValue(specification.priceIncrement.value))
      ) {
        rejected.push("MARKET_PRICE_INCREMENT_INVALID");
      }
    }

    if (policy.requireStopLoss) {
      const stopLossCode = policy.stopLossParameterCode as string;
      const stopLoss = intent.payload.priceParameters?.find((parameter) => parameter.code === stopLossCode);
      if (stopLoss === undefined) {
        rejected.push("REQUIRED_STOP_LOSS_MISSING");
      } else {
        const stopPrice = decimalValue(stopLoss.price.value);
        if (
          stopLoss.price.unit !== context.marketQuote.bid.unit ||
          stopLoss.price.currency !== context.marketQuote.bid.currency
        ) {
          rejected.push("STOP_LOSS_PRICE_UNIT_MISMATCH");
        } else if (decimalPlaces(stopPrice) > specification.pricePrecision) {
          rejected.push("STOP_LOSS_PRECISION_EXCEEDED");
        } else if (
          specification.priceIncrement !== undefined &&
          !isMultipleOfIncrement(stopPrice, decimalValue(specification.priceIncrement.value))
        ) {
          rejected.push("STOP_LOSS_PRICE_INCREMENT_INVALID");
        } else if (
          (intent.payload.direction === "BUY" && compareDecimal(stopPrice, bid) >= 0) ||
          (intent.payload.direction === "SELL" && compareDecimal(stopPrice, ask) <= 0)
        ) {
          rejected.push("STOP_LOSS_NOT_PROTECTIVE");
        } else if (intent.payload.direction !== "BUY" && intent.payload.direction !== "SELL") {
          rejected.push("ORDER_DIRECTION_REQUIRED");
        }
      }
    }

    const portfolio = context.portfolioRisk;
    if (
      portfolio.projectedOpenPositions > policy.maximumOpenPositions ||
      portfolio.projectedOpenInstrumentPositions > policy.maximumOpenPositionsPerInstrument
    ) {
      rejected.push("MAXIMUM_OPEN_POSITION_COUNT_EXCEEDED");
    }

    const projectedMoney: readonly Money[] = [
      portfolio.projectedPerTradeRisk,
      portfolio.projectedAccountGrossExposure,
      portfolio.projectedInstrumentGrossExposure,
      portfolio.projectedDailyLoss,
      portfolio.projectedDrawdown,
    ];
    if (projectedMoney.some((value) => !moneyCurrencyMatches(value, policy.accountCurrency))) {
      held.push("PORTFOLIO_RISK_CURRENCY_MISMATCH");
    }
    if (
      policy.minimumAvailableFunds !== undefined &&
      context.accountSnapshot.availableFunds !== undefined &&
      context.accountSnapshot.availableFunds.currency === policy.accountCurrency &&
      compareDecimal(decimalValue(context.accountSnapshot.availableFunds.amount), decimalValue(policy.minimumAvailableFunds.amount)) < 0
    ) {
      rejected.push("MINIMUM_AVAILABLE_FUNDS_NOT_MET");
    }
    if (
      policy.minimumAvailableMargin !== undefined &&
      context.accountSnapshot.availableMargin !== undefined &&
      context.accountSnapshot.availableMargin.currency === policy.accountCurrency &&
      compareDecimal(decimalValue(context.accountSnapshot.availableMargin.amount), decimalValue(policy.minimumAvailableMargin.amount)) < 0
    ) {
      rejected.push("MINIMUM_AVAILABLE_MARGIN_NOT_MET");
    }
    if (
      policy.maximumUsedMargin !== undefined &&
      context.accountSnapshot.usedMargin !== undefined &&
      context.accountSnapshot.usedMargin.currency === policy.accountCurrency &&
      compareDecimal(decimalValue(context.accountSnapshot.usedMargin.amount), decimalValue(policy.maximumUsedMargin.amount)) > 0
    ) {
      rejected.push("MAXIMUM_USED_MARGIN_EXCEEDED");
    }

    if (moneyAbove(portfolio.projectedPerTradeRisk, policy.maximumPerTradeRisk)) {
      rejected.push("MAXIMUM_PER_TRADE_RISK_EXCEEDED");
    }
    if (moneyAbove(portfolio.projectedAccountGrossExposure, policy.maximumAccountGrossExposure)) {
      rejected.push("MAXIMUM_ACCOUNT_GROSS_EXPOSURE_EXCEEDED");
    }
    if (moneyAbove(portfolio.projectedInstrumentGrossExposure, policy.maximumInstrumentGrossExposure)) {
      rejected.push("MAXIMUM_INSTRUMENT_GROSS_EXPOSURE_EXCEEDED");
    }
    if (moneyAbove(portfolio.projectedDailyLoss, policy.maximumDailyLoss)) {
      rejected.push("MAXIMUM_DAILY_LOSS_EXCEEDED");
    }
    if (moneyAbove(portfolio.projectedDrawdown, policy.maximumDrawdown)) {
      rejected.push("MAXIMUM_DRAWDOWN_EXCEEDED");
    }

    try {
      if (this.controls.isEmergencyHalted(intent.environment)) {
        rejected.push("EMERGENCY_TRADING_HALT_ACTIVE");
      }
      if (!this.controls.isTradingEnabled(intent.environment)) {
        held.push("TRADING_DISABLED");
      }
    } catch {
      held.push("TRADING_CONTROLS_UNAVAILABLE");
    }

    const reasonCodes = [...new Set([...rejected, ...held, ...advisory])];
    const outcome: RiskDecisionOutcome = rejected.length > 0 ? "REJECTED" : held.length > 0 ? "HELD" : "AUTHORIZED";
    return this.createAssessment(intent, evaluatedAt, outcome, reasonCodes, references, policy.version);
  }

  private createAssessment(
    intent: OrderIntentEnvelope,
    evaluatedAt: UtcTimestamp,
    outcome: RiskDecisionOutcome,
    reasonCodes: readonly string[],
    references: readonly string[],
    policyVersion: string,
  ): RiskAssessment {
    const provenance = createDataProvenance({
      source: { sourceId: sourceId("atheer-risk-engine"), sourceType: "INTERNAL" },
      environment: tradingEnvironment(intent.environment),
      eventAt: evaluatedAt,
      receivedAt: evaluatedAt,
      schemaVersion: "risk-assessment-v1",
      normalizationVersion: "1.0.0",
      validationCode: "RISK_EVALUATED_" + outcome,
    });
    return createRiskAssessment({
      id: this.assessmentIds.next(),
      intentId: intent.id,
      policyVersion,
      outcome,
      evaluatedAt,
      reasonCodes: [...reasonCodes],
      inputReferences: [...new Set(references)],
      provenance,
    });
  }
}

/** Production-safe gate until a separately qualified DEMO authorization is configured. */
export class DisabledRiskTradingControls implements RiskTradingControls {
  isTradingEnabled(_environment: TradingEnvironment): boolean { return false; }
  isEmergencyHalted(_environment: TradingEnvironment): boolean { return false; }
}
