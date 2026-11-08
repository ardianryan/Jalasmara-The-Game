extends Node2D

const HudScript = preload("res://scripts/GameHud.gd")
const AtlasScript = preload("res://scripts/WorldAtlas.gd")
const EXTENT := Vector2(2400, 1600)
const ENTRY := Vector2(200, 1320)
const WALK_SPEED := 175.0
var avatar: CharacterBody2D
var camera: Camera2D
var actors: Node2D
var game_hud: CanvasLayer
var dialog_actions: VBoxContainer
var ui: Control
var hint: Label
var notice: Label
var wallet: Label
var atlas_panel: PanelContainer
var dialog: PanelContainer
var dialog_text: RichTextLabel
var dialog_title: Label
var nearest: Dictionary = {}
var landmarks: Array = []
var busy := false
var syncing := false
var modal_open := false
var sync_clock := 0.0
var footstep_clock := 0.0
var animation_clock := 0.0
var touch_direction := Vector2.ZERO
var last_facing := Vector2.DOWN
var character_sheet: Texture2D
var walkable_paths: Array = []
var walkable_half_width := 130.0
var path_notice_cooldown := 0.0
var blocked_exits: Array = []
var background: Texture2D
var atlas_path := ""
var forest_lights: Array[Dictionary] = []
var light_clock := 0.0
var discovered: Array = []
var last_position := ENTRY
var depth_planes: Node2D

class ForestProp extends Node2D:
	var kind := "canopy"
	var variant := 0
	var display_size := Vector2(136,114)
	var sheet: Texture2D
	func _ready() -> void:
		if ResourceLoader.exists("res://resources/art/forest-props-atlas.png"):
			sheet = load("res://resources/art/forest-props-atlas.png")
	func _draw() -> void:
		if kind == "cache":
			draw_texture_rect(preload("res://scripts/ItemIcons.gd").texture("cache"),Rect2(-28,-48,56,56),false)
		elif sheet != null:
			var index: int = {"canopy":0,"roots":1,"stream":2,"landslide":3,"bridge":4,"gate":5}.get(kind,0)
			var cell := sheet.get_size()/Vector2(3,2)
			var source := Rect2(Vector2(index%3,floori(float(index)/3.0))*cell,cell)
			draw_texture_rect_region(sheet,Rect2(Vector2(-display_size.x/2,-display_size.y),display_size),source)

class ForestLife extends Node2D:
	var focus: Node2D
	var elapsed := 0.0
	var frame := -1
	func _process(delta: float) -> void:
		elapsed += delta
		var next_frame := int(elapsed*12)
		if next_frame != frame:
			frame = next_frame
			queue_redraw()
	func _draw() -> void:
		var center := focus.position if is_instance_valid(focus) else Vector2(1200,800)
		var view := Rect2(center-Vector2(650,420),Vector2(1300,840))
		for i in range(18):
			var phase := float(i)
			var at := Vector2(250+fposmod(phase*173.0+elapsed*5.0+sin(elapsed*0.7+phase)*12.0,1950),180+fposmod(phase*113.0+elapsed*(9.0+fmod(phase,4.0)),1220))
			if not view.has_point(at): continue
			var color := Color("b49b53") if i%3==0 else Color("758b45")
			at = at.round()
			draw_rect(Rect2(at,Vector2(4,2)),color)
			draw_rect(Rect2(at+Vector2(1,-1),Vector2(2,4)),color.darkened(0.15))
		var state := get_node_or_null("/root/EnvironmentState")
		var weather: Dictionary = state.snapshot() if state != null else {}
		if float(weather.get("rain",0))>0.38: return
		for i in range(5):
			var phase := float(i)
			var habitat := Vector2(610,1000) if i<3 else Vector2(1730,550)
			var at := habitat+Vector2(sin(elapsed*0.65+phase*2.0)*55+phase*24,cos(elapsed*0.9+phase)*19-24)
			if not view.has_point(at): continue
			at = at.round()
			var spread := 3 if (frame+i)%4<2 else 1
			var wing := Color("d8c47b") if i%2==0 else Color("c5d5b2")
			draw_rect(Rect2(at+Vector2(-spread,-2),Vector2(spread,3)),wing)
			draw_rect(Rect2(at+Vector2(1,-2),Vector2(spread,3)),wing)
			draw_rect(Rect2(at,Vector2(1,4)),Color("4a4731"))

