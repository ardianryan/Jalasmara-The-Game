extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func _soil_hit(renderer:Node,point:Vector3) -> bool:
	for instance in renderer.get("_geometry").find_children("*","MeshInstance3D",true,false):
		for surface in range(instance.mesh.get_surface_count()):
			var arrays:Array=instance.mesh.surface_get_arrays(surface)
			var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			var count:=indices.size() if not indices.is_empty() else vertices.size()
			for offset in range(0,count,3):
				var triangle:Array[Vector3]=[]
				for corner in range(3): triangle.append(instance.to_global(vertices[indices[offset+corner] if not indices.is_empty() else offset+corner]))
				var hit=Geometry3D.segment_intersects_triangle(point+Vector3(0,0,.2),point-Vector3(0,0,.2),triangle[0],triangle[1],triangle[2])
				if hit!=null: return true
	return false

func _transforms(entry:Dictionary) -> Array:
	var result:Array=[]
	for instance in entry.lines+entry.boxes: result.append(instance.transform)
	return result

func run() -> void:
	var state:Node=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var before:=JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})
	var clock:Node=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.visual_minutes=600
	clock.elapsed_seconds=0
	clock.clock_paused=false
	clock.reduced_motion=false
	root.get_node("RenderQuality").set_profile("low",false)
	var scene:=Node2D.new()
	root.add_child(scene)
	var player:=Node2D.new()
	scene.add_child(player)
	player.position=Vector2(1120,1230)
	var camera:=Camera2D.new()
	camera.position=Vector2(1720,520)
	scene.add_child(camera)
	camera.force_update_scroll()
	var collision:Node2D=load("res://scripts/land/LandCollision.gd").new()
	collision.configure(state.world.landMaps.hub)
	scene.add_child(collision)
	var people:Array[Node2D]=[]
	for name in ["Bu Darmi","Yu Sari"]:
		var profile:Dictionary={}
		if name=="Bu Darmi": profile=state.world.surface_hub.districtActivities[name].duplicate(true)
		else:
			for entry in state.world.surface_hub.residents:
				if entry.name==name: profile=entry.duplicate(true)
		profile["name"]=name
		var person:Node2D=load("res://scripts/HubActor.gd").new()
		person.actor_name=name
		person.position=Vector2(float(profile.activity.work[0]),float(profile.activity.work[1]))
		person.walkable=Callable(collision,"is_walkable")
		person.set_meta("land_hidden",true)
		scene.add_child(person)
		person.configure_activity(profile)
		person.set_process(false)
		people.append(person)
	var renderer:Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	scene.add_child(renderer)
	renderer.setup(scene,player,camera,"hub")
	renderer.set_process(false)
	await process_frame
	renderer.call("_process",.1)
	var activities:Node=renderer.actors_3d.get("_activities")
	var water_samples:=0
	for person in people:
		var origin:Vector2=person.position
		for reduced in [false,true]:
			clock.reduced_motion=reduced
			for frame in range(120):
				person.call("_process",.1)
				renderer.actors_3d.update_actors(.1)
				var entry:Dictionary=activities.get("_actors")[person.get_instance_id()]
				assert(person.position==origin and person.moved_velocity==Vector2.ZERO)
				assert(not entry.has("gripError"),"A socket-derived unannotated grip cannot claim zero error")
				assert(entry.gripMeasurement.status=="unknown")
				if str(person.actor_name)=="Bu Darmi":
					var target:Dictionary=entry.wateringTarget
					assert(target.garden=="kebun_darmi" and int(target.bed)==0)
					var point:Vector3=target.point
					assert(is_equal_approx(point.x,1836.75) and is_equal_approx(point.z,128))
					for index in range(1,6):
						var drop:MeshInstance3D=entry.boxes[index]
						assert(drop.visible==(person.body_animation_state().workPhase=="pour" and not reduced))
						assert(drop.position.z>=point.z-.001,"Water must approach the soil from above, not dive through it and reappear")
						if drop.visible: water_samples+=1
					if frame==30 and not reduced:
						assert(_soil_hit(renderer,point),"New destination must meet emitted soil mesh geometry")
						var feet:Vector3=renderer.map_point(person.position,renderer.ground_height(person.position))
						assert(not _soil_hit(renderer,feet+Vector3(95,0,32)),"Original miss must remain reproducible against actual geometry")
			clock.clock_paused=true
			var paused:Dictionary=activities.get("_actors")[person.get_instance_id()]
			var pose:=_transforms(paused)
			var elapsed:float=person.body_animation_state().elapsed
			for frame in range(5):
				person.call("_process",.1)
				renderer.actors_3d.update_actors(.1)
			assert(person.body_animation_state().elapsed==elapsed and _transforms(paused)==pose,"Clock pause must freeze the working tool and drops")
			clock.clock_paused=false
		var animation=person.get("_body_animation")
		animation.clip="walk"
		animation.direction="east"
		renderer.actors_3d.update_actors(.1)
		var hidden:Dictionary=activities.get("_actors")[person.get_instance_id()]
		assert(not hidden.root.visible and not hidden.has("gripError") and hidden.gripMeasurement.status=="inactive")
	assert(renderer.debug_status().azimuthDegrees==-45,"Tool/rig coverage must use the actual left runtime camera")
	var facing_checks:=0
	for person in people:
		for index in range(4):
			var wanted:=Vector2.RIGHT.rotated(index*PI*.5)
			person.moved_velocity=renderer.input_motion(wanted,person.position)*20
			renderer.actors_3d.update_actors(.1)
			var rig: Node3D=renderer.actors_3d._body_rigs[person.get_instance_id()]
			assert(rig.pose_snapshot().direction==["east","south","west","north"][index],"Layered worker facing must agree with actual projected movement")
			var native_motion: Vector2=renderer.camera_3d.unproject_position(renderer.map_point(person.position+person.moved_velocity,renderer.ground_height(person.position)))-renderer.camera_3d.unproject_position(renderer.map_point(person.position,renderer.ground_height(person.position)))
			assert(native_motion.normalized().dot(wanted)>.999)
			facing_checks+=1
		person.moved_velocity=Vector2.ZERO
	assert(facing_checks==8)
	# Reproduce the last authored Darmi commute edge, then enter work without
	# changing its logical cardinal label: screen facing must turn to the soil.
	for person in people:
		if str(person.actor_name)!="Bu Darmi": continue
		var animation=person.get("_body_animation")
		person.moved_velocity=Vector2(370,-115)
		animation.clip="walk"
		animation.direction="east"
		renderer.actors_3d.update_actors(.1)
		var rig: Node3D=renderer.actors_3d._body_rigs[person.get_instance_id()]
		assert(rig.pose_snapshot().direction=="north")
		person.moved_velocity=Vector2.ZERO
		animation.clip="start_work"
		renderer.actors_3d.update_actors(.1)
		assert(rig.pose_snapshot().direction=="east","Arrival at work must face the actual soil rather than keep the last projected commute vector")
	assert(water_samples>100)
	assert(JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})==before)
	print("VILLAGE TOOL CONTACT PASS: two original workers, 480 working samples, ",water_samples," visible droplets; actual soil hit and original miss; unknown unannotated grips; 8 actual left-camera view-facing checks; pause/reduced/hidden state; no WORLD/economy mutation")
	scene.free()
	quit()
