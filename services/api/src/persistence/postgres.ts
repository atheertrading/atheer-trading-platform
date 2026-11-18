import { createHash } from "node:crypto";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { readdir, readFile } from "node:fs/promises";
import { Pool } from "pg";
import {
  validateBrokerAccountIdentity,
  type BrokerAccountIdentity,
  type AccountBalanceSnapshot,
  validateAccountBalanceSnapshot,
} from "../domain/account.ts";
import {
  validateInstrumentIdentity,
  validateInstrumentSpecification,
  type InstrumentIdentity,
  type InstrumentSpecification,
} from "../domain/instrument.ts";
import {
  createAuditEvent,
  createOrderIntentEnvelope,
  createReconciliationEvent,
  createRiskAssessment,
  type AuditEvent,
  type OrderIntentEnvelope,
  type ReconciliationEvent,
  type RiskAssessment,
} from "../domain/trading.ts";
import {
  createOmsOrder,
  createOrderLifecycleTransition,
  type OmsOrder,
} from "../domain/order-lifecycle.ts";
import type { OrderId, TradingEnvironment, UtcTimestamp } from "../domain/shared.ts";

export interface SqlResult<Row extends Record<string, unknown> = Record<string, unknown>> {
  readonly rows: Row[];
  readonly rowCount: number | null;
}
export interface SqlClient {
  query<Row extends Record<string, unknown> = Record<string, unknown>>(sql: string, values?: readonly unknown[]): Promise<SqlResult<Row>>;
  release(error?: Error | boolean): void;
}
export interface SqlPool {
  connect(): Promise<SqlClient>;
  query<Row extends Record<string, unknown> = Record<string, unknown>>(sql: string, values?: readonly unknown[]): Promise<SqlResult<Row>>;
  end(): Promise<void>;
}
export interface SqlMigration { readonly version: string; readonly sql: string; }
export interface PersistIntentResult {
  readonly intentInserted: boolean;
  readonly riskAssessmentInserted: boolean;
  readonly replayed: boolean;
}
export interface PersistAuthorizedOrderResult {
  readonly orderInserted: boolean;
  readonly replayed: boolean;
  readonly order: OmsOrder;
}

export class PersistenceConflictError extends Error {
  readonly code = "persistence_conflict";
  constructor(message: string) { super(message); this.name = "PersistenceConflictError"; }
}

function canonicalize(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value !== null && typeof value === "object") {
    const record = value as Record<string, unknown>;
    return Object.fromEntries(Object.keys(record).sort().map((key) => [key, canonicalize(record[key])]));
  }
  return value;
}

function canonicalJson(value: unknown): string { return JSON.stringify(canonicalize(value)) ?? "null"; }
function sha256(value: string): string { return createHash("sha256").update(value, "utf8").digest("hex"); }
function isoTimestamp(epochMilliseconds: number): string { return new Date(epochMilliseconds).toISOString(); }

async function inTransaction<T>(pool: SqlPool, work: (client: SqlClient) => Promise<T>): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const result = await work(client);
    await client.query("COMMIT");
    return result;
  } catch (error) {
    await client.query("ROLLBACK").catch(() => undefined);
    throw error;
  } finally {
    client.release();
  }
}

export function createPostgresPool(connectionString: string): SqlPool {
  if (connectionString.trim().length === 0) throw new Error("DATABASE_URL must not be empty.");
  return new Pool({ connectionString, max: 10, idleTimeoutMillis: 30_000, connectionTimeoutMillis: 5_000 });
}

export async function loadSqlMigrations(directory = resolve(dirname(fileURLToPath(import.meta.url)), "../../migrations")): Promise<SqlMigration[]> {
  const names = (await readdir(directory)).filter((name) => /^\d{3,}_[a-z0-9_-]+\.sql$/.test(name)).sort();
  const migrations: SqlMigration[] = [];
  for (const name of names) {
    const version = name.slice(0, name.indexOf("_"));
    migrations.push({ version, sql: await readFile(resolve(directory, name), "utf8") });
  }
  return migrations;
}

