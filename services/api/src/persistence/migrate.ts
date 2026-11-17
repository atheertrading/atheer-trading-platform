import { env, exitCode } from "node:process";
import { createPostgresPool, runSqlMigrations } from "./postgres.ts";

const databaseUrl = env.DATABASE_URL;
if (databaseUrl === undefined || databaseUrl.trim().length === 0) {
  console.error("DATABASE_URL is required for the explicit migration command.");
  process.exitCode = 1;
} else {
  const pool = createPostgresPool(databaseUrl);
  try {
    await runSqlMigrations(pool);
    console.info("ATHEER PostgreSQL migrations applied and checksummed.");
  } catch {
    console.error("ATHEER PostgreSQL migration failed; database details were redacted.");
    process.exitCode = 1;
  } finally {
    await pool.end().catch(() => undefined);
  }
}

void exitCode;
