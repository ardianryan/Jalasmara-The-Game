extends SceneTree

var renderer:Node2D
var player:CharacterBody2D
var collision:Node2D
var clock:Node
var triangles:Array=[]
var triangle_grid:Dictionary={}
const TRIANGLE_GRID:=64.0
var _last_floor_height:=-INF
var _last_floor_normal:=Vector3.ZERO
var _last_floor_triangle:Array=[]
var checks:=0
var rejected:=0
var drift_max:=0.0
var length_max:=0.0
var previous:Dictionary={}
var frames:Array=[]
var capture:=false
var last_delta:=0.0
var capture_stride:=4
var trace:Array=[]
var output:=""
var capture_log:FileAccess
var forward_checks:=0
var source_foot_vertices:Dictionary={}

func _sampled_world_arc(from:Vector2,to:Vector2) -> float:
	var previous_point:Vector3=renderer.ground_point(from)
	var total:=0.0
	for index in range(1,129):
		var point:Vector3=renderer.ground_point(from.lerp(to,float(index)/128.0))
		total+=Vector2(point.x-previous_point.x,point.y-previous_point.y).length()
		previous_point=point
	return total

func _forward_units() -> bool:
	var planner:=preload("res://scripts/NalaFootPlant.gd").new()
	planner.configure(renderer)
	var wrong_metric_cases:=0
	for profile in renderer.get("_stair_queries"):
		if str(profile.type)!="stairs": continue
		var tangent:Vector2=(Vector2(profile.end)-Vector2(profile.start)).normalized()
		for progress in [.08,.55,.92]:
			var at:Vector2=Vector2(profile.start).lerp(profile.end,float(progress))
			for sign in [-1.0,1.0]:
				for angle in [0.0,.27]:
					var heading:=tangent.rotated(float(angle))*float(sign)
					planner.set("_heading",heading)
					for distance in [6.0,24.0]:
						var target:Vector2=planner.call("_forward_point",at,float(distance))
						var actual:=_sampled_world_arc(at,target)
						if not _check(absf(actual-float(distance))<.03,"Forward shoe target changed world-distance units "+str(profile.id)+" at="+str(at)+" requested="+str(distance)+" actual="+str(actual)): return false
						var local:Vector3=renderer.ground_point(at+heading)-renderer.ground_point(at)
						var old_target:=at+heading*float(distance)/maxf(.001,Vector2(local.x,local.y).length())
						if absf(_sampled_world_arc(at,old_target)-float(distance))>.03: wrong_metric_cases+=1
						forward_checks+=1
	if not _check(wrong_metric_cases>0,"Forward-distance fixture did not cross a real connector metric boundary"): return false
	print("NALA FORWARD WORLD-ARC PASS ",forward_checks," actual-ground probes; old local metric rejects ",wrong_metric_cases)
	return true

