export type GearId = "lamp" | "launcher";

export const GEAR_UPGRADES = {
  lamp: {
    name: "Lampu Sorot UV",
    costs: [180, 320],
    requiredFinds: ["photosynthesis", "inscription"],
    requiredItems: ["lensa_kelompok_bagas", "serpih_prasasti_uv"],
  },
  launcher: {
    name: "Pelontar Kapsul Basa",
    costs: [200, 360],
    requiredFinds: ["corporate_pipe", "inscription"],
    requiredItems: ["inti_katup_peneliti", "serpih_prasasti_uv"],
    ranges: [160, 200, 240],
  },
} as const;

export const DISCOVERY_GEAR_ITEMS: Record<string, string> = {
  photosynthesis: "lensa_kelompok_bagas",
  corporate_pipe: "inti_katup_peneliti",
  inscription: "serpih_prasasti_uv",
};
