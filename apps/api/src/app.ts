import Fastify from "fastify";
import cookie from "@fastify/cookie";
import helmet from "@fastify/helmet";
import rateLimit from "@fastify/rate-limit";
import fastifyStatic from "@fastify/static";
import { resolve } from "node:path";
import { existsSync } from "node:fs";
import { ZodError } from "zod";
import { type Store, AppError } from "./db.js";
import { authRoutes, guards } from "./auth.js";
import { gameRoutes } from "./game.js";
import { adminRoutes } from "./admin.js";
import { homesteadRoutes } from "./homestead.js";
import { adventureRoutes } from "./adventure.js";
export async function buildApp(s: Store, logging = true) {
  const app = Fastify({
    logger: logging
      ? {
          redact: [
            "req.headers.cookie",
            "req.headers.authorization",
            "res.headers.set-cookie",
          ],
          serializers: {
            req: (r) => ({
              method: r.method,
              url: r.url?.split("?")[0],
              remoteAddress: r.ip,
            }),
          },
        }
      : false,
    trustProxy: s.cfg.trustProxy.length ? s.cfg.trustProxy : false,
    bodyLimit: 2 * 1024 * 1024,
  });
  await app.register(cookie);
  await app.register(helmet, {
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'wasm-unsafe-eval'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", "data:", "blob:"],
        fontSrc: ["'self'"],
        connectSrc: ["'self'"],
        frameSrc: ["'self'"],
        workerSrc: ["'self'", "blob:"],
        objectSrc: ["'none'"],
        frameAncestors: ["'self'"],
        upgradeInsecureRequests: s.cfg.production ? [] : null,
      },
    },
    crossOriginEmbedderPolicy: false,
  });
  await app.register(rateLimit, {
    max: 180,
    timeWindow: "1 minute",
    redis: s.redis,
  });
  const g = guards(s);
  app.addHook("onRequest", async (req, reply) => {
    if (!req.url.startsWith("/api/")) return;
    reply.header("Cache-Control", "no-store");
    await g.load(req);
    if (!["GET", "HEAD", "OPTIONS"].includes(req.method)) {
      if (req.headers.origin !== s.cfg.origin)
        throw new AppError(403, "Origin permintaan tidak diizinkan.", "CSRF");
      const csrf = req.headers["x-csrf-token"];
      if (!csrf || csrf !== (req.auth?.csrf ?? req.cookies.jalasmara_csrf))
        throw new AppError(
          403,
          "Sesi formulir berubah. Muat ulang halaman.",
          "CSRF",
        );
    }
  });
  app.setErrorHandler((error, req, reply) => {
    if (error instanceof ZodError)
      return reply.code(400).send({
        error: error.issues
          .map((x) => `${x.path.join(".")}: ${x.message}`)
          .join("; "),
        code: "VALIDATION",
      });
    if (error instanceof AppError)
      return reply
        .code(error.status)
        .send({ error: error.message, code: error.code });
    if ((error as { code?: number }).code === 11000)
      return reply.code(409).send({
        error: "Data sudah tersedia atau diubah oleh operasi lain.",
        code: "CONFLICT",
      });
    const httpError = error as { statusCode?: number; message?: string };
    if (httpError.statusCode && httpError.statusCode < 500)
      return reply
        .code(httpError.statusCode)
        .send({ error: httpError.message, code: "REQUEST_ERROR" });
    req.log.error({ err: error }, "Request failed");
    return reply.code(500).send({
      error: "Layanan mengalami gangguan. Coba lagi.",
      code: "SERVER_ERROR",
    });
  });
  app.get("/api/health", async () => {
    await s.db.command({ ping: 1 });
    await s.redis.ping();
    return { status: "ok" };
  });
  await authRoutes(app, s, g);
  await gameRoutes(app, s, g);
  await adventureRoutes(app, s, g);
  await homesteadRoutes(app, s, g);
  await adminRoutes(app, s, g);
  const root = resolve(process.env.WEB_DIST ?? "apps/web/dist");
  if (existsSync(root)) {
    await app.register(fastifyStatic, {
      root,
      wildcard: false,
      preCompressed: true,
    });
    app.setNotFoundHandler((req, reply) => {
      if (req.url.startsWith("/api/"))
        return reply.code(404).send({ error: "Endpoint tidak ditemukan." });
      if (req.method !== "GET" || req.url.split("?")[0].includes("."))
        return reply.code(404).send({ error: "Berkas tidak ditemukan." });
      return reply.sendFile("index.html");
    });
  }
  return app;
}
