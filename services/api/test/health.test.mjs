import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import { loadRuntimeConfig } from "../dist/config/runtime-config.js";
import { createApiServer } from "../dist/server.js";

const server = createApiServer(undefined, undefined);
let baseUrl;

before(async () => {
  await new Promise((resolve, reject) => {
    const onError = (error) => reject(error);
    server.once("error", onError);
    server.listen(0, "127.0.0.1", () => {
      server.off("error", onError);
      resolve();
    });
  });
  const address = server.address();
  assert.ok(address && typeof address !== "string");
  baseUrl = "http://127.0.0.1:" + address.port;
});

after(async () => {
  await new Promise((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
});

test("liveness endpoint reports only process health", async () => {
  const response = await fetch(baseUrl + "/health/live");
  const payload = await response.json();
  assert.equal(response.status, 200);
  assert.equal(payload.status, "ok");
  assert.equal(payload.service, "atheer-api");
  assert.equal(typeof payload.timestamp, "string");
});

test("readiness fails closed while persistence and broker adapters are absent", async () => {
  const response = await fetch(baseUrl + "/health/ready");
  const payload = await response.json();
  assert.equal(response.status, 503);
  assert.equal(payload.status, "not_ready");
  assert.equal(payload.dependencies.persistence, "not_configured");
  assert.equal(payload.dependencies.broker, "not_configured");
  assert.equal(payload.trading.enabled, false);
  assert.equal(payload.trading.status, "disabled");
});

test("health routes reject non-GET methods", async () => {
  const response = await fetch(baseUrl + "/health/live", { method: "POST" });
  assert.equal(response.status, 405);
  assert.equal(response.headers.get("allow"), "GET");
});

test("unknown routes return 404", async () => {
  const response = await fetch(baseUrl + "/orders");
  assert.equal(response.status, 404);
});

test("runtime configuration defaults to loopback and a non-privileged port", () => {
  assert.deepEqual(loadRuntimeConfig({}), { host: "127.0.0.1", port: 4100 });
});

test("runtime configuration permits an OS-assigned ephemeral port", () => {
  assert.deepEqual(loadRuntimeConfig({ PORT: "0" }), { host: "127.0.0.1", port: 0 });
});

test("runtime configuration rejects invalid ports and non-loopback hosts", () => {
  assert.throws(() => loadRuntimeConfig({ PORT: "-1" }), /PORT must be an integer/);
  assert.throws(() => loadRuntimeConfig({ PORT: "70000" }), /PORT must be an integer/);
  assert.throws(() => loadRuntimeConfig({ PORT: "invalid" }), /PORT must be an integer/);
  assert.throws(() => loadRuntimeConfig({ HOST: "0.0.0.0" }), /restricted to 127.0.0.1/);
});
