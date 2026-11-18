import { CapitalDemoClient, type CapitalDemoCredentials } from "./capital-demo-client.ts";
import { CapitalDemoRuntime } from "./capital-demo-runtime.ts";

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

  constructor(
    private readonly runtimeFactory: RuntimeFactory = (credentials) =>
      new CapitalDemoRuntime(new CapitalDemoClient(), credentials),
    private readonly now: () => number = Date.now,
    private readonly sessionCreationIntervalMs = 10_000,
  ) {}

  status(): BrokerSessionStatus {
    return this.runtime?.status() ?? {
      provider: "capital.com",
      environment: "DEMO",
      state: "not_configured",
    };
  }

  async connect(credentials?: CapitalDemoCredentials): Promise<BrokerSessionStatus> {
    if (credentials) {
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
          lastError: `Capital.com DEMO session creation is rate-limited. Retry in ${Math.ceil(remainingMs / 1_000)} seconds.`,
        };
      }
      if (this.runtime) await this.disconnect();
      this.lastSessionCreationAttemptAtMs = now;
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

    const status = await runtime.disconnect();
    this.runtime = null;
    return { ...status, state: "disconnected" };
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
