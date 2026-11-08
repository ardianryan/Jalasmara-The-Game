extends Node3D

const TILT := deg_to_rad(12.0)
const ANCHOR := Vector2(1550, 620)
const ATLAS_PATH := "res://resources/art/ocean-atmosphere-atlas.png"
const CARD_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform sampler2D atlas : source_color, filter_nearest;
uniform vec4 region;
uniform vec4 tint : source_color;
uniform float contrast = 0.6;
uniform float visibility = 0.7;
uniform float world_surface = 400.0;
uniform vec2 card_center;
uniform vec2 card_size;
uniform vec2 layer_offset;
uniform float sway = 0.0;
uniform float phase = 0.0;
varying vec2 local_uv;
void vertex() {
	local_uv = UV;
	VERTEX.x += sin(TIME * 0.6 + phase + UV.y * 2.5) * sway * (1.0 - UV.y);
}
void fragment() {
	vec4 texel = texture(atlas, region.xy + local_uv * region.zw);
	if (texel.a < 0.2) discard;
	float world_y = card_center.y + layer_offset.y + (local_uv.y - 0.5) * card_size.y;
	if (world_y < world_surface + 18.0) discard;
	float luminance = dot(texel.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 detail = mix(vec3(luminance), texel.rgb, contrast);
	detail = (detail - vec3(0.5)) * contrast + vec3(0.5);
	ALBEDO = mix(tint.rgb, detail * tint.rgb * 1.65, visibility);
}
"""
const WATER_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform vec4 upper : source_color;
uniform vec4 lower : source_color;
void fragment() {
	float depth = smoothstep(0.0, 1.0, UV.y);
	ALBEDO = mix(upper.rgb, lower.rgb, depth);
}
"""
var _layers: Array[Dictionary] = []
var _cards: Array[Dictionary] = []
var _base_material: ShaderMaterial
var _card_shader: Shader
var _atlas: Texture2D
var _surface := 400.0
var _depth := 0.0
var _reduced := false
var _configured := false

static func layer_profiles() -> Array[Dictionary]:
	return [
		{"id":"far", "name":"Far", "depth":-1550.0, "parallax":Vector2(0.18,0.12), "contrast":0.35, "visibility":0.46},
		{"id":"mid", "name":"Mid", "depth":-950.0, "parallax":Vector2(0.42,0.28), "contrast":0.64, "visibility":0.72},
		{"id":"near", "name":"Near", "depth":-420.0, "parallax":Vector2(0.70,0.55), "contrast":0.88, "visibility":0.88},
	]

func configure(world: Dictionary) -> void:
	if _configured:
		return
	_configured = true
	_surface = float(world.get("surface", 400))
	if ResourceLoader.exists(ATLAS_PATH):
		_atlas = load(ATLAS_PATH) as Texture2D
	var width := float(world.get("width", 6144))
	var height := float(world.get("height", 3584))
	var shader := Shader.new()
	shader.code = WATER_SHADER
	_base_material = ShaderMaterial.new()
	_base_material.shader = shader
	_quad(self, "ContinuousWater", Vector2(width / 2, (_surface + height) / 2), Vector2(width + 6000, height - _surface + 1800), -2100, _base_material)
	for profile in layer_profiles():
		var layer := Node3D.new()
		layer.name = profile.name
		add_child(layer)
		var record := profile.duplicate()
		record["node"] = layer
		record["tint"] = Color.WHITE
		record["offset"] = Vector2.ZERO
		record["cards"] = 0
		_layers.append(record)
	if _atlas:
		_card_shader = Shader.new()
		_card_shader.code = CARD_SHADER
		_build_cards(width)
	update_camera(ANCHOR)

func _build_cards(width: float) -> void:
	# Overlapping wall masses leave negative space for the playable reef in front.
	for band in range(3):
		for column in range(6):
			var center := Vector2(-250 + column * 1450 + (band % 2) * 420, 1140 + band * 1160)
			_card(0, 0 if column % 3 != 1 else 1, center, Vector2(1760, 1530), false)
	for column in range(7):
		var center := Vector2(120 + column * 980, 1530 + (column % 2) * 260)
		_card(1, 1 if column % 2 == 0 else 0, center, Vector2(980, 1120), false)
		_card(1, 4, Vector2(center.x + 320, 2900 + (column % 2) * 270), Vector2(1200, 1050), false)
	for point in [Vector2(1520,1370),Vector2(3860,2070),Vector2(4930,3090)]:
		_card(1, 2, point, Vector2(1020,920), false)
	for column in range(9):
		var x := 80.0 + column * (width / 8.0)
		_card(2, 3, Vector2(x, 1270 + (column % 3) * 180), Vector2(510,890), true)
	for point in [Vector2(380,1110),Vector2(2300,1540),Vector2(3480,2350),Vector2(5550,3000)]:
		_card(2, 5, point, Vector2(680,650), false)

func _card(layer_index: int, cell: int, center: Vector2, size: Vector2, plant: bool) -> void:
	var layer: Dictionary = _layers[layer_index]
	var material := ShaderMaterial.new()
	material.shader = _card_shader
	material.set_shader_parameter("atlas", _atlas)
	material.set_shader_parameter("region", Vector4(float(cell % 3) / 3.0, float(cell / 3) / 2.0, 1.0 / 3.0, 0.5))
	material.set_shader_parameter("world_surface", _surface)
	material.set_shader_parameter("card_center", center)
	material.set_shader_parameter("card_size", size)
	material.set_shader_parameter("phase", center.x * 0.03)
	var mesh := _quad(layer.node, "Lamun" if plant else "Relief", center, size, float(layer.depth) + float(_cards.size() % 7), material)
	_cards.append({"mesh":mesh,"material":material,"layer":layer_index,"plant":plant})
	layer["cards"] = int(layer.cards) + 1

func _quad(parent: Node3D, label: String, center: Vector2, dimensions: Vector2, depth: float, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	var quad := QuadMesh.new()
	quad.size = dimensions
	mesh.mesh = quad
	mesh.position = Vector3(center.x, -center.y + sin(TILT) * depth, depth)
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh

func update_camera(center: Vector2, weather: Dictionary = {}, depth_m: float = -1.0) -> void:
	_depth = maxf(0.0, (center.y - _surface) / 28.0) if depth_m < 0 else depth_m
	_reduced = bool(weather.get("reduced_motion", false))
	var deep := clampf(_depth / 110.0, 0.0, 1.0)
	var daylight := float(weather.get("daylight", 0.8))
	var clouds := float(weather.get("clouds", 0.0))
	var brightness := lerpf(0.73,1.0,daylight) * (1.0 - clouds * 0.12)
	var sea := Color("3c8590").lerp(Color("123b57"), deep) * brightness
	if _base_material:
		_base_material.set_shader_parameter("upper", Color("45969a") * brightness)
		_base_material.set_shader_parameter("lower", Color("0a283e") * brightness)
	for index in range(_layers.size()):
		var layer: Dictionary = _layers[index]
		var factor: Vector2 = layer.parallax
		var offset := (center - ANCHOR) * (Vector2.ONE - factor)
		offset.y = clampf(offset.y, -220, 220)
		var node: Node3D = layer.node
		node.position = Vector3(offset.x, -offset.y, 0)
		layer["offset"] = offset
		layer["tint"] = sea.lerp(Color("79a9a0") * brightness, float(index) * 0.20)
	for card in _cards:
		var layer: Dictionary = _layers[int(card.layer)]
		var material: ShaderMaterial = card.material
		material.set_shader_parameter("tint", layer.tint)
		material.set_shader_parameter("contrast", layer.contrast)
		material.set_shader_parameter("visibility", layer.visibility)
		material.set_shader_parameter("layer_offset", layer.offset)
		material.set_shader_parameter("sway", 0.0 if _reduced or not bool(card.plant) else 6.0)
		var mesh: MeshInstance3D = card.mesh
		mesh.visible = not bool(card.plant) or _depth <= 60

func debug_status() -> Dictionary:
	var layers: Array[Dictionary] = []
	for layer in _layers:
		var node: Node3D = layer.node
		var offset: Vector2 = layer.offset
		var factor: Vector2 = layer.parallax
		var tint: Color = layer.tint
		layers.append({"id":layer.id,"name":layer.name,"depth":layer.depth,"parallax":[factor.x,factor.y],"position":[node.position.x,node.position.y,node.position.z],"offset":[offset.x,offset.y],"contrast":layer.contrast,"visibility":layer.visibility,"tint":[tint.r,tint.g,tint.b,tint.a],"cards":layer.cards})
	return {"active":visible and _configured,"atlasAvailable":_atlas != null,"depth":_depth,"reducedMotion":_reduced,"swayAmplitude":0.0 if _reduced else 6.0,"layers":layers}
