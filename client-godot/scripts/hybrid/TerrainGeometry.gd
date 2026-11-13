extends Node3D

@export var projection_tilt_degrees := 12.0
const FRONT_DEPTH := 26.0
const Layers = preload("res://scripts/hybrid/TerrainLayerProfile.gd")
var layered_band_count := 0
var world: Dictionary = {}
var terrain_count := 0
var triangle_count := 0
var volume_depth_range := Vector2(220, 440)
var projected_bounds: Array[Rect2] = []
var _uv_rect := Rect2(0,0,512,512)
var model_instances := 0
var backing_instances := 0
var geology: Node3D
var _atlas: Texture2D
var _materials: Array[Material] = []
var _coral_pivots: Array[Dictionary] = []

func configure(data: Dictionary) -> void:
	world = data
	for child in get_children():
		remove_child(child)
		child.queue_free()
	terrain_count = 0
	layered_band_count = 0
	triangle_count = 0
	model_instances = 0
	backing_instances = 0
	_coral_pivots.clear()
	projected_bounds.clear()
	_atlas = load("res://resources/art/ocean-terrain-atlas.png")
	_materials.clear()
	for column in range(3):
		var material := ShaderMaterial.new()
		material.shader = preload("res://scripts/hybrid/reef-material.gdshader")
		material.set_shader_parameter("rock_atlas",_atlas)
		material.set_shader_parameter("material_column",float(column))
		_materials.append(material)
	for entry in world.get("terrain", []):
		var rect := Rect2(float(entry[0]), float(entry[1]), float(entry[2]), float(entry[3]))
		if rect.position.y < 400 and rect.size.x > 500 and rect.size.y < 100:
			_build_dock(rect)
		else:
			_build_reef(rect, terrain_count)
		projected_bounds.append(rect)
		terrain_count += 1
	geology=preload("res://scripts/hybrid/OceanGeology.gd").new()
	add_child(geology)
	geology.configure(world,_materials)
	_build_cave_backwall()
	_build_model_rocks()
	_build_memory_backing()
	_build_growth()

func _point(at: Vector2, depth: float) -> Vector3:
	return Vector3(at.x, -at.y + sin(deg_to_rad(projection_tilt_degrees)) * depth, depth)

func _uv(at: Vector2, _column: int) -> Vector2:
	return at / 360.0

func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, column: int, shade: Color) -> void:
	if (b - a).cross(c - a).z < 0.0:
		var previous := b
		b = c
		c = previous
	var normal := (b - a).cross(c - a).normalized()
	for vertex in [a,b,c]:
		tool.set_normal(normal)
		tool.set_color(shade)
		tool.set_uv(_uv(Vector2(vertex.x, -vertex.y + sin(deg_to_rad(projection_tilt_degrees)) * vertex.z), column))
		tool.add_vertex(vertex)
	triangle_count += 1

