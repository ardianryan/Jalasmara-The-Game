import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import { spawnSync } from "node:child_process";
import { withWasmInitErrors } from "./godot-wasm-init-errors.mjs";
const fixture = readFileSync(
  new URL("./fixtures/godot-4.7.2-engine-init.js", import.meta.url),
  "utf8",
);

function startup(source, options = {}) {
  const calls = [],
    failure = new Error(options.failure ?? "injected startup failure");
  const body = new Response(
    new ReadableStream({
      start(controller) {
        controller.enqueue(new Uint8Array([1, 2, 3, 4]));
        if (options.bodyFailure) controller.error(failure);
        else controller.close();
      },
    }),
    { headers: { "content-type": "application/wasm" } },
  );
  const module = {
    initFS(paths) {
      calls.push(["initFS", paths]);
      if (options.fsThrow) throw failure;
      return options.fsFailure
        ? Promise.reject(failure)
        : Promise.resolve(null);
    },
  };
  const webAssembly = {
    instantiate: async (buffer, imports) => {
      calls.push(["instantiate", Array.from(new Uint8Array(buffer)), imports]);
      if (options.compileFailure) throw failure;
      return { instance: {}, module: {} };
    },
  };
  if (options.streaming !== false)
    webAssembly.instantiateStreaming = async (response, imports) => {
      calls.push(["instantiateStreaming"]);
      return webAssembly.instantiate(
        await (await response).arrayBuffer(),
        imports,
      );
    };
  const context = {
    Response,
    WebAssembly: webAssembly,
    loadPath: "index",
    initPromise: null,
    loadPromise: options.loadFailure
      ? Promise.reject(failure)
      : Promise.resolve(
          options.cloneFailure
            ? {
                clone() {
                  throw failure;
                },
              }
            : body,
        ),
    Engine: {
      unload() {
        calls.push(["unload"]);
      },
    },
    preloader: {
      setProgressFunc(callback) {
        calls.push(["progress", callback]);
      },
    },
    Godot(config) {
      calls.push(["Godot", config]);
      if (options.godotThrow) throw failure;
      if (options.godotFailure) return Promise.reject(failure);
      return new Promise((resolve, reject) => {
        try {
          config.instantiateWasm({}, () => resolve(module));
        } catch (error) {
          reject(error);
        }
      });
    },
  };
  const definitions = vm.runInNewContext(
    `${source}\n({Config,initMethods});`,
    context,
  );
  const progress = () => {};
  const config = Object.assign(new definitions.Config(), {
    onProgress: progress,
    gdextensionLibs: [],
    persistentPaths: ["user://"],
    unloadAfterInit: true,
  });
  const engine = { config, rtenv: null };
  return {
    promise: definitions.initMethods.init.call(engine, "index"),
    calls,
    engine,
    module,
    failure,
    progress,
  };
}
function bounded(promise) {
  let timer;
  return Promise.race([
    promise,
    new Promise((_, reject) => {
      timer = setTimeout(() => reject(Error("startup remained pending")), 500);
    }),
  ]).finally(() => clearTimeout(timer));
}

test("exact unpatched startup strands a raw WASM consumer rejection", () => {
  const child = spawnSync(
    process.execPath,
    [
      "--input-type=module",
      "-e",
      `
    import vm from 'node:vm';import{readFileSync}from'node:fs';
    const startup=${startup.toString()};
    const unhandled=[];process.on('unhandledRejection',error=>unhandled.push(error.message));
    const s=startup(readFileSync(process.argv[1],'utf8'),{bodyFailure:true});
    const outcome=await Promise.race([s.promise.then(()=> 'resolved',()=> 'rejected'),new Promise(resolve=>setTimeout(()=>resolve('pending'),50))]);
    console.log(JSON.stringify({outcome,unhandled}));
  `,
      new URL("./fixtures/godot-4.7.2-engine-init.js", import.meta.url)
        .pathname,
    ],
    { encoding: "utf8", timeout: 5000 },
  );
  assert.equal(child.status, 0, child.stderr || child.error?.message);
  assert.deepEqual(JSON.parse(child.stdout), {
    outcome: "pending",
    unhandled: ["injected startup failure"],
  });
});
for (const streaming of [true, false]) {
  test(`successful ${streaming ? "streaming" : "array-buffer"} startup retains actual config/progress/initFS/unload order`, async () => {
    const run = startup(withWasmInitErrors(fixture), { streaming });
    await bounded(run.promise);
    assert.equal(run.engine.rtenv, run.module);
    assert.equal(run.calls[0][0], "progress");
    assert.equal(run.calls[0][1], run.progress);
    assert.deepEqual(
      run.calls
        .filter(([name]) => name === "instantiate")
        .map(([, bytes]) => bytes),
      [[1, 2, 3, 4]],
    );
    assert.deepEqual(run.calls.slice(-2), [
      ["initFS", ["user://"]],
      ["unload"],
    ]);
    const config = run.calls.find(([name]) => name === "Godot")[1];
    assert.equal(
      config.locateFile("godot.web.template_release.wasm"),
      "index.wasm",
    );
    assert.equal(config.noExitRuntime, false);
  });
  test(`raw body and compile failure in ${streaming ? "streaming" : "fallback"} reach Engine.init rejection`, async () => {
    for (const options of [{ bodyFailure: true }, { compileFailure: true }]) {
      const run = startup(withWasmInitErrors(fixture), {
        streaming,
        ...options,
      });
      await assert.rejects(
        bounded(run.promise),
        (error) => error === run.failure,
      );
      assert.equal(run.engine.rtenv, null);
      assert(
        !run.calls.some(([name]) => name === "initFS" || name === "unload"),
      );
    }
  });
}
for (const option of [
  "loadFailure",
  "cloneFailure",
  "godotFailure",
  "godotThrow",
  "fsFailure",
  "fsThrow",
]) {
  test(`${option} rejects the existing init wrapper without remaining pending`, async () => {
    const run = startup(withWasmInitErrors(fixture), { [option]: true });
    await assert.rejects(
      bounded(run.promise),
      (error) => error === run.failure,
    );
    assert.equal(run.engine.rtenv, null);
    assert(!run.calls.some(([name]) => name === "unload"));
  });
}
test("WASM startup patch is idempotent and refuses changed or duplicated upstream implementations", () => {
  const patched = withWasmInitErrors(fixture);
  assert.equal(withWasmInitErrors(patched), patched);
  assert.throws(
    () =>
      withWasmInitErrors(
        fixture.replace("noExitRuntime': false", "noExitRuntime': true"),
      ),
    /implementation changed/,
  );
  assert.throws(
    () => withWasmInitErrors(fixture.replace("r = null;", "r = undefined;")),
    /implementation changed/,
  );
  assert.throws(() => withWasmInitErrors(fixture + fixture), /pattern changed/);
  assert.throws(
    () => withWasmInitErrors("unrelated script"),
    /pattern changed/,
  );
});
