import { timingSafeEqual } from "node:crypto";
import type { IncomingMessage } from "node:http";

const CAPABILITY_BYTES = 32;
const MAX_BOOTSTRAP_BYTES = 128;

/**
 * Reads one base64url-encoded 256-bit capability from the process' private
 * stdin pipe. The parent must close the pipe after writing the newline.
 * No environment variable or command-line argument is used for the secret.
 */
export async function readIPCStartupCapability(
  input: AsyncIterable<Uint8Array>,
): Promise<Buffer> {
  const chunks: Buffer[] = [];
  let totalBytes = 0;
  let complete = false;

  for await (const chunk of input) {
    const bytes = Buffer.from(chunk);
    const newlineIndex = bytes.indexOf(0x0a);
    const payload = newlineIndex >= 0 ? bytes.subarray(0, newlineIndex) : bytes;
    totalBytes += payload.length;
    if (totalBytes > MAX_BOOTSTRAP_BYTES) {
      throw new Error("IPC startup capability bootstrap exceeded its size limit.");
    }
    chunks.push(payload);
    if (newlineIndex >= 0) {
      complete = true;
      break;
    }
  }

  if (!complete) {
    throw new Error("IPC startup capability bootstrap ended before its delimiter.");
  }

  const encoded = Buffer.concat(chunks).toString("ascii").trim();
  if (!/^[A-Za-z0-9_-]{43}$/.test(encoded)) {
    throw new Error("IPC startup capability must be a 256-bit base64url value.");
  }
  const capability = Buffer.from(encoded, "base64url");
  if (capability.length !== CAPABILITY_BYTES || capability.toString("base64url") !== encoded) {
    capability.fill(0);
    throw new Error("IPC startup capability has an invalid encoding.");
  }
  return capability;
}

/** Constant-time comparison for the private app-to-backend bearer capability. */
export function hasValidIPCCapability(
  request: IncomingMessage,
  expectedCapability: Uint8Array | undefined,
): boolean {
  if (!expectedCapability || expectedCapability.byteLength !== CAPABILITY_BYTES) return false;
  const authorization = request.headers.authorization;
  if (typeof authorization !== "string" || !authorization.startsWith("Bearer ")) return false;

  const supplied = authorization.slice("Bearer ".length);
  if (!/^[A-Za-z0-9_-]{43}$/.test(supplied)) return false;

  const candidate = Buffer.from(supplied, "base64url");
  if (candidate.length !== CAPABILITY_BYTES) {
    candidate.fill(0);
    return false;
  }
  const expected = Buffer.from(expectedCapability);
  const valid = timingSafeEqual(candidate, expected);
  candidate.fill(0);
  expected.fill(0);
  return valid;
}
