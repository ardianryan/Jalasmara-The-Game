// Local compiled-host proof. All account/API responses are isolated fixtures.
import assert from "node:assert/strict";
import { createServer } from "node:http";
import { readFileSync, mkdirSync, writeFileSync } from "node:fs";
import { resolve, extname } from "node:path";
import { gzipSync } from "node:zlib";
import { build } from "vite";
import { chromium } from "@playwright/test";

const root = resolve("apps/web");
const directory = `artifacts/browser/admin-chunk-${Date.now()}`;
mkdirSync(directory, { recursive: true });
const built = await build({
  root,
  configFile: resolve(root, "vite.config.ts"),
  publicDir: false,
  build: { write: false, manifest: true },
});
assert(!Array.isArray(built));
const outputs = new Map(
  built.output.map((asset) => [
    `/${asset.fileName}`,
    Buffer.from(asset.type === "chunk" ? asset.code : asset.source),
  ]),
);
const chunks = built.output.filter((asset) => asset.type === "chunk");
const entry = chunks.find((asset) => asset.isEntry);
const admin = chunks.find(
  (asset) => asset.facadeModuleId === resolve(root, "src/admin.tsx"),
);
assert(entry && admin && entry.fileName !== admin.fileName);
assert(!entry.imports.includes(admin.fileName));
assert(entry.dynamicImports.includes(admin.fileName));
const mainPath = resolve(root, "src/main.tsx");
const mainSource = readFileSync(mainPath, "utf8");
assert(mainSource.includes('import { AdminRoute } from "./AdminRoute";'));
assert(mainSource.includes("<AdminRoute auth={auth} />"));
const eagerMain = mainSource
  .replace(
    'import { AdminRoute } from "./AdminRoute";',
    'import { Admin } from "./admin";',
  )
  .replace("<AdminRoute auth={auth} />", "<Admin auth={auth} />");
const eagerBuild = await build({
  root,
  configFile: resolve(root, "vite.config.ts"),
  publicDir: false,
  plugins: [
    {
      name: "eager-admin-comparison",
      enforce: "pre",
      load(id) {
        return id === mainPath ? eagerMain : null;
      },
    },
  ],
  build: { write: false },
});
assert(!Array.isArray(eagerBuild));
const eagerEntry = eagerBuild.output.find(
  (asset) => asset.type === "chunk" && asset.isEntry,
);
assert(eagerEntry);
const baseline = Buffer.from(eagerEntry.code);
const sizes = {
  baselineEntry: baseline.length,
  baselineGzip: gzipSync(baseline, { level: 9 }).length,
  candidateEntry: Buffer.byteLength(entry.code),
  candidateGzip: gzipSync(entry.code, { level: 9 }).length,
  deferredAdmin: Buffer.byteLength(admin.code),
  deferredAdminGzip: gzipSync(admin.code, { level: 9 }).length,
};
assert(sizes.candidateEntry < sizes.baselineEntry);
assert(sizes.candidateGzip < sizes.baselineGzip);
const mime = {
  ".html": "text/html",
  ".js": "text/javascript",
  ".css": "text/css",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
};
const server = createServer((request, response) => {
  const pathname = new URL(request.url, "http://localhost").pathname;
  let body = outputs.get(pathname);
  let type = mime[extname(pathname)];
  if (!body && !extname(pathname)) {
    body = outputs.get("/index.html");
    type = "text/html";
  }
  if (
    !body &&
    (pathname === "/brand/symbol.svg" || pathname.startsWith("/art/"))
  ) {
    const path = resolve(root, "public", `.${pathname}`);
    if (path.startsWith(`${resolve(root, "public")}/`)) {
      try {
        body = readFileSync(path);
      } catch {
        /* Missing art remains a real 404. */
      }
    }
  }
  response.writeHead(body ? 200 : 404, {
    "Content-Type": type ?? "application/octet-stream",
    "Cache-Control": "no-store",
  });
  response.end(body ?? "Not found");
});
await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const origin = `http://127.0.0.1:${server.address().port}`;
const checks = [],
  errors = [];
let browser,
  failure = null,
  completed = false;
