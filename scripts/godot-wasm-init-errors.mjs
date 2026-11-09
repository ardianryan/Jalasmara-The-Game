import { createHash } from "node:crypto";

const replacements = [
  [
    "getModuleConfig = function (loadPath, response)",
    "getModuleConfig = function (loadPath, response, onError)",
  ],
  [
    "WebAssembly.instantiateStreaming(Promise.resolve(r), imports).then(done);",
    "WebAssembly.instantiateStreaming(Promise.resolve(r), imports).then(done).catch(onError);",
  ],
  [
    `\t\t\t\t\tr.arrayBuffer().then(function (buffer) {
\t\t\t\t\t\tWebAssembly.instantiate(buffer, imports).then(done);
\t\t\t\t\t});`,
    `\t\t\t\t\tr.arrayBuffer().then(function (buffer) {
\t\t\t\t\t\treturn WebAssembly.instantiate(buffer, imports);
\t\t\t\t\t}).then(done).catch(onError);`,
  ],
  [
    `\t\t\t\t\t\tpromise.then(function (response) {
\t\t\t\t\t\t\tconst cloned = new Response(response.clone().body, { 'headers': [['content-type', 'application/wasm']] });
\t\t\t\t\t\t\tGodot(me.config.getModuleConfig(loadPath, cloned)).then(function (module) {
\t\t\t\t\t\t\t\tconst paths = me.config.persistentPaths;
\t\t\t\t\t\t\t\tmodule['initFS'](paths).then(function (err) {
\t\t\t\t\t\t\t\t\tme.rtenv = module;
\t\t\t\t\t\t\t\t\tif (me.config.unloadAfterInit) {
\t\t\t\t\t\t\t\t\t\tEngine.unload();
\t\t\t\t\t\t\t\t\t}
\t\t\t\t\t\t\t\t\tresolve();
\t\t\t\t\t\t\t\t});
\t\t\t\t\t\t\t});
\t\t\t\t\t\t});`,
    `\t\t\t\t\t\tfunction guard(callback) {
\t\t\t\t\t\t\treturn function (value) {
\t\t\t\t\t\t\t\ttry { callback(value); } catch (error) { reject(error); }
\t\t\t\t\t\t\t};
\t\t\t\t\t\t}
\t\t\t\t\t\tpromise.then(guard(function (response) {
\t\t\t\t\t\t\tconst cloned = new Response(response.clone().body, { 'headers': [['content-type', 'application/wasm']] });
\t\t\t\t\t\t\tGodot(me.config.getModuleConfig(loadPath, cloned, reject)).then(guard(function (module) {
\t\t\t\t\t\t\t\tconst paths = me.config.persistentPaths;
\t\t\t\t\t\t\t\tmodule['initFS'](paths).then(guard(function (err) {
\t\t\t\t\t\t\t\t\tme.rtenv = module;
\t\t\t\t\t\t\t\t\tif (me.config.unloadAfterInit) {
\t\t\t\t\t\t\t\t\t\tEngine.unload();
\t\t\t\t\t\t\t\t\t}
\t\t\t\t\t\t\t\t\tresolve();
\t\t\t\t\t\t\t\t}), reject);
\t\t\t\t\t\t\t}), reject);
\t\t\t\t\t\t}), reject);`,
  ],
];
const sections = [
  [
    "\tConfig.prototype.getModuleConfig = function (",
    "\n\t};",
    "392b8a4bb75bb67e173b0f51651587e63ed814e1663a9277273108426cb9cb6c",
  ],
  [
    "\t\t\tinit: function (basePath) {",
    "\n\t\t\t},",
    "0456398333f7777e52f2accef724b3731e63bdeaed9a04afe08059653216f283",
  ],
];

export function withWasmInitErrors(source) {
  let original = source;
  for (const [before, after] of replacements) {
    if (original.split(before).length + original.split(after).length !== 3)
      throw new Error("Godot 4.7.2 WASM startup export pattern changed");
    original = original.replace(after, before);
  }
  for (const [begin, end, hash] of sections) {
    const start = original.indexOf(begin),
      finish = original.indexOf(end, start);
    if (
      start < 0 ||
      finish < 0 ||
      original.split(begin).length !== 2 ||
      createHash("sha256")
        .update(original.slice(start, finish + end.length))
        .digest("hex") !== hash
    )
      throw new Error("Godot 4.7.2 WASM startup implementation changed");
  }
  for (const [before, after] of replacements)
    original = original.replace(before, after);
  return original;
}
