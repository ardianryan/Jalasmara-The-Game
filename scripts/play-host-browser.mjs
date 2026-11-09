// Host-only regression: run Vite on 5174, then node scripts/play-host-browser.mjs.
// The embedded engine and authentication are fixtures; no game/account data is mutated.
import { chromium } from "@playwright/test";
import assert from "node:assert/strict";
import { mkdirSync, writeFileSync } from "node:fs";
const origin = process.env.PLAY_HOST_ORIGIN ?? "http://localhost:5174";
assert(["localhost", "127.0.0.1"].includes(new URL(origin).hostname));
const output = "artifacts/browser/play-host";
mkdirSync(output, { recursive: true });
const browser = await chromium.launch();
const checks = [],
  errors = [];
let context;
try {
  for (const [name, viewport, touch] of [
    ["desktop", { width: 1440, height: 900 }, false],
    ["landscape", { width: 667, height: 375 }, true],
    ["portrait", { width: 390, height: 844 }, true],
  ]) {
    context = await browser.newContext({ viewport, hasTouch: touch });
    if (name === "portrait")
      await context.addInitScript(() => {
        Object.defineProperty(window, "localStorage", {
          get() {
            throw new DOMException(
              "Storage blocked in fixture",
              "SecurityError",
            );
          },
        });
      });
    const page = await context.newPage();
    page.on("pageerror", (error) => errors.push(error.message));
    await page.route("**/api/auth/session", (route) =>
      route.fulfill({
        json: {
          user: { role: "player" },
          csrf: "host-fixture",
          oidcEnabled: false,
          linked: false,
        },
      }),
    );
    await page.route("**/game/index.html", (route) =>
      route.fulfill({
        contentType: "text/html",
        body: '<!doctype html><html><body style="margin:0;background:#082e35"><script>window.messages=[];addEventListener("message",e=>{if(e.source===parent&&e.origin===location.origin)messages.push(e.data)})</script></body></html>',
      }),
    );
    await page.goto(`${origin}/play`);
    await page.locator("iframe").waitFor();
    const main = page.getByRole("main"),
      menu = page.getByRole("button", { name: "Menu", exact: true });
    assert.equal(await page.locator(".app-header").count(), 0);
    const bounds = await main.boundingBox();
    assert.equal(bounds.width, viewport.width);
    assert.equal(bounds.height, viewport.height);
    assert.equal(
      await page.evaluate(
        () => document.documentElement.scrollWidth > innerWidth,
      ),
      false,
    );
    await page.evaluate(() =>
      dispatchEvent(
        new MessageEvent("message", {
          origin: location.origin,
          source: window,
          data: { type: "jalasmara:ready" },
        }),
      ),
    );
    assert.equal(
      await page.locator(".game-loading").count(),
      1,
      "Same-origin sibling cannot announce engine readiness",
    );
    await page.evaluate(() =>
      dispatchEvent(
        new MessageEvent("message", {
          origin: "https://untrusted.invalid",
          source: document.querySelector("iframe").contentWindow,
          data: { type: "jalasmara:ready" },
        }),
      ),
    );
    assert.equal(
      await page.locator(".game-loading").count(),
      1,
      "Foreign origin cannot announce engine readiness",
    );
    const frame = page
      .frames()
      .find((frame) => frame.url().endsWith("/game/index.html"));
    await frame.evaluate(() =>
      parent.postMessage({ type: "jalasmara:ready" }, location.origin),
    );
    await page.locator(".game-loading").waitFor({ state: "detached" });
    assert.equal(await page.locator(".landscape-hint").count(),0,"Orientation advice must not cover portrait game controls after loading");
    await menu.click();
    const dialog = page.getByRole("dialog"),
      full = page.getByRole("button", { name: "Layar penuh", exact: true });
    await full.waitFor();
    await frame.waitForFunction(
      () => window.messages.at(-1)?.hostMenuOpen === true,
    );
    assert.equal(
      await full.evaluate((button) => button === document.activeElement),
      true,
    );
    await page.keyboard.press("Tab");
    const quality = page.getByLabel("Kualitas dunia", { exact: true });
    assert(
      await quality.evaluate((select) => select === document.activeElement),
      "Quality selector belongs to the menu keyboard sequence",
    );
    assert.equal(await quality.inputValue(), "auto");
    assert(
      await quality.evaluate(
        (select) =>
          parseFloat(getComputedStyle(select.labels[0]).fontSize) >= 16,
      ),
    );
    await quality.selectOption("low");
    await frame.waitForFunction(
      () => window.messages.at(-1)?.graphicsQuality === "low",
    );
    await quality.selectOption("balanced");
    await frame.waitForFunction(
      () => window.messages.at(-1)?.graphicsQuality === "balanced",
    );
    if (name !== "portrait")
      assert.equal(
        await page.evaluate(() =>
          localStorage.getItem("jalasmara.graphicsQuality"),
        ),
        "balanced",
      );
    else
      checks.push("quality:blocked-storage-still-updates-session-and-viewport");
    await full.focus();
    await page.keyboard.press("Shift+Tab");
    assert.equal(
      await page
        .getByRole("button", { name: "Lanjut bermain" })
        .evaluate((button) => button === document.activeElement),
      true,
    );
    await page.keyboard.press("Tab");
    assert.equal(
      await full.evaluate((button) => button === document.activeElement),
      true,
    );
    assert.equal(
      await page
        .getByRole("link", { name: "Akun dan pengaturan" })
        .getAttribute("href"),
      "/settings",
    );
    assert.equal(
      await page.getByRole("button", { name: "Keluar dari akun" }).count(),
      1,
    );
    const size = await dialog.boundingBox();
    assert(
      size.x >= 0 &&
        size.y >= 0 &&
        size.x + size.width <= viewport.width &&
        size.y + size.height <= viewport.height,
    );
    for (const control of await dialog.locator("button, a, select").all())
      assert((await control.boundingBox()).height >= 48);
    await page.screenshot({ path: `${output}/${name}-menu.png` });
    await page.keyboard.press("Escape");
    await dialog.waitFor({ state: "detached" });
    assert.equal(await menu.getAttribute("aria-expanded"), "false");
    await frame.waitForFunction(
      () => window.messages.at(-1)?.hostMenuOpen === false,
    );
    const contract = await frame.evaluate(() =>
      window.messages
        .filter((message) => message.type === "jalasmara:viewport")
        .at(-1),
    );
    assert.equal(contract.width, viewport.width);
    assert.equal(contract.height, viewport.height);
    assert.equal(contract.reservedTopPx, contract.safeArea.top + 52);
    assert(!JSON.stringify(contract).match(/token|password|email|csrf/i));
    checks.push(
      `${name}:immersive-bounds-source-origin-contract-menu-focus-48px-targets`,
    );
    await menu.click();
    await page.getByRole("button", { name: "Lanjut bermain" }).click();
    assert(
      await page
        .locator("iframe")
        .evaluate((element) => document.activeElement === element),
    );
    if (name === "portrait") {
      await page.setViewportSize({ width: 844, height: 390 });
      await frame.waitForFunction(
        () =>
          window.messages.at(-1)?.width === 844 &&
          window.messages.at(-1)?.height === 390,
      );
      const resized = await main.boundingBox();
      assert.equal(resized.width, 844);
      assert.equal(resized.height, 390);
      checks.push(
        "resize:portrait-to-landscape-contract-and-bounds-update-resume-returns-focus",
      );
    }
    if (!touch) {
      await menu.click();
      await full.click();
      await page.waitForFunction(() =>
        document.fullscreenElement?.classList.contains("immersive-player"),
      );
      const leave = page.getByRole("button", {
        name: "Keluar layar penuh",
        exact: true,
      });
      await leave.waitFor();
      assert.equal(await leave.getAttribute("aria-pressed"), "true");
      await leave.click();
      await page.waitForFunction(() => document.fullscreenElement === null);
      await full.waitFor();
      // An external browser exit must also restore the label from actual DOM state.
      await full.click();
      await page.waitForFunction(() => document.fullscreenElement !== null);
      await page.evaluate(() => document.exitFullscreen());
      await full.waitFor();
      await page.evaluate(() => {
        document.querySelector(".immersive-player").requestFullscreen = () =>
          Promise.reject(new Error("denied fixture"));
      });
      await full.click();
      await page
        .getByRole("status")
        .filter({ hasText: "tidak dapat dibuka" })
        .waitFor();
      assert.equal(await full.getAttribute("aria-pressed"), "false");
      await page.evaluate(() =>
        Object.defineProperty(document, "fullscreenEnabled", {
          configurable: true,
          value: false,
        }),
      );
      await full.click();
      await page
        .getByRole("status")
        .filter({ hasText: "belum mendukung" })
        .waitFor();
      checks.push(
        "fullscreen:real-entry-button-exit-external-exit-rejection-unsupported-fallback",
      );
      await page.reload();
      await menu.click();
      assert.equal(
        await page.getByLabel("Kualitas dunia", { exact: true }).inputValue(),
        "balanced",
      );
      const loadedFrame = page
        .frames()
        .find((frame) => frame.url().endsWith("/game/index.html"));
      await loadedFrame.waitForFunction(() =>
        window.messages.some(
          (message) => message.graphicsQuality === "balanced",
        ),
      );
      checks.push(
        "quality:selection-persists-after-reload-and-reaches-engine-contract",
      );
    }
    await context.close();
    context = null;
  }
  assert.deepEqual(errors, []);
  console.log(JSON.stringify({ checks, errors }, null, 2));
} finally {
  if (context) await context.close();
  await browser.close();
  writeFileSync(
    `${output}/results.json`,
    JSON.stringify({ checks, errors }, null, 2),
  );
}
