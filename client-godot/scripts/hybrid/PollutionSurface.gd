extends Node3D

const Model = preload("res://scripts/PollutionBubbles.gd")
const EMITTERS := [Vector2(1588, 1322), Vector2(1460, 1432)]

var _renderer: Node
var _field: RefCounted
var _bubbles: MultiMeshInstance3D
var _focus := Vector2.ZERO
var _time := 0.0
var _tick := 0.0
var _strength := -1.0
var _active := true
var _visible_bubbles := 0

func configure(renderer: Node, field: RefCounted) -> void:
	_renderer = renderer
	_field = field
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float ring = step(0.47, length(p)) * (1.0 - step(0.89, length(p)));
	float sheen = step(-0.72, p.x) * (1.0 - step(-0.17, p.x)) * step(-0.72, p.y) * (1.0 - step(-0.42, p.y));
	float pixel = max(ring, sheen * 0.65);
	if (pixel < 0.5 || COLOR.a < 0.02) discard;
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = quad
	mm.instance_count = Model.MAX_SURFACE_BUBBLES
	_bubbles = MultiMeshInstance3D.new()
	_bubbles.name = "PurplePollutionSurface"
	_bubbles.multimesh = mm
	_bubbles.material_override = material
	_bubbles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_bubbles)
	_hide_all()

func set_active(value: bool) -> void:
	_active = value
	visible = value
	if not value:
		_visible_bubbles = 0

func set_focus(point: Vector2) -> void:
	_focus = point

func _hide_all() -> void:
	if not is_instance_valid(_bubbles): return
	for index in range(Model.MAX_SURFACE_BUBBLES):
		_bubbles.multimesh.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0, 0, -9000)))
		_bubbles.multimesh.set_instance_color(index, Color.TRANSPARENT)

func _process(delta: float) -> void:
	if not _active or not is_instance_valid(_bubbles) or not is_instance_valid(_renderer): return
	var state := get_node_or_null("/root/GameState")
	if state == null: return
	var desired: float = Model.intensity(state.player, state.adventure, "main", state.dive)
	if _strength < 0.0: _strength = desired
	_strength = move_toward(_strength, desired, delta * 1.25)
	_tick += delta
	if _tick < 0.067: return
	_tick = 0.0
	var environment := get_node_or_null("/root/EnvironmentState")
	var weather: Dictionary = environment.snapshot() if environment != null else {}
	var reduced := bool(weather.get("reduced_motion", false))
	if not bool(weather.get("clockPaused", false)): _time += delta * (0.2 if reduced else 1.0)
	var mm := _bubbles.multimesh
	_visible_bubbles = 0
	for index in range(Model.MAX_SURFACE_BUBBLES):
		var source: Vector2 = EMITTERS[int(index / 9)]
		var phase := fposmod(float(index) * 0.173 + _time * 0.19, 1.0)
		var offset := Model.bubble_offset(index, _time, 0.0, reduced)
		var point := source + Vector2(offset.x * 0.55, float(index % 3) * 8.0 - 8.0)
		var wet := not bool(_field.sample_world(point).get("on_land", true))
		var show := _strength > 0.015 and point.distance_to(_focus) < 820.0 and wet
		if not show:
			mm.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0, 0, -9000)))
			mm.set_instance_color(index, Color.TRANSPARENT)
			continue
		_visible_bubbles += 1
		var radius := 4.4 + float(index % 4) * 1.4 + phase * 1.5
		var alpha := _strength * (0.48 + 0.20 * sin(phase * PI))
		var at: Vector3 = _renderer.map_point((point / 2.0).round() * 2.0, -12.7)
		mm.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3(radius * 2.0, radius * 1.3, 1.0)), at))
		mm.set_instance_color(index, Color(0.73, 0.30, 0.82, alpha))

func debug_status() -> Dictionary:
	return {"strength": maxf(0.0, _strength), "visibleBubbles": _visible_bubbles, "budget": Model.MAX_SURFACE_BUBBLES}
