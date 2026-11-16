import process, { env } from "node:process";
import { loadRuntimeConfig } from "./config/runtime-config.ts";
import { createApiServer } from "./server.ts";

const config = loadRuntimeConfig(env);
const server = createApiServer();
let shuttingDown = false;

server.listen(config.port, config.host, () => {
  console.info("ATHEER API listening on http://" + config.host + ":" + config.port);
});

function shutdown(): void {
  if (shuttingDown) return;
  shuttingDown = true;
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
