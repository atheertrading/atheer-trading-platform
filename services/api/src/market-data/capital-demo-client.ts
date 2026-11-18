const CAPITAL_DEMO_BASE_URL = "https://demo-api-capital.backend-capital.com/api/v1";
const REQUEST_TIMEOUT_MS = 10_000;
const MAX_RATE_LIMIT_RETRIES = 3;
const INITIAL_RATE_LIMIT_BACKOFF_MS = 500;
const MAX_RATE_LIMIT_BACKOFF_MS = 10_000;
const MAX_RETRY_AFTER_MS = 60_000;

export interface CapitalDemoCredentials {
  readonly apiKey: string;
  readonly identifier: string;
  readonly password: string;
}

export interface CapitalDemoSession {
  readonly cst: string;
  readonly securityToken: string;
  readonly createdAtMs: number;
  readonly environment: "DEMO";
}

export interface CapitalMarket {
  readonly epic: string;
  readonly instrumentName?: string;
  readonly marketStatus?: string;
  readonly currency?: string;
}

export interface CapitalMarketSearchResult {
  readonly markets: readonly CapitalMarket[];
}

export interface CapitalDemoStreamingConnectionInfo {
  readonly streamEndpoint: string;
  readonly cst: string;
  readonly securityToken: string;
}


export interface CapitalPriceHistoryResult {
  readonly prices: readonly Readonly<Record<string, unknown>>[];
}

export type FetchLike = (
  input: string | URL,
  init?: RequestInit,
) => Promise<Response>;

export interface CapitalDemoClientOptions {
  readonly requestIntervalMs?: number;
  readonly monotonicNow?: () => number;
  readonly sleep?: (milliseconds: number) => Promise<void>;
  readonly random?: () => number;
}


function parseRetryAfterMilliseconds(value: string | null, nowMs: number): number | undefined {
  if (value === null) return undefined;
  const normalized = value.trim();
  if (normalized.length === 0) return undefined;

  let delayMs: number;
  if (/^\d+(?:\.\d+)?$/.test(normalized)) {
    delayMs = Number(normalized) * 1_000;
  } else {
    const retryAtMs = Date.parse(normalized);
    if (!Number.isFinite(retryAtMs)) return undefined;
    delayMs = retryAtMs - nowMs;
  }

  if (!Number.isFinite(delayMs) || delayMs < 0) return undefined;
  return Math.min(MAX_RETRY_AFTER_MS, Math.ceil(delayMs));
}

export class CapitalDemoApiError extends Error {
  constructor(
    message: string,
    readonly statusCode: number,
  ) {
    super(message);
    this.name = "CapitalDemoApiError";
  }
}

/**
 * DEMO-only, read-only API adapter.
 *
 * This adapter intentionally has no order, position-dealing, account mutation,
 * or LIVE endpoint methods. Credentials and session tokens remain server-side.
 */
export class CapitalDemoClient {
  private requestQueue: Promise<void> = Promise.resolve();
  private lastRequestStartedAtMs = 0;
  private hasStartedRequest = false;
  private readonly requestIntervalMs: number;
  private readonly monotonicNow: () => number;
  private readonly sleep: (milliseconds: number) => Promise<void>;
  private readonly random: () => number;
  private rateLimitBlockedUntilMs = 0;

  constructor(
    private readonly fetcher: FetchLike = fetch,
    private readonly now: () => number = Date.now,
    options: CapitalDemoClientOptions = {},
  ) {
    this.requestIntervalMs = options.requestIntervalMs ?? 100;
    this.monotonicNow = options.monotonicNow ?? (() => performance.now());
    this.sleep = options.sleep ?? ((milliseconds) =>
      new Promise((resolve) => setTimeout(resolve, milliseconds)));
    this.random = options.random ?? Math.random;
  }

