extends RefCounted

const SHADER_SOURCE := """
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;
uniform vec4 base_color : source_color;
uniform int kind = 0;
uniform sampler2D material_atlas : source_color, filter_nearest, repeat_enable;
uniform bool has_atlas = false;
uniform sampler2D micro_texture : source_color, filter_nearest, repeat_enable;
uniform bool has_micro = false;
uniform int atlas_cell = 0;
varying vec3 at;
varying vec3 normal_world;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
void vertex() {
	at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	normal_world=normalize((MODEL_MATRIX*vec4(NORMAL,0.0)).xyz);
}
void fragment() {
	if(abs(normal_world.z)>.85) NORMAL=normalize((VIEW_MATRIX*vec4(0.0,0.0,1.0,0.0)).xyz);
	vec2 planar=abs(normal_world.z)>.6 ? at.xy : abs(normal_world.y)>.6 ? at.xz : at.yz;
	vec2 pixel=floor(planar/2.7);
	float fine=floor(hash(vec3(pixel,0.0))*5.0)/4.0;
	vec2 broad_at=planar/110.0;
	vec2 blend=smoothstep(vec2(0.0),vec2(1.0),fract(broad_at));
	vec2 cell=floor(broad_at);
	float patch=mix(mix(hash(vec3(cell,0.0)),hash(vec3(cell+vec2(1,0),0.0)),blend.x),mix(hash(vec3(cell+vec2(0,1),0.0)),hash(vec3(cell+vec2(1,1),0.0)),blend.x),blend.y);
	vec3 color=base_color.rgb*(.93+fine*.035+patch*.09);
	if(has_micro) { vec3 texel=texture(micro_texture,fract(planar/96.0)).rgb; float luma=dot(texel,vec3(.299,.587,.114)); color*=.84+mix(vec3(luma),texel,.28)*.36; }
	if(has_atlas) {
		vec2 tile=fract(planar/150.0);
		vec2 origin=vec2(float(atlas_cell%3)/3.0,float(atlas_cell/3)/2.0);
		vec3 texel=texture(material_atlas,origin+tile*vec2(1.0/3.0,.5)).rgb;
		color*=.78+texel*.50;
	}
	if(kind==3) {
		float seam=step(.95,hash(vec3(floor(planar/19.0),3.0)));
		color*=(1.0-seam*.23)*.82;
	}
	if(kind==4 || kind==6) {
		float seam=step(21.0,mod(planar.x,23.0));
		float fiber=step(.80,hash(vec3(floor(planar.x/2.5),floor(planar.y/14.0),4.0)));
		color*=1.0-seam*.4-fiber*.10;
	}
	if(kind==5) {
		float course=step(25.0,mod(planar.y,28.0));
		float fiber=step(2.5,mod(planar.x+floor(planar.y/28.0)*7.0,4.0));
		color*=1.0-course*.25-fiber*.10;
	}
	if(kind==9) {
		float fiber=hash(vec3(floor(planar.x/9.0),floor(planar.y/2.7),9.0));
		color*=.96+fiber*.045;
	}
	if(kind==10) {
		vec2 thread=floor(planar/3.0);
		float weave=mod(thread.x+thread.y,2.0);
		float band=step(18.0,mod(planar.x,24.0));
		color*=.90+weave*.12+band*.10;
	}
	if(kind==8) color*=.92+step(13.0,mod(planar.x,18.0))*.12;
	ALBEDO=color;
	ROUGHNESS=.96;
	SPECULAR=.08;
}
"""
var _shader: Shader
var _cache: Dictionary = {}
var _atlas: Texture2D

func _init() -> void:
	_shader=Shader.new()
	_shader.code=SHADER_SOURCE
	for path in ["res://resources/art/land-materials-v1.png","res://resources/art/land-material-atlas.png","res://resources/art/land-materials-atlas.png"]:
		if ResourceLoader.exists(path):
			_atlas=load(path)
			break

func get_material(id: String) -> ShaderMaterial:
	var key: String={"dock":"wood","bridge":"wood","cliff":"stone"}.get(id,id)
	if _cache.has(key): return _cache[key]
	var types: Dictionary={"dirt":[0,"9b7c52",0],"grass":[1,"76a268",-1],"sand":[2,"cdbb87",-1],"stone":[3,"969d98",1],"wood":[4,"887055",2],"thatch":[5,"a48c63",4],"bamboo":[6,"b39d74",3],"leaves":[7,"657361",5],"metal":[8,"344a4b",-1],"bridge_board":[9,"88775f",-1],"bridge_board_light":[9,"8b7a62",-1],"bridge_board_dark":[9,"85745d",-1],"terracotta":[0,"aa7050",-1],"cloth_cream":[0,"d2bd91",-1],"cloth_teal":[0,"4c8178",-1],"office_shell":[8,"c6c5b4",-1],"office_glass":[8,"425e65",-1],"corporate_copper":[8,"a76045",-1],"roof_tiles":[5,"97674e",-1],"woven_teal":[10,"568779",-1],"paper":[0,"bfae86",-1]}
	var data: Array=types.get(key,types.stone)
	var material:=ShaderMaterial.new()
	material.shader=_shader
	material.set_shader_parameter("kind",int(data[0]))
	material.set_shader_parameter("base_color",Color(str(data[1])))
	var tile: String={"dirt":"dirt","grass":"grass","sand":"sand","stone":"limestone"}.get(key,"")
	var tile_path:="res://resources/art/library/crawl/"+tile+".png"
	var has_micro:=tile!="" and ResourceLoader.exists(tile_path)
	material.set_shader_parameter("has_micro",has_micro)
	if has_micro: material.set_shader_parameter("micro_texture",load(tile_path))
	material.set_shader_parameter("has_atlas",not has_micro and _atlas!=null and int(data[2])>=0)
	if _atlas: material.set_shader_parameter("material_atlas",_atlas)
	material.set_shader_parameter("atlas_cell",maxi(0,int(data[2])))
	_cache[key]=material
	return material
