import {test} from 'node:test';
import assert from 'node:assert/strict';
import {parseForestPoint} from './forest-point.mjs';
test('forest point validates the authored footprint and body clearance before use',()=>{
 let checked;const point=parseForestPoint('350,1250',(value,margin)=>{checked={value,margin};return true;});
 assert.deepEqual(point,{x:350,y:1250});assert.deepEqual(checked,{value:point,margin:13});
 assert.throws(()=>parseForestPoint('350,1250',()=>false),/floor with 13px/);
});
test('empty, nonfinite and malformed forest point flags cannot seed a fixture',()=>{
 for(const value of ['',',1250','350,','350,1250,1','NaN,1250','350,Infinity'])assert.throws(()=>parseForestPoint(value,()=>true));
});
test('default scene point is preserved and still checked',()=>{
 assert.deepEqual(parseForestPoint(undefined,()=>true),{x:650,y:1050});assert.throws(()=>parseForestPoint(undefined,()=>false),/clearance/);
});
