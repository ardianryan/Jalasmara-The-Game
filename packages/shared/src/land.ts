import { createLandGateway, type LandGateway } from "./gateways.ts";
import { decorateVillageGround } from "./village-ground.ts";

export type LandPoint = readonly [number, number];
export type LandMaterial =
  "dirt" | "grass" | "sand" | "stone" | "dock" | "bridge" | "wood";
export type LandSurface = {
  id: string;
  polygon: LandPoint[];
  material: LandMaterial;
  elevation: number;
  priority?: number;
  connectorId?: string;
  bridgeId?: string;
  walkable?: boolean;
};
export type LandObstacle = {
  id: string;
  kind: "house" | "tree" | "rock" | "garden" | "crate" | "fence" | "cliff";
  x: number;
  y: number;
  width: number;
  height: number;
  height3d: number;
  footprint: LandPoint[];
  variant?: string;
  elevation?: number;
};
export type LandStair = {
  id: string;
  type: "stairs" | "ramp";
  path: LandPoint[];
  width: number;
  steps: number;
  from: string;
  to: string;
  x: number;
  y: number;
  material: LandMaterial;
};
export type LandBridge = {
  id: string;
  path: LandPoint[];
  width: number;
  elevation: number;
  railIds: string[];
};
export type LandMap = {
  id: "hub" | "forest" | "home";
  layoutVersion: number;
  landmass?: LandPoint[];
  width: number;
  height: number;
  spawn: { x: number; y: number };
  surfaces: LandSurface[];
  obstacles: LandObstacle[];
  stairs: LandStair[];
  bridges?: LandBridge[];
  terraces: { id: string; elevation: number }[];
  routes: LandPoint[][];
  shelters?: LandShelter[];
  gateways?: LandGateway[];
};
export type LandShelter = {
  id: string;
  buildingId: string;
  roof: LandPoint[];
  posts: LandPoint[];
  elevation: number;
  attachmentHeight: number;
  outerHeight: number;
  existing?: boolean;
};
export type LandPosition = { x: number; y: number };
const rectangle = (
  x: number,
  y: number,
  width: number,
  height: number,
): LandPoint[] => [
  [x, y],
  [x + width, y],
  [x + width, y + height],
  [x, y + height],
];
const obstacle = (
  id: string,
  kind: LandObstacle["kind"],
  x: number,
  y: number,
  width: number,
  height: number,
  height3d: number,
  variant?: string,
  elevation = 0,
  authoredFootprint?: LandPoint[],
): LandObstacle => ({
  id,
  kind,
  x,
  y,
  width,
  height,
  height3d,
  footprint:
    authoredFootprint ??
    (kind === "house"
      ? [
          [x + width * 0.16, y],
          [x + width, y + height * 0.27],
          [x + width - width * 0.16, y + height],
          [x, y + height - height * 0.27],
        ]
      : rectangle(x, y, width, height)),
  variant,
  elevation,
});
const rectangularHouse = (
  id: string,
  x: number,
  y: number,
  width: number,
  depth: number,
  height3d: number,
  variant: string,
  elevation: number,
): LandObstacle =>
  obstacle(
    id,
    "house",
    x,
    y,
    width,
    depth,
    height3d,
    variant,
    elevation,
    rectangle(x, y, width, depth),
  );
