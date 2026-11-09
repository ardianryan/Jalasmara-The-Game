import type { Loot } from "./index.js";
export type CropStage = "empty" | "seed" | "sprout" | "young" | "ready";
export type CropId = "kangkung" | "jahe";
export type GardenItemId = CropId | "ikan_seruni";
export type SeedId = "benih_kangkung" | "benih_jahe";
export interface GardenPlot {
  id: "plot_1" | "plot_2";
  cropId: null | CropId;
  growthDays: number;
  wateredDay: number;
  lastSettledDay: number;
  needsCare: boolean;
}
export interface HomesteadState {
  revision: number;
  inside: boolean;
  interiorVersion: number;
  position: { x: number; y: number };
  permit: boolean;
  seeds: Record<SeedId, number>;
  produce: Record<GardenItemId, number>;
  pantry: Record<GardenItemId, number>;
  liveCatch: { reef_seruni: number };
  fishPen: {
    breeders: number;
    progressDays: number;
    fedDay: number;
    lastSettledDay: number;
    offspring: number;
  };
  storageLoot: Loot[];
  plots: GardenPlot[];
  market: { day: number; bought: number };
  pendingStoryAdvance?: { storyDay: number; shiftId: string };
}
export const HOMESTEAD_DEFINITIONS = {
  crop: {
    id: "kangkung",
    seedId: "benih_kangkung",
    name: "Kangkung kebun",
    growthDays: 3,
    yield: 3,
  },
  market: { seedId: "benih_kangkung", price: 20, dailyStock: 6 },
  starterSeeds: 2,
  gardenServing: { itemId: "kangkung", quantity: 1, bonus: 5 },
  crops: [
    {
      id: "kangkung",
      seedId: "benih_kangkung",
      name: "Kangkung kebun",
      growthDays: 3,
      yield: 3,
      price: 20,
    },
    {
      id: "jahe",
      seedId: "benih_jahe",
      name: "Jahe pesisir",
      growthDays: 4,
      yield: 3,
      price: 30,
    },
  ],
  servings: {
    kangkung: {
      itemId: "kangkung",
      name: "Kangkung kebun",
      quantity: 1,
      bonus: 5,
    },
    jahe: { itemId: "jahe", name: "Jahe pesisir", quantity: 1, bonus: 12 },
    ikan_seruni: {
      itemId: "ikan_seruni",
      name: "Ikan seruni budidaya",
      quantity: 1,
      bonus: 10,
    },
  },
  fishPen: {
    speciesId: "reef_seruni",
    name: "Ikan karang seruni",
    parentCount: 2,
    growthDays: 2,
    feedCost: 2,
    capacity: 5,
    unlockStoryDay: 2,
    yieldItemId: "ikan_seruni",
  },
  chestCapacity: 100,
  interiorVersion: 1,
} as const;
export function freshHomestead(day = 1, legacyPermit = false): HomesteadState {
  return {
    revision: 0,
    inside: false,
    interiorVersion: 1,
    position: { x: 480, y: 580 },
    permit: legacyPermit,
    seeds: { benih_kangkung: legacyPermit ? 2 : 0, benih_jahe: 0 },
    produce: { kangkung: 0, jahe: 0, ikan_seruni: 0 },
    pantry: { kangkung: 0, jahe: 0, ikan_seruni: 0 },
    liveCatch: { reef_seruni: 0 },
    fishPen: {
      breeders: 0,
      progressDays: 0,
      fedDay: 0,
      lastSettledDay: day,
      offspring: 0,
    },
    storageLoot: [],
    market: { day, bought: 0 },
    plots: ["plot_1", "plot_2"].map((id) => ({
      id: id as GardenPlot["id"],
      cropId: null,
      growthDays: 0,
      wateredDay: 0,
      lastSettledDay: day,
      needsCare: false,
    })),
  };
}
export function normalizeHomestead(
  state: HomesteadState,
  day: number,
): boolean {
  let changed = false;
  const defaults = freshHomestead(day);
  for (const key of [
    "seeds",
    "produce",
    "pantry",
    "liveCatch",
    "fishPen",
  ] as const) {
    const existing = (state as unknown as Record<string, unknown>)[key];
    if (!existing || typeof existing !== "object") {
      Object.assign(state, { [key]: defaults[key] });
      changed = true;
      continue;
    }
    for (const [name, initial] of Object.entries(defaults[key])) {
      if (!(name in existing)) {
        Object.assign(existing, { [name]: initial });
        changed = true;
      }
    }
  }
  return changed;
}
