import {
  type BrokerAccountId,
  type BrokerAccountReference,
  type BrokerId,
  type CurrencyCode,
  type DataProvenance,
  type TradingEnvironment,
  type UtcTimestamp,
  DomainValidationError,
  currencyCode,
  decimalValue,
  createDataProvenance,
  tradingEnvironment,
  utcTimestamp,
  nonEmptyString,
} from "./shared.ts";

export interface Money {
  readonly amount: import("./shared.ts").DecimalValue;
  readonly currency: CurrencyCode;
}

export interface BrokerAccountIdentity {
  readonly id: BrokerAccountId;
  readonly brokerId: BrokerId;
  readonly environment: TradingEnvironment;
  readonly brokerAccountReference: BrokerAccountReference;
  readonly accountCurrency?: CurrencyCode;
}

export interface AccountBalanceSnapshot {
  readonly accountId: BrokerAccountId;
  readonly environment: TradingEnvironment;
  readonly asOf: UtcTimestamp;
  readonly provenance: DataProvenance;
  readonly balance?: Money;
  readonly equity?: Money;
  readonly availableFunds?: Money;
  readonly usedMargin?: Money;
  readonly availableMargin?: Money;
  readonly realizedPnl?: Money;
  readonly unrealizedPnl?: Money;
}

export function validateBrokerAccountIdentity(account: BrokerAccountIdentity): void {
  nonEmptyString(account.id, "broker_account_id");
  nonEmptyString(account.brokerId, "broker_id");
  nonEmptyString(account.brokerAccountReference, "broker_account_reference");
  tradingEnvironment(account.environment);
  if (account.accountCurrency !== undefined) currencyCode(account.accountCurrency);
}

export function validateAccountBalanceSnapshot(
  account: BrokerAccountIdentity,
  snapshot: AccountBalanceSnapshot,
): void {
  validateBrokerAccountIdentity(account);
  createDataProvenance(snapshot.provenance);
  tradingEnvironment(snapshot.environment);
  utcTimestamp(snapshot.asOf);
  if (snapshot.accountId !== account.id) {
    throw new DomainValidationError("account_snapshot_identity_mismatch", "Balance snapshot must belong to the supplied broker account.");
  }
  if (snapshot.environment !== account.environment || snapshot.provenance.environment !== account.environment) {
    throw new DomainValidationError("account_environment_mismatch", "Account and balance snapshot environments must match.");
  }
  if (
    snapshot.provenance.source.sourceType !== "BROKER" ||
    String(snapshot.provenance.source.sourceId) !== String(account.brokerId)
  ) {
    throw new DomainValidationError("account_provenance_mismatch", "Broker account snapshots require matching broker provenance.");
  }
  if (snapshot.asOf !== snapshot.provenance.eventAt) {
    throw new DomainValidationError("account_timestamp_mismatch", "Account snapshot time must match the broker event time.");
  }

  const monetaryValues = [
    snapshot.balance,
    snapshot.equity,
    snapshot.availableFunds,
    snapshot.usedMargin,
    snapshot.availableMargin,
    snapshot.realizedPnl,
    snapshot.unrealizedPnl,
  ];
  for (const value of monetaryValues) {
    if (value !== undefined) {
      decimalValue(value.amount);
      currencyCode(value.currency);
    }
  }
}