const alignedLegacyHouse = (
  id: string,
  x: number,
  y: number,
  width: number,
  depth: number,
  height3d: number,
  variant: string,
  elevation: number,
): LandObstacle => {
  const legacy = obstacle(
    id,
    "house",
    x,
    y,
    width,
    depth,
    height3d,
    variant,
    elevation,
  );
  const [a, b, , d] = legacy.footprint;
  // This is the persisted map embedding scale, not the current camera elevation.
  const embeddingCos = Math.cos((55 * Math.PI) / 180);
  const along = [b[0] - a[0], (b[1] - a[1]) / embeddingCos];
  const outward = [d[0] - a[0], (d[1] - a[1]) / embeddingCos];
  const area = Math.abs(along[0] * outward[1] - along[1] * outward[0]);
  const aspect = Math.hypot(...along) / Math.hypot(...outward);
  const alignedWidth = Math.sqrt(area * aspect);
  const alignedDepth = Math.sqrt(area / aspect) * embeddingCos;
  return rectangularHouse(
    id,
    x + (width - alignedWidth) / 2,
    y + (depth - alignedDepth) / 2,
    alignedWidth,
    alignedDepth,
    height3d,
    variant,
    elevation,
  );
};
const floor = (
  id: string,
  polygon: LandPoint[],
  material: LandMaterial,
  elevation = 0,
  priority = 0,
): LandSurface => ({ id, polygon, material, elevation, priority });
function strip(a: LandPoint, b: LandPoint, width: number): LandPoint[] {
  const length = Math.hypot(b[0] - a[0], b[1] - a[1]),
    nx = ((-(b[1] - a[1]) / length) * width) / 2,
    ny = (((b[0] - a[0]) / length) * width) / 2;
  return [
    [a[0] + nx, a[1] + ny],
    [a[0] - nx, a[1] - ny],
    [b[0] - nx, b[1] - ny],
    [b[0] + nx, b[1] + ny],
  ];
}
function miteredRouteSegments(
  route: readonly LandPoint[],
  width: number | readonly number[],
): LandPoint[][] {
  if (route.length < 2) return [];
  if (typeof width !== "number" && width.length !== route.length)
    throw new Error("Trail widths must match its route points");
  const normals: [number, number][] = [];
  for (let i = 0; i < route.length - 1; i++) {
    const a = route[i],
      b = route[i + 1],
      len = Math.hypot(b[0] - a[0], b[1] - a[1]) || 1;
    normals.push([-(b[1] - a[1]) / len, (b[0] - a[0]) / len]);
  }
  const offsets: [number, number][] = [];
  for (let i = 0; i < route.length; i++) {
    const half = (typeof width === "number" ? width : width[i]) / 2;
    if (i === 0) {
      offsets.push([normals[0][0] * half, normals[0][1] * half]);
    } else if (i === route.length - 1) {
      const last = normals[normals.length - 1];
      offsets.push([last[0] * half, last[1] * half]);
    } else {
      const n0 = normals[i - 1],
        n1 = normals[i];
      let bx = n0[0] + n1[0],
        by = n0[1] + n1[1];
      const blen = Math.hypot(bx, by);
      if (blen < 1e-4) {
        offsets.push([n0[0] * half, n0[1] * half]);
      } else {
        bx /= blen;
        by /= blen;
        const dot = Math.max(0.68, bx * n0[0] + by * n0[1]);
        const scale = Math.min(1.42, 1 / dot) * half;
        offsets.push([bx * scale, by * scale]);
      }
    }
  }
  const segments: LandPoint[][] = [];
  for (let i = 1; i < route.length; i++) {
    const a = route[i - 1],
      b = route[i],
      oa = offsets[i - 1],
      ob = offsets[i];
    segments.push([
      [
        Math.round((a[0] + oa[0]) * 100) / 100,
        Math.round((a[1] + oa[1]) * 100) / 100,
      ],
      [
        Math.round((a[0] - oa[0]) * 100) / 100,
        Math.round((a[1] - oa[1]) * 100) / 100,
      ],
      [
        Math.round((b[0] - ob[0]) * 100) / 100,
        Math.round((b[1] - ob[1]) * 100) / 100,
      ],
      [
        Math.round((b[0] + ob[0]) * 100) / 100,
        Math.round((b[1] + ob[1]) * 100) / 100,
      ],
    ]);
  }
  return segments;
}
const hubStairs: LandStair[] = [
  {
    id: "dock_gangway",
    type: "ramp",
    from: "dock",
    to: "lower_court",
    x: 1120,
    y: 1157.5,
    path: [
      [1120, 1190],
      [1120, 1125],
    ],
    width: 150,
    steps: 1,
    material: "wood",
  },
  {
    id: "central_stone_steps",
    type: "stairs",
    from: "lower_court",
    to: "upper_court",
    x: 1370,
    y: 775,
    path: [
      [1370, 815],
      [1370, 735],
    ],
    width: 120,
    steps: 4,
    material: "stone",
  },
  {
    id: "western_stone_steps",
    type: "stairs",
    from: "lower_court",
    to: "upper_court",
    x: 600,
    y: 775,
    path: [
      [600, 815],
      [600, 735],
    ],
    width: 120,
    steps: 4,
    material: "stone",
  },
  {
    id: "forest_ridge_steps",
    type: "stairs",
    from: "upper_court",
    to: "forest_ridge",
    x: 1780,
    y: 420,
    path: [
      [1780, 450],
      [1780, 390],
    ],
    width: 110,
    steps: 3,
    material: "stone",
  },
];
const hubSurfaces: LandSurface[] = [
  floor(
    "residential_court",
    [
      [330, 100],
      [1460, 100],
      [1550, 135],
      [1550, 350],
      [300, 350],
      [300, 135],
    ],
    "grass",
    2,
  ),
  floor("sasmita_deck", rectangle(40, 385, 240, 350), "wood", 2),
  floor("sasmita_garden_raft", rectangle(40, 735, 275, 140), "wood", 2),
  {
    ...floor(
      "sasmita_stone_landing",
      [
        [385, 692],
        [415, 688],
        [448, 708],
        [445, 735],
        [395, 735],
        [378, 720],
      ],
      "stone",
      2,
      9,
    ),
    walkable: false,
  },
  {
    ...floor(
      "sasmita_bridge",
      strip([265, 720], [400, 720], 80),
      "bridge",
      2,
      30,
    ),
    bridgeId: "sasmita_bridge",
  },
  floor("dock_main", rectangle(850, 1160, 700, 240), "dock", 0),
  floor(
    "lower_court",
    [
      [460, 815],
      [1710, 815],
      [1770, 900],
      [1660, 1080],
      [1540, 1125],
      [850, 1125],
      [640, 1100],
      [460, 970],
    ],
    "dirt",
    1,
  ),
  floor(
    "upper_court",
    [
      [335, 350],
      [1575, 350],
      [1620, 395],
      [1620, 695],
      [1580, 735],
      [335, 735],
      [300, 700],
      [300, 395],
    ],
    "dirt",
    2,
  ),
  floor(
    "garden_wing",
    [
      [1620, 475],
      [1660, 450],
      [2125, 450],
      [2180, 485],
      [2180, 705],
      [2165, 735],
      [1650, 735],
      [1620, 705],
    ],
    "grass",
    2,
  ),
  floor(
    "forest_ridge",
    [
      [1710, 80],
      [2285, 80],
      [2350, 120],
      [2350, 345],
      [2305, 390],
      [1700, 390],
      [1670, 350],
      [1670, 125],
    ],
    "grass",
    3,
  ),
];
for (const stair of hubStairs)
  hubSurfaces.push({
    ...floor(
      stair.id + "_floor",
      strip(stair.path[0], stair.path[1], stair.width),
      stair.material,
      stair.from === "dock" ? 0 : stair.from === "lower_court" ? 1 : 2,
      30,
    ),
    connectorId: stair.id,
  });
