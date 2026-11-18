import {
  evaluateQuoteFreshness,
  normalizeCapitalQuote,
  type NormalizedQuote,
  type QuoteFreshnessResult,
} from "./contracts.ts";
import type { CapitalDemoStreamingConnectionInfo } from "./capital-demo-client.ts";

const MAX_INSTRUMENTS_PER_PROVIDER_SESSION = 40;
const REQUEST_TIMEOUT_MS = 10_000;
const SOCKET_CLOSE_TIMEOUT_MS = 2_000;
const HEARTBEAT_INTERVAL_MS = 5 * 60 * 1_000;
const INITIAL_RECONNECT_DELAY_MS = 1_000;
const MAX_RECONNECT_DELAY_MS = 30_000;
const QUOTE_FRESHNESS_THRESHOLDS = {
  normalAgeMs: 5_000,
  automatedEntryBlockAgeMs: 10_000,
  staleAgeMs: 15_000,
} as const;

const QUOTE_FRESHNESS_POLICY = {
  ...QUOTE_FRESHNESS_THRESHOLDS,
  maximumFutureSkewMs: 250,
} as const;

export type MarketDataStreamState = "disconnected" | "connecting" | "connected" | "degraded";

export interface MarketDataStreamQuoteFreshness extends QuoteFreshnessResult {
  readonly normalAgeMs: number;
  readonly automatedEntryBlockAgeMs: number;
  readonly staleAgeMs: number;
}

export interface MarketDataStreamQuote extends NormalizedQuote {
  readonly receivedAtMonotonicMs: number;
  readonly freshness: MarketDataStreamQuoteFreshness;
}

export interface MarketDataStreamStatus {
  readonly provider: "capital.com";
  readonly environment: "DEMO";
  readonly state: MarketDataStreamState;
  readonly activeInstrumentCount: number;
  readonly lastMessageAtMs?: number;
  readonly lastError?: string;
  readonly invalidQuoteCount: number;
  readonly outOfOrderQuoteCount: number;
  readonly duplicateQuoteCount: number;
}

interface StreamSubscription {
  readonly epics: ReadonlySet<string>;
  readonly listener: (quote: MarketDataStreamQuote) => void;
}

interface PendingRequest {
  readonly resolve: () => void;
  readonly reject: (error: Error) => void;
  readonly timeout: ReturnType<typeof setTimeout>;
}

type SessionInfoProvider = () => Promise<CapitalDemoStreamingConnectionInfo>;
type WebSocketFactory = (url: string) => WebSocket;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function safeErrorMessage(error: unknown): string {
  // Provider and transport errors are untrusted and may contain sensitive data.
  // Expose a stable diagnostic; detailed causes stay out of client-visible status.
  void error;
  return "Capital.com streaming connection failed.";
}

/**
 * Server-side DEMO-only Capital.com quote stream.
 *
 * Provider session tokens remain inside this service. Consumers receive only
 * normalized, validated quote events. No dealing or order API is exposed.
 */
export class CapitalDemoStreamingRuntime {
  private socket: WebSocket | null = null;
  private connectionInfo: CapitalDemoStreamingConnectionInfo | null = null;
  private connectionPromise: Promise<void> | null = null;
  private syncQueue: Promise<void> = Promise.resolve();
  private readonly subscriptions = new Map<number, StreamSubscription>();
  private readonly pendingRequests = new Map<string, PendingRequest>();
  private readonly subscribedEpics = new Set<string>();
  private readonly latestQuotes = new Map<string, MarketDataStreamQuote>();
  private readonly intentionallyClosing = new WeakSet<WebSocket>();
  private nextSubscriptionId = 0;
  private nextCorrelationId = 0;
  private generation = 0;
  private reconnectAttempt = 0;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private heartbeatTimer: ReturnType<typeof setInterval> | null = null;
  private state: MarketDataStreamState = "disconnected";
  private lastMessageAtMs: number | undefined;
  private lastError: string | undefined;
  private invalidQuoteCount = 0;
  private outOfOrderQuoteCount = 0;
  private duplicateQuoteCount = 0;

  constructor(
    private readonly getSessionInfo: SessionInfoProvider,
    private readonly socketFactory: WebSocketFactory = (url) => new WebSocket(url),
    private readonly now: () => number = Date.now,
    private readonly monotonicNow: () => number = () => performance.now(),
  ) {}

