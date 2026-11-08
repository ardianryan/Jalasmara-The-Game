extends Node2D

const ROCK_SHADER = preload("res://shaders/ocean-rock.gdshader")
const SWAY_SHADER = preload("res://shaders/foliage.gdshader")
const WORLD_SIZE := Vector2(6144,3584)
const WATERLINE := 400.0
const TILE_SIZE := 256.0
var camera_point := Vector2(1120,470)
var solid_polygons: Array[PackedVector2Array] = []
var terrain: Array[Rect2] = []
var world: Dictionary = {}
var anchors: Array[Vector2] = []
var elapsed := 0.0
var atlas: Texture2D
var backdrop: Sprite2D
var hub_art: Texture2D
var decoration_count := 0
var near_growth: Array[Dictionary] = []

func configure(data: Dictionary, rectangles: Array[Rect2]) -> void:
	world = data
	terrain.assign(rectangles)

func _ready() -> void:
	if ResourceLoader.exists("res://resources/art/ocean-terrain-atlas.png"):
		atlas = load("res://resources/art/ocean-terrain-atlas.png")
	if ResourceLoader.exists("res://resources/art/bandar-hujung-map.png"):
		hub_art = load("res://resources/art/bandar-hujung-map.png")
	_collect_anchors()
	_build_water()
	for index in range(terrain.size()):
		_build_formation(terrain[index],index)
	_build_memory_relief()
	_build_anchored_growth()
	_build_near_growth()
	queue_redraw()

func _collect_anchors() -> void:
	anchors.assign([Vector2(1120,470),Vector2(1250,530),Vector2(1550,620)])
	for collection in ["landmarks","puzzles","caches","hazards"]:
		for item in world.get(collection,[]):
			anchors.append(Vector2(float(item.x),float(item.y)))
	for item in GameState.dive.get("targets",[]):
		if item is Dictionary and item.has("x") and item.has("y"):
			anchors.append(Vector2(float(item.x),float(item.y)))
	var boss: Dictionary = world.get("boss",{})
	if boss.has("x"):
		anchors.append(Vector2(float(boss.x),float(boss.get("y",3320))))

func _build_water() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0,0.24,0.55,0.84,1.0])
	gradient.colors = PackedColorArray([Color("299ca5"),Color("247e89"),Color("1c586c"),Color("173c55"),Color("102a42")])
	var water := GradientTexture2D.new()
	water.width = 16
	water.height = 1024
	water.gradient = gradient
	water.fill_from = Vector2(0.5,0)
	water.fill_to = Vector2(0.5,1)
	var plane := Sprite2D.new()
	plane.centered = false
	plane.position = Vector2(-100,WATERLINE-35)
	plane.texture = water
	plane.scale = Vector2((WORLD_SIZE.x+200)/16.0,(WORLD_SIZE.y-WATERLINE+100)/1024.0)
	plane.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	plane.z_index = -30
	add_child(plane)
	var path := "res://resources/art/ocean-depth-background.png"
	if ResourceLoader.exists(path):
		backdrop = Sprite2D.new()
		backdrop.texture = load(path)
		backdrop.centered = false
		backdrop.scale = Vector2(6400,3260)/backdrop.texture.get_size()
		backdrop.position = Vector2(-128,390)
		backdrop.modulate = Color(0.68,0.85,0.91,0.76)
		backdrop.z_index = -25
		add_child(backdrop)

func _build_memory_relief() -> void:
	if atlas == null:
		return
	# A distant karst rib explains the tablet's setting without blocking its swim route.
	var relief := Polygon2D.new()
	relief.position = Vector2(1550,680)
	relief.polygon = PackedVector2Array([Vector2(-26,0),Vector2(22,0),Vector2(41,70),Vector2(28,120),Vector2(62,175),Vector2(53,240),Vector2(98,310),Vector2(118,390),Vector2(-126,390),Vector2(-82,305),Vector2(-74,238),Vector2(-50,174),Vector2(-61,115),Vector2(-35,63)])
	var coordinates := PackedVector2Array()
	for point in relief.polygon:
		coordinates.append((point+Vector2(130,0))*2.0)
	relief.uv = coordinates
	relief.texture = atlas
	relief.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	relief.modulate = Color(0.53,0.72,0.74,0.87)
	relief.z_index = -8
	var material := ShaderMaterial.new()
	material.shader = ROCK_SHADER
	material.set_shader_parameter("atlas_grid",Vector2(3,2))
	material.set_shader_parameter("world_top",680.0)
	material.set_shader_parameter("face_height",390.0)
	material.set_shader_parameter("material_column",0.0)
	relief.material = material
	add_child(relief)

