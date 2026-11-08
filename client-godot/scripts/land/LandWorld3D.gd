extends Node2D

const TILT := deg_to_rad(55.0)
const DISTANCE := 3300.0
const LEVEL_HEIGHT := 48.0
const Materials = preload("res://scripts/land/LandMaterials.gd")
var source: Node2D
var actor: Node2D
var source_camera: Camera2D
var area := "hub"
var active := false
var world_root: Node3D
var viewport_3d: SubViewport
var camera_3d: Camera3D
var screen_layer: CanvasLayer
var display: TextureRect
var water_mesh: MeshInstance3D
var water_material: ShaderMaterial
var water_node: Node3D
var environment: Environment
var sunlight: DirectionalLight3D
var actors_3d: Node3D
var map: Dictionary = {}
var _materials = Materials.new()
var _geometry: Node3D
var _models := 0
var _trees := 0
var _houses := 0
var _stair_treads := 0
var _meshes := 0
var _weather_clock := 0.0
var _built := false
var _center := Vector2.ZERO
var _leaves: Array[Dictionary] = []
var _lanterns: Array[OmniLight3D] = []
var _glow_material: StandardMaterial3D
var _components: Dictionary={}
var _bridges: Dictionary={}

func setup(scene: Node2D, player: Node2D, camera: Camera2D, place: String) -> void:
	source=scene
	actor=player
	source_camera=camera
	area=place
	if is_instance_valid(viewport_3d): return
	screen_layer=CanvasLayer.new()
	screen_layer.layer=-1
	add_child(screen_layer)
	display=TextureRect.new()
	display.mouse_filter=Control.MOUSE_FILTER_IGNORE
	display.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var presentation:=CanvasItemMaterial.new()
	presentation.light_mode=CanvasItemMaterial.LIGHT_MODE_UNSHADED
	display.material=presentation
	screen_layer.add_child(display)
	viewport_3d=SubViewport.new()
	viewport_3d.size=Vector2i(480,270)
	viewport_3d.own_world_3d=true
	viewport_3d.transparent_bg=false
	viewport_3d.msaa_3d=Viewport.MSAA_DISABLED
	viewport_3d.positional_shadow_atlas_size=1024
	viewport_3d.render_target_update_mode=SubViewport.UPDATE_DISABLED
	add_child(viewport_3d)
	display.texture=viewport_3d.get_texture()
	world_root=Node3D.new()
	world_root.name="LandGeometry"
	viewport_3d.add_child(world_root)
	var atmosphere:=WorldEnvironment.new()
	environment=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("447d7a")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("c9d0b7")
	environment.ambient_light_energy=.75
	environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	atmosphere.environment=environment
	viewport_3d.add_child(atmosphere)
	camera_3d=Camera3D.new()
	camera_3d.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera_3d.keep_aspect=Camera3D.KEEP_HEIGHT
	camera_3d.near=5
	camera_3d.far=9000
	camera_3d.current=true
	viewport_3d.add_child(camera_3d)
	sunlight=DirectionalLight3D.new()
	sunlight.rotation_degrees=Vector3(-18,-12,-10)
	sunlight.directional_shadow_blend_splits=true
	sunlight.shadow_blur=1.8
	sunlight.shadow_opacity=.64
	sunlight.light_color=Color("fff0ce")
	sunlight.light_energy=1.15
	sunlight.shadow_enabled=true
	sunlight.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	sunlight.directional_shadow_max_distance=3800
	sunlight.shadow_bias=.035
	viewport_3d.add_child(sunlight)
	set_area(place)

func set_area(place: String) -> void:
	area=place
	map=GameState.world.get("landMaps",{}).get(area,{})
	if map.is_empty() or not is_instance_valid(world_root): return
	if is_instance_valid(_geometry):
		world_root.remove_child(_geometry)
		_geometry.queue_free()
	_geometry=Node3D.new()
	_geometry.name="Modular_"+area
	world_root.add_child(_geometry)
	_models=0
	_trees=0
	_houses=0
	_stair_treads=0
	_meshes=0
	_components.clear()
	_bridges.clear()
	_leaves.clear()
	_lanterns.clear()
	if ResourceLoader.exists("res://scripts/land/LandWater3D.gd"):
		if is_instance_valid(water_node): water_node.queue_free()
		water_node=load("res://scripts/land/LandWater3D.gd").new()
		_geometry.add_child(water_node)
		water_node.configure(self,map)
	else:
		_build_water()
	_build_landmass()
	var ordered: Array=map.get("surfaces",[]).duplicate()
	ordered.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return int(a.get("priority",0))<int(b.get("priority",0)))
	for surface in ordered:
		if surface.has("connectorId"): continue
		_build_surface(surface)
	for stair in map.get("stairs",[]): _build_stair(stair)
	for obstacle in map.get("obstacles",[]): _build_obstacle(obstacle)
	_build_corridor_landmarks()
	_build_ground_details()
	_build_wet_banks()
	_batch_static_geometry()
	if is_instance_valid(actors_3d): actors_3d.queue_free()
	actors_3d=preload("res://scripts/land/LandActors3D.gd").new()
	world_root.add_child(actors_3d)
	actors_3d.configure(self,source,actor)
	_built=true

func camera_up() -> Vector3:
	return Vector3(0,cos(TILT),sin(TILT))

func camera_forward() -> Vector3:
	return Vector3(0,sin(TILT),-cos(TILT))

func map_point(point: Vector2, height := 0.0) -> Vector3:
	return Vector3(point.x,-point.y/cos(TILT)-height*tan(TILT),height)

func ground_projection(point: Vector3) -> Vector2:
	return Vector2(point.x,-point.y*cos(TILT)-point.z*sin(TILT))

func ground_height(point: Vector2) -> float:
	var elevation:=0.0
	var priority:=-10000
	for surface in map.get("surfaces",[]):
		var poly:=_polygon(surface.get("polygon",[]))
		if Geometry2D.is_point_in_polygon(point,poly) and int(surface.get("priority",0))>=priority:
			priority=int(surface.get("priority",0))
			elevation=float(surface.get("elevation",0))*LEVEL_HEIGHT
	for stair in map.get("stairs",[]):
		var path: Array=stair.get("path",[])
		if path.size()<2: continue
		var start:=_v2(path[0])
		var end:=_v2(path[1])
		var t: float=(point-start).dot(end-start)/maxf(1,(end-start).length_squared())
		if t<0 or t>1: continue
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point,start,end))<=float(stair.width)*.5:
			elevation=lerpf(_level(str(stair.from)),_level(str(stair.to)),t)
	return elevation

func _level(id: String) -> float:
	for terrace in map.get("terraces",[]):
		if str(terrace.id)==id: return float(terrace.elevation)*LEVEL_HEIGHT
	return 0

