extends SceneTree

class ReferencePlayer extends Node2D:
	var swim_sprite:Sprite2D

var renderer:Node2D
var collision:Node2D
var people:Array[Node2D]=[]
var timer:=0.0
var measured:=0
var max_length_error:=0.0
var max_stance_drift:=0.0
var previous:Dictionary={}
var capture:=false
var frame:=0
var recording:Array=[]
var triangles:Array=[]
const OUTPUT:="res://../artifacts/godot/overnight-new-residents"
const SPECS:=[
	["npc_direktur_cakrawala","Direktur Pramudya","director",1.0,"briefcase","#EADBB5"],
	["npc_kid_bagas","Bagas","child",.68,"telescope","#DDB744"],
	["npc_kid_kinasih","Kinasih","child",.64,"snail_jar","#64A775"],
	["npc_kid_danu","Danu","child",.66,"bucket","#578C92"],
	["npc_kid_gito","Gito","child",.70,"slingshot","#6DA19D"],
	["npc_kid_cempaka","Cempaka","child",.62,"ladle","#D8BE8D"]]

func _initialize() -> void: call_deferred("run")

func _check(valid:bool,message:String) -> bool:
	if not valid:
		push_error(message)
		quit(1)
	return valid

func _transform(rig:Node3D,index:int) -> Transform3D:
	var emitted:Transform3D=rig.emitted_transform(index)
	# The dummy headless server returns identity; native also verifies real readback.
	if DisplayServer.get_name()=="headless": return emitted
	var actual:Transform3D=rig.batch.multimesh.get_instance_transform(index)
	_check(actual.is_equal_approx(emitted),"Actual native MultiMesh readback differs from emitted transform")
	return actual

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
		if Geometry3D.segment_intersects_triangle(sole+Vector3(0,0,1.2),sole-Vector3(0,0,1.2),triangle[0],triangle[1],triangle[2])!=null: return true
	return false

func _measure() -> void:
	for person in people:
		var rig:Node3D=renderer.actors_3d.get("_body_rigs")[person.get_instance_id()]
		var pose:Dictionary=rig.pose_snapshot()
		if not _check(pose.native and pose.id==person.resident_id,"Native profile identity mismatch"): return
		if not _check(not renderer.actors_3d.sprites["NPC_"+person.actor_name].visible,"New IDs must never display old adult atlas cells"): return
		if not _check(rig.batch.multimesh.visible_instance_count==int(pose.parts) and int(pose.parts)>20 and int(pose.drawBatches)==1,"Native resident batch/parts mismatch"): return
		max_length_error=maxf(max_length_error,float(pose.maxLengthError))
		if not _check(float(pose.maxLengthError)<.03,"Native bones must reach real soles without stretching: "+person.actor_name+" at "+str(person.position)): return
		for index in range(2):
			var side:="left" if index==0 else "right"
			var contact:Dictionary=pose.contacts.feet[side]
			var upper:Transform3D=_transform(rig,index*3)
			var lower:Transform3D=_transform(rig,index*3+1)
			if absf(upper.basis.z.length()-float(rig.get("_thigh")))>=.001 or absf(lower.basis.z.length()-float(rig.get("_shin")))>=.001:
				push_error("Native mesh limb length: "+person.actor_name+" side="+side+" upper="+str(upper.basis.z.length())+" expected="+str(rig.get("_thigh"))+" lower="+str(lower.basis.z.length())+" expected="+str(rig.get("_shin"))+" display="+DisplayServer.get_name())
				quit(1)
				return
			var foot:Transform3D=_transform(rig,index*3+2)
			if not _check(foot.basis.determinant()>0,"No reflected anatomy"): return
			var sole:Vector3=rig.to_global(foot.origin-foot.basis.z*.5)
			if not _check(sole.distance_to(contact.sole)<.01,"Measure emitted cube sole, not only declared contact"): return
			var key:String=person.resident_id+side
			if contact.grounded:
				if not _check(_on_mesh(sole),"Native planted foot must meet actual rendered floor"): return
				if previous.has(key) and previous[key].grounded and Vector3(previous[key].plant).distance_to(contact.plant)<.001:
					var drift:=sole.distance_to(previous[key].sole)
					max_stance_drift=maxf(max_stance_drift,drift)
					if not _check(drift<.02,"Planted native foot cannot slide"): return
			previous[key]={"grounded":contact.grounded,"plant":contact.plant,"sole":sole}
		measured+=1

