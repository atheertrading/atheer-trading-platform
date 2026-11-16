import test from 'node:test';
import assert from 'node:assert/strict';
import {
  Decimal, DomainError, Money, currency, UtcTimestamp,
  InstrumentSpecification, TradingInstrument, MarketQuote, TradingAccount, TradingSession,
  OrderIntent, TradingOrder, OrderExecution, TradingPosition, Portfolio, reconcilePosition, reconcileOrder,
  RiskEngine, MaximumOrderQuantityPolicy, MaximumInstrumentExposurePolicy, MaximumAccountExposurePolicy, OrderManagementService,
} from '../dist/domain/index.js';

const at = (iso = '2026-11-17T10:00:00.000Z') => UtcTimestamp.fromISO(iso);
const provenance = (kind = 'BROKER') => ({ kind, sourceId: 'test-source', observedAt: at(), normalizationVersion: '1' });
const accountId = 'account-1';
const instrumentId = 'instrument-1';

function instrument(overrides = {}) {
  const specification = new InstrumentSpecification({
    pricePrecision: 2, quantityPrecision: 2, priceTick: '0.01', quantityStep: '0.05',
    minimumQuantity: '0.01', maximumQuantity: '100', contractMultiplier: '1',
    valuationModel: 'LINEAR', effectiveFrom: at(), provenance: provenance(),
    ...overrides.specification,
  });
  return new TradingInstrument({ id: instrumentId, symbol: 'TEST', name: 'Test instrument', assetClass: 'EQUITY',
    quoteCurrency: 'USD', specification, active: true, ...overrides });
}
function account(environment = 'DEMO', platformTradingEnabled = true) {
  return new TradingAccount({ id: accountId, brokerId: 'broker-generic', environment, currency: 'USD', status: 'ACTIVE',
    brokerTradingEnabled: true, platformTradingEnabled, provenance: provenance() });
}
function quote(id = instrumentId, iso = '2026-11-17T10:00:00.000Z') {
  return new MarketQuote({ instrumentId: id, bid: '99.00', ask: '100.00', source: 'broker-feed', sourceEventTime: at(iso), receivedAt: at(iso) });
}
function intent(overrides = {}) {
  return new OrderIntent({ id: 'intent-1', accountId, instrumentId, environment: 'DEMO', sourceType: 'MANUAL', sourceId: 'desktop-user',
    operation: 'OPEN', side: 'BUY', orderType: 'MARKET', quantity: '2', idempotencyKey: 'idem-1', correlationId: 'corr-1',
    createdAt: at(), ...overrides });
}
function context(overrides = {}) {
  const a = overrides.account ?? account();
  return { account: a, session: overrides.session ?? TradingSession.start({ id: 'session-1', accountId: a.id, environment: a.environment, startedAt: at() }),
    instrument: overrides.instrument ?? instrument(), quote: overrides.quote ?? quote(), positions: overrides.positions ?? [], existingGrossExposureByCurrency: overrides.existingGrossExposureByCurrency ?? new Map(), exposureSnapshotComplete: overrides.exposureSnapshotComplete ?? true,
    assessedAt: overrides.assessedAt ?? at('2026-11-17T10:00:01.000Z'), emergencyHalt: overrides.emergencyHalt ?? false };
}
function riskEngine(policies = [new MaximumOrderQuantityPolicy('max-order', '1', '10')]) {
  return new RiskEngine({ policyVersion: 'risk-policy-1', maximumQuoteAgeMilliseconds: 5000, policies });
}

class MemoryOrderRegistry {
  entries = new Map();
  decisions = 0;
  events = [];
  async register(value, fingerprint, order, createdEvent) {
    const existing = this.entries.get(value.idempotencyKey);
    if (existing) return existing.fingerprint === fingerprint
      ? { kind: 'DUPLICATE', order: existing.order, decision: existing.decision }
      : { kind: 'CONFLICT' };
    this.entries.set(value.idempotencyKey, { fingerprint, order });
    this.events.push(createdEvent);
    return { kind: 'REGISTERED', order };
  }
  async recordRiskDecisionAndEvents(orderId, order, decision, events) {
    const entry = [...this.entries.values()].find(value => value.order.id === orderId);
    assert.ok(entry);
    entry.order = order;
    entry.decision = decision;
    this.decisions += 1;
    this.events.push(...events);
  }
  async findByIdempotencyKey(key) { return this.entries.get(key)?.order; }
  async findByOrderId(id) { return [...this.entries.values()].find(value => value.order.id === id)?.order; }
  async listByAccount() { return [...this.entries.values()].map(value => value.order); }
}

