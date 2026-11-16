export interface ApiRuntimeConfig {
  readonly host: "127.0.0.1";
  readonly port: number;
}

const DEFAULT_PORT = 4100;
const LOOPBACK_HOST = "127.0.0.1" as const;

export function loadRuntimeConfig(
  environment: Readonly<Record<string, string | undefined>>,
): ApiRuntimeConfig {
  const rawPort = environment.PORT ?? String(DEFAULT_PORT);
  if (!/^\d+$/.test(rawPort)) {
    throw new Error("PORT must be an integer between 1 and 65535.");
  }
  const port = Number(rawPort);
  if (!Number.isSafeInteger(port) || port < 1 || port > 65_535) {
    throw new Error("PORT must be an integer between 1 and 65535.");
  }
  const host = environment.HOST ?? LOOPBACK_HOST;
  if (host !== LOOPBACK_HOST) {
    throw new Error("HOST is restricted to 127.0.0.1 for the local development service.");
  }
  return { host: LOOPBACK_HOST, port };
}