func _v2(value: Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

func _polygon(points: Array) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for point in points: result.append(_v2(point))
	return result

func _mesh(label: String, vertices: PackedVector3Array, triangles: PackedInt32Array, material: Material, parent: Node3D=null) -> MeshInstance3D:
	_components[label]=int(_components.get(label,0))+1
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(0,triangles.size(),3):
		var a:=vertices[triangles[index]]
		var b:=vertices[triangles[index+1]]
		var c:=vertices[triangles[index+2]]
		var normal: Vector3=-(b-a).cross(c-a).normalized()
		for point in [a,b,c]:
			tool.set_normal(normal)
			tool.set_uv(Vector2(point.x,point.y)/128.0)
			tool.add_vertex(point)
	var mesh:=MeshInstance3D.new()
	mesh.name=label.validate_node_name()
	tool.index()
	mesh.mesh=tool.commit()
	mesh.material_override=material
	(parent if parent!=null else _geometry).add_child(mesh)
	_meshes+=1
	return mesh

func _face(label: String, points: Array[Vector3], material: Material) -> MeshInstance3D:
	return _mesh(label,PackedVector3Array(points),PackedInt32Array([0,1,2,0,2,3]),material)

func _box(label: String, center: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	_components[label]=int(_components.get(label,0))+1
	var box:=BoxMesh.new()
	box.size=dimensions
	var instance:=MeshInstance3D.new()
	instance.name=label.validate_node_name()
	instance.mesh=box
	instance.position=center
	instance.material_override=material
	_geometry.add_child(instance)
	_meshes+=1
	return instance

func _build_water() -> void:
	if is_instance_valid(water_mesh): water_mesh.queue_free()
	var width:=float(map.get("width",2400))
	var height:=float(map.get("height",1600))
	var shader:=Shader.new()
	shader.code="""
shader_type spatial;
render_mode unshaded, cull_disabled;
void fragment(){float wave=sin(UV.x*210.0+TIME)*sin(UV.y*170.0-TIME*.7);ALBEDO=mix(vec3(.10,.31,.32),vec3(.19,.45,.44),.5+wave*.12);}
"""
	water_material=ShaderMaterial.new()
	water_material.shader=shader
	water_mesh=_face("Water",[map_point(Vector2(-800,-800),-18),map_point(Vector2(width+800,-800),-18),map_point(Vector2(width+800,height+800),-18),map_point(Vector2(-800,height+800),-18)],water_material)

func _build_landmass() -> void:
	var points: Array=map.get("landmass",[])
	if points.size()>=3:
		var surface:={"id":"OrganicCoastalBacking","polygon":points,"material":"grass","elevation":0,"heightPixels":-8.0,"priority":0}
		_build_surface_geometry(surface)
		if area=="hub":
			_build_surface_geometry({"id":"HubGatewayBackingPatch","polygon":[[2160,15],[2390,20],[2385,95],[2160,95]],"material":"grass","elevation":3,"heightPixels":3.0*LEVEL_HEIGHT-2.0,"priority":1})
			_build_surface_geometry({"id":"HubGatewayBackingTrail","polygon":[[2238,18],[2324,18],[2324,88],[2238,88]],"material":"dirt","elevation":3,"heightPixels":3.0*LEVEL_HEIGHT+0.15,"priority":8})
		return
	if area=="forest":
		_build_surface_geometry({
			"id":"WestForestBacking",
			"polygon":[[-420,-260],[1295,-260],[1320,120],[1300,800],[1315,1480],[1240,1820],[-420,1820]],
			"material":"grass",
			"elevation":0,
			"heightPixels":-0.05,
			"priority":0,
		})
		_build_surface_geometry({
			"id":"EastForestBacking",
			"polygon":[[1585,120],[1615,-260],[2820,-260],[2820,1820],[1610,1820],[1565,1430],[1580,800]],
			"material":"grass",
			"elevation":0,
			"heightPixels":-0.05,
			"priority":0,
		})
		_build_surface_geometry({
			"id":"ForestEntryBackingTrail",
			"polygon":[[-45,1405],[110,1330],[150,1408],[-5,1485]],
			"material":"dirt",
			"elevation":0,
			"heightPixels":0.15,
			"priority":8,
		})

func _build_surface(surface: Dictionary) -> void:
	if bool(surface.get("walkable",true)):
		_build_surface_geometry(surface)
		return
	var decoration:=_polygon(surface.get("polygon",[]))
	for floor_surface in map.get("surfaces",[]):
		if not bool(floor_surface.get("walkable",true)): continue
		if str(floor_surface.get("material","")) in ["bridge","dock","wood"]: continue
		var floor_polygon:=_polygon(floor_surface.get("polygon",[]))
		for intersection in Geometry2D.intersect_polygons(decoration,floor_polygon):
			var clipped:=surface.duplicate()
			var points:Array=[]
			for point in intersection: points.append([point.x,point.y])
			clipped["polygon"]=points
			clipped["elevation"]=floor_surface.get("elevation",0)
			_build_surface_geometry(clipped)

func _build_surface_geometry(surface: Dictionary) -> void:
	if str(surface.get("material",""))=="bridge":
		_build_bridge(surface)
		return
	var polygon:=_polygon(surface.polygon)
	if polygon.size()<3: return
	if not bool(surface.get("walkable",true)) and str(surface.get("material",""))=="grass":
		polygon=_ragged_patch(polygon)
	var height:=float(surface.get("heightPixels",float(surface.get("elevation",0))*LEVEL_HEIGHT))+float(surface.get("priority",0))*.018
	var vertices:=PackedVector3Array()
	for point in polygon: vertices.append(map_point(point,height))
	var indices:=Geometry2D.triangulate_polygon(polygon)
	for i in range(0,indices.size(),3):
		if (vertices[indices[i+1]]-vertices[indices[i]]).cross(vertices[indices[i+2]]-vertices[indices[i]]).z<0:
			var swap:=indices[i+1]
			indices[i+1]=indices[i+2]
			indices[i+2]=swap
	_mesh(str(surface.id),vertices,indices,_materials.get_material(str(surface.material)))
	if int(surface.get("priority",0))>0: return
	var edge_material: Material=_materials.get_material("wood" if str(surface.material) in ["dock","wood","bridge"] else "stone")
	var surface_id:=str(surface.id)
	var is_forest_bank:=surface_id in ["forest_west_land","forest_east_land"]
	var is_forest_backing:=surface_id in ["WestForestBacking","EastForestBacking"]
	if is_forest_backing: return
	for i in range(polygon.size()):
		var first:=polygon[i]
		var second:=polygon[(i+1)%polygon.size()]
		if is_forest_bank:
			var edge_mid:=(first+second)*.5
			if edge_mid.x<1250.0 or edge_mid.x>1650.0 or (first.y<=125.0 and second.y<=125.0) or (first.y>=1425.0 and second.y>=1425.0):
				continue
		var parts:=maxi(1,ceili(first.distance_to(second)/32.0))
		for part in range(parts):
			var a:=first.lerp(second,float(part)/parts)
			var b:=first.lerp(second,float(part+1)/parts)
			if _connector_at((a+b)*.5): continue
			var top_a:=map_point(a,height)
			var top_b:=map_point(b,height)
			var thickness:=32.0 if height<1 else 44.0
			_face("TerraceFace",[top_a,top_b,top_b-Vector3(0,0,thickness),top_a-Vector3(0,0,thickness)],edge_material)
	if str(surface.material)=="bridge":
		for i in range(polygon.size()):
			var first:=polygon[i]
			var second:=polygon[(i+1)%polygon.size()]
			if first.distance_to(second)<200: continue
			var count:=maxi(2,ceili(first.distance_to(second)/85))
			var a:=map_point(first,height)
			var b:=map_point(second,height)
			for j in range(count+1):
				var at:=a.lerp(b,float(j)/count)
				_column(at,at+Vector3(0,0,44),4,_materials.get_material("wood"))
			_column(a+Vector3(0,0,34),b+Vector3(0,0,34),2,_materials.get_material("bamboo"))
	if str(surface.material)=="dock":
		for point in polygon:
			var at:=map_point(point,height)
			_column(at-Vector3(0,0,60),at+Vector3(0,0,10),9,_materials.get_material("wood"))

func _connector_at(point: Vector2) -> bool:
	for stair in map.get("stairs",[]):
		var path: Array=stair.path
		var a:=_v2(path[0])
		var b:=_v2(path[1])
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b))<float(stair.width)*.5+8: return true
	return false

