import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";

const contract = await readFile(new URL("../openapi.yaml", import.meta.url), "utf8");

function sectionBetween(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  assert.notEqual(start, -1, "missing section marker: " + startMarker);
  const end = source.indexOf(endMarker, start + startMarker.length);
  assert.notEqual(end, -1, "missing section end marker: " + endMarker);
  return source.slice(start, end);
}

test("OpenAPI contract is one 3.1 document for implemented local routes only", () => {
  for (const rootKey of ["openapi: 3.1.0", "info:", "servers:", "tags:", "paths:", "components:"]) {
    assert.equal(
      contract.split("\n").filter((line) => line === rootKey).length,
      1,
      "expected exactly one root " + rootKey,
    );
  }

  const paths = sectionBetween(contract, "paths:\n", "components:\n");
  const declaredPaths = [...paths.matchAll(/^  (\/[^:]+):$/gm)].map((match) => match[1]);
  assert.deepEqual(declaredPaths, [
    "/health/live",
    "/health/ready",
    "/broker-session/status",
    "/market-data/status",
    "/market-data/markets",
    "/market-data/history",
    "/market-data/stream",
  ]);

  assert.doesNotMatch(paths, /^  \/(orders|positions|dealing|executions|broker-session\/connect|broker-session\/disconnect):/m);
  assert.match(contract, /url: http:\/\/127\.0\.0\.1:4100/);
  assert.match(contract, /private, permission-restricted Unix-domain socket/);
  assert.match(contract, /CAP_ALLOW_TRADING=false|trading permission/);
});

test("broker-sensitive operations require the local capability and native request context", () => {
  for (const path of [
    "/broker-session/status",
    "/market-data/status",
    "/market-data/markets",
    "/market-data/history",
    "/market-data/stream",
  ]) {
    const start = "  " + path + ":\n";
    const endIndex = contract.indexOf("\n  /", contract.indexOf(start) + start.length);
    const block = contract.slice(
      contract.indexOf(start),
      endIndex < 0 ? contract.indexOf("components:\n") : endIndex,
    );
    assert.match(block, /^      security:\n        - localBackendCapability: \[\]$/m, path + " capability");
    assert.match(block, /^      x-native-request-context:/m, path + " native context");
  }

  const health = sectionBetween(contract, "  /health/live:\n", "  /broker-session/status:\n");
  assert.doesNotMatch(health, /^      security:/m);
});

test("historical query parameters are separately declared and bounded", () => {
  const history = sectionBetween(contract, "  /market-data/history:\n", "  /market-data/stream:\n");
  const names = [...history.matchAll(/^        - name: ([A-Za-z][A-Za-z0-9]*)$/gm)]
    .map((match) => match[1]);
  assert.deepEqual(names, ["epic", "resolution", "max"]);
  assert.ok(history.includes("pattern: '^[A-Za-z0-9_.-]{1,64}$'"));
  assert.match(history, /maximum: 1000/);
  assert.match(history, /minimum: 1/);
  assert.match(history, /enum: \[MINUTE, MINUTE_5, MINUTE_15, MINUTE_30, HOUR, HOUR_4, DAY, WEEK\]/);
});

test("all reusable OpenAPI component references resolve", () => {
  const components = contract.slice(contract.indexOf("components:\n"));
  const schemaSection = sectionBetween(components, "  schemas:\n", "  responses:\n");
  const responseSection = components.split("  responses:\n")[1] ?? "";
  const schemas = new Set([...schemaSection.matchAll(/^    ([A-Za-z][A-Za-z0-9]+):$/gm)].map((match) => match[1]));
  const responses = new Set([...responseSection.matchAll(/^    ([A-Za-z][A-Za-z0-9]+):$/gm)].map((match) => match[1]));
  const references = [...contract.matchAll(/\$ref: '#\/components\/(schemas|responses)\/([^']+)'/g)];

  assert.ok(references.length > 0);
  for (const [, section, name] of references) {
    const declared = section === "schemas" ? schemas : responses;
    assert.ok(declared.has(name), "unresolved " + section + " reference: " + name);
  }
});

test("SSE contract names the implemented status, quote and error event types", () => {
  const stream = sectionBetween(contract, "  /market-data/stream:\n", "components:\n");
  assert.match(stream, /event: status/);
  assert.match(stream, /event: quote/);
  assert.match(stream, /event: error/);
  assert.match(stream, /text\/event-stream/);
  assert.match(stream, /1–40 comma-separated/);
});