func _build_reef(rect: Rect2, index: int) -> void:
	var outline := PackedVector2Array()
	var contours: Array = world.get("terrainContours",[])
	if index < contours.size():
		for point in contours[index]: outline.append(Vector2(float(point[0]),float(point[1])))
	if outline.size() < 3:
		outline = PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	var column := 0 if rect.get_center().y < 2080 else 1 if rect.get_center().y < 3060 else 2
	var profile: Dictionary = Layers.at_depth(rect.get_center().y)
	var depth := float(profile.extrusion) * (0.88 + 0.12 * sin(index * 2.137))
	var front := PackedVector2Array()
	for point in outline:
		var inset_point := point.lerp(rect.get_center(),float(profile.inset))
		front.append(inset_point if Geometry2D.is_point_in_polygon(inset_point,outline) else point.lerp(rect.get_center(),0.025))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var band_height:=float(profile.get("bandHeight",52.0))
	var band_count:=maxi(1,ceili(rect.size.y/band_height))
	for band in range(band_count):
		var y0:=rect.position.y+band*band_height
		var strip:=PackedVector2Array([Vector2(rect.position.x-1,y0),Vector2(rect.end.x+1,y0),Vector2(rect.end.x+1,y0+band_height),Vector2(rect.position.x-1,y0+band_height)])
		for section in Geometry2D.intersect_polygons(front,strip):
			var triangles:=Geometry2D.triangulate_polygon(section)
			for offset in range(0,triangles.size(),3):
				var points: Array[Vector3]=[]
				for corner in range(3):
					var at: Vector2=section[triangles[offset+corner]]
					var relief:=FRONT_DEPTH+float(profile.peak)*(.5+.3*sin(at.x*.008+index)+.2*sin(band*1.9))
					points.append(_point(at,relief))
				var shade:=Color(profile.top).lerp(Color(profile.side),.18+.12*float(band%3))
				_triangle(tool,points[0],points[1],points[2],column,shade)
	var terrace_count := int(profile.terraces)
	for segment in range(outline.size()):
		var next := (segment + 1) % outline.size()
		var tangent := outline[next] - outline[segment]
		var outward := Vector2(tangent.y,-tangent.x).normalized()
		var top_weight := clampf(-outward.y,0,1)
		for band in range(terrace_count):
			var t0 := Layers.outline_band_factor(band,terrace_count,segment,index)
			var t1 := Layers.outline_band_factor(band,terrace_count,next,index)
			var t2 := Layers.outline_band_factor(band+1,terrace_count,segment,index)
			var t3 := Layers.outline_band_factor(band+1,terrace_count,next,index)
			var outer_a := _point(outline[segment].lerp(front[segment],t0),lerpf(-depth,FRONT_DEPTH,pow(t0,0.65)))
			var outer_b := _point(outline[next].lerp(front[next],t1),lerpf(-depth,FRONT_DEPTH,pow(t1,0.65)))
			var inner_a := _point(outline[segment].lerp(front[segment],t2),lerpf(-depth,FRONT_DEPTH,pow(t2,0.65)))
			var inner_b := _point(outline[next].lerp(front[next],t3),lerpf(-depth,FRONT_DEPTH,pow(t3,0.65)))
			var tint: Color = Color(profile.side).lerp(Color(profile.top),top_weight * 0.65)
			if band % 2 == 1: tint = tint.lerp(Color(profile.edge),0.70)
			_triangle(tool,outer_a,outer_b,inner_b,column,tint)
			_triangle(tool,outer_a,inner_b,inner_a,column,tint)
			layered_band_count += 1
	var back_triangles := Geometry2D.triangulate_polygon(outline)
	for offset in range(0,back_triangles.size(),3):
		_triangle(tool,_point(outline[back_triangles[offset]],-depth),_point(outline[back_triangles[offset+1]],-depth),_point(outline[back_triangles[offset+2]],-depth),column,Color(0.50,0.67,0.73))
	var instance := MeshInstance3D.new()
	instance.name = "ReefRelief%d" % index
	instance.mesh = tool.commit()
	instance.material_override = _materials[column]
	add_child(instance)