func _build_stair(stair: Dictionary) -> void:
	var path: Array=stair.path
	var a:=_v2(path[0])
	var b:=_v2(path[1])
	var tangent: Vector2=(b-a).normalized()
	var side:=Vector2(-tangent.y,tangent.x)*float(stair.width)*.5
	var lower:=_level(str(stair.from))
	var upper:=_level(str(stair.to))
	var count:=int(stair.steps) if str(stair.type)=="stairs" else 1
	var material: Material=_materials.get_material(str(stair.get("material","stone")))
	for i in range(count):
		var start:=a.lerp(b,float(i)/count)
		var end:=a.lerp(b,float(i+1)/count)
		var top:=lerpf(lower,upper,float(i+1)/count)
		var previous:=lerpf(lower,upper,float(i)/count)
		var h0:=previous if str(stair.type)=="ramp" else top
		_face("Tread",[map_point(start-side,h0),map_point(start+side,h0),map_point(end+side,top),map_point(end-side,top)],material)
		if str(stair.type)=="stairs":
			var left:=map_point(start-side,top)
			var right:=map_point(start+side,top)
			_face("Riser",[left,right,right-Vector3(0,0,top-previous),left-Vector3(0,0,top-previous)],material)
		_stair_treads+=1

func _build_obstacle(entry: Dictionary) -> void:
	var rect:=Rect2(float(entry.x),float(entry.y),float(entry.width),float(entry.height))
	var height:=float(entry.get("elevation",0))*LEVEL_HEIGHT
	var center:=map_point(rect.get_center(),height)
	match str(entry.kind):
		"house": _house(entry,rect,center)
		"tree": _tree(entry,rect,center)
		"rock","cliff": _rock(entry,rect,center)
		"garden": _garden(entry,rect,center)
		"fence": _fence(entry,rect,center)
		_: _crate(entry,rect,center)

func _house(entry: Dictionary, rect: Rect2, center: Vector3) -> void:
	var footprint:=_polygon(entry.get("footprint",[]))
	if footprint.size()!=4:
		_house_parts(entry,rect,center)
		return
	var height:=float(entry.get("elevation",0))*LEVEL_HEIGHT
	var back_left:=map_point(footprint[0],height)
	var back_right:=map_point(footprint[1],height)
	var front_left:=map_point(footprint[3],height)
	var along:=back_right-back_left
	var back:=back_left-front_left
	var building:=Node3D.new()
	building.name=str(entry.id).validate_node_name()
	building.transform=Transform3D(Basis(along.normalized(),back.normalized(),Vector3(0,0,1)),center)
	_geometry.add_child(building)
	var previous:=_geometry
	_geometry=building
	_house_parts(entry,Rect2(0,0,along.length(),back.length()*cos(TILT)),Vector3.ZERO)
	_geometry=previous

func _house_parts(entry: Dictionary, rect: Rect2, center: Vector3) -> void:
	_houses+=1
	var width:=rect.size.x
	var depth:=rect.size.y/cos(TILT)
	var height:=float(entry.get("height3d",145))
	var wall:=height*.70
	var floor_height:=12.0
	var wood: Material=_materials.get_material("wood")
	var bamboo: Material=_materials.get_material("bamboo")
	var roof: Material=_materials.get_material("metal" if str(entry.get("variant","")) in ["metal","workshop"] else "thatch")
	_box("RaisedWoodFloor",center+Vector3(0,0,8),Vector3(width,depth,16),wood)
	_box("BackWovenWall",center+Vector3(0,depth*.5-5,wall*.5+floor_height),Vector3(width,10,wall),bamboo)
	for side in [-1.0,1.0]:
		_box("SideWovenWall",center+Vector3(side*(width*.5-5),0,wall*.5+floor_height),Vector3(10,depth,wall),bamboo)
		_box("PorchPost",center+Vector3(side*(width*.5-16),-depth*.5+12,wall*.5+floor_height),Vector3(12,12,wall),wood)
		_box("InteriorPost",center+Vector3(side*width*.20,-depth*.5+12,wall*.5+floor_height),Vector3(9,9,wall),wood)
	_box("FrontCrossbeam",center+Vector3(0,-depth*.5+12,wall+floor_height-5),Vector3(width,12,10),wood)
	_box("FrontCounter",center+Vector3(0,-depth*.20,35),Vector3(width*.58,22,45),wood)
	for index in range(4):
		var x: float=-width*.34+index*width*.23
		_box("WovenPanel",center+Vector3(x,depth*.5-12,wall*.55),Vector3(width*.17,5,wall*.5),bamboo)
	var eave:=center+Vector3(0,0,wall+floor_height)
	var corners: Array[Vector3]=[eave+Vector3(-width*.55,-depth*.57,0),eave+Vector3(width*.55,-depth*.57,0),eave+Vector3(width*.55,depth*.57,0),eave+Vector3(-width*.55,depth*.57,0)]
	var peak_left:=eave+Vector3(-width*.27,0,height*.43)
	var peak_right:=eave+Vector3(width*.27,0,height*.43)
	_mesh("LimasRoof",PackedVector3Array([corners[0],corners[1],corners[2],corners[3],peak_left,peak_right]),PackedInt32Array([0,1,5,0,5,4,1,2,5,2,3,4,2,4,5,3,0,4]),roof)
	for i in range(8):
		var x: float=-width*.49+i*width*.14
		_column(eave+Vector3(x,-depth*.58,-4),eave+Vector3(x,depth*.58,-4),2.0,wood)
	_column(peak_left+Vector3(0,0,2),peak_right+Vector3(0,0,2),4,wood)
	_lantern(center+Vector3(-width*.35,-depth*.5+12,wall*.68))
	for side in [-1.0,1.0]:
		var window_at:=center+Vector3(side*width*.30,depth*.5-12,wall*.52)
		_box("WindowFrame",window_at,Vector3(width*.14,9,wall*.43),wood)
		_box("WarmWindow",window_at-Vector3(0,6,0),Vector3(width*.12,2,wall*.34),_glow_material)
		_box("WindowMullion",window_at-Vector3(0,8,0),Vector3(3,3,wall*.36),wood)

	var front_y: float=-depth*.5+13
	for side in [-1.0,1.0]:
		var window_at:=center+Vector3(side*width*.31,front_y,wall*.45+floor_height)
		_box("PorchWovenPanel",window_at,Vector3(width*.25,8,wall*.72),bamboo)
		_box("FrontWindowFrame",window_at-Vector3(0,6,0),Vector3(width*.16,8,wall*.43),wood)
		_box("FrontAmberWindow",window_at-Vector3(0,11,0),Vector3(width*.135,2,wall*.32),_glow_material)
		_box("FrontWindowCross",window_at-Vector3(0,13,0),Vector3(3,2,wall*.34),wood)
		var pot:=center+Vector3(side*width*.43,-depth*.46,14)
		_column(pot,pot+Vector3(0,0,17),9,_materials.get_material("stone"))
		for branch in range(3):
			var leaf_tip:=pot+Vector3(side*(branch-1)*7,branch*3,31+branch*3)
			_column(pot+Vector3(0,0,17),leaf_tip,2,_materials.get_material("leaves"))
	var door_material:=StandardMaterial3D.new()
	door_material.albedo_color=Color("4c4438")
	door_material.roughness=1
	_box("DarkDoorRecess",center+Vector3(0,front_y+2,wall*.34+floor_height),Vector3(width*.19,3,wall*.68),door_material)
	for side in [-1.0,1.0]: _box("DoorPost",center+Vector3(side*width*.105,front_y-2,wall*.37+floor_height),Vector3(8,10,wall*.74),wood)
	var plaque_y: float=-depth*.5+3
	_box("CarvedWoodSign",center+Vector3(0,plaque_y,wall*.82),Vector3(width*.25,8,22),wood)
	for i in range(3):
		var p:=center+Vector3(-width*.34+i*width*.14,depth*.22,wall*.12+18)
		_column(p,p+Vector3(0,0,22),9,_materials.get_material("stone"))