export async function applySqlMigrations(pool: SqlPool, migrations: readonly SqlMigration[]): Promise<void> {
  await inTransaction(pool, async (client) => {
    await client.query("SELECT pg_advisory_xact_lock($1::bigint)", ["73194712026001"]);
    await client.query("SET LOCAL ROLE atheer_db_owner");
    await client.query(
      "CREATE TABLE IF NOT EXISTS atheer.atheer_schema_migrations (version text PRIMARY KEY, checksum char(64) NOT NULL, applied_at timestamptz NOT NULL DEFAULT now())",
    );
    const applied = await client.query<{ version: string; checksum: string }>(
      "SELECT version, checksum FROM atheer.atheer_schema_migrations ORDER BY version",
    );
    const appliedByVersion = new Map(applied.rows.map((row) => [row.version, row.checksum]));
    if (migrations.some((migration) => !/^\d{3,}$/.test(migration.version))) {
      throw new PersistenceConflictError("Migration versions must be numeric identifiers with at least three digits.");
    }
    const seenVersions = new Set<string>();
    const orderedMigrations = [...migrations].sort((left, right) =>
      BigInt(left.version) < BigInt(right.version) ? -1 : BigInt(left.version) > BigInt(right.version) ? 1 : 0,
    );
    let highestAppliedVersion = applied.rows.reduce(
      (highest, row) => BigInt(row.version) > highest ? BigInt(row.version) : highest,
      0n,
    );
    for (const migration of orderedMigrations) {
      if (seenVersions.has(migration.version)) {
        throw new PersistenceConflictError("Migration versions must be unique numeric identifiers.");
      }
      seenVersions.add(migration.version);
      const checksum = sha256(migration.sql);
      const existing = appliedByVersion.get(migration.version);
      if (existing !== undefined) {
        if (existing !== checksum) throw new PersistenceConflictError("Migration checksum changed for version " + migration.version + ".");
        continue;
      }
      if (BigInt(migration.version) <= highestAppliedVersion) {
        throw new PersistenceConflictError("A new migration cannot be inserted behind the applied migration sequence.");
      }
      await client.query(migration.sql);
      await client.query(
        "INSERT INTO atheer.atheer_schema_migrations (version, checksum) VALUES ($1, $2)",
        [migration.version, checksum],
      );
      appliedByVersion.set(migration.version, checksum);
      highestAppliedVersion = BigInt(migration.version);
    }
  });
}

export async function runSqlMigrations(pool: SqlPool, directory?: string): Promise<void> {
  await applySqlMigrations(pool, await loadSqlMigrations(directory));
}

export async function verifySqlMigrations(pool: SqlPool, directory?: string): Promise<void> {
  const migrations = await loadSqlMigrations(directory);
  let applied: SqlResult<{ version: string; checksum: string }>;
  try {
    applied = await pool.query<{ version: string; checksum: string }>(
      "SELECT version, checksum FROM atheer.atheer_schema_migrations ORDER BY version",
    );
  } catch {
    throw new PersistenceConflictError("PostgreSQL schema migration ledger is unavailable; apply migrations explicitly before starting the API.");
  }
  const appliedByVersion = new Map(applied.rows.map((row) => [row.version, row.checksum]));
  for (const migration of migrations) {
    const checksum = sha256(migration.sql);
    const existing = appliedByVersion.get(migration.version);
    if (existing === undefined) {
      throw new PersistenceConflictError("PostgreSQL schema is missing migration " + migration.version + "; apply migrations explicitly.");
    }
    if (existing !== checksum) {
      throw new PersistenceConflictError("PostgreSQL migration checksum differs for version " + migration.version + ".");
    }
  }
  const knownVersions = new Set(migrations.map((migration) => migration.version));
  if (applied.rows.some((row) => !knownVersions.has(row.version))) {
    throw new PersistenceConflictError("PostgreSQL schema contains migrations unknown to this application version.");
  }
}

