// The game and authenticated session are fixtures; no player or world data is touched.
import { chromium } from "@playwright/test";
import assert from "node:assert/strict";
import { mkdirSync, writeFileSync } from "node:fs";

const origin = process.env.PLAY_HOST_ORIGIN ?? "http://localhost:5175";
assert(["localhost", "127.0.0.1"].includes(new URL(origin).hostname));
const shortOnly = process.env.LOADING_SHORT_ONLY === "1";
const shortCase = process.env.LOADING_SHORT_CASE ?? "all";
assert(["all", "844", "932"].includes(shortCase));
const output = shortOnly
  ? `artifacts/browser/website-loading-short-${Date.now()}`
  : "artifacts/browser/website-loading";
mkdirSync(output, { recursive: true });
const browser = await chromium.launch();
const checks = [],
  errors = [];
try {
  const viewports = shortOnly
    ? [
        ["short-844", { width: 844, height: 320 }, true, "reduce"],
        ["short-932", { width: 932, height: 280 }, true, "reduce"],
      ]
    : [
        ["desktop", { width: 1440, height: 900 }, false, "no-preference"],
        ["landscape", { width: 667, height: 375 }, true, "no-preference"],
        ["portrait", { width: 390, height: 844 }, true, "no-preference"],
        ["reduced-motion", { width: 1024, height: 768 }, false, "reduce"],
      ];
  for (const [name, viewport, touch, reducedMotion] of viewports.filter(
    ([name]) =>
      !shortOnly || shortCase === "all" || name === `short-${shortCase}`,
  )) {
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
    const shortLayout = async (phase) => {
      if (!shortOnly) return;
      const panel = page.locator(".harbor-loading-panel");
      const scroll = await panel.evaluate((element) => ({
        top: element.scrollTop,
        overflow: element.scrollHeight - element.clientHeight,
      }));
      if (scroll.overflow > 2) {
        const bounds = await panel.boundingBox();
        const cdp = await context.newCDPSession(page);
        try {
          const x = bounds.x + bounds.width - 24;
          const start = bounds.y + bounds.height - 20;
          const end = bounds.y + 36;
          await cdp.send("Input.dispatchTouchEvent", {
            type: "touchStart",
            touchPoints: [{ x, y: start, id: 1 }],
          });
          for (let i = 1; i <= 8; i++) {
            await cdp.send("Input.dispatchTouchEvent", {
              type: "touchMove",
              touchPoints: [{ x, y: start + ((end - start) * i) / 8, id: 1 }],
            });
          }
          await cdp.send("Input.dispatchTouchEvent", {
            type: "touchEnd",
            touchPoints: [],
          });
          await panel.evaluate((element) => element.scrollTop);
          await page.waitForFunction(
            () => document.querySelector(".harbor-loading-panel").scrollTop > 0,
          );
        } finally {
          await cdp.detach();
        }
      }
      await page.screenshot({
        path: `${output}/${name}-${phase}-controls.png`,
      });
      const measured = await page.evaluate(() => {
        const rect = (element) => {
          const r = element.getBoundingClientRect();
          return {
            x: r.x,
            y: r.y,
            right: r.right,
            bottom: r.bottom,
            width: r.width,
            height: r.height,
          };
        };
        const panel = document.querySelector(".harbor-loading-panel");
        return {
          panel: rect(panel),
          menu: rect(document.querySelector(".play-menu-toggle")),
          controls: [...panel.querySelectorAll("button,a")].map(rect),
          scrollTop: panel.scrollTop,
          scrollHeight: panel.scrollHeight,
          clientHeight: panel.clientHeight,
          body: [...panel.querySelectorAll("p")].map((p) =>
            parseFloat(getComputedStyle(p).fontSize),
          ),
        };
      });
      const inside = (r) =>
        r.x >= 0 &&
        r.y >= 0 &&
        r.right <= viewport.width &&
        r.bottom <= viewport.height;
      assert(
        inside(measured.panel),
        `${name}/${phase}: panel outside viewport ${JSON.stringify(measured)}`,
      );
      assert(
        measured.controls.every(
          (r) =>
            inside(r) &&
            r.height >= 48 &&
            r.y >= measured.panel.y &&
            r.bottom <= measured.panel.bottom,
        ),
        `${name}/${phase}: retry/link touch target clipped`,
      );
      const p = measured.panel,
        m = measured.menu;
      assert(
        p.right <= m.x || p.x >= m.right || p.bottom <= m.y || p.y >= m.bottom,
        `${name}/${phase}: loading panel overlaps Menu ${JSON.stringify(measured)}`,
      );
      assert(measured.body.every((font) => font >= 16));
      if (scroll.overflow > 2)
        assert(
          measured.scrollTop > scroll.top,
          "Actual touch gesture must reveal overflowing controls",
        );
      checks.push({
        label: `${name}: ${phase} viewport containment, Menu clearance, 48px controls,16px body`,
        measured,
      });
      await page.getByRole("button", { name: "Menu", exact: true }).tap();
      await page.getByRole("dialog").waitFor();
      await page.keyboard.press("Escape");
      await page.getByRole("dialog").waitFor({ state: "detached" });
    };
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
    await shortLayout("stalled");
    if (shortOnly) await retry.tap();
    else await retry.click();
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
        .getByRole("link", { name: "Halaman utama", exact: true })
        .getAttribute("href"),
      "/",
    );
    await page.screenshot({ path: `${output}/${name}-error.png` });
    await shortLayout("error");
    const errorRetry = page.getByRole("button", {
      name: "Muat ulang permainan",
      exact: true,
    });
    if (shortOnly) await errorRetry.tap();
    else await errorRetry.click();
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
    JSON.stringify(
      {
        status: "passed",
        completed: true,
        output,
        shortOnly,
        shortCase,
        checks,
        errors,
      },
      null,
      2,
    ),
  );
  console.log(
    JSON.stringify(
      {
        status: "passed",
        completed: true,
        output,
        shortOnly,
        shortCase,
        checks,
        errors,
      },
      null,
      2,
    ),
  );
} catch (error) {
  writeFileSync(
    `${output}/results.json`,
    JSON.stringify(
      {
        status: "failed",
        completed: false,
        output,
        shortOnly,
        shortCase,
        message: error.message,
        checks,
        errors,
      },
      null,
      2,
    ),
  );
  throw error;
} finally {
  await browser.close();
}
