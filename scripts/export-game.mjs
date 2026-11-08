import { spawnSync } from "node:child_process";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
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
for (const args of [
  ["--headless", "--path", "client-godot", "--editor", "--import", "--quit"],
  [
    "--headless",
    "--path",
    "client-godot",
    "--export-release",
    "Web",
    "../apps/web/public/game/index.html",
  ],
]) {
  const result = spawnSync(binary, args, { encoding: "utf8" });
  process.stdout.write(result.stdout ?? "");
  process.stderr.write(result.stderr ?? "");
  if (
    result.status !== 0 ||
    /SCRIPT ERROR|Parse Error|Failed to load script/.test(
      (result.stdout ?? "") + (result.stderr ?? ""),
    )
  )
    process.exit(1);
}
if (!existsSync("apps/web/public/game/index.wasm"))
  throw new Error("Ekspor Web tidak ditemukan.");

const htmlPath = "apps/web/public/game/index.html";
let count = 0;
const html = readFileSync(htmlPath, "utf8").replace(
  /<script>([\s\S]*?)<\/script>/gi,
  (_, script) => {
    const name = `bootstrap-${++count}.js`;
    writeFileSync(`apps/web/public/game/${name}`, script);
    return `<script src="${name}"></script>`;
  },
);
writeFileSync(htmlPath, html);