export interface TradingPersistenceRepository {
  registerInstrument(instrument: InstrumentIdentity, specification: InstrumentSpecification): Promise<void>;
  registerBrokerAccount(account: BrokerAccountIdentity): Promise<void>;
  recordAccountSnapshot(account: BrokerAccountIdentity, snapshot: AccountBalanceSnapshot): Promise<void>;
  persistIntentAndRiskAssessment(intent: OrderIntentEnvelope, assessment: RiskAssessment): Promise<PersistIntentResult>;
  persistAuthorizedOrder(input: {
    readonly orderId: OrderId;
    readonly intent: OrderIntentEnvelope;
    readonly assessment: RiskAssessment;
    readonly createdAt: UtcTimestamp;
  }): Promise<PersistAuthorizedOrderResult>;
  recordReconciliationEvent(event: ReconciliationEvent): Promise<void>;
  recordAuditEvent(event: AuditEvent): Promise<void>;
}

export class PostgresTradingRepository implements TradingPersistenceRepository {
  constructor(private readonly pool: SqlPool, private readonly environment: TradingEnvironment) {}

  private assertEnvironment(value: TradingEnvironment): void {
    if (value !== this.environment) throw new PersistenceConflictError("Record environment does not match this persistence boundary.");
  }

  async registerInstrument(instrument: InstrumentIdentity, specification: InstrumentSpecification): Promise<void> {
    validateInstrumentIdentity(instrument);
    validateInstrumentSpecification(specification);
    this.assertEnvironment(specification.brokerReference.environment);
    if (specification.instrumentId !== instrument.id) throw new PersistenceConflictError("Instrument specification identity mismatch.");
    const payload = canonicalJson(specification);
    const payloadHash = sha256(payload);
    await inTransaction(this.pool, async (client) => {
      const insertedInstrument = await client.query(
        "INSERT INTO atheer.instruments (environment, instrument_id, canonical_code, display_name, asset_class_code) VALUES ($1,$2,$3,$4,$5) ON CONFLICT (environment,instrument_id) DO NOTHING RETURNING instrument_id",
        [this.environment, instrument.id, instrument.canonicalCode, instrument.displayName, instrument.assetClassCode],
      );
      if (insertedInstrument.rowCount === 0) {
        const existingInstrument = await client.query<{ canonical_code: string; display_name: string; asset_class_code: string }>(
          "SELECT canonical_code,display_name,asset_class_code FROM atheer.instruments WHERE environment=$1 AND instrument_id=$2 FOR UPDATE",
          [this.environment, instrument.id],
        );
        const row = existingInstrument.rows[0];
        if (!row || row.canonical_code !== instrument.canonicalCode || row.display_name !== instrument.displayName || row.asset_class_code !== instrument.assetClassCode) {
          throw new PersistenceConflictError("Canonical instrument identity is immutable and conflicts with the persisted record.");
        }
      }
      const inserted = await client.query(
        "INSERT INTO atheer.instrument_specifications (environment,specification_id,instrument_id,broker_id,broker_instrument_id,specification_version,retrieved_at,payload_hash,provenance,payload) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9::jsonb,$10::jsonb) ON CONFLICT (environment,specification_id) DO NOTHING RETURNING specification_id",
        [this.environment, specification.id, instrument.id, specification.brokerReference.brokerId, specification.brokerReference.brokerInstrumentId, specification.version, isoTimestamp(specification.retrievedAt), payloadHash, canonicalJson(specification.provenance), payload],
      );
      if (inserted.rowCount === 0) {
        const existing = await client.query<{ payload_hash: string }>(
          "SELECT payload_hash FROM atheer.instrument_specifications WHERE environment=$1 AND specification_id=$2 FOR UPDATE",
          [this.environment, specification.id],
        );
        if (existing.rows[0]?.payload_hash !== payloadHash) throw new PersistenceConflictError("Instrument specification identity was reused with different content.");
      }
    });
  }

  async registerBrokerAccount(account: BrokerAccountIdentity): Promise<void> {
    validateBrokerAccountIdentity(account);
    this.assertEnvironment(account.environment);
    await this.pool.query(
      "INSERT INTO atheer.broker_accounts (environment,account_id,broker_id,broker_account_reference,account_currency) VALUES ($1,$2,$3,$4,$5) ON CONFLICT (environment,account_id) DO NOTHING",
      [this.environment, account.id, account.brokerId, account.brokerAccountReference, account.accountCurrency ?? null],
    );
    const existing = await this.pool.query<{ broker_id: string; broker_account_reference: string; account_currency: string | null }>(
      "SELECT broker_id,broker_account_reference,account_currency FROM atheer.broker_accounts WHERE environment=$1 AND account_id=$2",
      [this.environment, account.id],
    );
    const row = existing.rows[0];
    if (!row || row.broker_id !== account.brokerId || row.broker_account_reference !== account.brokerAccountReference || row.account_currency !== (account.accountCurrency ?? null)) {
      throw new PersistenceConflictError("Broker account identity conflicts with the persisted record.");
    }
  }