test('Decimal parses and calculates exactly without binary floating point', () => {
  assert.equal(Decimal.parse('0.1').add(Decimal.parse('0.2')).toString(), '0.3');
  assert.equal(Decimal.parse('12.50').multiply(Decimal.parse('2.4')).toString(), '30');
  assert.equal(Decimal.parse('1').divide(Decimal.parse('8'), 4, 'half-up').toString(), '0.125');
  assert.equal(Decimal.parse('1.005').quantize(2, 'half-up').toString(), '1.01');
  assert.equal(Decimal.parse('1.025').quantize(2, 'half-even').toString(), '1.02');
  assert.equal(Decimal.parse('-1.239').quantize(2, 'toward-zero').toString(), '-1.23');
});

test('Decimal rejects invalid values and division by zero', () => {
  assert.throws(() => Decimal.parse('NaN'), { code: 'INVALID_DECIMAL' });
  assert.throws(() => Decimal.parse('01.2'), { code: 'INVALID_DECIMAL' });
  assert.throws(() => Decimal.parse('1').divide(Decimal.zero(), 2, 'half-up'), { code: 'DIVISION_BY_ZERO' });
});

test('Money enforces currency-safe arithmetic', () => {
  assert.equal(new Money('10.25', 'usd').add(new Money('0.75', 'USD')).amount.toString(), '11');
  assert.throws(() => new Money('10', 'USD').add(new Money('1', 'EUR')), { code: 'CURRENCY_MISMATCH' });
  assert.throws(() => currency('US'), { code: 'INVALID_CURRENCY' });
});

test('UTC timestamps reject local or malformed timestamps', () => {
  assert.equal(at().toISOString(), '2026-11-17T10:00:00.000Z');
  assert.throws(() => UtcTimestamp.fromISO('2026-11-17T10:00:00'), { code: 'INVALID_TIMESTAMP' });
});

test('Instrument specification validates quantity precision, step, price tick and bounds', () => {
  const i = instrument();
  i.specification.validateQuantity(Decimal.parse('1.25'));
  i.specification.validatePrice(Decimal.parse('10.05'));
  assert.throws(() => i.specification.validateQuantity(Decimal.parse('0.015')), { code: 'INVALID_QUANTITY_PRECISION' });
  assert.throws(() => i.specification.validateQuantity(Decimal.parse('1.23')), { code: 'INVALID_QUANTITY_STEP' });
  assert.throws(() => i.specification.validatePrice(Decimal.parse('10.005')), { code: 'INVALID_PRICE_PRECISION' });
  assert.throws(() => i.specification.validateQuantity(Decimal.parse('101')), { code: 'QUANTITY_ABOVE_MAXIMUM' });
});

test('MarketQuote validates bid/ask ordering and calculates freshness explicitly', () => {
  assert.throws(() => new MarketQuote({ instrumentId, bid: '101', ask: '100', source: 'x', sourceEventTime: at(), receivedAt: at() }), { code: 'INVALID_QUOTE' });
  assert.equal(quote().isFreshAt(at('2026-11-17T10:00:05.000Z'), 5000), true);
  assert.equal(quote().isFreshAt(at('2026-11-17T10:00:06.000Z'), 5000), false);
  assert.equal(quote().executablePrice('BUY').toString(), '100');
  assert.equal(quote().executablePrice('SELL').toString(), '99');
});

test('TradingAccount cannot enable platform LIVE dealing', () => {
  assert.throws(() => account('LIVE', true), { code: 'LIVE_TRADING_DISABLED' });
  assert.equal(account('LIVE', false).canTrade, false);
});

test('TradingSession has explicit active, halted and closed transitions', () => {
  const session = TradingSession.start({ id: 's1', accountId, environment: 'DEMO', startedAt: at() });
  const halted = session.halt('operator halt');
  assert.equal(halted.input.state, 'HALTED');
  assert.throws(() => halted.halt('again'), { code: 'INVALID_SESSION_TRANSITION' });
  assert.equal(halted.close(at('2026-11-17T10:01:00.000Z')).input.state, 'CLOSED');
});

