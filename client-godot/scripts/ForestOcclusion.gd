extends Node2D

const CROWN_SHADER := """
shader_type canvas_item;
uniform float strength = 1.2;
uniform float wind_speed = 1.0;
uniform float wind_phase = 0.0;
uniform vec2 head = vec2(0.0);
uniform bool reveal_head = false;
varying vec2 leaf_position;
void vertex() {
	leaf_position = VERTEX;
	float root_weight = clamp(-VERTEX.y / 180.0, 0.0, 1.0);
	VERTEX.x += sin(TIME * wind_speed + VERTEX.y * 0.02 + wind_phase) * strength * root_weight;
}
void fragment() {
	vec3 leaf = texture(TEXTURE, UV).rgb;
	float mask = smoothstep(0.015, 0.05, leaf.g - leaf.b) * smoothstep(-0.02, 0.025, leaf.g - leaf.r * 0.93);
	float reveal = reveal_head ? mix(0.28, 1.0, smoothstep(20.0, 70.0, distance(leaf_position, head))) : 1.0;
	COLOR.a *= mask * reveal;
}
"""
static var _shared_shader: Shader
static var _images: Dictionary = {}
var crown: Polygon2D
var trunk: Polygon2D
var focus: Node2D
var _base_pixel := Vector2.ZERO
var _scale := 1.5625
var _trunk_radius := 0.0
var _image: Image
var _material: ShaderMaterial
var _behind := false
var _covered := false
var _alpha_at_head := 0.0

func configure(texture: Texture2D, base_pixel: Vector2, polygon_pixels: Array, trunk_radius := 0.0, pixel_scale := 1.5625, trunk_polygon_pixels: Array = []) -> void:
	_base_pixel = base_pixel
	_scale = pixel_scale
	_trunk_radius = trunk_radius * pixel_scale
	position = base_pixel * pixel_scale
	name = "TreeAt%d_%d" % [position.x,position.y]
	var polygon := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in polygon_pixels:
		polygon.append((point-base_pixel)*pixel_scale)
		uv.append(point)
	if trunk_polygon_pixels.size() >= 3:
		trunk = Polygon2D.new()
		trunk.name = "SolidWood"
		var wood_polygon := PackedVector2Array()
		var wood_uv := PackedVector2Array()
		for point in trunk_polygon_pixels:
			wood_polygon.append((point-base_pixel)*pixel_scale)
			wood_uv.append(point)
		trunk.polygon = wood_polygon
		trunk.uv = wood_uv
		trunk.texture = texture
		trunk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(trunk)
	crown = Polygon2D.new()
	crown.name = "AlphaCanopy"
	crown.polygon = polygon
	crown.uv = uv
	crown.texture = texture
	crown.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _shared_shader == null:
		_shared_shader = Shader.new()
		_shared_shader.code = CROWN_SHADER
	_material = ShaderMaterial.new()
	_material.shader = _shared_shader
	_material.set_shader_parameter("wind_phase",fmod(base_pixel.x*0.031,TAU))
	crown.material = _material
	add_child(crown)
	var key := texture.get_instance_id()
	if not _images.has(key):
		var image := texture.get_image()
		if image.is_compressed(): image.decompress()
		_images[key] = image
	_image = _images[key]

func set_focus(actor: Node2D) -> void:
	focus = actor
	update_occlusion()

func alpha_at_world(point: Vector2) -> float:
	if not is_instance_valid(crown) or _image == null:
		return 0.0
	var local := to_local(point)
	if not Geometry2D.is_point_in_polygon(local,crown.polygon):
		return 0.0
	var pixel := local/_scale+_base_pixel
	if pixel.x<0 or pixel.y<0 or pixel.x>=_image.get_width() or pixel.y>=_image.get_height():
		return 0.0
	var color := _image.get_pixel(int(pixel.x),int(pixel.y))
	return color.a * smoothstep(0.015,0.05,color.g-color.b) * smoothstep(-0.02,0.025,color.g-color.r*0.93)

func update_occlusion() -> void:
	if not is_instance_valid(focus) or _material == null:
		return
	update_player(focus.global_position)

func update_player(feet: Vector2) -> void:
	if _material == null:
		return
	_behind = feet.y < global_position.y - 5.0
	var head := feet + Vector2(0,-76)
	_alpha_at_head = alpha_at_world(head)
	_covered = _behind and _alpha_at_head>0.35
	_material.set_shader_parameter("head",to_local(head))
	_material.set_shader_parameter("reveal_head",_covered)
	var state := get_node_or_null("/root/EnvironmentState")
	var conditions: Dictionary = state.snapshot() if state != null else {}
	var reduced := bool(conditions.get("reduced_motion",false))
	var wind := absf(float(conditions.get("wind_x",0.0)))
	_material.set_shader_parameter("strength",0.0 if reduced else clampf(0.8+wind*0.025,0.8,2.0))

func _process(_delta: float) -> void:
	update_occlusion()

func debug_status() -> Dictionary:
	return {"base":[global_position.x,global_position.y],"footY":global_position.y,"behind":_behind,"headCovered":_covered,"fadeActive":_covered,"alphaAtHead":_alpha_at_head,"leafMasked":true,"woodLayer":is_instance_valid(trunk),"trunkRadius":_trunk_radius,"sway":_material.get_shader_parameter("strength") if _material else 0.0}
