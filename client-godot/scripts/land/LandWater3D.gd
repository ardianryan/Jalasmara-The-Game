extends Node3D

const MASK_SIZE := Vector2i(160, 112)
const WaterFieldScript = preload("res://scripts/land/WaterField.gd")
const MAX_ACTIVE_EMITTERS := 8
const MAX_SPLASHES := 24
const MAX_FLECKS := 96
const CREST_PHASE := 0.34

var mesh_instance: MeshInstance3D
var splash_instances: MultiMeshInstance3D
var fleck_instances: MultiMeshInstance3D
var material: ShaderMaterial
var water_field = WaterFieldScript.new()
var elapsed := 0.0
var _map: Dictionary = {}
var _extent := Vector2(2400.0, 1600.0)
var _wet_cells := 0
var _renderer: Node
var _wind_level := 0.2
var _rain_level := 0.0
var _motion_scale := 1.0
var _focus_point := Vector2(1120.0, 1230.0)
var _emitter_phases: Dictionary = {}
var _splashes: Array[Dictionary] = []
var _flecks: Array[Dictionary] = []
var _splash_cursor := 0
var _fleck_cursor := 0
var _swell_events: Array[Dictionary] = []
var _total_swell_events := 0
var _last_swell_event: Dictionary = {}
var _active_emitter_count := 0

func configure(renderer: Node, map: Dictionary) -> void:
	_renderer = renderer
	_map = map
	_extent = Vector2(float(map.get("width", 2400.0)), float(map.get("height", 1600.0)))
	var spawn: Dictionary = map.get("spawn", {"x": 1120.0, "y": 1230.0})
	_focus_point = Vector2(float(spawn.get("x", 1120.0)), float(spawn.get("y", 1230.0)))
	water_field.configure(map)
	_wet_cells = water_field.wet_cells

	material = ShaderMaterial.new()
	material.shader = preload("res://scripts/land/LandWater3D.gdshader")
	material.set_shader_parameter("shoreline", water_field.shoreline_texture)
	material.set_shader_parameter("map_extent", _extent)
	material.set_shader_parameter("river", water_field.is_river)

	var margin := Vector2(420.0, 320.0)
	var span := _extent + margin * 2.0
	var vertices := PackedVector3Array()
	var uv := PackedVector2Array()
	var normals := PackedVector3Array()
	for row in range(24):
		for column in range(32):
			var corners := [
				Vector2(column, row),
				Vector2(column + 1, row),
				Vector2(column + 1, row + 1),
				Vector2(column, row + 1),
			]
			for index in [0, 2, 1, 0, 3, 2]:
				var fraction: Vector2 = corners[index] / Vector2(32.0, 24.0)
				var world_point := -margin + fraction * span
				vertices.append(renderer.map_point(world_point, -14.0))
				uv.append(world_point / _extent)
				normals.append(Vector3(0.0, 0.0, 1.0))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_NORMAL] = normals
	var geometry := ArrayMesh.new()
	geometry.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = geometry
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)

	_setup_effect_pools()
	_seed_initial_activity()