class ForestCreature extends Node2D:
	var species := "ular_muara"
	var origin := Vector2.ZERO
	var elapsed := 0.0
	var frame := -1
	var width := 80.0
	var walkable: Callable
	func _process(delta: float) -> void:
		elapsed += delta
		var next_frame := int(elapsed*12)
		if next_frame==frame: return
		frame = next_frame
		var pace := 0.19 if species=="kura_pesisir" else 0.38
		var next_position := origin+Vector2(sin(elapsed*pace)*40,cos(elapsed*pace)*9)
		if not walkable.is_valid() or walkable.call(next_position): position = next_position
		queue_redraw()
	func _draw() -> void:
		var pace := 0.19 if species=="kura_pesisir" else 0.38
		preload("res://scripts/CreatureAnimator.gd").draw_creature(self,species,Vector2.ZERO,width,elapsed,cos(elapsed*pace),Color.WHITE,false)

class ForestAvatar extends CharacterBody2D:
	var facing := Vector2.DOWN
	var walking := false
	var clock := 0.0
	var sheet: Texture2D
	var variant := "male_default"
	func _draw() -> void:
		draw_set_transform(Vector2(0,-1),0,Vector2(1,0.35))
		draw_circle(Vector2.ZERO,21,Color(0.015,0.055,0.04,0.35))
		draw_set_transform(Vector2.ZERO)
		if sheet != null:
			var cell := sheet.get_size() / 3.0
			var frame := 1+int(clock * 8.0) % 2 if walking else 0
			var source := Rect2(Vector2(frame * cell.x,0),cell)
			var destination := Rect2(-50,-100,100,100)
			if facing.x < -0.1:
				destination.position.x = 50
				destination.size.x = -100
			draw_texture_rect_region(sheet,destination,source)
			return
		draw_set_transform(Vector2.ZERO,0,Vector2(1.4,1.4))
		var step := sin(clock * 11.0) * 4 if walking else 0.0
		draw_rect(Rect2(-11,-22,8,20+step),Color("30443d"))
		draw_rect(Rect2(4,-22,8,20-step),Color("30443d"))
		draw_rect(Rect2(-13,-4+step,11,5),Color("403c2f"))
		draw_rect(Rect2(3,-4-step,12,5),Color("403c2f"))
		draw_rect(Rect2(-14,-46,28,27),Color("bf733f"))
		draw_rect(Rect2(-7,-44,14,25),Color("d09b59"))
		draw_rect(Rect2(-20,-43,7,26),Color("a9764e"))
		draw_rect(Rect2(14,-43,7,25),Color("a9764e"))
		draw_rect(Rect2(-11,-64,23,20),Color("ba895c"))
		draw_rect(Rect2(-14,-70,28,12),Color("303b31"))
		draw_rect(Rect2(-14,-60,28,4),Color("a9b489"))
		if facing.y < -0.2:
			draw_rect(Rect2(-12,-62,26,15),Color("303b31"))
		else:
			draw_rect(Rect2(-6,-55,3,3),Color("343a31"))
			draw_rect(Rect2(6,-55,3,3),Color("343a31"))

