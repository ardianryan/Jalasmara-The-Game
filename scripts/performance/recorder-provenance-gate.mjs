import assert from "node:assert/strict";
const oldPck =
  "73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b";
const fieldNames = [
  "partCount",
  "pckBytes",
  "pckSha256",
  "schemaVersion",
  "verification",
];
export function recorderProvenanceMode(flag, pck) {
  assert(
    flag === undefined || flag === "1",
    "PERFORMANCE_RECORDER_PROVENANCE accepts only explicit1",
  );
  if (flag === undefined) return false;
  assert(/^[a-f0-9]{64}$/.test(pck ?? ""));
  assert.notEqual(
    pck,
    oldPck,
    "Historical73d recorder proof has no verified loader identity; use the next coherent export",
  );
  return true;
}
export function assertRecorderIdentity(identity, expectedSha, expectedBytes) {
  assert(
    identity && typeof identity === "object",
    "Actual iframe/report identity is missing; no candidate fallback is allowed",
  );
  assert.deepEqual(Object.keys(identity).sort(), fieldNames);
  assert.deepEqual(identity, {
    schemaVersion: 1,
    pckSha256: expectedSha,
    pckBytes: expectedBytes,
    partCount: Math.ceil(expectedBytes / 1048576),
    verification: "all-parts-verified-manifest",
  });
}
export function assertDownloadedProvenance(report, expectedSha, expectedBytes) {
  const provenance = report.assetProvenance;
  assert(
    provenance && typeof provenance === "object",
    "Downloaded report must contain its own asset provenance",
  );
  assert.deepEqual(Object.keys(provenance).sort(), [
    "document",
    "end",
    "start",
    "status",
  ]);
  assert.equal(provenance.status, "unchanged-loader-pin");
  assert.equal(provenance.document, "same");
  assertRecorderIdentity(provenance.start, expectedSha, expectedBytes);
  assertRecorderIdentity(provenance.end, expectedSha, expectedBytes);
  return provenance;
}
export function assertProvenanceLoader(source, expectedSha, expectedBytes) {
  assert(
    typeof source === "string" && Buffer.byteLength(source) <= 4 * 1024 * 1024,
  );
  for (const marker of [
    "const jalasmaraAssetFetch =",
    "jalasmaraPckIdentity",
    "all-parts-verified-manifest",
  ])
    assert(
      source.includes(marker),
      "Live loader lacks provenance capability: " + marker,
    );
  assert(/identityTarget:\s*globalThis/.test(source));
  const matches = [
    ...source.matchAll(
      /\}\)\((\{"version":1,"sha256":"[a-f0-9]{64}","bytes":\d+,"partSize":\d+,"hashes":\[[^\]\r\n]{0,40000}\]\}),\s*globalThis\.fetch\.bind\(globalThis\),/g,
    ),
  ];
  assert.equal(
    matches.length,
    1,
    "Expected exactly one pinned segmented loader manifest",
  );
  const manifest = JSON.parse(matches[0][1]);
  assert.equal(manifest.sha256, expectedSha);
  assert.equal(manifest.bytes, expectedBytes);
  assert.equal(manifest.partSize, 1048576);
  assert.equal(manifest.hashes.length, Math.ceil(expectedBytes / 1048576));
  assert(manifest.hashes.every((value) => /^[a-f0-9]{64}$/.test(value)));
  return {
    preflight: "source-capability-only-not-loaded-identity",
    partCount: manifest.hashes.length,
  };
}
