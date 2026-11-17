import process, { env } from "node:process";
import { loadRuntimeConfig } from "./config/runtime-config.ts";
import { createCapitalDemoRuntime } from "./market-data/capital-demo-runtime.ts";
import { CapitalDemoStreamingRuntime } from "./market-data/capital-demo-streaming-runtime.ts";
import { createApiServer } from "./server.ts";

const config = loadRuntimeConfig(env);
const marketDataRuntime = createCapitalDemoRuntime(env);
const marketDataStreamRuntime = new CapitalDemoStreamingRuntime(async () => {
  if (marketDataRuntime.status().state !== "connected") {
    const status = await marketDataRuntime.connect();
    if (status.state !== "connected") {
      throw new Error("Capital.com DEMO session is not connected.");
    }
  }
  return marketDataRuntime.getStreamingConnectionInfo();
});
const server = createApiServer(marketDataRuntime, marketDataStreamRuntime);
let shuttingDown = false;

server.listen(config.port, config.host, () => {
  console.info("ATHEER API listening on http://" + config.host + ":" + config.port);
});

function shutdown(): void {
  if (shuttingDown) return;
  shuttingDown = true;
  void (async () => {
    await marketDataStreamRuntime.disconnect();
    await marketDataRuntime.disconnect().catch(() => undefined);
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
