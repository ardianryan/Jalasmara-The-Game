extends SceneTree

var renderer:Node2D
var person:Node2D
var collision:Node2D
var rig:Node3D
var clock:Node
var checked:=0
var max_drift:=0.0
var max_join_error:=0.0
var max_pelvis:=0.0
var _previous:Dictionary={}
var _triangles:Dictionary={}
const GRID:=64.0
var _capture:=false
var _frame:=0
var _recording:Dictionary={}
var measured_grips:=0
var max_grip_error:=0.0
const OUTPUT:="res://../artifacts/godot/06b-body-contact"

func _initialize() -> void:
	call_deferred("run")

func _index_floor_meshes() -> void:
	for instance in renderer.get("_geometry").find_children("*","MeshInstance3D",true,false):
		for surface in range(instance.mesh.get_surface_count()):
			var arrays:Array=instance.mesh.surface_get_arrays(surface)
			var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			var count:=indices.size() if not indices.is_empty() else vertices.size()
			for offset in range(0,count,3):
				var triangle:Array[Vector3]=[]
				for corner in range(3): triangle.append(instance.to_global(vertices[indices[offset+corner] if not indices.is_empty() else offset+corner]))
				if absf((triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).normalized().z)<.2: continue
				var low:=Vector2(minf(triangle[0].x,minf(triangle[1].x,triangle[2].x)),minf(triangle[0].y,minf(triangle[1].y,triangle[2].y)))
				var high:=Vector2(maxf(triangle[0].x,maxf(triangle[1].x,triangle[2].x)),maxf(triangle[0].y,maxf(triangle[1].y,triangle[2].y)))
				for x in range(floori(low.x/GRID),floori(high.x/GRID)+1):
					for y in range(floori(low.y/GRID),floori(high.y/GRID)+1):
						var key:=Vector2i(x,y)
						if not _triangles.has(key): _triangles[key]=[]
						_triangles[key].append(triangle)

func _mesh_contact(sole:Vector3) -> bool:
	var key:=Vector2i(floori(sole.x/GRID),floori(sole.y/GRID))
	for triangle in _triangles.get(key,[]):
		if Geometry3D.segment_intersects_triangle(sole+Vector3(0,0,1.2),sole-Vector3(0,0,1.2),triangle[0],triangle[1],triangle[2])!=null: return true
	return false

func _measure() -> void:
	var pose:Dictionary=rig.pose_snapshot()
	assert(pose.has("contacts"),"Actual LandWorld Ujang must use the contact pilot")
	var contact:Dictionary=pose.contacts
	assert(contact.reachValid,"Fixed-length legs cannot be accepted by hiding unreachable contacts: "+str(contact.requestedPelvisDrop))
	assert(float(contact.maxLengthError)<.02)
	max_pelvis=maxf(max_pelvis,float(contact.pelvisDrop))
	for side in ["left","right"]:
		var entry:Dictionary=contact.feet[side]
		var foot:Sprite3D=rig.sprites["foot_"+side]
		var image:Image=foot.texture.get_image()
		if image.is_compressed(): image.decompress()
		var bottom:=image.get_used_rect().end.y-1
		var total:=0.0
		var count:=0
		for x in range(image.get_width()):
			if image.get_pixel(x,bottom).a>=.5: total+=x+.5; count+=1
		var actual_sole:=foot.to_global(Vector3(total/maxi(1,count)-image.get_width()*.5,image.get_height()*.5-bottom-1,0))
		assert(actual_sole.distance_to(entry.sole)<.01,"Measure real alpha sole, not only a declared debug socket")
		var upper:Sprite3D=rig.sprites["upper_leg_"+side]
		var lower:Sprite3D=rig.sprites["lower_leg_"+side]
		for limb in [upper,lower]:
			assert(absf(limb.global_basis.y.length()-1.0)<.001,"Limb pixels must retain fixed length; no scale stretching")
		var knee_a:=upper.global_position-upper.global_basis.y*upper.texture.get_height()*.5
		var knee_b:=lower.global_position+lower.global_basis.y*lower.texture.get_height()*.5
		var error:=knee_a.distance_to(knee_b)
		max_join_error=maxf(max_join_error,error)
		assert(error<.02,"Actual thigh/calf quad endpoints must share the same knee")
		if entry.grounded:
			assert(_mesh_contact(actual_sole),"Planted opaque sole must meet an actual rendered floor/tread triangle: "+str(actual_sole)+" actor "+str(person.position))
			if _previous.has(side) and _previous[side].grounded and Vector3(_previous[side].plant).distance_to(entry.plant)<.001:
				var drift:=actual_sole.distance_to(_previous[side].sole)
				max_drift=maxf(max_drift,drift)
				assert(drift<.02,"Stance sole must stay locked in WORLD while the actor advances")
		_previous[side]={"sole":actual_sole,"plant":entry.plant,"grounded":entry.grounded}
	checked+=1