func _ready() -> void:
	_register_input()
	var config: Dictionary = GameState.world.get("forest",{})
	walkable_paths = config.get("walkablePaths",[
		[[200,1320],[350,1250],[480,1210],[650,1050],[930,950],[1200,730],[1530,650],[1830,470],[2230,400]],
		[[1200,730],[1600,1000],[2130,1050],[2260,1250]],
		[[1200,730],[1200,200]]])
	walkable_half_width = float(config.get("walkableHalfWidth",130))
	landmarks = config.get("landmarks",[
		{"id":"forest_canopy","x":650,"y":1050,"name":"Celah Cahaya Tajuk","title":"Cahaya di sela daun","text":"Amati daun yang mendapat cahaya di sela tajuk."},
		{"id":"forest_roots","x":1200,"y":730,"name":"Akar dan Serasah","title":"Tanah yang hidup","text":"Akar menjaga tanah; pengurai mendaur ulang unsur hara."},
		{"id":"forest_stream","x":1830,"y":470,"name":"Aliran Hulu Bandar","title":"Hutan dan teluk terhubung","text":"Aliran ini membawa air dari hutan menuju Bandar Hujung."}])
	blocked_exits = config.get("blockedExits",[
		{"id":"bridge_east","x":2230,"y":400,"width":180,"height":80,"name":"Jembatan Akar Patah","reason":"Jembatan belum aman dilalui. Jalur ini terbuka pada petualangan berikutnya."},
		{"id":"landslide_north","x":1200,"y":200,"width":240,"height":90,"name":"Longsoran Hulu","reason":"Batu dan tanah menutup jalur hulu."},
		{"id":"gate_east","x":2260,"y":1250,"width":110,"height":220,"name":"Gerbang Kebun Lama","reason":"Gerbang kebun lama masih terkunci."}])
	landmarks = landmarks.duplicate(true)
	landmarks.append({"id":"forest_cache","x":2130,"y":1050,"name":"Peti Perbekalan","title":"Bekal di persimpangan","text":"Perbekalan lama tersimpan di pinggir jalan hutan."})
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	if ResourceLoader.exists("res://resources/art/forest-muara.png"):
		background = load("res://resources/art/forest-muara.png")
	_build_props()
	_add_polyfork_plant("fern-plant",Vector2(485,1160),Vector2(68,68))
	_add_polyfork_plant("fern-plant",Vector2(1480,810),Vector2(60,60))
	depth_planes = preload("res://scripts/DepthPlanes.gd").new()
	depth_planes.configure("forest",EXTENT,walkable_paths,walkable_half_width)
	add_child(depth_planes)
	move_child(depth_planes,0)
	_build_lighting()
	var pixel_effects := preload("res://scripts/PixelEffects.gd").new()
	pixel_effects.name = "PixelEffects"
	add_child(pixel_effects)
	pixel_effects.configure("forest")
	avatar = ForestAvatar.new()
	avatar.position = ENTRY
	var saved_surface: Variant = GameState.get("surface")
	var surface: Dictionary = saved_surface if saved_surface is Dictionary else GameState.adventure.get("surface",{})
	if str(surface.get("area","")) == "forest":
		avatar.position = Vector2(float(surface.get("x",ENTRY.x)),float(surface.get("y",ENTRY.y)))
	avatar.position = avatar.position.clamp(Vector2(40,120),Vector2(2360,1500))
	last_position = avatar.position
	var appearance: Variant = GameState.player.get("appearance","male_default")
	var appearance_id := str(appearance.get("id","male_default")) if appearance is Dictionary else str(appearance)
	var paths := {"male_default":"male-default","male_nusantara":"male-nusantara","female_default":"female-default","female_nusantara":"female-nusantara"}
	if paths.has(appearance_id):
		atlas_path = "res://resources/art/%s.png" % paths[appearance_id]
		if ResourceLoader.exists(atlas_path):
			avatar.sheet = load(atlas_path)
	avatar.variant = appearance_id
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 13
	collider.shape = shape
	collider.position = Vector2(0,-6)
	avatar.add_child(collider)
	actors.add_child(avatar)
	for item in [["ular_muara",Vector2(960,900),90.0],["kura_pesisir",Vector2(1630,980),60.0]]:
		var creature := ForestCreature.new()
		creature.species = item[0]
		creature.origin = item[1]
		creature.position = item[1]
		creature.width = item[2]
		creature.walkable = _is_walkable
		actors.add_child(creature)
	var forest_life := ForestLife.new()
	forest_life.focus = avatar
	forest_life.z_index = 3
	add_child(forest_life)
	camera = Camera2D.new()
	camera.zoom = Vector2(1.05,1.05)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(EXTENT.x)
	camera.limit_bottom = int(EXTENT.y)
	avatar.add_child(camera)
	_build_ui()
	if get_tree().has_meta("surface_change_notice"):
		game_hud.message(str(get_tree().get_meta("surface_change_notice")))
		get_tree().remove_meta("surface_change_notice")
	var environment = get_node_or_null("/root/EnvironmentState")
	if environment != null:
		var progress: Dictionary = GameState.player.get("progress",{})
		environment.update_story(int(progress.get("day",1)),str(progress.get("stage","dive")))
	var effects = preload("res://scripts/EnvironmentEffects.gd").new()
	effects.configure("forest")
	add_child(effects)
	queue_redraw()
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		window.jalasmaraReady = true
		_publish_snapshot()
		window.parent.postMessage(JavaScriptBridge.get_interface("JSON").parse('{"type":"jalasmara:ready"}'),str(window.location.origin))

func _register_input() -> void:
	for action in {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"up":[KEY_W,KEY_UP],"down":[KEY_S,KEY_DOWN],"interact":[KEY_E],"journal":[KEY_J],"map":[KEY_M],"inventory":[KEY_I],"character":[KEY_C]}:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var keys: Array = {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"up":[KEY_W,KEY_UP],"down":[KEY_S,KEY_DOWN],"interact":[KEY_E],"journal":[KEY_J],"map":[KEY_M],"inventory":[KEY_I],"character":[KEY_C]}[action]
		for key in keys:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action,event):
				InputMap.action_add_event(action,event)

