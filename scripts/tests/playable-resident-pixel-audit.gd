extends SceneTree

var output:="res://../artifacts/godot/playable-resident-pixel-audit"
var width:=667
var stage:Node2D
var renderer:Node2D
var actor:Node2D
var collision:Node2D
var player:Node2D
var ticks:=0
var frames:Array=[]
var failed:=false
var max_drop:=0.0
var deep_drops:Array=[]

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--width="): width=int(arg.trim_prefix("--width="))
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
	_run.call_deferred()

func _capture(label:String) -> void:
	for frame in range(4): await process_frame
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false)
		var image:=root.get_texture().get_image()
		assert(image.get_size()==Vector2i(width,375 if width==667 else 390))
		image.save_png(output+"/"+label+".png")
	var rig:Node3D=renderer.actors_3d._body_rig(actor)
	frames.append({"label":label,"position":[actor.position.x,actor.position.y],"pose":rig.pose_snapshot()})

func _step(velocity:Vector2,elapsed:float) -> void:
	var before:Vector2=actor.position
	var next:=before+velocity*2.6
	if not collision.is_walkable(next):
		failed=true
		push_error("Audit route left legal floor: "+str(next))
		quit(1)
		return
	actor.position=next
	actor.moved_velocity=(next-before)/.1
	actor._elapsed+=.1
	actor._body_animation.update(.1,actor.moved_velocity,false,false,false,false,false,actor.activity_kind)
	renderer.actors_3d.update_actors(.1)
	var pose:Dictionary=renderer.actors_3d._body_rig(actor).pose_snapshot()
	max_drop=maxf(max_drop,float(pose.pelvisDrop))
	if float(pose.pelvisDrop)>=9*float(actor.body_scale):
		deep_drops.append({"at":[actor.position.x,actor.position.y],"velocity":[actor.moved_velocity.x,actor.moved_velocity.y],"drop":pose.pelvisDrop,"shift":pose.get("pelvisShiftX",0),"links":pose.links})
	if not (bool(pose.contacts.feet.left.grounded) or bool(pose.contacts.feet.right.grounded)):
		failed=true
		push_error("Both feet lost floor at "+str(actor.position))
		quit(1)
		return
	ticks+=1

func _run() -> void:
	assert(width in [667,844])
	root.size=Vector2i(width,375 if width==667 else 390)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var state:Node=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var clock:Node=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=false
	clock.reduced_motion=false
	clock.authoritative=true
	clock.apply_calendar({"calendarRevision":1,"calendarDay":1,"minuteOfDay":600})
	clock.set("_server_rain",false)
	clock.set("_rain_amount",0)
	root.get_node("RenderQuality").set_profile("balanced",false)
	stage=Node2D.new()
	root.add_child(stage)
	collision=load("res://scripts/land/LandCollision.gd").new()
	stage.add_child(collision)
	collision.configure(state.world.landMaps.hub)
	player=load("res://scripts/Player.gd").new()
	stage.add_child(player)
	player.position=Vector2(1350,1325)
	player.set_physics_process(false)
	player.visible=false
	player.swim_sprite.set_appearance("male_nusantara")
	player.swim_sprite.set_outfit("daily")
	player.swim_sprite.animate(false,false,1,0)
	var camera:=Camera2D.new()
	camera.position=player.position
	camera.zoom=Vector2(1.5,1.5)
	stage.add_child(camera)
	var profile:Dictionary={}
	for resident in state.world.surface_hub.residents:
		if str(resident.id)=="npc_kid_gito": profile=resident
	assert(not profile.is_empty())
	actor=load("res://scripts/HubActor.gd").new()
	actor.actor_name=str(profile.name)
	actor.appearance_index=int(profile.appearance)
	actor.configure_activity(profile)
	var directions:=[Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP,Vector2(1,1).normalized(),Vector2(-1,1).normalized(),Vector2(-1,-1).normalized(),Vector2(1,-1).normalized()]
	var station:=Vector2(1430,1330)
	var found:=false
	for radius in range(0,100,8):
		if found: break
		for dx in range(-radius,radius+1,8):
			for dy in range(-radius,radius+1,8):
				var probe:=station+Vector2(dx,dy)
				var clear:bool=collision.is_walkable(probe)
				for direction in directions: clear=clear and collision.is_walkable(probe+direction*22)
				if clear:
					station=probe
					found=true
					break
			if found: break
	assert(found,"No eight-heading legal pier patch")
	actor.position=station
	print("RESIDENT AUDIT STATION: ",station)
	assert(collision.is_walkable(actor.position))
	actor.visible=false
	stage.add_child(actor)
	actor.set_process(false)
	renderer=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	renderer.setup(stage,player,camera,"hub")
	renderer.set_process(false)
	renderer._process(.1)
	var rig:Node3D=renderer.actors_3d._body_rig(actor)
	assert(rig.get_script().resource_path.ends_with("ResidentArtRig3D.gd"))
	await _capture("idle")
	for index in range(directions.size()):
		var start:=actor.position
		for tick in range(8):
			_step(directions[index],.1)
			if failed: return
			if tick in [2,6]: await _capture("heading-%d-step-%d"%[index,tick])
		for tick in range(8):
			_step(-directions[index],.1)
			if failed: return
		assert(actor.position.distance_to(start)<.5,"Return displacement: "+str(actor.position.distance_to(start)))
		actor.moved_velocity=Vector2.ZERO
		actor._body_animation.update(.2,Vector2.ZERO,false,false,false,false,false,actor.activity_kind)
		renderer.actors_3d.update_actors(.2)
		await _capture("heading-%d-idle"%index)
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify({"width":width,"ticks":ticks,"frames":frames,"maxPelvisDrop":max_drop,"deepDrops":deep_drops},"  "))
	if not deep_drops.is_empty():
		printerr("PLAYABLE RESIDENT PIXEL AUDIT FAIL: ",width,"x",root.size.y,"; deep drops ",deep_drops.size(),"; max ",max_drop)
		quit(1)
		return
	print("PLAYABLE RESIDENT PIXEL AUDIT PASS: ",width,"x",root.size.y,"; actual art rig; eight motion headings, two stride phases, idle; max drop ",max_drop)
	stage.free()
	quit()
