extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func _project(vertex:Vector3) -> Vector2:
	return Vector2(vertex.x,-vertex.y+sin(deg_to_rad(12.0))*vertex.z)

func run() -> void:
	var world:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var unchanged:=JSON.stringify(world)
	var terrain=load("res://scripts/hybrid/TerrainGeometry.gd").new()
	root.add_child(terrain)
	terrain.configure(world)
	var geology=terrain.geology
	var connection:Dictionary={}
	for candidate in geology.connections:
		if int(candidate.terrain)==13: connection=candidate
	assert(int(connection.anchoredTo)==4 and connection.profile=="flared_collar")
	var root_mesh:MeshInstance3D=geology.get_node("RearAnchoredStratum13")
	var arrays:Array=root_mesh.mesh.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var shades:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
	var top:float=connection.top[1]
	var bottom:float=connection.base[1]
	var top_x:Array[float]=[]
	var base_x:Array[float]=[]
	var middle_x:Array[float]=[]
	var upper:Array=world.terrain[13]
	var lower:Array=world.terrain[4]
	var upper_outline:=PackedVector2Array()
	var lower_outline:=PackedVector2Array()
	for at in world.terrainContours[13]: upper_outline.append(Vector2(at[0],at[1]))
	for at in world.terrainContours[4]: lower_outline.append(Vector2(at[0],at[1]))
	var upper_rect:=Rect2(upper[0],upper[1],upper[2],upper[3])
	var lower_rect:=Rect2(lower[0],lower[1],lower[2],lower[3])
	for vertex in vertices:
		assert(vertex.z < -100,"Collar must stay behind the swimmer, never a foreground obstacle")
		var at:=_project(vertex)
		if absf(at.y-top)<.01:
			top_x.append(at.x)
			assert(upper_rect.has_point(at) and Geometry2D.is_point_in_polygon(at,upper_outline),"Every shoulder vertex must nest inside the source volume")
		if absf(at.y-bottom)<.01:
			base_x.append(at.x)
			assert(lower_rect.has_point(at) and Geometry2D.is_point_in_polygon(at,lower_outline),"Every flared foot vertex must nest inside the destination volume")
		if absf(at.y-lerpf(top,bottom,3.0/7.0))<.01: middle_x.append(at.x)
	assert(top_x.size()>0 and base_x.size()>0 and middle_x.size()>0)
	assert(top_x.max()-top_x.min()>middle_x.max()-middle_x.min()+20,"Shoulder must have visible geometric collar, not just a label")
	assert(base_x.max()-base_x.min()>top_x.max()-top_x.min()+30,"Base must flare into lower stratum")
	var wall:MeshInstance3D=terrain.get_node("CaveRearRockWall")
	var outline:PackedVector2Array=wall.get_meta("rear_outline")
	assert(outline.size()>=24)
	var recesses:=0
	for index in outline.size():
		var a:=outline[index]
		var b:=outline[(index+1)%outline.size()]
		var c:=outline[(index+2)%outline.size()]
		assert(a.distance_to(b)<140,"No long quad edge may survive in the rear silhouette")
		if (b-a).cross(c-b)<0: recesses+=1
	assert(recesses>=6,"Silhouette needs genuine recesses, not a subdivided rectangle")
	var wall_arrays:Array=wall.mesh.surface_get_arrays(0)
	var wall_vertices:PackedVector3Array=wall_arrays[Mesh.ARRAY_VERTEX]
	var edges:Dictionary={}
	for triangle in range(0,wall_vertices.size(),3):
		for edge in range(3):
			var a:=str(wall_vertices[triangle+edge].snapped(Vector3.ONE*.001))
			var b:=str(wall_vertices[triangle+(edge+1)%3].snapped(Vector3.ONE*.001))
			var key:=a+"|"+b if a<b else b+"|"+a
			edges[key]=int(edges.get(key,0))+1
	var open_edges:=0
	for count in edges.values():
		assert(int(count)<=2,"No doubled overlapping rear-wall triangles")
		if int(count)==1: open_edges+=1
	assert(open_edges==outline.size(),"Only the outer perimeter may be open; shared relief bands must meet without cracks")
	var wall_colors:PackedColorArray=wall_arrays[Mesh.ARRAY_COLOR]
	var min_depth:=0.0
	var max_depth:=-10000.0
	for vertex in wall_arrays[Mesh.ARRAY_VERTEX]:
		assert(vertex.z < -500,"All cave relief remains farther back than anchored roots")
		min_depth=minf(min_depth,vertex.z)
		max_depth=maxf(max_depth,vertex.z)
	assert(max_depth-min_depth>130,"Rear wall must retain actual relief, not a cutout plane")
	assert(shades[0].get_luminance()>wall_colors[0].get_luminance()+.1,"Support and distant wall need distinct material value")
	for center in [Vector2(660,900),Vector2(750,900),Vector2(840,900)]:
		geology.update_camera(center)
		assert(geology.position==Vector3.ZERO)
	assert(terrain.find_children("*","CollisionObject3D",true,false).is_empty())
	assert(terrain.get_meta("model_rock_mounts").size()==3,"All three previous GLB mounts remain present")
	assert(JSON.stringify(world)==unchanged,"No terrain, routes, targets or save definitions may change")
	print("OCEAN06 PASS: mesh shoulders/base inside existing volumes; rear-only flare; 30-point recessed cave relief; camera-locked roots; previous mounts retained; no colliders/world mutations")
	terrain.free()
	quit()
