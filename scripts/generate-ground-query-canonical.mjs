// Run from the repository root with node --import tsx.
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { mkdirSync, writeFileSync } from "node:fs";
const { WORLD } = await import(pathToFileURL(resolve("packages/shared/src/world.ts")));
const { landPointInPolygon } = await import(pathToFileURL(resolve("packages/shared/src/land.ts")));
const output = resolve(process.argv[2] ?? "scripts/tests/fixtures/ground-query-canonical.json");
const cases = [];
const metadata = {};
for (const area of ["hub", "forest"]) {
  const map = WORLD.landMaps[area];
  const levels = Object.fromEntries(map.terraces.map(t => [t.id, t.elevation * 48]));
  const points = [[1135.271484375,1125],[1135.271484375,1124.9990234375],[1135.271484375,1124.989990234375]];
  for (let y = 130; y < map.height; y += 180)
    for (let x = 70; x < map.width; x += 230) points.push([x,y]);
  for (const stair of map.stairs) {
    const [a,b] = stair.path, length = Math.hypot(b[0]-a[0],b[1]-a[1]);
    const nx = -(b[1]-a[1])/length, ny = (b[0]-a[0])/length;
    for (const end of [a,b]) for (const lateral of [-.49,0,.49])
      for (const offset of [-.01,-.001,0,.001,.01])
        points.push([end[0]+nx*stair.width*lateral, end[1]+ny*stair.width*lateral+offset]);
  }
  for (const raw of points) {
    const point = {x:Math.fround(raw[0]),y:Math.fround(raw[1])};
    let floorHeight = 0, priority = -10000;
    const matches = [];
    map.surfaces.forEach((s,index) => {
      if (!landPointInPolygon(point,s.polygon)) return;
      matches.push(index);
      if ((s.priority??0) >= priority) { priority=s.priority??0; floorHeight=s.elevation*48; }
    });
    let groundHeight = floorHeight;
    for (const stair of map.stairs) {
      const [a,b] = stair.path, dx=b[0]-a[0],dy=b[1]-a[1];
      const t=((point.x-a[0])*dx+(point.y-a[1])*dy)/(dx*dx+dy*dy);
      if (t<0 || t>1 || Math.hypot(point.x-a[0]-t*dx,point.y-a[1]-t*dy)>stair.width*.5) continue;
      const steps=Math.max(1,stair.steps??4);
      const fraction=stair.type==="stairs" ? (Math.min(steps-1,Math.max(0,Math.floor(t*steps)))+1)/steps : t;
      groundHeight=levels[stair.from]+(levels[stair.to]-levels[stair.from])*fraction;
    }
    cases.push({area,point:[point.x,point.y],matches,floorHeight,groundHeight});
  }
  metadata[area]={layoutVersion:map.layoutVersion,surfaceIds:map.surfaces.map(s=>s.id)};
}
const polygons = [
  {polygon:[[0,0],[2,0],[2,2],[0,2]], points:[[1,1],[0,1],[-.00000005,1],[-.0000002,1],[2.000001,1],[2,2],[-.00000009999999,1],[-.0000001,1],[-.00000010000001,1],[1,-.00000009999999],[1,-.00000010000001]]},
  {polygon:[[0,0],[4,0],[4,1],[1,1],[1,4],[0,4]], points:[[.5,3],[3,3],[1,1],[3,.5]]},
  {polygon:[[1.00000001,0],[2,0],[2,2],[1.00000001,2]], points:[[1,1],[1.0000002,1]]},
  {polygon:[[1.000000095,0],[2,0],[2,2],[1.000000095,2]], points:[[1,1],[.99999988,1],[1.00000024,1]]},
];
const polygonCases=polygons.flatMap(({polygon,points})=>points.map(p=>{
  const point={x:Math.fround(p[0]),y:Math.fround(p[1])};
  return {polygon,point:[point.x,point.y],inside:landPointInPolygon(point,polygon)};
}));
mkdirSync(resolve(output,".."),{recursive:true});
writeFileSync(output,JSON.stringify({authority:"packages/shared/src/land.ts landPointInPolygon; float32 controller coordinates, raw scalar manifest polygons",metadata,cases,polygonCases},null,2)+"\n");
console.log(JSON.stringify({output,cases:cases.length,polygonCases:polygonCases.length}));