const hubRoutes: LandPoint[][] = [
  [
    [1210, 1250],
    [1424, 1260],
  ],
  [
    [1120, 1230],
    [1350, 1290],
    [1485, 1330],
  ],
  [
    [1120, 1230],
    [1120, 1190],
    [1120, 1125],
    [1120, 1000],
  ],
  [
    [600, 950],
    [1120, 1000],
    [1370, 950],
    [1600, 950],
  ],
  [
    [1370, 950],
    [1370, 815],
    [1370, 735],
    [1350, 635],
  ],
  [
    [600, 950],
    [600, 815],
    [600, 735],
    [595, 650],
  ],
  [
    [595, 650],
    [900, 650],
    [1350, 635],
    [1720, 520],
  ],
  [
    [1720, 520],
    [1780, 450],
    [1780, 390],
    [1950, 300],
    [2180, 300],
    [2295, 230],
    [2295, 125],
  ],
];
hubRoutes.push(
  [
    [595, 650],
    [400, 720],
    [265, 720],
    [200, 700],
    [160, 660],
    [160, 615],
  ],
  [
    [160, 615],
    [160, 660],
    [230, 700],
    [230, 740],
    [280, 740],
    [280, 850],
    [205, 850],
    [105, 850],
  ],
  [
    [900, 650],
    [900, 350],
    [940, 310],
  ],
  [
    [940, 310],
    [760, 325],
    [640, 350],
    [640, 320],
    [465, 320],
  ],
  [
    [940, 310],
    [1150, 320],
    [1150, 360],
    [1240, 365],
    [1305, 360],
    [1305, 300],
    [1365, 280],
  ],
  [
    [1120, 1000],
    [1005, 975],
  ],
);
for (const [routeIndex, route] of hubRoutes.slice(-4).entries()) {
  for (const [index, polygon] of miteredRouteSegments(route, 76).entries()) {
    hubSurfaces.push({
      ...floor(
        `village_footpath_${routeIndex}_${index}`,
        polygon,
        "stone",
        routeIndex === 3 ? 1 : 2,
        8,
      ),
      walkable: false,
    });
  }
}
const hubObstacles: LandObstacle[] = [
  alignedLegacyHouse("kedai_waras", 360, 420, 400, 175, 155, "thatch", 2),
  alignedLegacyHouse("galangan_beno", 1090, 390, 420, 170, 125, "workshop", 2),
  alignedLegacyHouse("pos_cakrawala", 1840, 140, 300, 105, 135, "metal", 3),
  rectangularHouse("griya_sasmita", 78, 420, 164, 145, 122, "sasmita", 2),
  obstacle("home_plot_1", "garden", 65, 760, 80, 70, 24, "home_plot", 2),
  obstacle("home_plot_2", "garden", 165, 760, 80, 70, 24, "home_plot", 2),
  obstacle(
    "sasmita_bridge_north",
    "fence",
    320,
    686,
    80,
    8,
    44,
    "bridge_rail",
    2,
  ),
  obstacle(
    "sasmita_bridge_south",
    "fence",
    320,
    754,
    80,
    8,
    44,
    "bridge_rail",
    2,
  ),
  alignedLegacyHouse("balai_lurah", 750, 120, 380, 145, 165, "balai", 2),
  alignedLegacyHouse("rumah_ratih", 350, 150, 230, 125, 108, "home_pelana", 2),
  alignedLegacyHouse("rumah_sari", 1210, 120, 230, 125, 112, "home_limas", 2),
  alignedLegacyHouse("rumah_tedi", 920, 850, 170, 90, 100, "home_pelana", 1),
  obstacle("kebun_darmi", "garden", 1810, 485, 330, 180, 34, "raised_beds", 2),
  obstacle("batu_pelataran", "rock", 760, 835, 105, 65, 70, "limestone", 1),
  obstacle("palm_lower", "tree", 1530, 1020, 34, 34, 190, "palm", 1),
  obstacle("palm_kedai", "tree", 800, 430, 34, 34, 185, "palm", 2),
  obstacle("palm_garden", "tree", 1640, 600, 34, 34, 180, "palm", 2),
  obstacle("market_crates", "crate", 470, 915, 65, 48, 38, "woven", 1),
  obstacle("dock_crates", "crate", 920, 1190, 80, 55, 48, "wood", 0),
  obstacle(
    "changing_post_north",
    "fence",
    1425,
    1195,
    10,
    10,
    120,
    "changing_booth",
    0,
  ),
  obstacle(
    "changing_post_south",
    "fence",
    1425,
    1375,
    10,
    10,
    120,
    "changing_booth",
    0,
  ),
  obstacle("forest_gate_west", "fence", 2240, 80, 25, 110, 80, "bamboo", 3),
  obstacle("forest_gate_east", "fence", 2325, 80, 25, 110, 80, "bamboo", 3),
];
function attachedShelter(buildingId: string, reach: number): LandShelter {
  const house = hubObstacles.find((entry) => entry.id === buildingId)!;
  const [backLeft, , frontRight, frontLeft] = house.footprint;
  const alongLength = Math.hypot(
    frontRight[0] - frontLeft[0],
    frontRight[1] - frontLeft[1],
  );
  const outLength = Math.hypot(
    frontLeft[0] - backLeft[0],
    frontLeft[1] - backLeft[1],
  );
  const along = [
    (frontRight[0] - frontLeft[0]) / alongLength,
    (frontRight[1] - frontLeft[1]) / alongLength,
  ];
  const outward = [
    (frontLeft[0] - backLeft[0]) / outLength,
    (frontLeft[1] - backLeft[1]) / outLength,
  ];
  const offset = (point: LandPoint, side: number, out: number): LandPoint => [
    point[0] + along[0] * side + outward[0] * out,
    point[1] + along[1] * side + outward[1] * out,
  ];
  const widthMargin = buildingId === "balai_lurah" ? 24 : 16;
  return {
    id: `${buildingId}_serambi`,
    buildingId,
    roof: [
      offset(frontLeft, -widthMargin, -8),
      offset(frontRight, widthMargin, -8),
      offset(frontRight, widthMargin, reach),
      offset(frontLeft, -widthMargin, reach),
    ],
    posts: [
      offset(frontLeft, 8, reach - 12),
      offset(frontRight, -8, reach - 12),
    ],
    elevation: house.elevation ?? 0,
    attachmentHeight:
      house.variant === "balai" ? 126 : house.height3d * 0.7 + 22,
    outerHeight: house.variant === "balai" ? 108 : house.height3d * 0.7 + 8,
  };
}
const hubShelters = [
  attachedShelter("balai_lurah", 112),
  attachedShelter("rumah_ratih", 112),
  attachedShelter("rumah_sari", 105),
  attachedShelter("rumah_tedi", 100),
  attachedShelter("griya_sasmita", 90),
];
for (const shelter of hubShelters) {
  for (const [index, point] of shelter.posts.entries()) {
    hubObstacles.push(
      obstacle(
        `${shelter.id}_post_${index}`,
        "fence",
        point[0] - 5,
        point[1] - 5,
        10,
        10,
        shelter.outerHeight,
        "shelter_post",
        shelter.elevation,
      ),
    );
  }
}
hubShelters.push({
  id: "changing_booth_shade",
  buildingId: "changing_booth",
  existing: true,
  roof: [
    [1392, 1200],
    [1468, 1200],
    [1468, 1380],
    [1392, 1380],
  ],
  posts: [
    [1430, 1200],
    [1430, 1380],
  ],
  elevation: 0,
  attachmentHeight: 120,
  outerHeight: 120,
});
const forestRoutes: LandPoint[][] = [
  [
    [200, 1320],
    [350, 1250],
    [480, 1210],
    [650, 1050],
    [930, 950],
    [1200, 730],
    [1260, 660],
    [1300, 660],
    [1600, 640],
    [1660, 600],
    [1830, 470],
    [2080, 430],
  ],
  [
    [1200, 730],
    [1180, 1000],
    [1260, 1080],
    [1310, 1080],
    [1620, 1080],
    [1700, 1050],
    [2130, 1050],
    [2160, 1090],
  ],
  [
    [1200, 730],
    [1200, 300],
  ],
];
const forestBridges: LandBridge[] = [
  {
    id: "bridge_upper",
    path: [
      [1300, 660],
      [1600, 640],
    ],
    width: 110,
    elevation: 0,
    railIds: ["bridge_upper_left_rail", "bridge_upper_right_rail"],
  },
  {
    id: "bridge_lower",
    path: [
      [1310, 1080],
      [1620, 1080],
    ],
    width: 110,
    elevation: 0,
    railIds: ["bridge_lower_left_rail", "bridge_lower_right_rail"],
  },
];
const forestSurfaces: LandSurface[] = [
  floor(
    "forest_west_land",
    [
      [80, 120],
      [1320, 120],
      [1350, 290],
      [1310, 470],
      [1340, 650],
      [1320, 820],
      [1340, 1000],
      [1370, 1180],
      [1340, 1330],
      [1320, 1480],
      [120, 1480],
      [80, 1350],
    ],
    "grass",
  ),
  floor(
    "forest_east_land",
    [
      [1580, 120],
      [2340, 120],
      [2350, 1430],
      [1560, 1430],
      [1580, 1280],
      [1600, 1130],
      [1570, 1020],
      [1530, 890],
      [1560, 710],
      [1560, 620],
      [1590, 450],
      [1550, 280],
    ],
    "grass",
  ),
  ...forestBridges.map((bridge) => ({
    ...floor(
      bridge.id,
      strip(bridge.path[0], bridge.path[1], bridge.width),
      "bridge",
      bridge.elevation,
      30,
    ),
    bridgeId: bridge.id,
  })),
];
for (const [routeIndex, route] of forestRoutes.entries()) {
  const visualRoute: readonly LandPoint[] =
    routeIndex === 0 ? [[85, 1378], ...route] : route;
  const segments = miteredRouteSegments(visualRoute, 105);
  for (let i = 0; i < segments.length; i++) {
    forestSurfaces.push({
      ...floor(
        `forest_trail_${routeIndex}_${i + 1}`,
        segments[i],
        "dirt",
        0,
        10,
      ),
      walkable: false,
    });
  }
}
const forestObstacles: LandObstacle[] = [
  obstacle("bridge_east", "fence", 2140, 360, 180, 80, 75, "broken_bridge"),
  obstacle("landslide_north", "rock", 1080, 155, 240, 90, 125, "landslide"),
  obstacle("gate_east", "fence", 2205, 1140, 110, 220, 110, "bamboo"),
  obstacle("forest_hut", "house", 1960, 600, 160, 100, 110, "thatch"),
];
for (const bridge of forestBridges) {
  const [a, b] = bridge.path,
    length = Math.hypot(b[0] - a[0], b[1] - a[1]);
  const normal = [-(b[1] - a[1]) / length, (b[0] - a[0]) / length];
  for (const [side, sign] of [-1, 1].entries()) {
    const offset = bridge.width / 2 - 5;
    const start: LandPoint = [
      a[0] + normal[0] * offset * sign,
      a[1] + normal[1] * offset * sign,
    ];
    const end: LandPoint = [
      b[0] + normal[0] * offset * sign,
      b[1] + normal[1] * offset * sign,
    ];
    const footprint = strip(start, end, 8),
      xs = footprint.map((p) => p[0]),
      ys = footprint.map((p) => p[1]);
    const x = Math.min(...xs),
      y = Math.min(...ys),
      width = Math.max(...xs) - x,
      height = Math.max(...ys) - y;
    forestObstacles.push({
      ...obstacle(
        bridge.railIds[side],
        "fence",
        x,
        y,
        width,
        height,
        44,
        "bridge_rail",
      ),
      footprint,
    });
  }
}
for (const [i, x, y] of [
  [0, 470, 1030],
  [1, 820, 780],
  [2, 1080, 970],
  [3, 1290, 470],
  [4, 1710, 730],
  [5, 1990, 1180],
  [6, 1020, 550],
  [7, 1660, 1100],
  [8, 2040, 320],
  [9, 360, 1360],
] as const)
  forestObstacles.push(
    obstacle(
      `forest_tree_${i}`,
      "tree",
      x,
      y,
      36,
      36,
      180 + (i % 3) * 12,
      i % 2 ? "mangrove" : "broadleaf",
    ),
  );
