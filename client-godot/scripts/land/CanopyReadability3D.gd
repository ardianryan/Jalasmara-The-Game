extends RefCounted

const SOURCE := """
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;
uniform sampler2D canopy_atlas : source_color, filter_nearest;
uniform vec4 atlas_region = vec4(0.0,0.0,1.0,1.0);
uniform vec2 crown_size = vec2(250.0);
uniform vec2 reveal_center = vec2(0.0);
uniform float reveal = 0.0;
void vertex() {
	// Match the original Sprite3D's full camera-facing billboard, including shadows.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(MAIN_CAM_INV_VIEW_MATRIX[0], MAIN_CAM_INV_VIEW_MATRIX[1], MAIN_CAM_INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
float ordered_pixel(vec2 point) {
	ivec2 p = ivec2(mod(floor(point),4.0));
	int value = ((p.x & 1) ^ (p.y & 1))*8 + (p.y & 1)*4 + (((p.x >> 1) & 1) ^ ((p.y >> 1) & 1))*2 + ((p.y >> 1) & 1);
	return (float(value)+0.5)/16.0;
}
void fragment() {
	vec4 leaf = texture(canopy_atlas,UV);
	if(leaf.a<0.2) discard;
	if(reveal>0.001) {
		vec2 local_uv = (UV-atlas_region.xy)/atlas_region.zw;
		vec2 point = (local_uv-vec2(0.5))*crown_size;
		float body = 1.0-smoothstep(0.72,1.28,length((point-reveal_center)/vec2(36.0,53.0)));
		float retained = 1.0-reveal*body*0.98;
		if(ordered_pixel(point/2.7)>retained) discard;
	}
	ALBEDO=leaf.rgb;
	ROUGHNESS=1.0;
}
"""

var entries: Array[Dictionary] = []
var _shader: Shader
var _masks: Dictionary = {}
var revealed := 0

func register(crown: Sprite3D, frame: AtlasTexture, width: float) -> void:
	if _shader==null:
		_shader=Shader.new()
		_shader.code=SOURCE
	var key:=str(frame.atlas.get_instance_id())+str(frame.region)
	if not _masks.has(key):
		# A single cached CPU mask per atlas frame; never read textures during update.
		var image:=frame.get_image()
		if image.is_compressed(): image.decompress()
		image.resize(64,64,Image.INTERPOLATE_NEAREST)
		_masks[key]=image
	var size:=Vector2(width,width*frame.region.size.y/frame.region.size.x)
	var material:=ShaderMaterial.new()
	material.shader=_shader
	material.set_shader_parameter("canopy_atlas",frame.atlas)
	material.set_shader_parameter("atlas_region",Vector4(frame.region.position.x/frame.atlas.get_width(),frame.region.position.y/frame.atlas.get_height(),frame.region.size.x/frame.atlas.get_width(),frame.region.size.y/frame.atlas.get_height()))
	material.set_shader_parameter("crown_size",size)
	crown.material_override=material
	entries.append({"node":crown,"size":size,"mask":_masks[key],"material":material,"amount":0.0,"hold":0.0,"target":false})

func update(feet: Vector3, up: Vector3, forward: Vector3, delta: float, right := Vector3.ZERO) -> void:
	revealed=0
	var screen_right:=forward.cross(up).normalized() if right.is_zero_approx() else right
	var body:=feet+up*48.0-forward*8.0
	for entry in entries:
		var relative: Vector3=body-entry.node.global_position
		var local:=Vector2(relative.dot(screen_right),-relative.dot(up))
		var in_front: bool=relative.dot(forward)>12.0
		var overlaps:=false
		if in_front and absf(local.x)<entry.size.x*.5+28 and absf(local.y)<entry.size.y*.5+48:
			for offset in [Vector2(0,-28),Vector2(-15,0),Vector2(15,0),Vector2(0,27)]:
				var uv: Vector2=(local+offset)/entry.size+Vector2(.5,.5)
				if uv.x<0 or uv.x>=1 or uv.y<0 or uv.y>=1: continue
				if entry.mask.get_pixel(int(uv.x*64),int(uv.y*64)).a>.35:
					overlaps=true
					break
		if overlaps: entry.hold=.18
		else: entry.hold=maxf(0,float(entry.hold)-delta)
		entry.target=in_front and float(entry.hold)>0
		var amount:=move_toward(float(entry.amount),1.0 if entry.target else 0.0,delta/(.14 if entry.target else .24))
		if amount>0.001: revealed+=1
		if amount>0.001 or float(entry.amount)>0.001:
			entry.material.set_shader_parameter("reveal_center",local)
			entry.material.set_shader_parameter("reveal",amount)
		entry.amount=amount

func debug_status() -> Dictionary:
	var active: Array=[]
	for index in range(entries.size()):
		if float(entries[index].amount)>.001: active.append({"index":index,"amount":entries[index].amount,"target":entries[index].target})
	return {"crowns":entries.size(),"revealed":revealed,"active":active,"cachedMasks":_masks.size(),"trunksUntouched":true}
