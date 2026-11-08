extends Node2D

const MODEL_PATH := "res://resources/models/reef-rock.glb"
const RESOLUTION := Vector2i(128,128)
const STONE_SHADER := """
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
varying vec3 stone_position;
varying vec3 stone_normal;
float grain(vec3 cell) {
	return fract(sin(dot(cell,vec3(127.1,311.7,74.7)))*43758.5453);
}
void vertex() {
	stone_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	stone_normal = normalize((MODEL_MATRIX * vec4(NORMAL,0.0)).xyz);
}
void fragment() {
	vec3 pixel = floor(stone_position * 74.0);
	float fine = floor(grain(pixel) * 5.0) / 4.0;
	float patch = grain(floor(stone_position * 13.0));
	vec3 gray = mix(vec3(0.40,0.395,0.38),vec3(0.56,0.545,0.515),fine * 0.2 + patch * 0.8);
	float pit = step(0.95,grain(floor(stone_position * 31.0))) * step(0.70,fine);
	gray *= 1.0 - pit * 0.24;
	float mineral = step(0.97,grain(pixel + vec3(17.0)));
	gray = mix(gray,vec3(0.63,0.61,0.56),mineral * 0.18);
	float moss = step(0.86,patch) * step(0.45,stone_normal.y) * step(0.5,fine);
	ALBEDO = mix(gray,vec3(0.17,0.19,0.12),moss * 0.42);
	ROUGHNESS = 0.98;
	SPECULAR = 0.0;
}
"""
var viewport_3d: SubViewport
var sprite: Sprite2D
var rock_model: Node3D
var key_light: DirectionalLight3D
var atmosphere: Environment
var _dimensions := Vector2(120,90)
var _solid_rect := Rect2()
var _yaw := 0.0
var _built := false
var _configured := false
var _calibrated := false
var _mesh_count := 0
var _daylight := 0.8
var _weather_clock := 0.0
var _alpha_bounds := Rect2i()

func configure(foot: Vector2, dimensions: Vector2, solid_rect: Rect2, yaw := 0.0) -> bool:
	var visual := Rect2(foot-Vector2(dimensions.x/2,dimensions.y),dimensions)
	if not solid_rect.encloses(visual) or dimensions.x<=0 or dimensions.y<=0:
		return false
	position = foot
	_dimensions = dimensions
	_solid_rect = solid_rect
	_yaw = yaw
	_configured = true
	if is_inside_tree(): _build()
	return true

func _ready() -> void:
	if _configured: _build()

func _build() -> void:
	if _built or not ResourceLoader.exists(MODEL_PATH): return
	_built = true
	viewport_3d = SubViewport.new()
	viewport_3d.size = RESOLUTION
	viewport_3d.own_world_3d = true
	viewport_3d.transparent_bg = true
	viewport_3d.msaa_3d = Viewport.MSAA_DISABLED
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_DISABLED if DisplayServer.get_name()=="headless" else SubViewport.UPDATE_ALWAYS
	viewport_3d.positional_shadow_atlas_size = 512
	add_child(viewport_3d)
	atmosphere = Environment.new()
	atmosphere.background_mode = Environment.BG_COLOR
	atmosphere.background_color = Color(0,0,0,0)
	atmosphere.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	atmosphere.ambient_light_color = Color("abc1ac")
	atmosphere.ambient_light_energy = 0.5
	atmosphere.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var environment := WorldEnvironment.new()
	environment.environment = atmosphere
	viewport_3d.add_child(environment)
	var holder := Node3D.new()
	holder.rotation.y = _yaw
	viewport_3d.add_child(holder)
	rock_model = (load(MODEL_PATH) as PackedScene).instantiate() as Node3D
	holder.add_child(rock_model)
	var geometry := rock_model.find_children("*","MeshInstance3D",true,false)
	if rock_model is MeshInstance3D: geometry.append(rock_model)
	var bounds := AABB()
	var first := true
	for leaf in geometry:
		var mesh := leaf as MeshInstance3D
		var transform_to_model: Transform3D = rock_model.global_transform.affine_inverse()*mesh.global_transform
		var extent := transform_to_model*mesh.get_aabb()
		bounds = extent if first else bounds.merge(extent)
		first = false
		_mesh_count += 1
		var stone_shader := Shader.new()
		stone_shader.code = STONE_SHADER
		var stone_material := ShaderMaterial.new()
		stone_material.shader = stone_shader
		mesh.material_override = stone_material
	if first:
		return
	var height := maxf(0.01,bounds.size.y)
	rock_model.scale = Vector3.ONE/height
	rock_model.position = Vector3(-bounds.get_center().x,-bounds.position.y,-bounds.get_center().z)/height
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = maxf(1.45,maxf(bounds.size.x,bounds.size.z)/height*1.4)
	camera.position = Vector3(0,1.35,3)
	camera.near = 0.05
	camera.far = 20
	viewport_3d.add_child(camera)
	camera.look_at(Vector3(0,0.48,0),Vector3.UP)
	camera.current = true
	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-48,-32,-10)
	key_light.shadow_enabled = true
	viewport_3d.add_child(key_light)
	sprite = Sprite2D.new()
	sprite.name = "LiveRockProjection"
	sprite.texture = viewport_3d.get_texture()
	sprite.visible = false
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# The 3D pass already receives the time-dependent light; avoid double tinting it.
	var presentation := CanvasItemMaterial.new()
	presentation.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sprite.material = presentation
	add_child(sprite)
	var state := get_node_or_null("/root/EnvironmentState")
	update_weather(state.snapshot() if state != null else {})
	_calibrate.call_deferred()

