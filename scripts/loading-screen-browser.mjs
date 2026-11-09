// The game and authenticated session are fixtures; no player or world data is touched.
import { chromium } from "@playwright/test";
import assert from "node:assert/strict";
import { mkdirSync, writeFileSync } from "node:fs";

const origin = process.env.PLAY_HOST_ORIGIN ?? "http://localhost:5175";
assert(["localhost", "127.0.0.1"].includes(new URL(origin).hostname));
const output = "artifacts/browser/website-loading";
mkdirSync(output, { recursive: true });
const browser = await chromium.launch();
const checks = [],
  errors = [];
try {
  for (const [name, viewport, touch, reducedMotion] of [
    ["desktop", { width: 1440, height: 900 }, false, "no-preference"],
    ["landscape", { width: 667, height: 375 }, true, "no-preference"],
    ["portrait", { width: 390, height: 844 }, true, "no-preference"],
    ["reduced-motion", { width: 1024, height: 768 }, false, "reduce"],
  ]) {
    const context = await browser.newContext({
      viewport,
      hasTouch: touch,
      reducedMotion,
    });
    const page = await context.newPage();
    page.on("pageerror", (error) => errors.push(error.message));
    let requests = 0;
    await page.route("**/api/auth/session", (route) =>
      route.fulfill({
        json: {
          user: { role: "player" },
          csrf: "loading-fixture",
          oidcEnabled: false,
          linked: false,
        },
      }),
    );
    await page.route("**/game/index.html", (route) => {
      requests++;
      return route.fulfill({
        contentType: "text/html",
        body: '<!doctype html><html><body style="margin:0;background:#123735"><script>window.send=(data)=>parent.postMessage(data,location.origin);</script></body></html>',
      });
    });
    await page.goto(`${origin}/play`);
    const progress = page.getByRole("progressbar");
    await progress.waitFor();
    let frame = page
      .frames()
      .find((frame) => frame.url().endsWith("/game/index.html"));
    const emit = async (payload) =>
      frame.evaluate((data) => window.send(data), payload);
    const message = (downloadedBytes, totalBytes, phase = "downloading") => ({
      type: "jalasmara:loading",
      version: 1,
      phase,
      downloadedBytes,
      totalBytes,
    });

    assert.equal(
      await progress.getAttribute("value"),
      null,
      "Unknown size must not fabricate a percentage",
    );
    await emit(message(3_000_000, null));
    await page
      .getByText("3 MB diunduh. Ukuran total belum tersedia.", { exact: true })
      .waitFor();
    assert.equal(await progress.getAttribute("value"), null);
    await emit(message(25_000_000, 100_000_000));
    await page.getByText("25%", { exact: true }).waitFor();
    assert.equal(await progress.getAttribute("value"), "25");
    checks.push(
      `${name}: genuine bytes, known percentage and unknown-size indeterminate`,
    );

    for (const [source, eventOrigin, data] of [
      ["window", origin, message(90, 100)],
      ["iframe", "https://untrusted.invalid", message(90, 100)],
      ["iframe", origin, { ...message(90, 100), version: 2 }],
      ["iframe", origin, message(110, 100)],
      ["iframe", origin, message(-1, 100)],
      ["iframe", origin, message(Number.NaN, 100)],
      ["iframe", origin, { ...message(90, 100), totalBytes: "100" }],
    ]) {
      await page.evaluate(
        ({ source, eventOrigin, data }) => {
          dispatchEvent(
            new MessageEvent("message", {
              source:
                source === "window"
                  ? window
                  : document.querySelector("iframe").contentWindow,
              origin: eventOrigin,
              data,
            }),
          );
        },
        { source, eventOrigin, data },
      );
    }
    assert.equal(
      await progress.getAttribute("value"),
      "25",
      "Invalid messages must not alter real download progress",
    );
    checks.push(
      `${name}: rejects sibling, foreign origin, wrong version and invalid byte counts`,
    );

    await page.screenshot({ path: `${output}/${name}-download.png` });
    assert.equal(
      await page.evaluate(
        () => document.documentElement.scrollWidth > innerWidth,
      ),
      false,
    );
    const layout = await page
      .locator(".harbor-loading-panel")
      .evaluate((element) => {
        const rect = element.getBoundingClientRect();
        return {
          x: rect.x,
          y: rect.y,
          right: rect.right,
          bottom: rect.bottom,
          font: parseFloat(
            getComputedStyle(element.querySelector("p")).fontSize,
          ),
          scroll: element.scrollHeight,
          height: element.clientHeight,
        };
      });
    assert(
      layout.x >= 0 &&
        layout.y >= 52 &&
        layout.right <= viewport.width &&
        layout.bottom <= viewport.height,
    );
    assert(layout.font >= 16);
    assert(layout.scroll <= layout.height + 2);
    await page.mouse.move(1200, 100);
    const motion = await page
      .locator(".harbor-loading-harbor")
      .evaluate((element) => ({
        animation: getComputedStyle(element).animationName,
        transform: getComputedStyle(element).transform,
      }));
    if (touch || reducedMotion === "reduce") {
      assert.equal(motion.animation, "none");
      assert.equal(motion.transform, "none");
    } else assert.equal(motion.animation, "harbor-tide");
    checks.push(
      `${name}: responsive 16px text, zero overflow, appropriate motion preference`,
    );

    await emit(message(100_000_000, 100_000_000));
    await page.getByText("100%", { exact: true }).waitFor();
    assert.equal(
      await page.locator(".game-loading").count(),
      1,
      "Download 100% is not world readiness",
    );
    await emit(message(0, null, "preparing"));
    await page
      .getByText("Menyiapkan dunia petualangan", { exact: true })
      .waitFor();
    assert.equal(await progress.getAttribute("value"), null);
    await emit(message(50, 100));
    assert.equal(
      await page
        .getByText("Menyiapkan dunia petualangan", { exact: true })
        .count(),
      1,
      "Late transfer progress cannot downgrade preparation",
    );
    checks.push(
      `${name}: download completion stays covered until actual world-ready event`,
    );

    await page.clock.install();
    await page.clock.fastForward(32_000);
    const retry = page.getByRole("button", {
      name: "Muat ulang permainan",
      exact: true,
    });
    await retry.waitFor();
    await page
      .getByText("Belum ada pembaruan pemuatan.", { exact: false })
      .waitFor();
    const retryBounds = await retry.boundingBox();
    assert(retryBounds.height >= 48);
    await page.screenshot({ path: `${output}/${name}-stalled.png` });
    await retry.click();
    await page.waitForFunction(
      () => document.querySelector("iframe")?.contentWindow?.send !== undefined,
    );
    frame = page
      .frames()
      .find((frame) => frame.url().endsWith("/game/index.html"));
    assert.equal(await page.locator("iframe").count(), 1);
    assert.equal(requests, 2);
    assert.equal(
      await page
        .getByRole("button", { name: "Muat ulang permainan", exact: true })
        .count(),
      0,
    );
    checks.push(
      `${name}: stalled state offers accessible retry and replaces exactly one iframe`,
    );

    await emit(message(0, null, "error"));
    await page
      .getByRole("heading", { name: "Perjalanan belum dapat dimulai" })
      .waitFor();
    assert.equal(await page.getByRole("progressbar").count(), 0);
    assert.equal(
      await page
        .getByRole("link", { name: "Buka di tab ini", exact: true })
        .getAttribute("href"),
      "/game/index.html",
    );
    await page.screenshot({ path: `${output}/${name}-error.png` });
    await page
      .getByRole("button", { name: "Muat ulang permainan", exact: true })
      .click();
    await page.waitForFunction(
      () => document.querySelector("iframe")?.contentWindow?.send !== undefined,
    );
    frame = page
      .frames()
      .find((frame) => frame.url().endsWith("/game/index.html"));
    assert.equal(requests, 3);
    await emit({ type: "jalasmara:ready" });
    await page.locator(".game-loading").waitFor({ state: "detached" });
    assert.equal(await page.locator(".landscape-hint").count(), 0);
    checks.push(
      `${name}: failure has real recovery and readiness removes the full overlay`,
    );
    await context.close();
  }
  assert.deepEqual(errors, []);
  writeFileSync(
    `${output}/results.json`,
    JSON.stringify({ checks, errors }, null, 2),
  );
  console.log(JSON.stringify({ checks, errors }, null, 2));
} finally {
  await browser.close();
}