for (const [i, x, y] of [
  [0, 520, 1320],
  [1, 1050, 1040],
  [2, 1730, 600],
  [3, 1850, 1100],
] as const)
  forestObstacles.push(
    obstacle(`forest_rock_${i}`, "rock", x, y, 75, 58, 55, "limestone"),
  );
export const LAND_MAPS: Record<"hub" | "forest", LandMap> = {
  hub: {
    id: "hub",
    layoutVersion: 10,
    landmass: [
      [240, 80],
      [680, 60],
      [1080, 80],
      [1530, 80],
      [1600, 170],
      [1650, 65],
      [2060, 40],
      [2360, 65],
      [2365, 420],
      [2250, 470],
      [2250, 760],
      [1980, 820],
      [1820, 1030],
      [1640, 1160],
      [1440, 1170],
      [860, 1160],
      [620, 1125],
      [405, 1030],
      [360, 810],
      [250, 750],
      [210, 530],
    ],
    width: 2400,
    height: 1600,
    spawn: { x: 1120, y: 1230 },
    surfaces: hubSurfaces,
    obstacles: hubObstacles,
    shelters: hubShelters,
    stairs: hubStairs,
    bridges: [
      {
        id: "sasmita_bridge",
        path: [
          [265, 720],
          [400, 720],
        ],
        width: 80,
        elevation: 2,
        railIds: ["sasmita_bridge_north", "sasmita_bridge_south"],
      },
    ],
    terraces: [
      { id: "dock", elevation: 0 },
      { id: "lower_court", elevation: 1 },
      { id: "upper_court", elevation: 2 },
      { id: "forest_ridge", elevation: 3 },
    ],
    routes: hubRoutes,
  },
  forest: {
    id: "forest",
    layoutVersion: 6,
    width: 2400,
    height: 1600,
    spawn: { x: 200, y: 1320 },
    surfaces: forestSurfaces,
    obstacles: forestObstacles,
    stairs: [],
    bridges: forestBridges,
    terraces: [{ id: "forest_floor", elevation: 0 }],
    routes: forestRoutes,
  },
};
const hubMarginTrees: readonly (readonly [number, number, number])[] = [
  [340, 390, 2],
  [430, 380, 2],
  [990, 390, 2],
  [1585, 470, 2],
  [1570, 690, 2],
  [360, 650, 2],
  [1000, 705, 2],
  [1770, 700, 2],
  [2145, 700, 2],
  [1710, 150, 3],
  [1770, 340, 3],
  [2180, 130, 3],
  [2290, 350, 3],
  [500, 850, 1],
  [1680, 890, 1],
  [1400, 1090, 1],
];
for (const [index, [x, y, elevation]] of hubMarginTrees.entries()) {
  if (!isLandWalkable(LAND_MAPS.hub, { x, y }, 28))
    throw new Error(`Hub margin tree ${index} is not on clear authored ground`);
  LAND_MAPS.hub.obstacles.push(
    obstacle(
      `hub_margin_tree_${index}`,
      "tree",
      x - 15,
      y - 15,
      30,
      30,
      155 + (index % 4) * 14,
      index % 3 === 0 ? "broadleaf" : "palm",
      elevation,
    ),
  );
}
for (const [index, [x, y, w, h, elevation]] of [
  [700, 700, 110, 30, 2],
  [850, 360, 180, 40, 2],
  [1550, 855, 130, 35, 1],
  [1200, 1080, 250, 35, 1],
  [1690, 100, 90, 60, 3],
  [2190, 320, 130, 50, 3],
  [1650, 680, 130, 45, 2],
  [315, 480, 35, 120, 2],
].entries())
  LAND_MAPS.hub.surfaces.push({
    ...floor(
      `hub_edge_grass_${index}`,
      [
        [x + w * 0.18, y],
        [x + w * 0.7, y + h * 0.08],
        [x + w, y + h * 0.32],
        [x + w * 0.94, y + h * 0.8],
        [x + w * 0.65, y + h],
        [x + w * 0.22, y + h * 0.92],
        [x, y + h * 0.6],
        [x + w * 0.04, y + h * 0.2],
      ],
      "grass",
      elevation,
      6,
    ),
    walkable: false,
  });