func _calibrate() -> void:
	if DisplayServer.get_name()=="headless": return
	for frame in range(4): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if not is_instance_valid(viewport_3d): return
	var image := viewport_3d.get_texture().get_image()
	if image == null or image.is_empty(): return
	var minimum := Vector2i(RESOLUTION.x,RESOLUTION.y)
	var maximum := Vector2i.ZERO
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x,y).a>0.1:
				minimum.x = mini(minimum.x,x)
				minimum.y = mini(minimum.y,y)
				maximum.x = maxi(maximum.x,x+1)
				maximum.y = maxi(maximum.y,y+1)
	if maximum.x<=minimum.x or maximum.y<=minimum.y: return
	_alpha_bounds = Rect2i(minimum,maximum-minimum)
	sprite.offset = -Vector2(float(minimum.x+maximum.x)/2.0,float(maximum.y))
	sprite.scale = _dimensions/Vector2(_alpha_bounds.size)
	_calibrated = true
	sprite.visible = true
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE
	queue_redraw()

func update_weather(weather: Dictionary) -> void:
	_daylight = clampf(float(weather.get("daylight",0.8)),0,1)
	if not is_instance_valid(key_light): return
	var clouds := clampf(float(weather.get("clouds",0)),0,1)
	key_light.light_energy = lerpf(0.30,1.25,_daylight)*(1.0-clouds*0.25)
	key_light.light_color = Color("7897ae").lerp(Color("fff2dd"),_daylight)
	atmosphere.ambient_light_energy = lerpf(0.19,0.58,_daylight)
	atmosphere.ambient_light_color = Color("617b94").lerp(Color("c0c2b8"),_daylight)
	if _calibrated: viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE

func _process(delta: float) -> void:
	if not _built or not visible: return
	_weather_clock += delta
	if _weather_clock<1.0: return
	_weather_clock = 0
	var state := get_node_or_null("/root/EnvironmentState")
	if state != null: update_weather(state.snapshot())

func _draw() -> void:
	if not _calibrated: return
	draw_set_transform(Vector2(0,-1),0,Vector2(1,0.18))
	draw_circle(Vector2.ZERO,_dimensions.x*0.43,Color(0.055,0.05,0.04,0.15))
	draw_circle(Vector2.ZERO,_dimensions.x*0.31,Color(0.04,0.035,0.025,0.31))
	draw_set_transform(Vector2.ZERO)

func debug_status() -> Dictionary:
	var visual := Rect2(position-Vector2(_dimensions.x/2,_dimensions.y),_dimensions)
	return {"ready":_calibrated,"stoneTexture":"procedural_pixel_grain","modelPath":MODEL_PATH,"meshCount":_mesh_count,"viewport":[128,128],"foot":[position.x,position.y],"dimensions":[_dimensions.x,_dimensions.y],"bounds":[visual.position.x,visual.position.y,visual.size.x,visual.size.y],"contained":_solid_rect.encloses(visual),"daylight":_daylight,"lightEnergy":key_light.light_energy if is_instance_valid(key_light) else 0.0,"alphaBounds":[_alpha_bounds.position.x,_alpha_bounds.position.y,_alpha_bounds.size.x,_alpha_bounds.size.y]}
