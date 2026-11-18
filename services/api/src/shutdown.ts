export type ShutdownOperation = "credential_ipc_server" | "market_data_stream" | "broker_session" | "http_server";
export type ShutdownStepOutcome = "succeeded" | "failed" | "timed_out";

/**
 * Runs one shutdown action within a strict observation deadline.
 *
 * JavaScript promises are not cancellable. A timeout therefore does not claim
 * that the underlying operation stopped. The caller must not begin a dependent
 * teardown step after "timed_out"; the process hard deadline remains armed and
 * is responsible for terminating the process if the operation never settles.
 *
 * Diagnostics intentionally expose only the operation and outcome. Provider
 * errors may contain account or session details and must never be logged raw.
 */
export async function runBoundedShutdownStep(
  operation: ShutdownOperation,
  action: () => Promise<unknown>,
  timeoutMs: number,
  log: (message: string) => void,
): Promise<ShutdownStepOutcome> {
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
    return "succeeded";
  } catch {
    log(`ATHEER API shutdown ${operation} ${timedOut ? "timed_out" : "failed"}.`);
    return timedOut ? "timed_out" : "failed";
  } finally {
    if (timer !== undefined) clearTimeout(timer);
  }
}
