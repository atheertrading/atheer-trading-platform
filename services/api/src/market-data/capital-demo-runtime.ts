import {
  CapitalDemoApiError,
  CapitalDemoClient,
  type CapitalDemoCredentials,
  type CapitalDemoSession,
  type CapitalMarketSearchResult,
  type CapitalPriceHistoryResult,
} from "./capital-demo-client.ts";

const DEFAULT_SESSION_CREATION_INTERVAL_MS = 1_000;
const DEFAULT_KEEPALIVE_INTERVAL_MS = 5 * 60 * 1_000;

export interface CapitalDemoRuntimeStatus {
  readonly provider: "capital.com";
  readonly environment: "DEMO";
  readonly state: "not_configured" | "disconnected" | "connecting" | "connected" | "degraded" | "error";
  readonly connectedAtMs?: number;
  readonly lastError?: string;
}

export interface CapitalDemoRuntimeScheduler {
  schedule(task: () => Promise<void>, intervalMs: number): unknown;
  cancel(handle: unknown): void;
}

export interface CapitalDemoRuntimeTiming {
  readonly sessionCreationIntervalMs?: number;
  readonly keepaliveIntervalMs?: number;
  readonly sleep?: (milliseconds: number) => Promise<void>;
  readonly scheduler?: CapitalDemoRuntimeScheduler;
}

const defaultScheduler: CapitalDemoRuntimeScheduler = {
  schedule: (task, intervalMs) => setInterval(() => { void task(); }, intervalMs),
  cancel: (handle) => clearInterval(handle as number),
};

