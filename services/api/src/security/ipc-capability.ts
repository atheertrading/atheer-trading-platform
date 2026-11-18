import { timingSafeEqual } from "node:crypto";
import type { IncomingMessage } from "node:http";

const CAPABILITY_BYTES = 32;
const MAX_BOOTSTRAP_BYTES = 128;

function decodeBase64Url(value: string): Uint8Array {
  const base64 = value.replace(/-/g, "+").replace(/_/g, "/") + "=";
  const binary = atob(base64);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function encodeBase64Url(value: Uint8Array): string {
  const binary = Array.from(value, (byte) => String.fromCharCode(byte)).join("");
  return btoa(binary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

/**
 * Reads one base64url-encoded 256-bit capability from the process' private
 * stdin pipe. The parent must close the pipe after writing the newline.
 * No environment variable or command-line argument is used for the secret.
 */
export async function readIPCStartupCapability(
  input: AsyncIterable<Uint8Array>,
): Promise<Uint8Array> {
  const chunks: Uint8Array[] = [];
  let totalBytes = 0;
  let complete = false;

  for await (const chunk of input) {
    const newlineIndex = chunk.indexOf(0x0a);
    const payload = newlineIndex >= 0 ? chunk.subarray(0, newlineIndex) : chunk;
    totalBytes += payload.length;
    if (totalBytes > MAX_BOOTSTRAP_BYTES) {
      throw new Error("IPC startup capability bootstrap exceeded its size limit.");
    }
    chunks.push(payload.slice());
    if (newlineIndex >= 0) {
      complete = true;
      break;
    }
  }

  if (!complete) {
    throw new Error("IPC startup capability bootstrap ended before its delimiter.");
  }

  const combined = new Uint8Array(totalBytes);
  let offset = 0;
  for (const chunk of chunks) {
    combined.set(chunk, offset);
    offset += chunk.length;
    chunk.fill(0);
  }
  const encoded = new TextDecoder("ascii").decode(combined).trim();
  combined.fill(0);

  if (!/^[A-Za-z0-9_-]{43}$/.test(encoded)) {
    throw new Error("IPC startup capability must be a 256-bit base64url value.");
  }
  const capability = decodeBase64Url(encoded);
  if (capability.length !== CAPABILITY_BYTES || encodeBase64Url(capability) !== encoded) {
    capability.fill(0);
    throw new Error("IPC startup capability has an invalid encoding.");
  }
  return capability;
}

/** Constant-time comparison for a supplied base64url capability value. */
export function hasValidIPCCapabilityValue(
  supplied: string | undefined,
  expectedCapability: Uint8Array | undefined,
): boolean {
  if (!expectedCapability || expectedCapability.byteLength !== CAPABILITY_BYTES) return false;
  if (typeof supplied !== "string" || !/^[A-Za-z0-9_-]{43}$/.test(supplied)) return false;

  let candidate: Uint8Array;
  try {
    candidate = decodeBase64Url(supplied);
  } catch {
    return false;
  }
  if (candidate.length !== CAPABILITY_BYTES) {
    candidate.fill(0);
    return false;
  }
  const expected = Uint8Array.from(expectedCapability);
  const valid = timingSafeEqual(candidate, expected);
  candidate.fill(0);
  expected.fill(0);
  return valid;
}

/** Constant-time comparison for the private app-to-backend bearer capability. */
export function hasValidIPCCapability(
  request: IncomingMessage,
  expectedCapability: Uint8Array | undefined,
): boolean {
  const authorization = request.headers.authorization;
  if (typeof authorization !== "string" || !authorization.startsWith("Bearer ")) return false;
  return hasValidIPCCapabilityValue(
    authorization.slice("Bearer ".length),
    expectedCapability,
  );
}
