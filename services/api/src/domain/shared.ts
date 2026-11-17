export type Identifier<Name extends string> = string & { readonly __brand: Name };

export class DomainValidationError extends Error {
  readonly code: string;

  constructor(code: string, message: string) {
    super(message);
    this.name = "DomainValidationError";
    this.code = code;
  }
}

export function nonEmptyString(value: string, field: string): string {
  if (typeof value !== "string" || value.length === 0 || value.trim() !== value) {
    throw new DomainValidationError("invalid_" + field, field + " must be a non-empty, trimmed string.");
  }
  return value;
}

export function identifier<Name extends string>(value: string, field: string): Identifier<Name> {
  return nonEmptyString(value, field) as Identifier<Name>;
}

export type BrokerId = Identifier<"BrokerId">;
export type BrokerInstrumentId = Identifier<"BrokerInstrumentId">;
export type BrokerAccountReference = Identifier<"BrokerAccountReference">;
export type InstrumentId = Identifier<"InstrumentId">;
export type InstrumentSpecificationId = Identifier<"InstrumentSpecificationId">;
export type BrokerAccountId = Identifier<"BrokerAccountId">;
export type OrderIntentId = Identifier<"OrderIntentId">;
export type CommandId = Identifier<"CommandId">;
export type CorrelationId = Identifier<"CorrelationId">;
export type IdempotencyKey = Identifier<"IdempotencyKey">;
export type OrderId = Identifier<"OrderId">;
export type PositionId = Identifier<"PositionId">;
export type ExecutionFillId = Identifier<"ExecutionFillId">;
export type ExecutionEventId = Identifier<"ExecutionEventId">;
export type RiskAssessmentId = Identifier<"RiskAssessmentId">;
export type ReconciliationEventId = Identifier<"ReconciliationEventId">;
export type AuditEventId = Identifier<"AuditEventId">;
export type SourceId = Identifier<"SourceId">;
export type PrecisionPolicyReference = Identifier<"PrecisionPolicyReference">;

export const brokerId = (value: string): BrokerId => identifier<"BrokerId">(value, "broker_id");
export const brokerInstrumentId = (value: string): BrokerInstrumentId =>
  identifier<"BrokerInstrumentId">(value, "broker_instrument_id");
export const brokerAccountReference = (value: string): BrokerAccountReference =>
  identifier<"BrokerAccountReference">(value, "broker_account_reference");
export const instrumentId = (value: string): InstrumentId => identifier<"InstrumentId">(value, "instrument_id");
export const instrumentSpecificationId = (value: string): InstrumentSpecificationId =>
  identifier<"InstrumentSpecificationId">(value, "instrument_specification_id");
export const brokerAccountId = (value: string): BrokerAccountId =>
  identifier<"BrokerAccountId">(value, "broker_account_id");
export const orderIntentId = (value: string): OrderIntentId =>
  identifier<"OrderIntentId">(value, "order_intent_id");
export const commandId = (value: string): CommandId => identifier<"CommandId">(value, "command_id");
export const correlationId = (value: string): CorrelationId =>
  identifier<"CorrelationId">(value, "correlation_id");
export const idempotencyKey = (value: string): IdempotencyKey =>
  identifier<"IdempotencyKey">(value, "idempotency_key");
export const orderId = (value: string): OrderId => identifier<"OrderId">(value, "order_id");
export const positionId = (value: string): PositionId => identifier<"PositionId">(value, "position_id");
export const executionFillId = (value: string): ExecutionFillId =>
  identifier<"ExecutionFillId">(value, "execution_fill_id");
export const executionEventId = (value: string): ExecutionEventId =>
  identifier<"ExecutionEventId">(value, "execution_event_id");
export const riskAssessmentId = (value: string): RiskAssessmentId =>
  identifier<"RiskAssessmentId">(value, "risk_assessment_id");
export const reconciliationEventId = (value: string): ReconciliationEventId =>
  identifier<"ReconciliationEventId">(value, "reconciliation_event_id");
export const auditEventId = (value: string): AuditEventId => identifier<"AuditEventId">(value, "audit_event_id");
export const sourceId = (value: string): SourceId => identifier<"SourceId">(value, "source_id");
export const precisionPolicyReference = (value: string): PrecisionPolicyReference =>
  identifier<"PrecisionPolicyReference">(value, "precision_policy_reference");

export type DecimalValue = string & { readonly __brand: "DecimalValue" };

const DECIMAL_PATTERN = /^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?$/;
const MAX_DECIMAL_LENGTH = 128;

export function decimalValue(value: string): DecimalValue {
  if (typeof value !== "string" || value.length === 0 || value.length > MAX_DECIMAL_LENGTH) {
    throw new DomainValidationError("invalid_decimal", "Decimal values must be non-empty strings of at most 128 characters.");
  }
  if (!DECIMAL_PATTERN.test(value)) {
    throw new DomainValidationError("invalid_decimal", "Decimal values must use plain base-10 notation without exponents or leading zeroes.");
  }

  const negative = value.startsWith("-");
  const unsigned = negative ? value.slice(1) : value;
  const [whole, fraction = ""] = unsigned.split(".");
  const normalizedFraction = fraction.replace(/0+$/, "");
  const isZero = /^0+$/.test(whole) && normalizedFraction.length === 0;
  const sign = negative && !isZero ? "-" : "";
  const normalized = sign + whole + (normalizedFraction.length > 0 ? "." + normalizedFraction : "");
  return normalized as DecimalValue;
}

interface DecimalParts {
  readonly coefficient: bigint;
  readonly scale: number;
}