const forestCandidates: LandPosition[] = [];
for (let y = 220; y <= 1360; y += 145)
  for (let x = 200; x <= 2220; x += 155)
    forestCandidates.push({
      x: x + Math.round(Math.sin(x * 0.13 + y * 0.07) * 18),
      y: y + Math.round(Math.cos(x * 0.09 - y * 0.11) * 16),
    });
const candidateOrder = (p: LandPosition) => {
  const n = Math.sin(p.x * 0.137 + p.y * 0.291) * 43758.5453;
  return n - Math.floor(n);
};
forestCandidates.sort((a, b) => candidateOrder(a) - candidateOrder(b));
let forestAdded = 0;
for (const point of forestCandidates) {
  const map = LAND_MAPS.forest;
  if (!isLandWalkable(map, point, 36)) continue;
  if (
    map.routes.some((route) =>
      route
        .slice(1)
        .some((end, i) => landDistanceToSegment(point, route[i], end) < 175),
    )
  )
    continue;
  if (
    [
      [650, 1050],
      [1200, 730],
      [1830, 470],
      [2130, 1050],
      [200, 1320],
    ].some(([x, y]) => Math.hypot(point.x - x, point.y - y) < 190)
  )
    continue;
  if (
    map.surfaces
      .filter((s) => s.material === "bridge")
      .some(
        (s) =>
          landPointInPolygon(point, s.polygon) ||
          s.polygon.some(
            (a, i) =>
              landDistanceToSegment(
                point,
                a,
                s.polygon[(i + 1) % s.polygon.length],
              ) < 140,
          ),
      )
  )
    continue;
  if (
    map.obstacles.some(
      (o) =>
        Math.hypot(point.x - o.x - o.width / 2, point.y - o.y - o.height / 2) <
        125,
    )
  )
    continue;
  map.obstacles.push(
    obstacle(
      `forest_canopy_tree_${forestAdded}`,
      "tree",
      point.x - 18,
      point.y - 18,
      36,
      36,
      190 + (forestAdded % 4) * 13,
      forestAdded % 3 === 0 ? "mangrove" : "broadleaf",
    ),
  );
  if (++forestAdded === 25) break;
}
if (forestAdded !== 25)
  throw new Error(
    "Forest canopy placement could not fit the authored clearance budget",
  );
