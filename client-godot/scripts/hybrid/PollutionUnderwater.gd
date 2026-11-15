extends Node3D

const Model = preload("res://scripts/PollutionBubbles.gd")
const PLUME_DEPTH := 28.0

var _bubbles: MultiMeshInstance3D
var _source := Vector2.ZERO
var _focus := Vector2.ZERO
var _time := 0.0
var _tick := 0.0
var _strength := -1.0
var _visible_bubbles := 0
var _active := true

func configure(world: Dictionary) -> void:
	var valve := Model.source_position(world, "valve", Vector2(4660, 2630))
	# Cell 1 in ocean-props-atlas is the grounded copper elbow; its outlet is left of the visual center.
	_source = valve + Vector2(-34, 112)
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ring = step(0.50, r) * (1.0 - step(0.88, r));
	float glint = step(-0.68, p.x) * (1.0 - step(-0.28, p.x)) * step(-0.68, p.y) * (1.0 - step(-0.48, p.y));
	if (max(ring, glint) < 0.5 || COLOR.a < 0.02) discard;
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
	mm.instance_count = Model.MAX_UNDERWATER_BUBBLES
	_bubbles = MultiMeshInstance3D.new()
	_bubbles.name = "ValvePollutionBubbles"
	_bubbles.multimesh = mm
	_bubbles.material_override = material
	_bubbles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_bubbles)
	_hide_all()

func set_active(value: bool) -> void:
	_active = value
	visible = value
	if not value: _visible_bubbles = 0

func set_focus(point: Vector2) -> void:
	_focus = point

func _hide_all() -> void:
	if not is_instance_valid(_bubbles): return
	for index in range(Model.MAX_UNDERWATER_BUBBLES):
		_bubbles.multimesh.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0, 0, -9000)))
		_bubbles.multimesh.set_instance_color(index, Color.TRANSPARENT)

func _process(delta: float) -> void:
	if not _active or not is_instance_valid(_bubbles): return
	var state := get_node_or_null("/root/GameState")
	if state == null: return
	var desired: float = Model.intensity(state.player, state.adventure, "valve", state.dive)
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
	for index in range(Model.MAX_UNDERWATER_BUBBLES):
		var show := _strength > 0.015 and _source.distance_to(_focus) < 700.0
		if not show:
			mm.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0, 0, -9000)))
			mm.set_instance_color(index, Color.TRANSPARENT)
			continue
		_visible_bubbles += 1
		var offset := Model.bubble_offset(index, _time, 135.0, reduced)
		var phase := fposmod(float(index) * 0.341 + _time * (0.24 + float(index % 3) * 0.035), 1.0)
		var at := _source + offset * Vector2(0.72, 1.0)
		at = (at / 2.0).round() * 2.0
		var radius := 5.3 + float(index % 3) * 1.9
		var alpha := _strength * (1.0 - phase) * 0.72
		var basis := Basis.from_scale(Vector3(radius * 2.0, radius * 2.0, 1.0))
		mm.set_instance_transform(index, Transform3D(basis, Vector3(at.x, -at.y, PLUME_DEPTH)))
		mm.set_instance_color(index, Color(0.78, 0.43, 0.85, alpha))

func debug_status() -> Dictionary:
	return {"strength": maxf(0.0, _strength), "visibleBubbles": _visible_bubbles, "budget": Model.MAX_UNDERWATER_BUBBLES, "source": [_source.x, _source.y]}
