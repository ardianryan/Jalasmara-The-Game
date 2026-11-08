import { MongoClient, type ClientSession } from "mongodb";
import { Redis } from "ioredis";
import { createHash, randomBytes, randomUUID } from "node:crypto";
import type {
  Player,
  ContentVersion,
} from "../../../packages/shared/src/index.js";
import { seedCatalog } from "./content.js";
export interface User extends Player {
  passwordHash: string;
  oidc?: { issuer: string; subject: string };
  oidcVersion?: number;
}
export interface Token {
  _id: string;
  kind: "invite" | "reset";
  email: string;
  userId?: string;
  name?: string;
  expiresAt: Date;
  issuedBy: string;
}
export interface Audit {
  _id: string;
  actor: string;
  target: string;
  action: string;
  reason: string;
  before: unknown;
  after: unknown;
  at: Date;
  requestId: string;
}
export interface Receipt {
  _id: string;
  fingerprint: string;
  result: unknown;
  createdAt: Date;
}
export class AppError extends Error {
  constructor(
    public status: number,
    message: string,
    public code = "INVALID",
  ) {
    super(message);
  }
}
export const fail = (
  message: string,
  status = 400,
  code = "INVALID",
): never => {
  throw new AppError(status, message, code);
};
export const opaque = () => randomBytes(32).toString("base64url");
export const digest = (s: string) =>
  createHash("sha256").update(s).digest("hex");
export const publicUser = (u: User): Player => {
  const { passwordHash, oidc, oidcVersion, _id, ...p } = u as User & {
    _id?: unknown;
  };
  return p;
};
export const emailKey = (s: string) => s.trim().toLowerCase();
export const config = () => ({
  mongoUrl:
    process.env.MONGO_URL ??
    "mongodb://127.0.0.1:27018/jalasmara?replicaSet=rs0",
  redisUrl: process.env.REDIS_URL ?? "redis://127.0.0.1:6380",
  origin: process.env.APP_ORIGIN ?? "http://localhost:5173",
  production: process.env.NODE_ENV === "production",
  trustProxy: (process.env.TRUST_PROXY ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean),
});
export async function connect() {
  const cfg = config();
  const mongo = new MongoClient(cfg.mongoUrl, {
    serverSelectionTimeoutMS: 10000,
  });
  await mongo.connect();
  const db = mongo.db();
  const redis = new Redis(cfg.redisUrl, {
    maxRetriesPerRequest: 2,
    lazyConnect: true,
  });
  await redis.connect();
  const users = db.collection<User>("players");
  const contents = db.collection<ContentVersion>("contents");
  const tokens = db.collection<Token>("tokens");
  const audits = db.collection<Audit>("audits");
  const receipts = db.collection<Receipt>("receipts");
  await users.createIndex({ email: 1 }, { unique: true });
  await users.createIndex({ id: 1 }, { unique: true });
  await users.createIndex(
    { "oidc.issuer": 1, "oidc.subject": 1 },
    {
      unique: true,
      partialFilterExpression: { "oidc.issuer": { $type: "string" } },
    },
  );
  await tokens.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
  await tokens.createIndex({ kind: 1, email: 1 }, { unique: true });
  await contents.createIndex({ id: 1 }, { unique: true });
  await contents.createIndex(
    { state: 1 },
    { unique: true, partialFilterExpression: { state: "published" } },
  );
  await audits.createIndex({ target: 1, at: -1 });
  await receipts.createIndex(
    { createdAt: 1 },
    { expireAfterSeconds: 7 * 86400 },
  );
  const store = {
    mongo,
    db,
    redis,
    users,
    contents,
    tokens,
    audits,
    receipts,
    cfg,
  };
  return store;
}
export type Store = Awaited<ReturnType<typeof connect>>;
export async function seed(store: Store) {
  if ((await store.contents.countDocuments()) === 0)
    await store.contents.insertOne({
      id: randomUUID(),
      label: "Palung Smara · Fase 1",
      state: "published",
      catalog: seedCatalog(),
      createdAt: new Date().toISOString(),
      publishedAt: new Date().toISOString(),
    });
}
export async function currentContent(
  s: Store,
  session?: ClientSession,
): Promise<ContentVersion> {
  const c = await s.contents.findOne({ state: "published" }, { session });
  if (!c) return fail("Belum ada konten aktif. Hubungi pengelola.", 503);
  return c;
}
export async function lock<T>(
  s: Store,
  id: string,
  fn: () => Promise<T>,
): Promise<T> {
  const token = opaque(),
    key = `lock:${id}`;
  if (!(await s.redis.set(key, token, "PX", 30000, "NX")))
    return fail("Operasi lain sedang berlangsung. Coba lagi.", 409, "BUSY");
  try {
    return await fn();
  } finally {
    await s.redis.eval(
      "if redis.call('get',KEYS[1])==ARGV[1] then return redis.call('del',KEYS[1]) else return 0 end",
      1,
      key,
      token,
    );
  }
}
export async function audit(
  s: Store,
  session: ClientSession,
  actor: string,
  target: string,
  action: string,
  reason: string,
  before: unknown,
  after: unknown,
  requestId: string,
) {
  await s.audits.insertOne(
    {
      _id: randomUUID(),
      actor,
      target,
      action,
      reason,
      before,
      after,
      at: new Date(),
      requestId,
    },
    { session },
  );
}
export async function transaction<T>(
  s: Store,
  fn: (session: ClientSession) => Promise<T>,
): Promise<T> {
  const session = s.mongo.startSession();
  try {
    return (await session.withTransaction(() => fn(session)))!;
  } finally {
    await session.endSession();
  }
}
export async function once<T>(
  s: Store,
  actor: string,
  key: string,
  fingerprint: unknown,
  fn: (session: ClientSession) => Promise<T>,
): Promise<T> {
  const hash = digest(JSON.stringify(fingerprint)),
    id = `${actor}:${key}`;
  return transaction(s, async (session) => {
    const old = await s.receipts.findOne({ _id: id }, { session });
    if (old) {
      if (old.fingerprint !== hash)
        return fail(
          "Kunci permintaan sudah digunakan untuk operasi lain.",
          409,
        );
      return old.result as T;
    }
    const result = await fn(session);
    await s.receipts.insertOne(
      { _id: id, fingerprint: hash, result, createdAt: new Date() },
      { session },
    );
    return result;
  });
}
export async function close(s: Store) {
  await s.redis.quit();
  await s.mongo.close();
}