func _step(to:Vector2,delta:=.1,talking:=false) -> void:
	var previous:Vector2=person.position
	var next:=previous.move_toward(to,26.0*delta)
	assert(collision.is_walkable(next),"Diagnostic route must use real legal hub geometry")
	person.position=next
	person.moved_velocity=(next-previous)/delta
	person.set("_elapsed",float(person.get("_elapsed"))+delta)
	person.get("_body_animation").update(delta,person.moved_velocity,false,false,talking,talking,clock.reduced_motion,"fishing")
	renderer.actors_3d.update_actors(delta)
	_measure()
	if _capture:
		await process_frame
		await RenderingServer.frame_post_draw
		renderer.viewport_3d.get_texture().get_image().save_png(OUTPUT+"/%04d.png"%_frame)
		if _frame%40==0:
			root.get_texture().get_image().save_png(OUTPUT+"/scene-%04d.png"%_frame)
			_recording[str(_frame)]={"actor":[person.position.x,person.position.y],"reduced":clock.reduced_motion,"pose":rig.pose_snapshot()}
		_frame+=1

func _work_grip_checks() -> void:
	var animation=person.get("_body_animation")
	var palm_meta:Dictionary=rig.data.parts.hand_rod_west
	var palm:Sprite3D=rig.sprites.hand_rod_west
	var art:Image=palm.texture.get_image()
	if art.is_compressed(): art.decompress()
	assert(art.get_pixel(3,3).a>.5,"Annotated grip pixel must belong to an opaque curled finger")
	var activities=renderer.actors_3d.get("_activities")
	for reduced in [false,true]:
		clock.reduced_motion=reduced
		for clip in ["start_work","work_loop","end_work"]:
			for time in ([.05,.4,.79] if clip=="start_work" else [.85,1.1,1.65,2.0,6.9,7.8,8.7] if clip=="work_loop" else [.05,.3,.64]):
				animation.clip=clip
				animation.elapsed=time
				animation.direction="west"
				animation.set("_work_kind","fishing")
				person.moved_velocity=Vector2.ZERO
				renderer.actors_3d.update_actors(.1)
				var entry:Dictionary=activities.get("_actors")[person.get_instance_id()]
				assert(entry.root.visible and palm.visible)
				var rod:MeshInstance3D=entry.lines[0]
				var a:=rod.to_global(Vector3(0,-.5,0))
				var b:=rod.to_global(Vector3(0,.5,0))
				var pixel:=Vector2(float(palm_meta.gripPixel[0]),float(palm_meta.gripPixel[1]))
				var point:=palm.to_global(Vector3(pixel.x-art.get_width()*.5,art.get_height()*.5-pixel.y,0))
				var parameter:=clampf((point-a).dot(b-a)/(b-a).length_squared(),0,1)
				var actual:=point.distance_to(a.lerp(b,parameter))
				assert(actual<.1,"Authored fist must meet the actual independent rod cylinder: "+str(actual))
				assert(absf(float(entry.gripMeasurement.distance)-actual)<.001)
				assert(float(entry.gripMeasurement.axisDegrees)<.05)
				max_grip_error=maxf(max_grip_error,actual)
				measured_grips+=1
				if _capture:
					await process_frame
					await RenderingServer.frame_post_draw
					renderer.viewport_3d.get_texture().get_image().save_png(OUTPUT+"/grip-%s-%s-%s.png"%[reduced,clip,time])
	animation.clip="idle"
	animation.direction="north"
	renderer.actors_3d.update_actors(.1)
	assert(rig.sprites.head_back.visible and rig.sprites.torso_back.visible)
	assert(not rig.sprites.head.visible and not rig.sprites.torso.visible)
	assert(is_equal_approx(rig.sprites.head_back.position.x,0.0),"Authored rear head centre must not inherit the front nose offset")
	assert(person.get_meta("body_grip",{}).is_empty() and person.get_meta("body_rod",{}).is_empty(),"Leaving work must clear stale independent prop anchors")
	if _capture:
		for direction in ["south","east","north","west"]:
			animation.direction=direction
			animation.clip="walk"
			for frame in range(4):
				person.moved_velocity=Vector2.ZERO
				animation.distance=frame*6.25
				renderer.actors_3d.update_actors(.1)
				await process_frame
				await RenderingServer.frame_post_draw
				renderer.viewport_3d.get_texture().get_image().save_png(OUTPUT+"/art-%s-%s.png"%[direction,frame])

