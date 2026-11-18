import assert from "node:assert/strict";
import test from "node:test";
import { Pool } from "pg";
import {
  assetClassCode, brokerAccountId, brokerAccountReference, brokerId, brokerInstrumentId,
  commandId, correlationId, createAuditEvent, createDataProvenance, createOrderIntentEnvelope,
  createReconciliationEvent, createRiskAssessment, currencyCode, decimalValue, idempotencyKey, instrumentId,
  instrumentSpecificationId, orderIntentId, price, quantity, riskAssessmentId, sourceId,
  tradingEnvironment, unitCode, utcTimestamp,
} from "../dist/domain/index.js";
import {
  applySqlMigrations, loadSqlMigrations, PersistenceConflictError, PostgresTradingRepository,
  runSqlMigrations, verifySqlMigrations,
} from "../dist/persistence/postgres.js";

const enabled = typeof process.env.DATABASE_URL === "string" && process.env.DATABASE_URL.length > 0;

function asRole(adminPool, role) {
  return {
    async connect() {
      const client = await adminPool.connect();
      try { await client.query("SET ROLE " + role); return client; }
      catch (error) { client.release(); throw error; }
    },
    async query(sql, values) {
      const client = await this.connect();
      try { return await client.query(sql, values); }
      finally { client.release(); }
    },
    async end() {},
  };
}

