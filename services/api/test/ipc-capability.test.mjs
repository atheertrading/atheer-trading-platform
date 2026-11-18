import assert from "node:assert/strict";
import { test } from "node:test";
import { readIPCStartupCapability } from "../dist/security/ipc-capability.js";

async function* chunks(...values) {
  for (const value of values) yield Buffer.from(value);
}

test("private stdin bootstrap accepts one canonical 256-bit base64url capability", async () => {
  const expected = Buffer.alloc(32, 19);
  const encoded = expected.toString("base64url");
  const capability = await readIPCStartupCapability(chunks(encoded.slice(0, 17), encoded.slice(17) + "\n"));
  assert.deepEqual(capability, expected);
  capability.fill(0);
  expected.fill(0);
});

test("private stdin bootstrap rejects an unterminated capability", async () => {
  await assert.rejects(
    readIPCStartupCapability(chunks(Buffer.alloc(32, 1).toString("base64url"))),
    /ended before its delimiter/,
  );
});

test("private stdin bootstrap rejects malformed and non-256-bit values", async () => {
  await assert.rejects(readIPCStartupCapability(chunks("not-a-capability\n")), /256-bit base64url/);
  await assert.rejects(readIPCStartupCapability(chunks(Buffer.alloc(16, 1).toString("base64url") + "\n")), /256-bit base64url/);
});

test("private stdin bootstrap enforces a strict input size limit", async () => {
  await assert.rejects(readIPCStartupCapability(chunks("x".repeat(129) + "\n")), /size limit/);
});
