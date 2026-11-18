import process, { env } from "node:process";
import { loadRuntimeConfig } from "./config/runtime-config.ts";
import { createCapitalDemoRuntime } from "./market-data/capital-demo-runtime.ts";
import { createPostgresPool, verifySqlMigrations, type SqlPool } from "./persistence/postgres.ts";
import { createApiServer, type PersistenceReadiness } from "./server.ts";

const config = loadRuntimeConfig(env);
const marketDataRuntime = createCapitalDemoRuntime(env);

let databasePool: SqlPool | undefined;
let persistenceReadiness: PersistenceReadiness = "not_configured";
let shuttingDown = false;

async function start(): Promise<void> {
  const databaseUrl = env.DATABASE_URL;
  if (databaseUrl !== undefined && databaseUrl.trim().length > 0) {
    databasePool = createPostgresPool(databaseUrl);
    try {
      await verifySqlMigrations(databasePool);
      await databasePool.query("SELECT 1");
      persistenceReadiness = "ready";
    } catch {
      await databasePool.end().catch(() => undefined);
      databasePool = undefined;
      persistenceReadiness = "unavailable";
      throw new Error("PostgreSQL persistence initialization failed; connection details were redacted.");
    }
  }

  const server = createApiServer(marketDataRuntime, () => persistenceReadiness);
  server.listen(config.port, config.host, () => {
    console.info("ATHEER API listening on http://" + config.host + ":" + config.port);
  });

  function shutdown(): void {
    if (shuttingDown) return;
    shuttingDown = true;
    void marketDataRuntime.disconnect().catch(() => undefined);
    server.close((error) => {
      if (error) {
        console.error("ATHEER API shutdown failed.");
      } else {
        console.info("ATHEER API stopped.");
      }
      void databasePool?.end().catch(() => undefined);
    });
    server.closeAllConnections();
  }

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

void start().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : "ATHEER API startup failed.");
  process.exitCode = 1;
});
