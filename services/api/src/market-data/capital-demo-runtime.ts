import type { HistoricalPriceResolution } from "./historical-prices.ts";
import {
  CapitalDemoApiError,
  CapitalDemoClient,
  type CapitalDemoCredentials,
  type CapitalDemoSession,
  type CapitalMarketSearchResult,
  type CapitalPriceHistoryResult,
} from "./capital-demo-client.ts";

export interface CapitalDemoRuntimeStatus {
  readonly provider: "capital.com";
  readonly environment: "DEMO";
  readonly state: "not_configured" | "disconnected" | "connecting" | "connected" | "error";
  readonly connectedAtMs?: number;
  readonly lastError?: string;
}

export class CapitalDemoRuntime {
  private session: CapitalDemoSession | null = null;
  private connectionState: CapitalDemoRuntimeStatus["state"];
  private connectedAtMs: number | undefined;
  private lastError: string | undefined;
  private connecting: Promise<CapitalDemoRuntimeStatus> | null = null;
  private generation = 0;

  constructor(
    private readonly client: CapitalDemoClient,
    private readonly credentials: CapitalDemoCredentials | null,
    private readonly now: () => number = Date.now,
  ) {
    this.connectionState = credentials ? "disconnected" : "not_configured";
  }

  status(): CapitalDemoRuntimeStatus {
    return {
      provider: "capital.com",
      environment: "DEMO",
      state: this.connectionState,
      ...(this.connectedAtMs === undefined ? {} : { connectedAtMs: this.connectedAtMs }),
      ...(this.lastError === undefined ? {} : { lastError: this.lastError }),
    };
  }

  async connect(): Promise<CapitalDemoRuntimeStatus> {
    if (this.session) return this.status();
    if (!this.credentials) return this.status();
    if (this.connecting) return this.connecting;

    const generation = this.generation;
    this.connectionState = "connecting";
    this.lastError = undefined;
    this.connecting = this.client.startSession(this.credentials)
      .then(async (session) => {
        if (generation !== this.generation) {
          await this.client.endSession(session).catch(() => undefined);
          return this.status();
        }
        this.session = session;
        this.connectedAtMs = this.now();
        this.connectionState = "connected";
        return this.status();
      })
      .catch((error: unknown) => {
        if (generation === this.generation) {
          this.session = null;
          this.connectedAtMs = undefined;
          this.connectionState = "error";
          this.lastError = error instanceof Error ? error.message : "Provider connection failed.";
        }
        throw new Error(error instanceof Error ? error.message : "Provider connection failed.");
      })
      .finally(() => {
        this.connecting = null;
      });
    return this.connecting;
  }

  async disconnect(): Promise<CapitalDemoRuntimeStatus> {
    this.generation += 1;
    const pendingConnection = this.connecting;
    if (pendingConnection) await pendingConnection.catch(() => undefined);

    const current = this.session;
    this.session = null;
    this.connectedAtMs = undefined;
    this.connectionState = this.credentials ? "disconnected" : "not_configured";
    this.lastError = undefined;
    if (current) await this.client.endSession(current);
    return this.status();
  }

  async getStreamingConnectionInfo() {
    return this.withSession((session) => this.client.getStreamingConnectionInfo(session));
  }

  async getMarkets(searchTerm: string): Promise<CapitalMarketSearchResult> {
    return this.withSession((session) => this.client.getMarkets(session, searchTerm));
  }

  async getPriceHistory(
    epic: string,
    resolution: HistoricalPriceResolution,
    max: number,
    from?: string,
    to?: string,
  ): Promise<CapitalPriceHistoryResult> {
    return this.withSession((session) => this.client.getPriceHistory(session, epic, resolution, max, from, to));
  }

  async ping(): Promise<CapitalDemoRuntimeStatus> {
    await this.withSession((session) => this.client.ping(session));
    return this.status();
  }

  private async withSession<T>(
    operation: (session: CapitalDemoSession) => Promise<T>,
  ): Promise<T> {
    const session = this.requireSession();
    try {
      return await operation(session);
    } catch (error) {
      const shouldInvalidate = !(error instanceof CapitalDemoApiError) ||
        error.statusCode === 401 ||
        error.statusCode === 403;
      if (shouldInvalidate && this.session === session) {
        this.session = null;
        this.connectedAtMs = undefined;
        this.connectionState = error instanceof CapitalDemoApiError ? "disconnected" : "error";
        this.lastError = error instanceof CapitalDemoApiError
          ? "Capital.com DEMO session was rejected or expired."
          : "Capital.com DEMO connection is unavailable.";
      }
      throw error;
    }
  }

  private requireSession(): CapitalDemoSession {
    if (!this.session || this.connectionState !== "connected") {
      throw new Error("Capital.com DEMO is not connected.");
    }
    return this.session;
  }
}

export function createCapitalDemoRuntime(
  environment: Readonly<Record<string, string | undefined>>,
  client: CapitalDemoClient = new CapitalDemoClient(),
): CapitalDemoRuntime {
  const apiKey = environment.CAPITAL_COM_DEMO_API_KEY?.trim() ?? "";
  const identifier = environment.CAPITAL_COM_DEMO_IDENTIFIER?.trim() ?? "";
  const password = environment.CAPITAL_COM_DEMO_PASSWORD ?? "";
  const credentials = apiKey && identifier && password
    ? { apiKey, identifier, password }
    : null;
  return new CapitalDemoRuntime(client, credentials);
}
