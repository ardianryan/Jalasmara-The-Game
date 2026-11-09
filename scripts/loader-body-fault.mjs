import assert from "node:assert/strict";
import { createServer } from "node:http";

export async function startLoaderBodyFault({
  path,
  origin,
  totalBytes,
  prefix,
  packBytes,
  chunkBytes = 65536,
  chunkDelayMs = 60,
  abortDelayMs = 250,
}) {
  const part = path.match(/^\/game\/pck\/([a-f0-9]{64})\/(0|[1-9][0-9]{0,2})$/);
  assert(/^\/game\/index\.(pck|wasm)$/.test(path) || part);
  if (part) {
    assert(
      Number.isSafeInteger(packBytes) &&
        packBytes > 0 &&
        packBytes <= 512 * 1024 * 1024,
    );
    const offset = Number(part[2]) * 1024 * 1024;
    assert(
      offset < packBytes &&
        totalBytes === Math.min(1024 * 1024, packBytes - offset),
    );
  } else assert(packBytes === undefined);
  assert(["localhost", "127.0.0.1"].includes(new URL(origin).hostname));
  assert(
    Number.isSafeInteger(totalBytes) &&
      Buffer.isBuffer(prefix) &&
      prefix.length > 0 &&
      prefix.length < totalBytes,
  );
  assert(
    [chunkBytes, chunkDelayMs, abortDelayMs].every(
      (value) => Number.isSafeInteger(value) && value > 0,
    ),
  );
  const requests = [],
    sockets = new Set(),
    timers = new Set();
  const later = (callback, delay) => {
    const timer = setTimeout(() => {
      timers.delete(timer);
      callback();
    }, delay);
    timers.add(timer);
  };
  const server = createServer((request, response) => {
    response.on("error", () => {});
    if (request.url !== path || request.method !== "GET") {
      response.writeHead(404);
      response.end();
      return;
    }
    const record = {
      at: Date.now(),
      path,
      status: 200,
      declaredBytes: totalBytes,
      writtenBytes: 0,
      destroyedAt: null,
      ...(part ? { offset: Number(part[2]) * 1024 * 1024, packBytes } : {}),
    };
    requests.push(record);
    response.writeHead(200, {
      "content-type": path.endsWith("wasm")
        ? "application/wasm"
        : "application/octet-stream",
      "content-length": String(totalBytes),
      "cache-control": "no-store",
      "access-control-allow-origin": origin,
      "access-control-allow-credentials": "true",
      "cross-origin-resource-policy": "cross-origin",
      ...(part
        ? {
            "x-pck-offset": String(Number(part[2]) * 1024 * 1024),
            "x-pck-length": String(packBytes),
            "access-control-expose-headers":
              "Content-Length, X-Pck-Offset, X-Pck-Length",
          }
        : {}),
    });
    response.flushHeaders();
    const send = () => {
      if (response.destroyed) return;
      const end = Math.min(prefix.length, record.writtenBytes + chunkBytes);
      response.write(prefix.subarray(record.writtenBytes, end));
      record.writtenBytes = end;
      if (end < prefix.length) later(send, chunkDelayMs);
      else
        later(() => {
          if (!response.destroyed) {
            record.destroyedAt = Date.now();
            response.destroy();
          }
        }, abortDelayMs);
    };
    send();
  });
  server.on("connection", (socket) => {
    sockets.add(socket);
    socket.once("close", () => sockets.delete(socket));
  });
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  return {
    url: `http://127.0.0.1:${server.address().port}${path}`,
    requests,
    async close() {
      for (const timer of timers) clearTimeout(timer);
      timers.clear();
      const closing = [...sockets].map(
        (socket) =>
          new Promise((resolve) => {
            socket.once("close", resolve);
            socket.destroy();
          }),
      );
      await new Promise((resolve, reject) =>
        server.close((error) => (error ? reject(error) : resolve())),
      );
      await Promise.all(closing);
      assert.equal(sockets.size, 0);
    },
  };
}