  status(): MarketDataStreamStatus {
    return {
      provider: "capital.com",
      environment: "DEMO",
      state: this.state,
      activeInstrumentCount: this.subscribedEpics.size,
      ...(this.lastMessageAtMs === undefined ? {} : { lastMessageAtMs: this.lastMessageAtMs }),
      ...(this.lastError === undefined ? {} : { lastError: this.lastError }),
      invalidQuoteCount: this.invalidQuoteCount,
      outOfOrderQuoteCount: this.outOfOrderQuoteCount,
      duplicateQuoteCount: this.duplicateQuoteCount,
    };
  }

  latest(epics: readonly string[]): MarketDataStreamQuote[] {
    const nowMs = this.now();
    return epics.flatMap((epic) => {
      const quote = this.latestQuotes.get(epic);
      if (!quote) return [];

      // A cached quote may be replayed long after its original receipt. Recompute
      // freshness from the provider timestamp at replay time; never replay the
      // original "fresh" authorization decision as if it were current.
      const freshness = evaluateQuoteFreshness(quote, nowMs, QUOTE_FRESHNESS_POLICY);
      return [{
        ...quote,
        freshness: {
          ...freshness,
          ...QUOTE_FRESHNESS_THRESHOLDS,
        },
      }];
    });
  }

  async subscribe(
    epics: readonly string[],
    listener: (quote: MarketDataStreamQuote) => void,
  ): Promise<() => void> {
    const normalized = [...new Set(epics.map((epic) => epic.trim()))];
    if (
      normalized.length === 0 ||
      normalized.length > MAX_INSTRUMENTS_PER_PROVIDER_SESSION ||
      normalized.some((epic) => !/^[A-Za-z0-9_.-]{1,64}$/.test(epic))
    ) {
      throw new Error("A stream subscription requires 1–40 valid Capital.com instrument epics.");
    }

    const id = ++this.nextSubscriptionId;
    this.subscriptions.set(id, { epics: new Set(normalized), listener });
    if (this.desiredEpics().size > MAX_INSTRUMENTS_PER_PROVIDER_SESSION) {
      this.subscriptions.delete(id);
      throw new Error("The shared Capital.com DEMO stream is limited to 40 active instruments.");
    }

    try {
      await this.ensureConnected();
      await this.syncSubscriptions();
    } catch (error) {
      this.subscriptions.delete(id);
      throw error;
    }

    let active = true;
    return () => {
      if (!active) return;
      active = false;
      void this.removeSubscription(id);
    };
  }

  async disconnect(): Promise<void> {
    this.generation += 1;
    this.subscriptions.clear();
    this.clearReconnectTimer();
    this.stopHeartbeat();
    this.rejectPendingRequests(new Error("Capital.com streaming runtime disconnected."));
    const socket = this.socket;
    this.socket = null;
    this.connectionInfo = null;
    this.subscribedEpics.clear();
    if (socket) {
      this.intentionallyClosing.add(socket);
      await new Promise<void>((resolve) => {
        let settled = false;
        const finish = () => {
          if (settled) return;
          settled = true;
          clearTimeout(timeout);
          socket.removeEventListener("close", finish);
          resolve();
        };
        const timeout = setTimeout(finish, SOCKET_CLOSE_TIMEOUT_MS);
        if (socket.readyState === WebSocket.CLOSED) {
          finish();
          return;
        }
        socket.addEventListener("close", finish, { once: true });
        try {
          socket.close(1000, "ATHEER streaming runtime disconnected");
        } catch {
          finish();
        }
      });
    }
    this.state = "disconnected";
    this.lastError = undefined;
  }

  private async removeSubscription(id: number): Promise<void> {
    this.subscriptions.delete(id);
    if (this.subscriptions.size === 0) {
      this.generation += 1;
      this.clearReconnectTimer();
      this.stopHeartbeat();
      const socket = this.socket;
      this.socket = null;
      this.connectionInfo = null;
      this.subscribedEpics.clear();
      if (socket) {
        this.intentionallyClosing.add(socket);
        socket.close(1000, "No active market-data subscribers");
      }
      this.state = "disconnected";
      return;
    }

    try {
      await this.syncSubscriptions();
    } catch (error) {
      this.lastError = safeErrorMessage(error);
      this.state = "degraded";
    }
  }

