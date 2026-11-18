import { CapitalDemoClient, type CapitalDemoCredentials } from "./capital-demo-client.ts";
import { CapitalDemoRuntime } from "./capital-demo-runtime.ts";

const DEFAULT_SESSION_CREATION_INTERVAL_MS = 1_000;

export type BrokerSessionStatus = ReturnType<CapitalDemoRuntime["status"]>;
type RuntimeFactory = (credentials: CapitalDemoCredentials) => CapitalDemoRuntime;

/**
 * The single backend owner for Capital.com DEMO session credentials, REST
 * session tokens, keepalive and streaming connection information.
 *
 * Credentials are held only by the current runtime instance. Disconnect drops
 * that instance so credentials and session tokens are no longer retained.
 */
export class BrokerSessionManager {
  private runtime: CapitalDemoRuntime | null = null;
  private lastSessionCreationAttemptAtMs: number | null = null;
  // One REST client per backend process keeps the provider's 10 req/s budget
  // intact across broker-session replacement and runtime recreation.
  private readonly sharedClient: CapitalDemoClient;
  private readonly runtimeFactory: RuntimeFactory;

  constructor(
    runtimeFactory?: RuntimeFactory,
    private readonly now: () => number = Date.now,
    private readonly sessionCreationIntervalMs = DEFAULT_SESSION_CREATION_INTERVAL_MS,
    sharedClient: CapitalDemoClient = new CapitalDemoClient(),
  ) {
    this.sharedClient = sharedClient;
    this.runtimeFactory = runtimeFactory ?? ((credentials) =>
      new CapitalDemoRuntime(this.sharedClient, credentials));
  }

  status(): BrokerSessionStatus {
    return this.runtime?.status() ?? {
      provider: "capital.com",
      environment: "DEMO",
      state: "not_configured",
    };
  }

  async connect(
    credentials?: CapitalDemoCredentials,
    beforeSessionReplacement?: () => Promise<void>,
  ): Promise<BrokerSessionStatus> {
    if (credentials) {
      // Reuse the current session for identical credentials. This preserves
      // keepalive/recovery state and prevents resetting provider-auth lockout.
      if (this.runtime?.usesCredentials(credentials)) {
        try {
          return await this.runtime.connect();
        } catch {
          return this.runtime.status();
        }
      }

      const now = this.now();
      if (
        this.lastSessionCreationAttemptAtMs !== null &&
        now - this.lastSessionCreationAttemptAtMs < this.sessionCreationIntervalMs
      ) {
        const remainingMs = this.sessionCreationIntervalMs -
          (now - this.lastSessionCreationAttemptAtMs);
        return {
          ...this.status(),
          state: "error",
          lastError: `Capital.com DEMO session creation is rate-limited. Retry in ${Math.ceil(remainingMs / 1_000)} second${Math.ceil(remainingMs / 1_000) === 1 ? "" : "s"}.`,
        };
      }
      this.lastSessionCreationAttemptAtMs = now;
      if (this.runtime) {
        await beforeSessionReplacement?.();
        await this.disconnect();
      }
      this.runtime = this.runtimeFactory({
        apiKey: credentials.apiKey,
        identifier: credentials.identifier,
        password: credentials.password,
      });
    }

    if (!this.runtime) return this.status();

    try {
      return await this.runtime.connect();
    } catch {
      // CapitalDemoRuntime retains only a sanitized status error.
      return this.runtime.status();
    }
  }

  async disconnect(): Promise<BrokerSessionStatus> {
    const runtime = this.runtime;
    if (!runtime) return this.status();

    try {
      const status = await runtime.disconnect();
      return { ...status, state: "disconnected" };
    } finally {
      // Drop the credential-bearing runtime even when provider logout fails.
      // The caller still receives the logout failure and must not report success.
      this.runtime = null;
    }
  }

  async getMarkets(searchTerm: string) {
    return this.requireRuntime().getMarkets(searchTerm);
  }

  async getPriceHistory(
    epic: string,
    resolution: "MINUTE" | "MINUTE_5" | "MINUTE_15" | "MINUTE_30" | "HOUR" | "HOUR_4" | "DAY" | "WEEK",
    max: number,
  ) {
    return this.requireRuntime().getPriceHistory(epic, resolution, max);
  }

  async ping(): Promise<void> {
    await this.requireRuntime().ping();
  }

  getStreamingConnectionInfo() {
    return this.requireRuntime().getStreamingConnectionInfo();
  }

  private requireRuntime(): CapitalDemoRuntime {
    if (!this.runtime) {
      throw new Error("broker_session_not_configured");
    }
    return this.runtime;
  }
}
