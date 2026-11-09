import assert from "node:assert/strict";
import test from "node:test";
import { isAdminChunkUrl, publicAcceptance } from "./public-smoke-scope.mjs";
const origin = "https://staging-jalasmara.ardianryan.com";

test("compiled admin chunk detection uses exact same-origin script pathname", () => {
  assert(isAdminChunkUrl("/assets/admin-aB_12-x.js", origin));
  assert(isAdminChunkUrl(origin + "/assets/admin-aB_12-x.js?v=1", origin));
  for (const path of [
    "/assets/index-abc.js?admin-abc.js",
    "/game/admin-abc.js",
    "/assets/admin-abc.js.map",
    "https://other.invalid/assets/admin-abc.js",
  ])
    assert.equal(isAdminChunkUrl(path, origin), false);
});

test("host component acceptance never implies a full gameplay-route acceptance", () => {
  assert.deepEqual(publicAcceptance("completed", false, true), {
    defaultPublicAccepted: false,
    hostPublicAccepted: true,
    scope: "host-auth-startup-reload-clock-and-admin-chunk-delivery",
  });
  assert.equal(
    publicAcceptance("completed", false, false).defaultPublicAccepted,
    true,
  );
  assert.equal(
    publicAcceptance("completed", false, false).hostPublicAccepted,
    false,
  );
});

test("failed cleanup/outcome or HTTP1 diagnostic cannot pass either public scope", () => {
  for (const hostOnly of [false, true])
    for (const [outcome, diagnostic] of [
      ["failed", false],
      ["completed", true],
    ]) {
      const result = publicAcceptance(outcome, diagnostic, hostOnly);
      assert.equal(result.defaultPublicAccepted, false);
      assert.equal(result.hostPublicAccepted, false);
    }
});
