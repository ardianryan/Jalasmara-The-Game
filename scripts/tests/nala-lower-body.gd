extends SceneTree

var renderer:Node2D
var player:CharacterBody2D
var clock:Node
var triangles:Array=[]
var checks:=0
var rejected:=0
var drift_max:=0.0
var length_max:=0.0
var previous:Dictionary={}
var frames:Array=[]
var capture:=false
const OUTPUT:="res://../artifacts/godot/overnight-nala-lower"

func _initialize() -> void: call_deferred("run")
func _check(valid:bool,message:String) -> bool:
	if not valid:
		push_error(message)
		quit(1)
	return valid

func _index_meshes() -> void:
	for instance in renderer.get("_geometry").find_children("*","MeshInstance3D",true,false):
		for surface in range(instance.mesh.get_surface_count()):
			var arrays:Array=instance.mesh.surface_get_arrays(surface)
			var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			for offset in range(0,indices.size() if not indices.is_empty() else vertices.size(),3):
				var triangle:Array[Vector3]=[]
				for corner in range(3): triangle.append(instance.to_global(vertices[indices[offset+corner] if not indices.is_empty() else offset+corner]))
				if absf((triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).normalized().z)>.2: triangles.append(triangle)

func _on_mesh(sole:Vector3) -> bool:
	for triangle in triangles:
		if Geometry3D.segment_intersects_triangle(sole+Vector3(0,0,.3),sole-Vector3(0,0,.3),triangle[0],triangle[1],triangle[2])!=null: return true
	return false

func _measure(label:String) -> void:
	var rig:Node3D=renderer.actors_3d.get("_nala_lower")
	var pose:Dictionary=renderer.actors_3d.counts.nalaLowerBody
	if not _check(bool(pose.get("enabled",false)),"Nala lower-body pilot missing "+label): return
	if not bool(pose.reachValid): rejected+=1
	if not _check(bool(pose.reachValid),"Unreachable Nala leg "+label+" at "+str(player.position)+" drop="+str(pose.requestedDropPixels)): return
	if not _check(not bool(pose.rootMotion),"Visual rig may not move actor root"): return
	for side in ["left","right"]:
		var entry:Dictionary=pose.contacts.feet[side]
		var foot:Sprite3D=rig.get("_parts")[side+"_foot"]
		var direction:Dictionary=rig.get("_data").views[pose.direction]
		var sole:Array=direction.legs[side].solePixel
		var actual:=foot.to_global(Vector3(float(sole[0])-foot.texture.get_width()*.5,foot.texture.get_height()*.5-float(sole[1]),0))
		if not _check(actual.distance_to(entry.sole)<.002,"Actual foot pixel must meet world sole "+label): return
		for name in ["thigh","shin"]:
			var bone:Sprite3D=rig.get("_parts")[side+"_"+name]
			var first:=bone.to_global(Vector3(0,-bone.texture.get_height()*.5,0))
			var second:=bone.to_global(Vector3(0,bone.texture.get_height()*.5,0))
			var expected:float=entry.lengths[0 if name=="thigh" else 1]
			var error:=absf(first.distance_to(second)-expected)
			length_max=maxf(length_max,error)
			if not _check(error<.003,"Actual Sprite3D bone length changed "+label): return
		if entry.grounded:
			if not _check(_on_mesh(actual),"Actual sole misses rendered triangle "+label+" side="+side+" sole="+str(actual)): return
			if previous.has(side) and previous[side].grounded and Vector3(previous[side].plant).distance_to(entry.plant)<.001:
				var drift:=actual.distance_to(previous[side].actual)
				drift_max=maxf(drift_max,drift)
				if not _check(drift<.002,"Planted source-pixel sole slides "+label): return
		previous[side]={"grounded":entry.grounded,"plant":entry.plant,"actual":actual}
	checks+=1

func _tick(target:Vector2,delta:float,label:String) -> void:
	var before:=player.position
	player.position=target
	player.velocity=(target-before)/delta
	var visual:Sprite2D=player.swim_sprite
	visual.call("set_locomotion",player.velocity,delta,renderer.visual_locomotion(before,target,delta))
	visual.call("animate",player.velocity.length()>.1,false,1,0)
	renderer.call("_process",delta)
	_measure(label)
	await process_frame
	if capture and checks%4==0:
		RenderingServer.force_draw(false)
		var index:=frames.size()
		renderer.viewport_3d.get_texture().get_image().save_png(OUTPUT+"/%04d.png"%index)
		frames.append({"frame":index,"case":label,"position":[target.x,target.y],"pose":renderer.actors_3d.counts.nalaLowerBody.duplicate(true)})

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
	if capture:
		root.size=Vector2i(1440,810)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
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
	player=load("res://scripts/Player.gd").new()
	stage.add_child(player)
	player.set_physics_process(false)
	player.hybrid_visual=true
	player.set_meta("nala_lower_body_pilot",true)
	player.position=Vector2(1000,1360)
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
	for outfit in ["daily","explorer"]:
		for reduced in [false,true]:
			clock.reduced_motion=reduced
			for heading in range(8):
				var label:=outfit+"/"+str(reduced)+"/"+str(heading)
				var origin:=Vector2(1000,1360)
				_reset_case(origin,outfit)
				await _tick(origin,1.0/30,label+" idle")
				var direction:=Vector2.from_angle(heading*PI*.25)
				for index in range(24): await _tick(origin+direction*(index+1)*2,1.0/30,label+" walk")
				for index in range(8): await _tick(player.position,1.0/30,label+" stop")
				var stopped:=player.position
				for index in range(12): await _tick(stopped-direction*(index+1)*2,1.0/30,label+" restart turn")
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
	if capture: FileAccess.open(OUTPUT+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(frames,"  "))
	print("NALA LOWER BODY PASS: ",checks," actual sprite sole/limb samples, 8 headings, daily/explorer, normal/reduced, stop/restart/turn, real stair triangles, pause; stance drift=",drift_max," limb error=",length_max," rejected=",rejected)
	stage.free()
	quit()
