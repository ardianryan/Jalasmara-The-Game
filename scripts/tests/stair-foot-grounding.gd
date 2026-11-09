extends SceneTree

const Traversal = preload("res://scripts/SurfaceTraversal.gd")
const Stairs = preload("res://scripts/land/StairGeometry3D.gd")
const GRID := 64.0
var _triangles: Dictionary={}
var checks:=0
var flat_floor_normals:=0

func _initialize() -> void: call_deferred("run")
func _v2(value: Array) -> Vector2: return Vector2(float(value[0]),float(value[1]))

func _index_meshes(renderer: Node) -> void:
	var dirt: Color=renderer._materials.get_material("dirt").get_shader_parameter("base_color")
	var grass: Color=renderer._materials.get_material("grass").get_shader_parameter("base_color")
	for instance in renderer._geometry.find_children("*","MeshInstance3D",true,false):
		if not str(instance.name).begins_with("StaticMaterialBatch_"): continue
		var material: Material=instance.material_override
		var floor_material:=false
		if material is ShaderMaterial:
			var kind:=int(material.get_shader_parameter("kind"))
			var color: Color=material.get_shader_parameter("base_color")
			floor_material=kind in [0,1] and (color.is_equal_approx(dirt) or color.is_equal_approx(grass))
		for surface in range(instance.mesh.get_surface_count()):
			var arrays: Array=instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			var count:=indices.size() if not indices.is_empty() else vertices.size()
			for index in range(0,count,3):
				var triangle: Array[Vector3]=[]
				for corner in range(3): triangle.append(instance.to_global(vertices[indices[index+corner] if not indices.is_empty() else index+corner]))
				var geometric: Vector3=(triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).normalized()
				if floor_material and absf(geometric.z)>.99:
					for corner in range(3):
						var at:=indices[index+corner] if not indices.is_empty() else index+corner
						var normal: Vector3=(instance.global_basis.inverse().transposed()*normals[at]).normalized()
						assert(normal.dot(Vector3(0,0,1))>.99999,"Actual batched flat dirt/grass vertex normal must face up in both the shadow pass and fragment lighting")
						flat_floor_normals+=1
				if absf(geometric.z)<.2: continue
				var low:=Vector2(minf(triangle[0].x,minf(triangle[1].x,triangle[2].x)),minf(triangle[0].y,minf(triangle[1].y,triangle[2].y)))
				var high:=Vector2(maxf(triangle[0].x,maxf(triangle[1].x,triangle[2].x)),maxf(triangle[0].y,maxf(triangle[1].y,triangle[2].y)))
				for x in range(floori(low.x/GRID),floori(high.x/GRID)+1):
					for y in range(floori(low.y/GRID),floori(high.y/GRID)+1):
						var key:=Vector2i(x,y)
						if not _triangles.has(key): _triangles[key]=[]
						_triangles[key].append(triangle)

func _highest_floor(point: Vector3) -> float:
	var highest:=-INF
	for triangle in _triangles.get(Vector2i(floori(point.x/GRID),floori(point.y/GRID)),[]):
		var hit=Geometry3D.ray_intersects_triangle(point+Vector3(0,0,512),Vector3(0,0,-1),triangle[0],triangle[1],triangle[2])
		if hit!=null: highest=maxf(highest,float(hit.z))
	return highest