  async recordAccountSnapshot(account: BrokerAccountIdentity, snapshot: AccountBalanceSnapshot): Promise<void> {
    validateAccountBalanceSnapshot(account, snapshot);
    this.assertEnvironment(snapshot.environment);
    const payload = canonicalJson(snapshot);
    const payloadHash = sha256(payload);
    const snapshotId = payloadHash;
    await this.pool.query(
      "INSERT INTO atheer.account_balance_snapshots (environment,snapshot_id,account_id,as_of,payload_hash,provenance,payload) VALUES ($1,$2,$3,$4,$5,$6::jsonb,$7::jsonb) ON CONFLICT (environment,account_id,as_of) DO NOTHING",
      [this.environment, snapshotId, account.id, isoTimestamp(snapshot.asOf), payloadHash, canonicalJson(snapshot.provenance), payload],
    );
    const existing = await this.pool.query<{ payload_hash: string }>(
      "SELECT payload_hash FROM atheer.account_balance_snapshots WHERE environment=$1 AND account_id=$2 AND as_of=$3",
      [this.environment, account.id, isoTimestamp(snapshot.asOf)],
    );
    if (existing.rows[0]?.payload_hash !== payloadHash) throw new PersistenceConflictError("A different account snapshot already exists for this broker timestamp.");
  }