func _initialize() -> void: call_deferred("run")
func _check(valid:bool,message:String) -> bool:
	if not valid:
		if is_instance_valid(renderer):
			var record:={"message":message,"checks":checks,"position":[player.position.x,player.position.y],"pose":renderer.actors_3d.counts.get("nalaLowerBody",{}),"recentTrace":trace,"actorPilot":player.get_meta("nala_lower_body_pilot",null),"physicalPilot":player.get_meta("nala_physical_walk_pilot",null),"rendererActive":renderer.active,"rendererBuilt":renderer.get("_built"),"actorTexture":player.get("swim_sprite").texture.resource_path}
			FileAccess.open("res://../.runtime/nala-lower-failure.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
			if not output.is_empty() and DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)):
				FileAccess.open(output+"/rejected.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
		push_error(message)
		quit(1)
	return valid

func _index_meshes() -> void:
	for instance in renderer.get("_geometry").find_children("*","MeshInstance3D",true,false):
		if not bool(instance.get_meta("foot_support",false)): continue
		for surface in range(instance.mesh.get_surface_count()):
			var arrays:Array=instance.mesh.surface_get_arrays(surface)
			var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			for offset in range(0,indices.size() if not indices.is_empty() else vertices.size(),3):
				var triangle:Array[Vector3]=[]
				for corner in range(3): triangle.append(instance.to_global(vertices[indices[offset+corner] if not indices.is_empty() else offset+corner]))
				if absf((triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).normalized().z)>.2:
					triangles.append(triangle)
					var low:=Vector2(minf(triangle[0].x,minf(triangle[1].x,triangle[2].x)),minf(triangle[0].y,minf(triangle[1].y,triangle[2].y)))
					var high:=Vector2(maxf(triangle[0].x,maxf(triangle[1].x,triangle[2].x)),maxf(triangle[0].y,maxf(triangle[1].y,triangle[2].y)))
					for x in range(floori(low.x/TRIANGLE_GRID),floori(high.x/TRIANGLE_GRID)+1):
						for y in range(floori(low.y/TRIANGLE_GRID),floori(high.y/TRIANGLE_GRID)+1):
							var key:=Vector2i(x,y)
							if not triangle_grid.has(key): triangle_grid[key]=[]
							triangle_grid[key].append(triangle)

func _on_mesh(sole:Vector3) -> bool:
	var highest:=-INF
	_last_floor_normal=Vector3.ZERO
	_last_floor_triangle=[]
	for triangle in triangle_grid.get(Vector2i(floori(sole.x/TRIANGLE_GRID),floori(sole.y/TRIANGLE_GRID)),[]):
		var hit=Geometry3D.ray_intersects_triangle(sole+Vector3(0,0,256),Vector3(0,0,-1),triangle[0],triangle[1],triangle[2])
		if hit!=null and float(hit.z)>highest:
			highest=float(hit.z)
			_last_floor_normal=(Vector3(triangle[1])-Vector3(triangle[0])).cross(Vector3(triangle[2])-Vector3(triangle[0])).normalized()
			if _last_floor_normal.z<0: _last_floor_normal=-_last_floor_normal
			_last_floor_triangle=[]
			for point in triangle: _last_floor_triangle.append([point.x,point.y,point.z])
	_last_floor_height=highest
	return absf(highest-sole.z)<.3

func _measure(label:String) -> void:
	var rig:Node3D=renderer.actors_3d.get("_nala_lower")
	var pose:Dictionary=renderer.actors_3d.counts.get("nalaLowerBody",{})
	trace.append({"case":label,"position":[player.position.x,player.position.y],"pose":pose.duplicate(true)})
	if trace.size()>16: trace.pop_front()
	if not _check(bool(pose.get("enabled",false)),"Nala lower-body pilot rejected "+label+" reason="+str(pose.get("reason",""))+" requestedDrop="+str(pose.get("requestedDropPixels",-1))): return
	if not bool(pose.reachValid): rejected+=1
	if not _check(bool(pose.reachValid),"Unreachable Nala leg "+label+" at "+str(player.position)+" drop="+str(pose.requestedDropPixels)): return
	if not _check(not bool(pose.rootMotion),"Visual rig may not move actor root"): return
	var upper:Sprite3D=rig.get("_parts").upper
	var vertical:float=renderer.camera_up().dot(Vector3(0,0,1))
	var actual_baseline:Vector3=upper.global_position-renderer.camera_up()*38+Vector3(0,0,(float(pose.pelvisDropPixels)-28.0)/vertical)
	if not _check(absf(actual_baseline.z-float(pose.contacts.bodyHeight))<.003,"Actual upper body disagrees with support transfer "+label): return
	if previous.has("body"):
		var travelled:=maxf(0,float(pose.contacts.acceptedDistance)-float(previous.body.distance))
		var allowance:float=(travelled if travelled>.00001 else last_delta*24.0)*float(pose.contacts.bodyTransferRate)+.003
		if not _check(absf(float(pose.contacts.bodyHeight)-float(previous.body.height))<=allowance,"Stair body baseline jumps across a riser "+label): return
	previous["body"]={"height":pose.contacts.bodyHeight,"distance":pose.contacts.acceptedDistance}
	var equipment:Node3D=renderer.actors_3d.get("_equipment")
	var full_body_anchor:Vector3=upper.global_position-renderer.camera_up()*26
	if not _check(equipment.global_position.distance_to(full_body_anchor)<.003,"Separate equipment must follow actual lowered torso "+label+" actualGap="+str(equipment.global_position.distance_to(full_body_anchor))): return
	for side in ["left","right"]:
		var entry:Dictionary=pose.contacts.feet[side]
		if str(pose.contacts.swingSide)==side and not entry.has("settlingTarget"):
			var plan:Dictionary=entry.get("treadPlan",entry.get("rampCurvePlan",{}))
			if not plan.is_empty():
				if not _check(bool(plan.valid) and is_finite(float(plan.curveSpeedBound)) and float(plan.curveSpeedBound)<=4.9,"Invalid terrain curve budget accepted "+label): return
				var expected_type:="ramp_support_profile" if bool(entry.get("fixedRampTarget",false)) else "stair_clearance"
				if bool(entry.get("fixedTreadTarget",false)) and str(plan.curveType)=="stair_swept_support":
					expected_type="stair_swept_support"
					if not _check(bool(plan.get("sweptSupportMode",{}).get("supported",false)) and plan.get("knots",[]).size()>=2,"Swept stair path lacks its original geometry "+label): return
				if not _check(str(plan.curveType)==expected_type,"Terrain bound does not match actual path type "+label): return
				if not _check(absf(float(plan.distance)-float(pose.contacts.landingDistance))<.00001 and Vector3(plan.fromWorld).distance_to(entry.fromWorld)<.003 and Vector3(plan.toWorld).distance_to(entry.toWorld)<.003,"Terrain curve budget is stale after reanchor/retarget "+label+" side="+side): return
		if entry.has("viewLandingFit") and entry.has("viewRotationPivot"):
			if not _check(bool(entry.viewLandingFit.supported) and str(entry.viewLandingFit.candidate)==str(entry.viewRotationPivot.nextDirection),"Source-view switch invalidates frozen original-foot landing "+label+" side="+side): return
		var foot:Sprite3D=rig.get("_parts")[side+"_foot"]
		entry["measuredFootBasis"]=[foot.global_basis.x,foot.global_basis.y,foot.global_basis.z]
		if not _check(absf(foot.global_basis.x.length()-1)<.003 and absf(foot.global_basis.y.length()-1.0/vertical)<.003 and absf(foot.global_basis.x.dot(foot.global_basis.y))<.003,"Original foot pixel dimensions sheared or stretched "+label+" side="+side): return
		var direction:Dictionary=rig.get("_data").views[str(entry.footDirection)]
		var sole:Array=direction.legs[side].solePixel
		var actual:=foot.to_global(Vector3(float(sole[0])-foot.texture.get_width()*.5,foot.texture.get_height()*.5-float(sole[1]),0))
		if not _check(actual.distance_to(entry.sole)<.002,"Actual foot pixel must meet world sole "+label): return
		var source_leg:Dictionary=direction.legs[side]
		var source_rect:Array=source_leg.parts.foot
		var ankle_pixel:=Vector2(float(source_leg.ankle[0])-float(source_rect[0]),float(source_leg.ankle[1])-float(source_rect[1]))
		var actual_ankle:=foot.to_global(Vector3(ankle_pixel.x-foot.texture.get_width()*.5,foot.texture.get_height()*.5-ankle_pixel.y,0))
		for operation in ["viewRotationPivot","planeRotationPivot"]:
			if not entry.has(operation): continue
			var recorded:Dictionary=entry[operation]
			var before:Array=recorded.before
			var after:Array=recorded.after
			if not _check(Vector3(float(before[0]),float(before[1]),float(before[2])).distance_to(Vector3(float(after[0]),float(after[1]),float(after[2])))<.003,"Shoe rotation changed ankle within its own planned pose "+label+" operation="+operation): return
		if entry.has("viewSupportContinuity"):
			var continuity:Dictionary=entry.viewSupportContinuity
			var before_height:float=float(continuity.previousSupport)+float(continuity.offsetBefore)*float(continuity.remainingProgress)
			var after_height:float=float(continuity.nextSupport)+float(continuity.offsetAfter)*float(continuity.remainingProgress)
			if not _check(absf(before_height-after_height)<.003,"Original shoe view changed its planned support trajectory "+label): return
		if entry.has("supportPlanTranslation"):
			var translation:Dictionary=entry.supportPlanTranslation
			var before:Array=translation.before
			var after:Array=translation.after
			var measured_delta:=Vector3(float(after[0])-float(before[0]),float(after[1])-float(before[1]),float(after[2])-float(before[2]))
			if not _check(measured_delta.distance_to(Vector3(0,0,float(translation.deltaZ)))<.003,"Support plan changed more than its declared vertical trajectory "+label): return
		if entry.has("rotationAnchorWorld"):
			var pivot:Array=entry.rotationAnchorWorld
			if not _check(actual_ankle.distance_to(Vector3(float(pivot[0]),float(pivot[1]),float(pivot[2])))<.003,"Airborne shoe view changed actual ankle pivot "+label): return
		if previous.has(side):
			var accepted:=maxf(0,float(pose.contacts.acceptedDistance)-float(previous[side].distance))
			var allowance:=accepted*5.0 if accepted>.00001 else last_delta*24.0
			if not _check(actual_ankle.distance_to(previous[side].ankle)<=allowance+.003,"Actual ankle jumps across terrain "+label+" side="+side): return
		for name in ["thigh","shin"]:
			var bone:Sprite3D=rig.get("_parts")[side+"_"+name]
			var first:=bone.to_global(Vector3(0,-bone.texture.get_height()*.5,0))
			var second:=bone.to_global(Vector3(0,bone.texture.get_height()*.5,0))
			var expected:float=entry.lengths[0 if name=="thigh" else 1]
			var error:=absf(first.distance_to(second)-expected)
			length_max=maxf(length_max,error)
			if not _check(error<.003,"Actual Sprite3D bone length changed "+label): return
		var endpoints:Array[Vector3]=[]
		var original_foot_ground_minimum:=INF
		var exact_centroid:=_on_mesh(actual)
		if entry.grounded:
			if not _check(exact_centroid,"Actual sole misses rendered triangle "+label+" side="+side+" sole="+str(actual)+" highest="+str(_last_floor_height)): return
		else:
			if not _check(is_finite(_last_floor_height) and actual.z>=_last_floor_height-.3,"Airborne sole enters actual terrain "+label+" side="+side): return
		entry["measuredOpaqueVertices"]=[]
		for pixel in direction.legs[side].soleEdgePixels:
			var endpoint:=foot.to_global(Vector3(float(pixel[0])-foot.texture.get_width()*.5,foot.texture.get_height()*.5-float(pixel[1]),0))
			endpoints.append(endpoint)
			var exact_endpoint:=_on_mesh(endpoint)
			original_foot_ground_minimum=minf(original_foot_ground_minimum,_last_floor_height)
			entry.measuredOpaqueVertices.append({"sourcePixel":pixel,"world":[endpoint.x,endpoint.y,endpoint.z],"actualTriangleHeight":_last_floor_height,"actualTriangleNormal":[_last_floor_normal.x,_last_floor_normal.y,_last_floor_normal.z],"actualTriangleVertices":_last_floor_triangle.duplicate(true)})
			if entry.grounded:
				if not _check(exact_endpoint,"Actual heel/toe source pixel misses tread "+label+" side="+side+" pixel="+str(pixel)+" highest="+str(_last_floor_height)): return
			else:
				if not _check(is_finite(_last_floor_height) and endpoint.z>=_last_floor_height-.3,"Airborne opaque heel/toe enters actual terrain "+label+" side="+side+" pixel="+str(pixel)+" highest="+str(_last_floor_height)): return
		var texture_id:=foot.texture.get_instance_id()
		if not source_foot_vertices.has(texture_id):
			var image:Image=foot.texture.get_image()
			if image.is_compressed(): image.decompress()
			var points:Dictionary={}
			for y in range(image.get_height()):
				for x in range(image.get_width()):
					if image.get_pixel(x,y).a<.5: continue
					for point in [Vector2(x,y),Vector2(x+1,y),Vector2(x+1,y+1),Vector2(x,y+1)]: points[point]=true
			source_foot_vertices[texture_id]=points.keys()
		entry["opaqueMaskVertexCount"]=source_foot_vertices[texture_id].size()
		for pixel in source_foot_vertices[texture_id]:
			var point:Vector3=foot.to_global(Vector3(float(pixel.x)-foot.texture.get_width()*.5,foot.texture.get_height()*.5-float(pixel.y),0))
			var contact:=_on_mesh(point)
			original_foot_ground_minimum=minf(original_foot_ground_minimum,_last_floor_height)
			var valid:bool=is_finite(_last_floor_height) and point.z>=_last_floor_height-.3
			if entry.grounded and absf(float(pixel.y)-float(sole[1]))<.0001: valid=contact
			if not valid:
				entry["failedOpaqueMaskVertex"]={"pixel":[pixel.x,pixel.y],"world":[point.x,point.y,point.z],"actualTriangleHeight":_last_floor_height,"actualTriangleNormal":[_last_floor_normal.x,_last_floor_normal.y,_last_floor_normal.z]}
				if not _check(false,"Original opaque foot-mask vertex enters/misses actual surface "+label+" side="+side+" pixel="+str(pixel)): return
		if pose.contacts.has("currentFootprintBodyTransfer"):
			var transfer:Dictionary=pose.contacts.currentFootprintBodyTransfer
			var support:Dictionary=transfer.footprints[side]
			var lowest:Dictionary=support.lowest
			var source_pixel:Vector2=lowest.pixel
			var rendered:Vector3=foot.to_global(Vector3(source_pixel.x-foot.texture.get_width()*.5,foot.texture.get_height()*.5-source_pixel.y,0))
			if not _check(rendered.distance_to(lowest.world)<.003,"Body support queried stale original-foot transform "+label+" side="+side): return
			if not _check(absf(float(support.height)-original_foot_ground_minimum)<.3,"Body support disagrees with actual original-mask triangle heights "+label+" side="+side): return
			if not _check(not bool(transfer.futureLandingUsed),"Body support must not report future landing as current contact "+label): return
		if entry.grounded:
			if previous.has(side) and previous[side].grounded and Vector3(previous[side].plant).distance_to(entry.plant)<.001:
				var drift:=actual.distance_to(previous[side].actual)
				drift_max=maxf(drift_max,drift)
				if not _check(drift<.002,"Planted source-pixel sole slides "+label): return
				for index in range(2):
					if not _check(endpoints[index].distance_to(previous[side].endpoints[index])<.002,"Planted heel/toe pixel rotates or slides "+label): return
		previous[side]={"grounded":entry.grounded,"plant":entry.plant,"actual":actual,"endpoints":endpoints if entry.grounded else [],"ankle":actual_ankle,"distance":pose.contacts.acceptedDistance}
	checks+=1

func _tick(target:Vector2,delta:float,label:String) -> void:
	if not _check(collision.is_walkable(target),"Fixture actor target left authoritative walkable floor "+label+" target="+str(target)): return
	last_delta=delta
	var before:=player.position
	player.position=target
	player.velocity=(target-before)/delta
	var visual:Sprite2D=player.swim_sprite
	visual.call("set_locomotion",player.velocity,delta,renderer.visual_locomotion(before,target,delta))
	visual.call("animate",player.velocity.length()>.1,false,1,0)
	renderer.call("_process",delta)
	_measure(label)
	await process_frame
	if capture and checks%capture_stride==0:
		RenderingServer.force_draw(false)
		var index:=frames.size()
		renderer.viewport_3d.get_texture().get_image().save_png(output+"/%04d.png"%index)
		frames.append({"frame":index,"case":label,"position":[target.x,target.y],"pose":renderer.actors_3d.counts.nalaLowerBody.duplicate(true)})
		capture_log.store_line(JSON.stringify(frames[-1]))
		capture_log.flush()

func _reset_case(at:Vector2,outfit:String) -> void:
	previous.clear()
	var old:Node3D=renderer.actors_3d.get("_nala_lower")
	if is_instance_valid(old): old.free()
	renderer.actors_3d.set("_nala_lower",null)
	player.position=at
	player.velocity=Vector2.ZERO
	player.swim_sprite.call("set_outfit",outfit)

func run() -> void:
	capture=OS.get_environment("NALA_LOWER_CAPTURE")=="1"
	capture_stride=clampi(int(OS.get_environment("NALA_LOWER_CAPTURE_STRIDE")) if OS.has_environment("NALA_LOWER_CAPTURE_STRIDE") else 4,1,24)
	if capture:
		root.size=Vector2i(1440,810)
		output=OS.get_environment("NALA_LOWER_OUTPUT") if OS.has_environment("NALA_LOWER_OUTPUT") else "res://../artifacts/godot/overnight-nala-lower-"+str(int(Time.get_unix_time_from_system()))
		if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)),"Capture output already exists; preserve prior native proof"): return
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
		capture_log=FileAccess.open(output+"/frames.jsonl",FileAccess.WRITE)
		var source_hashes:Dictionary={}
		for path in ["res://scripts/NalaFootPlant.gd","res://scripts/NalaLowerBody3D.gd","res://scripts/CharacterVisual.gd","res://scripts/land/LandActors3D.gd","res://../scripts/tests/nala-lower-body.gd"]: source_hashes[path]=FileAccess.get_sha256(path)
		FileAccess.open(output+"/source.json",FileAccess.WRITE).store_string(JSON.stringify({"files":source_hashes,"flatOnly":OS.get_environment("NALA_LOWER_FLAT_ONLY")=="1","captureStride":capture_stride,"nativeAcceptance":"pending visual review; never full gait by geometry alone"},"  "))
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var unchanged:=JSON.stringify({"world":state.world,"player":state.player})
	clock=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=false
	var stage:=Node2D.new()
	root.add_child(stage)
	collision=load("res://scripts/land/LandCollision.gd").new()
	collision.configure(state.world.landMaps.hub)
	stage.add_child(collision)
	player=load("res://scripts/Player.gd").new()
	stage.add_child(player)
	player.set_physics_process(false)
	player.hybrid_visual=true
	player.set_meta("nala_lower_body_pilot",true)
	player.position=Vector2(1000,1325)
	player.swim_sprite.call("set_appearance","male_nusantara")
	var camera:=Camera2D.new()
	camera.zoom=Vector2(1.5,1.5)
	stage.add_child(camera)
	renderer=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	renderer.setup(stage,player,camera,"hub")
	renderer.set_process(false)
	renderer.call("_process",0)
	_index_meshes()
	if not _forward_units(): return
	for outfit in ["daily","explorer"]:
		for reduced in [false,true]:
			clock.reduced_motion=reduced
			for heading in range(8):
				var label:String=outfit+"/"+str(reduced)+"/"+str(heading)
				var origin:=Vector2(1000,1325)
				_reset_case(origin,outfit)
				await _tick(origin,1.0/30,label+" idle")
				var direction:=Vector2.from_angle(heading*PI*.25)
				for index in range(24): await _tick(origin+direction*(index+1)*2,1.0/30,label+" walk")
				for index in range(8): await _tick(player.position,1.0/30,label+" stop")
				var stopped:=player.position
				var settled_pose:Dictionary=renderer.actors_3d.counts.nalaLowerBody
				if not _check(settled_pose.direction==settled_pose.desiredDirection,"Cutout facing failed to converge after walk+stop "+label): return
				for index in range(12): await _tick(stopped-direction*(index+1)*2,1.0/30,label+" restart turn")
	if OS.get_environment("NALA_LOWER_FLAT_ONLY")=="1":
		if capture: FileAccess.open(output+"/flat-results.json",FileAccess.WRITE).store_string(JSON.stringify(frames,"  "))
		print("NALA LOWER BODY FLAT ONLY PASS: ",checks," actual sprite samples; stairs and full natural gait NOT accepted")
		stage.free()
		quit()
		return
	var stairs:Array=state.world.landMaps.hub.stairs
	for stair in stairs:
		if str(stair.get("type","stairs"))!="stairs": continue
		var start:=Vector2(float(stair.path[0][0]),float(stair.path[0][1]))
		var end:=Vector2(float(stair.path[1][0]),float(stair.path[1][1]))
		for reverse in [false,true]:
			var a:=end if reverse else start
			var b:=start if reverse else end
			var label:="stairs/"+str(stair.id)+"/"+str(reverse)
			_reset_case(a,"daily")
			await _tick(a,1.0/30,label+" idle")
			var samples:=ceili(a.distance_to(b)/1.5)
			for index in range(samples): await _tick(a.lerp(b,float(index+1)/samples),1.0/30,label)
	var before_pose:Dictionary=renderer.actors_3d.counts.nalaLowerBody.duplicate(true)
	clock.clock_paused=true
	await _tick(player.position,.1,"pause")
	if not _check(renderer.actors_3d.counts.nalaLowerBody==before_pose,"Pause retains exact rig state"): return
	if not _check(JSON.stringify({"world":state.world,"player":state.player})==unchanged,"Visual candidate mutated server state"): return
	if capture: FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(frames,"  "))
	print("NALA LOWER BODY PASS: ",checks," actual sprite sole/limb samples, 8 headings, daily/explorer, normal/reduced, stop/restart/turn, real stair triangles, pause; stance drift=",drift_max," limb error=",length_max," rejected=",rejected)
	stage.free()
	quit()