  private async ensureConnected(): Promise<void> {
    if (this.socket?.readyState === WebSocket.OPEN) return;
    if (this.connectionPromise) return this.connectionPromise;

    this.state = "connecting";
    this.lastError = undefined;
    const generation = this.generation;
    let createdSocket: WebSocket | null = null;
    this.connectionPromise = (async () => {
      const info = await this.getSessionInfo();
      if (generation !== this.generation) {
        throw new Error("Capital.com DEMO stream connection was superseded.");
      }
      let endpoint: URL;
      try {
        endpoint = new URL(info.streamEndpoint);
      } catch {
        throw new Error("Capital.com DEMO session returned an invalid stream endpoint.");
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
        throw new Error("Capital.com DEMO stream endpoint failed host validation.");
      }
      endpoint.pathname = "/connect";

      const socket = this.socketFactory(endpoint.toString());
      createdSocket = socket;
      this.socket = socket;
      this.connectionInfo = info;

      await new Promise<void>((resolve, reject) => {
        let settled = false;
        const timeout = setTimeout(() => {
          if (settled) return;
          settled = true;
          socket.close(1000, "Capital.com stream connection timed out");
          reject(new Error("Capital.com DEMO WebSocket connection timed out."));
        }, REQUEST_TIMEOUT_MS);

        socket.addEventListener("open", () => {
          if (settled) return;
          settled = true;
          clearTimeout(timeout);
          if (generation !== this.generation) {
            this.intentionallyClosing.add(socket);
            socket.close(1000, "Superseded stream connection");
            reject(new Error("Capital.com DEMO stream connection was superseded."));
            return;
          }
          this.state = "connected";
          this.lastError = undefined;
          this.reconnectAttempt = 0;
          this.startHeartbeat();
          resolve();
        }, { once: true });

        socket.addEventListener("error", () => {
          if (!settled) {
            settled = true;
            clearTimeout(timeout);
            reject(new Error("Capital.com DEMO WebSocket connection failed."));
          }
        }, { once: true });

        socket.addEventListener("close", () => {
          if (!settled) {
            settled = true;
            clearTimeout(timeout);
            reject(new Error("Capital.com DEMO WebSocket closed before connecting."));
          }
          this.handleSocketClosed(socket);
        });

        socket.addEventListener("message", (event) => this.handleMessage(event.data));
      });
    })()
      .catch((error: unknown) => {
        if (generation === this.generation) {
          this.state = "degraded";
          this.lastError = safeErrorMessage(error);
        }
        const socket = createdSocket;
        if (socket && this.socket === socket) {
          this.socket = null;
          this.connectionInfo = null;
          this.intentionallyClosing.add(socket);
          socket.close();
        }
        throw error;
      })
      .finally(() => {
        this.connectionPromise = null;
      });

    return this.connectionPromise;
  }

  private syncSubscriptions(): Promise<void> {
    const operation = this.syncQueue
      .catch(() => undefined)
      .then(() => this.performSubscriptionSync());
    this.syncQueue = operation;
    return operation;
  }

  private async performSubscriptionSync(): Promise<void> {
    const desired = this.desiredEpics();
    const toSubscribe = [...desired].filter((epic) => !this.subscribedEpics.has(epic));
    const toUnsubscribe = [...this.subscribedEpics].filter((epic) => !desired.has(epic));

    if (toSubscribe.length > 0) {
      await this.sendRequest("marketData.subscribe", { epics: toSubscribe });
      for (const epic of toSubscribe) this.subscribedEpics.add(epic);
    }
    if (toUnsubscribe.length > 0) {
      await this.sendRequest("marketData.unsubscribe", { epics: toUnsubscribe });
      for (const epic of toUnsubscribe) this.subscribedEpics.delete(epic);
    }
  }