const forestCompanionTrees: readonly (readonly [
  number,
  number,
  number,
  "broadleaf" | "mangrove",
  number,
])[] = [
  [310, 1400, 135, "broadleaf", 24],
  [430, 1420, 210, "mangrove", 30],
  [425, 1000, 145, "broadleaf", 24],
  [405, 1100, 225, "mangrove", 30],
  [1305, 405, 125, "mangrove", 24],
  [1310, 345, 200, "broadleaf", 30],
  [1690, 825, 140, "broadleaf", 24],
  [1760, 805, 220, "mangrove", 30],
];
for (const [
  index,
  [x, y, height, variant, size],
] of forestCompanionTrees.entries()) {
  const map = LAND_MAPS.forest,
    point = { x, y };
  if (!isLandWalkable(map, point, 18))
    throw new Error(`Forest companion ${index} has no clear floor`);
  if (
    map.routes.some((route) =>
      route
        .slice(1)
        .some((end, i) => landDistanceToSegment(point, route[i], end) < 100),
    )
  )
    throw new Error(`Forest companion ${index} crowds an authored route`);
  const protectedPoints: LandPoint[] = [
    [650, 1050],
    [1200, 730],
    [1830, 470],
    [2130, 1050],
    [200, 1320],
    ...(map.bridges ?? []).flatMap((b) => b.path),
  ];
  if (protectedPoints.some((p) => Math.hypot(x - p[0], y - p[1]) < 120))
    throw new Error(
      `Forest companion ${index} crowds an interaction or bridge landing`,
    );
  map.obstacles.push(
    obstacle(
      `forest_cluster_tree_${index}`,
      "tree",
      x - size / 2,
      y - size / 2,
      size,
      size,
      height,
      variant,
    ),
  );
}
const hubRidgeTrail = miteredRouteSegments(
  hubRoutes[7].slice(2),
  [92, 92, 92, 52, 52],
);
for (const [index, segment] of hubRidgeTrail.entries()) {
  LAND_MAPS.hub.surfaces.push({
    ...floor(`hub_ridge_trail_${index}`, segment, "dirt", 3, 10),
    walkable: false,
  });
}
const hubGatewayRoad = LAND_MAPS.hub.surfaces.find(
  (surface) => surface.id === "hub_ridge_trail_3",
)!;
LAND_MAPS.hub.gateways = [
  createLandGateway({
    id: "hub_forest_gate",
    label: "HubForestGate",
    elevation: 3,
    route: { segment: [[2295, 230], [2295, 125]], fraction: 95 / 105 },
    roadSurfaceId: hubGatewayRoad.id,
    roadPolygon: hubGatewayRoad.polygon,
    colliderIds: ["forest_gate_west", "forest_gate_east"],
    halfSpan: 42.5,
  }),
];
const forestGatewayRoad = LAND_MAPS.forest.surfaces.find(
  (surface) => surface.id === "forest_trail_0_1",
)!;
const forestGateway = createLandGateway({
  id: "forest_entry_gate",
  label: "ForestEntryGate",
  elevation: 0,
  route: { segment: [[85, 1378], [200, 1320]], fraction: 0.65 },
  roadSurfaceId: forestGatewayRoad.id,
  roadPolygon: forestGatewayRoad.polygon,
  colliderIds: ["forest_entry_gate_post_0", "forest_entry_gate_post_1"],
});
LAND_MAPS.forest.gateways = [forestGateway];
for (const [index, footprint] of forestGateway.postFootprints.entries()) {
  const xs = footprint.map((point) => point[0]);
  const ys = footprint.map((point) => point[1]);
  LAND_MAPS.forest.obstacles.push(obstacle(
    forestGateway.colliderIds[index], "fence", Math.min(...xs), Math.min(...ys),
    Math.max(...xs) - Math.min(...xs), Math.max(...ys) - Math.min(...ys),
    118, "gateway_post", forestGateway.elevation, footprint,
  ));
}
LAND_MAPS.hub = decorateVillageGround(LAND_MAPS.hub);

