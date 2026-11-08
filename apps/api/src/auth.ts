import type { FastifyInstance, FastifyRequest, FastifyReply } from "fastify";
import argon2 from "argon2";
import { randomUUID } from "node:crypto";
import { z } from "zod";
import * as oidc from "openid-client";
import {
  type Store,
  type User,
  opaque,
  digest,
  fail,
  publicUser,
  transaction,
  audit,
  lock,
} from "./db.js";
import { email, password, reason, uuid } from "./schemas.js";
import {
  freshAbilities,
  freshProgress,
} from "../../../packages/shared/src/index.js";
export interface Session {
  userId: string;
  authVersion: number;
  csrf: string;
  reauthAt: number;
}
declare module "fastify" {
  interface FastifyRequest {
    user?: User;
    auth?: Session;
    sessionId?: string;
  }
}
const ttl = 7 * 86400;
export function guards(s: Store) {
  const cookie = s.cfg.production ? "__Host-jalasmara" : "jalasmara";
  const opts = {
    path: "/",
    httpOnly: true,
    secure: s.cfg.production,
    sameSite: "lax" as const,
  };
  async function issue(u: User, reply: FastifyReply) {
    const token = opaque(),
      auth: Session = {
        userId: u.id,
        authVersion: u.authVersion,
        csrf: opaque(),
        reauthAt: Date.now(),
      };
    await s.redis.set(`auth:${digest(token)}`, JSON.stringify(auth), "EX", ttl);
    reply.setCookie(cookie, token, { ...opts, maxAge: ttl });
    return auth;
  }
  async function load(req: FastifyRequest) {
    const token = req.cookies[cookie];
    if (!token) return;
    const raw = await s.redis.get(`auth:${digest(token)}`);
    if (!raw) return;
    const auth = JSON.parse(raw) as Session;
    const user = await s.users.findOne({ id: auth.userId });
    if (
      !user ||
      user.authVersion !== auth.authVersion ||
      user.status !== "active"
    )
      return;
    req.user = user;
    req.auth = auth;
    req.sessionId = digest(token);
  }
  async function authenticated(req: FastifyRequest) {
    if (!req.user) fail("Silakan masuk kembali.", 401, "UNAUTHENTICATED");
  }
  async function admin(req: FastifyRequest) {
    await authenticated(req);
    if (!["owner", "admin"].includes(req.user!.role))
      fail("Akses pengelola diperlukan.", 403);
  }
  async function owner(req: FastifyRequest) {
    await authenticated(req);
    if (req.user!.role !== "owner")
      fail("Hanya owner yang dapat melakukan tindakan ini.", 403);
  }
  async function recent(req: FastifyRequest) {
    await authenticated(req);
    if (Date.now() - (req.auth?.reauthAt ?? 0) > 5 * 60000)
      fail("Konfirmasi ulang password diperlukan.", 403, "REAUTH");
  }
  return { cookie, opts, issue, load, authenticated, admin, owner, recent };
}
export type Guards = ReturnType<typeof guards>;
export async function authRoutes(app: FastifyInstance, s: Store, g: Guards) {
  let provider: oidc.Configuration | undefined;
  const issuer = process.env.OIDC_ISSUER,
    clientId = process.env.OIDC_CLIENT_ID;
  async function providerConfig() {
    if (!issuer || !clientId) fail("Login tambahan belum dikonfigurasi.", 404);
    const url = new URL(issuer!);
    const local =
      !s.cfg.production &&
      url.protocol === "http:" &&
      ["127.0.0.1", "localhost", "[::1]"].includes(url.hostname);
    provider ??= await oidc.discovery(
      url,
      clientId!,
      process.env.OIDC_CLIENT_SECRET,
      undefined,
      local ? { execute: [oidc.allowInsecureRequests] } : undefined,
    );
    return provider;
  }
  app.get("/api/auth/session", async (req, reply) => {
    let csrf = req.auth?.csrf;
    if (!csrf) {
      csrf = req.cookies.jalasmara_csrf ?? opaque();
      reply.setCookie("jalasmara_csrf", csrf, g.opts);
    }
    return {
      user: req.user ? publicUser(req.user) : null,
      csrf,
      oidcEnabled: !!(issuer && clientId),
      oidcLabel: process.env.OIDC_LABEL ?? "Google / Microsoft / OIDC",
      linked: !!req.user?.oidc,
    };
  });
  app.post(
    "/api/auth/login",
    { config: { rateLimit: { max: 8, timeWindow: "5 minutes" } } },
    async (req, reply) => {
      const body = z
        .object({ email, password: z.string().min(1).max(128) })
        .strict()
        .parse(req.body);
      const u = await s.users.findOne({ email: body.email });
      // A real Argon2 calculation on unknown accounts avoids a fast account-enumeration path.
      const hash =
        u?.passwordHash ??
        (await argon2.hash(opaque(), { type: argon2.argon2id }));
      const valid = await argon2.verify(hash, body.password);
      if (!u || !valid || u.status !== "active")
        fail("Email atau password tidak sesuai, atau akses belum aktif.", 401);
      if (req.sessionId) await s.redis.del(`auth:${req.sessionId}`);
      const auth = await g.issue(u!, reply);
      return { user: publicUser(u!), csrf: auth.csrf };
    },
  );
  app.post("/api/auth/logout", async (req, reply) => {
    if (req.sessionId) await s.redis.del(`auth:${req.sessionId}`);
    reply.clearCookie(g.cookie, g.opts);
    return { ok: true };
  });
  app.post(
    "/api/auth/reauth",
    {
      preHandler: g.authenticated,
      config: { rateLimit: { max: 5, timeWindow: "5 minutes" } },
    },
    async (req) => {
      const b = z
        .object({ password: z.string().min(1).max(128) })
        .strict()
        .parse(req.body);
      if (!(await argon2.verify(req.user!.passwordHash, b.password)))
        fail("Password tidak sesuai.", 401);
      req.auth!.reauthAt = Date.now();
      await s.redis.set(
        `auth:${req.sessionId}`,
        JSON.stringify(req.auth),
        "EX",
        ttl,
      );
      return { ok: true };
    },
  );
  app.post(
    "/api/auth/activate",
    { config: { rateLimit: { max: 8, timeWindow: "5 minutes" } } },
    async (req, reply) => {
      const b = z
        .object({
          token: z.string().min(32).max(128),
          password,
          name: z.string().trim().min(2).max(60),
        })
        .strict()
        .parse(req.body);
      const hash = await argon2.hash(b.password, { type: argon2.argon2id });
      const user = await transaction(s, async (session) => {
        const t = await s.tokens.findOne(
          {
            _id: digest(b.token),
            kind: "invite",
            expiresAt: { $gt: new Date() },
          },
          { session },
        );
        if (!t) return fail("Undangan tidak berlaku atau sudah digunakan.");
        if (await s.users.findOne({ email: t.email }, { session }))
          return fail("Akun sudah tersedia. Gunakan halaman masuk.", 409);
        const now = new Date().toISOString();
        const u: User = {
          id: randomUUID(),
          email: t.email,
          name: b.name,
          role: "player",
          status: "active",
          coins: 0,
          inventory: [],
          abilities: freshAbilities(),
          progress: freshProgress(),
          version: 0,
          authVersion: 0,
          passwordHash: hash,
          createdAt: now,
          updatedAt: now,
        };
        await s.users.insertOne(u, { session });
        await s.tokens.deleteOne({ _id: t._id }, { session });
        await audit(
          s,
          session,
          u.id,
          u.id,
          "account.activate",
          "Aktivasi undangan",
          null,
          publicUser(u),
          req.id,
        );
        return u;
      });
      const auth = await g.issue(user, reply);
      return { user: publicUser(user), csrf: auth.csrf };
    },
  );
  app.post(
    "/api/auth/reset",
    { config: { rateLimit: { max: 8, timeWindow: "5 minutes" } } },
    async (req) => {
      const b = z
        .object({ token: z.string().min(32).max(128), password })
        .strict()
        .parse(req.body);
      const hash = await argon2.hash(b.password, { type: argon2.argon2id });
      await transaction(s, async (session) => {
        const t = await s.tokens.findOne(
          {
            _id: digest(b.token),
            kind: "reset",
            expiresAt: { $gt: new Date() },
          },
          { session },
        );
        if (!t) return fail("Tautan reset tidak berlaku atau sudah digunakan.");
        const u = await s.users.findOne({ id: t.userId }, { session });
        if (!u || u.role === "owner")
          return fail("Akun tidak dapat direset melalui tautan ini.");
        await s.users.updateOne(
          { id: u.id },
          {
            $set: { passwordHash: hash, updatedAt: new Date().toISOString() },
            $inc: { authVersion: 1, version: 1 },
          },
          { session },
        );
        await s.tokens.deleteOne({ _id: t._id }, { session });
        await audit(
          s,
          session,
          u.id,
          u.id,
          "account.password_reset",
          "Reset melalui token sekali pakai",
          { authVersion: u.authVersion },
          { authVersion: u.authVersion + 1 },
          req.id,
        );
      });
      return { ok: true };
    },
  );
  app.post("/api/admin/invitations", { preHandler: g.owner }, async (req) => {
    const b = z.object({ email, reason }).strict().parse(req.body),
      token = opaque();
    await transaction(s, async (session) => {
      if (await s.users.findOne({ email: b.email }, { session }))
        return fail("Email sudah memiliki akun.", 409);
      await s.tokens.deleteMany(
        { email: b.email, kind: "invite" },
        { session },
      );
      await s.tokens.insertOne(
        {
          _id: digest(token),
          kind: "invite",
          email: b.email,
          expiresAt: new Date(Date.now() + 72 * 3600000),
          issuedBy: req.user!.id,
        },
        { session },
      );
      await audit(
        s,
        session,
        req.user!.id,
        b.email,
        "account.invite",
        b.reason,
        null,
        { email: b.email, expiresInHours: 72 },
        req.id,
      );
    });
    return { url: `${s.cfg.origin}/activate#${token}`, expiresInHours: 72 };
  });
  app.post(
    "/api/admin/players/:id/reset-password",
    { preHandler: [g.owner, g.recent] },
    async (req) => {
      const { id } = z.object({ id: uuid }).parse(req.params),
        b = z.object({ reason }).strict().parse(req.body),
        token = opaque();
      await transaction(s, async (session) => {
        const u = await s.users.findOne({ id }, { session });
        if (!u || u.role === "owner")
          return fail("Reset owner harus menggunakan perintah server.", 403);
        await s.tokens.deleteMany(
          { email: u.email, kind: "reset" },
          { session },
        );
        await s.tokens.insertOne(
          {
            _id: digest(token),
            kind: "reset",
            email: u.email,
            userId: u.id,
            expiresAt: new Date(Date.now() + 3600000),
            issuedBy: req.user!.id,
          },
          { session },
        );
        await audit(
          s,
          session,
          req.user!.id,
          id,
          "account.reset_link",
          b.reason,
          null,
          { expiresInHours: 1 },
          req.id,
        );
      });
      return { url: `${s.cfg.origin}/reset#${token}`, expiresInHours: 1 };
    },
  );
  app.get("/api/auth/oidc/start", async (req, reply) => {
    const q = z
      .object({ mode: z.enum(["login", "link"]).default("login") })
      .parse(req.query);
    if (q.mode === "link") await g.recent(req);
    const c = await providerConfig(),
      state = oidc.randomState(),
      nonce = oidc.randomNonce(),
      verifier = oidc.randomPKCECodeVerifier(),
      browser = opaque();
    await s.redis.set(
      `oidc:${state}`,
      JSON.stringify({
        nonce,
        verifier,
        browser: digest(browser),
        mode: q.mode,
        userId: req.user?.id,
        authVersion: req.user?.authVersion,
        oidcVersion: req.user?.oidcVersion ?? 0,
        sessionId: req.sessionId,
      }),
      "EX",
      600,
    );
    reply.setCookie("jalasmara_oidc", browser, { ...g.opts, maxAge: 600 });
    const url = oidc.buildAuthorizationUrl(c, {
      redirect_uri: `${s.cfg.origin}/api/auth/oidc/callback`,
      scope: "openid profile email",
      state,
      nonce,
      code_challenge: await oidc.calculatePKCECodeChallenge(verifier),
      code_challenge_method: "S256",
    });
    return reply.redirect(url.href);
  });
  app.get("/api/auth/oidc/callback", async (req, reply) => {
    const { state } = z
      .object({ state: z.string().min(1).max(256) })
      .passthrough()
      .parse(req.query);
    const raw = await s.redis.getdel(`oidc:${state}`);
    if (!raw) return fail("Permintaan login telah kedaluwarsa.", 400);
    const flow = JSON.parse(raw);
    if (digest(req.cookies.jalasmara_oidc ?? "") !== flow.browser)
      return fail("Browser login tidak sesuai.", 403);
    const c = await providerConfig();
    const tokens = await oidc.authorizationCodeGrant(
      c,
      new URL(req.url, s.cfg.origin),
      {
        pkceCodeVerifier: flow.verifier,
        expectedState: state,
        expectedNonce: flow.nonce,
        idTokenExpected: true,
      },
    );
    const claims = tokens.claims();
    if (!claims?.sub) return fail("Identitas provider tidak tersedia.", 400);
    const identity = { issuer: c.serverMetadata().issuer, subject: claims.sub };
    if (flow.mode === "link") {
      await g.recent(req);
      if (
        req.user!.id !== flow.userId ||
        req.user!.authVersion !== flow.authVersion ||
        req.sessionId !== flow.sessionId
      )
        return fail("Sesi penautan telah berubah.", 403);
      await lock(s, req.user!.id, () =>
        transaction(s, async (session) => {
          const u = await s.users.findOne({ id: flow.userId }, { session });
          if (
            !u ||
            u.authVersion !== flow.authVersion ||
            (u.oidcVersion ?? 0) !== flow.oidcVersion
          )
            return fail("Tautan identitas berubah. Ulangi proses.", 409);
          const existing = await s.users.findOne(
            {
              "oidc.issuer": identity.issuer,
              "oidc.subject": identity.subject,
            },
            { session },
          );
          if (existing && existing.id !== u.id)
            return fail("Identitas sudah ditautkan ke akun lain.", 409);
          await s.users.updateOne(
            { id: u.id },
            { $set: { oidc: identity }, $inc: { oidcVersion: 1 } },
            { session },
          );
          await audit(
            s,
            session,
            u.id,
            u.id,
            "account.oidc_link",
            "Penautan setelah autentikasi ulang",
            u.oidc ?? null,
            identity,
            req.id,
          );
        }),
      );
      return reply.redirect("/settings?linked=1");
    }
    const u = await s.users.findOne({
      "oidc.issuer": identity.issuer,
      "oidc.subject": identity.subject,
    });
    if (!u || u.status !== "active")
      return reply.redirect("/?authError=unlinked");
    if (req.sessionId) await s.redis.del(`auth:${req.sessionId}`);
    await g.issue(u, reply);
    reply.clearCookie("jalasmara_oidc", g.opts);
    return reply.redirect("/play");
  });
  app.post(
    "/api/auth/oidc/unlink",
    { preHandler: [g.authenticated, g.recent] },
    async (req) => {
      await lock(s, req.user!.id, () =>
        transaction(s, async (session) => {
          const u = await s.users.findOne({ id: req.user!.id }, { session });
          if (!u) return fail("Akun tidak ditemukan.", 404);
          await s.users.updateOne(
            { id: u.id },
            { $unset: { oidc: "" }, $inc: { oidcVersion: 1 } },
            { session },
          );
          await audit(
            s,
            session,
            u.id,
            u.id,
            "account.oidc_unlink",
            "Pelepasan setelah autentikasi ulang",
            u.oidc ?? null,
            null,
            req.id,
          );
        }),
      );
      return { ok: true };
    },
  );
}