func _build_props() -> void:
	if background != null:
		# Polygon memakai UV peta asli; titik urut berada pada kaki batang.
		_add_foreground(Vector2(70,709),[Vector2(0,337),Vector2(72,324),Vector2(154,360),Vector2(222,417),Vector2(197,520),Vector2(103,505),Vector2(73,710),Vector2(35,709),Vector2(42,499),Vector2(0,535)],22)
		_add_foreground(Vector2(454,610),[Vector2(338,449),Vector2(395,407),Vector2(467,430),Vector2(528,480),Vector2(553,558),Vector2(483,549),Vector2(475,609),Vector2(434,620),Vector2(411,537),Vector2(335,530)],22)
		_add_foreground(Vector2(690,399),[Vector2(470,186),Vector2(541,122),Vector2(653,105),Vector2(747,139),Vector2(824,196),Vector2(859,278),Vector2(795,340),Vector2(730,356),Vector2(721,405),Vector2(657,416),Vector2(624,357),Vector2(550,343),Vector2(483,290)],28)
		_add_foreground(Vector2(1428,618),[Vector2(1314,414),Vector2(1392,347),Vector2(1481,360),Vector2(1536,402),Vector2(1536,530),Vector2(1480,528),Vector2(1455,628),Vector2(1409,634),Vector2(1391,530),Vector2(1315,528)],22)
		_add_foreground(Vector2(720,1010),[Vector2(420,818),Vector2(444,763),Vector2(509,703),Vector2(590,672),Vector2(673,705),Vector2(724,651),Vector2(787,644),Vector2(849,672),Vector2(870,720),Vector2(954,724),Vector2(992,793),Vector2(1068,879),Vector2(1040,1024),Vector2(441,1024)],0,false)
		_add_foreground(Vector2(286,285),[Vector2(169,153),Vector2(250,89),Vector2(370,127),Vector2(427,173),Vector2(395,204),Vector2(363,204),Vector2(367,270),Vector2(327,286),Vector2(242,278),Vector2(221,239),Vector2(180,232)],0,false)
		_add_rect_obstacle(Rect2(347,308,218,101))
		_add_rect_occluder(Rect2(347,308,218,101))
		# Pemain tidak dapat menembus batu besar yang tampak di tepi jalan.
		for item in [Vector3(391,837,26),Vector3(292,920,35),Vector3(1076,377,24),Vector3(1114,589,29),Vector3(1271,771,32),Vector3(1450,855,35)]:
			_add_circle_obstacle(Vector2(item.x,item.y)*1.5625,item.z*1.5625)
	else:
		for at in [Vector2(400,800),Vector2(900,600),Vector2(1550,450),Vector2(2250,800)]:
			_add_prop("tree",at,0,true)
	for item in landmarks:
		var at := Vector2(item.x,item.y) + Vector2(24,8)
		var kind: String = {"forest_canopy":"canopy","forest_roots":"roots","forest_stream":"stream","forest_cache":"cache"}.get(str(item.id),"canopy")
		_add_prop(kind,at,0,false)
		_add_circle_obstacle(at,18 if kind=="cache" else 7)
	for item in blocked_exits:
		var at := Vector2(item.x,item.y)
		var kind: String = {"landslide_north":"landslide","bridge_east":"bridge","gate_east":"gate"}.get(str(item.id),"landslide")
		_add_prop(kind,at+Vector2(0,float(item.height)/2),0,false)
		_add_rect_obstacle(Rect2(at-Vector2(item.width,item.height)/2,Vector2(item.width,item.height)))
	for edge in [Rect2(-40,80,2480,40),Rect2(-40,1500,2480,40),Rect2(0,120,40,1380),Rect2(2360,120,40,1380)]:
		_add_rect_obstacle(edge)

func _add_polyfork_plant(id: String, at: Vector2, dimensions: Vector2) -> void:
	var path := "res://resources/art/polyfork/%s.png" % id
	if not ResourceLoader.exists(path): return
	var plant := Sprite2D.new()
	plant.texture = load(path)
	plant.position = at
	plant.centered = false
	plant.offset = Vector2(-plant.texture.get_width()/2.0,-plant.texture.get_height())
	plant.scale = dimensions/plant.texture.get_size()
	plant.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	actors.add_child(plant)

func _add_foreground(base_pixel: Vector2, polygon_pixels: Array, trunk_radius: float, foliage := true) -> void:
	var foreground := Polygon2D.new()
	foreground.position = base_pixel * 1.5625
	var polygon := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in polygon_pixels:
		polygon.append((point-base_pixel)*1.5625)
		uv.append(point)
	foreground.polygon = polygon
	foreground.uv = uv
	foreground.texture = background
	if foliage:
		var leaves := ShaderMaterial.new()
		leaves.shader = preload("res://shaders/foliage.gdshader")
		leaves.set_shader_parameter("strength",2.5)
		leaves.set_shader_parameter("wind_speed",1.2)
		leaves.set_shader_parameter("wind_phase",fmod(base_pixel.x*0.031,TAU))
		foreground.material = leaves
	actors.add_child(foreground)
	if trunk_radius > 0:
		_add_circle_obstacle(base_pixel*1.5625,trunk_radius*1.5625)
		_add_trunk_occluder(base_pixel*1.5625,trunk_radius*1.5625)

