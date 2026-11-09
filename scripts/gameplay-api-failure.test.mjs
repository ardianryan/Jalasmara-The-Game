import assert from "node:assert/strict";
import test from "node:test";
import { gameplayFailureDetails } from "./gameplay-api-failure.mjs";

test("failure diagnostics retain stale-version path evidence but exclude secrets", () => {
  const actual = gameplayFailureDetails(
    "/api/adventure/surface-position",
    {
      version: 7,
      fromPositionAt: 123,
      x: 160,
      y: 615,
      path: [
        { x: 160, y: 615, token: "secret" },
        { x: 180, y: 615 },
      ],
      password: "secret",
      cookie: "secret",
    },
    { code: "STALE_POSITION", player: { version: 8, email: "secret" } },
  );
  assert.equal(actual.requestVersion, 7);
  assert.equal(actual.playerVersion, 8);
  assert.equal(actual.fromPositionAt, 123);
  assert.deepEqual(actual.positionPath, [
    { x: 160, y: 615 },
    { x: 180, y: 615 },
  ]);
  assert(!JSON.stringify(actual).includes("secret"));
});

test("login and unrelated APIs never expose submitted or response bodies", () => {
  for (const path of [
    "/api/auth/login",
    "/api/admin/export",
    "/api/account/password",
  ])
    assert.deepEqual(
      gameplayFailureDetails(path, { password: "secret" }, { error: "secret" }),
      {},
    );
});

test("malformed coordinate evidence is finite and bounded to the API64-point limit", () => {
  const actual = gameplayFailureDetails("/api/adventure/surface-position", {
    version: Infinity,
    x: "secret",
    path: Array.from({ length: 100 }, () => ({ x: 1, y: 2 })),
  });
  assert.equal(actual.requestVersion, undefined);
  assert.equal(actual.x, undefined);
  assert.equal(actual.pathPoints, 100);
  assert.equal(actual.positionPath.length, 64);
});