  private sendRequest(destination: string, payload?: Readonly<Record<string, unknown>>): Promise<void> {
    const socket = this.socket;
    const info = this.connectionInfo;
    if (!socket || socket.readyState !== WebSocket.OPEN || !info) {
      return Promise.reject(new Error("Capital.com DEMO WebSocket is not connected."));
    }

    const correlationId = String(++this.nextCorrelationId);
    const message = {
      destination,
      correlationId,
      cst: info.cst,
      securityToken: info.securityToken,
      ...(payload === undefined ? {} : { payload }),
    };

    return new Promise<void>((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.pendingRequests.delete(correlationId);
        reject(new Error("Capital.com DEMO streaming request timed out."));
      }, REQUEST_TIMEOUT_MS);
      this.pendingRequests.set(correlationId, { resolve, reject, timeout });
      try {
        socket.send(JSON.stringify(message));
      } catch {
        clearTimeout(timeout);
        this.pendingRequests.delete(correlationId);
        reject(new Error("Capital.com DEMO streaming request could not be sent."));
      }
    });
  }

  private handleMessage(rawData: unknown): void {
    let message: unknown;
    try {
      message = JSON.parse(typeof rawData === "string" ? rawData : String(rawData));
    } catch {
      return;
    }
    if (!isRecord(message)) return;

    if (typeof message.correlationId === "string") {
      const pending = this.pendingRequests.get(message.correlationId);
      if (pending) {
        clearTimeout(pending.timeout);
        this.pendingRequests.delete(message.correlationId);
        if (message.status === "OK") pending.resolve();
        else pending.reject(new Error("Capital.com rejected a streaming subscription request."));
      }
    }

    if (message.destination !== "quote" || !isRecord(message.payload)) return;
    const receivedAtMs = this.now();
    let normalized: NormalizedQuote;
    try {
      normalized = normalizeCapitalQuote(message.payload, receivedAtMs);
    } catch {
      this.invalidQuoteCount += 1;
      return;
    }

    const previous = this.latestQuotes.get(normalized.instrumentId);
    if (previous && normalized.providerTimestampMs < previous.providerTimestampMs) {
      this.outOfOrderQuoteCount += 1;
      return;
    }
    if (
      previous &&
      normalized.providerTimestampMs === previous.providerTimestampMs &&
      normalized.bid === previous.bid &&
      normalized.ask === previous.ask
    ) {
      this.duplicateQuoteCount += 1;
      return;
    }

    const quote: MarketDataStreamQuote = {
      ...normalized,
      receivedAtMonotonicMs: this.monotonicNow(),
      freshness: {
        ...evaluateQuoteFreshness(normalized, receivedAtMs, QUOTE_FRESHNESS_POLICY),
        ...QUOTE_FRESHNESS_THRESHOLDS,
      },
    };
    this.latestQuotes.set(quote.instrumentId, quote);
    this.lastMessageAtMs = receivedAtMs;

    for (const subscription of this.subscriptions.values()) {
      if (subscription.epics.has(quote.instrumentId)) subscription.listener(quote);
    }
  }

  private handleSocketClosed(socket: WebSocket): void {
    if (this.intentionallyClosing.has(socket) || this.socket !== socket) return;
    this.socket = null;
    this.connectionInfo = null;
    this.subscribedEpics.clear();
    this.stopHeartbeat();
    this.rejectPendingRequests(new Error("Capital.com DEMO WebSocket connection was interrupted."));
    this.state = "degraded";
    this.lastError = "Capital.com DEMO WebSocket connection was interrupted.";
    this.scheduleReconnect();
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer || this.subscriptions.size === 0) return;
    const delay = Math.min(
      INITIAL_RECONNECT_DELAY_MS * (2 ** this.reconnectAttempt),
      MAX_RECONNECT_DELAY_MS,
    );
    this.reconnectAttempt += 1;
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      void this.ensureConnected()
        .then(() => this.syncSubscriptions())
        .catch((error: unknown) => {
          this.lastError = safeErrorMessage(error);
          this.state = "degraded";
          this.scheduleReconnect();
        });
    }, delay);
  }

  private startHeartbeat(): void {
    this.stopHeartbeat();
    this.heartbeatTimer = setInterval(() => {
      void this.sendRequest("ping").catch((error: unknown) => {
        this.lastError = safeErrorMessage(error);
        this.socket?.close();
      });
    }, HEARTBEAT_INTERVAL_MS);
  }

  private stopHeartbeat(): void {
    if (this.heartbeatTimer) clearInterval(this.heartbeatTimer);
    this.heartbeatTimer = null;
  }

  private clearReconnectTimer(): void {
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    this.reconnectTimer = null;
  }

  private rejectPendingRequests(error: Error): void {
    for (const pending of this.pendingRequests.values()) {
      clearTimeout(pending.timeout);
      pending.reject(error);
    }
    this.pendingRequests.clear();
  }

  private desiredEpics(): Set<string> {
    const epics = new Set<string>();
    for (const subscription of this.subscriptions.values()) {
      for (const epic of subscription.epics) epics.add(epic);
    }
    return epics;
  }
}