func _tick(mover:Node2D,target:Vector2) -> void:
	timer+=.1
	for person in people:
		var before:=person.position
		if person==mover:
			person.position=person.position.move_toward(target,2.6)
			if not _check(collision.is_walkable(person.position),"Native fixture route left legal floor"): return
		person.moved_velocity=(person.position-before)/.1
		person.set("_elapsed",timer)
		person.get("_body_animation").update(.1,person.moved_velocity,false,false,false,false,false,person.activity_kind)
	renderer.actors_3d.update_actors(.1)
	_measure()
	if capture and measured%24==0:
		await process_frame
		RenderingServer.force_draw(false)
		renderer.viewport_3d.get_texture().get_image().save_png(OUTPUT+"/%03d.png"%frame)
		recording.append({"frame":frame,"bodies":renderer.actors_3d.counts.bodyClips.duplicate(true)})
		frame+=1
	else: await process_frame

func run() -> void:
	capture=OS.get_environment("NATIVE_RESIDENT_CAPTURE")=="1"
	if capture:
		root.size=Vector2i(1440,810)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var unchanged:=JSON.stringify({"world":state.world,"player":state.player})
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=false
	clock.reduced_motion=false
	clock.visual_minutes=600
	var stage:=Node2D.new()
	root.add_child(stage)
	var player:=ReferencePlayer.new()
	player.position=Vector2(1000,1325)
	player.swim_sprite=load("res://scripts/CharacterVisual.gd").new()
	player.add_child(player.swim_sprite)
	player.swim_sprite.call("set_appearance","male_nusantara")
	player.swim_sprite.call("set_outfit","daily")
	player.swim_sprite.call("set_locomotion",Vector2.ZERO,.1)
	player.swim_sprite.call("animate",false,false,1,0)
	player.swim_sprite.visible=false
	stage.add_child(player)
	var camera:=Camera2D.new()
	camera.position=Vector2(1000,1360)
	camera.zoom=Vector2(1.5,1.5)
	stage.add_child(camera)
	camera.force_update_scroll()
	collision=load("res://scripts/land/LandCollision.gd").new()
	collision.configure(state.world.landMaps.hub)
	stage.add_child(collision)
	for index in range(SPECS.size()):
		var spec:Array=SPECS[index]
		var person:Node2D=load("res://scripts/HubActor.gd").new()
		person.actor_name=spec[1]
		person.appearance_index=6+index
		person.position=Vector2(900+index*32,1360)
		person.set_meta("land_hidden",true)
		person.set_meta("native_mesh_diagnostics",true)
		person.configure_activity({"id":spec[0],"bodyScale":spec[3],"visual":{"kind":spec[2],"prop":spec[4],"shirtColor":spec[5]}})
		stage.add_child(person)
		person.set_process(false)
		people.append(person)
	renderer=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	renderer.setup(stage,player,camera,"hub")
	renderer.set_process(false)
	await process_frame
	renderer.call("_process",.1)
	_index_meshes()
	for person in people:
		var start:=person.position
		for offset in [Vector2(20,0),Vector2(20,-16),Vector2(0,-16),Vector2.ZERO]:
			while person.position.distance_to(start+offset)>.01: await _tick(person,start+offset)
		for stop in range(5): await _tick(null,Vector2.ZERO)
	var poses:Dictionary=renderer.actors_3d.counts.bodyClips.duplicate(true)
	clock.clock_paused=true
	renderer.actors_3d.update_actors(5)
	if not _check(renderer.actors_3d.counts.bodyClips==poses,"Paused native bodies/props retain exact pose"): return
	clock.clock_paused=false
	clock.reduced_motion=true
	await _tick(null,Vector2.ZERO)
	if not _check(JSON.stringify({"world":state.world,"player":state.player})==unchanged,"Native fixture mutated state"): return
	if not _check(renderer.actors_3d.counts.npcs==6 and renderer.actors_3d.counts.player==1 and measured>500,"Native fixture did not exercise six complete bodies beside actual Nala"): return
	if capture: FileAccess.open(OUTPUT+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(recording,"  "))
	print("NATIVE RESIDENT BODY PASS: six canonical director/child models, ",measured," ","emitted-input" if DisplayServer.get_name()=="headless" else "actual mesh readback"," sole/limb samples; one body batch each, stable world stance max=",max_stance_drift," length error=",max_length_error,"; all four movement headings, child ratios/props, pause/reduced, no WORLD or player mutation")
	stage.free()
	quit()
