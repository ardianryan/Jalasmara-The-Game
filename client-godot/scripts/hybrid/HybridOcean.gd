extends Node2D

const TILT := deg_to_rad(12.0)
const CAMERA_DISTANCE := 2200.0
const LOW_RESOLUTION := Vector2i(480, 270)
var main: Node2D
var active := false
var enabled := true
var backdrop: Node3D
var _fill_light: DirectionalLight3D
var screen_layer: CanvasLayer
var display: TextureRect
var viewport_3d: SubViewport
var world_root: Node3D
var camera_3d: Camera3D
var environment: Environment
var sunlight: DirectionalLight3D
var headlamp: SpotLight3D
var terrain_geometry: Node3D
var actors: Node3D
var living_water: Node2D
var _living_layer: CanvasLayer
var _built := false
var _camera_center := Vector2.ZERO
var _depth := 0.0
var _lighting_clock := 0.0

func setup(source: Node2D) -> void:
	main = source
	if is_instance_valid(screen_layer):
		return
	screen_layer = CanvasLayer.new()
	screen_layer.layer = -1
	add_child(screen_layer)
	display = TextureRect.new()
	display.position = Vector2.ZERO
	display.size = Vector2(960, 540)
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var presentation := ShaderMaterial.new()
	presentation.shader = preload("res://shaders/ComfyGrade.gdshader")
	presentation.set_shader_parameter("strength",0.4)
	display.material = presentation
	display.visible = false
	screen_layer.add_child(display)
	viewport_3d = SubViewport.new()
	viewport_3d.size = LOW_RESOLUTION
	viewport_3d.own_world_3d = true
	viewport_3d.transparent_bg = false
	viewport_3d.msaa_3d = Viewport.MSAA_DISABLED
	viewport_3d.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport_3d.positional_shadow_atlas_size = 1024
	viewport_3d.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(viewport_3d)
	display.texture = viewport_3d.get_texture()
	get_viewport().size_changed.connect(_resize_display)
	_resize_display()
	_living_layer = CanvasLayer.new()
	_living_layer.layer = 4
	add_child(_living_layer)
	living_water = preload("res://scripts/hybrid/LivingWater.gd").new()
	_living_layer.add_child(living_water)
	living_water.setup(main)

func _resize_display() -> void:
	if is_instance_valid(display):
		display.size = get_viewport().get_visible_rect().size

# Helpers use pixel coordinates (x, -y, z). Their common parent applies the
# camera's inverse Y foreshortening so the z=0 plane follows the 2D collision map.
func map_point(point: Vector2, z := 0.0) -> Vector3:
	return Vector3(point.x, -point.y, z)

func _create_world() -> void:
	world_root = Node3D.new()
	world_root.name = "PixelWorldGeometry"
	world_root.scale.y = 1.0 / cos(TILT)
	viewport_3d.add_child(world_root)
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("092f3a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("87b5b3")
	environment.ambient_light_energy = 0.9
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled = true
	environment.fog_light_color = Color("235965")
	environment.fog_density = 0.000025
	var atmosphere := WorldEnvironment.new()
	atmosphere.environment = environment
	viewport_3d.add_child(atmosphere)
	camera_3d = Camera3D.new()
	camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera_3d.keep_aspect = Camera3D.KEEP_HEIGHT
	camera_3d.near = 5.0
	camera_3d.far = 4500.0
	camera_3d.current = true
	viewport_3d.add_child(camera_3d)
	backdrop = preload("res://scripts/hybrid/OceanBackdrop.gd").new()
	world_root.add_child(backdrop)
	backdrop.configure(GameState.world)
	_add_sky_and_water()
	var terrain_path := "res://scripts/hybrid/TerrainGeometry.gd"
	if ResourceLoader.exists(terrain_path):
		terrain_geometry = load(terrain_path).new()
		world_root.add_child(terrain_geometry)
		terrain_geometry.configure(GameState.world)
	var actors_path := "res://scripts/hybrid/OceanActors.gd"
	if ResourceLoader.exists(actors_path):
		actors = load(actors_path).new()
		world_root.add_child(actors)
		actors.configure(main)
	sunlight = DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-24, -25, -12)
	sunlight.light_color = Color("f0eee1")
	sunlight.light_energy = 1.35
	sunlight.shadow_enabled = true
	sunlight.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sunlight.directional_shadow_max_distance = 3100.0
	viewport_3d.add_child(sunlight)
	_fill_light = DirectionalLight3D.new()
	_fill_light.rotation_degrees = Vector3(22, 40, 0)
	_fill_light.light_color = Color("8dd0cf")
	_fill_light.light_energy = 0.28
	_fill_light.shadow_enabled = false
	viewport_3d.add_child(_fill_light)
	headlamp = SpotLight3D.new()
	headlamp.light_color = Color("fff1c4")
	headlamp.light_energy = 2.4
	headlamp.spot_range = 760.0
	headlamp.spot_angle = 23.0
	headlamp.spot_attenuation = 0.8
	headlamp.shadow_enabled = true
	headlamp.shadow_bias = 0.08
	viewport_3d.add_child(headlamp)
	_built = true

