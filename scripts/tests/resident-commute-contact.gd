extends SceneTree

const GRID:=64.0
var renderer:Node2D
var source:Node2D
var collision:Node2D
var clock:Node
var actor:Node2D
var rig:Node3D
var triangles:Dictionary={}
var previous_feet:Dictionary={}
var checked:=0
var stair_samples:=0
var ramp_samples:=0
var max_drop:=0.0
var max_drift:=0.0
var phase:="setup"
var failed:=false
var started:=0
var paused_once:=false
var atlas:Image
var reports:Array=[]

func _initialize() -> void:
	_run.call_deferred()

func _check(value:bool,message:String) -> bool:
	if value: return true
	failed=true
	var details:Dictionary={"phase":phase,"message":message,"checked":checked,"stairSamples":stair_samples,"rampSamples":ramp_samples,"resident":str(actor.resident_id) if is_instance_valid(actor) else "","at":actor.position if is_instance_valid(actor) else Vector2.ZERO,"activity":actor.activity_state() if is_instance_valid(actor) else {},"pose":rig.pose_snapshot() if is_instance_valid(rig) else {}}
	FileAccess.open("res://../.runtime/resident-commute-failure.json",FileAccess.WRITE).store_string(JSON.stringify(details,"  "))
	printerr("RESIDENT COMMUTE FAILED: ",JSON.stringify(details))
	quit(1)
	return false

# Same actual emitted-mesh intersection proof as the accepted Ujang fixture.
func _index_floor() -> void:
	for instance in renderer._geometry.find_children("*","MeshInstance3D",true,false):
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
						if not triangles.has(key): triangles[key]=[]
						triangles[key].append(triangle)

func _mesh_contact(sole:Vector3) -> bool:
	for triangle in triangles.get(Vector2i(floori(sole.x/GRID),floori(sole.y/GRID)),[]):
		if Geometry3D.segment_intersects_triangle(sole+Vector3(0,0,1.2),sole-Vector3(0,0,1.2),triangle[0],triangle[1],triangle[2])!=null: return true
	return false

func _pixel(name:String,pixel:Array) -> Vector3:
	var part:Dictionary=rig.data.parts[name]
	var rect:Array=part.rect
	var bounds:Array=part.sourceBounds
	var unit:=Vector3((float(pixel[0])-float(bounds[0]))/float(rect[2])-.5,.5-(float(pixel[1])-float(bounds[1]))/float(rect[3]),0)
	var transform:Transform3D=rig._part_transforms[name]
	if DisplayServer.get_name()!="headless":
		var actual:Transform3D=rig.body_mesh.multimesh.get_instance_transform(int(rig.sprites[name]))
		if not _check(actual.is_equal_approx(transform),"Native quad readback differs from submitted geometry"): return Vector3.ZERO
		transform=actual
	return rig.to_global(transform*unit)

