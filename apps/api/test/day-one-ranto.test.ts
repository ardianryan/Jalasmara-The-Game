import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import test from "node:test";
import { seedCatalog } from "../src/content.js";
import { close, connect, seed } from "../src/db.js";

const LEGACY_COMPLAINT =
  "Daun kebun apung saya menguning. Saya lupa apa yang dibutuhkan tanaman.";
const LEGACY_SOLUTION =
  "Periksa akar, cahaya, air, dan unsur hara sebelum menambah pupuk. Daun kuning dapat memiliki beberapa penyebab.";

test("new day-one service is Ranto; published seed migration preserves an active Darmi shift", async () => {
  const previousMongoUrl = process.env.MONGO_URL;
  const previousRedisUrl = process.env.REDIS_URL;
  const mongoUrl = new URL(
    process.env.TEST_MONGO_URL ??
      "mongodb://127.0.0.1:27018/jalasmara?replicaSet=rs0",
  );
  mongoUrl.pathname = `/jalasmara_ranto_${randomUUID().replaceAll("-", "")}`;
  process.env.MONGO_URL = mongoUrl.toString();
  process.env.REDIS_URL =
    process.env.TEST_REDIS_URL ?? "redis://127.0.0.1:6380/14";
  let store: Awaited<ReturnType<typeof connect>> | undefined;
  try {
    store = await connect();
    await seed(store);
    const published = await store.contents.findOne({ state: "published" });
    assert(published);
    const first = published.catalog.recipes.find((r) => r.id === "daun_kuning");
    assert.equal(first?.customer, "Pak Ranto");
    assert.equal(first?.reward, 100);
    assert.equal(first?.fragmentId, "klorofil");
    assert.equal(
      published.catalog.recipes.find((r) => r.id === "akar")?.customer,
      "Bu Darmi",
    );

    const legacy = structuredClone(seedCatalog());
    const oldFirst = legacy.recipes.find((r) => r.id === "daun_kuning")!;
    oldFirst.customer = "Bu Darmi";
    oldFirst.complaint = LEGACY_COMPLAINT;
    oldFirst.solution = LEGACY_SOLUTION;
    await store.contents.updateOne(
      { id: published.id },
      { $set: { catalog: legacy } },
    );
    const shiftId = randomUUID();
    const shifts = store.db.collection<{
      id: string;
      userId: string;
      contentId: string;
      customers: typeof legacy.recipes;
      served: string[];
      earnings: number;
      playerVersion: number;
      active: boolean;
      createdAt: Date;
    }>("shifts");
    await shifts.insertOne({
      id: shiftId,
      userId: randomUUID(),
      contentId: published.id,
      customers: [structuredClone(oldFirst)],
      served: [],
      earnings: 0,
      playerVersion: 1,
      active: true,
      createdAt: new Date(),
    });

    await seed(store);
    const migrated = await store.contents.findOne({ id: published.id });
    assert(migrated);
    const migratedFirst = migrated.catalog.recipes.find(
      (r) => r.id === "daun_kuning",
    );
    assert.equal(migratedFirst?.customer, "Pak Ranto");
    assert.equal(migratedFirst?.reward, 100);
    assert.equal(migratedFirst?.fragmentId, "klorofil");
    assert.equal(
      migrated.catalog.recipes.find((r) => r.id === "akar")?.customer,
      "Bu Darmi",
    );
    const activeShift = await shifts.findOne({ id: shiftId, active: true });
    assert.equal(activeShift?.contentId, published.id);
    assert.equal(activeShift?.customers[0].customer, "Bu Darmi");

    await seed(store);
    assert.equal(
      (await store.contents.findOne({ id: published.id }))?.catalog.recipes[0]
        .customer,
      "Pak Ranto",
    );

    const ownerCatalog = structuredClone(legacy);
    ownerCatalog.recipes[0].complaint = "Resep khusus pengelola yang belum ditinjau.";
    await store.contents.updateOne(
      { id: published.id },
      { $set: { catalog: ownerCatalog } },
    );
    await seed(store);
    const ownerPublished = await store.contents.findOne({ id: published.id });
    assert.equal(ownerPublished?.catalog.recipes[0].customer, "Bu Darmi");
    assert.equal(
      ownerPublished?.catalog.recipes[0].complaint,
      ownerCatalog.recipes[0].complaint,
    );
  } finally {
    if (store) {
      await store.db.dropDatabase();
      await close(store);
    }
    if (previousMongoUrl === undefined) delete process.env.MONGO_URL;
    else process.env.MONGO_URL = previousMongoUrl;
    if (previousRedisUrl === undefined) delete process.env.REDIS_URL;
    else process.env.REDIS_URL = previousRedisUrl;
  }
});
