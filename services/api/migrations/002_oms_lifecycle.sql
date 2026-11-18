ALTER TABLE atheer.risk_assessments
  ADD CONSTRAINT risk_assessments_order_reference_unique
  UNIQUE (environment, risk_assessment_id, intent_id);

ALTER TABLE atheer.domain_outbox
  DROP CONSTRAINT domain_outbox_event_type_check;

ALTER TABLE atheer.domain_outbox
  ADD CONSTRAINT domain_outbox_event_type_check
  CHECK (event_type IN (
    'order.intent.persisted',
    'risk.assessment.persisted',
    'reconciliation.event.persisted',
    'audit.event.persisted',
    'oms.order.persisted',
    'oms.order.lifecycle.changed'
  ));

CREATE TABLE atheer.orders (
  environment text NOT NULL CHECK (environment IN ('DEMO', 'SIMULATION', 'BACKTEST', 'LIVE')),
  order_id text NOT NULL,
  intent_id text NOT NULL,
  risk_assessment_id text NOT NULL,
  account_id text NOT NULL,
  instrument_id text NOT NULL,
  correlation_id text NOT NULL,
  state text NOT NULL CHECK (state IN (
    'CREATED', 'VALIDATING', 'RISK_CHECKING', 'AUTHORIZED', 'PERSISTED',
    'SUBMITTED', 'PENDING', 'ACCEPTED', 'WORKING', 'PARTIALLY_FILLED',
    'FILLED', 'CANCEL_PENDING', 'CANCELLED', 'REJECTED', 'EXPIRED',
    'UNKNOWN', 'RECONCILIATION_REQUIRED'
  )),
  version integer NOT NULL CHECK (version > 0),
  requested_quantity numeric NOT NULL CHECK (requested_quantity > 0),
  filled_quantity numeric NOT NULL DEFAULT 0 CHECK (filled_quantity >= 0),
  remaining_quantity numeric NOT NULL CHECK (remaining_quantity >= 0),
  quantity_unit text NOT NULL,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  payload_hash char(64) NOT NULL CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  payload jsonb NOT NULL,
  PRIMARY KEY (environment, order_id),
  UNIQUE (environment, intent_id),
  UNIQUE (environment, risk_assessment_id),
  FOREIGN KEY (environment, intent_id)
    REFERENCES atheer.order_intents (environment, intent_id),
  FOREIGN KEY (environment, risk_assessment_id, intent_id)
    REFERENCES atheer.risk_assessments (environment, risk_assessment_id, intent_id),
  FOREIGN KEY (environment, account_id)
    REFERENCES atheer.broker_accounts (environment, account_id),
  FOREIGN KEY (environment, instrument_id)
    REFERENCES atheer.instruments (environment, instrument_id),
  CHECK (filled_quantity + remaining_quantity = requested_quantity)
);

CREATE INDEX orders_active_idx
  ON atheer.orders (environment, account_id, updated_at)
  WHERE state NOT IN ('FILLED', 'CANCELLED', 'REJECTED', 'EXPIRED');

CREATE TABLE atheer.order_lifecycle_events (
  environment text NOT NULL,
  event_id text NOT NULL,
  order_id text NOT NULL,
  from_state text NOT NULL CHECK (from_state IN (
    'CREATED', 'VALIDATING', 'RISK_CHECKING', 'AUTHORIZED', 'PERSISTED',
    'SUBMITTED', 'PENDING', 'ACCEPTED', 'WORKING', 'PARTIALLY_FILLED',
    'FILLED', 'CANCEL_PENDING', 'CANCELLED', 'REJECTED', 'EXPIRED',
    'UNKNOWN', 'RECONCILIATION_REQUIRED'
  )),
  to_state text NOT NULL CHECK (to_state IN (
    'CREATED', 'VALIDATING', 'RISK_CHECKING', 'AUTHORIZED', 'PERSISTED',
    'SUBMITTED', 'PENDING', 'ACCEPTED', 'WORKING', 'PARTIALLY_FILLED',
    'FILLED', 'CANCEL_PENDING', 'CANCELLED', 'REJECTED', 'EXPIRED',
    'UNKNOWN', 'RECONCILIATION_REQUIRED'
  )),
  source_kind text NOT NULL CHECK (source_kind IN ('OMS', 'EXECUTION_GATEWAY', 'BROKER', 'RECONCILIATION')),
  source_id text NOT NULL,
  occurred_at timestamptz NOT NULL,
  correlation_id text NOT NULL,
  reason_code text,
  evidence_reference text,
  order_version integer NOT NULL CHECK (order_version > 0),
  payload_hash char(64) NOT NULL CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  payload jsonb NOT NULL,
  PRIMARY KEY (environment, event_id),
  UNIQUE (environment, order_id, order_version),
  FOREIGN KEY (environment, order_id)
    REFERENCES atheer.orders (environment, order_id)
);

CREATE INDEX order_lifecycle_events_order_idx
  ON atheer.order_lifecycle_events (environment, order_id, order_version);

GRANT SELECT, INSERT ON atheer.orders TO atheer_app;
REVOKE UPDATE, DELETE ON atheer.orders FROM atheer_app;
GRANT SELECT, INSERT ON atheer.order_lifecycle_events TO atheer_app;
REVOKE UPDATE, DELETE ON atheer.order_lifecycle_events FROM atheer_app;