func _lantern(at: Vector3) -> void:
	if _glow_material==null:
		_glow_material=StandardMaterial3D.new()
		_glow_material.albedo_color=Color("f4cc88")
		_glow_material.emission_enabled=true
		_glow_material.emission=Color("ffc773")
		_glow_material.emission_energy_multiplier=.38
	var wood: Material=_materials.get_material("wood")
	_box("LanternGlass",at,Vector3(10,10,16),_glow_material)
	_box("LanternCap",at+Vector3(0,0,10),Vector3(15,15,4),wood)
	_box("LanternBase",at-Vector3(0,0,10),Vector3(15,15,4),wood)
	_column(at+Vector3(0,0,12),at+Vector3(0,0,30),1,wood)
	var light:=OmniLight3D.new()
	light.position=at+Vector3(0,-14,0)
	light.light_color=Color("ffc078")
	light.light_energy=.5
	light.omni_range=300
	light.omni_attenuation=1.2
	light.shadow_enabled=false
	_geometry.add_child(light)
	light.global_basis=Basis.IDENTITY
	_lanterns.append(light)

func _column(start: Vector3,end: Vector3,radius: float,material: Material) -> MeshInstance3D:
	var cylinder:=CylinderMesh.new()
	cylinder.top_radius=radius*.85
	cylinder.bottom_radius=radius
	cylinder.height=start.distance_to(end)
	cylinder.radial_segments=7
	var instance:=MeshInstance3D.new()
	instance.mesh=cylinder
	instance.material_override=material
	instance.position=(start+end)*.5
	instance.quaternion=Quaternion(Vector3.UP,(end-start).normalized())
	_geometry.add_child(instance)
	_meshes+=1
	return instance

func _tree(entry: Dictionary, rect: Rect2, center: Vector3) -> void:
	_trees+=1
	var height:=float(entry.get("height3d",185))
	var palm:=str(entry.get("variant",""))=="palm"
	var wood: Material=_materials.get_material("wood")
	var previous:=center
	for i in range(7):
		var progress:=float(i+1)/7.0
		var next:=center+Vector3(sin(progress*1.2)*14,progress*5,height*progress)
		_column(previous,next,rect.size.x*(.20 if palm else .28)*(1.0-progress*.38),wood)
		previous=next
	if not palm:
		for side in [-1.0,1.0]:
			_column(center+Vector3(side*rect.size.x*.5,0,0),center+Vector3(0,0,height*.28),4,wood)
		if not _atlas_canopy(previous,210+height*.25,0): _canopy(previous,210+height*.25,_trees)
	else:
		if not _atlas_canopy(previous,height*1.35,1): _palm_fronds(previous,height*.65)

func _atlas_canopy(at: Vector3,width: float,index: int) -> bool:
	var path:="res://resources/art/land-foliage-v1.png"
	if not ResourceLoader.exists(path): return false
	var atlas: Texture2D=load(path)
	var cell:=atlas.get_size()/Vector2(3,2)
	var frame:=AtlasTexture.new()
	frame.atlas=atlas
	frame.region=Rect2(Vector2(index%3,index/3)*cell,cell)
	frame.filter_clip=true
	var sprite:=Sprite3D.new()
	sprite.name="LivingCanopy"
	sprite.texture=frame
	sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded=true
	sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold=.2
	sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	sprite.pixel_size=width/cell.x
	sprite.position=at+camera_up()*width*.08
	_geometry.add_child(sprite)
	_leaves.append({"node":sprite,"home":sprite.position,"phase":float(_trees)})
	return true

func _palm_fronds(crown: Vector3, radius: float) -> void:
	var leaf: Material=_materials.get_material("leaves")
	for index in range(9):
		var angle:=float(index)*TAU/9.0
		var direction:=Vector3(cos(angle),sin(angle),0)
		var side:=Vector3(-sin(angle),cos(angle),0)
		var vertices:=PackedVector3Array()
		for segment in range(8):
			var t:=float(segment)/7.0
			var at:=crown+direction*radius*t+Vector3(0,0,sin(t*PI)*25-t*t*28)
			var half_width: float=sin(t*PI)*radius*.115
			vertices.append(at-side*half_width)
			vertices.append(at+side*half_width)
			if segment in [2,3,4,5,6]:
				for sign_value in [-1.0,1.0]:
					var tip: Vector3=at+side*sign_value*half_width*1.8-direction*8-Vector3(0,0,10)
					_mesh("PalmLeaflet",PackedVector3Array([at,at+direction*14,tip]),PackedInt32Array([0,1,2]),leaf)
		var triangles:=PackedInt32Array()
		for segment in range(7): triangles.append_array(PackedInt32Array([segment*2,segment*2+1,segment*2+3,segment*2,segment*2+3,segment*2+2]))
		_mesh("PalmFrond",vertices,triangles,leaf)