export function landDistanceToSegment(
  point: LandPosition,
  a: LandPoint,
  b: LandPoint,
): number {
  const dx = b[0] - a[0],
    dy = b[1] - a[1],
    t = Math.max(
      0,
      Math.min(
        1,
        ((point.x - a[0]) * dx + (point.y - a[1]) * dy) /
          (dx * dx + dy * dy || 1),
      ),
    );
  return Math.hypot(point.x - a[0] - t * dx, point.y - a[1] - t * dy);
}
export function landPointInPolygon(
  point: LandPosition,
  polygon: readonly LandPoint[],
): boolean {
  let inside = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const a = polygon[j],
      b = polygon[i];
    if (landDistanceToSegment(point, a, b) < 1e-7) return true;
    if (
      a[1] > point.y !== b[1] > point.y &&
      point.x < ((b[0] - a[0]) * (point.y - a[1])) / (b[1] - a[1]) + a[0]
    )
      inside = !inside;
  }
  return inside;
}
export function isLandWalkable(
  map: LandMap,
  point: LandPosition,
  bodyMargin = 12,
): boolean {
  if (
    !Number.isFinite(point.x) ||
    !Number.isFinite(point.y) ||
    point.x < 0 ||
    point.y < 0 ||
    point.x > map.width ||
    point.y > map.height
  )
    return false;
  const onFloor = (p: LandPosition) =>
    map.surfaces.some(
      (s) => s.walkable !== false && landPointInPolygon(p, s.polygon),
    );
  if (!onFloor(point)) return false;
  for (let i = 0; i < 8; i++)
    if (
      !onFloor({
        x: point.x + Math.cos((i * Math.PI) / 4) * bodyMargin,
        y: point.y + Math.sin((i * Math.PI) / 4) * bodyMargin,
      })
    )
      return false;
  return !map.obstacles.some(
    (o) =>
      landPointInPolygon(point, o.footprint) ||
      o.footprint.some(
        (a, i) =>
          landDistanceToSegment(
            point,
            a,
            o.footprint[(i + 1) % o.footprint.length],
          ) < bodyMargin,
      ),
  );
}
export function isLandSegmentWalkable(
  map: LandMap,
  from: LandPosition,
  to: LandPosition,
  bodyMargin = 12,
): boolean {
  const steps = Math.max(
    1,
    Math.ceil(Math.hypot(to.x - from.x, to.y - from.y) / 6),
  );
  for (let i = 0; i <= steps; i++)
    if (
      !isLandWalkable(
        map,
        {
          x: from.x + ((to.x - from.x) * i) / steps,
          y: from.y + ((to.y - from.y) * i) / steps,
        },
        bodyMargin,
      )
    )
      return false;
  return true;
}
export function mapFootMaterial(
  map: LandMap,
  point: LandPosition,
): LandMaterial {
  return (
    [...map.surfaces]
      .sort(
        (a, b) =>
          (b.priority ?? 0) - (a.priority ?? 0) || b.elevation - a.elevation,
      )
      .find((s) => landPointInPolygon(point, s.polygon))?.material ?? "sand"
  );
}
export function nearestSafeLandPoint(
  map: LandMap,
  point: LandPosition,
): LandPosition {
  // Recovery must also clear LandCollision.WALK_CLEARANCE, not only the API's 12px body.
  const recoveryClearance = 13;
  if (isLandWalkable(map, point, recoveryClearance))
    return { x: point.x, y: point.y };
  for (let radius = 16; radius <= 2600; radius += 16)
    for (let i = 0; i < 32; i++) {
      const candidate = {
        x: point.x + Math.cos((i * Math.PI) / 16) * radius,
        y: point.y + Math.sin((i * Math.PI) / 16) * radius,
      };
      if (isLandWalkable(map, candidate, recoveryClearance)) return candidate;
    }
  return { ...map.spawn };
}

