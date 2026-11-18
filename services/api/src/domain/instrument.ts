import {
  type AssetClassCode,
  type BrokerId,
  type BrokerInstrumentId,
  type DataProvenance,
  type InstrumentId,
  type InstrumentSpecificationId,
  type TradingEnvironment,
  type UnitCode,
  type CurrencyCode,
  decimalValue,
  type DecimalValue,
  type UtcTimestamp,
  DomainValidationError,
  assertArray,
  assertRecord,
  assetClassCode,
  currencyCode,
  createDataProvenance,
  assertPositiveDecimal,
  compareDecimal,
  tradingEnvironment,
  unitCode,
  utcTimestamp,
  nonEmptyString,
} from "./shared.ts";

export interface InstrumentIdentity {
  readonly id: InstrumentId;
  readonly canonicalCode: string;
  readonly displayName: string;
  readonly assetClassCode: AssetClassCode;
}

export interface BrokerInstrumentReference {
  readonly brokerId: BrokerId;
  readonly environment: TradingEnvironment;
  readonly brokerInstrumentId: BrokerInstrumentId;
}

export interface Quantity {
  readonly value: DecimalValue;
  readonly unit: UnitCode;
}

export interface Price {
  readonly value: DecimalValue;
  readonly unit: UnitCode;
  readonly currency?: CurrencyCode;
}

export function quantity(value: string, unit: UnitCode): Quantity {
  const normalized = decimalValue(value);
  const validatedUnit = unitCode(unit);
  return Object.freeze({ value: normalized, unit: validatedUnit });
}

export function price(value: string, unit: UnitCode, currency?: CurrencyCode): Price {
  const normalized = decimalValue(value);
  const validatedUnit = unitCode(unit);
  if (currency !== undefined) currencyCode(currency);
  return Object.freeze(currency === undefined
    ? { value: normalized, unit: validatedUnit }
    : { value: normalized, unit: validatedUnit, currency });
}

export interface BrokerInstrumentConstraint {
  readonly code: string;
  readonly rawValue: string;
  readonly unit?: UnitCode;
  readonly sourceField?: string;
}

export interface InstrumentSpecification {
  readonly id: InstrumentSpecificationId;
  readonly instrumentId: InstrumentId;
  readonly brokerReference: BrokerInstrumentReference;
  readonly version: number;
  readonly retrievedAt: UtcTimestamp;
  readonly provenance: DataProvenance;
  readonly pricePrecision: number;
  readonly quantityPrecision: number;
  readonly priceIncrement?: Price;
  readonly minimumDealSize?: Quantity;
  readonly maximumDealSize?: Quantity;
  readonly quantityIncrement?: Quantity;
  readonly lotSize?: Quantity;
  readonly contractSize?: Quantity;
  readonly tradingSessionReference?: string;
  readonly marketStatusCode?: string;
  readonly precisionPolicyReference?: string;
  readonly constraints: readonly BrokerInstrumentConstraint[];
  readonly supersedesSpecificationId?: InstrumentSpecificationId;
}

export function validateInstrumentIdentity(instrument: InstrumentIdentity): void {
  assertRecord(instrument, "instrument_identity");
  nonEmptyString(instrument.canonicalCode, "canonical_instrument_code");
  nonEmptyString(instrument.displayName, "instrument_display_name");
  assetClassCode(instrument.assetClassCode);
  nonEmptyString(instrument.id, "instrument_id");
}

function decimalScale(value: DecimalValue): number {
  const normalized = decimalValue(value);
  const point = normalized.indexOf(".");
  return point < 0 ? 0 : normalized.length - point - 1;
}

function validateQuantity(quantity: Quantity | undefined, field: string): void {
  if (quantity === undefined) return;
  assertRecord(quantity, field);
  assertPositiveDecimal(quantity.value, field);
  unitCode(quantity.unit);
}