func _canopy(at: Vector3,width: float,seed_value: int) -> void:
	var texture: Texture2D=load("res://resources/art/forest-muara.png")
	var pixel_base:=Vector2(690,260)
	var outline: Array[Vector2]=[Vector2(470,186),Vector2(541,122),Vector2(653,105),Vector2(747,139),Vector2(824,196),Vector2(859,278),Vector2(795,340),Vector2(730,356),Vector2(624,357),Vector2(550,343),Vector2(483,290)]
	var vertices:=PackedVector3Array()
	var poly:=PackedVector2Array()
	var factor:=width/390.0
	for p in outline:
		var relative: Vector2=(p-pixel_base)*factor
		vertices.append(at+Vector3(relative.x,0,0)-camera_up()*relative.y)
		poly.append(p)
	var shader:=Shader.new()
	shader.code="""
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D leaves : source_color,filter_nearest;
void fragment(){vec4 leaf=texture(leaves,UV);float mask=smoothstep(.015,.05,leaf.g-leaf.b)*smoothstep(-.02,.025,leaf.g-leaf.r*.93);if(mask<.35)discard;ALBEDO=leaf.rgb*.8;ROUGHNESS=1.0;}
"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("leaves",texture)
	var instance:=_mesh("TreeCrown",vertices,Geometry2D.triangulate_polygon(poly),material)
	var triangles:=Geometry2D.triangulate_polygon(poly)
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0,triangles.size(),3):
		for j in range(3):
			var vertex_index:=triangles[i+j]
			tool.set_normal(-camera_forward())
			tool.set_uv(outline[vertex_index]/texture.get_size())
			tool.add_vertex(vertices[vertex_index])
	instance.mesh=tool.commit()
	_leaves.append({"node":instance,"home":at,"phase":float(seed_value)})

func _rock(entry: Dictionary, rect: Rect2, center: Vector3) -> void:
	var path:="res://resources/models/reef-rock.glb"
	if not ResourceLoader.exists(path):
		_box("StoneBlock",center+Vector3(0,0,float(entry.height3d)*.5),Vector3(rect.size.x,rect.size.y/cos(TILT),float(entry.height3d)),_materials.get_material("stone"))
		return
	var model: Node3D=(load(path) as PackedScene).instantiate()
	_geometry.add_child(model)
	var meshes:=model.find_children("*","MeshInstance3D",true,false)
	var bounds:=AABB()
	var first:=true
	for leaf in meshes:
		var transform_to_model: Transform3D=model.global_transform.affine_inverse()*leaf.global_transform
		var extent: AABB=transform_to_model*leaf.get_aabb()
		bounds=extent if first else bounds.merge(extent)
		first=false
		leaf.material_override=_materials.get_material("stone")
	if first: model.queue_free(); return
	var holder:=Node3D.new()
	_geometry.add_child(holder)
	_geometry.remove_child(model)
	holder.add_child(model)
	model.position=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	holder.scale=Vector3(rect.size.x/maxf(bounds.size.x,.01),float(entry.height3d)/maxf(bounds.size.y,.01),rect.size.y/cos(TILT)/maxf(bounds.size.z,.01))
	holder.rotation.x=PI*.5
	holder.position=center
	_models+=1

func _garden(_entry: Dictionary,rect: Rect2,center: Vector3) -> void:
	var wood: Material=_materials.get_material("wood")
	for index in range(3):
		var offset: float=(index-1)*rect.size.x*.3
		_box("RaisedBed",center+Vector3(offset,0,14),Vector3(rect.size.x*.27,rect.size.y/cos(TILT),28),wood)
		_box("DarkSoil",center+Vector3(offset,0,30),Vector3(rect.size.x*.25,rect.size.y/cos(TILT)-6,4),_materials.get_material("dirt"))
		for crop in range(5):
			var plant:=center+Vector3(offset,-rect.size.y*.48+crop*rect.size.y*.24,31)
			_column(plant,plant+Vector3(0,0,16),2,_materials.get_material("leaves"))
			_box("CropLeaves",plant+Vector3(0,0,14),Vector3(13,12,4),_materials.get_material("leaves"))

func _fence(_entry: Dictionary,rect: Rect2,center: Vector3) -> void:
	if str(_entry.get("variant",""))=="bridge_rail":
		_bridge_rail(_entry)
		return
	var wood: Material=_materials.get_material("bamboo")
	var count:=maxi(3,ceili(rect.size.x/20))
	for i in range(count):
		var x: float=-rect.size.x*.5+float(i)*rect.size.x/maxi(1,count-1)
		_column(center+Vector3(x,0,0),center+Vector3(x,0,75),4,wood)
	for height in [24.0,58.0]: _box("FenceRail",center+Vector3(0,0,height),Vector3(rect.size.x+8,8,7),wood)

func _crate(entry: Dictionary,rect: Rect2,center: Vector3) -> void:
	var height:=float(entry.get("height3d",40))
	_box("Crate",center+Vector3(0,0,height*.5),Vector3(rect.size.x,rect.size.y/cos(TILT),height),_materials.get_material("wood"))
	for offset in [-rect.size.x*.3,rect.size.x*.3]:
		_box("CrateBand",center+Vector3(offset,0,height*.5),Vector3(5,rect.size.y/cos(TILT)+3,height+3),_materials.get_material("bamboo"))

func _build_ground_details() -> void:
	var fern_path:="res://resources/art/polyfork/fern-plant.png"
	var fern: Texture2D=load(fern_path) if ResourceLoader.exists(fern_path) else null
	var ground_foliage: Array[Texture2D]=[]
	if fern!=null: ground_foliage.append(fern)
	var foliage_path:="res://resources/art/land-foliage-v1.png"
	if ResourceLoader.exists(foliage_path):
		var atlas: Texture2D=load(foliage_path)
		var cell:=atlas.get_size()/Vector2(3,2)
		for frame_index in [2,4]:
			var frame:=AtlasTexture.new()
			frame.atlas=atlas
			frame.region=Rect2(Vector2(frame_index%3,frame_index/3)*cell,cell)
			frame.filter_clip=true
			ground_foliage.append(frame)
	var flower_material:=StandardMaterial3D.new()
	flower_material.albedo_color=Color("bc9c7e")
	flower_material.roughness=1
	var clusters: Array[Vector2]=[]
	if area=="hub":
		clusters=[Vector2(490,660),Vector2(740,650),Vector2(1180,680),Vector2(1485,675),Vector2(700,1000),Vector2(1550,980),Vector2(1180,1100)]
	else:
		for obstacle in map.get("obstacles",[]):
			if str(obstacle.kind)=="tree" and clusters.size()<18: clusters.append(Vector2(float(obstacle.x)+48,float(obstacle.y)+48))
	for cluster_index in range(clusters.size()):
		for tuft in range(4+cluster_index%4):
			var angle:=float(tuft)*2.39996+cluster_index*.71
			var radius:=10.0+fposmod(tuft*13.7+cluster_index*3.1,26.0)
			var point:=clusters[cluster_index]+Vector2(cos(angle),sin(angle))*radius
			if not _decor_ground(point): continue
			var at:=map_point(point,ground_height(point)+1)
			if not ground_foliage.is_empty():
				var ground_texture: Texture2D=ground_foliage[(tuft+cluster_index)%ground_foliage.size()]
				var plant:=Sprite3D.new()
				plant.texture=ground_texture
				plant.billboard=BaseMaterial3D.BILLBOARD_ENABLED
				plant.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
				plant.alpha_scissor_threshold=.3
				plant.shaded=true
				plant.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
				var plant_width:=16.0+fposmod(tuft*5.7+cluster_index*2.4,24.0)
				plant.pixel_size=plant_width/ground_texture.get_width()
				plant.position=at+camera_up()*plant_width*.36
				plant.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				_geometry.add_child(plant)
			for litter in range(3):
				var leaf_offset:=Vector3(litter*7-7,tuft%3*3-3,.4)
				_box("LeafLitter",at+leaf_offset,Vector3(4+tuft%3,2,0.8),_materials.get_material("leaves"))
			if area=="hub":
				var flower:=at+Vector3(7,0,9+tuft)
				_column(at+Vector3(7,0,0),flower,.7,_materials.get_material("leaves"))
				_box("SmallFlower",flower,Vector3(5,2,3),flower_material)
				_box("SmallFlower",flower,Vector3(2,5,3),flower_material)
	var index:=0
	for surface in map.get("surfaces",[]):
		if not bool(surface.get("walkable",true)) or str(surface.material) not in ["grass","dirt","sand"]: continue
		var polygon:=_polygon(surface.polygon)
		var bounds:=Rect2(polygon[0],Vector2.ZERO)
		for p in polygon: bounds=bounds.expand(p)
		var count:=clampi(int(bounds.get_area()/42000.0),3,28)
		for candidate in range(count):
			index+=1
			var fraction:=Vector2(fposmod(index*.6180339,1),fposmod(index*.4142135,1))
			var point:=bounds.position+bounds.size*fraction
			if not Geometry2D.is_point_in_polygon(point,polygon): continue
			var blocked:=false
			for obstacle in map.get("obstacles",[]):
				if Geometry2D.is_point_in_polygon(point,_polygon(obstacle.footprint)): blocked=true; break
			if blocked: continue
			var at:=map_point(point,ground_height(point)+1)
			if str(surface.material)=="grass" and fern!=null:
				var plant:=Sprite3D.new()
				plant.texture=fern
				plant.billboard=BaseMaterial3D.BILLBOARD_ENABLED
				plant.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
				plant.alpha_scissor_threshold=.3
				plant.shaded=true
				plant.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
				plant.pixel_size=22.0/fern.get_width()
				plant.position=at+camera_up()*8
				plant.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				_geometry.add_child(plant)
			else:
				for pebble in range(3):
					var offset:=Vector3(pebble*5-5,pebble%2*4,1)
					_box("LoosePebble",at+offset,Vector3(3+index%3,4,2),_materials.get_material("stone"))

func _decor_ground(point: Vector2) -> bool:
	var on_ground:=false
	for surface in map.get("surfaces",[]):
		if bool(surface.get("walkable",true)) and Geometry2D.is_point_in_polygon(point,_polygon(surface.polygon)): on_ground=true; break
	if not on_ground: return false
	for obstacle in map.get("obstacles",[]):
		if Geometry2D.is_point_in_polygon(point,_polygon(obstacle.footprint)): return false
	return true

func _batch_static_geometry() -> void:
	var batches: Dictionary={}
	var originals: Array[MeshInstance3D]=[]
	for child in _geometry.find_children("*","MeshInstance3D",true,false):
		var mesh:=child as MeshInstance3D
		if mesh.name=="TreeCrown" or (is_instance_valid(water_node) and water_node.is_ancestor_of(mesh)): continue
		if mesh==water_mesh: continue
		var material:=mesh.material_override
		if material==null: continue
		var format_key:=str((mesh.mesh as ArrayMesh).surface_get_format(0)) if mesh.mesh is ArrayMesh else mesh.mesh.get_class()
		var key:=str(material.get_instance_id())+":"+format_key
		if not batches.has(key):
			var tool:=SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			batches[key]={"tool":tool,"material":material}
		var tool: SurfaceTool=batches[key].tool
		var transform_to_geometry: Transform3D=_geometry.global_transform.affine_inverse()*mesh.global_transform
		for surface in range(mesh.mesh.get_surface_count()): tool.append_from(mesh.mesh,surface,transform_to_geometry)
		originals.append(mesh)
	for key in batches:
		var tool: SurfaceTool=batches[key].tool
		var combined:=MeshInstance3D.new()
		combined.name="StaticMaterialBatch_"+str(key)
		combined.mesh=tool.commit()
		combined.material_override=batches[key].material
		_geometry.add_child(combined)
	for mesh in originals:
		mesh.get_parent().remove_child(mesh)
		mesh.queue_free()
	_meshes=batches.size()

func _process(delta: float) -> void:
	if not _built or not is_instance_valid(actor) or not is_instance_valid(source_camera): return
	active=area=="forest" or GameState.dive.is_empty()
	display.visible=active
	viewport_3d.render_target_update_mode=SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	if not active: return
	display.size=get_viewport().get_visible_rect().size
	_center=source_camera.get_screen_center_position()
	var center:=map_point(_center,0)
	camera_3d.position=center+Vector3(0,-sin(TILT)*DISTANCE,cos(TILT)*DISTANCE)
	camera_3d.look_at(center,Vector3(0,0,1))
	camera_3d.size=540.0/maxf(.1,source_camera.zoom.y)
	actors_3d.update_actors(delta)
	var conditions:=EnvironmentState.snapshot()
	var sway:=0.0 if bool(conditions.get("reduced_motion",false)) else 1.2+absf(float(conditions.get("wind_x",0)))*.035
	for leaf in _leaves:
		var node: Node3D=leaf.node
		var home: Vector3=leaf.home
		node.position=home+Vector3(sin(float(Time.get_ticks_msec())*.0009+float(leaf.phase))*sway,0,0)
	_weather_clock+=delta
	if _weather_clock>.25:
		_weather_clock=0
		var weather:=EnvironmentState.snapshot()
		var daylight:=clampf((float(weather.get("daylight",.8))-.24)/.76,0,1)
		var clouds:=float(weather.get("clouds",0))
		sunlight.light_energy=lerpf(.035,.55,daylight)*(1-clouds*.25)
		sunlight.light_color=Color("a5c2c0").lerp(Color("fff0d7"),daylight)
		sunlight.shadow_enabled=daylight>.15
		for lantern in _lanterns: lantern.light_energy=lerpf(280.0,28.0,daylight)
		if _glow_material: _glow_material.emission_energy_multiplier=lerpf(.85,.14,daylight)
		environment.ambient_light_energy=lerpf(.50,.55,daylight)
		environment.ambient_light_color=Color("8da4a8").lerp(Color("bdc0b5"),daylight)

func debug_status() -> Dictionary:
	return {"active":active,"area":area,"renderer":"LandSubViewport3D","viewport":[480,270],"tilt":55,"elevationDegrees":35,"meshes":_meshes,"houses":_houses,"trees":_trees,"glbModels":_models,"stairTreads":_stair_treads,"surfaces":map.get("surfaces",[]).size(),"obstacles":map.get("obstacles",[]).size(),"actors":actors_3d.counts if is_instance_valid(actors_3d) else {},"maxFootError":actors_3d.max_foot_error if is_instance_valid(actors_3d) else 0,"camera":[_center.x,_center.y],"warmLanterns":_lanterns.size(),"components":_components.duplicate(),"bridges":_bridges.duplicate(true),"bitmapGround":false,"water":water_node.debug_status() if is_instance_valid(water_node) else {}}

func _build_bridge(surface: Dictionary) -> void:
	var polygon:=_polygon(surface.polygon)
	if polygon.size()<4: return
	var id:=str(surface.get("bridgeId",surface.id))
	var metadata: Dictionary={}
	for bridge in map.get("bridges",[]):
		if str(bridge.id)==id: metadata=bridge; break
	var a: Vector2
	var b: Vector2
	if metadata.has("path"):
		a=_v2(metadata.path[0])
		b=_v2(metadata.path[-1])
	elif polygon[0].distance_to(polygon[1])>polygon[1].distance_to(polygon[2]):
		a=(polygon[0]+polygon[3])*.5
		b=(polygon[1]+polygon[2])*.5
	else:
		a=(polygon[0]+polygon[1])*.5
		b=(polygon[2]+polygon[3])*.5
	var axis: Vector2=(b-a).normalized()
	var side:=Vector2(-axis.y,axis.x)
	var width:=float(metadata.get("width",minf(polygon[0].distance_to(polygon[1]),polygon[1].distance_to(polygon[2]))))
	var height:=float(surface.get("elevation",0))*LEVEL_HEIGHT
	var count:=maxi(2,ceili(a.distance_to(b)/19.0))
	var boards: Array[Material]=[_materials.get_material("bridge_board"),_materials.get_material("bridge_board_light"),_materials.get_material("bridge_board_dark")]
	var wood: Material=_materials.get_material("wood")
	var bamboo: Material=_materials.get_material("bamboo")
	_bridges[id]={"id":id,"axis":[axis.x,axis.y],"endpoints":[[a.x,a.y],[b.x,b.y]],"planks":0,"sideBeams":2,"railPosts":0,"railBeams":0,"thickness":18,"oriented":true}
	for index in range(count):
		var start:=a.lerp(b,float(index)/count)
		var end:=a.lerp(b,float(index+1)/count)
		var gap:=Vector2.ZERO
		var board: Material=boards[(index*7+floori(float(index)/3.0))%boards.size()]
		var plank:=PackedVector2Array([start-side*width*.5+gap,end-side*width*.5-gap,end+side*width*.5-gap,start+side*width*.5+gap])
		for piece in Geometry2D.intersect_polygons(plank,polygon):
			var top:=PackedVector3Array()
			for point in piece: top.append(map_point(point,height)+Vector3(0,0,.75))
			_mesh("BridgePlank",top,Geometry2D.triangulate_polygon(piece),board)
			for edge in range(piece.size()):
				var p:=map_point(piece[edge],height)+Vector3(0,0,.75)
				var q:=map_point(piece[(edge+1)%piece.size()],height)+Vector3(0,0,.75)
				_face("BridgePlankEdge",[p,q,q-Vector3(0,0,18),p-Vector3(0,0,18)],wood)
			_bridges[id].planks=int(_bridges[id].planks)+1
	for sign_value in [-1.0,1.0]:
		var offset: Vector2=side*(width*.5-7)*float(sign_value)
		_column(map_point(a+offset,height)-Vector3(0,0,21),map_point(b+offset,height)-Vector3(0,0,21),7,wood)
		for fraction in [.08,.48,.92]:
			var at:=map_point(a.lerp(b,fraction)+offset,height)-Vector3(0,0,18)
			_column(at-Vector3(0,0,95),at,7,bamboo)
			_column(at-Vector3(0,0,64),at+Vector3(axis.x*24,-axis.y*24/cos(TILT),0),3,wood)
	for end_point in [a,b]:
		var start:=map_point(end_point-side*width*.48,height)-Vector3(0,0,20)
		var end:=map_point(end_point+side*width*.48,height)-Vector3(0,0,20)
		_column(start,end,10,_materials.get_material("stone"))

func _bridge_rail(entry: Dictionary) -> void:
	var polygon:=_polygon(entry.footprint)
	if polygon.size()!=4: return
	var a: Vector2
	var b: Vector2
	var thickness: float
	if polygon[0].distance_to(polygon[1])>polygon[1].distance_to(polygon[2]):
		a=(polygon[0]+polygon[3])*.5
		b=(polygon[1]+polygon[2])*.5
		thickness=polygon[0].distance_to(polygon[3])
	else:
		a=(polygon[0]+polygon[1])*.5
		b=(polygon[2]+polygon[3])*.5
		thickness=polygon[0].distance_to(polygon[1])
	var height:=float(entry.get("elevation",0))*LEVEL_HEIGHT
	var rail_height:=float(entry.get("height3d",44))
	var radius:=minf(3.5,thickness*.36)
	var posts:=maxi(2,ceili(a.distance_to(b)/67.0))
	var inset:=(b-a).normalized()*radius
	a+=inset
	b-=inset
	var bamboo: Material=_materials.get_material("bamboo")
	for index in range(posts+1):
		var at:=map_point(a.lerp(b,float(index)/posts),height)
		_column(at,at+Vector3(0,0,rail_height),radius,bamboo)
	for z in [rail_height*.46,rail_height*.90]:
		_column(map_point(a,height)+Vector3(0,0,z),map_point(b,height)+Vector3(0,0,z),radius*.66,bamboo)
	for bridge in map.get("bridges",[]):
		if str(entry.id) in bridge.get("railIds",[]):
			var id:=str(bridge.id)
			if _bridges.has(id):
				_bridges[id].railPosts=int(_bridges[id].railPosts)+posts+1
				_bridges[id].railBeams=int(_bridges[id].railBeams)+2

func _ragged_patch(polygon: PackedVector2Array) -> PackedVector2Array:
	var center:=Vector2.ZERO
	for point in polygon: center+=point
	center/=polygon.size()
	var result:=PackedVector2Array()
	for index in range(polygon.size()):
		var a:=polygon[index]
		var b:=polygon[(index+1)%polygon.size()]
		var count:=maxi(2,ceili(a.distance_to(b)/15.0))
		for part in range(count):
			var point:=a.lerp(b,float(part)/count)
			var seed_value:=sin(point.x*.127+point.y*.193)*4375.43
			var inward:=(center-point).normalized()*(3.0+fposmod(seed_value,1)*7.0)
			var candidate:=point+inward
			result.append(candidate if Geometry2D.is_point_in_polygon(candidate,polygon) else point)
	return result

func _build_wet_banks() -> void:
	if area!="forest": return
	var atlas_path:="res://resources/art/land-foliage-v1.png"
	if not ResourceLoader.exists(atlas_path): return
	var atlas: Texture2D=load(atlas_path)
	var cell:=atlas.get_size()/Vector2(3,2)
	var fronds:=AtlasTexture.new()
	fronds.atlas=atlas
	fronds.region=Rect2(Vector2(2,0)*cell,cell)
	fronds.filter_clip=true
	var placed: Array[Vector2]=[]
	for bridge in map.get("bridges",[]):
		var center:=(_v2(bridge.path[0])+_v2(bridge.path[-1]))*.5
		for bank in ["forest_west_land","forest_east_land"]:
			var floor_polygon:=PackedVector2Array()
			for surface in map.get("surfaces",[]):
				if str(surface.id)==bank: floor_polygon=_polygon(surface.polygon); break
			for displacement in [-170.0,150.0,230.0]:
				if placed.size()>=12: return
				var y: float=center.y+displacement+(-19.0 if bank=="forest_west_land" else 23.0)
				var intersections: Array[float]=[]
				for edge in range(floor_polygon.size()):
					var a:=floor_polygon[edge]
					var b:=floor_polygon[(edge+1)%floor_polygon.size()]
					if (a.y<=y and b.y>y) or (b.y<=y and a.y>y):
						intersections.append(lerpf(a.x,b.x,(y-a.y)/(b.y-a.y)))
				if intersections.size()<2: continue
				intersections.sort()
				var west: bool=bank=="forest_west_land"
				var point:=Vector2(intersections[-1]+14 if west else intersections[0]-14,y)
				if not _wet_bank_clear(point,placed): continue
				placed.append(point)
				_components["WetBankClusters"]=placed.size()
				for index in range(3):
					var offset:=Vector2((index-1)*3,index%2*5-2)
					var at:=map_point(point+offset,0)-Vector3(0,0,11)
					var plant:=Sprite3D.new()
					plant.name="WetBankFronds"
					plant.texture=fronds
					plant.billboard=BaseMaterial3D.BILLBOARD_ENABLED
					plant.shaded=true
					plant.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
					plant.alpha_scissor_threshold=.25
					plant.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
					plant.pixel_size=(16.0+index*3)/cell.x
					plant.position=at+camera_up()*(6+index)
					plant.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					_geometry.add_child(plant)
				for pebble in range(4):
					var offset:=Vector2(pebble*4-6,(pebble%2)*6-3)
					_box("WetBankPebble",map_point(point+offset,0)-Vector3(0,0,8),Vector3(4+pebble%3,5,8),_materials.get_material("stone"))
	_components["WetBankClusters"]=placed.size()

func _wet_bank_clear(point: Vector2,placed: Array[Vector2]) -> bool:
	for previous in placed:
		if point.distance_to(previous)<65: return false
	for bridge in map.get("bridges",[]):
		var a:=_v2(bridge.path[0])
		var b:=_v2(bridge.path[-1])
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b))<100: return false
	for surface in map.get("surfaces",[]):
		if not bool(surface.get("walkable",true)): continue
		var polygon:=_polygon(surface.polygon)
		for sample in [Vector2.ZERO,Vector2(12,0),Vector2(-12,0),Vector2(0,12),Vector2(0,-12)]:
			if Geometry2D.is_point_in_polygon(point+sample,polygon): return false
	return true

func _gateway_arch(label: String, post_a: Vector2, post_b: Vector2, elevation_z: float) -> void:
	if _glow_material==null:
		_glow_material=StandardMaterial3D.new()
		_glow_material.albedo_color=Color("f4cc88")
		_glow_material.emission_enabled=true
		_glow_material.emission=Color("ffc773")
		_glow_material.emission_energy_multiplier=.38
	var wood: Material=_materials.get_material("wood")
	var bamboo: Material=_materials.get_material("bamboo")
	var thatch: Material=_materials.get_material("thatch")
	var stone: Material=_materials.get_material("stone")
	var a3:=map_point(post_a,elevation_z)
	var b3:=map_point(post_b,elevation_z)
	var mid:=(a3+b3)*.5
	for post in [a3,b3]:
		_box(label+"_Base",post+Vector3(0,0,10),Vector3(18,18,20),stone)
		_column(post+Vector3(0,0,16),post+Vector3(0,0,118),6.5,wood)
		_column(post+Vector3(0,0,28),post+Vector3(0,0,112),4.0,bamboo)
	_column(a3+Vector3(0,0,98),b3+Vector3(0,0,98),5.0,wood)
	_column(a3+Vector3(0,0,114),b3+Vector3(0,0,114),6.0,bamboo)
	var span:=a3.distance_to(b3)+26.0
	_box(label+"_LintelRoof",mid+Vector3(0,0,122),Vector3(span,26,12),thatch)
	_box(label+"_Signboard",mid+Vector3(0,0,105),Vector3(span*.55,8,14),wood)
	var lamp_pos:=a3.lerp(b3,0.18)+Vector3(0,0,84)
	_box(label+"_LanternGlass",lamp_pos,Vector3(9,9,14),_glow_material)
	_box(label+"_LanternCap",lamp_pos+Vector3(0,0,8),Vector3(13,13,4),wood)
	_box(label+"_LanternBase",lamp_pos-Vector3(0,0,8),Vector3(13,13,4),wood)

func _build_corridor_landmarks() -> void:
	var wood: Material=_materials.get_material("wood")
	var bamboo: Material=_materials.get_material("bamboo")
	var stone: Material=_materials.get_material("stone")
	if area=="hub":
		var ridge_z:=3.0*LEVEL_HEIGHT
		_gateway_arch("HubForestGate",Vector2(2248,108),Vector2(2326,108),ridge_z)
		for side_x in [1720.0,1840.0]:
			var step_pillar:=map_point(Vector2(side_x,392),ridge_z)
			_box("RidgeStepPillar",step_pillar+Vector3(0,0,16),Vector3(16,16,32),stone)
			_box("RidgeStepCap",step_pillar+Vector3(0,0,34),Vector3(20,20,6),wood)
		for cairn_pt in [Vector2(2040,248),Vector2(2215,245)]:
			var c_at:=map_point(cairn_pt,ridge_z)
			_box("RidgeGuideStone",c_at+Vector3(0,0,11),Vector3(14,12,22),stone)
		for backdrop_pt in [Vector2(2205,48),Vector2(2355,52)]:
			_tree({"height3d":185,"variant":"broadleaf"},Rect2(backdrop_pt-Vector2(16,16),Vector2(32,32)),map_point(backdrop_pt,ridge_z-2.0))
	elif area=="forest":
		_gateway_arch("ForestEntryGate",Vector2(108,1358),Vector2(188,1358),0.0)
		var sign_at:=map_point(Vector2(228,1348),0.0)
		_column(sign_at,sign_at+Vector3(0,0,58),4.5,wood)
		_box("ForestDirectionSign",sign_at+Vector3(0,0,48),Vector3(38,8,14),wood)
		_box("ForestEntryCairn",sign_at+Vector3(-18,8,10),Vector3(16,14,20),stone)
		for border_pt in [Vector2(45,1150),Vector2(95,1010),Vector2(185,910),Vector2(-25,1280)]:
			_tree({"height3d":195,"variant":"broadleaf"},Rect2(border_pt-Vector2(17,17),Vector2(34,34)),map_point(border_pt,0.0))
		# Landmark 1: Celah Cahaya Tajuk (650, 1050)
		var canopy_pt:=map_point(Vector2(692,1005),0.0)
		_box("CanopyCairnBase",canopy_pt+Vector3(0,0,10),Vector3(24,20,20),stone)
		_box("CanopyCairnTop",canopy_pt+Vector3(0,0,24),Vector3(14,12,12),stone)
		_column(canopy_pt+Vector3(-28,16,7),canopy_pt+Vector3(18,24,7),6.0,wood)
		# Landmark 2: Akar dan Serasah (1200, 730)
		var roots_pt:=map_point(Vector2(1148,688),0.0)
		for arc in [-1.0,1.0]:
			_column(roots_pt+Vector3(arc*22,0,0),roots_pt+Vector3(0,0,46),5.5,wood)
		_box("RootsMarkerStone",roots_pt+Vector3(0,0,12),Vector3(18,16,24),stone)
		# Landmark 3: Aliran Hulu Bandar (1830, 470)
		var stream_pt:=map_point(Vector2(1788,425),0.0)
		_column(stream_pt,stream_pt+Vector3(0,0,54),4.5,bamboo)
		_column(stream_pt+Vector3(28,8,0),stream_pt+Vector3(28,8,54),4.5,bamboo)
		_column(stream_pt+Vector3(0,0,42),stream_pt+Vector3(28,8,42),3.5,bamboo)
		_box("StreamWatchStone",stream_pt+Vector3(-16,12,9),Vector3(18,14,18),stone)
		# Landmark 4: Peti Perbekalan (2130, 1050)
		var cache_pt:=map_point(Vector2(2166,1008),0.0)
		_box("CachePlatform",cache_pt+Vector3(0,0,5),Vector3(46,34,10),bamboo)
		_box("CacheChest",cache_pt+Vector3(0,0,20),Vector3(34,24,22),wood)
		_box("CacheChestBand",cache_pt+Vector3(0,0,21),Vector3(36,26,5),bamboo)
