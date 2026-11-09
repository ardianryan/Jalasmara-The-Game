// Run against a local Vite server. All API routes are isolated fixtures.
import { chromium } from "@playwright/test";
import assert from "node:assert/strict";
import { mkdirSync, writeFileSync } from "node:fs";

const origin = process.env.WEBSITE_TEST_ORIGIN ?? "http://localhost:5176";
assert(["localhost", "127.0.0.1"].includes(new URL(origin).hostname));
const output = "artifacts/browser/website06";
mkdirSync(output, { recursive: true });
const checks = [],
  errors = [];
const browser = await chromium.launch();
const longName = "Pengelola Bandar Hujung dengan nama yang panjang";
const longEmail = `${"pemain".repeat(12)}@test.invalid`;
const question = {
  id: "q1",
  subject: "Biologi",
  phase: 1,
  difficulty: 1,
  prompt: "Apa fungsi klorofil pada tumbuhan?",
  options: ["A", "B", "C", "D"],
  correctIndex: 0,
  explanation: "Klorofil menyerap cahaya.",
  source: "https://openstax.org/details/books/biology-2e",
  timeLimitMs: 15000,
  fragmentId: "klorofil",
};
const catalog = {
  questions: [question],
  fragments: [],
  abilities: [],
  recipes: [],
  balance: {},
};
let context;

async function fits(page, label) {
  const widths = await page.evaluate(() => ({
    viewport: innerWidth,
    document: document.documentElement.scrollWidth,
  }));
  assert(
    widths.document <= widths.viewport + 1,
    `${label}: ${JSON.stringify(widths)}`,
  );
  checks.push({ label, ...widths });
}
async function fixture(viewport, role = "owner") {
  context = await browser.newContext({ viewport });
  const page = await context.newPage();
  page.on("pageerror", (error) => errors.push(error.message));
  const state = {
    role,
    failPlayers: false,
    slowActive: false,
    firstLoad: false,
    requests: [],
    accountActions: 0,
  };
  await page.route("**/api/**", async (route) => {
    const url = new URL(route.request().url()),
      path = url.pathname;
    state.requests.push({ path, query: url.search });
    if (path === "/api/auth/session")
      return route.fulfill({
        json: {
          user: state.role
            ? {
                id: "website-fixture",
                name: longName,
                email: longEmail,
                role: state.role,
              }
            : null,
          csrf: "website-fixture",
          oidcEnabled: true,
          oidcLabel: "Sekolah",
          linked: true,
        },
      });
    if (path === "/api/auth/login")
      return route.fulfill({
        status: 401,
        json: { error: "Email atau password belum sesuai." },
      });
    if (path === "/api/auth/logout")
      return route.fulfill({
        status: 503,
        json: { error: "Layanan sementara tidak tersedia." },
      });
    if (path === "/api/auth/reauth") {
      state.accountActions++;
      return route.fulfill({ json: {} });
    }
    if (path === "/api/auth/oidc/unlink") {
      state.accountActions++;
      return route.fulfill({
        status: 503,
        json: { error: "Identitas belum dapat dilepas. Coba lagi." },
      });
    }
    if (path === "/api/admin/players") {
      if (!state.firstLoad) {
        await new Promise((resolve) => setTimeout(resolve, 550));
        state.firstLoad = true;
      }
      if (state.failPlayers)
        return route.fulfill({
          status: 503,
          json: { error: "Daftar pemain belum dapat dimuat." },
        });
      const status = url.searchParams.get("status"),
        search = url.searchParams.get("search");
      if (state.slowActive && status === "active")
        await new Promise((resolve) => setTimeout(resolve, 500));
      return route.fulfill({
        json: {
          total: search === "kosong" ? 0 : 41,
          players:
            search === "kosong"
              ? []
              : [
                  {
                    id: `fixture-${status}`,
                    name:
                      status === "blocked"
                        ? "Hasil diblokir terbaru"
                        : status === "active"
                          ? "Hasil aktif terlambat"
                          : "Pemain fixture",
                    email: longEmail,
                    role: "player",
                    progress: { day: 1, stage: "dive" },
                    coins: 200,
                    status: status === "blocked" ? "blocked" : "active",
                  },
                ],
        },
      });
    }
    if (path === "/api/game/state") return route.fulfill({ json: { catalog } });
    if (path === "/api/admin/content")
      return route.fulfill({
        json: {
          versions: [
            {
              id: "fixture-draft",
              label: "Draft fixture",
              state: "draft",
              createdAt: "2026-11-09T00:00:00Z",
            },
          ],
        },
      });
    if (path === "/api/admin/content/fixture-draft")
      return route.fulfill({
        json: {
          hash: "fixture-hash",
          content: {
            id: "fixture-draft",
            label: "Draft fixture",
            state: "draft",
            catalog,
          },
        },
      });
    if (path === "/api/admin/audit")
      return route.fulfill({ json: { total: 0, audits: [] } });
    throw new Error(`Unexpected fixture request: ${path}`);
  });
  await page.route(`${origin}/game/**`, (route) => route.abort());
  return { page, state };
}

