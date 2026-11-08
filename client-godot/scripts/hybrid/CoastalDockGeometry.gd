extends Node3D

const WOOD_SHADER = preload("res://scripts/hybrid/dock-wood.gdshader")
var extent := Rect2()
var tilt := deg_to_rad(12.0)
var mesh_count := 0
var _wood: ShaderMaterial
var _dark: ShaderMaterial

static func wood_texture() -> Texture2D:
	var atlas: Texture2D = load("res://resources/art/ocean-props-atlas.png")
	var tile := AtlasTexture.new()
	tile.atlas = atlas
	# An opaque patch of the original supply crate's wooden front, not a borrowed texture.
	tile.region = Rect2(1500,760,40,50)
	tile.filter_clip = true
	return tile

func configure(rect: Rect2, tilt_degrees: float = 12.0) -> void:
	extent = rect
	tilt = deg_to_rad(tilt_degrees)
	for child in get_children(): child.queue_free()
	mesh_count = 0
	_wood = _wood_material(Color(1.15,1.12,0.93))
	_dark = _wood_material(Color(0.64,0.75,0.72))
	# The visible solid deck stays within the same projected footprint as the server's rectangle.
	_volume(rect,26,-230,_dark,"DockCore")
	var count := ceili(rect.size.x/74.0)
	for index in range(count):
		var width := rect.size.x/count
		var plank := Rect2(rect.position+Vector2(index*width+0.8,1.0),Vector2(width-1.6,rect.size.y-2.0))
		_volume(plank,29+float(index%3)*0.8,10,_wood,"Plank%d" % index)
	_volume(Rect2(rect.position,Vector2(rect.size.x,7)),36,-245,_wood,"UpperFascia")
	_volume(Rect2(Vector2(rect.position.x,rect.end.y-9),Vector2(rect.size.x,9)),34,-245,_dark,"WaterlineFascia")
	# End grain makes this a constructed quay end rather than an abruptly cropped strip.
	_volume(Rect2(Vector2(rect.end.x-24,rect.position.y),Vector2(24,rect.size.y)),39,-250,_dark,"QuayEndCap")
	var rope := StandardMaterial3D.new()
	rope.albedo_color = Color("b6a17a")
	rope.roughness = 1.0
	for index in range(ceili(rect.size.x/430.0)):
		var x := clampf(rect.position.x+100+index*430,rect.position.x+15,rect.end.x-15)
		var top := _point(Vector2(x,rect.position.y+8),44)
		var bottom := _point(Vector2(x,rect.end.y-5),44)
		_bar(top,bottom,7.0,_wood,"MooringPost")
		for y in [rect.position.y+20,rect.position.y+25]:
			_bar(_point(Vector2(x-8,y),51),_point(Vector2(x+8,y),51),1.6,rope,"RopeLashing")
	# Cross-braces are behind the solid dock, never a new wall across the swimming lane.
	for x in [rect.position.x+180,rect.end.x-230]:
		_bar(_point(Vector2(x,rect.position.y+5),-80),_point(Vector2(x+85,rect.end.y-5),-185),5,_dark,"RearBrace")
	_build_ladder(1120.0,rect.end.y-8)

func _point(at: Vector2, depth: float) -> Vector3:
	return Vector3(at.x,-at.y+sin(tilt)*depth,depth)

func _wood_material(tint: Color) -> ShaderMaterial:
	var tile := wood_texture() as AtlasTexture
	var material := ShaderMaterial.new()
	material.shader = WOOD_SHADER
	material.set_shader_parameter("wood_atlas",tile.atlas)
	material.set_shader_parameter("wood_patch",Vector4(tile.region.position.x/tile.atlas.get_width(),tile.region.position.y/tile.atlas.get_height(),tile.region.size.x/tile.atlas.get_width(),tile.region.size.y/tile.atlas.get_height()))
	material.set_shader_parameter("wood_tint",tint)
	return material

func _volume(rect: Rect2, front: float, back: float, material: Material, label: String) -> void:
	var points := [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for depth in [front,back]:
		_quad(tool,_point(points[0],depth),_point(points[1],depth),_point(points[2],depth),_point(points[3],depth))
	for index in range(4):
		var next := (index+1)%4
		_quad(tool,_point(points[index],front),_point(points[next],front),_point(points[next],back),_point(points[index],back))
	tool.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = label+"_"+str(mesh_count)
	mesh.mesh = tool.commit()
	mesh.material_override = material
	add_child(mesh)
	mesh_count += 1

func _quad(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
	if (b-a).cross(c-a).z < 0:
		var previous := b
		b = d
		d = previous
	for item in [[a,Vector2(0,0)],[b,Vector2(1,0)],[c,Vector2(1,1)],[a,Vector2(0,0)],[c,Vector2(1,1)],[d,Vector2(0,1)]]:
		tool.set_uv(item[1])
		tool.add_vertex(item[0])

func _bar(a: Vector3,b: Vector3,radius: float,material: Material,label: String) -> void:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = a.distance_to(b)
	shape.radial_segments = 8
	var mesh := MeshInstance3D.new()
	mesh.name = label+"_"+str(mesh_count)
	mesh.mesh = shape
	mesh.material_override = material
	mesh.position = (a+b)/2.0
	mesh.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	add_child(mesh)
	mesh_count += 1

func _build_ladder(x: float, top: float) -> void:
	var rail := StandardMaterial3D.new()
	rail.albedo_color = Color("9c9275")
	rail.roughness = 0.95
	for side in [-1,1]:
		_bar(_point(Vector2(x+side*24,top),39),_point(Vector2(x+side*24,475),39),2.8,rail,"LadderRail")
	for y in range(int(top)+10,475,15):
		_bar(_point(Vector2(x-24,y),40),_point(Vector2(x+24,y),40),2.3,_wood,"LadderRung")

func debug_status() -> Dictionary:
	return {"meshes":mesh_count,"footprint":[extent.position.x,extent.position.y,extent.size.x,extent.size.y],"ladder":[1120,475],"newColliders":0}