func _add_circle_obstacle(at: Vector2,radius: float) -> void:
	var body := StaticBody2D.new()
	body.position = at
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _add_rect_obstacle(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _add_prop(kind: String, at: Vector2, variant: int, solid: bool) -> void:
	var prop := ForestProp.new()
	prop.kind = kind
	prop.variant = variant
	prop.position = at
	prop.display_size = {"canopy":Vector2(136,114),"roots":Vector2(170,145),"stream":Vector2(150,130),"landslide":Vector2(280,180),"bridge":Vector2(270,155),"gate":Vector2(180,245)}.get(kind,Vector2(136,114))
	actors.add_child(prop)
	if solid:
		var body := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 18 if kind == "tree" else 27
		collision.shape = shape
		collision.position.y = -6
		body.add_child(collision)
		prop.add_child(body)

func _path_distance(at: Vector2, points: Array) -> float:
	var distance := 99999.0
	for i in range(points.size()-1):
		distance = minf(distance,at.distance_to(Geometry2D.get_closest_point_to_segment(at,points[i],points[i+1])))
	return distance

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,EXTENT),Color("33523a"))
	if background != null:
		draw_texture_rect(background,Rect2(Vector2.ZERO,EXTENT),false)
	var route := PackedVector2Array([Vector2(200,1320),Vector2(480,1210),Vector2(650,1050),Vector2(930,950),Vector2(1200,730),Vector2(1530,650),Vector2(1830,470)])
	var branch := PackedVector2Array([Vector2(1200,730),Vector2(1600,1000),Vector2(2130,1050)])
	for path in ([] if background != null else [route,branch]):
		draw_polyline(path,Color(0.35,0.37,0.20,0.7),126,false)
		draw_polyline(path,Color(0.60,0.51,0.31,0.86),89,false)
		for point in path:
			draw_circle(point,44,Color(0.60,0.51,0.31,0.86))
	# Aliran mengikuti lereng; tepian dangkal tetap bisa dijelajahi.
	var stream := PackedVector2Array([Vector2(2230,40),Vector2(2100,200),Vector2(1970,330),Vector2(1870,450),Vector2(1860,620),Vector2(2020,760),Vector2(2240,840),Vector2(2450,860)])
	draw_polyline(stream,Color(0.34,0.48,0.40,0.0 if background != null else 1.0),100,false)
	draw_polyline(stream,Color(0.32,0.55,0.53,0.0 if background != null else 1.0),67,false)
	draw_polyline(stream,Color(0.60,0.81,0.71,0.0 if background != null else 0.4),7,false)

func _physics_process(delta: float) -> void:
	if avatar == null:
		return
	if is_instance_valid(depth_planes): depth_planes.update_camera(avatar.position)
	var direction := Input.get_vector("left","right","up","down")
	if touch_direction != Vector2.ZERO:
		direction = touch_direction.normalized()
	if modal_open or busy:
		direction = Vector2.ZERO
	avatar.velocity = avatar.velocity.move_toward(direction*WALK_SPEED,delta*1250)
	if direction == Vector2.ZERO:
		avatar.velocity = avatar.velocity.move_toward(Vector2.ZERO,delta*1700)
	var previous_position := avatar.position
	avatar.move_and_slide()
	path_notice_cooldown = maxf(0.0,path_notice_cooldown-delta)
	if not _is_walkable(avatar.position):
		avatar.position = previous_position
		avatar.velocity = Vector2.ZERO
		if path_notice_cooldown <= 0.0:
			game_hud.message("Vegetasi lebat menutup jalur. Ikuti jalan tanah atau telusuri cabangnya.")
			path_notice_cooldown = 4.0
	avatar.position = avatar.position.clamp(Vector2(40,120),Vector2(2360,1500))
	avatar.walking = avatar.velocity.length() > 8
	light_clock += delta
	if Engine.get_physics_frames() % 6 == 0:
		_update_lighting()
	avatar.clock += delta
	if direction.length() > 0.1:
		avatar.facing = direction
	avatar.queue_redraw()
	_find_nearby()
	if OS.has_feature("web") and Engine.get_process_frames() % 10 == 0:
		_publish_snapshot()
	if Input.is_action_just_pressed("interact") and not modal_open:
		_interact()
	if not modal_open and not busy:
		if Input.is_action_just_pressed("journal"):
			_show_journal()
		elif Input.is_action_just_pressed("inventory"):
			_show_inventory()
		elif Input.is_action_just_pressed("map"):
			_show_map()
		elif Input.is_action_just_pressed("character"):
			_show_characters()
	if Input.is_key_pressed(KEY_ESCAPE) and modal_open:
		_close_dialog()
	sync_clock += delta
	if sync_clock >= 2.0 and not syncing and not busy:
		sync_clock = 0.0
		_sync_position()