function sleep(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

export class CapitalDemoRuntime {
  private session: CapitalDemoSession | null = null;
  private connectionState: CapitalDemoRuntimeStatus["state"];
  private connectedAtMs: number | undefined;
  private lastError: string | undefined;
  private connecting: Promise<CapitalDemoRuntimeStatus> | null = null;
  private keepaliveInFlight: Promise<void> | null = null;
  private keepaliveHandle: unknown = null;
  private lastSessionCreationAttemptAtMs: number | null = null;
  private generation = 0;
  private readonly sessionCreationIntervalMs: number;
  private readonly keepaliveIntervalMs: number;
  private readonly sleep: (milliseconds: number) => Promise<void>;
  private readonly scheduler: CapitalDemoRuntimeScheduler;

  constructor(
    private readonly client: CapitalDemoClient,
    private readonly credentials: CapitalDemoCredentials | null,
    private readonly now: () => number = Date.now,
    timing: CapitalDemoRuntimeTiming = {},
  ) {
    this.connectionState = credentials ? "disconnected" : "not_configured";
    const sessionCreationIntervalMs = timing.sessionCreationIntervalMs ?? DEFAULT_SESSION_CREATION_INTERVAL_MS;
    const keepaliveIntervalMs = timing.keepaliveIntervalMs ?? DEFAULT_KEEPALIVE_INTERVAL_MS;
    if (!Number.isSafeInteger(sessionCreationIntervalMs) || sessionCreationIntervalMs < 1_000) {
      throw new Error("Capital.com session creation must be throttled to at least one second.");
    }
    if (!Number.isSafeInteger(keepaliveIntervalMs) || keepaliveIntervalMs <= 0 || keepaliveIntervalMs >= 10 * 60 * 1_000) {
      throw new Error("Capital.com REST keepalive must run before the ten-minute inactivity limit.");
    }
    this.sessionCreationIntervalMs = sessionCreationIntervalMs;
    this.keepaliveIntervalMs = keepaliveIntervalMs;
    this.sleep = timing.sleep ?? sleep;
    this.scheduler = timing.scheduler ?? defaultScheduler;
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
    if (this.session && this.connectionState === "connected") return this.status();
    if (this.session && this.connectionState === "degraded") {
      await this.runKeepalive().catch(() => undefined);
      return this.status();
    }
    if (!this.credentials) return this.status();
    if (this.connecting) return this.connecting;

    const generation = this.generation;
    this.connectionState = "connecting";
    this.lastError = undefined;
    const credentials = this.credentials;
    this.connecting = (async () => {
      await this.waitForSessionCreationSlot();
      if (generation !== this.generation) return this.status();

      this.lastSessionCreationAttemptAtMs = this.now();
      const session = await this.client.startSession(credentials);
      if (generation !== this.generation) {
        await this.client.endSession(session).catch(() => undefined);
        return this.status();
      }

      this.session = session;
      this.connectedAtMs = this.now();
      this.connectionState = "connected";
      this.lastError = undefined;
      this.startKeepalive();
      return this.status();
    })()
      .catch((error: unknown) => {
        if (generation === this.generation) {
          this.stopKeepalive();
          this.session = null;
          this.connectedAtMs = undefined;
          this.connectionState = "error";
          this.lastError = this.safeErrorMessage(error, "session creation");
        }
        throw new Error(this.safeErrorMessage(error, "session creation"));
      })
      .finally(() => {
        this.connecting = null;
      });
    return this.connecting;
  }

  async disconnect(): Promise<CapitalDemoRuntimeStatus> {
    this.generation += 1;
    this.stopKeepalive();

    const pendingConnection = this.connecting;
    if (pendingConnection) await pendingConnection.catch(() => undefined);
    const pendingKeepalive = this.keepaliveInFlight;
    if (pendingKeepalive) await pendingKeepalive.catch(() => undefined);

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
    resolution: "MINUTE" | "MINUTE_5" | "MINUTE_15" | "MINUTE_30" | "HOUR" | "HOUR_4" | "DAY" | "WEEK",
    max: number,
  ): Promise<CapitalPriceHistoryResult> {
    return this.withSession((session) => this.client.getPriceHistory(session, epic, resolution, max));
  }

  async ping(): Promise<CapitalDemoRuntimeStatus> {
    await this.runKeepalive();
    return this.status();
  }

  private async waitForSessionCreationSlot(): Promise<void> {
    const lastAttempt = this.lastSessionCreationAttemptAtMs;
    if (lastAttempt !== null) {
      const elapsed = this.now() - lastAttempt;
      const remaining = this.sessionCreationIntervalMs - elapsed;
      if (remaining > 0) await this.sleep(remaining);
    }
  }

  private startKeepalive(): void {
    if (this.keepaliveHandle !== null || !this.session) return;
    this.keepaliveHandle = this.scheduler.schedule(
      async () => {
        // A scheduled keepalive updates runtime health internally. Contain its
        // rejection here so timer-driven failures never become unhandled promises.
        await this.runKeepalive().catch(() => undefined);
      },
      this.keepaliveIntervalMs,
    );
  }

  private stopKeepalive(): void {
    if (this.keepaliveHandle === null) return;
    this.scheduler.cancel(this.keepaliveHandle);
    this.keepaliveHandle = null;
  }

  private async runKeepalive(): Promise<void> {
    if (this.keepaliveInFlight) return this.keepaliveInFlight;
    const session = this.session;
    if (!session || this.connectionState === "disconnected" || this.connectionState === "not_configured") {
      return;
    }

    this.keepaliveInFlight = this.client.ping(session)
      .then(() => {
        if (this.session === session) {
          this.connectionState = "connected";
          this.lastError = undefined;
        }
      })
      .catch((error: unknown) => {
        this.handleSessionFailure(session, error);
        throw error;
      })
      .finally(() => {
        this.keepaliveInFlight = null;
      });
    return this.keepaliveInFlight;
  }

  private async withSession<T>(
    operation: (session: CapitalDemoSession) => Promise<T>,
  ): Promise<T> {
    const session = this.requireSession();
    try {
      const result = await operation(session);
      if (this.session === session && this.connectionState === "degraded") {
        this.connectionState = "connected";
        this.lastError = undefined;
      }
      return result;
    } catch (error) {
      this.handleSessionFailure(session, error);
      throw error;
    }
  }

  private handleSessionFailure(session: CapitalDemoSession, error: unknown): void {
    if (this.session !== session) return;

    if (!(error instanceof CapitalDemoApiError) || (error.statusCode !== 401 && error.statusCode !== 403)) {
      this.connectionState = "degraded";
      this.lastError = error instanceof CapitalDemoApiError
        ? `Capital.com DEMO session health is degraded (HTTP ${error.statusCode}).`
        : "Capital.com DEMO session connectivity is unconfirmed.";
      return;
    }

    this.stopKeepalive();
    this.session = null;
    this.connectedAtMs = undefined;
    this.connectionState = "disconnected";
    this.lastError = "Capital.com DEMO session was rejected or expired.";
  }

  private requireSession(): CapitalDemoSession {
    if (!this.session || this.connectionState !== "connected") {
      throw new Error("Capital.com DEMO is not connected.");
    }
    return this.session;
  }

  private safeErrorMessage(error: unknown, operation: string): string {
    if (error instanceof CapitalDemoApiError) {
      return `Capital.com DEMO ${operation} failed with HTTP ${error.statusCode}.`;
    }
    return `Capital.com DEMO ${operation} failed.`;
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
