import { execFileSync, spawnSync } from "node:child_process";
import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

const runtime = resolve(".runtime");
const output = resolve(process.env.WORLD_REPORT_DIR ?? ".runtime/world-check");
mkdirSync(runtime, { recursive: true });
mkdirSync(output, { recursive: true });
const world = execFileSync(
  process.execPath,
  [
    "--experimental-strip-types",
    "--input-type=module",
    "-e",
    'import {WORLD} from "./packages/shared/src/world.ts";process.stdout.write(JSON.stringify(WORLD))',
  ],
  { encoding: "utf8" },
);
writeFileSync(`${runtime}/world-map.json`, world);
const godot =
  process.env.GODOT_BIN ??
  process.env.GODOT ??
  [
    ".runtime/godot/Godot.app/Contents/MacOS/Godot",
    ".cache/godot-4.7.2/godot",
  ].find(existsSync) ??
  "godot";
const scripts = [
  "scripts/godot-map-geometry.gd",
  "scripts/godot-creature-animation.gd",
  "scripts/godot-wildlife-check.gd",
  "scripts/tests/living-water.gd",
  "scripts/tests/world-foley.gd",
  "scripts/tests/terrain-layers.gd",
  "scripts/tests/ocean-geology.gd",
  "scripts/tests/character-outfits.gd",
  "scripts/tests/hud-oxygen.gd",
  "scripts/tests/analog-dialogue.gd",
  "scripts/tests/field-book.gd",
  "scripts/tests/world-atlas-layout.gd",
  "scripts/tests/render-performance.gd",
  "scripts/tests/player-locomotion.gd",
  "scripts/tests/locomotion-collision-foley.gd",
  "scripts/tests/quiz-layout.gd",
  "scripts/tests/legacy-forest-ui.gd",
  "scripts/tests/ocean-backdrop.gd",
  "scripts/tests/component-land.gd",
  "scripts/tests/land-water-3d.gd",
  "scripts/tests/land-renderer.gd",
  "scripts/tests/surface-traversal.gd",
  "scripts/tests/land-path.gd",
  "scripts/tests/world-clock.gd",
  "scripts/tests/authoritative-calendar.gd",
  "scripts/tests/homestead-world.gd",
  "scripts/tests/homestead-ui.gd",
  "scripts/tests/kedai-focus.gd",
  "scripts/tests/village-activities.gd",
  "scripts/tests/npc-body-animation.gd",
];
const results = [];
try {
  for (const script of scripts) {
    const started = Date.now();
    let log = "";
    try {
      const run = spawnSync(
        godot,
        ["--headless", "--path", "client-godot", "--script", resolve(script)],
        { encoding: "utf8", timeout: 60000, stdio: ["ignore", "pipe", "pipe"] },
      );
      log = String(run.stdout ?? "") + String(run.stderr ?? "");
      if (run.error) throw run.error;
      if (run.status !== 0 || /SCRIPT ERROR|(?:^|\n)ERROR:/.test(log))
        throw new Error(`Godot check failed: ${script}\n${log}`);
      if (!log.includes("PASS")) throw new Error("No completed PASS result");
      results.push({
        script,
        status: "passed",
        elapsedMs: Date.now() - started,
      });
      process.stdout.write(log);
    } catch (error) {
      log += String(error.stdout ?? "") + String(error.stderr ?? error.message);
      results.push({
        script,
        status: "failed",
        elapsedMs: Date.now() - started,
      });
      throw error;
    } finally {
      writeFileSync(`${output}/${script.replaceAll("/", "-")}.log`, log);
    }
  }
  execFileSync(process.execPath, ["tools/procedural-creatures/verify.mjs"], {
    stdio: "inherit",
  });
} finally {
  writeFileSync(
    `${output}/world-checks.json`,
    JSON.stringify(results, null, 2),
  );
}
