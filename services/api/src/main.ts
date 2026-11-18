import process, { env } from "node:process";
import { loadRuntimeConfig } from "./config/runtime-config.ts";
import { BrokerSessionManager } from "./market-data/broker-session-manager.ts";
import { CapitalDemoStreamingRuntime } from "./market-data/capital-demo-streaming-runtime.ts";
import { createApiServer } from "./server.ts";
import { readIPCStartupCapability } from "./security/ipc-capability.ts";
import { createBrokerCredentialIPCServer } from "./security/broker-credential-ipc.ts";
import { runBoundedShutdownStep } from "./shutdown.ts";

const config = loadRuntimeConfig(env);
const brokerSessionManager = new BrokerSessionManager();
const marketDataStreamRuntime = new CapitalDemoStreamingRuntime(async () => {
  const status = await brokerSessionManager.connect();
  if (status.state !== "connected") {
    throw new Error("Capital.com DEMO session is not connected.");
  }
  return brokerSessionManager.getStreamingConnectionInfo();
});
const ipcCapability = await readIPCStartupCapability(process.stdin);
const credentialSocketPath = env.ATHEER_CREDENTIAL_SOCKET_PATH;
if (!credentialSocketPath) {
  ipcCapability.fill(0);
  throw new Error("The private broker credential IPC socket path is not configured.");
}
const credentialIPCServer = await createBrokerCredentialIPCServer({
  socketPath: credentialSocketPath,
  expectedCapability: ipcCapability,
  manager: brokerSessionManager,
  beforeSessionReplacement: async () => marketDataStreamRuntime.disconnect(),
});
const server = createApiServer(brokerSessionManager, ipcCapability, marketDataStreamRuntime);
let shuttingDown = false;

server.listen(config.port, config.host, () => {
  const address = server.address();
  if (!address || typeof address === "string") {
    console.error("ATHEER API could not determine its bound loopback port.");
    process.exitCode = 1;
    return;
  }

  // The native process supervisor consumes this non-secret readiness marker.
  // Port 0 requests an OS-assigned port and avoids fixed-port collisions.
  process.stdout.write(`ATHEER_BACKEND_READY ${address.port}\n`);
});

// Sequential budgets total 17s, leaving a 3s margin before the 20s
// process hard deadline. A timed-out action aborts all later teardown steps.
const SHUTDOWN_CREDENTIAL_IPC_TIMEOUT_MS = 2_000;
const SHUTDOWN_STREAM_TIMEOUT_MS = 3_000;
const SHUTDOWN_BROKER_TIMEOUT_MS = 11_000;
const SHUTDOWN_HTTP_TIMEOUT_MS = 1_000;
const SHUTDOWN_HARD_DEADLINE_MS = 20_000;

function shutdown(): void {
  if (shuttingDown) return;
  shuttingDown = true;
  ipcCapability.fill(0);

  // Stop accepting IPC immediately. Active requests and SSE streams are closed
  // before provider resources are released.
  const credentialIPCClosed = credentialIPCServer.close();
  const serverClosed = new Promise<void>((resolve, reject) => {
    server.close((error) => error ? reject(error) : resolve());
  });
  server.closeAllConnections();

  const hardDeadline = setTimeout(() => {
    console.error("ATHEER API shutdown exceeded its hard deadline; forcing termination.");
    process.exit(1);
  }, SHUTDOWN_HARD_DEADLINE_MS);

  void (async () => {
    let shutdownFailed = false;

    const credentialIPCOutcome = await runBoundedShutdownStep(
      "credential_ipc_server",
      () => credentialIPCClosed,
      SHUTDOWN_CREDENTIAL_IPC_TIMEOUT_MS,
      (message) => console.error(message),
    );
    if (credentialIPCOutcome === "timed_out") {
      process.exitCode = 1;
      console.error("ATHEER API shutdown stopped after the credential IPC drain deadline.");
      return;
    }
    if (credentialIPCOutcome === "failed") shutdownFailed = true;

    const streamOutcome = await runBoundedShutdownStep(
      "market_data_stream",
      () => marketDataStreamRuntime.disconnect(),
      SHUTDOWN_STREAM_TIMEOUT_MS,
      (message) => console.error(message),
    );
    if (streamOutcome === "timed_out") {
      process.exitCode = 1;
      console.error("ATHEER API shutdown stopped after the market-data stream deadline.");
      return;
    }
    if (streamOutcome === "failed") shutdownFailed = true;

    const brokerOutcome = await runBoundedShutdownStep(
      "broker_session",
      () => brokerSessionManager.disconnect(),
      SHUTDOWN_BROKER_TIMEOUT_MS,
      (message) => console.error(message),
    );
    if (brokerOutcome === "timed_out") {
      process.exitCode = 1;
      console.error("ATHEER API shutdown stopped after the broker-session deadline.");
      return;
    }
    if (brokerOutcome === "failed") shutdownFailed = true;

    const httpOutcome = await runBoundedShutdownStep(
      "http_server",
      () => serverClosed,
      SHUTDOWN_HTTP_TIMEOUT_MS,
      (message) => console.error(message),
    );
    if (httpOutcome === "timed_out") {
      process.exitCode = 1;
      console.error("ATHEER API shutdown stopped after the HTTP server deadline.");
      return;
    }
    if (httpOutcome === "failed") shutdownFailed = true;

    clearTimeout(hardDeadline);
    if (shutdownFailed) {
      process.exit(1);
    } else {
      console.info("ATHEER API stopped.");
    }
  })().catch(() => {
    console.error("ATHEER API shutdown failed.");
    process.exitCode = 1;
    server.closeAllConnections();
    // Keep the hard deadline armed when teardown cannot be confirmed.
  });
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
