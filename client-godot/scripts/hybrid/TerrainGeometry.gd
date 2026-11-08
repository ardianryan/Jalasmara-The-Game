extends Node3D

@export var projection_tilt_degrees := 12.0
const FRONT_DEPTH := 26.0
var world: Dictionary = {}
var terrain_count := 0
var triangle_count := 0
var volume_depth_range := Vector2(220, 440)
var projected_bounds: Array[Rect2] = []
var _uv_rect := Rect2(0,0,512,512)
var model_instances := 0
var _atlas: Texture2D
var _materials: Array[Material] = []

func configure(data: Dictionary) -> void:
	world = data
	for child in get_children():
		remove_child(child)
		child.queue_free()
	terrain_count = 0
	triangle_count = 0
	model_instances = 0
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
	_build_cave_backwall()
	_build_model_rocks()

func _point(at: Vector2, depth: float) -> Vector3:
	return Vector3(at.x, -at.y + sin(deg_to_rad(projection_tilt_degrees)) * depth, depth)

func _uv(at: Vector2, _column: int) -> Vector2:
	return at / 512.0

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
	var depth := lerpf(260.0,440.0,(sin(index * 2.137) + 1.0) * 0.5)
	var front := PackedVector2Array()
	for point in outline:
		var inset_point := point.lerp(rect.get_center(),0.12)
		front.append(inset_point if Geometry2D.is_point_in_polygon(inset_point,outline) else point.lerp(rect.get_center(),0.025))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var triangles := Geometry2D.triangulate_polygon(front)
	for offset in range(0,triangles.size(),3):
		var a := front[triangles[offset]]
		var b := front[triangles[offset+1]]
		var c := front[triangles[offset+2]]
		var center := (a+b+c)/3.0
		var peak := FRONT_DEPTH + 25.0 + 24.0 * sin(offset * 1.71 + index * 2.13)
		var raised := _point(center,peak)
		var tint := Color(1.12,1.13,1.02) if center.y < rect.get_center().y else Color(0.95,1.05,1.02)
		_triangle(tool,_point(a,FRONT_DEPTH),_point(b,FRONT_DEPTH),raised,column,tint)
		_triangle(tool,_point(b,FRONT_DEPTH),_point(c,FRONT_DEPTH),raised,column,tint)
		_triangle(tool,_point(c,FRONT_DEPTH),_point(a,FRONT_DEPTH),raised,column,tint)
	for segment in range(outline.size()):
		var next := (segment + 1) % outline.size()
		var mid_a := _point(outline[segment].lerp(front[segment],0.35),-35)
		var mid_b := _point(outline[next].lerp(front[next],0.35),-35)
		var back_a := _point(outline[segment],-depth)
		var back_b := _point(outline[next],-depth)
		var front_a := _point(front[segment],FRONT_DEPTH)
		var front_b := _point(front[next],FRONT_DEPTH)
		var upper := outline[segment].y < rect.get_center().y
		var edge_tint := Color(1.17,1.17,1.02) if upper else Color(0.68,0.92,0.92)
		_triangle(tool,mid_a,mid_b,front_b,column,edge_tint)
		_triangle(tool,mid_a,front_b,front_a,column,edge_tint)
		_triangle(tool,back_a,back_b,mid_b,column,Color(0.60,0.83,0.86))
		_triangle(tool,back_a,mid_b,mid_a,column,Color(0.60,0.83,0.86))
	var back_triangles := Geometry2D.triangulate_polygon(outline)
	for offset in range(0,back_triangles.size(),3):
		_triangle(tool,_point(outline[back_triangles[offset]],-depth),_point(outline[back_triangles[offset+1]],-depth),_point(outline[back_triangles[offset+2]],-depth),column,Color(0.50,0.67,0.73))
	var instance := MeshInstance3D.new()
	instance.name = "ReefRelief%d" % index
	instance.mesh = tool.commit()
	instance.material_override = _materials[column]
	add_child(instance)

