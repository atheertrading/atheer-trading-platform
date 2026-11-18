import process, { env } from "node:process";
import { loadRuntimeConfig } from "./config/runtime-config.ts";
import { createCapitalDemoRuntime } from "./market-data/capital-demo-runtime.ts";
import { createApiServer } from "./server.ts";
import { readIPCStartupCapability } from "./security/ipc-capability.ts";

const config = loadRuntimeConfig(env);
const marketDataRuntime = createCapitalDemoRuntime(env);
const ipcCapability = await readIPCStartupCapability(process.stdin);
const server = createApiServer(marketDataRuntime, ipcCapability);
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
  void marketDataRuntime.disconnect().catch(() => undefined);
  server.close((error) => {
    if (error) {
      console.error("ATHEER API shutdown failed.", error.message);
      return;
    }
    console.info("ATHEER API stopped.");
  });
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
