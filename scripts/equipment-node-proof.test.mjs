import test from "node:test";
import assert from "node:assert/strict";
import {
  wardrobeNodeMode,
  REQUESTED_ONLY_WARDROBE_PCK,
  assertEquipmentNodeSnapshot,
  explorerNodeMode,
  assertExplorerNodeSnapshot,
} from "./equipment-node-proof.mjs";
function snapshot(outfit, diving = false) {
  const on = outfit === "diving";
  const nodes = Object.fromEntries(
    Object.entries({ tank: 6, net: 12, satchel: 4, vest: 6 }).map(
      ([key, count]) => {
        const visible = on && ["tank", "net"].includes(key);
        return [
          key,
          {
            exists: true,
            meshCount: count,
            visible,
            visibleInTree: visible,
            visibleMeshCount: visible ? count : 0,
          },
        ];
      },
    ),
  );
  const report = {
    schemaVersion: 1,
    visibilityScope: "scene-tree-not-pixel-occlusion",
    rootInTree: true,
    rootVisibleInTree: true,
    nodes,
  };
  return {
    outfit,
    diving,
    equipment: { tank: on, net: on, satchel: false },
    land: { active: !diving, actors: { gearNodes: report } },
    hybrid: { active: diving, gearNodes: report },
  };
}
test("actual node proof is explicit and cannot reuse the historical requested-only PCK", () => {
  assert.equal(
    wardrobeNodeMode(undefined, "wardrobe", REQUESTED_ONLY_WARDROBE_PCK),
    false,
  );
  assert.throws(
    () => wardrobeNodeMode("1", "wardrobe", REQUESTED_ONLY_WARDROBE_PCK),
    /Historical73d/,
  );
  assert.throws(() => wardrobeNodeMode("0", "wardrobe", "a".repeat(64)));
  assert.throws(() => wardrobeNodeMode("1", "left", "a".repeat(64)));
  assert.equal(wardrobeNodeMode("1", "wardrobe", "a".repeat(64)), true);
});
test("protocol accepts actual land daily/diving and ocean diving without mutating snapshots", () => {
  for (const state of [
    snapshot("daily"),
    snapshot("diving"),
    snapshot("diving", true),
  ]) {
    const before = structuredClone(state);
    assertEquipmentNodeSnapshot(state, state.outfit);
    assert.deepEqual(state, before);
  }
});
test("requested flags cannot conceal missing schema, inherited hiding, missing meshes or inactive renderer", () => {
  for (const mutate of [
    (s) => delete s.land.actors.gearNodes,
    (s) => (s.land.actors.gearNodes.schemaVersion = 2),
    (s) => (s.land.actors.gearNodes.nodes.tank.visibleInTree = false),
    (s) => (s.land.actors.gearNodes.nodes.net.visibleMeshCount = 11),
    (s) => (s.land.actors.gearNodes.nodes.satchel.visible = true),
    (s) => (s.land.active = false),
    (s) => (s.land.actors.gearNodes.account = "fixture-not-allowed"),
  ]) {
    const state = snapshot("diving");
    mutate(state);
    assert.throws(() => assertEquipmentNodeSnapshot(state, "diving"));
  }
  assert.throws(
    () => assertEquipmentNodeSnapshot(snapshot("daily"), "explorer"),
    /forest explorer/,
  );
});

test("explorer node mode is a separate explicit forest-only entry and rejects historical pins", () => {
  assert.equal(
    explorerNodeMode(undefined, "left-forest", REQUESTED_ONLY_WARDROBE_PCK),
    false,
  );
  assert.equal(explorerNodeMode("1", "left-forest", "b".repeat(64)), true);
  assert.throws(
    () => explorerNodeMode("1", "wardrobe", "b".repeat(64)),
    /separate focused forest/,
  );
  assert.throws(
    () => explorerNodeMode("1", "left-forest", REQUESTED_ONLY_WARDROBE_PCK),
    /Historical73d/,
  );
  assert.throws(() => explorerNodeMode("0", "left-forest", "b".repeat(64)));
});

test("explicit explorer entry requires an actual forest satchel and hidden tank/net/duplicate vest", () => {
  const state = snapshot("daily");
  state.area = "forest";
  state.land.area = "forest";
  state.outfit = "explorer";
  state.equipment.satchel = true;
  Object.assign(state.land.actors.gearNodes.nodes.satchel, {
    visible: true,
    visibleInTree: true,
    visibleMeshCount: 4,
  });
  const before = structuredClone(state);
  assertExplorerNodeSnapshot(state);
  assert.deepEqual(state, before);
  assert.throws(
    () => assertEquipmentNodeSnapshot(state, "explorer"),
    /forest explorer/,
  );
  for (const mutate of [
    (s) => (s.area = "hub"),
    (s) => (s.outfit = "daily"),
    (s) => (s.equipment.satchel = false),
    (s) => (s.land.actors.gearNodes.nodes.satchel.visibleInTree = false),
    (s) => (s.land.actors.gearNodes.nodes.satchel.visibleMeshCount = 3),
    (s) => (s.land.actors.gearNodes.nodes.vest.visible = true),
    (s) => (s.land.actors.gearNodes.nodes.tank.visibleMeshCount = 6),
    (s) => delete s.land.actors.gearNodes,
  ]) {
    const invalid = structuredClone(state);
    mutate(invalid);
    assert.throws(() => assertExplorerNodeSnapshot(invalid));
  }
});