function decimalParts(value: DecimalValue): DecimalParts {
  const negative = value.startsWith("-");
  const unsigned = negative ? value.slice(1) : value;
  const [whole, fraction = ""] = unsigned.split(".");
  const digits = whole + fraction;
  const coefficient = BigInt(digits) * (negative ? -1n : 1n);
  return { coefficient, scale: fraction.length };
}

function alignDecimalParts(left: DecimalParts, right: DecimalParts): readonly [bigint, bigint] {
  const scale = Math.max(left.scale, right.scale);
  return [
    left.coefficient * 10n ** BigInt(scale - left.scale),
    right.coefficient * 10n ** BigInt(scale - right.scale),
  ];
}

export function compareDecimal(left: DecimalValue, right: DecimalValue): -1 | 0 | 1 {
  const [a, b] = alignDecimalParts(decimalParts(left), decimalParts(right));
  return a < b ? -1 : a > b ? 1 : 0;
}

export function isPositiveDecimal(value: DecimalValue): boolean {
  return compareDecimal(value, decimalValue("0")) > 0;
}

export function isMultipleOfIncrement(value: DecimalValue, increment: DecimalValue): boolean {
  if (!isPositiveDecimal(increment)) {
    throw new DomainValidationError("invalid_increment", "A decimal increment must be greater than zero.");
  }
  const [amount, step] = alignDecimalParts(decimalParts(value), decimalParts(increment));
  return amount % step === 0n;
}

export type CurrencyCode = string & { readonly __brand: "CurrencyCode" };
export type UnitCode = string & { readonly __brand: "UnitCode" };
export type AssetClassCode = string & { readonly __brand: "AssetClassCode" };

export function currencyCode(value: string): CurrencyCode {
  if (!/^[A-Z]{3}$/.test(value)) {
    throw new DomainValidationError("invalid_currency_code", "Currency codes must use three uppercase letters.");
  }
  return value as CurrencyCode;
}

export function unitCode(value: string): UnitCode {
  if (!/^[A-Za-z][A-Za-z0-9._:/-]{0,31}$/.test(value)) {
    throw new DomainValidationError("invalid_unit_code", "Unit codes must be 1–32 characters and begin with a letter.");
  }
  return value as UnitCode;
}

export function assetClassCode(value: string): AssetClassCode {
  return nonEmptyString(value, "asset_class_code") as AssetClassCode;
}

export type TradingEnvironment = "DEMO" | "SIMULATION" | "BACKTEST" | "LIVE";

export function tradingEnvironment(value: string): TradingEnvironment {
  if (value !== "DEMO" && value !== "SIMULATION" && value !== "BACKTEST" && value !== "LIVE") {
    throw new DomainValidationError("invalid_trading_environment", "Trading environment is not supported.");
  }
  return value;
}

export type SourceType = "BROKER" | "MARKET_DATA_PROVIDER" | "INTERNAL" | "USER" | "STRATEGY" | "AI_AGENT";

export interface SourceIdentity {
  readonly sourceId: SourceId;
  readonly sourceType: SourceType;
}

export interface DataProvenance {
  readonly source: SourceIdentity;
  readonly environment: TradingEnvironment;
  readonly eventAt: UtcTimestamp;
  readonly receivedAt: UtcTimestamp;
  readonly schemaVersion: string;
  readonly normalizationVersion: string;
  readonly validationCode: string;
  readonly sourceRecordReference?: string;
}

export type UtcTimestamp = number & { readonly __brand: "UtcTimestamp" };

export function utcTimestamp(value: number): UtcTimestamp {
  if (!Number.isSafeInteger(value) || value <= 0) {
    throw new DomainValidationError("invalid_utc_timestamp", "UTC timestamps must be positive safe-integer epoch milliseconds.");
  }
  return value as UtcTimestamp;
}

export function utcTimestampFromIso(value: string): UtcTimestamp {
  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$/.test(value)) {
    throw new DomainValidationError("invalid_utc_timestamp", "Timestamp must be an ISO-8601 UTC value ending in Z.");
  }
  const parsed = Date.parse(value);
  if (!Number.isFinite(parsed)) {
    throw new DomainValidationError("invalid_utc_timestamp", "Timestamp is not a valid ISO-8601 instant.");
  }
  return utcTimestamp(parsed);
}

export function createDataProvenance(input: DataProvenance): DataProvenance {
  nonEmptyString(input.source.sourceId, "source_id");
  nonEmptyString(input.schemaVersion, "schema_version");
  nonEmptyString(input.normalizationVersion, "normalization_version");
  nonEmptyString(input.validationCode, "validation_code");
  tradingEnvironment(input.environment);
  utcTimestamp(input.eventAt);
  utcTimestamp(input.receivedAt);
  if (input.sourceRecordReference !== undefined) {
    nonEmptyString(input.sourceRecordReference, "source_record_reference");
  }
  return deepFreeze({ ...input, source: { ...input.source } }) as DataProvenance;
}

export function deepFreeze<T>(value: T, seen: WeakSet<object> = new WeakSet<object>()): Readonly<T> {
  if (value !== null && typeof value === "object") {
    const objectValue = value as object;
    if (!seen.has(objectValue)) {
      seen.add(objectValue);
      for (const nested of Object.values(value as Record<string, unknown>)) {
        deepFreeze(nested, seen);
      }
      Object.freeze(objectValue);
    }
  }
  return value as Readonly<T>;
}

export function assertPositiveDecimal(value: DecimalValue, field: string): void {
  if (!isPositiveDecimal(value)) {
    throw new DomainValidationError("invalid_" + field, field + " must be greater than zero.");
  }
}