func _measure() -> bool:
	var pose:Dictionary=rig.pose_snapshot()
	var contacts:Dictionary=pose.contacts
	if not _check(bool(contacts.feet.left.grounded) or bool(contacts.feet.right.grounded),"Both feet lost support"): return false
	if not _check(int(contacts.discontinuityResets)==0,"Continuous 2.6-unit commute must not be treated as teleport/reanchored"): return false
	if not _check(rig.global_basis.determinant()>0,"No anatomical mirror for view-relative movement"): return false
	for link in pose.links.values():
		if not _check(absf(link.start.distance_to(link.joint)-float(link.first))<.04,"First bone stretched in 3D"): return false
		if not _check(absf(link.joint.distance_to(link.end)-float(link.second))<.04,"Second bone stretched in 3D"): return false
	for side in ["left","right"]:
		var leg:Dictionary=pose.links["leg_"+side]
		for segment in ["upper_leg_","lower_leg_"]:
			var name:String=segment+side
			if bool(rig.data.parts[name].hiddenByAuthoredClothing): continue
			var endpoints:Array=rig.data.parts[name].bone
			var expected:Array=[leg.start,leg.joint] if segment=="upper_leg_" else [leg.joint,leg.end]
			for endpoint in range(2):
				if not _check(_pixel(name,endpoints[endpoint]).distance_to(rig.to_global(expected[endpoint]))<.01,"Actual quad endpoints do not join hip/knee/ankle"): return false
		var foot:Dictionary=rig.data.parts["foot_"+side]
		var rect:Array=foot.rect
		var bounds:Array=foot.sourceBounds
		var bottom:=Vector2i(int(rect[0])+floori(float(foot.sole[0])-float(bounds[0])),int(rect[1])+int(rect[3])-1)
		if not _check(atlas.get_pixelv(bottom).a>.5,"Contact must originate on an actual opaque bottom pixel"): return false
		var sole:=_pixel("foot_"+side,foot.sole)
		var entry:Dictionary=contacts.feet[side]
		if not _check(sole.distance_to(entry.sole)<.01,"Actual opaque sole differs from physical contact"): return false
		if entry.grounded:
			if not _check(_mesh_contact(sole),"Planted original alpha sole misses emitted floor/tread triangles"): return false
			if previous_feet.has(side) and previous_feet[side].grounded and Vector3(previous_feet[side].plant).distance_to(entry.plant)<.001:
				var drift:=sole.distance_to(previous_feet[side].sole)
				max_drift=maxf(max_drift,drift)
				if not _check(drift<.02,"Stance sole drifted while actor advanced"): return false
		previous_feet[side]={"sole":sole,"plant":entry.plant,"grounded":entry.grounded}
		if not _check(_pixel("hand_"+side,rig.data.parts["hand_"+side].grip).distance_to(rig.hands[side])<.001,"Opaque palm lost held-item socket"): return false
	if not _check(rig._held.global_position.distance_to(rig.hands.right)<.001,"Held prop detached"): return false
	max_drop=maxf(max_drop,float(pose.pelvisDrop))
	if not _check(float(pose.pelvisDrop)<9*float(actor.body_scale),"Scaled child solve exceeds accepted pelvis bound"): return false
	for stair in renderer._stair_queries:
		if not preload("res://scripts/SurfaceTraversal.gd").connector_ground(stair,actor.position).is_empty():
			if str(stair.get("type","stairs"))=="stairs": stair_samples+=1
			else: ramp_samples+=1
	checked+=1
	return true

func _tick() -> bool:
	if not _check(Time.get_ticks_msec()-started<55000,"Bounded fixture runtime exceeded55seconds"): return false
	var previous:Vector2=actor.position
	actor._process(.1)
	if not _check(actor.position.distance_to(previous)<=2.601,"Actual scheduler teleported/exceeded26units persecond"): return false
	if not _check(collision.is_walkable(actor.position),"Actual route left floor/entered collider"): return false
	renderer.actors_3d.update_actors(.1)
	if not _measure(): return false
	if not paused_once and actor.moved_velocity.length()>.1 and absf(sin(float(rig.pose_snapshot().contacts.phaseDistance)/float(rig.pose_snapshot().contacts.stride)*TAU))>.2:
		paused_once=true
		var frozen:Dictionary=rig.pose_snapshot()
		var stopped:Vector2=actor.position
		clock.clock_paused=true
		for tick in range(3):
			actor._process(.1)
			renderer.actors_3d.update_actors(.1)
			if not _check(actor.position==stopped and rig.pose_snapshot()==frozen,"Mid-commute pause must preserve feet, arms and held prop"): return false
		clock.clock_paused=false
	return true