func run() -> void:
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":200,"inventory":[],"progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var original:=JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})
	var environment:=root.get_node("EnvironmentState")
	environment.set_process(false)
	environment.clock_paused=false
	var stage:=Node2D.new()
	root.add_child(stage)
	var player: CharacterBody2D=load("res://scripts/Player.gd").new()
	stage.add_child(player)
	player.set_physics_process(false)
	player.hybrid_visual=true
	player.position=Vector2(1370,795)
	player.surface_traversal.configure(state.world.landMaps.hub)
	var camera:=Camera2D.new()
	stage.add_child(camera)
	var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	renderer.setup(stage,player,camera,"hub")
	renderer.set_process(false)
	renderer._process(0)
	assert(renderer.has_method("ground_point"),"Integration must use the actual stair contact embedding")
	_index_meshes(renderer)
	assert(flat_floor_normals>30,"Normal regression must measure real batched dirt/grass surfaces, excluding vegetation and vertical cliff faces")
	var traversal:=Traversal.new()
	traversal.configure(state.world.landMaps.hub)
	var actual_treads:=0
	var legacy_inverse_misses:=0
	for connector in state.world.landMaps.hub.stairs:
		var profile:=Traversal.connector_profile(connector,renderer._level(str(connector.from)),renderer._level(str(connector.to)))
		var start: Vector2=profile.start
		var end: Vector2=profile.end
		var along: Vector2=(end-start).normalized()
		var side:=Vector2(-along.y,along.x)
		var count:=int(profile.steps) if str(connector.type)=="stairs" else 1
		for index in range(count):
			for phase in [.1,.5,.9]:
				var progress: float=(index+phase)/count
				for across in [-.3,0.0,.3]:
					var logical: Vector2=start.lerp(end,progress)+side*float(connector.width)*float(across)
					var ground:=Traversal.connector_ground(profile,logical)
					var support: Vector3=renderer.ground_point(logical)
					assert(absf(support.z-float(ground.groundHeight))<.001)
					var highest:=_highest_floor(support)
					assert(is_finite(highest) and absf(highest-support.z)<.025,"Foot is buried under or floating above actual highest rendered tread: "+str(connector.id)+" logical="+str(logical)+" support="+str(support)+" meshZ="+str(highest))
					assert(Stairs.logical_from_contact(renderer,profile,support).distance_to(logical)<.005)
					var recovered: Vector2=renderer.logical_on_height(support-renderer.camera_forward()*8,support.z)
					assert(recovered.distance_to(logical)<.01,"Actual camera ray must recover the same authoritative stair point")
					var host: Vector2=renderer.project_host(logical)
					var actual: Vector2=renderer.view_projection.render_to_host(renderer.camera_3d.unproject_position(support),Rect2(renderer.display.position,renderer.display.size))
					assert(host.distance_to(actual)<.01)
					if renderer.ground_projection(support).distance_to(logical)>1: legacy_inverse_misses+=1
					var original_point: Vector2=logical
					for velocity in [along*80,-along*80,Vector2.ZERO]:
						var result: Dictionary=traversal.sample(logical,velocity,.033)
						assert(absf(float(result.groundHeight)-support.z)<.001)
						assert(logical==original_point and absf(float(result.bodyLift))<=1.6)
						if velocity==Vector2.ZERO or str(connector.type)=="ramp": assert(is_zero_approx(float(result.bodyLift)))
					checks+=8
			actual_treads+=1
		var midpoint:=start.lerp(end,.125)
		var walking: Dictionary=traversal.sample(midpoint,along*80,.016)
		var paused: Dictionary=traversal.sample(midpoint,Vector2.ZERO,3,true)
		assert(paused.paused and paused.bodyLift==walking.bodyLift,"Pause must hold the pose instead of driving a timed stair bounce")
		traversal.set_reduced_motion(true)
		var reduced: Dictionary=traversal.sample(midpoint,along*80,.12)
		assert(is_zero_approx(float(reduced.bodyLift)) and reduced.groundHeight==walking.groundHeight)
		traversal.set_reduced_motion(false)
	for logical in [Vector2(1120,1230),Vector2(595,650),Vector2(370,430),Vector2(2295,125)]:
		var height: float=renderer.ground_height(logical)
		assert(renderer.ground_point(logical).distance_to(renderer.map_point(logical,height))<.001,"Ordinary floor embedding must be unchanged")
		checks+=1
	assert(legacy_inverse_misses>20,"The fixture must exercise stair points where the old inverse is actually wrong")
	assert(actual_treads==12,"Expected3 actual stairs plus the original dock ramp")
	player.position=Vector2(1370,805)
	player.swim_sprite.set_appearance("male_nusantara")
	player.swim_sprite.set_locomotion(Vector2(0,-80),.016)
	player.swim_sprite.animate(true,false,1,0)
	player.traversal_state=player.surface_traversal.sample(player.position,Vector2(0,-80),.016)
	renderer._process(0)
	var grounding: Dictionary=renderer.actors_3d.counts.playerGrounding
	var support: Vector3=renderer.ground_point(player.position)
	var actual_foot:=Vector3(grounding.visualFoot[0],grounding.visualFoot[1],grounding.visualFoot[2])
	assert(actual_foot.distance_to(support+Vector3(0,0,float(player.traversal_state.bodyLift)))<.01,"Actual rendered Nala must consume the explicit stair lift rather than discard it while resolving the atlas pivot")
	assert(float(grounding.visualLift)>1.5 and float(grounding.visualLift)<=1.6)
	var position_before: Vector2=player.position
	var distance_before: float=player.swim_sprite.locomotion_state().distance
	player.frozen=true
	var idle_visual_y:=INF
	for tick in range(5):
		player._physics_process(.12)
		renderer._process(.12)
		if tick==0: idle_visual_y=player.swim_sprite.position.y
		else: assert(player.swim_sprite.position.y==idle_visual_y,"Frozen atlas placement must not accumulate the traversal offset each physics frame")
	assert(player.position==position_before and player.swim_sprite.locomotion_state().distance==distance_before,"Pause must preserve accepted position and distance-driven gait")
	assert(renderer.actors_3d.counts.playerGrounding.visualLift==grounding.visualLift)
	assert(JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})==original)
	print("STAIR FOOT GROUNDING PASS: ",checks," actual highest-triangle/height/logical inverse/host projection samples; ",actual_treads," real treads/ramp; ",flat_floor_normals," actual upward flat terrain vertex normals; ascent/descent/idle/pause/reduced/lowdelta; ordinary floor and authoritative state unchanged")
	stage.free()
	quit()