func _depth_point(point: Vector2, z: float) -> Vector3:
	return Vector3(point.x, -point.y + sin(TILT) * z, z)

func _shader_plane(label: String, center: Vector2, dimensions: Vector2, depth: float, source: String) -> void:
	var plane := MeshInstance3D.new()
	plane.name = label
	var quad := QuadMesh.new()
	quad.size = dimensions
	plane.mesh = quad
	plane.position = _depth_point(center, depth)
	var shader := Shader.new()
	shader.code = source
	var material := ShaderMaterial.new()
	material.shader = shader
	plane.material_override = material
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world_root.add_child(plane)

func _add_sky_and_water() -> void:
	var width := float(GameState.world.get("width", 6144))
	var surface := float(GameState.world.get("surface", 400))
	_shader_plane("CoastalSky", Vector2(width / 2, surface / 2), Vector2(width, surface), -1100, """
shader_type spatial;
render_mode unshaded, cull_disabled;
void fragment() {
	float cloud = sin(UV.x * 23.0 + TIME * 0.025) * sin(UV.y * 12.0 + UV.x * 7.0) * 0.035;
	ALBEDO = mix(vec3(0.35, 0.64, 0.69), vec3(0.81, 0.85, 0.73), UV.y) + cloud;
}
""")
	_shader_plane("TidalSurface", Vector2(width / 2, surface), Vector2(width, 28), -40, """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void fragment() {
	float ridge = 0.5 + sin(UV.x * 170.0 + TIME * 1.4) * 0.14 + sin(UV.x * 70.0 - TIME) * 0.08;
	float foam = 1.0 - smoothstep(0.05, 0.22, abs(UV.y - ridge));
	ALBEDO = mix(vec3(0.18, 0.64, 0.66), vec3(0.75, 0.91, 0.8), foam);
	ALPHA = foam * 0.75;
}
""")

func _process(delta: float) -> void:
	if not is_instance_valid(main) or not is_instance_valid(viewport_3d):
		return
	var next_active := enabled and not GameState.dive.is_empty() and not GameState.world.is_empty()
	if next_active and not _built:
		_create_world()
	active = next_active and _built
	if is_instance_valid(living_water): living_water.set_active(not GameState.dive.is_empty())
	display.visible = active
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	if is_instance_valid(actors):
		actors.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if not active:
		return
	_camera_center = main.camera.get_screen_center_position()
	var center := Vector3(_camera_center.x, -_camera_center.y / cos(TILT), 0)
	camera_3d.position = center + Vector3(0, sin(TILT) * CAMERA_DISTANCE, cos(TILT) * CAMERA_DISTANCE)
	camera_3d.look_at(center, Vector3.UP)
	camera_3d.size = 540.0 / maxf(0.1, main.camera.zoom.y)
	if is_instance_valid(terrain_geometry): terrain_geometry.update_camera(_camera_center)
	var at: Vector2 = main.nala.position
	var facing := float(main.nala.direction)
	_update_headlamp(at, facing)
	_depth = maxf(0, (at.y - float(GameState.world.get("surface", 400))) / 28.0)
	if is_instance_valid(backdrop):
		backdrop.update_camera(_camera_center, EnvironmentState.snapshot(), _depth)
	_lighting_clock += delta
	if _lighting_clock >= 0.25:
		_lighting_clock = 0.0
		_update_lighting()

