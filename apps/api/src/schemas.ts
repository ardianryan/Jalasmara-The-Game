import { z } from "zod";
export const email = z
  .string()
  .trim()
  .email()
  .max(254)
  .transform((s) => s.toLowerCase());
export const password = z
  .string()
  .min(12, "Password minimal 12 karakter.")
  .max(128);
export const reason = z
  .string()
  .trim()
  .min(5, "Alasan minimal 5 karakter.")
  .max(500);
export const uuid = z.string().uuid();
export const version = z.number().int().nonnegative();
export const ability = z.enum(["oxygen", "bag", "speed", "net"]);
export const adminChange = z
  .object({
    version,
    reason,
    action: z.enum([
      "coins",
      "inventory",
      "ability",
      "progress",
      "reset",
      "block",
      "unblock",
      "revoke",
      "role",
    ]),
    mode: z.enum(["add", "subtract", "set"]).optional(),
    amount: z.number().int().min(0).max(10000000).optional(),
    fragmentId: z.string().max(64).optional(),
    stars: z.number().int().min(1).max(3).optional(),
    ability: ability.optional(),
    level: z.number().int().min(0).max(5).optional(),
    progress: z
      .object({
        day: z.number().int().min(1).max(3),
        stage: z.enum(["dive", "night", "boss", "done"]),
        tutorial: z.boolean(),
        bossDefeated: z.boolean(),
        missions: z.array(z.string().max(64)).max(20),
      })
      .strict()
      .optional(),
    role: z.enum(["player", "admin"]).optional(),
  })
  .strict();