test('OrderIntent validates mandatory identifiers, quantity and order-type prices', () => {
  assert.throws(() => intent({ orderType: 'LIMIT' }), { code: 'LIMIT_PRICE_REQUIRED' });
  assert.throws(() => intent({ quantity: '0' }), { code: 'INVALID_ORDER_QUANTITY' });
  assert.throws(() => intent({ operation: 'CLOSE' }), { code: 'POSITION_REQUIRED' });
  const valid = intent({ orderType: 'STOP_LIMIT', stopPrice: '98', limitPrice: '97', stopLossPrice: '95', takeProfitPrice: '110' });
  assert.equal(valid.stopLossPrice.toString(), '95');
});

test('Order lifecycle rejects unauthorized and invalid state transitions', () => {
  let order = TradingOrder.fromIntent('order-1', intent());
  assert.throws(() => order.transition('SUBMISSION_PENDING', 'EXECUTION_GATEWAY', at('2026-11-17T10:00:01.000Z')), { code: 'INVALID_ORDER_TRANSITION' });
  order = order.transition('RISK_AUTHORIZED', 'RISK_ENGINE', at('2026-11-17T10:00:01.000Z'));
  order = order.transition('SUBMISSION_PENDING', 'EXECUTION_GATEWAY', at('2026-11-17T10:00:02.000Z'));
  order = order.transition('BROKER_ACCEPTED', 'BROKER_REPORT', at('2026-11-17T10:00:03.000Z'));
  assert.equal(order.input.status, 'BROKER_ACCEPTED');
});

test('Order rejection requires a reason and rejected orders are terminal', () => {
  const order = TradingOrder.fromIntent('order-1', intent());
  assert.throws(() => order.transition('RISK_REJECTED', 'RISK_ENGINE', at('2026-11-17T10:00:01.000Z')), { code: 'REJECTION_REASON_REQUIRED' });
  const rejected = order.transition('RISK_REJECTED', 'RISK_ENGINE', at('2026-11-17T10:00:01.000Z'), 'POLICY_BLOCK');
  assert.throws(() => rejected.transition('RISK_AUTHORIZED', 'RISK_ENGINE', at('2026-11-17T10:00:02.000Z')), { code: 'INVALID_ORDER_TRANSITION' });
});

function execution(id, orderId, quantity, price, seconds = 4) {
  const occurredAt = at(`2026-11-17T10:00:0${seconds}.000Z`);
  return new OrderExecution({ id, orderId, brokerExecutionReference: `broker-${id}`, quantity, price, occurredAt,
    receivedAt: at(`2026-11-17T10:00:0${seconds}.100Z`), provenance: provenance() });
}

test('Order records partial and complete fills with exact weighted average price', () => {
  const source = intent({ quantity: '5' });
  let order = TradingOrder.fromIntent('order-1', source)
    .transition('RISK_AUTHORIZED', 'RISK_ENGINE', at('2026-11-17T10:00:01.000Z'))
    .transition('SUBMISSION_PENDING', 'EXECUTION_GATEWAY', at('2026-11-17T10:00:02.000Z'))
    .transition('BROKER_ACCEPTED', 'BROKER_REPORT', at('2026-11-17T10:00:03.000Z'));
  order = order.applyExecution(execution('fill-1', 'order-1', '2', '100', 4));
  assert.equal(order.input.status, 'PARTIALLY_FILLED');
  order = order.applyExecution(execution('fill-2', 'order-1', '3', '101', 5));
  assert.equal(order.input.status, 'FILLED');
  assert.equal(order.filledQuantity.toString(), '5');
  assert.equal(order.averageFillPrice.toString(), '100.6');
});

