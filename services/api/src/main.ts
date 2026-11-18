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
  console.info("ATHEER API listening on http://" + config.host + ":" + config.port);
});

function shutdown(): void {
  if (shuttingDown) return;
  shuttingDown = true;
  void marketDataRuntime.disconnect().catch(() => undefined);
  server.close((error) => {
    if (error) {
      console.error("ATHEER API shutdown failed.", error.message);
      return;
    }
    ipcCapability.fill(0);
    console.info("ATHEER API stopped.");
  });
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
