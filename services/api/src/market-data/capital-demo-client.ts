const CAPITAL_DEMO_BASE_URL = "https://demo-api-capital.backend-capital.com/api/v1";
const REQUEST_TIMEOUT_MS = 10_000;

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
  readonly bid?: number;
  readonly offer?: number;
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
  constructor(
    private readonly fetcher: FetchLike = fetch,
    private readonly now: () => number = Date.now,
  ) {}

  async startSession(credentials: CapitalDemoCredentials): Promise<CapitalDemoSession> {
    this.validateCredentials(credentials);
    const response = await this.fetcher(`${CAPITAL_DEMO_BASE_URL}/session`, {
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
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
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
      endpoint.hostname !== "api-streaming-capital.backend-capital.com"
    ) {
      throw new Error("Capital.com DEMO session returned an untrusted streaming endpoint.");
    }

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
    if (!isRecord(payload) || !Array.isArray(payload.markets) || !payload.markets.every(isCapitalMarket)) {
      throw new Error("Capital.com returned an invalid market search response.");
    }
    return { markets: payload.markets };
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
    const response = await this.fetcher(`${CAPITAL_DEMO_BASE_URL}/session`, {
      method: "DELETE",
      headers: this.sessionHeaders(session),
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    });
    await this.assertSuccessful(response, "session termination");
  }

  private async authorizedGet(
    session: CapitalDemoSession,
    path: string,
  ): Promise<Response> {
    this.validateSession(session);
    const response = await this.fetcher(`${CAPITAL_DEMO_BASE_URL}${path}`, {
      method: "GET",
      headers: this.sessionHeaders(session),
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
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

function isCapitalMarket(value: unknown): value is CapitalMarket {
  if (!isRecord(value)) return false;
  return typeof value.epic === "string" && value.epic.length > 0;
}