  async persistIntentAndRiskAssessment(intent: OrderIntentEnvelope, assessment: RiskAssessment): Promise<PersistIntentResult> {
    createOrderIntentEnvelope(intent);
    createRiskAssessment(assessment);
    this.assertEnvironment(intent.environment);
    this.assertEnvironment(assessment.provenance.environment);
    if (assessment.intentId !== intent.id) throw new PersistenceConflictError("Risk assessment must reference the persisted order intent.");
    const intentPayload = canonicalJson(intent);
    const intentHash = sha256(intentPayload);
    const assessmentPayload = canonicalJson(assessment);
    const assessmentHash = sha256(assessmentPayload);
    return inTransaction(this.pool, async (client) => {
      const insertedIntent = await client.query(
        "INSERT INTO atheer.order_intents (environment,intent_id,command_id,correlation_id,idempotency_key,account_id,instrument_id,specification_id,created_at,intent_version,schema_version,payload_hash,payload) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13::jsonb) ON CONFLICT (environment,account_id,idempotency_key) DO NOTHING RETURNING intent_id",
        [this.environment,intent.id,intent.commandId,intent.correlationId,intent.idempotencyKey,intent.accountId,intent.instrumentId,intent.instrumentSpecificationId,isoTimestamp(intent.createdAt),intent.intentVersion,intent.schemaVersion,intentHash,intentPayload],
      );
      const intentInserted = insertedIntent.rowCount === 1;
      if (!intentInserted) {
        const existing = await client.query<{ intent_id: string; payload_hash: string }>(
          "SELECT intent_id,payload_hash FROM atheer.order_intents WHERE environment=$1 AND account_id=$2 AND idempotency_key=$3 FOR UPDATE",
          [this.environment,intent.accountId,intent.idempotencyKey],
        );
        if (existing.rows[0]?.intent_id !== intent.id || existing.rows[0]?.payload_hash !== intentHash) {
          throw new PersistenceConflictError("Idempotency key was reused for a different order intent.");
        }
      }
      const insertedAssessment = await client.query(
        "INSERT INTO atheer.risk_assessments (environment,risk_assessment_id,intent_id,policy_version,outcome,evaluated_at,payload_hash,payload) VALUES ($1,$2,$3,$4,$5,$6,$7,$8::jsonb) ON CONFLICT (environment,risk_assessment_id) DO NOTHING RETURNING risk_assessment_id",
        [this.environment,assessment.id,assessment.intentId,assessment.policyVersion,assessment.outcome,isoTimestamp(assessment.evaluatedAt),assessmentHash,assessmentPayload],
      );
      const riskAssessmentInserted = insertedAssessment.rowCount === 1;
      if (!riskAssessmentInserted) {
        const existing = await client.query<{ payload_hash: string }>(
          "SELECT payload_hash FROM atheer.risk_assessments WHERE environment=$1 AND risk_assessment_id=$2 FOR UPDATE",
          [this.environment,assessment.id],
        );
        if (existing.rows[0]?.payload_hash !== assessmentHash) throw new PersistenceConflictError("Risk assessment identity was reused with different content.");
      }
      await client.query(
        "INSERT INTO atheer.domain_outbox (environment,outbox_id,aggregate_type,aggregate_id,event_type,correlation_id,idempotency_key,payload) VALUES ($1,$2,'ORDER_INTENT',$3,'order.intent.persisted',$4,$5,$6::jsonb) ON CONFLICT (environment,event_type,idempotency_key) DO NOTHING",
        [this.environment,"intent:" + intent.id,intent.id,intent.correlationId,"intent:" + intent.id,canonicalJson({ intentId: intent.id, payloadHash: intentHash })],
      );
      await client.query(
        "INSERT INTO atheer.domain_outbox (environment,outbox_id,aggregate_type,aggregate_id,event_type,correlation_id,idempotency_key,payload) VALUES ($1,$2,'RISK_ASSESSMENT',$3,'risk.assessment.persisted',$4,$5,$6::jsonb) ON CONFLICT (environment,event_type,idempotency_key) DO NOTHING",
        [this.environment,"risk:" + assessment.id,assessment.id,intent.correlationId,"risk:" + assessment.id,canonicalJson({ intentId: intent.id, riskAssessmentId: assessment.id, outcome: assessment.outcome, policyVersion: assessment.policyVersion })],
      );
      await client.query(
        "INSERT INTO atheer.audit_events (environment,audit_event_id,correlation_id,subject_type,subject_id,event_type,occurred_at,payload_hash,payload) VALUES ($1,$2,$3,'ORDER_INTENT',$4,'trading.intent-and-risk.persisted',$5,$6,$7::jsonb) ON CONFLICT (environment,audit_event_id) DO NOTHING",
        [this.environment,"risk-assessment:" + assessment.id,intent.correlationId,intent.id,isoTimestamp(assessment.evaluatedAt),assessmentHash,canonicalJson({ intentId: intent.id, riskAssessmentId: assessment.id, outcome: assessment.outcome, policyVersion: assessment.policyVersion })],
      );
      return { intentInserted, riskAssessmentInserted, replayed: !intentInserted && !riskAssessmentInserted };
    });
  }
  async persistAuthorizedOrder(input: {
    readonly orderId: OrderId;
    readonly intent: OrderIntentEnvelope;
    readonly assessment: RiskAssessment;
    readonly createdAt: UtcTimestamp;
  }): Promise<PersistAuthorizedOrderResult> {
    const order = createOmsOrder({
      id: input.orderId,
      intent: input.intent,
      riskAssessment: input.assessment,
      createdAt: input.createdAt,
    });
    this.assertEnvironment(order.environment);
    const orderPayload = canonicalJson(order);
    const orderHash = sha256(orderPayload);
    const transition = createOrderLifecycleTransition({
      eventId: "order-persisted:" + order.id,
      orderId: order.id,
      fromState: "AUTHORIZED",
      toState: "PERSISTED",
      sourceKind: "OMS",
      sourceId: "atheer-oms" as import("../domain/shared.ts").SourceId,
      occurredAt: input.createdAt,
      correlationId: order.correlationId,
      orderVersion: 1,
    });
    const transitionPayload = canonicalJson(transition);
    const transitionHash = sha256(transitionPayload);

    return inTransaction(this.pool, async (client) => {
      const persistedIntent = await client.query<{ payload_hash: string }>(
        "SELECT payload_hash FROM atheer.order_intents WHERE environment=$1 AND intent_id=$2 AND account_id=$3 AND instrument_id=$4 FOR UPDATE",
        [this.environment, input.intent.id, input.intent.accountId, input.intent.instrumentId],
      );
      if (persistedIntent.rows[0]?.payload_hash !== sha256(canonicalJson(input.intent))) {
        throw new PersistenceConflictError("OMS order intent must exactly match the immutable, persisted intent envelope.");
      }

      const persistedAssessment = await client.query<{ payload_hash: string; outcome: string }>(
        "SELECT payload_hash,outcome FROM atheer.risk_assessments WHERE environment=$1 AND risk_assessment_id=$2 AND intent_id=$3 FOR UPDATE",
        [this.environment, input.assessment.id, input.intent.id],
      );
      if (
        persistedAssessment.rows[0]?.outcome !== "AUTHORIZED" ||
        persistedAssessment.rows[0]?.payload_hash !== sha256(canonicalJson(input.assessment))
      ) {
        throw new PersistenceConflictError("OMS order requires the exact persisted AUTHORIZED risk assessment for this intent and environment.");
      }

      const inserted = await client.query(
        "INSERT INTO atheer.orders (environment,order_id,intent_id,risk_assessment_id,account_id,instrument_id,correlation_id,state,version,requested_quantity,filled_quantity,remaining_quantity,quantity_unit,created_at,updated_at,payload_hash,payload) VALUES ($1,$2,$3,$4,$5,$6,$7,'PERSISTED',1,$8,$9,$10,$11,$12,$12,$13,$14::jsonb) ON CONFLICT (environment,intent_id) DO NOTHING RETURNING order_id",
        [
          this.environment, order.id, order.intentId, order.riskAssessmentId, order.accountId,
          order.instrumentId, order.correlationId, order.requestedQuantity.value,
          order.filledQuantity.value, order.remainingQuantity.value, order.requestedQuantity.unit,
          isoTimestamp(order.createdAt), orderHash, orderPayload,
        ],
      );
      const orderInserted = inserted.rowCount === 1;
      if (!orderInserted) {
        const existing = await client.query<{ order_id: string; payload_hash: string }>(
          "SELECT order_id,payload_hash FROM atheer.orders WHERE environment=$1 AND intent_id=$2",
          [this.environment, order.intentId],
        );
        if (existing.rows[0]?.order_id !== order.id || existing.rows[0]?.payload_hash !== orderHash) {
          throw new PersistenceConflictError("An OMS order already exists for this intent with a different order identity or payload.");
        }
      }

      await client.query(
        "INSERT INTO atheer.order_lifecycle_events (environment,event_id,order_id,from_state,to_state,source_kind,source_id,occurred_at,correlation_id,order_version,payload_hash,payload) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12::jsonb) ON CONFLICT (environment,event_id) DO NOTHING",
        [
          this.environment, transition.eventId, transition.orderId, transition.fromState,
          transition.toState, transition.sourceKind, transition.sourceId,
          isoTimestamp(transition.occurredAt), transition.correlationId,
          transition.orderVersion, transitionHash, transitionPayload,
        ],
      );
      const persistedTransition = await client.query<{ payload_hash: string }>(
        "SELECT payload_hash FROM atheer.order_lifecycle_events WHERE environment=$1 AND event_id=$2",
        [this.environment, transition.eventId],
      );
      if (persistedTransition.rows[0]?.payload_hash !== transitionHash) {
        throw new PersistenceConflictError("OMS lifecycle event identity was reused with different content.");
      }

      await client.query(
        "INSERT INTO atheer.domain_outbox (environment,outbox_id,aggregate_type,aggregate_id,event_type,correlation_id,idempotency_key,payload) VALUES ($1,$2,'ORDER',$3,'oms.order.persisted',$4,$5,$6::jsonb) ON CONFLICT (environment,event_type,idempotency_key) DO NOTHING",
        [
          this.environment, "oms-order:" + order.id, order.id, order.correlationId,
          "oms-order:" + order.id,
          canonicalJson({ orderId: order.id, intentId: order.intentId, riskAssessmentId: order.riskAssessmentId, state: order.state, version: order.version }),
        ],
      );
      await client.query(
        "INSERT INTO atheer.audit_events (environment,audit_event_id,correlation_id,subject_type,subject_id,event_type,occurred_at,payload_hash,payload) VALUES ($1,$2,$3,'ORDER',$4,'trading.order.persisted',$5,$6,$7::jsonb) ON CONFLICT (environment,audit_event_id) DO NOTHING",
        [
          this.environment, "oms-order-persisted:" + order.id, order.correlationId,
          order.id, isoTimestamp(order.createdAt), transitionHash, transitionPayload,
        ],
      );
      return { orderInserted, replayed: !orderInserted, order };
    });
  }

