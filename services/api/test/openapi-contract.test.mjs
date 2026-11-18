import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";

const contract = await readFile(new URL("../openapi.yaml", import.meta.url), "utf8");

test("OpenAPI contract has one canonical root document and only implemented routes", () => {
  for (const rootKey of ["openapi: 3.1.0", "info:", "servers:", "tags:", "paths:", "components:"]) {
    assert.equal(contract.split("\\n").filter((line) => line === rootKey).length, 1, `expected exactly one root ${rootKey}`);
  }
  assert.match(contract, /^openapi: 3\.1\.0$/m);
  assert.match(contract, /version: 0\.1\.0/);
  assert.match(contract, /url: http:\/\/127\.0\.0\.1:4100/);
  assert.match(contract, /per-request application capability/);

  for (const route of [
    "/health/live",
    "/health/ready",
    "/market-data/status",
    "/market-data/connect",
    "/market-data/disconnect",
    "/market-data/markets",
    "/market-data/history",
  ]) {
    assert.ok(contract.includes(`  ${route}:\n`), `missing documented route ${route}`);
  }

  assert.ok(contract.includes("minimum: 1"));
  assert.ok(contract.includes("maximum: 1000"));
  assert.ok(contract.includes("pattern: '^[A-Za-z0-9_.-]{1,64}$'"));
  assert.doesNotMatch(contract, /^  \/(orders|positions|dealing|executions):/m);
});

test("OpenAPI component references resolve to declared schemas and responses", () => {
  const components = contract.slice(contract.indexOf("components:\n"));
  const schemaSection = components.split("  schemas:\n")[1]?.split("  responses:\n")[0] ?? "";
  const responseSection = components.split("  responses:\n")[1] ?? "";
  const schemas = new Set([...schemaSection.matchAll(/^    ([A-Za-z][A-Za-z0-9]+):$/gm)].map((match) => match[1]));
  const responses = new Set([...responseSection.matchAll(/^    ([A-Za-z][A-Za-z0-9]+):$/gm)].map((match) => match[1]));
  const references = [...contract.matchAll(/\$ref: '#\/components\/(schemas|responses)\/([^']+)'/g)];

  assert.ok(references.length > 0, "expected reusable component references");
  for (const [, section, name] of references) {
    const declared = section === "schemas" ? schemas : responses;
    assert.ok(declared.has(name), `unresolved ${section} reference: ${name}`);
  }
});