func _build_cave_backwall() -> void:
	_uv_rect = Rect2(390,570,790,670)
	var outline := PackedVector2Array([
		Vector2(420,600),Vector2(505,578),Vector2(590,608),Vector2(700,590),
		Vector2(770,632),Vector2(850,608),Vector2(936,635),Vector2(1020,612),
		Vector2(1110,653),Vector2(1154,716),Vector2(1125,790),Vector2(1172,858),
		Vector2(1128,945),Vector2(1148,1020),Vector2(1100,1088),Vector2(1090,1178),
		Vector2(1008,1195),Vector2(925,1170),Vector2(840,1220),Vector2(750,1195),
		Vector2(656,1228),Vector2(580,1185),Vector2(496,1214),Vector2(430,1168),
		Vector2(444,1080),Vector2(410,1012),Vector2(437,940),Vector2(402,865),
		Vector2(434,790),Vector2(403,716)])
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector2(785,910)
	# Irregular rear ledges share world UVs with the rock face, not alpha cards.
	for band in range(3):
		var outer_weight: float=[1.0,.76,.42][band]
		var inner_weight: float=[.76,.42,0.0][band]
		for index in range(outline.size()):
			var next:=(index+1)%outline.size()
			var corners:Array[Vector3]=[]
			for pair in [Vector2i(index,0),Vector2i(next,0),Vector2i(next,1),Vector2i(index,1)]:
				var weight:=outer_weight if pair.y==0 else inner_weight
				var at:=center.lerp(outline[pair.x],weight)
				var depth:=lerpf(-710.0,-555.0,weight)+sin(pair.x*1.47+weight*2.0)*18.0*weight
				corners.append(_point(at,depth))
			var shade:=Color(.40,.56,.59).lerp(Color(.47,.61,.61),float(index%5)/4.0)
			if band==1: shade=shade.darkened(.08)
			_triangle(tool,corners[0],corners[1],corners[2],1,shade)
			if inner_weight>0: _triangle(tool,corners[0],corners[2],corners[3],1,shade)
	var wall := MeshInstance3D.new()
	wall.name = "CaveRearRockWall"
	wall.mesh = tool.commit()
	wall.material_override = _materials[1]
	wall.set_meta("rear_outline",outline)
	wall.set_meta("relief_bands",3)
	add_child(wall)

func _build_model_rocks() -> void:
	set_meta("model_rock_mounts",[])
	var mounting:=preload("res://scripts/hybrid/OceanRockMount.gd")
	var path := "res://resources/models/reef-rock.glb"
	if not ResourceLoader.exists(path): return
	var source = load(path)
	if not source is PackedScene: return
	for at in [Vector2(620,1130),Vector2(1530,1140),Vector2(3210,990)]:
		var rock: Node3D = source.instantiate()
		rock.scale = Vector3.ONE * 95.0
		rock.rotation = Vector3(0.12,0.5 + model_instances * 1.6,0.18)
		var mount: Dictionary=mounting.solve(self,world,rock,at,deg_to_rad(projection_tilt_degrees))
		get_meta("model_rock_mounts").append(mount)
		if not bool(mount.supported):
			rock.free()
			continue
		rock.position=_point(at,float(mount.depth))
		rock.set_meta("reef_mount",mount)
		var rock_material := StandardMaterial3D.new()
		rock_material.albedo_color = Color("a0b9ac")
		var column:=0 if at.y<2080 else 1 if at.y<3060 else 2
		var image:=_atlas.get_image()
		if image.is_compressed():image.decompress()
		var tile:=image.get_region(Rect2i(column*image.get_width()/3,0,image.get_width()/3,image.get_height()/2))
		tile.resize(128,128,Image.INTERPOLATE_NEAREST)
		rock_material.albedo_texture=ImageTexture.create_from_image(tile)
		rock_material.uv1_triplanar=true
		rock_material.uv1_scale=Vector3.ONE*2.8
		rock_material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		rock_material.roughness = 0.98
		for mesh in rock.find_children("*","MeshInstance3D",true,false):
			mesh.material_override = rock_material
		add_child(rock)
		model_instances += 1

func _build_memory_backing() -> void:
	var path := "res://resources/models/memory-slab.glb"
	var model: Node3D
	if ResourceLoader.exists(path):
		var scene = load(path)
		if scene is PackedScene: model = scene.instantiate()
	elif FileAccess.file_exists(path):
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		if document.append_from_file(path,state) == OK: model = document.generate_scene(state)
	if model == null: return
	var at := Vector2(1550,620)
	for landmark in world.get("landmarks",[]):
		if str(landmark.get("id","")) == "cell": at = Vector2(float(landmark.x),float(landmark.y))
	model.name = "MemorySlabBacking"
	model.position = _point(at + Vector2(4,32),-12)
	model.scale = Vector3(44,52,44)
	model.rotation.y = -0.10
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("3e514b")
	stone.roughness = 0.96
	stone.metallic_specular = 0.12
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		mesh.material_override = stone
	add_child(model)
	backing_instances += 1

