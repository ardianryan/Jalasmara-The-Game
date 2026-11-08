extends Node3D

const MASK_SIZE := Vector2i(160,112)
var mesh_instance: MeshInstance3D
var material: ShaderMaterial
var elapsed := 0.0
var _map: Dictionary = {}
var _extent := Vector2(2400,1600)
var _wet_cells := 0

func configure(renderer: Node, map: Dictionary) -> void:
	_map = map
	_extent = Vector2(float(map.get("width",2400)),float(map.get("height",1600)))
	material = ShaderMaterial.new()
	material.shader = preload("res://scripts/land/LandWater3D.gdshader")
	material.set_shader_parameter("shoreline",_shoreline_texture())
	material.set_shader_parameter("map_extent",_extent)
	var vertices := PackedVector3Array()
	var uv := PackedVector2Array()
	var normals := PackedVector3Array()
	for row in range(24):
		for column in range(32):
			var corners := [Vector2(column,row),Vector2(column+1,row),Vector2(column+1,row+1),Vector2(column,row+1)]
			for index in [0,2,1,0,3,2]:
				var fraction: Vector2 = corners[index]/Vector2(32,24)
				vertices.append(renderer.map_point(fraction*_extent,-14.0))
				uv.append(fraction)
				normals.append(Vector3(0,0,1))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_NORMAL] = normals
	var geometry := ArrayMesh.new()
	geometry.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = geometry
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)

func _shoreline_texture() -> ImageTexture:
	var land: Array[PackedVector2Array] = []
	for surface in _map.get("surfaces",[]):
		if not bool(surface.get("walkable",true)) or str(surface.get("material","")) in ["dock","bridge","wood"]: continue
		var points := PackedVector2Array()
		for point in surface.get("polygon",[]): points.append(Vector2(float(point[0]),float(point[1])))
		land.append(points)
	var backing := PackedVector2Array()
	for point in _map.get("landmass",[]): backing.append(Vector2(float(point[0]),float(point[1])))
	if backing.size()>2: land.append(backing)
	var distance := PackedFloat32Array()
	distance.resize(MASK_SIZE.x*MASK_SIZE.y)
	for y in range(MASK_SIZE.y):
		for x in range(MASK_SIZE.x):
			var p := (Vector2(x,y)+Vector2(0.5,0.5))/Vector2(MASK_SIZE)*_extent
			var on_land := false
			for polygon in land:
				if Geometry2D.is_point_in_polygon(p,polygon):
					on_land = true
					break
			distance[y*MASK_SIZE.x+x] = 0.0 if on_land else 999.0
			if not on_land: _wet_cells += 1
	for y in range(MASK_SIZE.y):
		for x in range(MASK_SIZE.x):
			var at := y*MASK_SIZE.x+x
			if x>0: distance[at] = minf(distance[at],distance[at-1]+1)
			if y>0: distance[at] = minf(distance[at],distance[at-MASK_SIZE.x]+1)
			if x>0 and y>0: distance[at] = minf(distance[at],distance[at-MASK_SIZE.x-1]+1.4142)
	for y in range(MASK_SIZE.y-1,-1,-1):
		for x in range(MASK_SIZE.x-1,-1,-1):
			var at := y*MASK_SIZE.x+x
			if x<MASK_SIZE.x-1: distance[at] = minf(distance[at],distance[at+1]+1)
			if y<MASK_SIZE.y-1: distance[at] = minf(distance[at],distance[at+MASK_SIZE.x]+1)
			if x<MASK_SIZE.x-1 and y<MASK_SIZE.y-1: distance[at] = minf(distance[at],distance[at+MASK_SIZE.x+1]+1.4142)
	var raster := Image.create(MASK_SIZE.x,MASK_SIZE.y,false,Image.FORMAT_RGBA8)
	for y in range(MASK_SIZE.y):
		for x in range(MASK_SIZE.x):
			var d := distance[y*MASK_SIZE.x+x]
			raster.set_pixel(x,y,Color(1.0 if d==0 else 0.0,clampf(d*_extent.x/MASK_SIZE.x/90.0,0,1),0,1))
	return ImageTexture.create_from_image(raster)

func _process(delta: float) -> void:
	if material==null: return
	elapsed += delta
	var weather: Dictionary = EnvironmentState.snapshot()
	material.set_shader_parameter("clock",elapsed)
	material.set_shader_parameter("rain",float(weather.get("rain",0)))
	material.set_shader_parameter("wind",minf(1.0,absf(float(weather.get("wind_x",0)))/30.0))
	material.set_shader_parameter("motion",0.2 if bool(weather.get("reduced_motion",false)) else 1.0)

func debug_status() -> Dictionary:
	return {"mesh":is_instance_valid(mesh_instance),"elapsed":elapsed,"shoreMask":[MASK_SIZE.x,MASK_SIZE.y],"waterCells":_wet_cells,"vertexWaves":true,"shoreFoam":true,"rainRings":true,"walkable":false}
