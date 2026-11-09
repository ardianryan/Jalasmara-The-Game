// Explicit transport diagnostic: one real asset, drained without the game or authentication.
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { mkdirSync, writeFileSync } from "node:fs";
import { chromium } from "@playwright/test";

assert.equal(process.env.STAGING_TRANSPORT_DIAGNOSTIC, "plan06-read");
assert(!process.env.BROWSER_FIXTURE);
const mode = process.env.PLAN06_TRANSPORT_ASSET;
assert(["pck", "wasm"].includes(mode));
const origin = "https://staging-jalasmara.ardianryan.com";
const asset = `${origin}/game/index.${mode}`;
const range = process.env.PLAN06_TRANSPORT_RANGE ?? null;
assert(range === null || (mode === "pck" && range === "bytes=0-"));
const protocol = process.env.PLAN06_TRANSPORT_PROTOCOL ?? "default";
assert(["default", "http1"].includes(protocol));
const documentUrl = `${origin}/__qa_transport_blank`;
const id = randomUUID(),
  directory = `artifacts/browser/transport-${mode}-${id}`;
mkdirSync(directory, { recursive: true });
const transfers = [],
  requests = [],
  errors = [],
  samples = [];
let browser,
  context,
  page,
  consumer,
  failure = null;
const started = Date.now();
try {
  browser = await chromium.launch({
    args: [
      "--enable-webgl",
      "--use-gl=angle",
      "--use-angle=swiftshader",
      "--enable-unsafe-swiftshader",
      ...(protocol === "http1" ? ["--disable-http2"] : []),
    ],
  });
  context = await browser.newContext({
    viewport: { width: 844, height: 390 },
    hasTouch: true,
    isMobile: true,
    deviceScaleFactor: 1,
  });
  await context.route("**/*", (route) => {
    const url = route.request().url();
    requests.push({
      path: new URL(url).pathname,
      synthetic: url === documentUrl,
    });
    if (url === documentUrl)
      return route.fulfill({
        contentType: "text/html",
        body: '<!doctype html><meta charset="utf-8"><title>Transport diagnostic</title>',
      });
    if (url === asset) return route.continue();
    return route.abort("blockedbyclient");
  });
  page = await context.newPage();
  page.on("pageerror", (error) =>
    errors.push({ name: error.name, message: error.message }),
  );
  const cdp = await context.newCDPSession(page),
    tracked = new Map();
  await cdp.send("Network.enable");
  await cdp.send("Network.setCacheDisabled", { cacheDisabled: true });
  cdp.on("Network.requestWillBeSent", (event) => {
    if (event.request.url !== asset) return;
    const value = {
      at: Date.now(),
      decodedDataLength: 0,
      encodedDataLength: 0,
    };
    tracked.set(event.requestId, value);
    transfers.push(value);
  });
  cdp.on("Network.responseReceived", (event) => {
    const value = tracked.get(event.requestId);
    if (!value) return;
    const headers = Object.fromEntries(
      Object.entries(event.response.headers).map(([key, val]) => [
        key.toLowerCase(),
        val,
      ]),
    );
    Object.assign(value, {
      status: event.response.status,
      protocol: event.response.protocol,
      remoteIPAddress: event.response.remoteIPAddress,
      remotePort: event.response.remotePort,
      fromDiskCache: event.response.fromDiskCache,
      fromServiceWorker: event.response.fromServiceWorker,
      headers: Object.fromEntries(
        [
          "content-encoding",
          "content-length",
          "content-type",
          "cache-control",
          "vary",
          "server",
        ]
          .filter((key) => key in headers)
          .map((key) => [key, headers[key]]),
      ),
    });
  });
  cdp.on("Network.dataReceived", (event) => {
    const value = tracked.get(event.requestId);
    if (!value) return;
    value.decodedDataLength += event.dataLength;
    value.encodedDataLength += event.encodedDataLength;
  });
  cdp.on("Network.loadingFinished", (event) => {
    const value = tracked.get(event.requestId);
    if (value)
      Object.assign(value, {
        finishedAt: Date.now(),
        finishedEncodedDataLength: event.encodedDataLength,
      });
  });
  cdp.on("Network.loadingFailed", (event) => {
    const value = tracked.get(event.requestId);
    if (value)
      Object.assign(value, {
        failedAt: Date.now(),
        error: event.errorText,
        cancelled: event.canceled,
      });
  });
  await page.goto(documentUrl, { waitUntil: "load", timeout: 15000 });
  assert.equal(await page.locator("iframe,canvas,script").count(), 0);
  const timer = setInterval(() => {
    const sample = {
      at: Date.now(),
      transfers: transfers.map((value) => ({ ...value })),
    };
    samples.push(sample);
    console.log(JSON.stringify(sample));
  }, 5000);
  try {
    consumer = await Promise.race([
      page.evaluate(
        async ({ url, range }) => {
          const controller = new AbortController(),
            begin = performance.now();
          const timeout = setTimeout(() => controller.abort(), 20000);
          let bytes = 0,
            chunks = 0,
            status,
            headers,
            outcome;
          try {
            const response = await fetch(url, {
              signal: controller.signal,
              cache: "no-store",
              headers: range ? { Range: range } : undefined,
            });
            status = response.status;
            headers = Object.fromEntries(
              ["content-encoding", "content-length", "content-type"].map(
                (key) => [key, response.headers.get(key)],
              ),
            );
            if (!response.ok)
              throw new Error("Asset response was not successful");
            const reader = response.body.getReader();
            while (true) {
              const part = await reader.read();
              if (part.done) {
                outcome = "body-completed";
                break;
              }
              bytes += part.value.byteLength;
              chunks++;
            }
          } catch (error) {
            outcome = controller.signal.aborted
              ? "aborted-at-20-second-budget"
              : "body-failed";
            if (!controller.signal.aborted)
              return {
                outcome,
                name: error.name,
                status,
                headers,
                decodedBytesRead: bytes,
                chunks,
                elapsedMs: performance.now() - begin,
              };
          } finally {
            clearTimeout(timeout);
          }
          return {
            outcome,
            status,
            headers,
            decodedBytesRead: bytes,
            chunks,
            elapsedMs: performance.now() - begin,
          };
        },
        { url: asset, range },
      ),
      new Promise((_, reject) =>
        setTimeout(
          () =>
            reject(
              new Error("Diagnostic consumer exceeded 25-second hard bound"),
            ),
          25000,
        ),
      ),
    ]);
  } finally {
    clearInterval(timer);
  }
  await page.waitForTimeout(200);
  assert.equal(requests.filter((request) => !request.synthetic).length, 1);
  assert.equal(transfers.length, 1);
  assert([200, 206].includes(consumer.status));
  assert(consumer.decodedBytesRead > 0);
  assert.deepEqual(errors, []);
} catch (error) {
  failure = { name: error.name, message: error.message };
  throw error;
} finally {
  let closed = false;
  try {
    await browser?.close();
    closed = true;
  } finally {
    const result = {
      diagnosticOnly: true,
      gameplayAccepted: false,
      origin,
      asset: `/game/index.${mode}`,
      requestRange: range,
      requestedProtocol: protocol,
      budgetMs: 20000,
      consumer,
      transfers,
      samples,
      requests,
      errors,
      failure,
      browserClosed: closed,
      fixtureCreated: false,
      elapsedMs: Date.now() - started,
    };
    writeFileSync(`${directory}/results.json`, JSON.stringify(result, null, 2));
    console.log(JSON.stringify({ directory, ...result }, null, 2));
  }
}