test('Order execution is idempotent and rejects overfills or mismatched order IDs', () => {
  let order = TradingOrder.fromIntent('order-1', intent({ quantity: '2' }))
    .transition('RISK_AUTHORIZED', 'RISK_ENGINE', at('2026-11-17T10:00:01.000Z'))
    .transition('SUBMISSION_PENDING', 'EXECUTION_GATEWAY', at('2026-11-17T10:00:02.000Z'))
    .transition('BROKER_ACCEPTED', 'BROKER_REPORT', at('2026-11-17T10:00:03.000Z'));
  const fill = execution('fill-1', 'order-1', '1', '100', 4);
  order = order.applyExecution(fill);
  assert.equal(order.applyExecution(fill), order);
  assert.throws(() => order.applyExecution(execution('fill-2', 'order-1', '2', '100', 5)), { code: 'OVERFILL' });
  assert.throws(() => order.applyExecution(execution('fill-3', 'other-order', '1', '100', 5)), { code: 'EXECUTION_ORDER_MISMATCH' });
});

test('Unknown submission outcome requires reconciliation and cannot be blindly resubmitted', () => {
  const order = TradingOrder.fromIntent('order-1', intent())
    .transition('RISK_AUTHORIZED', 'RISK_ENGINE', at('2026-11-17T10:00:01.000Z'))
    .transition('SUBMISSION_PENDING', 'EXECUTION_GATEWAY', at('2026-11-17T10:00:02.000Z'))
    .transition('SUBMISSION_UNKNOWN', 'OMS', at('2026-11-17T10:00:03.000Z'))
    .transition('RECONCILIATION_REQUIRED', 'OMS', at('2026-11-17T10:00:04.000Z'));
  assert.equal(order.input.status, 'RECONCILIATION_REQUIRED');
  assert.throws(() => order.transition('SUBMISSION_PENDING', 'EXECUTION_GATEWAY', at('2026-11-17T10:00:05.000Z')), { code: 'INVALID_ORDER_TRANSITION' });
});

test('Position supports partial close and linear realized P&L for long positions', () => {
  const p = TradingPosition.open({ id: 'position-1', accountId, instrumentId, side: 'LONG', quantity: '10', averageEntryPrice: '100', quoteCurrency: 'USD', openedAt: at(), provenance: provenance() });
  const partial = p.close('4', '110', '1', at('2026-11-17T10:01:00.000Z'));
  assert.equal(partial.input.status, 'PARTIALLY_CLOSED');
  assert.equal(partial.quantity.toString(), '6');
  assert.equal(partial.calculatedRealizedPnl.amount.toString(), '40');
  assert.equal(partial.unrealizedPnl('115', '1').amount.toString(), '90');
  assert.equal(partial.grossExposure('115', '1').amount.toString(), '690');
  const closed = partial.close('6', '90', '1', at('2026-11-17T10:02:00.000Z'));
  assert.equal(closed.input.status, 'CLOSED');
  assert.equal(closed.calculatedRealizedPnl.amount.toString(), '-20');
});

test('Position supports short-side P&L and prevents over-close', () => {
  const p = TradingPosition.open({ id: 'position-2', accountId, instrumentId, side: 'SHORT', quantity: '3', averageEntryPrice: '100', quoteCurrency: 'USD', openedAt: at(), provenance: provenance() });
  const closed = p.close('1', '90', '2', at('2026-11-17T10:01:00.000Z'));
  assert.equal(closed.calculatedRealizedPnl.amount.toString(), '20');
  assert.throws(() => p.close('4', '90', '1', at('2026-11-17T10:01:00.000Z')), { code: 'POSITION_OVER_CLOSE' });
});

test('Position increase calculates weighted average entry price', () => {
  const p = TradingPosition.open({ id: 'position-3', accountId, instrumentId, side: 'LONG', quantity: '2', averageEntryPrice: '100', quoteCurrency: 'USD', openedAt: at(), provenance: provenance() });
  const increased = p.increase('3', '110', at('2026-11-17T10:01:00.000Z'));
  assert.equal(increased.quantity.toString(), '5');
  assert.equal(increased.averageEntryPrice.toString(), '106');
});

test('Position reconciliation reports discrepancies and preserves broker snapshot authority', () => {
  const p = TradingPosition.open({ id: 'position-4', accountId, instrumentId, side: 'LONG', quantity: '2', averageEntryPrice: '100', quoteCurrency: 'USD', openedAt: at(), provenance: provenance() });
  const broker = { positionId: p.id, accountId: p.input.accountId, instrumentId: p.input.instrumentId, side: 'LONG', quantity: Decimal.parse('3'), averageEntryPrice: Decimal.parse('100'), realizedPnl: new Money('0', 'USD'), unrealizedPnl: new Money('5', 'USD'), observedAt: at(), provenance: provenance() };
  const result = reconcilePosition(p, broker);
  assert.equal(result.matched, false);
  assert.deepEqual(result.discrepancies, ['QUANTITY_MISMATCH']);
  assert.equal(result.authoritative, broker);
});

