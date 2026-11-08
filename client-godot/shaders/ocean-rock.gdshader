shader_type canvas_item;
#include "res://shaders/reef-variation.gdshaderinc"
uniform vec2 atlas_grid = vec2(3.0,2.0);
uniform float material_column = 0.0;
uniform float world_top = 0.0;
uniform float face_height = 300.0;
uniform bool vertical_cliff = false;
varying vec2 face_point;
varying vec4 vertex_tint;
void vertex(){
	face_point=VERTEX;
	vertex_tint=COLOR;
}
void fragment(){
	float depth=world_top+face_point.y;
	float column=material_column;
	if(vertical_cliff){column=depth<2080.0?0.0:(depth<3060.0?1.0:2.0);}
	vec4 texel=vec4(reef_variation(TEXTURE,(vec2(0.0,world_top)+face_point)/360.0,column),1.0);
	float shade=0.84+0.16*(1.0-clamp(face_point.y/max(face_height,160.0),0.0,1.0));
	vec3 water_tint=depth<1100.0?vec3(0.95,1.0,0.96):(depth<2080.0?vec3(0.81,0.94,0.87):vec3(0.78,0.88,0.93));
	COLOR=vec4(texel.rgb*shade*water_tint,texel.a)*vertex_tint;
}