export const HOMESTEAD_INTERIOR: LandMap & {
  entry: LandPosition;
  exit: LandPosition;
  bed: LandPosition;
  chest: LandPosition;
  archive: LandPosition;
  display: LandPosition;
} = {
  id: "home",
  layoutVersion: 1,
  width: 960,
  height: 720,
  spawn: { x: 480, y: 580 },
  entry: { x: 480, y: 580 },
  exit: { x: 480, y: 625 },
  bed: { x: 270, y: 250 },
  chest: { x: 700, y: 340 },
  archive: { x: 650, y: 210 },
  display: { x: 420, y: 175 },
  surfaces: [floor("home_floor", rectangle(80, 150, 800, 490), "wood", 0)],
  obstacles: [
    obstacle("home_bed", "crate", 170, 185, 180, 100, 34, "rattan_bed"),
    obstacle("home_archive", "crate", 590, 180, 140, 75, 68, "archive_desk"),
    obstacle("home_chest", "crate", 655, 315, 100, 65, 42, "storage_chest"),
    obstacle("home_display", "crate", 380, 150, 100, 48, 85, "display_shelf"),
  ],
  stairs: [],
  terraces: [{ id: "home_floor", elevation: 0 }],
  routes: [
    [
      [480, 580],
      [480, 420],
      [270, 330],
    ],
    [
      [480, 420],
      [700, 425],
    ],
    [
      [480, 420],
      [520, 300],
      [650, 280],
    ],
    [
      [480, 420],
      [420, 280],
    ],
    [
      [480, 580],
      [480, 625],
    ],
  ],
};