test("PostgreSQL migrations and durable trading journal preserve transactional invariants", { skip: !enabled }, async (t) => {
  const adminPool = new Pool({ connectionString: process.env.DATABASE_URL, max: 8 });
  const migratorAdminPool = new Pool({ connectionString: process.env.DATABASE_URL, max: 4 });
  const appAdminPool = new Pool({ connectionString: process.env.DATABASE_URL, max: 4 });
  try {
    await adminPool.query("CREATE ROLE atheer_db_owner NOLOGIN");
    await adminPool.query("CREATE ROLE atheer_migrator NOLOGIN NOINHERIT");
    await adminPool.query("GRANT atheer_db_owner TO atheer_migrator");
    await adminPool.query("CREATE ROLE atheer_app NOLOGIN");
    await adminPool.query("CREATE SCHEMA atheer AUTHORIZATION atheer_db_owner");
    await adminPool.query("GRANT USAGE ON SCHEMA atheer TO atheer_app");
    await adminPool.query("ALTER DEFAULT PRIVILEGES FOR ROLE atheer_db_owner IN SCHEMA atheer GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO atheer_app");
    await adminPool.query("ALTER DEFAULT PRIVILEGES FOR ROLE atheer_db_owner IN SCHEMA atheer GRANT USAGE, SELECT ON SEQUENCES TO atheer_app");
    const migratorPool = asRole(migratorAdminPool, "atheer_migrator");
    const appPool = asRole(appAdminPool, "atheer_app");
    const migrations = await loadSqlMigrations();
    assert.ok(migrations.length > 0, "No SQL migrations were discovered.");
    await runSqlMigrations(migratorPool);
    await Promise.all([runSqlMigrations(migratorPool), runSqlMigrations(migratorPool)]);
    await verifySqlMigrations(appPool);
    await assert.rejects(
      migratorPool.query("CREATE TABLE atheer.migrator_must_not_create (id integer)"),
      (error) => error && error.code === "42501",
    );
    await assert.rejects(
      appPool.query("CREATE TABLE atheer.app_must_not_create (id integer)"),
      (error) => error && error.code === "42501",
    );
    const ownership = await appPool.query("SELECT tableowner FROM pg_tables WHERE schemaname='atheer'");
    assert.ok(ownership.rows.length > 0);
    assert.ok(ownership.rows.every((row) => row.tableowner === "atheer_db_owner"));

    // Verify owner-default sequence privileges independently from table DML grants.
    const ownerPool = asRole(adminPool, "atheer_db_owner");
    await ownerPool.query("CREATE SEQUENCE atheer.atheer_sequence_privilege_probe");
    const sequenceValue = await appPool.query("SELECT nextval('atheer.atheer_sequence_privilege_probe') AS value");
    assert.equal(Number(sequenceValue.rows[0].value), 1);
    await assert.rejects(
      appPool.query("CREATE SEQUENCE atheer.app_must_not_create_sequence"),
      (error) => error && error.code === "42501",
    );
    await assert.rejects(
      migratorPool.query("CREATE SEQUENCE atheer.migrator_must_not_create_sequence"),
      (error) => error && error.code === "42501",
    );
    await ownerPool.query("DROP SEQUENCE atheer.atheer_sequence_privilege_probe");

    const serverVersion = await appPool.query("SHOW server_version");
    console.info("PostgreSQL integration server version: " + serverVersion.rows[0].server_version);
    assert.match(serverVersion.rows[0].server_version, /^17\./);
    await assert.rejects(
      applySqlMigrations(migratorPool, [{ version: migrations[0].version, sql: migrations[0].sql + "\n-- checksum drift\n" }]),
      (error) => error instanceof PersistenceConflictError && error.message.includes("checksum"),
    );

    await assert.rejects(
      applySqlMigrations(migratorPool, [
        { version: "002", sql: "SELECT 1;" },
        { version: "002", sql: "SELECT 2;" },
      ]),
      PersistenceConflictError,
    );

    const prefix = "pg-it-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 8);
    const account = {
      id: brokerAccountId(prefix + "-account"), brokerId: brokerId("capital.com"), environment: tradingEnvironment("DEMO"),
      brokerAccountReference: brokerAccountReference(prefix + "-broker-account"), accountCurrency: currencyCode("USD"),
    };
    const instrument = {
      id: instrumentId(prefix + "-instrument"), canonicalCode: "XAUUSD", displayName: "Gold", assetClassCode: assetClassCode("COMMODITY"),
    };
    const provenance = createDataProvenance({
      source: { sourceId: sourceId("capital.com"), sourceType: "BROKER" }, environment: tradingEnvironment("DEMO"),
      eventAt: utcTimestamp(1_800_000_000_000), receivedAt: utcTimestamp(1_800_000_000_100),
      schemaVersion: "capital-v1", normalizationVersion: "1.0.0", validationCode: "VALID",
    });
    const specification = {
      id: instrumentSpecificationId(prefix + "-spec"), instrumentId: instrument.id,
      brokerReference: { brokerId: account.brokerId, environment: account.environment, brokerInstrumentId: brokerInstrumentId("GOLD") },
      version: 1, retrievedAt: provenance.receivedAt, provenance, pricePrecision: 2, quantityPrecision: 2,
      priceIncrement: price("0.01", unitCode("USD_PER_OUNCE"), currencyCode("USD")),
      minimumDealSize: quantity("0.1", unitCode("CONTRACT")), maximumDealSize: quantity("10", unitCode("CONTRACT")),
      quantityIncrement: quantity("0.1", unitCode("CONTRACT")), lotSize: quantity("1", unitCode("LOT")),
      contractSize: quantity("100", unitCode("OUNCE")), constraints: [],
    };
    const repository = new PostgresTradingRepository(appPool, tradingEnvironment("DEMO"));
    await repository.registerBrokerAccount(account);
    await repository.registerBrokerAccount(account);
    await repository.registerInstrument(instrument, specification);
    await repository.registerInstrument(instrument, specification);
    await assert.rejects(
      repository.registerInstrument({ ...instrument, displayName: "Conflicting canonical identity" }, specification),
      PersistenceConflictError,
    );

    const accountSnapshot = {
      accountId: account.id,
      environment: account.environment,
      asOf: provenance.eventAt,
      provenance,
      balance: { amount: decimalValue("1000.250000"), currency: currencyCode("USD") },
      equity: { amount: decimalValue("1012.50"), currency: currencyCode("USD") },
      availableFunds: { amount: decimalValue("900"), currency: currencyCode("USD") },
      usedMargin: { amount: decimalValue("112.50"), currency: currencyCode("USD") },
    };
    await repository.recordAccountSnapshot(account, accountSnapshot);
    await repository.recordAccountSnapshot(account, accountSnapshot);
    const exactBalance = await appPool.query(
      "SELECT payload->'balance'->>'amount' AS amount FROM atheer.account_balance_snapshots WHERE environment='DEMO' AND account_id=$1 AND as_of=$2",
      [account.id, new Date(accountSnapshot.asOf).toISOString()],
    );
    assert.equal(exactBalance.rows[0].amount, "1000.25");
    await assert.rejects(
      repository.recordAccountSnapshot(account, {
        ...accountSnapshot,
        balance: { amount: decimalValue("1000.26"), currency: currencyCode("USD") },
      }),
      PersistenceConflictError,
    );

    const intent = createOrderIntentEnvelope({
      id: orderIntentId(prefix + "-intent"), commandId: commandId(prefix + "-command"),
      correlationId: correlationId(prefix + "-correlation"), idempotencyKey: idempotencyKey(prefix + "-idempotency"),
      accountId: account.id, instrumentId: instrument.id, instrumentSpecificationId: specification.id, environment: account.environment,
      origin: { kind: "HUMAN", sourceId: sourceId("operator") }, createdAt: utcTimestamp(1_800_000_000_200),
      intentVersion: 1, schemaVersion: "1.0.0", payload: { operationCode: "OPEN", direction: "BUY", quantity: quantity("0.2", unitCode("CONTRACT")), orderTypeCode: "MARKET" },
    });
    const riskProvenance = createDataProvenance({
      source: { sourceId: sourceId("risk-engine"), sourceType: "INTERNAL" }, environment: account.environment,
      eventAt: utcTimestamp(1_800_000_000_300), receivedAt: utcTimestamp(1_800_000_000_300),
      schemaVersion: "risk-v1", normalizationVersion: "1.0.0", validationCode: "VALID",
    });
    const assessment = createRiskAssessment({
      id: riskAssessmentId(prefix + "-risk"), intentId: intent.id, policyVersion: "risk-policy-v1",
      outcome: "REJECTED", evaluatedAt: riskProvenance.eventAt, reasonCodes: ["TEST_REJECTION"],
      inputReferences: ["snapshot:test"], provenance: riskProvenance,
    });
    assert.deepEqual(await repository.persistIntentAndRiskAssessment(intent, assessment), { intentInserted: true, riskAssessmentInserted: true, replayed: false });
    assert.deepEqual(await repository.persistIntentAndRiskAssessment(intent, assessment), { intentInserted: false, riskAssessmentInserted: false, replayed: true });

    const orphanIntent = createOrderIntentEnvelope({
      ...intent,
      id: orderIntentId(prefix + "-orphan-intent"),
      accountId: brokerAccountId(prefix + "-missing-account"),
      idempotencyKey: idempotencyKey(prefix + "-orphan-idempotency"),
    });
    await assert.rejects(
      repository.persistIntentAndRiskAssessment(orphanIntent, { ...assessment, id: riskAssessmentId(prefix + "-orphan-risk"), intentId: orphanIntent.id }),
    );
    const orphanCount = await appPool.query("SELECT count(*)::text AS count FROM atheer.order_intents WHERE environment='DEMO' AND intent_id=$1", [orphanIntent.id]);
    assert.equal(orphanCount.rows[0].count, "0");

    const conflictingIntent = createOrderIntentEnvelope({
      ...intent, id: orderIntentId(prefix + "-other-intent"), payload: { ...intent.payload, quantity: quantity("0.3", unitCode("CONTRACT")) },
    });
    await assert.rejects(repository.persistIntentAndRiskAssessment(conflictingIntent, { ...assessment, id: riskAssessmentId(prefix + "-other-risk"), intentId: conflictingIntent.id }),
      (error) => error instanceof PersistenceConflictError && error.message.includes("Idempotency"));

    const reconciliation = createReconciliationEvent({
      id: (await import("../dist/domain/index.js")).reconciliationEventId(prefix + "-recon"),
      aggregateType: "ACCOUNT", aggregateId: account.id, outcomeCode: "MATCHED",
      occurredAt: provenance.eventAt, environment: account.environment, discrepancyCodes: [], provenance,
    });
    await repository.recordReconciliationEvent(reconciliation);
    const audit = createAuditEvent({
      id: (await import("../dist/domain/index.js")).auditEventId(prefix + "-audit"), actorKind: "SYSTEM",
      actorId: sourceId("persistence-test"), actionCode: "PERSISTENCE_TEST", subjectType: "ORDER_INTENT",
      subjectId: intent.id, outcomeCode: "RECORDED", occurredAt: riskProvenance.eventAt,
      correlationId: intent.correlationId, environment: account.environment, reasonCodes: [],
    });
    await repository.recordAuditEvent(audit);

    const outbox = await appPool.query("SELECT event_type FROM atheer.domain_outbox WHERE environment='DEMO' AND correlation_id=$1 ORDER BY event_type", [intent.correlationId]);
    assert.deepEqual(outbox.rows.map((row) => row.event_type).sort(), ["order.intent.persisted", "risk.assessment.persisted", "audit.event.persisted"].sort());
    const persisted = await appPool.query("SELECT outcome FROM atheer.risk_assessments WHERE environment='DEMO' AND risk_assessment_id=$1", [assessment.id]);
    assert.equal(persisted.rows[0].outcome, "REJECTED");
    const reconciliationCount = await appPool.query("SELECT count(*)::text AS count FROM atheer.reconciliation_events WHERE environment='DEMO' AND reconciliation_event_id=$1", [reconciliation.id]);
    assert.equal(reconciliationCount.rows[0].count, "1");
    const auditCount = await appPool.query("SELECT count(*)::text AS count FROM atheer.audit_events WHERE environment='DEMO' AND audit_event_id=$1", [audit.id]);
    assert.equal(auditCount.rows[0].count, "1");

    const wrongEnvironment = new PostgresTradingRepository(appPool, tradingEnvironment("SIMULATION"));
    await assert.rejects(wrongEnvironment.registerBrokerAccount(account), PersistenceConflictError);
    await t.test("rejected risk decisions are journaled but never create execution-dispatch events", async () => {
      const dispatch = await appPool.query("SELECT count(*)::text AS count FROM atheer.domain_outbox WHERE event_type LIKE 'execution.dispatch.%' OR event_type='broker.order.submit'");
      assert.equal(dispatch.rows[0].count, "0");
    });
  } finally {
    await Promise.all([adminPool.end(), migratorAdminPool.end(), appAdminPool.end()]);
  }
});
