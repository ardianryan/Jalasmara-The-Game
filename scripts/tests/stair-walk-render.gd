extends SceneTree

var output:="res://../artifacts/godot/06g-stair-walk"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	call_deferred("run")

func run() -> void:
	assert(DisplayServer.get_name()!="headless")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(1280,720)
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":200,"inventory":[],"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive={}
	var before:=JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})
	var environment:=root.get_node("EnvironmentState")
	environment.set_process(false)
	environment.clock_paused=false
	environment.authoritative=true
	environment.visual_minutes=600
	environment._process(0)
	for action in ["left","right","up","down"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var stage:=Node2D.new()
	root.add_child(stage)
	var collision: Node2D=load("res://scripts/land/LandCollision.gd").new()
	stage.add_child(collision)
	collision.configure(state.world.landMaps.hub)
	var player: CharacterBody2D=load("res://scripts/Player.gd").new()
	stage.add_child(player)
	player.set_physics_process(false)
	player.hybrid_visual=true
	player.land_mask=collision.is_walkable
	player.position=Vector2(1370,825)
	var camera:=Camera2D.new()
	camera.zoom=Vector2(1.65,1.65)
	stage.add_child(camera)
	var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	renderer.setup(stage,player,camera,"hub")
	renderer.set_process(false)
	player.input_transform=renderer.input_motion
	player.visual_motion_transform=renderer.visual_locomotion
	var report: Dictionary={"cases":{},"frames":{},"scope":"Actual Player controller on three authored connectors; single whole-body atlas, not independent per-leg stair animation"}
	for reduced in [false,true]:
		environment.reduced_motion=reduced
		for connector_id in ["central_stone_steps","forest_ridge_steps","dock_gangway"]:
			if reduced and connector_id!="central_stone_steps": continue
			var connector: Dictionary={}
			for entry in state.world.landMaps.hub.stairs:
				if str(entry.id)==connector_id: connector=entry
			var a:=Vector2(float(connector.path[0][0]),float(connector.path[0][1]))
			var b:=Vector2(float(connector.path[1][0]),float(connector.path[1][1]))
			var along: Vector2=(b-a).normalized()
			for descending in [false,true]:
				var first:=b+along*10 if descending else a-along*10
				var target:=a-along*10 if descending else b+along*10
				player.position=first
				player.velocity=Vector2.ZERO
				player.land_path.reset(first)
				player.surface_traversal.configure(state.world.landMaps.hub)
				player.traversal_state={}
				renderer._update_view(0,true)
				var id:="%s-%s-%s"%[connector_id,"down" if descending else "up","reduced" if reduced else "normal"]
				var travelled:=0.0
				var gait_distance:=0.0
				var start_distance: float=player.swim_sprite.locomotion_state().distance
				var saved:=0
				var reached:=false
				for frame in range(160):
					var previous: Vector2=player.position
					var direction: Vector2=(target-player.position).normalized()
					player.touch=renderer.visual_motion(direction,renderer.ground_gradient(player.position).dot(direction)).normalized() if player.position.distance_to(target)>1.5 else Vector2.ZERO
					await physics_frame
					player._physics_process(1.0/60)
					var accepted: float=player.position.distance_to(previous)
					travelled+=accepted
					if accepted*60>=8: gait_distance+=accepted
					camera.position=player.position
					camera.force_update_scroll()
					renderer._process(1.0/60)
					assert(collision.is_walkable(player.position))
					assert(renderer.actors_3d.max_foot_error<.01)
					if frame%8==0 or player.touch==Vector2.ZERO:
						await process_frame
						RenderingServer.force_draw(false)
						var key:="%s-%03d"%[id,frame]
						root.get_texture().get_image().save_png(output+"/"+key+".png")
						var land: Dictionary=renderer.debug_status()
						report.frames[key]={"player":[player.position.x,player.position.y],"traversal":player.traversal_state.duplicate(),"gait":player.swim_sprite.locomotion_state(),"grounding":land.actors.playerGrounding,"view":land.view}
						saved+=1
					if player.touch==Vector2.ZERO:
						reached=true
						break
				assert(reached,"Actual accepted player motion failed to reach the opposite landing: "+id)
				player.touch=Vector2.ZERO
				for rest in range(12):
					var previous: Vector2=player.position
					await physics_frame
					player._physics_process(1.0/60)
					var accepted: float=player.position.distance_to(previous)
					travelled+=accepted
					if accepted*60>=8: gait_distance+=accepted
					renderer._process(1.0/60)
					if rest in [0,5,11]:
						await process_frame
						RenderingServer.force_draw(false)
						var key:="%s-stop-%02d"%[id,rest]
						root.get_texture().get_image().save_png(output+"/"+key+".png")
						var land: Dictionary=renderer.debug_status()
						report.frames[key]={"player":[player.position.x,player.position.y],"traversal":player.traversal_state.duplicate(),"gait":player.swim_sprite.locomotion_state(),"grounding":land.actors.playerGrounding,"view":land.view}
						saved+=1
				assert(absf(player.swim_sprite.locomotion_state().distance-start_distance-gait_distance)<.05,"Stair display must preserve the existing accepted-speed>=8 gait distance filter")
				assert(player.velocity.is_zero_approx() and is_zero_approx(float(player.traversal_state.bodyLift)))
				report.cases[id]={"frames":saved,"distance":travelled,"gaitDistance":gait_distance,"reached":reached}
	assert(JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})==before)
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("STAIR WALK NATIVE PASS: ",report.cases.size()," actual controller ascent/descent/reduced cases,",report.frames.size()," sequential frames; distance/state preserved")
	stage.free()
	quit()
