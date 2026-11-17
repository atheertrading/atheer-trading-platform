import assert from "node:assert/strict";
import test from "node:test";
import { Pool } from "pg";
import {
  assetClassCode, brokerAccountId, brokerAccountReference, brokerId, brokerInstrumentId,
  commandId, correlationId, createAuditEvent, createDataProvenance, createOrderIntentEnvelope,
  createReconciliationEvent, createRiskAssessment, currencyCode, idempotencyKey, instrumentId,
  instrumentSpecificationId, orderIntentId, price, quantity, riskAssessmentId, sourceId,
  tradingEnvironment, unitCode, utcTimestamp,
} from "../dist/domain/index.js";
import {
  applySqlMigrations, loadSqlMigrations, PersistenceConflictError, PostgresTradingRepository,
  runSqlMigrations,
} from "../dist/persistence/postgres.js";

const enabled = typeof process.env.DATABASE_URL === "string" && process.env.DATABASE_URL.length > 0;

test("PostgreSQL migrations and durable trading journal preserve transactional invariants", { skip: !enabled }, async (t) => {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, max: 4 });
  try {
    const migrations = await loadSqlMigrations();
    await runSqlMigrations(pool);
    await Promise.all([runSqlMigrations(pool), runSqlMigrations(pool)]);
    await assert.rejects(
      applySqlMigrations(pool, [{ version: migrations[0].version, sql: migrations[0].sql + "\n-- checksum drift\n" }]),
      (error) => error instanceof PersistenceConflictError && error.message.includes("checksum"),
    );

    await assert.rejects(
      applySqlMigrations(pool, [
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
    const repository = new PostgresTradingRepository(pool, tradingEnvironment("DEMO"));
    await repository.registerBrokerAccount(account);
    await repository.registerInstrument(instrument, specification);

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
    const orphanCount = await pool.query("SELECT count(*)::text AS count FROM order_intents WHERE environment='DEMO' AND intent_id=$1", [orphanIntent.id]);
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

    const outbox = await pool.query("SELECT event_type FROM domain_outbox WHERE environment='DEMO' AND correlation_id=$1 ORDER BY event_type", [intent.correlationId]);
    assert.deepEqual(outbox.rows.map((row) => row.event_type).sort(), ["order.intent.persisted", "risk.assessment.persisted", "audit.event.persisted"].sort());
    const persisted = await pool.query("SELECT outcome FROM risk_assessments WHERE environment='DEMO' AND risk_assessment_id=$1", [assessment.id]);
    assert.equal(persisted.rows[0].outcome, "REJECTED");
    const reconciliationCount = await pool.query("SELECT count(*)::text AS count FROM reconciliation_events WHERE environment='DEMO' AND reconciliation_event_id=$1", [reconciliation.id]);
    assert.equal(reconciliationCount.rows[0].count, "1");
    const auditCount = await pool.query("SELECT count(*)::text AS count FROM audit_events WHERE environment='DEMO' AND audit_event_id=$1", [audit.id]);
    assert.equal(auditCount.rows[0].count, "1");

    const wrongEnvironment = new PostgresTradingRepository(pool, tradingEnvironment("SIMULATION"));
    await assert.rejects(wrongEnvironment.registerBrokerAccount(account), PersistenceConflictError);
    await t.test("rejected risk decisions are journaled but never create execution-dispatch events", async () => {
      const dispatch = await pool.query("SELECT count(*)::text AS count FROM domain_outbox WHERE event_type LIKE 'execution.dispatch.%' OR event_type='broker.order.submit'");
      assert.equal(dispatch.rows[0].count, "0");
    });
  } finally {
    await pool.end();
  }
});
