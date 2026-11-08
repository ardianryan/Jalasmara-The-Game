import type { Store, User } from "./db.js";

export async function surfaceInvalidatedByAdmin(
  store: Store,
  player: User,
  savedVersion: number,
): Promise<boolean> {
  if (savedVersion >= player.version) return false;
  return Boolean(
    await store.audits.findOne(
      {
        target: player.id,
        action: /^player\./,
        "after.version": { $gt: savedVersion, $lte: player.version },
      },
      { projection: { _id: 1 } },
    ),
  );
}
