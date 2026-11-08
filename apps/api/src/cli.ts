import { createInterface } from "node:readline/promises";
import { Writable } from "node:stream";
import { existsSync } from "node:fs";
import { randomUUID } from "node:crypto";
import argon2 from "argon2";
import {
  connect,
  close,
  seed,
  transaction,
  audit,
  emailKey,
  fail,
  type User,
} from "./db.js";
import { email, password } from "./schemas.js";
import {
  freshAbilities,
  freshProgress,
} from "../../../packages/shared/src/index.js";
if (existsSync(".env")) process.loadEnvFile?.(".env");
const s = await connect(),
  command = process.argv[2];
try {
  if (command === "seed") {
    await seed(s);
    console.log("Konten awal siap.");
  } else if (command === "owner" || command === "recover-owner") {
    if (!process.stdin.isTTY)
      fail("Jalankan melalui terminal interaktif untuk menjaga password.");
    const rl = createInterface({
      input: process.stdin,
      output: process.stdout,
    });
    const address = email.parse(await rl.question("Email owner: "));
    const name = command === "owner" ? await rl.question("Nama owner: ") : "";
    rl.close();
    async function hidden(prompt: string) {
      process.stdout.write(prompt);
      let muted = false;
      const output = new Writable({
        write(chunk, encoding, cb) {
          if (!muted) process.stdout.write(chunk);
          cb();
        },
      });
      const r = createInterface({
        input: process.stdin,
        output,
        terminal: true,
      });
      muted = true;
      const value = await r.question("");
      r.close();
      process.stdout.write("\n");
      return value;
    }
    const secret = password.parse(
      await hidden("Password baru (minimal 12 karakter): "),
    );
    if (secret !== (await hidden("Ulangi password: ")))
      fail("Konfirmasi password berbeda.");
    const hash = await argon2.hash(secret, { type: argon2.argon2id });
    await transaction(s, async (session) => {
      const now = new Date().toISOString();
      if (command === "owner") {
        if (await s.users.countDocuments({ role: "owner" }, { session }))
          return fail(
            "Owner sudah tersedia. Gunakan recover-owner untuk pemulihan.",
          );
        const u: User = {
          id: randomUUID(),
          email: emailKey(address),
          name: name.trim() || "Pengelola",
          role: "owner",
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
        await audit(
          s,
          session,
          "server",
          u.id,
          "owner.bootstrap",
          "Bootstrap interaktif server",
          null,
          { email: u.email, role: u.role },
          randomUUID(),
        );
      } else {
        const u = await s.users.findOne(
          { email: address, role: "owner" },
          { session },
        );
        if (!u) return fail("Owner tidak ditemukan.");
        await s.users.updateOne(
          { id: u.id },
          {
            $set: { passwordHash: hash, status: "active", updatedAt: now },
            $inc: { authVersion: 1, version: 1 },
          },
          { session },
        );
        await audit(
          s,
          session,
          "server",
          u.id,
          "owner.recover",
          "Pemulihan interaktif server",
          { authVersion: u.authVersion },
          { authVersion: u.authVersion + 1 },
          randomUUID(),
        );
      }
    });
    console.log("Akun owner siap.");
  } else fail("Perintah: seed | owner | recover-owner");
} finally {
  await close(s);
}
