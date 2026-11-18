import process, { env } from "node:process";
import { loadRuntimeConfig } from "./config/runtime-config.ts";
import { BrokerSessionManager } from "./market-data/broker-session-manager.ts";
import { CapitalDemoStreamingRuntime } from "./market-data/capital-demo-streaming-runtime.ts";
import { createApiServer } from "./server.ts";
import { readIPCStartupCapability } from "./security/ipc-capability.ts";

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

function shutdown(): void {
  if (shuttingDown) return;
  shuttingDown = true;
  ipcCapability.fill(0);

  void (async () => {
    try {
      await marketDataStreamRuntime.disconnect();
    } catch {
      // Shutdown must continue even if the provider stream is already degraded.
    }
    try {
      await brokerSessionManager.disconnect();
    } catch {
      // Never retain the child process solely because remote logout failed.
    }
    server.close((error) => {
      if (error) {
        console.error("ATHEER API shutdown failed.", error.message);
        return;
      }
      console.info("ATHEER API stopped.");
    });
    server.closeAllConnections();
  })();
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
