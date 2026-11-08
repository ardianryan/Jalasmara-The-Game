import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { createServer } from "node:http";
import { createHash, generateKeyPairSync, randomUUID, sign } from "node:crypto";
import argon2 from "argon2";
import {
  connect,
  close,
  seed,
  opaque,
  type Store,
  type User,
} from "../src/db.js";
import { buildApp } from "../src/app.js";
import {
  freshAbilities,
  freshProgress,
} from "../../../packages/shared/src/index.js";
import type { FastifyInstance } from "fastify";
const { privateKey, publicKey } = generateKeyPairSync("rsa", {
  modulusLength: 2048,
});
const jwk = {
  ...publicKey.export({ format: "jwk" }),
  kid: "test-key",
  use: "sig",
  alg: "RS256",
};
const codes = new Map<
  string,
  { nonce: string; challenge: string; sub: string; bad?: string }
>();
let issuer = "",
  s: Store,
  app: FastifyInstance,
  pass = opaque(),
  user: User;
let verifiedPkce = 0;
const provider = createServer(async (req, res) => {
  res.setHeader("Content-Type", "application/json");
  const path = req.url?.split("?")[0];
  if (path === "/.well-known/openid-configuration")
    return res.end(
      JSON.stringify({
        issuer,
        authorization_endpoint: `${issuer}/authorize`,
        token_endpoint: `${issuer}/token`,
        jwks_uri: `${issuer}/jwks`,
        response_types_supported: ["code"],
        subject_types_supported: ["public"],
        id_token_signing_alg_values_supported: ["RS256"],
        token_endpoint_auth_methods_supported: ["none"],
        code_challenge_methods_supported: ["S256"],
      }),
    );
  if (path === "/jwks") return res.end(JSON.stringify({ keys: [jwk] }));
  if (path === "/token") {
    let text = "";
    for await (const chunk of req) text += chunk;
    const b = new URLSearchParams(text),
      flow = codes.get(b.get("code") ?? "");
    codes.delete(b.get("code") ?? "");
    if (
      !flow ||
      createHash("sha256")
        .update(b.get("code_verifier") ?? "")
        .digest("base64url") !== flow.challenge
    ) {
      res.statusCode = 400;
      return res.end(JSON.stringify({ error: "invalid_grant" }));
    }
    verifiedPkce++;
    const time = Math.floor(Date.now() / 1000),
      header = Buffer.from(
        JSON.stringify({ alg: "RS256", kid: "test-key", typ: "JWT" }),
      ).toString("base64url"),
      payload = Buffer.from(
        JSON.stringify({
          iss: flow.bad === "issuer" ? "https://evil.invalid" : issuer,
          sub: flow.sub,
          aud: flow.bad === "audience" ? "wrong-app" : "jalasmara-test",
          iat: time,
          exp: time + 300,
          nonce: flow.bad === "nonce" ? "wrong-nonce" : flow.nonce,
          email: user.email,
        }),
      ).toString("base64url"),
      unsigned = `${header}.${payload}`,
      jwt = `${unsigned}.${sign("RSA-SHA256", Buffer.from(unsigned), privateKey).toString("base64url")}`;
    return res.end(
      JSON.stringify({
        access_token: opaque(),
        token_type: "Bearer",
        expires_in: 300,
        id_token: jwt,
      }),
    );
  }
  res.statusCode = 404;
  res.end("{}");
});
const runAddress = `fd01:${randomUUID().replaceAll("-", "").match(/.{4}/g)!.slice(0, 5).join(":")}`;
let ip = 0;
class Browser {
  remoteAddress = `${runAddress}::${(++ip).toString(16)}`;
  cookies: Record<string, string> = {};
  csrf = "";
  async request(path: string, body?: unknown) {
    const r = await app.inject({
      method: body === undefined ? "GET" : "POST",
      url: `/api${path}`,
      remoteAddress: this.remoteAddress,
      headers: {
        cookie: Object.entries(this.cookies)
          .map(([k, v]) => `${k}=${v}`)
          .join("; "),
        origin: s.cfg.origin,
        "x-csrf-token": this.csrf,
        "idempotency-key": randomUUID(),
      },
      payload: body as any,
    });
    for (const c of r.cookies) this.cookies[c.name] = c.value;
    let data: any;
    try {
      data = r.json();
    } catch {
      data = r.body;
    }
    if (data.csrf) this.csrf = data.csrf;
    return { r, data, status: r.statusCode };
  }
  async login() {
    await this.request("/auth/session");
    assert.equal(
      (await this.request("/auth/login", { email: user.email, password: pass }))
        .status,
      200,
    );
  }
  async flow(mode = "login", sub = "external-nala", bad?: string) {
    const r = await this.request(`/auth/oidc/start?mode=${mode}`);
    assert.equal(r.status, 302, JSON.stringify(r.data));
    const url = new URL(r.r.headers.location!),
      code = opaque();
    codes.set(code, {
      nonce: url.searchParams.get("nonce")!,
      challenge: url.searchParams.get("code_challenge")!,
      sub,
      bad,
    });
    assert.equal(url.searchParams.get("code_challenge_method"), "S256");
    return `/auth/oidc/callback?state=${url.searchParams.get("state")}&code=${code}`;
  }
}
before(async () => {
  await new Promise<void>((resolve) =>
    provider.listen(0, "127.0.0.1", resolve),
  );
  issuer = `http://127.0.0.1:${(provider.address() as any).port}`;
  process.env.NODE_ENV = "test";
  process.env.APP_ORIGIN = "http://localhost:5173";
  process.env.OIDC_ISSUER = issuer;
  process.env.OIDC_CLIENT_ID = "jalasmara-test";
  process.env.MONGO_URL =
    process.env.TEST_MONGO_URL ??
    `mongodb://127.0.0.1:27018/jalasmara_oidc_test_${randomUUID().replaceAll("-", "")}?replicaSet=rs0`;
  process.env.REDIS_URL =
    process.env.TEST_REDIS_URL ?? "redis://127.0.0.1:6380/13";
  s = await connect();
  await seed(s);
  const now = new Date().toISOString();
  user = {
    id: randomUUID(),
    name: "Nala OIDC",
    email: `${randomUUID()}@test.invalid`,
    passwordHash: await argon2.hash(pass),
    role: "player",
    status: "active",
    coins: 0,
    inventory: [],
    abilities: freshAbilities(),
    progress: freshProgress(),
    version: 0,
    authVersion: 0,
    createdAt: now,
    updatedAt: now,
  };
  await s.users.insertOne(user);
  app = await buildApp(s, false);
});
after(async () => {
  await app.close();
  await s.db.dropDatabase();
  await close(s);
  await new Promise<void>((resolve) => provider.close(() => resolve()));
});
test("OIDC tak tertaut tidak membuat akun meskipun email cocok", async () => {
  const b = new Browser(),
    callback = await b.flow();
  const r = await b.request(callback);
  assert.equal(r.r.headers.location, "/?authError=unlinked");
  assert.equal(await s.users.countDocuments(), 1);
  assert.equal((await b.request("/auth/session")).data.user, null);
});
test("callback ditolak untuk state atau browser yang berbeda", async () => {
  const b = new Browser(),
    callback = await b.flow();
  assert.equal((await new Browser().request(callback)).status, 403);
  assert.equal((await b.request(callback)).status, 400);
  assert.equal(
    (await b.request("/auth/oidc/callback?state=unknown&code=x")).status,
    400,
  );
});
test("audience, issuer, dan nonce yang salah tidak menghasilkan sesi", async () => {
  for (const bad of ["audience", "issuer", "nonce"]) {
    const b = new Browser(),
      callback = await b.flow("login", "external-nala", bad);
    const r = await b.request(callback);
    assert.notEqual(r.status, 302);
    assert.equal((await b.request("/auth/session")).data.user, null);
  }
});
test("tautkan setelah reauth, login akun sama, lepas tautan; PKCE diverifikasi issuer", async () => {
  const b = new Browser();
  await b.login();
  const token = b.cookies.jalasmara;
  const { digest } = await import("../src/db.js");
  const auth = JSON.parse((await s.redis.get(`auth:${digest(token)}`))!);
  auth.reauthAt = Date.now() - 10 * 60000;
  await s.redis.set(`auth:${digest(token)}`, JSON.stringify(auth), "EX", 600);
  assert.equal((await b.request("/auth/oidc/start?mode=link")).status, 403);
  assert.equal(
    (await b.request("/auth/reauth", { password: pass })).status,
    200,
  );
  const callback = await b.flow("link");
  assert.equal(
    (await b.request(callback)).r.headers.location,
    "/settings?linked=1",
  );
  assert.equal((await b.request("/auth/session")).data.linked, true);
  assert.equal(
    (await s.users.findOne({ id: user.id }))!.oidc?.subject,
    "external-nala",
  );
  const other = new Browser();
  assert.equal(
    (await other.request(await other.flow())).r.headers.location,
    "/play",
  );
  assert.equal((await other.request("/auth/session")).data.user.id, user.id);
  assert.equal((await b.request("/auth/oidc/unlink", {})).status, 200);
  assert.equal((await b.request("/auth/session")).data.linked, false);
  assert.equal(
    (await new Browser().request(await new Browser().flow())).status,
    403,
  );
  assert(verifiedPkce >= 5);
});
