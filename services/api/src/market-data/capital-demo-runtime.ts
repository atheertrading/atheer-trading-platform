import {
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

    this.connectionState = "connecting";
    this.lastError = undefined;
    this.connecting = this.client.startSession(this.credentials)
      .then((session) => {
        this.session = session;
        this.connectedAtMs = this.now();
        this.connectionState = "connected";
        return this.status();
      })
      .catch((error: unknown) => {
        this.session = null;
        this.connectedAtMs = undefined;
        this.connectionState = "error";
        this.lastError = error instanceof Error ? error.message : "Provider connection failed.";
        throw new Error(this.lastError);
      })
      .finally(() => {
        this.connecting = null;
      });
    return this.connecting;
  }

  async disconnect(): Promise<CapitalDemoRuntimeStatus> {
    const current = this.session;
    this.session = null;
    this.connectedAtMs = undefined;
    this.connectionState = this.credentials ? "disconnected" : "not_configured";
    this.lastError = undefined;
    if (current) await this.client.endSession(current);
    return this.status();
  }

  async getMarkets(searchTerm: string): Promise<CapitalMarketSearchResult> {
    return this.client.getMarkets(this.requireSession(), searchTerm);
  }

  async getPriceHistory(
    epic: string,
    resolution: "MINUTE" | "MINUTE_5" | "MINUTE_15" | "MINUTE_30" | "HOUR" | "HOUR_4" | "DAY" | "WEEK",
    max: number,
  ): Promise<CapitalPriceHistoryResult> {
    return this.client.getPriceHistory(this.requireSession(), epic, resolution, max);
  }

  async ping(): Promise<CapitalDemoRuntimeStatus> {
    const current = this.requireSession();
    try {
      await this.client.ping(current);
      return this.status();
    } catch {
      this.session = null;
      this.connectedAtMs = undefined;
      this.connectionState = "disconnected";
      this.lastError = "Capital.com DEMO session is no longer available.";
      return this.status();
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
