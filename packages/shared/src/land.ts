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
export type LandMap = {
  id: "hub" | "forest";
  layoutVersion: number;
  landmass?: LandPoint[];
  width: number;
  height: number;
  spawn: { x: number; y: number };
  surfaces: LandSurface[];
  obstacles: LandObstacle[];
  stairs: LandStair[];
  terraces: { id: string; elevation: number }[];
  routes: LandPoint[][];
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
): LandObstacle => ({
  id,
  kind,
  x,
  y,
  width,
  height,
  height3d,
  footprint:
    kind === "house"
      ? [
          [x + width * 0.16, y],
          [x + width, y + height * 0.27],
          [x + width - width * 0.16, y + height],
          [x, y + height - height * 0.27],
        ]
      : rectangle(x, y, width, height),
  variant,
  elevation,
});
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
  floor("garden_wing", rectangle(1620, 450, 560, 285), "grass", 2),
  floor("forest_ridge", rectangle(1670, 80, 680, 310), "sand", 3),
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
const hubObstacles: LandObstacle[] = [
  obstacle("kedai_waras", "house", 360, 420, 400, 175, 155, "thatch", 2),
  obstacle("galangan_beno", "house", 1090, 390, 420, 170, 125, "workshop", 2),
  obstacle("pos_cakrawala", "house", 1840, 140, 300, 105, 135, "metal", 3),
  obstacle("kebun_darmi", "garden", 1810, 485, 330, 180, 34, "raised_beds", 2),
  obstacle("batu_pelataran", "rock", 760, 835, 105, 65, 70, "limestone", 1),
  obstacle("palm_lower", "tree", 1530, 1020, 34, 34, 190, "palm", 1),
  obstacle("palm_kedai", "tree", 800, 430, 34, 34, 185, "palm", 2),
  obstacle("palm_garden", "tree", 1640, 600, 34, 34, 180, "palm", 2),
  obstacle("market_crates", "crate", 470, 915, 65, 48, 38, "woven", 1),
  obstacle("dock_crates", "crate", 920, 1190, 80, 55, 48, "wood", 0),
  obstacle("forest_gate_west", "fence", 2240, 80, 25, 110, 80, "bamboo", 3),
  obstacle("forest_gate_east", "fence", 2325, 80, 25, 110, 80, "bamboo", 3),
];
const forestRoutes: LandPoint[][] = [
  [
    [200, 1320],
    [350, 1250],
    [480, 1210],
    [650, 1050],
    [930, 950],
    [1200, 730],
    [1530, 650],
    [1830, 470],
    [2080, 430],
  ],
  [
    [1200, 730],
    [1600, 1000],
    [2130, 1050],
    [2160, 1090],
  ],
  [
    [1200, 730],
    [1200, 300],
  ],
];
const forestSurfaces: LandSurface[] = [
  floor(
    "forest_west_land",
    [
      [80, 120],
      [1340, 120],
      [1340, 680],
      [1320, 900],
      [1370, 1180],
      [1320, 1480],
      [120, 1480],
      [80, 1350],
    ],
    "grass",
  ),
  floor(
    "forest_east_land",
    [
      [1560, 120],
      [2340, 120],
      [2350, 1430],
      [1560, 1430],
      [1580, 1110],
      [1530, 900],
      [1560, 620],
    ],
    "grass",
  ),
  floor("bridge_upper", strip([1280, 710], [1620, 620], 150), "bridge", 0, 30),
  floor("bridge_lower", strip([1280, 790], [1620, 1020], 150), "bridge", 0, 30),
];
for (const [routeIndex, route] of forestRoutes.entries())
  for (let i = 1; i < route.length; i++) {
    forestSurfaces.push({
      ...floor(
        `forest_trail_${routeIndex}_${i}`,
        strip(route[i - 1], route[i], 105),
        "dirt",
        0,
        10,
      ),
      walkable: false,
    });
  }
const forestObstacles: LandObstacle[] = [
  obstacle("bridge_east", "fence", 2140, 360, 180, 80, 75, "broken_bridge"),
  obstacle("landslide_north", "rock", 1080, 155, 240, 90, 125, "landslide"),
  obstacle("gate_east", "fence", 2205, 1140, 110, 220, 110, "bamboo"),
  obstacle("forest_hut", "house", 1960, 600, 160, 100, 110, "thatch"),
];
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
    layoutVersion: 4,
    landmass: [
      [240, 300],
      [680, 280],
      [1080, 305],
      [1530, 300],
      [1600, 170],
      [1650, 65],
      [2060, 40],
      [2370, 70],
      [2390, 420],
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
    stairs: hubStairs,
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
    layoutVersion: 4,
    width: 2400,
    height: 1600,
    spawn: { x: 200, y: 1320 },
    surfaces: forestSurfaces,
    obstacles: forestObstacles,
    stairs: [],
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
  [1640, 680, 140, 50, 2],
  [315, 480, 35, 120, 2],
].entries())
  LAND_MAPS.hub.surfaces.push({
    ...floor(
      `hub_edge_grass_${index}`,
      rectangle(x, y, w, h),
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
  if (isLandWalkable(map, point)) return { x: point.x, y: point.y };
  for (let radius = 16; radius <= 2600; radius += 16)
    for (let i = 0; i < 32; i++) {
      const candidate = {
        x: point.x + Math.cos((i * Math.PI) / 16) * radius,
        y: point.y + Math.sin((i * Math.PI) / 16) * radius,
      };
      if (isLandWalkable(map, candidate)) return candidate;
    }
  return { ...map.spawn };
}