func _find_nearby() -> void:
	nearest = {}
	var distance := 95.0
	for item in landmarks:
		var candidate := avatar.position.distance_to(Vector2(item.x,item.y))
		if candidate < distance:
			distance = candidate
			nearest = item
	for exit in blocked_exits:
		var rect := Rect2(Vector2(exit.x,exit.y)-Vector2(exit.width,exit.height)/2,Vector2(exit.width,exit.height)).grow(75)
		if rect.has_point(avatar.position):
			nearest = {"id":exit.id,"name":exit.name,"blocked":true,"reason":exit.get("reason","Jalur ini belum terbuka.")}
	if avatar.position.distance_to(ENTRY) < 110:
		nearest = {"id":"return","name":"Kembali ke Bandar Hujung"}
	var hud_state := {"area":"Hutan Pesisir Wringin","coins":GameState.player.get("coins",0),"weight":0,"capacity":GameState.player.get("bagCapacity",20),"objective":"Amati celah tajuk, akar hidup, dan aliran hulu.","action":str(nearest.get("name","Dekati temuan alam untuk mengamati")),"canInteract":not nearest.is_empty() and not busy,"canNet":false,"diving":false}
	var environment = get_node_or_null("/root/EnvironmentState")
	if environment != null:
		hud_state.merge(environment.snapshot())
	game_hud.update_state(hud_state)
	game_hud.set_navigation(GameState.world,"forest",avatar.position)

func _sync_position() -> bool:
	if syncing:
		return false
	syncing = true
	var result: Dictionary = await ApiClient.call_api("/adventure/surface-position",{"area":"forest","x":snappedf(avatar.position.x,0.1),"y":snappedf(avatar.position.y,0.1),"version":int(GameState.player.get("version",0))})
	syncing = false
	if not result.get("ok",false):
		if str(result.get("code","")) in ["SESSION_CHANGED","AREA_CHANGED"]:
			syncing = true
			busy = true
			avatar.velocity = Vector2.ZERO
			touch_direction = Vector2.ZERO
			var refreshed: Dictionary = await GameState.refresh()
			syncing = false
			if refreshed.get("ok",false):
				_close_dialog()
				var message := "Data permainan diubah oleh admin atau sesi lain. Posisi dan progres terbaru telah dimuat."
				if str(GameState.surface.get("area","hub")) != "forest":
					get_tree().set_meta("surface_change_notice",message)
					get_tree().change_scene_to_file("res://scenes/main.tscn")
				else:
					avatar.position = Vector2(float(GameState.surface.get("x",ENTRY.x)),float(GameState.surface.get("y",ENTRY.y)))
					last_position = avatar.position
					avatar.variant = str(GameState.player.get("appearance","male_default"))
					var path := "res://resources/art/%s.png" % avatar.variant.replace("_","-")
					avatar.sheet = load(path) if ResourceLoader.exists(path) else null
					game_hud.message(message)
					busy = false
			else:
				busy = false
				game_hud.message(str(refreshed.get("error","Perubahan data belum dapat dimuat. Coba sambungkan kembali.")))
			return false
		game_hud.message(str(result.get("error","Posisi belum tersimpan. Periksa koneksi.")))
		return false
	if result.has("surface"):
		GameState.surface = result.surface
	last_position = avatar.position
	if result.has("adventure"):
		GameState.adventure = result.adventure
	return true

func _interact() -> void:
	if nearest.is_empty() or busy or modal_open:
		return
	if nearest.get("blocked",false):
		_show_dialog(str(nearest.name),str(nearest.reason))
		return
	busy = true
	var item := nearest.duplicate()
	while syncing:
		await get_tree().process_frame
	var saved: bool = await _sync_position()
	if not saved:
		busy = false
		return
	if item.id == "return":
		var result: Dictionary = await ApiClient.call_api("/adventure/travel",{"destination":"hub"})
		if result.get("ok",false):
			await GameState.refresh()
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		else:
			busy = false
			game_hud.message(str(result.get("error","Belum dapat kembali ke dermaga.")))
		return
	var response: Dictionary = await ApiClient.call_api("/adventure/surface-interact",{"id":item.id})
	busy = false
	if not response.get("ok",false):
		game_hud.message(str(response.get("error","Pengamatan belum tersimpan.")))
		return
	if response.has("player"):
		GameState.player = response.player
	if response.has("adventure"):
		GameState.adventure = response.adventure
	var reward := int(response.get("reward",0))
	var knowledge: Dictionary = response.get("knowledge",{}) if response.get("knowledge") is Dictionary else {}
	var text := str(knowledge.get("text",item.get("text","Perbekalan ini dapat membantu perjalanan berikutnya.")))
	if reward > 0:
		text += "\n\nPenemuan baru: +%d koin. Tersimpan di jurnal." % reward
	else:
		text += "\n\nPengamatan tersimpan di jurnal."
	_show_dialog(str(knowledge.get("title",item.get("title",item.name))),text)