const cleanup = { browser: false, server: false };
async function fixture(role, viewport = { width: 390, height: 844 }) {
  const context = await browser.newContext({ viewport });
  const page = await context.newPage();
  const requests = [],
    apiRequests = [];
  page.on("request", (request) =>
    requests.push(new URL(request.url()).pathname),
  );
  page.on("pageerror", (error) => errors.push(error.message));
  await page.route("**/game/index.html*", (route) =>
    route.fulfill({
      contentType: "text/html",
      body: "<!doctype html><title>Host route fixture</title>",
    }),
  );
  await page.route("**/api/**", (route) => {
    const pathname = new URL(route.request().url()).pathname;
    apiRequests.push({ pathname, method: route.request().method() });
    if (pathname === "/api/auth/session")
      return route.fulfill({
        json: {
          user: role
            ? {
                id: "chunk-fixture",
                name: "Pengelola Uji",
                email: "chunk@test.invalid",
                role,
              }
            : null,
          csrf: "chunk-fixture",
          oidcEnabled: false,
          linked: false,
        },
      });
    if (pathname === "/api/admin/players")
      return route.fulfill({ json: { players: [], total: 0 } });
    return route.fulfill({
      status: 404,
      json: { error: "No fixture for this endpoint" },
    });
  });
  return { context, page, requests, apiRequests };
}
async function fits(page, label) {
  const measurement = await page.evaluate(() => ({
    width: innerWidth,
    scroll: document.documentElement.scrollWidth,
  }));
  assert(
    measurement.scroll <= measurement.width + 1,
    `${label} overflow ${JSON.stringify(measurement)}`,
  );
}
try {
  browser = await chromium.launch();
  for (const [role, path, heading] of [
    [null, "/", "Pulang ke Bandar."],
    ["player", "/admin", "Akses terbatas"],
    ["player", "/settings", "Pengaturan akun"],
    ["owner", "/settings", "Pengaturan akun"],
  ]) {
    const f = await fixture(role);
    try {
      await f.page.goto(`${origin}${path}`);
      await f.page
        .getByRole("heading", { name: heading, exact: true })
        .waitFor();
      assert(!f.requests.includes(`/${admin.fileName}`));
      assert(
        !f.apiRequests.some((request) =>
          request.pathname.startsWith("/api/admin/"),
        ),
      );
      await fits(f.page, `${role} ${path}`);
      checks.push(`no-admin-chunk-or-api:${role ?? "guest"}:${path}`);
    } finally {
      await f.context.close();
    }
  }
  {
    const f = await fixture("player", { width: 844, height: 390 });
    try {
      await f.page.goto(`${origin}/play`);
      await f.page.locator("iframe").waitFor();
      assert(!f.requests.includes(`/${admin.fileName}`));
      checks.push("player-host-route-does-not-fetch-admin-chunk");
    } finally {
      await f.context.close();
    }
  }
  {
    const f = await fixture("owner");
    let release;
    const held = new Promise((resolve) => {
      release = resolve;
    });
    await f.page.route(`**/${admin.fileName}`, async (route) => {
      await held;
      await route.continue();
    });
    try {
      await f.page.goto(`${origin}/admin`, { waitUntil: "domcontentloaded" });
      await f.page
        .getByRole("status")
        .filter({ hasText: "Menyiapkan ingatan…" })
        .waitFor();
      assert(
        !f.apiRequests.some((request) =>
          request.pathname.startsWith("/api/admin/"),
        ),
      );
      await fits(f.page, "admin-loading");
      await f.page.screenshot({ path: `${directory}/admin-loading.png` });
      checks.push(
        "authorized-admin-has-real-chunk-loading-fallback-before-api",
      );
      release();
      await f.page
        .getByRole("heading", { name: "Pemain", exact: true })
        .waitFor();
      assert(f.requests.includes(`/${admin.fileName}`));
      assert(
        f.apiRequests.some(
          (request) => request.pathname === "/api/admin/players",
        ),
      );
      await fits(f.page, "admin-loaded");
      checks.push(
        "authorized-admin-loads-deferred-chunk-and-existing-players-screen",
      );
    } finally {
      release();
      await f.context.close();
    }
  }
  {
    const f = await fixture("owner", { width: 667, height: 375 });
    let fail = true;
    await f.page.route(`**/${admin.fileName}`, (route) =>
      fail
        ? route.fulfill({
            status: 503,
            contentType: "text/plain",
            body: "Injected chunk transport failure",
          })
        : route.continue(),
    );
    try {
      await f.page.goto(`${origin}/admin`);
      await f.page
        .getByRole("heading", {
          name: "Pengelola belum dapat dibuka",
          exact: true,
        })
        .waitFor();
      await f.page.getByRole("alert").waitFor();
      assert(
        !f.apiRequests.some((request) =>
          request.pathname.startsWith("/api/admin/"),
        ),
      );
      await fits(f.page, "admin-chunk-error");
      await f.page.screenshot({ path: `${directory}/admin-chunk-error.png` });
      checks.push(
        "failed-chunk-shows-actionable-error-without-admin-api-or-write",
      );
      fail = false;
      await f.page
        .getByRole("button", { name: "Muat ulang halaman", exact: true })
        .click();
      await f.page
        .getByRole("heading", { name: "Pemain", exact: true })
        .waitFor();
      assert(
        f.requests.filter((path) => path === `/${admin.fileName}`).length >= 2,
      );
      checks.push("reload-retries-real-failed-module-and-restores-admin");
    } finally {
      await f.context.close();
    }
  }
  assert.deepEqual(errors, []);
  completed = true;
} catch (error) {
  failure = { name: error.name, message: error.message };
  throw error;
} finally {
  try {
    await browser?.close();
    cleanup.browser = true;
  } catch (error) {
    errors.push(`Browser shutdown: ${error.message}`);
  }
  try {
    await new Promise((resolve, reject) =>
      server.close((error) => (error ? reject(error) : resolve())),
    );
    cleanup.server = true;
  } catch (error) {
    errors.push(`Server shutdown: ${error.message}`);
  }
  writeFileSync(
    `${directory}/results.json`,
    JSON.stringify(
      {
        outcome: completed && errors.length === 0 ? "passed" : "failed",
        completed,
        failure,
        cleanup,
        checks,
        errors,
        sizes,
        compiledChunks: chunks.map(({ fileName, isEntry }) => ({
          fileName,
          isEntry,
        })),
        limits:
          "Local production-compiled host with intercepted API fixtures and empty game iframe. No database writes, actual Godot startup, public deployment, FPS, physical-device or post-mount draft-recovery claims.",
      },
      null,
      2,
    ),
  );
  if (completed)
    assert.deepEqual(errors, [], "Browser/server cleanup must succeed");
}
console.log(JSON.stringify({ checks: checks.length, errors, sizes }));
