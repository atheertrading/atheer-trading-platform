export type ShutdownOperation = "market_data_stream" | "broker_session" | "http_server";

/**
 * Runs one shutdown action within a strict deadline.
 *
 * Diagnostics intentionally expose only the operation and outcome. Provider
 * errors may contain account or session details and must never be logged raw.
 */
export async function runBoundedShutdownStep(
  operation: ShutdownOperation,
  action: () => Promise<unknown>,
  timeoutMs: number,
  log: (message: string) => void,
): Promise<boolean> {
  if (!Number.isSafeInteger(timeoutMs) || timeoutMs <= 0) {
    throw new RangeError("Shutdown timeout must be a positive safe integer.");
  }

  let timer: ReturnType<typeof setTimeout> | undefined;
  let timedOut = false;
  const deadline = new Promise<never>((_, reject) => {
    timer = setTimeout(() => {
      timedOut = true;
      reject(new Error("shutdown_timeout"));
    }, timeoutMs);
  });

  try {
    await Promise.race([Promise.resolve().then(action), deadline]);
    return true;
  } catch {
    log(`ATHEER API shutdown ${operation} ${timedOut ? "timed_out" : "failed"}.`);
    return false;
  } finally {
    if (timer !== undefined) clearTimeout(timer);
  }
}