func _build_ui() -> void:
	game_hud = HudScript.new()
	add_child(game_hud)
	game_hud.interact_requested.connect(_interact)
	game_hud.journal_requested.connect(_show_journal)
	game_hud.map_requested.connect(_show_map)
	game_hud.inventory_requested.connect(_show_inventory)
	game_hud.character_requested.connect(_show_characters)
	game_hud.move_changed.connect(func(direction: Vector2): touch_direction = direction)
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	ui.theme = game_hud.root_control.theme.duplicate()
	ui.theme.set_color("font_color","Label",Color("302D2A"))
	ui.theme.set_color("default_color","RichTextLabel",Color("302D2A"))
	dialog = PanelContainer.new()
	dialog.position = Vector2(180,130)
	dialog.size = Vector2(600,285)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("F1E1BC")
	style.border_color = Color("654733")
	style.set_border_width_all(2)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	dialog.add_theme_stylebox_override("panel",style)
	var box := VBoxContainer.new()
	dialog.add_child(box)
	dialog_title = Label.new()
	dialog_title.add_theme_font_size_override("font_size",20)
	box.add_child(dialog_title)
	dialog_text = RichTextLabel.new()
	dialog_text.custom_minimum_size = Vector2(540,175)
	dialog_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_text.bbcode_enabled = false
	box.add_child(dialog_text)
	dialog_actions = VBoxContainer.new()
	box.add_child(dialog_actions)
	var close := Button.new()
	close.text = "Lanjut berjalan"
	close.custom_minimum_size.y = 42
	close.pressed.connect(_close_dialog)
	box.add_child(close)
	ui.add_child(dialog)
	dialog.hide()

func _show_dialog(title: String,text: String) -> void:
	modal_open = true
	game_hud.set_modal(true)
	for child in dialog_actions.get_children():
		child.queue_free()
	touch_direction = Vector2.ZERO
	dialog.position = Vector2(180,130)
	dialog_text.custom_minimum_size.y = 175
	dialog_title.text = title
	dialog_text.text = text
	dialog.show()

func _close_dialog() -> void:
	modal_open = false
	game_hud.set_modal(false)
	dialog.hide()
	if is_instance_valid(atlas_panel):
		atlas_panel.hide()

func _show_journal() -> void:
	if busy:
		return
	var text := ""
	var entries: Array = GameState.adventure.get("discoveries",[])
	for item in landmarks:
		var seen := false
		for entry in entries:
			if (entry is Dictionary and str(entry.get("id","")) == str(item.id)) or (entry is String and entry == item.id):
				seen = true
		if seen:
			text += str(item.name) + "\n" + str(item.get("text","Perbekalan ditemukan.")) + "\n\n"
	if text.is_empty():
		text = "Belum ada catatan hutan. Dekati penanda di sepanjang jalan, lalu tekan E untuk mengamati.\n\nKembali ke lingkaran jalan di barat daya untuk pulang ke Bandar Hujung."
	_show_dialog("Jurnal hutan",text)

func _show_inventory() -> void:
	var text := ""
	for item in GameState.player.get("inventory",[]):
		text += "%s  x%s\n" % [GameState.fragment_name(str(item.get("fragmentId",item.get("id","fragmen")))),str(item.get("quantity",1))]
	_show_dialog("Tas Nala",text if not text.is_empty() else "Tas masih kosong. Amati lingkungan, lalu jelajahi laut untuk menemukan fragmen ilmu.")

func _show_characters() -> void:
	_show_dialog("Penampilan Nala","Pilih penampilan. Kemampuan dan progres tetap mengikuti pemain.")
	dialog.position.y = 45
	dialog_text.custom_minimum_size.y = 65
	for option in [["male_default","Nala — pakaian selam"],["male_nusantara","Nala — kain pesisir"],["female_default","Nala perempuan — pakaian selam"],["female_nusantara","Nala perempuan — kain pesisir"]]:
		var button := Button.new()
		button.text = option[1]
		button.custom_minimum_size.y = 36
		button.pressed.connect(func(): _select_character(str(option[0])))
		dialog_actions.add_child(button)
		if str(option[0]) == avatar.variant:
			button.grab_focus()

func _select_character(id: String) -> void:
	if busy:
		return
	busy = true
	var result: Dictionary = await ApiClient.call_api("/game/appearance",{"appearance":id})
	busy = false
	if not result.get("ok",false):
		game_hud.message(str(result.get("error","Penampilan belum dapat disimpan.")))
		return
	if result.has("player"):
		GameState.player = result.player
	avatar.variant = id
	var paths := {"male_default":"male-default","male_nusantara":"male-nusantara","female_default":"female-default","female_nusantara":"female-nusantara"}
	var path := "res://resources/art/%s.png" % paths.get(id,"male-default")
	avatar.sheet = load(path) if ResourceLoader.exists(path) else null
	_close_dialog()

