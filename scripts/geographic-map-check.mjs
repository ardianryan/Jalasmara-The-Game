import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, writeFileSync } from "node:fs";

mkdirSync(".runtime", { recursive: true });
const world = execFileSync(
  "npx",
  [
    "tsx",
    "-e",
    'import {WORLD} from "./packages/shared/src/world.ts"; process.stdout.write(JSON.stringify(WORLD))',
  ],
  { encoding: "utf8" },
);
writeFileSync(".runtime/world-map.json", world);
const localEngine = ".runtime/godot/Godot.app/Contents/MacOS/Godot";
const godot =
  process.env.GODOT ?? (existsSync(localEngine) ? localEngine : "godot");
execFileSync(
  godot,
  [
    "--headless",
    "--path",
    "client-godot",
    "--script",
    "../scripts/godot-map-geometry.gd",
  ],
  { stdio: "inherit", timeout: 30000 },
);