try {
  for (const viewport of [
    { width: 1440, height: 900 },
    { width: 667, height: 375 },
    { width: 390, height: 844 },
    { width: 320, height: 740 },
  ]) {
    const { page, state } = await fixture(viewport);
    await page.goto(`${origin}/admin`);
    await page.getByText("Memuat daftar pemain…", { exact: true }).waitFor();
    assert.equal(
      await page
        .getByText("Tidak ada pemain yang cocok dengan pencarian.")
        .count(),
      0,
    );
    await page.getByText("Pemain fixture", { exact: true }).waitFor();
    await page.evaluate(() => document.fonts.ready);
    assert(await page.evaluate(() => document.fonts.check('400 16px "Nunito Sans"') && document.fonts.check('600 16px "Lora"')), "Local website fonts must load before captures");
    await fits(page, `admin ${viewport.width}`);
    const table = page.getByRole("region", { name: /Daftar pemain/ });
    await table.focus();
    assert(
      await table.evaluate((element) => element === document.activeElement),
    );
    const navTargets = await page
      .locator(".app-header nav a, .app-header nav button")
      .evaluateAll((elements) =>
        elements.map((element) => element.getBoundingClientRect().height),
      );
    assert(
      navTargets.every((height) => height >= 44),
      "Website navigation targets remain at least 44 CSS px",
    );
    await page.screenshot({
      path: `${output}/admin-${viewport.width}.png`,
      fullPage: true,
    });
    if (viewport.width === 1440) {
      await page
        .getByRole("button", { name: "Berikutnya", exact: true })
        .click();
      await page.getByText("Halaman 2", { exact: true }).waitFor();
      await page.locator('.table-scroll[aria-busy="false"]').waitFor();
      await page.getByLabel("Cari nama atau email").fill("Nala");
      const before = state.requests.length;
      await page.getByRole("button", { name: "Cari", exact: true }).click();
      await page.getByText("Halaman 1", { exact: true }).waitFor();
      await page.locator('.table-scroll[aria-busy="false"]').waitFor();
      const searches = state.requests
        .slice(before)
        .filter((request) => request.path === "/api/admin/players");
      assert.equal(searches.length, 1);
      assert.equal(new URLSearchParams(searches[0].query).get("page"), "1");
      assert.equal(
        new URLSearchParams(searches[0].query).get("search"),
        "Nala",
      );
      checks.push({ label: "new search from page 2 requests only page 1" });
      state.slowActive = true;
      await page.getByRole("combobox", { name: /^Status/ }).selectOption("active");
      await page.getByRole("combobox", { name: /^Status/ }).selectOption("blocked");
      await page.getByText("Hasil diblokir terbaru", { exact: true }).waitFor();
      await page.waitForTimeout(650);
      assert.equal(
        await page.getByText("Hasil aktif terlambat", { exact: true }).count(),
        0,
      );
      checks.push({ label: "late list response cannot replace newer filter" });
      state.failPlayers = true;
      await page.getByRole("combobox", { name: /^Status/ }).selectOption("all");
      await page
        .getByRole("alert")
        .filter({ hasText: "Daftar pemain belum dapat dimuat." })
        .waitFor();
      state.failPlayers = false;
      await page.getByRole("button", { name: "Muat ulang pemain" }).click();
      await page.getByText("Pemain fixture", { exact: true }).waitFor();
      assert.equal(await page.getByRole("alert").count(), 0);
      await page.getByLabel("Cari nama atau email").fill("kosong");
      await page.getByRole("button", { name: "Cari", exact: true }).click();
      await page
        .getByText("Tidak ada pemain yang cocok dengan pencarian.")
        .waitFor();
      checks.push({ label: "list failure retry and real empty state" });
      await page
        .getByRole("button", { name: "Undang pemain", exact: true })
        .click();
      await page
        .getByRole("dialog", { name: "Undang pemain", exact: true })
        .waitFor();
      await page.keyboard.press("Escape");
      assert(
        await page
          .getByRole("button", { name: "Undang pemain", exact: true })
          .evaluate((element) => element === document.activeElement),
      );
      checks.push({ label: "native dialog Escape restores trigger focus" });
      await page
        .getByRole("button", { name: "Konten permainan", exact: true })
        .click();
      await page.getByRole("button", { name: "Buka", exact: true }).click();
      await page
        .getByLabel("Pertanyaan", { exact: true })
        .fill("Draft yang harus tetap tersimpan saat batal pindah.");
      page.once("dialog", (dialog) => dialog.dismiss());
      await page.getByRole("button", { name: "Pemain", exact: true }).click();
      assert.equal(
        await page.getByLabel("Pertanyaan", { exact: true }).inputValue(),
        "Draft yang harus tetap tersimpan saat batal pindah.",
      );
      page.once("dialog", (dialog) => dialog.accept());
      await page.getByRole("button", { name: "Pemain", exact: true }).click();
      await page
        .getByRole("heading", { name: "Pemain", exact: true })
        .waitFor();
      checks.push({
        label:
          "unsaved draft survives canceled tab change and discards only after confirmation",
      });
    }
    await page.goto(`${origin}/settings`);
    await page.getByRole("heading", { name: "Pengaturan akun" }).waitFor();
    await fits(page, `settings long identity ${viewport.width}`);
    await page.getByLabel("Password saat ini").fill("fixture-password-only");
    await page.getByRole("button", { name: "Konfirmasi password" }).click();
    await page.getByText(/Password dikonfirmasi/).waitFor();
    await page
      .getByRole("button", { name: "Lepas identitas tambahan" })
      .click();
    await page
      .getByRole("alert")
      .filter({ hasText: "Identitas belum dapat dilepas" })
      .waitFor();
    assert.equal(await page.getByText(/Password dikonfirmasi/).count(), 0);
    await page.getByRole("button", { name: "Keluar dari akun" }).click();
    await page
      .getByText(
        "Belum dapat keluar dari akun. Periksa koneksi lalu coba lagi.",
      )
      .waitFor();
    assert.equal(
      await page.getByRole("button", { name: "Keluar dari akun" }).isEnabled(),
      true,
    );
    await page.screenshot({
      path: `${output}/settings-${viewport.width}.png`,
      fullPage: true,
    });
    checks.push({
      label: `account error recovery and logout retry ${viewport.width}`,
      fixtureAccountRequests: state.accountActions,
    });
    state.role = null;
    await page.goto(origin);
    await page
      .getByLabel("Email", { exact: true })
      .fill("fixture@test.invalid");
    await page
      .getByLabel("Password", { exact: true })
      .fill("fixture-password-only");
    await page.getByRole("button", { name: "Masuk ke Jalasmara" }).click();
    await page.getByText("Email atau password belum sesuai.").waitFor();
    assert.equal(
      await page.getByLabel("Email", { exact: true }).inputValue(),
      "fixture@test.invalid",
    );
    await fits(page, `login ${viewport.width}`);
    await page.screenshot({
      path: `${output}/login-${viewport.width}.png`,
      fullPage: true,
    });
    for (const path of ["/reset", "/activate"]) {
      await page.goto(`${origin}${path}`);
      await page.getByText(/Tautan tidak lengkap/).waitFor();
      assert.equal(await page.locator("form").count(), 0);
      await fits(page, `${path} missing token ${viewport.width}`);
    }
    await context.close();
  }
  const { page } = await fixture({ width: 390, height: 844 }, "player");
  await page.goto(`${origin}/admin`);
  await page.getByRole("heading", { name: "Akses terbatas" }).waitFor();
  assert.equal(
    await page.getByRole("link", { name: "Pengelola", exact: true }).count(),
    0,
  );
  checks.push({ label: "player role cannot open admin interface" });
  await fits(page, "player forbidden admin");
  await context.close();
  assert.equal(errors.length, 0, errors.join("\n"));
  writeFileSync(
    `${output}/results.json`,
    JSON.stringify(
      {
        status: "pass",
        environment:
          "Playwright Chromium, emulated CSS viewports, local Vite with intercepted API; no real account, Godot or server transaction",
        checks,
        javascriptErrors: errors,
      },
      null,
      2,
    ),
  );
  console.log(
    `Website06: ${checks.length} checks passed, ${errors.length} JavaScript errors.`,
  );
} finally {
  await context?.close();
  await browser.close();
}