func _update_headlamp(at: Vector2, facing: float) -> void:
	var direction := -1.0 if facing < 0 else 1.0
	var mount := at + Vector2(direction * 30.0, -14.0)
	# Keep the emitter just ahead of the helmet, on the actor's depth plane.
	# The small Y correction cancels the extra depth's projection through the tilted camera.
	var actor_depth := 12.0
	var lamp_depth := 24.0
	headlamp.position = Vector3(mount.x, -mount.y / cos(TILT) + tan(TILT) * (lamp_depth - actor_depth), lamp_depth)
	var ahead := at + Vector2(direction * 560.0, 18.0)
	headlamp.look_at(Vector3(ahead.x, -ahead.y / cos(TILT), 0), Vector3.UP)

func _flashlight_status() -> Dictionary:
	if not is_instance_valid(headlamp):
		return {}
	var origin := headlamp.position
	var ahead := origin - headlamp.basis.z * 560.0
	var mount := Vector2(origin.x, -origin.y * cos(TILT) + origin.z * sin(TILT))
	var aim := Vector2(ahead.x, -ahead.y * cos(TILT) + ahead.z * sin(TILT))
	return {"mount":[mount.x,mount.y],"aim":[aim.x,aim.y],"facing":float(main.nala.direction) if is_instance_valid(main) else 1.0,"depth":origin.z,"shadow":headlamp.shadow_enabled}

func _update_lighting() -> void:
	var state := EnvironmentState.snapshot()
	var daylight := float(state.get("daylight", 0.8))
	if display.material is ShaderMaterial:
		display.material.set_shader_parameter("daylight",daylight)
	var cloud := float(state.get("clouds", 0.0))
	var deep := clampf(_depth / 110.0, 0, 1)
	environment.ambient_light_energy = lerpf(0.92, 0.62, deep) * lerpf(0.85, 1.0, daylight)
	environment.ambient_light_color = Color("c5d7cc").lerp(Color("8cb4b8"), deep)
	environment.fog_density = lerpf(0.000018, 0.000055, deep) + cloud * 0.000008
	environment.fog_light_color = Color("367982").lerp(Color("123b56"), deep)
	sunlight.light_energy = lerpf(1.45, 0.65, deep) * lerpf(0.8, 1.0, daylight) * (1 - cloud * 0.25)
	headlamp.light_energy = lerpf(1.8, 3.2, deep)

func is_active() -> bool:
	return active

func _count_nodes(node: Node, type_name: String) -> int:
	var count := 1 if node.is_class(type_name) else 0
	for child in node.get_children():
		count += _count_nodes(child, type_name)
	return count

func debug_status() -> Dictionary:
	return {
		"active": active, "enabled": enabled, "renderer": "SubViewport3D", "viewport": [480, 270],
		"orthographic": is_instance_valid(camera_3d) and camera_3d.projection == Camera3D.PROJECTION_ORTHOGONAL,
		"mesh_count": _count_nodes(world_root, "MeshInstance3D") if _built else 0,
		"sprite_count": _count_nodes(world_root, "Sprite3D") if _built else 0,
		"camera_center": [_camera_center.x, _camera_center.y], "depth_m": _depth,
		"spot_shadow": is_instance_valid(headlamp) and headlamp.shadow_enabled,
		"flashlight": _flashlight_status(),
		"geology": terrain_geometry.debug_status() if is_instance_valid(terrain_geometry) else {},
		"backdrop": backdrop.debug_status() if is_instance_valid(backdrop) else {},
		"water": living_water.debug_status() if is_instance_valid(living_water) else {},
	}