func _publish_snapshot() -> void:
	var snapshot := {"area":"forest","x":avatar.position.x,"y":avatar.position.y,"modal":modal_open,"nearby":str(nearest.get("id","")),"appearance":avatar.variant,"diving":false}
	snapshot["audio"] = AudioManager.debug_status()
	JavaScriptBridge.get_interface("window").jalasmaraSnapshot = JavaScriptBridge.get_interface("JSON").parse(JSON.stringify(snapshot))

func _show_map() -> void:
	if modal_open and is_instance_valid(atlas_panel):
		_close_dialog()
		return
	if busy:
		return
	modal_open = true
	touch_direction = Vector2.ZERO
	game_hud.set_modal(true)
	dialog.hide()
	if is_instance_valid(atlas_panel):
		atlas_panel.queue_free()
	atlas_panel = PanelContainer.new()
	atlas_panel.position = Vector2(139,52)
	atlas_panel.size = Vector2(682,422)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("F1E1BC")
	style.border_color = Color("654733")
	style.set_border_width_all(2)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	atlas_panel.add_theme_stylebox_override("panel",style)
	var atlas := AtlasScript.new()
	atlas.configure(GameState.world,GameState.player,"forest_wringin")
	atlas.set_player_position(avatar.position)
	atlas.close_requested.connect(_close_dialog)
	atlas_panel.add_child(atlas)
	ui.add_child(atlas_panel)

func _is_walkable(point: Vector2) -> bool:
	for path in walkable_paths:
		for index in range(path.size()-1):
			var first: Variant = path[index]
			var second: Variant = path[index+1]
			var start := Vector2(float(first[0]),float(first[1]))
			var end := Vector2(float(second[0]),float(second[1]))
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,start,end)) <= walkable_half_width:
				return true
	return false

func _build_lighting() -> void:
	_add_forest_light(Vector2(430,418),1.85,"lantern",true)
	# Cahaya penemuan berasal dari celah tajuk, bukan lampu pada papan UI.
	_add_forest_light(Vector2(670,985),2.8,"canopy",false)
	_add_forest_light(Vector2(1350,620),2.35,"canopy",false)
	_update_lighting()

func _add_forest_light(at: Vector2, size_scale: float, kind: String, shadows: bool) -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0,0.25,0.65,1.0])
	gradient.colors = PackedColorArray([Color(1,1,1,0.95),Color(1,1,1,0.55),Color(1,1,1,0.12),Color(1,1,1,0)])
	var texture := GradientTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5,0.5)
	texture.fill_to = Vector2(1,0.5)
	var light := PointLight2D.new()
	light.texture = texture
	light.texture_scale = size_scale
	light.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	light.color = Color("ffe0a3") if kind == "lantern" else Color("e9efc5")
	light.position = at
	light.shadow_enabled = shadows
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	light.shadow_color = Color(0.05,0.09,0.07,0.45)
	light.energy = 0.15
	add_child(light)
	forest_lights.append({"node":light,"kind":kind,"phase":fmod(at.x*0.017,TAU)})

func _update_lighting() -> void:
	var environment = get_node_or_null("/root/EnvironmentState")
	var data: Dictionary = environment.snapshot() if environment != null else {"daylight":0.9,"clouds":0.0}
	var daylight := clampf(float(data.get("daylight",0.9)),0.0,1.0)
	var clouds := clampf(float(data.get("clouds",0.0)),0.0,1.0)
	for entry in forest_lights:
		var light: PointLight2D = entry.node
		var phase := float(entry.phase)
		if str(entry.kind) == "lantern":
			var dusk := clampf((0.85-daylight)/0.65,0.0,1.0)
			light.energy = (0.10+dusk*0.56+clouds*0.05)*(1.0+sin(light_clock*2.7+phase)*0.025)
		else:
			light.energy = daylight*(1.0-clouds*0.80)*(0.055+sin(light_clock*0.22+phase)*0.008)

func _add_trunk_occluder(at: Vector2,radius: float) -> void:
	var polygon := PackedVector2Array()
	for i in range(10):
		var angle := TAU*i/10.0
		polygon.append(Vector2(cos(angle),sin(angle))*Vector2(radius,radius*0.48))
	var occluder := LightOccluder2D.new()
	var shape := OccluderPolygon2D.new()
	shape.polygon = polygon
	occluder.occluder = shape
	occluder.position = at
	add_child(occluder)

func _add_rect_occluder(rect: Rect2) -> void:
	var occluder := LightOccluder2D.new()
	var shape := OccluderPolygon2D.new()
	shape.polygon = PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])
	occluder.occluder = shape
	add_child(occluder)