export function validateInstrumentSpecification(specification: InstrumentSpecification): void {
  assertRecord(specification, "instrument_specification");
  assertRecord(specification.brokerReference, "instrument_broker_reference");
  assertArray(specification.constraints, "instrument_constraints");
  nonEmptyString(specification.id, "instrument_specification_id");
  nonEmptyString(specification.instrumentId, "instrument_id");
  tradingEnvironment(specification.brokerReference.environment);
  utcTimestamp(specification.retrievedAt);
  createDataProvenance(specification.provenance);
  nonEmptyString(specification.brokerReference.brokerId, "broker_id");
  nonEmptyString(specification.brokerReference.brokerInstrumentId, "broker_instrument_id");
  if (!Number.isSafeInteger(specification.version) || specification.version < 1) {
    throw new DomainValidationError("invalid_specification_version", "Instrument specification version must be a positive integer.");
  }
  if (!Number.isSafeInteger(specification.pricePrecision) || specification.pricePrecision < 0) {
    throw new DomainValidationError("invalid_price_precision", "Price precision must be a non-negative integer.");
  }
  if (!Number.isSafeInteger(specification.quantityPrecision) || specification.quantityPrecision < 0) {
    throw new DomainValidationError("invalid_quantity_precision", "Quantity precision must be a non-negative integer.");
  }
  if (specification.provenance.source.sourceType !== "BROKER") {
    throw new DomainValidationError("invalid_specification_source", "Instrument specifications must retain broker provenance.");
  }
  if (String(specification.provenance.source.sourceId) !== String(specification.brokerReference.brokerId)) {
    throw new DomainValidationError("broker_provenance_mismatch", "Specification source must match its broker identity.");
  }
  if (specification.provenance.environment !== specification.brokerReference.environment) {
    throw new DomainValidationError("environment_provenance_mismatch", "Specification and provenance environments must match.");
  }
  if (specification.retrievedAt !== specification.provenance.receivedAt) {
    throw new DomainValidationError("retrieval_timestamp_mismatch", "Retrieved-at time must match the local provenance receipt time.");
  }

  validateQuantity(specification.minimumDealSize, "minimum_deal_size");
  validateQuantity(specification.maximumDealSize, "maximum_deal_size");
  validateQuantity(specification.quantityIncrement, "quantity_increment");
  validateQuantity(specification.lotSize, "lot_size");
  validateQuantity(specification.contractSize, "contract_size");

  if (specification.priceIncrement !== undefined) {
    assertRecord(specification.priceIncrement, "price_increment");
    assertPositiveDecimal(specification.priceIncrement.value, "price_increment");
    unitCode(specification.priceIncrement.unit);
    if (specification.priceIncrement.currency !== undefined) {
      currencyCode(specification.priceIncrement.currency);
    }
    if (decimalScale(specification.priceIncrement.value) > specification.pricePrecision) {
      throw new DomainValidationError(
        "price_increment_precision_mismatch",
        "Price increment precision cannot exceed the broker-declared price precision.",
      );
    }
  }

  const quantityConstraints = [
    specification.minimumDealSize,
    specification.maximumDealSize,
    specification.quantityIncrement,
  ].filter((value): value is Quantity => value !== undefined);

  if (quantityConstraints.length > 1) {
    const expectedUnit = quantityConstraints[0].unit;
    if (quantityConstraints.some((value) => value.unit !== expectedUnit)) {
      throw new DomainValidationError("quantity_unit_mismatch", "Minimum, maximum, and increment quantities must use the same validated unit.");
    }
  }

  for (const value of quantityConstraints) {
    if (decimalScale(value.value) > specification.quantityPrecision) {
      throw new DomainValidationError(
        "quantity_precision_mismatch",
        "Minimum, maximum, and increment quantities cannot exceed the broker-declared quantity precision.",
      );
    }
  }

  if (
    specification.minimumDealSize !== undefined &&
    specification.maximumDealSize !== undefined &&
    compareDecimal(specification.minimumDealSize.value, specification.maximumDealSize.value) > 0
  ) {
    throw new DomainValidationError("invalid_deal_size_range", "Minimum deal size cannot exceed maximum deal size.");
  }

  if (specification.tradingSessionReference !== undefined) {
    nonEmptyString(specification.tradingSessionReference, "trading_session_reference");
  }
  if (specification.marketStatusCode !== undefined) {
    nonEmptyString(specification.marketStatusCode, "market_status_code");
  }
  if (specification.precisionPolicyReference !== undefined) {
    nonEmptyString(specification.precisionPolicyReference, "precision_policy_reference");
  }

  for (const constraint of specification.constraints) {
    assertRecord(constraint, "broker_instrument_constraint");
    nonEmptyString(constraint.code, "broker_constraint_code");
    nonEmptyString(constraint.rawValue, "broker_constraint_raw_value");
    if (constraint.unit !== undefined) unitCode(constraint.unit);
    if (constraint.sourceField !== undefined) {
      nonEmptyString(constraint.sourceField, "broker_constraint_source_field");
    }
  }
}
