import test from "node:test";
import assert from "node:assert/strict";
import {
  assetIdentity,
  assetProvenance,
} from "../../apps/web/src/performance-capture.ts";

const pin = {
  schemaVersion: 1,
  pckSha256: "a".repeat(64),
  pckBytes: 1048599,
  partCount: 2,
  verification: "all-parts-verified-manifest",
};

test("asset provenance copies only validated loader identity without account fields", () => {
  const source = {
    ...pin,
    email: "private@test.invalid",
    token: "private",
    url: "private",
  };
  const result = assetIdentity(source);
  assert.deepEqual(result, pin);
  source.pckSha256 = "b".repeat(64);
  assert.equal(result.pckSha256, pin.pckSha256);
  for (const bad of [
    null,
    {},
    { ...pin, schemaVersion: 2 },
    { ...pin, partCount: 1 },
    { ...pin, pckBytes: NaN },
    { ...pin, pckBytes: 0 },
    { ...pin, pckBytes: 536870913 },
    { ...pin, pckSha256: "wrong" },
    { ...pin, verification: "whole-file-computed" },
  ])
    assert.equal(assetIdentity(bad), null);
});

test("old, incomplete and changed recordings never inherit the current candidate pin", () => {
  assert.equal(assetProvenance(null, null).status, "unavailable");
  assert.equal(assetProvenance(pin, null).status, "incomplete");
  assert.equal(assetProvenance(null, pin).status, "incomplete");
  assert.equal(
    assetProvenance(pin, { ...pin, pckSha256: "b".repeat(64) }).status,
    "changed",
  );
  assert.equal(assetProvenance(pin, pin, true).status, "unchanged-loader-pin");
  assert.equal(assetProvenance(pin, pin, false).status, "changed-document");
  assert.equal(assetProvenance(pin, pin).document, "unobserved");
});