func _setup_effect_pools() -> void:
	_splashes.clear()
	_flecks.clear()
	_emitter_phases.clear()
	_swell_events.clear()
	_splash_cursor = 0
	_fleck_cursor = 0
	for i in range(MAX_SPLASHES):
		_splashes.append({"active": false, "age": 0.0, "lifetime": 1.2})
	for i in range(MAX_FLECKS):
		_flecks.append({"active": false, "age": 0.0, "lifetime": 1.0})

	var fx_shader := Shader.new()
	fx_shader.code = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float mask = 1.0 - smoothstep(0.45, 1.0, length(centered));
	if (mask * COLOR.a < 0.03) discard;
	ALBEDO = COLOR.rgb;
	ALPHA = mask * COLOR.a;
}
"""
	var fx_material := ShaderMaterial.new()
	fx_material.shader = fx_shader

	var splash_quad := QuadMesh.new()
	splash_quad.size = Vector2(1.0, 1.0)
	var splash_mm := MultiMesh.new()
	splash_mm.transform_format = MultiMesh.TRANSFORM_3D
	splash_mm.use_colors = true
	splash_mm.mesh = splash_quad
	splash_mm.instance_count = MAX_SPLASHES
	for i in range(MAX_SPLASHES):
		splash_mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0, 0, -9000)))
		splash_mm.set_instance_color(i, Color(1, 1, 1, 0))
	splash_instances = MultiMeshInstance3D.new()
	splash_instances.name = "WaterSplashPool"
	splash_instances.multimesh = splash_mm
	splash_instances.material_override = fx_material
	splash_instances.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(splash_instances)

	var fleck_quad := QuadMesh.new()
	fleck_quad.size = Vector2(1.0, 1.0)
	var fleck_mm := MultiMesh.new()
	fleck_mm.transform_format = MultiMesh.TRANSFORM_3D
	fleck_mm.use_colors = true
	fleck_mm.mesh = fleck_quad
	fleck_mm.instance_count = MAX_FLECKS
	for i in range(MAX_FLECKS):
		fleck_mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0, 0, -9000)))
		fleck_mm.set_instance_color(i, Color(1, 1, 1, 0))
	fleck_instances = MultiMeshInstance3D.new()
	fleck_instances.name = "WaterFleckPool"
	fleck_instances.multimesh = fleck_mm
	fleck_instances.material_override = fx_material
	fleck_instances.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fleck_instances)

func _seed_initial_activity() -> void:
	var near := water_field.emitters_near(_focus_point, 750.0, MAX_ACTIVE_EMITTERS)
	_active_emitter_count = near.size()
	for idx in range(near.size()):
		var emitter: Dictionary = near[idx]
		_spawn_emitter_wash(emitter, 0.72)
		var splash: Dictionary = _splashes[(_splash_cursor - 1 + MAX_SPLASHES) % MAX_SPLASHES]
		if bool(splash.get("active", false)):
			splash.age = float(idx % 3) * 0.32
	_sync_multimeshes()

func set_focus_point(point: Vector2) -> void:
	_focus_point = point

func pop_swell_events() -> Array[Dictionary]:
	if _swell_events.is_empty():
		return []
	var out := _swell_events.duplicate()
	_swell_events.clear()
	return out

func _process(delta: float) -> void:
	if material == null:
		return
	elapsed += delta
	var weather: Dictionary = EnvironmentState.snapshot()
	var target_rain := clampf(float(weather.get("rain", 0.0)), 0.0, 1.0)
	var target_wind := clampf(absf(float(weather.get("wind_x", 0.0))) / 30.0, 0.08, 1.0)
	_rain_level = move_toward(_rain_level, target_rain, delta * 0.8)
	_wind_level = move_toward(_wind_level, target_wind, delta * 0.5)
	_motion_scale = 0.2 if bool(weather.get("reduced_motion", false)) else 1.0

	material.set_shader_parameter("clock", elapsed)
	material.set_shader_parameter("rain", _rain_level)
	material.set_shader_parameter("wind", _wind_level)
	material.set_shader_parameter("motion", _motion_scale)

	if is_instance_valid(_renderer):
		var center_val: Variant = _renderer.get("_center")
		if center_val is Vector2 and (center_val as Vector2).length_squared() > 1.0:
			_focus_point = center_val
		else:
			var actor_node: Variant = _renderer.get("actor")
			if actor_node is Node2D and is_instance_valid(actor_node):
				_focus_point = (actor_node as Node2D).position

	_step_emitters_and_pools(delta)
	_sync_multimeshes()

func _step_emitters_and_pools(delta: float) -> void:
	var dt := clampf(delta, 0.0, 0.25) * _motion_scale
	var rate := (0.36 if water_field.is_river else 0.28) * (0.92 + _wind_level * 0.26)
	var nearby := water_field.emitters_near(_focus_point, 760.0, MAX_ACTIVE_EMITTERS)
	_active_emitter_count = nearby.size()
	var energy := clampf(0.58 + _wind_level * 0.32 + _rain_level * 0.10, 0.35, 1.0) * (0.45 if _motion_scale < 0.5 else 1.0)

	for emitter in nearby:
		var id := str(emitter.id)
		var offset := float(emitter.get("phase_offset", 0.0)) / TAU
		var curr_unwrapped := elapsed * rate * _motion_scale + offset
		var prev_unwrapped := float(_emitter_phases.get(id, maxf(0.0, elapsed - delta) * rate * _motion_scale + offset))
		_emitter_phases[id] = curr_unwrapped
		var crossed := floori(curr_unwrapped - CREST_PHASE) > floori(prev_unwrapped - CREST_PHASE)
		if crossed:
			_spawn_emitter_wash(emitter, energy)
			var ev := {
				"id": id,
				"area": water_field.area,
				"position": emitter.position,
				"normal": emitter.normal,
				"outward": emitter.outward,
				"kind": str(emitter.kind),
				"energy": energy,
				"time": elapsed,
			}
			_last_swell_event = ev
			_total_swell_events += 1
			if _swell_events.size() < 12:
				_swell_events.append(ev)

	for i in range(MAX_SPLASHES):
		var splash: Dictionary = _splashes[i]
		if not bool(splash.get("active", false)):
			continue
		splash.age = float(splash.age) + dt
		if float(splash.age) >= float(splash.lifetime):
			splash.active = false

	for i in range(MAX_FLECKS):
		var fleck: Dictionary = _flecks[i]
		if not bool(fleck.get("active", false)):
			continue
		fleck.age = float(fleck.age) + dt
		if float(fleck.age) >= float(fleck.lifetime):
			fleck.active = false
			continue
		var next_pos: Vector2 = Vector2(fleck.position) + Vector2(fleck.velocity) * dt
		if water_field.sample_world(next_pos).on_land:
			# Bounce gently back onto water so foam never creeps onto dry land
			fleck.velocity = -Vector2(fleck.velocity) * 0.5
		else:
			fleck.position = next_pos

func _has_active_splash_for(emitter_id: String) -> bool:
	for splash in _splashes:
		if bool(splash.get("active", false)) and str(splash.get("emitter_id", "")) == emitter_id:
			return true
	return false

func _spawn_emitter_wash(emitter: Dictionary, energy: float) -> void:
	var kind := str(emitter.get("kind", "sand"))
	var pos: Vector2 = emitter.position
	var outward: Vector2 = emitter.outward
	var tangent := Vector2(-outward.y, outward.x)
	var sample := water_field.sample_world(pos)
	var flow: Vector2 = sample.get("flow", Vector2(0.0, 1.0))

	var splash_idx := _splash_cursor
	_splash_cursor = (_splash_cursor + 1) % MAX_SPLASHES
	var lifetime := 1.45 if kind in ["sand", "bank"] else 0.95
	var width := (42.0 if kind == "sand" else 28.0 if kind == "bank" else 22.0) * (0.85 + energy * 0.25)
	var depth := (14.0 if kind in ["sand", "bank"] else 16.0) * (0.85 + energy * 0.25)
	_splashes[splash_idx] = {
		"active": true,
		"emitter_id": str(emitter.get("id", "")),
		"kind": kind,
		"origin": pos,
		"outward": outward,
		"tangent": tangent,
		"width": width,
		"depth": depth,
		"age": 0.0,
		"lifetime": lifetime,
		"energy": energy,
	}

	var fleck_count := 2 if _motion_scale < 0.5 else (5 if kind in ["pile", "rock"] else 4)
	for n in range(fleck_count):
		var f_idx := _fleck_cursor
		_fleck_cursor = (_fleck_cursor + 1) % MAX_FLECKS
		var spread := (float(n) / maxf(1.0, float(fleck_count - 1)) - 0.5) * 2.0
		var spawn_pos := pos + tangent * spread * (width * 0.38) + outward * (4.0 + float(n % 2) * 4.0)
		if water_field.sample_world(spawn_pos).on_land:
			spawn_pos = pos + outward * 10.0
		var vel := outward * (8.0 + float(n % 3) * 4.0) + flow * (12.0 if water_field.is_river else 5.0) + tangent * (spread * 6.0)
		_flecks[f_idx] = {
			"active": true,
			"position": spawn_pos,
			"velocity": vel,
			"size": 4.5 + float(n % 3) * 1.8,
			"age": 0.0,
			"lifetime": 0.85 + float(n % 3) * 0.22,
			"energy": energy,
		}

func _sync_multimeshes() -> void:
	if not is_instance_valid(splash_instances) or not is_instance_valid(fleck_instances) or not is_instance_valid(_renderer):
		return
	var splash_mm := splash_instances.multimesh
	var active_splashes := 0
	for i in range(MAX_SPLASHES):
		var splash: Dictionary = _splashes[i]
		if not bool(splash.get("active", false)):
			splash_mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0, 0, -9000)))
			splash_mm.set_instance_color(i, Color(1, 1, 1, 0))
			continue
		active_splashes += 1
		var t := clampf(float(splash.age) / maxf(0.01, float(splash.lifetime)), 0.0, 1.0)
		var origin: Vector2 = splash.origin
		var outward: Vector2 = splash.outward
		var tangent: Vector2 = splash.tangent
		var kind := str(splash.kind)
		var offset_dist := 0.0
		if kind in ["sand", "bank"]:
			# Advance shoreward (0..0.38), pause at crest (0.38..0.55), then recede seaward (0.55..1.0)
			var advance := smoothstep(0.0, 0.38, t) - smoothstep(0.52, 1.0, t) * 0.85
			offset_dist = -advance * 9.0 + 3.0
		else:
			# Obstacle/pile splash expands outward on wave-facing side
			offset_dist = (2.0 + t * 8.0)
		var world_2d := origin + outward * offset_dist
		if water_field.sample_world(world_2d).on_land:
			world_2d = origin + outward * 6.0
		var center_3d: Vector3 = _renderer.map_point(world_2d, -13.1)
		var angle := atan2(-tangent.y, tangent.x)
		var w := float(splash.width) * (0.75 + sin(t * PI) * 0.35)
		var d := float(splash.depth) * (0.70 + sin(t * PI) * 0.40)
		var basis := Basis(Vector3(0, 0, 1), angle).scaled(Vector3(w, d, 1.0))
		var alpha := sin(t * PI) * 0.46 * float(splash.energy)
		splash_mm.set_instance_transform(i, Transform3D(basis, center_3d))
		splash_mm.set_instance_color(i, Color(0.76, 0.88, 0.82, alpha))

	var fleck_mm := fleck_instances.multimesh
	var active_flecks := 0
	for i in range(MAX_FLECKS):
		var fleck: Dictionary = _flecks[i]
		if not bool(fleck.get("active", false)):
			fleck_mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0, 0, -9000)))
			fleck_mm.set_instance_color(i, Color(1, 1, 1, 0))
			continue
		active_flecks += 1
		var t := clampf(float(fleck.age) / maxf(0.01, float(fleck.lifetime)), 0.0, 1.0)
		var pos_2d := (Vector2(fleck.position) / 2.0).floor() * 2.0
		var center_3d: Vector3 = _renderer.map_point(pos_2d, -12.9)
		var sz := float(fleck.size) * (1.0 - t * 0.35)
		var basis := Basis.from_scale(Vector3(sz, sz * 0.85, 1.0))
		var alpha := (1.0 - t) * 0.52 * float(fleck.energy)
		fleck_mm.set_instance_transform(i, Transform3D(basis, center_3d))
		fleck_mm.set_instance_color(i, Color(0.82, 0.92, 0.86, alpha))

func debug_status() -> Dictionary:
	var active_splashes := 0
	for s in _splashes:
		if bool(s.get("active", false)):
			active_splashes += 1
	var active_flecks := 0
	for f in _flecks:
		if bool(f.get("active", false)):
			active_flecks += 1
	return {
		"mesh": is_instance_valid(mesh_instance),
		"elapsed": elapsed,
		"shoreMask": [MASK_SIZE.x, MASK_SIZE.y],
		"waterCells": _wet_cells,
		"vertexWaves": true,
		"shoreFoam": true,
		"rainRings": true,
		"directionalFlow": water_field.is_river,
		"walkable": false,
		"emitters": water_field.emitters.size(),
		"activeEmitters": _active_emitter_count,
		"activeSplashes": active_splashes,
		"activeFlecks": active_flecks,
		"swellEvents": _total_swell_events,
		"lastEvent": _last_swell_event,
	}
