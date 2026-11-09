import test from "node:test";
import assert from "node:assert/strict";
import {
  recorderProvenanceMode,
  assertRecorderIdentity,
  assertDownloadedProvenance,
  assertProvenanceLoader,
} from "./recorder-provenance-gate.mjs";
const sha = "a".repeat(64),
  bytes = 1048593;
const identity = () => ({
  schemaVersion: 1,
  pckSha256: sha,
  pckBytes: bytes,
  partCount: 2,
  verification: "all-parts-verified-manifest",
});
const report = () => ({
  assetProvenance: {
    status: "unchanged-loader-pin",
    document: "same",
    start: identity(),
    end: identity(),
  },
});
const manifest = {
  version: 1,
  sha256: sha,
  bytes,
  partSize: 1048576,
  hashes: ["b".repeat(64), "c".repeat(64)],
};
const loader = (value = manifest) =>
  `const jalasmaraAssetFetch = (function(){ /* jalasmaraPckIdentity all-parts-verified-manifest */ })(${JSON.stringify(value)}, globalThis.fetch.bind(globalThis), {identityTarget: globalThis});`;
test("future recorder gate is explicit and rejects known old identity before fixture creation", () => {
  assert.equal(recorderProvenanceMode(undefined, sha), false);
  assert.equal(recorderProvenanceMode("1", sha), true);
  assert.throws(() => recorderProvenanceMode("0", sha));
  assert.throws(
    () =>
      recorderProvenanceMode(
        "1",
        "73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b",
      ),
    /Historical73d/,
  );
});
test("prefixture source capability must have the exact expected embedded manifest", () => {
  assert.equal(assertProvenanceLoader(loader(), sha, bytes).partCount, 2);
  for (const source of [
    "old-loader",
    loader({ ...manifest, sha256: "d".repeat(64) }),
    loader({ ...manifest, bytes: bytes + 1 }),
    loader().replace("identityTarget: globalThis", "identityTarget: null"),
    loader() + loader(),
  ])
    assert.throws(() => assertProvenanceLoader(source, sha, bytes));
});
test("downloaded JSON independently supplies unchanged same-document identities with no private extras", () => {
  const original = report(),
    before = structuredClone(original);
  assert.deepEqual(
    assertDownloadedProvenance(original, sha, bytes),
    before.assetProvenance,
  );
  assert.deepEqual(original, before);
  for (const mutate of [
    (r) => delete r.assetProvenance,
    (r) => (r.assetProvenance.status = "incomplete"),
    (r) => (r.assetProvenance.document = "unobserved"),
    (r) => (r.assetProvenance.end.pckSha256 = "d".repeat(64)),
    (r) => (r.assetProvenance.start.verification = "whole-file-computed"),
    (r) => (r.assetProvenance.start.email = "fixture-extra-rejected"),
    (r) => (r.assetProvenance.end = null),
  ]) {
    const value = report();
    mutate(value);
    assert.throws(() => assertDownloadedProvenance(value, sha, bytes));
  }
  assert.throws(() => assertRecorderIdentity(identity(), sha, bytes + 1));
});
