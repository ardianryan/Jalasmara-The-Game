import assert from "node:assert/strict";

export const REQUESTED_ONLY_WARDROBE_PCK =
  "73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b";
const meshCounts = { tank: 6, net: 12, satchel: 4, vest: 6 };
const keys = (object) => Object.keys(object).sort();

export function wardrobeNodeMode(flag, routeMode, pck) {
  assert(
    flag === undefined || flag === "1",
    "PLAN06_WARDROBE_NODES accepts only explicit1",
  );
  if (flag === undefined) return false;
  assert.equal(
    routeMode,
    "wardrobe",
    "Actual gear nodes are a focused wardrobe-only proof",
  );
  assert(/^[a-f0-9]{64}$/.test(pck ?? ""));
  assert.notEqual(
    pck,
    REQUESTED_ONLY_WARDROBE_PCK,
    "Historical73d has requested gear state only; export a new diagnostic-capable PCK",
  );
  return true;
}

export function assertEquipmentNodeSnapshot(snapshot, outfit) {
  assert(
    ["daily", "diving"].includes(outfit),
    "This gate does not claim a new forest explorer proof",
  );
  assert.equal(snapshot.outfit, outfit);
  const expected = {
    tank: outfit === "diving",
    net: outfit === "diving",
    satchel: false,
    vest: false,
  };
  return assertActualGearReport(snapshot, expected);
}

export function explorerNodeMode(flag, routeMode, pck) {
  assert(
    flag === undefined || flag === "1",
    "PLAN06_EXPLORER_NODES accepts only explicit1",
  );
  if (flag === undefined) return false;
  assert.equal(
    routeMode,
    "left-forest",
    "Explorer node proof is a separate focused forest fixture",
  );
  assert(/^[a-f0-9]{64}$/.test(pck ?? ""));
  assert.notEqual(
    pck,
    REQUESTED_ONLY_WARDROBE_PCK,
    "Historical73d forest proof has requested gear only; use the diagnostic-capable export",
  );
  return true;
}

export function assertExplorerNodeSnapshot(snapshot) {
  assert.equal(snapshot.area, "forest");
  assert.equal(snapshot.land?.area, "forest");
  assert.notEqual(snapshot.diving, true);
  assert.equal(snapshot.outfit, "explorer");
  return assertActualGearReport(snapshot, {
    tank: false,
    net: false,
    satchel: true,
    vest: false,
  });
}

function assertActualGearReport(snapshot, expected) {
  for (const key of ["tank", "net", "satchel"])
    assert.equal(
      snapshot.equipment?.[key],
      expected[key],
      "Requested gear state differs: " + key,
    );
  assert.equal(
    snapshot.diving ? snapshot.hybrid?.active : snapshot.land?.active,
    true,
    "Actual gear proof requires the active renderer",
  );
  const report = snapshot.diving
    ? snapshot.hybrid?.gearNodes
    : snapshot.land?.actors?.gearNodes;
  assert.equal(
    report?.schemaVersion,
    1,
    "Unsupported or absent actual-node diagnostic schema; requested gear is not a fallback",
  );
  assert.equal(report.visibilityScope, "scene-tree-not-pixel-occlusion");
  assert.deepEqual(keys(report), [
    "nodes",
    "rootInTree",
    "rootVisibleInTree",
    "schemaVersion",
    "visibilityScope",
  ]);
  assert.equal(report.rootInTree, true);
  assert.equal(report.rootVisibleInTree, true);
  assert.deepEqual(keys(report.nodes), keys(meshCounts));
  for (const [key, count] of Object.entries(meshCounts)) {
    const node = report.nodes[key];
    assert.deepEqual(keys(node), [
      "exists",
      "meshCount",
      "visible",
      "visibleInTree",
      "visibleMeshCount",
    ]);
    assert.equal(node.exists, true, key + " attachment node must exist");
    assert.equal(
      node.meshCount,
      count,
      key + " must describe the current actual mesh hierarchy",
    );
    assert.equal(node.visible, expected[key], key + " local visibility");
    assert.equal(
      node.visibleInTree,
      expected[key],
      key + " inherited visibility",
    );
    assert.equal(
      node.visibleMeshCount,
      expected[key] ? count : 0,
      key + " actual descendant mesh visibility",
    );
  }
  return report;
}
