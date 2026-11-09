import assert from "node:assert/strict";

export async function findFixtureAuthKeys(cache, userId) {
  assert(
    /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(
      userId,
    ),
    "Auth cleanup requires an exact fixture UUID",
  );
  const own = new Set();
  let cursor = "0";
  do {
    const page = await cache.scan(cursor, "MATCH", "auth:*", "COUNT", 100);
    cursor = page[0];
    for (const key of page[1]) {
      const raw = await cache.get(key);
      if (!raw) continue;
      let session;
      try {
        session = JSON.parse(raw);
      } catch {
        continue;
      }
      if (session?.userId === userId) own.add(key);
    }
  } while (cursor !== "0");
  return [...own];
}
