import { chromium } from "@playwright/test";
import assert from "node:assert/strict";
import { readFileSync, mkdirSync, writeFileSync } from "node:fs";
const origin = process.env.APP_TEST_ORIGIN ?? "http://localhost:3100";
assert(
  ["localhost", "127.0.0.1"].includes(new URL(origin).hostname),
  "Audio fixture verification is local only.",
);
const fixture = JSON.parse(
  readFileSync(
    process.env.AUDIO_BROWSER_FIXTURE ?? ".runtime/geographic-map-browser.json",
    "utf8",
  ),
);
const account = fixture.accounts[0];
const output = "artifacts/godot/audio";
mkdirSync(output, { recursive: true });
const browser = await chromium.launch({
  args: [
    "--enable-webgl",
    "--use-gl=angle",
    "--use-angle=swiftshader",
    "--enable-unsafe-swiftshader",
  ],
});
const context = await browser.newContext({
  viewport: { width: 1440, height: 900 },
});
const page = await context.newPage();
const errors = [];
const evidence = [];
let frame;
page.on("response", (response) => {
  if (response.status() >= 400)
    errors.push(response.status() + " " + response.url());
});
page.on("pageerror", (error) => errors.push(error.message));
page.on("console", (message) => {
  if (message.type() === "error") errors.push(message.text());
});
const read = () => frame.evaluate(() => window.jalasmaraSnapshot);
async function attach() {
  await page.locator("iframe").waitFor();
  frame = await (await page.locator("iframe").elementHandle()).contentFrame();
  await frame.waitForFunction(
    () =>
      window.jalasmaraReady === true && window.jalasmaraSnapshot?.audio != null,
    null,
    { timeout: 90000 },
  );
  await page.waitForTimeout(700);
}
async function waitAudio(expected) {
  await frame.waitForFunction(
    (expected) =>
      Object.entries(expected).every(
        ([key, value]) => window.jalasmaraSnapshot?.audio?.[key] === value,
      ),
    expected,
    { timeout: 12000 },
  );
  return (await read()).audio;
}
async function soundButton() {
  const canvas = frame.locator("canvas");
  const rect = await canvas.boundingBox();
  assert(rect);
  const center = (await read()).hud?.sound;
  assert(Array.isArray(center), "Sound HUD control is missing");
  await page.mouse.click(
    rect.x + rect.width * (center[0] / 960),
    rect.y + rect.height * (center[1] / 540),
  );
}
try {
  const session = await (
    await context.request.get(origin + "/api/auth/session")
  ).json();
  const login = await context.request.post(origin + "/api/auth/login", {
    data: { email: account.email, password: fixture.password },
    headers: { Origin: origin, "X-CSRF-Token": session.csrf },
  });
  assert(login.ok(), "Local isolated player login failed.");
  await page.goto(origin + "/play");
  await attach();
  let initial = (await read()).audio;
  assert.equal(initial.unlocked, false);
  assert.equal(initial.playing, false);
  evidence.push({ step: "before-gesture", audio: initial });
  await frame.locator("canvas").focus();
  await page.keyboard.press("v");
  evidence.push({
    step: "keyboard-mute-first-gesture",
    audio: await waitAudio({ unlocked: true, muted: true, playing: true }),
  });
  await soundButton();
  evidence.push({
    step: "hud-unmute",
    audio: await waitAudio({ muted: false, playing: true }),
  });
  await soundButton();
  evidence.push({ step: "hud-mute", audio: await waitAudio({ muted: true }) });
  await page.screenshot({ path: output + "/01-hud-muted.png", fullPage: true });
  await page.reload();
  await attach();
  const persisted = (await read()).audio;
  assert.equal(persisted.muted, true);
  assert.equal(persisted.unlocked, false);
  assert.equal(persisted.playing, false);
  evidence.push({
    step: "reload-persists-mute-and-regates-audio",
    audio: persisted,
  });
  await soundButton();
  evidence.push({
    step: "hud-gesture-unlocks-and-unmutes",
    audio: await waitAudio({ unlocked: true, muted: false, playing: true }),
  });
  assert(
    [
      "coastal_day",
      "underwater_segaran",
      "kedai_waras_night",
      "boss_gajah_mina",
    ].includes((await read()).audio.track),
  );
  await page.screenshot({
    path: output + "/02-hud-playing.png",
    fullPage: true,
  });
  assert.deepEqual(errors, []);
  writeFileSync(
    output + "/results.json",
    JSON.stringify(
      {
        origin,
        checks: [
          "silent-before-gesture",
          "keyboard-gesture-unlocks",
          "hud-toggle-mutes-unmutes",
          "mute-persists-reload",
          "reload-does-not-autoplay",
          "actual-hud-gesture-restarts-playback",
        ],
        evidence,
        errors,
        scope:
          "Browser verifies AudioStreamPlayer state and gesture/mute integration; audibility and speaker output require human listening.",
      },
      null,
      2,
    ),
  );
  console.log(
    "Audio browser PASS: gesture gate, HUD toggle, persistent mute/reload, track playback; no page/console errors.",
  );
} catch (error) {
  await page
    .screenshot({ path: output + "/failure.png", fullPage: true })
    .catch(() => {});
  writeFileSync(
    output + "/failure.json",
    JSON.stringify({ error: error.message, errors, evidence }, null, 2),
  );
  console.error(error.stack);
  process.exitCode = 1;
} finally {
  await browser.close();
}