  async recordReconciliationEvent(event: ReconciliationEvent): Promise<void> {
    createReconciliationEvent(event);
    this.assertEnvironment(event.environment);
    const payload = canonicalJson(event);
    const payloadHash = sha256(payload);
    await inTransaction(this.pool, async (client) => {
      await client.query(
        "INSERT INTO atheer.reconciliation_events (environment,reconciliation_event_id,aggregate_type,aggregate_id,outcome_code,occurred_at,payload_hash,discrepancy_codes,provenance,payload) VALUES ($1,$2,$3,$4,$5,$6,$7,$8::jsonb,$9::jsonb,$10::jsonb) ON CONFLICT (environment,reconciliation_event_id) DO NOTHING",
        [this.environment,event.id,event.aggregateType,event.aggregateId,event.outcomeCode,isoTimestamp(event.occurredAt),payloadHash,canonicalJson(event.discrepancyCodes),canonicalJson(event.provenance),payload],
      );
      const existing = await client.query<{ payload_hash: string }>(
        "SELECT payload_hash FROM atheer.reconciliation_events WHERE environment=$1 AND reconciliation_event_id=$2",
        [this.environment,event.id],
      );
      if (existing.rows[0]?.payload_hash !== payloadHash) throw new PersistenceConflictError("Reconciliation event identity was reused with different content.");
      await client.query(
        "INSERT INTO atheer.domain_outbox (environment,outbox_id,aggregate_type,aggregate_id,event_type,correlation_id,idempotency_key,payload) VALUES ($1,$2,'RECONCILIATION',$3,'reconciliation.event.persisted',$4,$5,$6::jsonb) ON CONFLICT (environment,event_type,idempotency_key) DO NOTHING",
        [this.environment,"reconciliation:" + event.id,event.aggregateId,event.id,"reconciliation:" + event.id,payload],
      );
    });
  }

