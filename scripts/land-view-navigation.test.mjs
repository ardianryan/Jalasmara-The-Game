import test from "node:test";
import assert from "node:assert/strict";
import { keyboardForLogicalDelta, keyboardPulse, logicalMotionFromKeys, projectLogicalDelta } from "./land-view-navigation.mjs";

const legacy = { schemaVersion: 1, columns: [[1, 0], [0, 1]] };
// A renderer contract is the source of truth; this consumer never reconstructs camera angles.
const quarter = { schemaVersion: 1, columns: [[0.7071067811865476, -0.3535533905932737], [1.232803051821635, 0.6164015259108174]] };
const directions = [[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1],[0,-1],[1,-1]];

test("legacy matrix preserves eight physical keyboard directions", () => {
  const expected = [["d"],["d","s"],["s"],["a","s"],["a"],["a","w"],["w"],["d","w"]];
  directions.forEach((delta,index) => assert.deepEqual(keyboardForLogicalDelta(delta,legacy).keys,expected[index]));
});
test("left-view routes select screen keys through the actual matrix", () => {
  assert.deepEqual(keyboardForLogicalDelta([1,0],quarter).keys,["d","w"]);
  assert.deepEqual(keyboardForLogicalDelta([0,1],quarter).keys,["d","s"]);
  assert.deepEqual(keyboardForLogicalDelta([0,-1],quarter).keys,["a","w"]);
  for (const strength of [.25,1,2]) {
    const logical = logicalMotionFromKeys([strength,0],quarter);
    assert(Math.abs(Math.hypot(...logical)-Math.min(strength,1))<1e-12);
    const screen = projectLogicalDelta(logical,quarter);
    assert(screen[0]>0 && Math.abs(screen[1])<1e-12);
  }
});
test("bounded pulses limit predicted lateral drift and release the player", () => {
  for (const contract of [legacy,quarter]) for (const delta of directions) {
    const pulse = keyboardPulse(delta.map((value)=>value*120),contract);
    assert(pulse.holdMs>0 && pulse.holdMs<=330);
    assert(pulse.releaseMs>=143);
    assert(pulse.nominalDistance*Math.abs(pulse.crossTrack)<=2.1+1e-9);
    assert(pulse.alignment>0);
  }
  assert.equal(keyboardPulse([0,0],quarter).holdMs,0);
});
test("navigation refuses missing, stale or singular view contracts", () => {
  for (const contract of [undefined,{schemaVersion:0,columns:legacy.columns},{schemaVersion:1,columns:[[1,0],[2,0]]}]) assert.throws(()=>keyboardForLogicalDelta([1,0],contract));
});
