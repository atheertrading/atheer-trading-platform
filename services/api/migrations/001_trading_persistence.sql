CREATE TABLE instruments (
  environment text NOT NULL CHECK (environment IN ('DEMO', 'SIMULATION', 'BACKTEST', 'LIVE')),
  instrument_id text NOT NULL,
  canonical_code text NOT NULL,
  display_name text NOT NULL,
  asset_class_code text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (environment, instrument_id)
);

CREATE TABLE instrument_specifications (
  environment text NOT NULL,
  specification_id text NOT NULL,
  instrument_id text NOT NULL,
  broker_id text NOT NULL,
  broker_instrument_id text NOT NULL,
  specification_version integer NOT NULL CHECK (specification_version > 0),
  retrieved_at timestamptz NOT NULL,
  payload_hash char(64) NOT NULL CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  provenance jsonb NOT NULL,
  payload jsonb NOT NULL,
  PRIMARY KEY (environment, specification_id),
  UNIQUE (environment, instrument_id, broker_id, broker_instrument_id, specification_version),
  FOREIGN KEY (environment, instrument_id) REFERENCES instruments (environment, instrument_id)
);

CREATE TABLE broker_accounts (
  environment text NOT NULL CHECK (environment IN ('DEMO', 'SIMULATION', 'BACKTEST', 'LIVE')),
  account_id text NOT NULL,
  broker_id text NOT NULL,
  broker_account_reference text NOT NULL,
  account_currency char(3),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (environment, account_id),
  UNIQUE (environment, broker_id, broker_account_reference)
);

CREATE TABLE account_balance_snapshots (
  environment text NOT NULL,
  snapshot_id char(64) NOT NULL CHECK (snapshot_id ~ '^[0-9a-f]{64}$'),
  account_id text NOT NULL,
  as_of timestamptz NOT NULL,
  payload_hash char(64) NOT NULL CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  provenance jsonb NOT NULL,
  payload jsonb NOT NULL,
  PRIMARY KEY (environment, snapshot_id),
  UNIQUE (environment, account_id, as_of),
  FOREIGN KEY (environment, account_id) REFERENCES broker_accounts (environment, account_id)
);

CREATE TABLE order_intents (
  environment text NOT NULL CHECK (environment IN ('DEMO', 'SIMULATION', 'BACKTEST', 'LIVE')),
  intent_id text NOT NULL,
  command_id text NOT NULL,
  correlation_id text NOT NULL,
  idempotency_key text NOT NULL,
  account_id text NOT NULL,
  instrument_id text NOT NULL,
  specification_id text NOT NULL,
  created_at timestamptz NOT NULL,
  intent_version integer NOT NULL CHECK (intent_version > 0),
  schema_version text NOT NULL,
  payload_hash char(64) NOT NULL CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  payload jsonb NOT NULL,
  PRIMARY KEY (environment, intent_id),
  UNIQUE (environment, account_id, idempotency_key),
  FOREIGN KEY (environment, account_id) REFERENCES broker_accounts (environment, account_id),
  FOREIGN KEY (environment, instrument_id) REFERENCES instruments (environment, instrument_id),
  FOREIGN KEY (environment, specification_id) REFERENCES instrument_specifications (environment, specification_id)
);
CREATE INDEX order_intents_correlation_idx ON order_intents (environment, correlation_id);

CREATE TABLE risk_assessments (
  environment text NOT NULL CHECK (environment IN ('DEMO', 'SIMULATION', 'BACKTEST', 'LIVE')),
  risk_assessment_id text NOT NULL,
  intent_id text NOT NULL,
  policy_version text NOT NULL,
  outcome text NOT NULL CHECK (outcome IN ('AUTHORIZED', 'REJECTED', 'HELD')),
  evaluated_at timestamptz NOT NULL,
  payload_hash char(64) NOT NULL CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  payload jsonb NOT NULL,
  PRIMARY KEY (environment, risk_assessment_id),
  FOREIGN KEY (environment, intent_id) REFERENCES order_intents (environment, intent_id)
);
CREATE INDEX risk_assessments_intent_idx ON risk_assessments (environment, intent_id, evaluated_at);

CREATE TABLE domain_outbox (
  environment text NOT NULL CHECK (environment IN ('DEMO', 'SIMULATION', 'BACKTEST', 'LIVE')),
  outbox_id text NOT NULL,
  aggregate_type text NOT NULL,
  aggregate_id text NOT NULL,
  event_type text NOT NULL CHECK (event_type IN ('order.intent.persisted', 'risk.assessment.persisted')),
  correlation_id text NOT NULL,
  idempotency_key text NOT NULL,
  payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  published_at timestamptz,
  attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  PRIMARY KEY (environment, outbox_id),
  UNIQUE (environment, event_type, idempotency_key)
);
CREATE INDEX domain_outbox_pending_idx ON domain_outbox (created_at) WHERE published_at IS NULL;

CREATE TABLE audit_events (
  environment text NOT NULL CHECK (environment IN ('DEMO', 'SIMULATION', 'BACKTEST', 'LIVE')),
  audit_event_id text NOT NULL,
  correlation_id text NOT NULL,
  subject_type text NOT NULL,
  subject_id text NOT NULL,
  event_type text NOT NULL,
  occurred_at timestamptz NOT NULL,
  payload_hash char(64) NOT NULL CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  payload jsonb NOT NULL,
  PRIMARY KEY (environment, audit_event_id)
);
CREATE INDEX audit_events_subject_idx ON audit_events (environment, subject_type, subject_id, occurred_at);