func _build_solid_lip(rect: Rect2, index: int, column: int) -> void:
	if rect.size.x < 250 or rect.position.y < 600 or index % 2 != 0:
		return
	# Lip apex stays inside the authoritative solid footprint; no cosmetic cave openings.
	var at := rect.position + Vector2(rect.size.x * 0.62, minf(38,rect.size.y * 0.3))
	var span := minf(60,rect.size.x * 0.12)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tip := _point(at + Vector2(0,minf(24,rect.size.y * 0.2)),FRONT_DEPTH + 12)
	var points := [_point(at + Vector2(-span,0),-8),_point(at + Vector2(span,0),-8),_point(at + Vector2(0,-minf(22,rect.size.y * 0.15)),FRONT_DEPTH - 35)]
	for side in range(3):
		_triangle(tool,points[side],points[(side+1)%3],tip,column,Color(0.85,0.95,0.90))
	var lip := MeshInstance3D.new()
	lip.name = "SolidLip%d" % index
	lip.mesh = tool.commit()
	lip.material_override = _materials[column]
	add_child(lip)

func _build_dock(rect: Rect2) -> void:
	var dock := preload("res://scripts/hybrid/CoastalDockGeometry.gd").new()
	add_child(dock)
	dock.configure(rect,projection_tilt_degrees)

func _build_growth() -> void:
	var path := "res://resources/art/coral-clusters.png"
	if not ResourceLoader.exists(path): return
	var atlas: Texture2D = load(path)
	var cell := Vector2(atlas.get_width()/3.0,634.0)
	for entry in preload("res://scripts/ReefGrowth.gd").placements(world):
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(Vector2(int(entry.kind)*cell.x,0),cell)
		texture.filter_clip = true
		var plant := Sprite3D.new()
		plant.texture = texture
		plant.pixel_size = 1.0
		plant.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		plant.shaded = true
		plant.modulate = Color(0.78,0.83,0.78)
		plant.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		plant.alpha_scissor_threshold = 0.5
		plant.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		plant.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var original_position: Vector3 = _point(entry.at-Vector2(0,entry.size.y/2),36)
		plant.scale = Vector3(entry.size.x/cell.x,entry.size.y/cell.y,1)
		plant.flip_h = bool(entry.flip)
		var pivot:=Node3D.new()
		pivot.name="CoralRoot"
		pivot.position=original_position-Vector3(0,0,entry.size.y*.5)
		plant.position=Vector3(0,0,entry.size.y*.5)
		add_child(pivot)
		pivot.add_child(plant)
		_coral_pivots.append({"node":pivot,"position":entry.at})

func _process(_delta: float) -> void:
	var now:=float(Time.get_ticks_msec())*.001
	var motion=preload("res://scripts/FoliageMotion.gd")
	for coral in _coral_pivots:
		var pivot: Node3D=coral.node
		pivot.rotation.y=0.0 if EnvironmentState.reduced_motion else motion.current_angle(now,coral.position)

func update_camera(center: Vector2) -> void:
	if is_instance_valid(geology): geology.update_camera(center)

func debug_status() -> Dictionary:
	return {"geology":geology.debug_status() if is_instance_valid(geology) else {},"terrainVolumes":terrain_count,"layeredBands":layered_band_count,"modelInstances":model_instances,"memoryBackingInstances":backing_instances,"coralPivots":_coral_pivots.size(),"triangles":triangle_count,"depthRange":volume_depth_range,"bounds":projected_bounds,"units":"world pixels; x,-y,z; front26/backnegative"}