func _build_cave_backwall() -> void:
	var rect := Rect2(410,600,760,610)
	_uv_rect = rect
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [Vector2(410,600),Vector2(1160,650),Vector2(1090,1180),Vector2(430,1210)]
	var center := _point(Vector2(770,900),-670)
	for index in range(4):
		_triangle(tool,_point(corners[index],-580),_point(corners[(index+1)%4],-620),center,1,Color(0.45,0.65,0.69))
	var wall := MeshInstance3D.new()
	wall.name = "CaveRearRockWall"
	wall.mesh = tool.commit()
	wall.material_override = _materials[1]
	add_child(wall)

func _build_model_rocks() -> void:
	var path := "res://resources/models/reef-rock.glb"
	if not ResourceLoader.exists(path): return
	var source = load(path)
	if not source is PackedScene: return
	for at in [Vector2(620,1130),Vector2(1530,1140),Vector2(3210,990)]:
		var rock: Node3D = source.instantiate()
		rock.position = _point(at,115)
		rock.scale = Vector3.ONE * 95.0
		rock.rotation = Vector3(0.12,0.5 + model_instances * 1.6,0.18)
		var rock_material := StandardMaterial3D.new()
		rock_material.albedo_color = Color("475951")
		rock_material.roughness = 0.98
		for mesh in rock.find_children("*","MeshInstance3D",true,false):
			mesh.material_override = rock_material
		add_child(rock)
		model_instances += 1

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
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("76634b")
	wood.roughness = 0.95
	var dock := SurfaceTool.new()
	dock.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
	for side in range(4):
		var next := (side + 1) % 4
		var a := _point(corners[side],FRONT_DEPTH)
		var b := _point(corners[next],FRONT_DEPTH)
		var c := _point(corners[next],-170)
		var d := _point(corners[side],-170)
		_triangle(dock,a,b,c,0,Color.WHITE)
		_triangle(dock,a,c,d,0,Color.WHITE)
	for depth in [FRONT_DEPTH,-170.0]:
		_triangle(dock,_point(corners[0],depth),_point(corners[1],depth),_point(corners[2],depth),0,Color.WHITE)
		_triangle(dock,_point(corners[0],depth),_point(corners[2],depth),_point(corners[3],depth),0,Color.WHITE)
	var body := MeshInstance3D.new()
	body.name = "DockSolidVolume"
	body.mesh = dock.commit()
	body.material_override = wood
	add_child(body)
	var planks := SurfaceTool.new()
	planks.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := ceili(rect.size.x / 85.0)
	for index in range(count):
		var x := rect.position.x + index * rect.size.x / count
		var right := x + rect.size.x / count - 2.0
		var a := _point(Vector2(x,rect.position.y),FRONT_DEPTH + 2)
		var b := _point(Vector2(right,rect.position.y),FRONT_DEPTH + 2)
		var c := _point(Vector2(right,rect.end.y),FRONT_DEPTH + 2)
		var d := _point(Vector2(x,rect.end.y),FRONT_DEPTH + 2)
		_triangle(planks,a,b,c,0,Color.WHITE)
		_triangle(planks,a,c,d,0,Color.WHITE)
	var plank_mesh := MeshInstance3D.new()
	plank_mesh.name = "DockPlankFaces"
	plank_mesh.mesh = planks.commit()
	var plank_material := StandardMaterial3D.new()
	plank_material.albedo_color = Color("a68a61")
	plank_material.roughness = 0.9
	plank_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	plank_mesh.material_override = plank_material
	add_child(plank_mesh)

func debug_status() -> Dictionary:
	return {"terrainVolumes":terrain_count,"modelInstances":model_instances,"triangles":triangle_count,"depthRange":volume_depth_range,"bounds":projected_bounds,"units":"world pixels; x,-y,z; front26/backnegative"}