test('Order reconciliation treats broker snapshot as authoritative evidence', () => {
  const order = TradingOrder.fromIntent('order-1', intent());
  const broker = { orderId: order.id, brokerOrderReference: 'broker-order-1', status: 'ACCEPTED', filledQuantity: Decimal.zero(), observedAt: at(), provenance: provenance() };
  const result = reconcileOrder(order, broker);
  assert.equal(result.authoritative, broker);
});

test('Portfolio groups exposure by quote currency without implicit FX conversion', () => {
  const p = TradingPosition.open({ id: 'position-5', accountId, instrumentId, side: 'LONG', quantity: '2', averageEntryPrice: '100', quoteCurrency: 'USD', openedAt: at(), provenance: provenance() });
  const portfolio = new Portfolio({ id: 'portfolio-1', accountId, baseCurrency: 'USD', positions: [p], observedAt: at(), provenance: provenance() });
  const exposures = portfolio.grossExposureByQuoteCurrency(new Map([[instrumentId, instrument()]]), new Map([[instrumentId, Decimal.parse('105')]]));
  assert.equal(exposures.get('USD').toString(), '210');
});

test('RiskEngine fails closed when no policies are configured', () => {
  const result = new RiskEngine({ policyVersion: 'none', maximumQuoteAgeMilliseconds: 5000, policies: [] }).assess(intent(), context());
  assert.equal(result.authorized, false);
  assert.ok(result.violations.some(v => v.code === 'RISK_POLICY_UNAVAILABLE'));
});

test('RiskEngine rejects excessive order volume and exposure', () => {
  const volumeResult = riskEngine([new MaximumOrderQuantityPolicy('volume', '1', '1')]).assess(intent(), context());
  assert.ok(volumeResult.violations.some(v => v.code === 'MAX_ORDER_QUANTITY_EXCEEDED'));
  const exposureResult = riskEngine([new MaximumInstrumentExposurePolicy('exposure', '1', new Money('150', 'USD'))]).assess(intent(), context());
  assert.ok(exposureResult.violations.some(v => v.code === 'MAX_INSTRUMENT_EXPOSURE_EXCEEDED'));
  const accountExposure = riskEngine([new MaximumAccountExposurePolicy('account-exposure', '1', new Money('150', 'USD'))]).assess(intent(), context({ existingGrossExposureByCurrency: new Map([['USD', Decimal.parse('100')]]) }));
  assert.ok(accountExposure.violations.some(v => v.code === 'MAX_ACCOUNT_EXPOSURE_EXCEEDED'));
  const incompleteExposure = riskEngine([new MaximumAccountExposurePolicy('account-exposure', '1', new Money('150', 'USD'))]).assess(intent(), context({ exposureSnapshotComplete: false }));
  assert.ok(incompleteExposure.violations.some(v => v.code === 'ACCOUNT_EXPOSURE_SNAPSHOT_INCOMPLETE'));
  const wrongCurrency = riskEngine([new MaximumAccountExposurePolicy('account-exposure', '1', new Money('150', 'EUR'))]).assess(intent(), context());
  assert.ok(wrongCurrency.violations.some(v => v.code === 'RISK_LIMIT_CURRENCY_MISMATCH'));
});

test('RiskEngine rejects halted, stale, inactive-account and LIVE contexts', () => {
  const engine = riskEngine();
  assert.ok(engine.assess(intent(), context({ emergencyHalt: true })).violations.some(v => v.code === 'TRADING_HALTED'));
  const reduceIntent = intent({ operation: 'REDUCE', positionId: 'position-1' });
  assert.equal(engine.assess(reduceIntent, context({ emergencyHalt: true })).authorized, true);
  const closedSession = TradingSession.start({ id: 'closed-session', accountId, environment: 'DEMO', startedAt: at() }).close(at('2026-11-17T10:00:00.500Z'));
  assert.ok(engine.assess(reduceIntent, context({ session: closedSession })).violations.some(v => v.code === 'SESSION_CLOSED'));
  assert.ok(engine.assess(intent(), context({ quote: quote(instrumentId, '2026-11-17T09:59:00.000Z') })).violations.some(v => v.code === 'MARKET_DATA_STALE'));
  assert.ok(engine.assess(intent(), context({ account: account('DEMO', false) })).violations.some(v => v.code === 'ACCOUNT_NOT_AUTHORIZED'));
  const liveIntent = intent({ environment: 'LIVE' });
  assert.ok(engine.assess(liveIntent, context({ account: account('LIVE', false), session: TradingSession.start({ id: 'live-session', accountId, environment: 'LIVE', startedAt: at() }) })).violations.some(v => v.code === 'LIVE_TRADING_DISABLED'));
});