func _reach(profile:Dictionary,destination:String,raining:bool) -> bool:
	phase=destination+("-rain" if raining else "")
	clock.visual_minutes=float(profile.activity.endMinute)+1 if destination=="rest" else float(profile.activity.startMinute)+30
	clock.set("_server_rain",raining)
	clock.set("_rain_amount",.55 if raining else 0.0)
	clock._process(0)
	var point:Array=profile.activity[destination]
	var target:=Vector2(float(point[0]),float(point[1]))
	for tick in range(3500):
		if not _tick(): return false
		if actor.position.distance_to(target)<2 and str(actor.activity_state().phase)==destination:
			for settle in range(15):
				if not _tick(): return false
			return true
	return _check(false,"Actual work/rest/shelter route did not reach authored station")

func _run() -> void:
	started=Time.get_ticks_msec()
	var state:Node=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var immutable:=JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})
	clock=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=false
	clock.authoritative=true
	source=Node2D.new()
	root.add_child(source)
	collision=load("res://scripts/land/LandCollision.gd").new()
	source.add_child(collision)
	collision.configure(state.world.landMaps.hub)
	var player:=Node2D.new()
	source.add_child(player)
	player.position=Vector2(1320,650)
	var camera:=Camera2D.new()
	source.add_child(camera)
	renderer=load("res://scripts/land/LandWorld3D.gd").new()
	source.add_child(renderer)
	renderer.setup(source,player,camera,"hub")
	renderer.set_process(false)
	_index_floor()
	for profile in state.world.surface_hub.residents:
		if not profile.has("visual"): continue
		for reduced in [false,true]:
			clock.reduced_motion=reduced
			clock.clock_paused=false
			clock.set("_server_rain",false)
			clock.set("_rain_amount",0.0)
			clock.visual_minutes=float(profile.activity.startMinute)+30
			clock._process(0)
			actor=load("res://scripts/HubActor.gd").new()
			actor.actor_name=str(profile.name)
			actor.walkable=collision.is_walkable
			actor.configure_activity(profile)
			actor.position=Vector2(float(profile.activity.work[0]),float(profile.activity.work[1]))
			source.add_child(actor)
			actor.set_process(false)
			actor.visible=false
			renderer.actors_3d._scan()
			renderer.actors_3d.update_actors(0)
			rig=renderer.actors_3d._body_rig(actor)
			if not _check(rig!=null and rig.get_script().resource_path.ends_with("ResidentArtRig3D.gd"),"Production canonical resident helper is required"): return
			if atlas==null:
				atlas=rig._atlas.get_image()
				if atlas.is_compressed(): atlas.decompress()
			previous_feet.clear()
			paused_once=false
			phase="initial-work"
			for tick in range(15):
				if not _tick(): return
			var before:=checked
			if not _reach(profile,"rest",false): return
			if not _reach(profile,"work",false): return
			if not _reach(profile,"shelter",true): return
			reports.append({"id":str(profile.id),"reduced":reduced,"samples":checked-before,"resets":rig.pose_snapshot().contacts.discontinuityResets})
			actor.free()
			renderer.actors_3d._scan()
			renderer.actors_3d.update_actors(0)
			await process_frame
	if not _check(reports.size()==12 and stair_samples+ramp_samples>10,"All6 normal/reduced actual commutes must include emitted connector contacts"): return
	if not _check(immutable==JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive}),"Cosmetic commute changed canonical gameplay state"): return
	FileAccess.open("res://../.runtime/resident-commute-results.json",FileAccess.WRITE).store_string(JSON.stringify({"reports":reports,"samples":checked,"stairs":stair_samples,"ramps":ramp_samples,"maxPelvisDrop":max_drop,"maxStanceDrift":max_drift,"durationMs":Time.get_ticks_msec()-started},"  "))
	source.free()
	await process_frame
	print("RESIDENT COMMUTE PASS:6 actual HubActor work/rest/reverse/rain routes normal+reduced, ",checked," strict production rig poses, stairs",stair_samples," ramps",ramp_samples," opaque sole on actual mesh, fixed3D bones, stance lock, midwalk pause, no resets/teleport/world mutation")
	quit()