func _build_formation(rect: Rect2,index: int) -> void:
	var polygon := outline_for(rect,index)
	solid_polygons.append(polygon)
	var body := StaticBody2D.new()
	var collision := CollisionPolygon2D.new()
	collision.polygon = polygon
	body.add_child(collision)
	add_child(body)
	var shadow := LightOccluder2D.new()
	var silhouette := OccluderPolygon2D.new()
	silhouette.polygon = polygon
	shadow.occluder = silhouette
	add_child(shadow)
	if rect.position.y < WATERLINE and rect.size.x > 200:
		return
	var face := Polygon2D.new()
	face.position = rect.position
	var local := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in polygon:
		local.append(point-rect.position)
		uv.append((point-rect.position)*2.0)
	face.polygon = local
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if atlas != null:
		face.texture = atlas
		face.uv = uv
		var material := ShaderMaterial.new()
		material.shader = ROCK_SHADER
		material.set_shader_parameter("atlas_grid",Vector2(3,2))
		material.set_shader_parameter("world_top",rect.position.y)
		material.set_shader_parameter("face_height",rect.size.y)
		material.set_shader_parameter("vertical_cliff",rect.size.y>700)
		material.set_shader_parameter("material_column",_material_index(rect.get_center().y))
		face.material = material
	else:
		face.color = Color("47716c")
	add_child(face)

func outline_for(rect: Rect2,index: int) -> PackedVector2Array:
	# API rectangles remain solid cores; the visible scallops also define local collision.
	if rect.position.y < WATERLINE and rect.size.x > 200:
		return PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])
	var points := PackedVector2Array()
	var corners := [rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]
	var outward := [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]
	for side in range(4):
		var start: Vector2 = corners[side]
		var end: Vector2 = corners[(side+1)%4]
		var steps := maxi(2,ceili(start.distance_to(end)/145.0))
		for step in range(steps):
			var weight := float(step)/steps
			var point := start.lerp(end,weight)
			var wave := 0.5+0.5*sin(float(index)*2.13+float(step)*1.72+float(side)*2.4)
			var distance := sin(weight*PI)*(7.0+wave*17.0)
			var candidate: Vector2 = point+outward[side]*distance
			for anchor in anchors:
				if candidate.distance_to(anchor) < 145.0:
					distance = 0.0
			if Geometry2D.get_closest_point_to_segment(candidate,Vector2(1120,470),Vector2(1550,620)).distance_to(candidate)<110.0:
				distance = 0.0
			points.append(point+outward[side]*distance)
	return points

func _material_index(depth: float) -> float:
	return 0.0 if depth<2080 else 1.0 if depth<3060 else 2.0

func _build_anchored_growth() -> void:
	if atlas == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 18342
	for index in range(terrain.size()):
		var rect := terrain[index]
		if rect.position.y < 550 or rect.size.x < 150 or rect.position.y>3370:
			continue
		if rect.position.y<2080:
			var count := clampi(int(rect.size.x/170),1,20)
			for step in range(count):
				var x := rect.position.x+70+float(step)*maxf(1,(rect.size.x-140)/maxi(count-1,1))
				var height := rng.randf_range(75,140)
				var width := height*rng.randf_range(1.0,1.5)
				var kind := 2 if rect.position.y>1100 and step%3==0 else 0
				var at := Vector2(x,rect.position.y+25)
				_add_growth(at,kind,Vector2(width,height),step*0.7)
		if rect.size.y>700:
			for step in range(2,mini(14,int(rect.size.y/160))):
				var at := Vector2(rect.position.x+65,rect.position.y+step*160)
				_add_growth(at,1,Vector2(130,95),step)

