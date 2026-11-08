import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, copyFileSync } from "node:fs";
import { resolve } from "node:path";
const revision = "a2207c4bd6f1be51d426684cf58f11668def7579";
const upstream = resolve(".runtime/procedural-pixel-creatures");
const output = resolve(
  process.argv[2] ?? "client-godot/resources/art/procedural",
);
mkdirSync(resolve(".runtime"), { recursive: true });
const run = (program, args, options = {}) =>
  execFileSync(program, args, { stdio: "inherit", ...options });
if (!existsSync(`${upstream}/.git`))
  run("git", [
    "clone",
    "--no-checkout",
    "https://github.com/idlerunner00/procedural-pixel-creatures.git",
    upstream,
  ]);
const head = execFileSync("git", ["-C", upstream, "rev-parse", "HEAD"], {
  encoding: "utf8",
}).trim();
if (head !== revision) {
  run("git", ["-C", upstream, "fetch", "--depth", "1", "origin", revision]);
  run("git", ["-C", upstream, "checkout", "--detach", revision]);
}
const dotnet =
  process.env.DOTNET_BIN ??
  (existsSync(".runtime/dotnet/dotnet")
    ? resolve(".runtime/dotnet/dotnet")
    : "dotnet");
run(
  dotnet,
  [
    "build",
    "tools/procedural-creatures/Generator.csproj",
    "--configuration",
    "Release",
    `-p:UpstreamRoot=${upstream}`,
    `-p:BaseIntermediateOutputPath=${resolve(".runtime/procedural-build/obj")}/`,
    `-p:OutputPath=${resolve(".runtime/procedural-build/bin")}/`,
  ],
  {
    env: {
      ...process.env,
      DOTNET_CLI_HOME: resolve(".runtime/dotnet-home"),
      DOTNET_CLI_TELEMETRY_OPTOUT: "1",
      DOTNET_NOLOGO: "1",
    },
  },
);
run(dotnet, [resolve(".runtime/procedural-build/bin/Generator.dll"), output], {
  env: { ...process.env, DOTNET_CLI_TELEMETRY_OPTOUT: "1", DOTNET_NOLOGO: "1" },
});
copyFileSync(
  `${upstream}/LICENSE`,
  resolve("tools/procedural-creatures/LICENSE.upstream.txt"),
);
copyFileSync(`${upstream}/LICENSE`, `${output}/LICENSE.upstream.txt`);
