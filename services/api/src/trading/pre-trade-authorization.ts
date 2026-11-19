import {
  DomainValidationError,
  type OrderIntentId,
  type TradingEnvironment,
} from "../domain/shared.ts";
import {
  createOrderIntentEnvelope,
  createRiskAssessment,
  type OrderIntentEnvelope,
  type RiskAssessment,
} from "../domain/trading.ts";

/**
 * Port implemented by the deterministic, provider-independent RiskEngine.
 * The coordinator does not own policy, valuation, limits, or risk formulas.
 */
export interface RiskAssessmentEvaluator {
  evaluate(intent: OrderIntentEnvelope): Promise<RiskAssessment>;
}

/**
 * Durable journal port. Implementations must commit the intent, assessment,
 * audit record, and domain outbox notifications atomically.
 */
export interface PreTradeDecisionJournal {
  persistIntentAndRiskAssessment(
    intent: OrderIntentEnvelope,
    assessment: RiskAssessment,
  ): Promise<PreTradePersistenceReceipt>;
}

export interface PreTradePersistenceReceipt {
  readonly intentInserted: boolean;
  readonly riskAssessmentInserted: boolean;
  readonly replayed: boolean;
}

export interface PersistedPreTradeDecision {
  readonly kind: "PRE_TRADE_DECISION_PERSISTED";
  readonly intentId: OrderIntentId;
  readonly environment: TradingEnvironment;
  readonly riskOutcome: RiskAssessment["outcome"];
  readonly assessment: RiskAssessment;
  readonly persistence: PreTradePersistenceReceipt;
}

/**
 * Orchestrates the common manual / strategy / algorithm / AI order-intent
 * boundary. A decision is returned only after its intent and assessment are
 * durably journaled. This service does not create OMS orders or dispatch
 * broker commands; those remain separate, explicitly qualified boundaries.
 */
export class PreTradeAuthorizationService {
  constructor(
    private readonly riskEvaluator: RiskAssessmentEvaluator,
    private readonly journal: PreTradeDecisionJournal,
  ) {
    if (typeof riskEvaluator?.evaluate !== "function") {
      throw new TypeError("A RiskAssessmentEvaluator is required.");
    }
    if (typeof journal?.persistIntentAndRiskAssessment !== "function") {
      throw new TypeError("A PreTradeDecisionJournal is required.");
    }
  }

  async evaluateAndPersist(
    input: OrderIntentEnvelope,
  ): Promise<PersistedPreTradeDecision> {
    // Validate and freeze the untrusted application-boundary input before
    // passing it to the risk authority.
    const intent = createOrderIntentEnvelope(input);

    // Risk evaluation must fail closed. If the evaluator throws, no result is
    // returned and no persistence or OMS operation is attempted.
    const assessment = createRiskAssessment(
      await this.riskEvaluator.evaluate(intent),
    );

    if (assessment.intentId !== intent.id) {
      throw new DomainValidationError(
        "risk_intent_mismatch",
        "Risk assessment does not reference the submitted order intent.",
      );
    }

    if (assessment.provenance.environment !== intent.environment) {
      throw new DomainValidationError(
        "risk_environment_mismatch",
        "Risk assessment environment does not match the submitted order intent.",
      );
    }

    // Persist AUTHORIZED, REJECTED, and HELD decisions alike. An assessment
    // that is not durably recorded must never be returned as a completed
    // pre-trade decision.
    const receipt = await this.journal.persistIntentAndRiskAssessment(
      intent,
      assessment,
    );

    return Object.freeze({
      kind: "PRE_TRADE_DECISION_PERSISTED" as const,
      intentId: intent.id,
      environment: intent.environment,
      riskOutcome: assessment.outcome,
      assessment,
      persistence: Object.freeze({ ...receipt }),
    });
  }
}
