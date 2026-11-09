import type { Loot } from "./index.js";
export type CropStage = "empty" | "seed" | "sprout" | "young" | "ready";
export interface GardenPlot {
  id: "plot_1" | "plot_2";
  cropId: null | "kangkung";
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
  seeds: { benih_kangkung: number };
  produce: { kangkung: number };
  pantry: { kangkung: number };
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
    seeds: { benih_kangkung: legacyPermit ? 2 : 0 },
    produce: { kangkung: 0 },
    pantry: { kangkung: 0 },
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
