import assert from 'node:assert/strict';
export function parseForestPoint(text,isWalkable) {
 let point={x:650,y:1050};
 if(text!==undefined){
  const parts=text.split(',').map(value=>value.trim());
  assert(parts.length===2&&parts.every(value=>value!==''),'PROFILE_FOREST_POINT must be x,y');
  point={x:Number(parts[0]),y:Number(parts[1])};
  assert(Number.isFinite(point.x)&&Number.isFinite(point.y),'Forest coordinates must be finite');
 }
 assert(isWalkable(point,13),'Forest point must be on floor with 13px body clearance');
 return point;
}
