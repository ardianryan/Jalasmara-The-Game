import test from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import argon2 from "argon2";
import { buildApp } from "../src/app.js";
import {
  connect,
  close,
  seed,
  opaque,
  digest,
  type Store,
  type User,
} from "../src/db.js";
import { setCalendar } from "../src/daily.js";
import {
  freshAbilities,
  freshProgress,
  freshCalendar,
  freshHomestead,
  HOMESTEAD_DEFINITIONS,
} from "../../../packages/shared/src/index.js";
import { WORLD } from "../../../packages/shared/src/world.js";
import { isLandWalkable } from "../../../packages/shared/src/land.js";

test(
  "jahe and real live-catch fish pen complete server-owned care, breeding and kedai transactions",
  { timeout: 60000 },
  async (t) => {
    const token = randomUUID().replaceAll("-", ""),
      database = `jalasmara_breeding_${token}`;
    const original = Object.fromEntries(
      ["NODE_ENV", "APP_ORIGIN", "MONGO_URL", "REDIS_URL"].map((key) => [
        key,
        process.env[key],
      ]),
    );
    const mongo = new URL(
      process.env.TEST_MONGO_URL ??
        "mongodb://127.0.0.1:27018/unused?replicaSet=rs0",
    );
    mongo.pathname = `/${database}`;
    Object.assign(process.env, {
      NODE_ENV: "test",
      APP_ORIGIN: "http://localhost:5173",
      MONGO_URL: mongo.toString(),
      REDIS_URL: process.env.TEST_REDIS_URL ?? "redis://127.0.0.1:6380/14",
    });
    let store: Store | undefined,
      app: Awaited<ReturnType<typeof buildApp>> | undefined;
    const id = randomUUID(),
      cookies: Record<string, string> = {},
      authKeys = new Set<string>();
    let csrf = "";
    try {
      store = await connect();
      assert.equal(store.db.databaseName, database);
      await seed(store);
      app = await buildApp(store, false);
      await app.ready();
      const request = async (
        path: string,
        payload?: Record<string, unknown>,
        key = randomUUID(),
      ) => {
        const response = await app!.inject({
          method: payload === undefined ? "GET" : "POST",
          url: `/api${path}`,
          remoteAddress: `fd00:${token.match(/.{4}/g)!.slice(0, 5).join(":")}::1`,
          headers: {
            cookie: Object.entries(cookies)
              .map(([key, value]) => `${key}=${value}`)
              .join("; "),
            origin: store!.cfg.origin,
            "x-csrf-token": csrf,
            "idempotency-key": key,
          },
          payload,
        });
        for (const cookie of response.cookies) {
          cookies[cookie.name] = cookie.value;
          if (cookie.name === "jalasmara")
            authKeys.add(`auth:${digest(cookie.value)}`);
        }
        const data = response.json();
        if (data.csrf) csrf = data.csrf;
        return { status: response.statusCode, data };
      };
      const state = async () => (await request("/homestead/state")).data;
      const surface = async (point: { x: number; y: number }) => {
        assert.ok(
          isLandWalkable(WORLD.landMaps.hub, point, 13),
          JSON.stringify(point),
        );
        const player = (await store!.users.findOne({ id }))!;
        await store!.redis.set(
          `surface:${id}`,
          JSON.stringify({
            area: "hub",
            ...point,
            playerVersion: player.version,
            layoutVersion: WORLD.hub.layoutVersion,
            positionAt: Date.now(),
          }),
          "EX",
          1800,
        );
      };
      const action = async (
        name: string,
        extra: Record<string, unknown> = {},
      ) =>
        request("/homestead/action", {
          action: name,
          expectedRevision: (await state()).homestead.revision,
          ...extra,
        });
      const sleep = async () => {
        await surface(WORLD.homestead.door);
        assert.equal((await action("enter")).status, 200);
        let player = (await store!.users.findOne({ id }))!;
        const bedApproach = {
          x: WORLD.homestead.interior.bed.x,
          y: WORLD.homestead.interior.bed.y + 80,
        };
        assert.ok(isLandWalkable(WORLD.homestead.interior, bedApproach, 13));
        await store!.redis.set(
          `home:${id}`,
          JSON.stringify({
            ...bedApproach,
            playerVersion: player.version,
            positionAt: Date.now(),
          }),
          "EX",
          1800,
        );
        const slept = await action("sleep", { confirmEarly: true });
        assert.equal(slept.status, 200, JSON.stringify(slept.data));
        player = (await store!.users.findOne({ id }))!;
        await store!.redis.set(
          `home:${id}`,
          JSON.stringify({
            ...WORLD.homestead.interior.exit,
            playerVersion: player.version,
            positionAt: Date.now(),
          }),
          "EX",
          1800,
        );
        assert.equal((await action("exit")).status, 200);
      };
      const password = opaque(),
        now = new Date().toISOString();
      const user: User = {
        id,
        email: `${id}@breeding.test.invalid`,
        name: "Penguji Budidaya",
        role: "player",
        status: "active",
        coins: 500,
        inventory: [],
        abilities: freshAbilities(),
        progress: {
          ...freshProgress(),
          day: 2,
          tutorial: true,
          missions: ["akar"],
        },
        version: 0,
        authVersion: 0,
        calendar: freshCalendar(),
        homestead: freshHomestead(1, true),
        passwordHash: await argon2.hash(password),
        createdAt: now,
        updatedAt: now,
      };
      await store.users.insertOne(user);
      await request("/auth/session");
      assert.equal(
        (await request("/auth/login", { email: user.email, password })).status,
        200,
      );

      await t.test(
        "legacy homestead migration preserves stored produce and does not grant parents or seeds",
        async () => {
          await store!.users.updateOne(
            { id },
            {
              $unset: {
                "homestead.seeds.benih_jahe": "",
                "homestead.produce.jahe": "",
                "homestead.produce.ikan_seruni": "",
                "homestead.pantry.jahe": "",
                "homestead.pantry.ikan_seruni": "",
                "homestead.liveCatch": "",
                "homestead.fishPen": "",
              },
              $set: { "homestead.produce.kangkung": 7 },
            },
          );
          const migrated = await state();
          assert.equal(migrated.homestead.produce.kangkung, 7);
          assert.equal(migrated.homestead.seeds.benih_kangkung, 2);
          assert.equal(migrated.homestead.seeds.benih_jahe, 0);
          assert.equal(migrated.homestead.liveCatch.reef_seruni, 0);
          assert.equal(migrated.homestead.fishPen.breeders, 0);
          assert.deepEqual((await state()).homestead, migrated.homestead);
          assert.equal(
            (await store!.users.findOne({ id }))!.homestead!.fishPen.breeders,
            0,
          );
        },
      );
      await t.test(
        "jahe has a distinct price and four cared calendar days, with retry-safe harvest",
        async () => {
          await surface(WORLD.homestead.market);
          const before = await state(),
            key = randomUUID(),
            body = {
              action: "buy_seed",
              itemId: "benih_jahe",
              qty: 1,
              expectedRevision: before.homestead.revision,
            };
          const bought = await request("/homestead/action", body, key);
          assert.equal(bought.status, 200, JSON.stringify(bought.data));
          assert.deepEqual(
            (await request("/homestead/action", body, key)).data,
            bought.data,
          );
          assert.equal((await state()).player.coins, before.player.coins - 30);
          await surface(WORLD.homestead.gardenPlots[0].interaction);
          assert.equal(
            (await action("plant", { plotId: "plot_1", itemId: "benih_jahe" }))
              .status,
            200,
          );
          assert.equal(
            (await action("harvest", { plotId: "plot_1" })).data.code,
            "CROP_NOT_READY",
          );
          for (let day = 0; day < 4; day++) {
            await surface(WORLD.homestead.gardenPlots[0].interaction);
            assert.equal(
              (await action("water", { plotId: "plot_1" })).status,
              200,
            );
            await sleep();
            const growing = await state();
            assert.equal(growing.homestead.plots[0].growthDays, day + 1);
            assert.equal(growing.homestead.plots[0].ready, day === 3);
          }
          await surface(WORLD.homestead.gardenPlots[0].interaction);
          const ready = await state(),
            harvestKey = randomUUID(),
            harvest = {
              action: "harvest",
              plotId: "plot_1",
              expectedRevision: ready.homestead.revision,
            };
          const harvested = await request(
            "/homestead/action",
            harvest,
            harvestKey,
          );
          assert.equal(harvested.status, 200);
          assert.deepEqual(
            (await request("/homestead/action", harvest, harvestKey)).data,
            harvested.data,
          );
          assert.equal((await state()).homestead.produce.jahe, 3);
          assert.equal(
            (await request("/homestead/action", harvest)).status,
            409,
          );
        },
      );
      await t.test(
        "knowledge fragments cannot become breeders and distant pen actions are rejected",
        async () => {
          await surface(WORLD.homestead.market);
          assert.equal(
            (await action("stock_pen", { itemId: "reef_seruni", qty: 2 })).data
              .code,
            "POSITION",
          );
          await surface(WORLD.homestead.fishPen.interaction);
          await store!.users.updateOne(
            { id },
            {
              $set: {
                inventory: [{ fragmentId: "ekosistem", stars: 3, quantity: 2 }],
              },
            },
          );
          assert.equal(
            (await action("stock_pen", { itemId: "reef_seruni", qty: 2 }))
              .status,
            400,
          );
          assert.equal((await state()).homestead.fishPen.breeders, 0);
        },
      );
      await t.test(
        "real three-star reef captures survive only successful extract and cannot duplicate on retry",
        async () => {
          await surface(WORLD.hub.divePoint);
          const started = await request("/dive/start", { mode: "dive" });
          assert.equal(started.status, 200, JSON.stringify(started.data));
          const diveId = started.data.dive.id;
          let dive = JSON.parse((await store!.redis.get(`dive:${id}`))!);
          const targets = dive.targets
            .filter((target: { fragmentId: string }) =>
              ["ekosistem", "netralisasi"].includes(target.fragmentId),
            )
            .slice(0, 2);
          assert.equal(targets.length, 2);
          for (const target of targets) {
            dive = JSON.parse((await store!.redis.get(`dive:${id}`))!);
            dive.position = { x: target.x, y: target.y };
            dive.netAt = Date.now() - 900;
            await store!.redis.set(
              `dive:${id}`,
              JSON.stringify(dive),
              "EX",
              1800,
            );
            const caught = await request("/dive/collect", {
              diveId,
              targetId: target.id,
            });
            assert.equal(caught.status, 200, JSON.stringify(caught.data));
            assert.equal(caught.data.stars, 3);
            await request("/dive/collect", { diveId, targetId: target.id });
          }
          dive = JSON.parse((await store!.redis.get(`dive:${id}`))!);
          assert.equal(dive.liveCatch.reef_seruni, 2);
          dive.position = WORLD.spawn;
          await store!.redis.set(
            `dive:${id}`,
            JSON.stringify(dive),
            "EX",
            1800,
          );
          const key = randomUUID(),
            result = await request("/dive/extract", { diveId }, key);
          assert.equal(result.status, 200, JSON.stringify(result.data));
          assert.deepEqual(
            (await request("/dive/extract", { diveId }, key)).data,
            result.data,
          );
          assert.equal((await state()).homestead.liveCatch.reef_seruni, 2);
          assert.equal(
            (await request("/dive/extract", { diveId })).status,
            410,
          );
        },
      );
      await t.test(
        "two-star net catches do not become parents and fainted extraction loses all live catch",
        async () => {
          const before = await state();
          await surface(WORLD.hub.divePoint);
          const started = await request("/dive/start", { mode: "dive" });
          assert.equal(started.status, 200, JSON.stringify(started.data));
          const diveId = started.data.dive.id;
          let dive = JSON.parse((await store!.redis.get(`dive:${id}`))!);
          const targets = dive.targets
            .filter((target: { fragmentId: string }) =>
              ["ekosistem", "netralisasi"].includes(target.fragmentId),
            )
            .slice(0, 2);
          assert.equal(targets.length, 2);
          for (const [index, target] of targets.entries()) {
            dive = JSON.parse((await store!.redis.get(`dive:${id}`))!);
            dive.position = { x: target.x, y: target.y };
            dive.netAt = Date.now() - (index === 0 ? 2000 : 900);
            await store!.redis.set(
              `dive:${id}`,
              JSON.stringify(dive),
              "EX",
              1800,
            );
            const caught = await request("/dive/collect", {
              diveId,
              targetId: target.id,
            });
            assert.equal(caught.status, 200, JSON.stringify(caught.data));
            assert.equal(caught.data.stars, index === 0 ? 2 : 3);
            const saved = JSON.parse((await store!.redis.get(`dive:${id}`))!);
            assert.equal(saved.liveCatch?.reef_seruni ?? 0, index);
          }
          dive = JSON.parse((await store!.redis.get(`dive:${id}`))!);
          dive.oxygen = 0;
          await store!.redis.set(
            `dive:${id}`,
            JSON.stringify(dive),
            "EX",
            1800,
          );
          const key = randomUUID();
          const extracted = await request("/dive/extract", { diveId }, key);
          assert.equal(extracted.status, 200, JSON.stringify(extracted.data));
          assert.equal(extracted.data.fainted, true);
          assert.equal(
            (await state()).homestead.liveCatch.reef_seruni,
            before.homestead.liveCatch.reef_seruni,
          );
          assert.deepEqual(
            (await request("/dive/extract", { diveId }, key)).data,
            extracted.data,
          );
          assert.equal(
            (await state()).homestead.liveCatch.reef_seruni,
            before.homestead.liveCatch.reef_seruni,
          );
        },
      );
      await t.test(
        "two fed settlements breed once; unfed days, duplicate day settlement and receipt replay do not",
        async () => {
          await surface(WORLD.homestead.fishPen.interaction);
          await store!.users.updateOne({ id }, { $set: { "progress.day": 1 } });
          assert.equal(
            (await action("stock_pen", { itemId: "reef_seruni", qty: 2 })).data
              .code,
            "PEN_LOCKED",
          );
          await store!.users.updateOne({ id }, { $set: { "progress.day": 2 } });
          assert.equal(
            (await action("stock_pen", { itemId: "reef_seruni", qty: 2 }))
              .status,
            200,
          );
          assert.equal((await state()).homestead.liveCatch.reef_seruni, 0);
          assert.equal(
            (await action("stock_pen", { itemId: "reef_seruni", qty: 2 }))
              .status,
            400,
          );
          await sleep();
          assert.equal((await state()).homestead.fishPen.progressDays, 0);
          for (let day = 0; day < 2; day++) {
            await surface(WORLD.homestead.fishPen.interaction);
            const before = await state(),
              key = randomUUID(),
              body = {
                action: "feed_pen",
                expectedRevision: before.homestead.revision,
              };
            const fed = await request("/homestead/action", body, key);
            assert.equal(fed.status, 200, JSON.stringify(fed.data));
            assert.deepEqual(
              (await request("/homestead/action", body, key)).data,
              fed.data,
            );
            assert.equal((await state()).player.coins, before.player.coins - 2);
            assert.equal(
              (await action("feed_pen")).data.code,
              "PEN_ALREADY_FED",
            );
            await sleep();
            const after = await state();
            assert.equal(after.homestead.fishPen.offspring, day === 1 ? 1 : 0);
            const player = (await store!.users.findOne({ id }))!;
            const pen = structuredClone(player.homestead!.fishPen);
            setCalendar(
              player,
              player.calendar!.calendarDay,
              player.calendar!.minuteOfDay,
            );
            assert.deepEqual(player.homestead!.fishPen, pen);
          }
          await surface(WORLD.homestead.fishPen.interaction);
          const before = await state(),
            key = randomUUID(),
            body = {
              action: "harvest_pen",
              expectedRevision: before.homestead.revision,
              qty: 1,
            };
          const harvested = await request("/homestead/action", body, key);
          assert.equal(harvested.status, 200);
          assert.deepEqual(
            (await request("/homestead/action", body, key)).data,
            harvested.data,
          );
          assert.equal((await state()).homestead.produce.ikan_seruni, 1);
          assert.equal(
            (await action("harvest_pen")).data.code,
            "PEN_NOT_READY",
          );
          const capped = structuredClone((await store!.users.findOne({ id }))!);
          Object.assign(capped.homestead!.fishPen, {
            offspring: 5,
            progressDays: 1,
            fedDay: capped.calendar!.calendarDay,
          });
          setCalendar(capped, capped.calendar!.calendarDay + 1, 360);
          assert.equal(capped.homestead!.fishPen.offspring, 5);
          assert.equal(capped.homestead!.fishPen.progressDays, 1);
        },
      );
      await t.test(
        "jahe and cultivated fish are consumed only by successful atomic kedai service",
        async () => {
          const wira = WORLD.surface_hub.districts.find(
            (district) => district.npc === "Mbah Wira",
          )!;
          await surface(wira);
          await store!.users.updateOne(
            { id },
            {
              $set: {
                adventure: {
                  discoveries: ["nitrogen", "photosynthesis", "osmosis"],
                  puzzles: [],
                  keyItems: [],
                },
              },
            },
          );
          for (const itemId of ["jahe", "ikan_seruni"])
            assert.equal(
              (await action("stock_kedai", { itemId, qty: 1 })).status,
              200,
            );
          const started = await request("/kedai/start", {});
          assert.equal(started.status, 200, JSON.stringify(started.data));
          const recipes = started.data.shift.customers.filter(
            (recipe: { id: string }) =>
              !started.data.shift.served.includes(recipe.id),
          );
          assert.ok(recipes.length >= 2);
          for (const [index, gardenItemId] of (
            ["jahe", "ikan_seruni"] as const
          ).entries()) {
            const recipe = recipes[index],
              before = await state();
            await store!.users.updateOne(
              { id },
              {
                $push: {
                  inventory: {
                    fragmentId: recipe.fragmentId,
                    stars: 3,
                    quantity: 1,
                  },
                },
              },
            );
            const key = randomUUID(),
              body = {
                shiftId: started.data.shift.id,
                recipeId: recipe.id,
                fragmentId: recipe.fragmentId,
                stars: 3,
                gardenIngredient: true,
                gardenItemId,
              };
            const served = await request("/kedai/serve", body, key);
            assert.equal(served.status, 200, JSON.stringify(served.data));
            assert.equal(
              served.data.gardenBonus,
              HOMESTEAD_DEFINITIONS.servings[gardenItemId].bonus,
            );
            assert.deepEqual(
              (await request("/kedai/serve", body, key)).data,
              served.data,
            );
            assert.equal(
              (await state()).homestead.pantry[gardenItemId],
              before.homestead.pantry[gardenItemId] - 1,
            );
          }
        },
      );
    } finally {
      if (app) await app.close();
      if (store) {
        const keys = [
          `surface:${id}`,
          `home:${id}`,
          `dive:${id}`,
          `calendar:writer:${id}`,
          ...authKeys,
        ];
        await store.redis.del(...keys);
        await store.db.dropDatabase();
        await close(store);
      }
      for (const [key, value] of Object.entries(original)) {
        if (value === undefined) delete process.env[key];
        else process.env[key] = value;
      }
    }
  },
);