func _add_growth(at: Vector2,kind: int,dimensions: Vector2,phase: float) -> void:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	var cell := atlas.get_size()/Vector2(3,2)
	texture.region = Rect2(Vector2(kind*cell.x,cell.y),cell)
	var plant := Sprite2D.new()
	plant.texture = texture
	plant.position = at
	plant.offset = Vector2(0,-cell.y/2)
	plant.scale = dimensions/cell
	plant.modulate = Color(0.78,0.92,0.83,0.95) if at.y>2080 else Color.WHITE
	if kind==2:
		var sway := ShaderMaterial.new()
		sway.shader = SWAY_SHADER
		sway.set_shader_parameter("strength",7.5)
		sway.set_shader_parameter("wind_speed",0.8)
		sway.set_shader_parameter("wind_phase",phase)
		plant.material = sway
	add_child(plant)
	decoration_count += 1

func _process(delta: float) -> void:
	elapsed += delta
	if is_instance_valid(backdrop):
		backdrop.position = Vector2(-128+camera_point.x*0.018,390+camera_point.y*0.008)
	_update_near_growth()
	queue_redraw()

func _draw() -> void:
	if camera_point.y<850:
		if hub_art != null:
			var source := Rect2(Vector2.ZERO,Vector2(hub_art.get_width(),hub_art.get_height()*0.68125))
			draw_texture_rect_region(hub_art,Rect2(0,-160,3080,545),source)
		# Surface reflection is atmospheric; it does not add invisible collision.
		for index in range(16):
			var x := index*210.0+sin(elapsed*0.5+index)*13
			draw_line(Vector2(x,395),Vector2(x+78,395),Color(0.71,0.91,0.86,0.15),2)
	var view := Rect2(camera_point-Vector2(700,440),Vector2(1400,880))
	for index in range(110):
		var at := Vector2(fposmod(index*173.0+sin(elapsed*0.2+index)*12,6144),420+fposmod(index*197.0-elapsed*(4+index%5)+3100,3020))
		if view.has_point(at):
			draw_circle(at,1.0+index%2,Color(0.62,0.84,0.79,0.14))

func _build_near_growth() -> void:
	if atlas == null:
		return
	var cell := atlas.get_size()/Vector2(3,2)
	for index in range(terrain.size()):
		var rect := terrain[index]
		if rect.position.y<650 or rect.size.x<280:
			continue
		for side in [0,1]:
			var at := Vector2(rect.position.x+65 if side==0 else rect.end.x-65,rect.position.y+35)
			var kind := 2 if rect.position.y>1100 and rect.position.y<2080 else 0
			if rect.position.y>2080:
				kind = 1
			var tile := AtlasTexture.new()
			tile.atlas = atlas
			tile.region = Rect2(Vector2(kind*cell.x,cell.y),cell)
			var plant := Sprite2D.new()
			plant.texture = tile
			plant.offset = Vector2(0,-cell.y/2)
			plant.scale = Vector2(235,225)/cell
			plant.z_index = 20
			plant.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			plant.position = at
			plant.modulate = Color(0.32,0.53,0.47,0)
			var sway := ShaderMaterial.new()
			sway.shader = SWAY_SHADER
			sway.set_shader_parameter("strength",5.0 if kind==2 else 1.5)
			sway.set_shader_parameter("wind_speed",0.65)
			sway.set_shader_parameter("wind_phase",index*1.7+side)
			plant.material = sway
			add_child(plant)
			near_growth.append({"node":plant,"base":at})

func _update_near_growth() -> void:
	var camera := get_viewport().get_camera_2d()
	var zoom := camera.zoom if camera != null else Vector2(0.88,0.88)
	var half_view := get_viewport_rect().size/zoom/2.0
	for entry in near_growth:
		var plant: Sprite2D = entry.node
		var base: Vector2 = entry.base
		var relative := base-camera_point
		var onscreen := absf(relative.x)<half_view.x+250 and absf(relative.y)<half_view.y+270
		plant.visible = onscreen
		if not onscreen:
			continue
		var edge := maxf(absf(relative.x)/half_view.x,absf(relative.y)/half_view.y)
		var opacity := smoothstep(0.72,1.1,edge)*0.84
		plant.modulate.a = opacity
		# Decorative near-plane roots stay within the existing solid ledge.
		plant.position = base-relative*0.035
