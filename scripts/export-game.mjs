import { spawnSync } from "node:child_process";
import {
  existsSync,
  readFileSync,
  writeFileSync,
  readdirSync,
  unlinkSync,
} from "node:fs";
import { join } from "node:path";
import { gzipSync } from "node:zlib";
import { withLoadingBridge } from "./game-loading-bridge.mjs";
import { withTrackedStreamErrors } from "./godot-preloader-stream.mjs";
import { withWasmInitErrors } from "./godot-wasm-init-errors.mjs";
import { pckManifest } from "./pck-manifest.mjs";
import { withSegmentedPck } from "./pck-stream.mjs";
const candidates = [
  process.env.GODOT_BIN,
  "godot",
  "godot4",
  "/Applications/Godot.app/Contents/MacOS/Godot",
  ".runtime/godot/Godot.app/Contents/MacOS/Godot",
].filter(Boolean);
const binary = candidates.find(
  (p) => spawnSync(p, ["--version"], { encoding: "utf8" }).status === 0,
);
if (!binary)
  throw new Error(
    "Godot 4.7.2 diperlukan. Isi GODOT_BIN dengan path executable Godot, lalu pasang export template Web.",
  );
function runGodot(args) {
  const result = spawnSync(binary, args, { encoding: "utf8" });
  process.stdout.write(result.stdout ?? "");
  process.stderr.write(result.stderr ?? "");
  if (
    result.status !== 0 ||
    /SCRIPT ERROR|Parse Error|Failed to load script/.test(
      (result.stdout ?? "") + (result.stderr ?? ""),
    )
  )
    throw new Error(
      `Godot ${args.includes("--import") ? "import" : "export"} failed`,
    );
}
const importArgs = [
  "--headless",
  "--path",
  "client-godot",
  "--editor",
  "--import",
  "--quit",
];
const projectPath = "client-godot/project.godot";
const project = readFileSync(projectPath, "utf8");
const importProject = project.replace(/^theme\/custom=.*(?:\r?\n|$)/m, "");
// A global theme resolves its imported font before a fresh editor import can create it.
if (importProject !== project) {
  try {
    writeFileSync(projectPath, importProject);
    runGodot(importArgs);
  } finally {
    writeFileSync(projectPath, project);
  }
}
runGodot(importArgs);
runGodot([
  "--headless",
  "--path",
  "client-godot",
  "--export-release",
  "Web",
  "../apps/web/public/game/index.html",
]);
if (!existsSync("apps/web/public/game/index.wasm"))
  throw new Error("Ekspor Web tidak ditemukan.");

const htmlPath = "apps/web/public/game/index.html";
let count = 0;
const html = readFileSync(htmlPath, "utf8").replace(
  /<script>([\s\S]*?)<\/script>/gi,
  (_, script) => {
    const name = `bootstrap-${++count}.js`;
    writeFileSync(`apps/web/public/game/${name}`, withLoadingBridge(script));
    return `<script src="${name}"></script>`;
  },
);
writeFileSync(htmlPath, html);

const loaderPath = "apps/web/public/game/index.js";
const manifest = pckManifest(readFileSync("apps/web/public/game/index.pck"));
writeFileSync(
  "apps/web/public/game/pck-manifest.json",
  JSON.stringify(manifest),
);
writeFileSync(
  loaderPath,
  withSegmentedPck(
    withWasmInitErrors(
      withTrackedStreamErrors(readFileSync(loaderPath, "utf8")),
    ),
    manifest,
  ),
);

function compressGameAssets(directory) {
  for (const item of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, item.name);
    if (item.isDirectory()) compressGameAssets(path);
    else if (/\.(wasm|pck|js)$/.test(item.name)) {
      const source = readFileSync(path);
      const compressed = gzipSync(source, { level: 9 });
      if (
        item.name.endsWith(".pck") &&
        compressed.length > source.length * 0.95
      ) {
        if (existsSync(`${path}.gz`)) unlinkSync(`${path}.gz`);
        console.log(`Skipped ${item.name} gzip: savings below 5%`);
        continue;
      }
      writeFileSync(`${path}.gz`, compressed);
      console.log(
        `Precompressed ${item.name}: ${source.length} → ${compressed.length} bytes`,
      );
    }
  }
}
compressGameAssets("apps/web/public/game");