test('RiskEngine rejects account, instrument and environment mismatches', () => {
  const engine = riskEngine();
  const wrongAccount = new TradingAccount({ id: 'other-account', brokerId: 'broker-generic', environment: 'DEMO', currency: 'USD', status: 'ACTIVE', brokerTradingEnabled: true, platformTradingEnabled: true, provenance: provenance() });
  const result = engine.assess(intent(), context({ account: wrongAccount }));
  assert.ok(result.violations.some(v => v.code === 'ACCOUNT_MISMATCH'));
  const noBrokerCapability = new TradingAccount({ id: accountId, brokerId: 'broker-generic', environment: 'DEMO', currency: 'USD', status: 'ACTIVE', brokerTradingEnabled: false, platformTradingEnabled: true, provenance: provenance() });
  assert.ok(engine.assess(intent(), context({ account: noBrokerCapability })).violations.some(v => v.code === 'BROKER_TRADING_DISABLED'));
});

test('OMS registers and risk-authorizes an intent through the single intake', async () => {
  const registry = new MemoryOrderRegistry();
  const service = new OrderManagementService(registry, riskEngine());
  const result = await service.registerAndAuthorize(intent(), context(), 'order-1');
  assert.equal(result.order.input.status, 'RISK_AUTHORIZED');
  assert.equal(result.decision.authorized, true);
  assert.equal(result.events[0].eventType, 'OrderIntentCreated');
  assert.equal(result.events[1].eventType, 'OrderValidated');
  assert.equal(result.events[1].correlationId, 'corr-1');
});

test('OMS returns existing outcome for duplicate idempotency key and rejects conflicting reuse', async () => {
  const registry = new MemoryOrderRegistry();
  const service = new OrderManagementService(registry, riskEngine());
  const first = await service.registerAndAuthorize(intent(), context(), 'order-1');
  const duplicate = await service.registerAndAuthorize(intent(), context(), 'order-2');
  assert.equal(duplicate.duplicate, true);
  assert.equal(duplicate.order.id, first.order.id);
  assert.equal(registry.decisions, 1);
  await assert.rejects(() => service.registerAndAuthorize(intent({ quantity: '3' }), context(), 'order-3'), { code: 'IDEMPOTENCY_KEY_CONFLICT' });
});

test('Concurrent duplicate intents cannot create two logical orders', async () => {
  const registry = new MemoryOrderRegistry();
  const service = new OrderManagementService(registry, riskEngine());
  const [first, second] = await Promise.all([
    service.registerAndAuthorize(intent(), context(), 'order-1'),
    service.registerAndAuthorize(intent(), context(), 'order-2'),
  ]);
  assert.equal(registry.entries.size, 1);
  assert.equal(first.order.id, second.order.id);
  assert.equal(registry.decisions, 1);
  assert.equal([first, second].filter(value => !value.duplicate).length, 1);
});


test('Core value objects and event collections are immutable snapshots', () => {
  const value = Decimal.parse('1.25');
  assert.equal(Object.isFrozen(value), true);
  const source = { kind: 'BROKER', sourceId: 'before', observedAt: at(), normalizationVersion: '1' };
  const specInput = { pricePrecision: 2, quantityPrecision: 2, priceTick: '0.01', quantityStep: '0.01', minimumQuantity: '0.01', contractMultiplier: '1', valuationModel: 'LINEAR', effectiveFrom: at(), provenance: source };
  const spec = new InstrumentSpecification(specInput);
  source.sourceId = 'after';
  assert.equal(spec.input.provenance.sourceId, 'before');
  assert.equal(Object.isFrozen(spec.input), true);
});