  async startSession(credentials: CapitalDemoCredentials): Promise<CapitalDemoSession> {
    this.validateCredentials(credentials);
    const response = await this.fetchWithRateLimit(`${CAPITAL_DEMO_BASE_URL}/session`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "X-CAP-API-KEY": credentials.apiKey,
      },
      body: JSON.stringify({
        identifier: credentials.identifier,
        password: credentials.password,
        encryptedPassword: false,
      }),
    });
    await this.assertSuccessful(response, "session creation");

    const cst = response.headers.get("CST");
    const securityToken = response.headers.get("X-SECURITY-TOKEN");
    if (!cst || !securityToken) {
      throw new Error("Capital.com DEMO session response omitted required session headers.");
    }
    return {
      cst,
      securityToken,
      createdAtMs: this.now(),
      environment: "DEMO",
    };
  }

  async getStreamingConnectionInfo(
    session: CapitalDemoSession,
  ): Promise<CapitalDemoStreamingConnectionInfo> {
    const response = await this.authorizedGet(session, "/session");
    const payload: unknown = await response.json();
    if (!isRecord(payload) || typeof payload.streamEndpoint !== "string") {
      throw new Error("Capital.com DEMO session response omitted the streaming endpoint.");
    }

    let endpoint: URL;
    try {
      endpoint = new URL(payload.streamEndpoint);
    } catch {
      throw new Error("Capital.com DEMO session returned an invalid streaming endpoint.");
    }
    if (
      endpoint.protocol !== "wss:" ||
      endpoint.hostname !== "api-streaming-capital.backend-capital.com" ||
      endpoint.port !== "" ||
      endpoint.username.length > 0 ||
      endpoint.password.length > 0 ||
      endpoint.search.length > 0 ||
      endpoint.hash.length > 0 ||
      (endpoint.pathname !== "/" && endpoint.pathname !== "/connect")
    ) {
      throw new Error("Capital.com DEMO session returned an untrusted streaming endpoint.");
    }

    // GET /session documents the host root, while the WebSocket contract
    // requires the /connect path. Normalize only the two official forms.
    endpoint.pathname = "/connect";

    return {
      streamEndpoint: endpoint.toString(),
      cst: session.cst,
      securityToken: session.securityToken,
    };
  }

  async getMarkets(
    session: CapitalDemoSession,
    searchTerm: string,
  ): Promise<CapitalMarketSearchResult> {
    const normalizedSearch = searchTerm.trim();
    if (normalizedSearch.length === 0 || normalizedSearch.length > 100) {
      throw new Error("Market search term must contain between 1 and 100 characters.");
    }
    const query = new URLSearchParams({ searchTerm: normalizedSearch });
    const response = await this.authorizedGet(session, `/markets?${query.toString()}`);
    const payload: unknown = await response.json();
    if (!isRecord(payload) || !Array.isArray(payload.markets)) {
      throw new Error("Capital.com returned an invalid market search response.");
    }
    const markets: CapitalMarket[] = [];
    for (const value of payload.markets) {
      const market = normalizeCapitalMarket(value);
      if (!market) {
        throw new Error("Capital.com returned an invalid market search response.");
      }
      markets.push(market);
    }
    return { markets };
  }

  async getPriceHistory(
    session: CapitalDemoSession,
    epic: string,
    resolution: "MINUTE" | "MINUTE_5" | "MINUTE_15" | "MINUTE_30" | "HOUR" | "HOUR_4" | "DAY" | "WEEK",
    max: number,
  ): Promise<CapitalPriceHistoryResult> {
    const normalizedEpic = epic.trim();
    if (!/^[A-Za-z0-9_.-]{1,64}$/.test(normalizedEpic)) {
      throw new Error("Capital.com epic is invalid.");
    }
    if (!Number.isSafeInteger(max) || max < 1 || max > 1000) {
      throw new Error("Price history max must be an integer between 1 and 1000.");
    }
    const query = new URLSearchParams({ resolution, max: String(max) });
    const response = await this.authorizedGet(
      session,
      `/prices/${encodeURIComponent(normalizedEpic)}?${query.toString()}`,
    );
    const payload: unknown = await response.json();
    if (!isRecord(payload) || !Array.isArray(payload.prices) || !payload.prices.every(isRecord)) {
      throw new Error("Capital.com returned an invalid price history response.");
    }
    return { prices: payload.prices };
  }

  async ping(session: CapitalDemoSession): Promise<void> {
    const response = await this.authorizedGet(session, "/ping");
    await response.body?.cancel();
  }

  async endSession(session: CapitalDemoSession): Promise<void> {
    this.validateSession(session);
    const response = await this.fetchWithRateLimit(`${CAPITAL_DEMO_BASE_URL}/session`, {
      method: "DELETE",
      headers: this.sessionHeaders(session),
    });
    await this.assertSuccessful(response, "session termination");
  }

  private async fetchWithRateLimit(
    input: string | URL,
    init?: RequestInit,
  ): Promise<Response> {
    let retryAttempt = 0;

    while (true) {
      const previous = this.requestQueue;
      let release!: () => void;
      this.requestQueue = new Promise<void>((resolve) => { release = resolve; });
      await previous;

      try {
        // One shared queue enforces both the provider request-start budget and
        // a Retry-After cooldown observed by any request in this process.
        while (true) {
          const now = this.monotonicNow();
          const spacingWait = this.hasStartedRequest
            ? Math.max(0, this.requestIntervalMs - (now - this.lastRequestStartedAtMs))
            : 0;
          const cooldownWait = Math.max(0, this.rateLimitBlockedUntilMs - now);
          const wait = Math.max(spacingWait, cooldownWait);
          if (wait <= 0) break;
          await this.sleep(wait);
        }

        this.lastRequestStartedAtMs = this.monotonicNow();
        this.hasStartedRequest = true;
      } finally {
        release();
      }

      // The 10s timeout applies to each network attempt, not to the provider's
      // server-directed rate-limit delay preceding a retry.
      const response = await this.fetcher(input, {
        ...init,
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      });

      if (response.status !== 429 || retryAttempt >= MAX_RATE_LIMIT_RETRIES) {
        return response;
      }

      const retryAfterMs = parseRetryAfterMilliseconds(
        response.headers.get("Retry-After"),
        this.now(),
      );
      const exponentialCapMs = Math.min(
        INITIAL_RATE_LIMIT_BACKOFF_MS * (2 ** retryAttempt),
        MAX_RATE_LIMIT_BACKOFF_MS,
      );
      const sample = this.random();
      const boundedSample = Number.isFinite(sample)
        ? Math.min(1, Math.max(0, sample))
        : 0.5;
      const jitterDelayMs = Math.max(1, Math.floor(boundedSample * exponentialCapMs));
      const delayMs = retryAfterMs ?? jitterDelayMs;

      this.rateLimitBlockedUntilMs = Math.max(
        this.rateLimitBlockedUntilMs,
        this.monotonicNow() + delayMs,
      );
      retryAttempt += 1;
      await response.body?.cancel();
    }
  }

  private async authorizedGet(
    session: CapitalDemoSession,
    path: string,
  ): Promise<Response> {
    this.validateSession(session);
    const response = await this.fetchWithRateLimit(`${CAPITAL_DEMO_BASE_URL}${path}`, {
      method: "GET",
      headers: this.sessionHeaders(session),
    });
    await this.assertSuccessful(response, path);
    return response;
  }

  private sessionHeaders(session: CapitalDemoSession): HeadersInit {
    return {
      CST: session.cst,
      "X-SECURITY-TOKEN": session.securityToken,
    };
  }

  private validateCredentials(credentials: CapitalDemoCredentials): void {
    if (
      !credentials.apiKey.trim() ||
      !credentials.identifier.trim() ||
      !credentials.password
    ) {
      throw new Error("Capital.com DEMO credentials are incomplete.");
    }
  }

  private validateSession(session: CapitalDemoSession): void {
    if (
      session.environment !== "DEMO" ||
      !session.cst ||
      !session.securityToken ||
      !Number.isSafeInteger(session.createdAtMs) ||
      session.createdAtMs <= 0
    ) {
      throw new Error("A valid Capital.com DEMO session is required.");
    }
  }

  private async assertSuccessful(response: Response, operation: string): Promise<void> {
    if (response.ok) return;
    await response.body?.cancel();
    throw new CapitalDemoApiError(
      `Capital.com DEMO ${operation} failed with HTTP ${response.status}.`,
      response.status,
    );
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function normalizeCapitalMarket(value: unknown): CapitalMarket | null {
  if (!isRecord(value) || typeof value.epic !== "string" || value.epic.trim().length === 0) {
    return null;
  }
  return {
    epic: value.epic,
    ...(typeof value.instrumentName === "string" ? { instrumentName: value.instrumentName } : {}),
    ...(typeof value.marketStatus === "string" ? { marketStatus: value.marketStatus } : {}),
    ...(typeof value.currency === "string" ? { currency: value.currency } : {}),
  };
}
