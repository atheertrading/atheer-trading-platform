# Domain Events Reference

**Status:** Versioned event envelope and event type catalogue implemented. Durable event publication and consumer processing are not implemented.

## Envelope

`DomainEvent<TPayload>` contains:

- `eventId` — immutable event identity.
- `eventType` — controlled trading event name.
- `aggregateId` and positive `aggregateVersion`.
- `occurredAt` — UTC timestamp.
- `correlationId` — end-to-end workflow identity.
- optional `causationId` — preceding event/command identity.
- `schemaVersion` — currently `1`.
- immutable payload snapshot.

Commands express requested actions; events express facts that occurred. An order intent event does not mean a broker order was submitted. An accepted event does not mean a fill occurred.

## Defined event types

- `OrderIntentCreated`
- `OrderValidated`
- `OrderRejected`
- `OrderSubmitted`
- `OrderAccepted`
- `OrderPartiallyFilled`
- `OrderFilled`
- `OrderCancelled`
- `PositionOpened`
- `PositionUpdated`
- `PositionClosed`
- `RiskLimitBreached`
- `TradingHalted`
- `OrderSubmissionUnknown`
- `ReconciliationRequired`

The current OMS emits `OrderIntentCreated` and `OrderValidated`/`OrderRejected` from the intent authorization slice. Broker/execution/position/halt events are type definitions for future authoritative producers; they are not claimed as emitted by a live service.

## Delivery contract

A future persistence adapter must atomically commit business state and outbox records. Event consumers must be idempotent and support duplicate delivery. No exactly-once delivery guarantee is claimed. Transport, schema registry, retention, replay and dead-letter policy remain open.