  async recordAuditEvent(event: AuditEvent): Promise<void> {
    createAuditEvent(event);
    this.assertEnvironment(event.environment);
    const payload = canonicalJson(event);
    const payloadHash = sha256(payload);
    await inTransaction(this.pool, async (client) => {
      await client.query(
        "INSERT INTO atheer.audit_events (environment,audit_event_id,correlation_id,subject_type,subject_id,event_type,occurred_at,payload_hash,payload) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9::jsonb) ON CONFLICT (environment,audit_event_id) DO NOTHING",
        [this.environment,event.id,event.correlationId,event.subjectType,event.subjectId,event.actionCode,isoTimestamp(event.occurredAt),payloadHash,payload],
      );
      const existing = await client.query<{ payload_hash: string }>(
        "SELECT payload_hash FROM atheer.audit_events WHERE environment=$1 AND audit_event_id=$2",
        [this.environment,event.id],
      );
      if (existing.rows[0]?.payload_hash !== payloadHash) throw new PersistenceConflictError("Audit event identity was reused with different content.");
      await client.query(
        "INSERT INTO atheer.domain_outbox (environment,outbox_id,aggregate_type,aggregate_id,event_type,correlation_id,idempotency_key,payload) VALUES ($1,$2,'AUDIT',$3,'audit.event.persisted',$4,$5,$6::jsonb) ON CONFLICT (environment,event_type,idempotency_key) DO NOTHING",
        [this.environment,"audit:" + event.id,event.subjectId,event.correlationId,"audit:" + event.id,payload],
      );
    });
  }

}

export function isTradingEnvironment(value: string): value is TradingEnvironment {
  return value === "DEMO" || value === "SIMULATION" || value === "BACKTEST" || value === "LIVE";
}
