import test from "node:test";
import assert from "node:assert/strict";
import { findFixtureAuthKeys } from "./own-fixture-auth.mjs";

const id = "11111111-1111-4111-8111-111111111111";
const other = "22222222-2222-4222-8222-222222222222";
test("uncertain-login cleanup finds every exact own session without selecting another account", async () => {
  const values = new Map([
    ["auth:own-cookie", JSON.stringify({ userId: id })],
    ["auth:lost-ack", JSON.stringify({ userId: id })],
    ["auth:other", JSON.stringify({ userId: other })],
    ["auth:malformed", "not-json"],
    ["auth:null", "null"],
  ]);
  const originalOther = values.get("auth:other");
  const pages = [
    ["auth:own-cookie", "auth:other", "auth:malformed"],
    ["auth:lost-ack", "auth:own-cookie", "auth:null", "auth:expired"],
  ];
  const cache = {
    async scan(cursor, ...options) {
      assert.deepEqual(options, ["MATCH", "auth:*", "COUNT", 100]);
      const index = Number(cursor);
      return [
        index === 0 ? "1" : "0",
        pages[index].filter((key) => values.has(key)),
      ];
    },
    async get(key) {
      return values.get(key) ?? null;
    },
  };
  const own = await findFixtureAuthKeys(cache, id);
  assert.deepEqual(own.sort(), ["auth:lost-ack", "auth:own-cookie"]);
  for (const key of own) values.delete(key);
  assert.deepEqual(await findFixtureAuthKeys(cache, id), []);
  assert.equal(values.get("auth:other"), originalOther);
  assert.equal(values.get("auth:malformed"), "not-json");
  assert.equal(values.get("auth:null"), "null");
});
test("auth cleanup refuses broad identifiers before touching Redis", async () => {
  await assert.rejects(
    findFixtureAuthKeys(
      {
        scan() {
          throw Error("must not scan");
        },
      },
      "*",
    ),
    /exact fixture UUID/,
  );
});