func run() -> void:
	_capture=OS.get_environment("UJANG_CAPTURE")=="1"
	if _capture:
		assert(DisplayServer.get_name()!="headless")
		root.size=Vector2i(1440,810)
		DirAccess.make_dir_recursive_absolute(OUTPUT)
	var state:Node=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var before:=JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})
	clock=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=false
	clock.reduced_motion=false
	root.get_node("RenderQuality").set_profile("balanced",false)
	var scene:=Node2D.new()
	root.add_child(scene)
	var player:=Node2D.new()
	scene.add_child(player)
	player.position=Vector2(1120,1230)
	var camera:=Camera2D.new()
	camera.position=Vector2(900,1360) if _capture and OS.get_environment("UJANG_ART_ONLY")=="1" else Vector2(1120,1250)
	camera.zoom=Vector2(1.5,1.5)
	scene.add_child(camera)
	camera.force_update_scroll()
	collision=load("res://scripts/land/LandCollision.gd").new()
	collision.configure(state.world.landMaps.hub)
	scene.add_child(collision)
	person=load("res://scripts/HubActor.gd").new()
	person.actor_name="Mang Ujang"
	person.activity_kind="fishing"
	person.position=Vector2(900,1360)
	person.walkable=Callable(collision,"is_walkable")
	person.set_meta("land_hidden",true)
	scene.add_child(person)
	person.set_process(false)
	for profile in state.world.surface_hub.residents:
		if profile.name=="Mang Ujang": person.configure_activity(profile)
	clock.visual_minutes=600
	clock.elapsed_seconds=0
	person.call("_process",1.0)
	renderer=load("res://scripts/land/LandWorld3D.gd").new()
	scene.add_child(renderer)
	renderer.setup(scene,player,camera,"hub")
	renderer.set_process(false)
	await process_frame
	renderer.call("_process",.1)
	rig=renderer.actors_3d.get("_body_rigs")[person.get_instance_id()]
	_index_floor_meshes()
	var activities:Dictionary=renderer.actors_3d.get("_activities").debug_status()
	if activities.gripMeasurements["Mang Ujang"].status=="measured":
		assert(float(activities.gripErrors["Mang Ujang"])<.1)
	else:
		assert(not activities.gripErrors.has("Mang Ujang"),"Unmeasured directional grip must not inherit a socket-derived contact value")
	await _work_grip_checks()
	if OS.get_environment("UJANG_ART_ONLY")=="1":
		print("UJANG ART PASS 26 independent west rod contact poses max error=",max_grip_error,"; north centres; 16 direction stills are artwork review, not four authored directions or locomotion proof")
		scene.free()
		quit()
		return
	person.get("_body_animation").begin_departure()
	for tick in range(8): await _step(person.position)
	# Ujang's real commute, followed by a diagnostic traversal of real authored
	# dock/terrace stairs. This does not alter his production schedule or anchors.
	var points:Array[Vector2]=[Vector2(900,1360),Vector2(1120,1360),Vector2(1210,1250),Vector2(1120,1230),Vector2(1120,1190),Vector2(1120,1125),Vector2(1120,1190),Vector2(1120,1230),Vector2(1210,1250),Vector2(1120,1360),Vector2(900,1360)]
	for reduced in [false,true]:
		clock.reduced_motion=reduced
		for target in points:
			while person.position.distance_to(target)>.01: await _step(target)
			for tick in range(4): await _step(person.position)
			var stopped:float=rig.pose_snapshot().contacts.phaseDistance
			for tick in range(4): await _step(person.position,.1,true)
			assert(person.body_animation_state().clip=="interact")
			assert(rig.pose_snapshot().contacts.phaseDistance==stopped)
	var hit_edge:=false
	for attempt in range(60):
		var proposed:Vector2=person.position.move_toward(Vector2(820,1360),2.6)
		if not collision.is_walkable(proposed):
			hit_edge=true
			var blocked_at:Vector2=person.position
			var stopped_phase:float=rig.pose_snapshot().contacts.phaseDistance
			for tick in range(8): await _step(person.position)
			assert(person.position==blocked_at and person.moved_velocity==Vector2.ZERO)
			assert(rig.pose_snapshot().contacts.phaseDistance==stopped_phase)
			assert(not person.body_animation_state().events.has("step"))
			break
		await _step(proposed)
	assert(hit_edge,"Must actually reach the authored dock/water collision boundary")
	assert(checked>500 and max_pelvis<=8)
	assert(rig.pose_snapshot().gripMeasurement.status=="inactive")
	assert(JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})==before)
	assert(measured_grips==26)
	print("UJANG CONTACT PASS actual3/4renderer: ",checked," legal26unit/s steps, alpha-sole world drift=",max_drift," knee join=",max_join_error," bounded pelvis=",max_pelvis,"; fixed pixel lengths, rendered floor/tread triangles, reduced/stop/turn; ",measured_grips," authored west grip poses max error=",max_grip_error,"; no actor root motion/world mutation")
	if _capture: FileAccess.open(OUTPUT+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(_recording,"  "))
	scene.free()
	quit()
