import test from "node:test";
import assert from "node:assert/strict";
import vm from "node:vm";
import { withLoadingBridge } from "./game-loading-bridge.mjs";

// Small executable shell fixture: preserve exporter callback signatures and promise order.
const shell = `const GODOT_CONFIG = {};
function displayFailureNotice(err) { window.failed = err; }
function setStatusMode(mode) { window.mode = mode; }
engine.startGame({
  'onProgress': function (current, total) { window.bytes = [current, total]; },
}).then(() => { setStatusMode('hidden'); }, displayFailureNotice);`;

function boot({ standalone = false } = {}) {
  const messages = [];
  let callbacks, resolve, reject;
  const parent = {
    postMessage: (data, origin) => messages.push({ data, origin }),
  };
  const window = { parent, location: { origin: "https://jalasmara.test" } };
  if (standalone) window.parent = window;
  const engine = {
    startGame: (value) => {
      callbacks = value;
      return new Promise((yes, no) => {
        resolve = yes;
        reject = no;
      });
    },
  };
  vm.runInNewContext(withLoadingBridge(shell), { window, engine, Number });
  return { messages, window, callbacks, resolve, reject };
}

test("bridge forwards real bytes and keeps existing progress + preparation callbacks", async () => {
  const fixture = boot();
  fixture.callbacks.onProgress(5_000_000, 10_000_000);
  assert.equal(fixture.messages.at(-1).data.downloadedBytes, 5_000_000);
  assert.equal(fixture.messages.at(-1).data.totalBytes, 10_000_000);
  assert.deepEqual(Array.from(fixture.window.bytes), [5_000_000, 10_000_000]);
  assert.equal(fixture.messages.at(-1).origin, "https://jalasmara.test");
  assert.equal(fixture.messages.at(-1).data.version, 1);
  fixture.resolve();
  await Promise.resolve();
  assert.equal(fixture.messages.at(-1).data.phase, "preparing");
  assert.equal(fixture.window.mode, "hidden");
});

test("unknown totals remain unknown and failures reach the host", async () => {
  const fixture = boot();
  fixture.callbacks.onProgress(20, 0);
  assert.equal(fixture.messages.at(-1).data.totalBytes, null);
  assert.equal(fixture.messages.at(-1).data.downloadedBytes, 20);
  fixture.reject(new Error("Network unavailable"));
  await Promise.resolve();
  assert.equal(fixture.messages.at(-1).data.phase, "error");
  assert.equal(fixture.window.failed.message, "Network unavailable");
});

test("standalone export keeps working without parent messages", async () => {
  const fixture = boot({ standalone: true });
  fixture.callbacks.onProgress(1, 2);
  fixture.resolve();
  await Promise.resolve();
  assert.equal(fixture.messages.length, 0);
  assert.equal(fixture.window.mode, "hidden");
});

test("an upstream shell change fails export rather than silently losing progress", () => {
  assert.throws(
    () =>
      withLoadingBridge(
        shell.replace(
          "function displayFailureNotice(err)",
          "function showError(err)",
        ),
      ),
    /hook changed/,
  );
  assert.equal(
    withLoadingBridge("console.log('unrelated inline script')"),
    "console.log('unrelated inline script')",
  );
});
