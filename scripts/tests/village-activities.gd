extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var before:=JSON.stringify({"player":state.player,"dive":state.dive})
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.elapsed_seconds=0
	clock.clock_paused=false
	clock.reduced_motion=false
	var collision: Node2D=load("res://scripts/land/LandCollision.gd").new()
	collision.configure(state.world.landMaps.hub)
	root.add_child(collision)
	var profiles: Array=state.world.surface_hub.residents.duplicate(true)
	var gardener: Dictionary=state.world.surface_hub.districtActivities["Bu Darmi"].duplicate(true)
	gardener["name"]="Bu Darmi"
	profiles.append(gardener)
	var steps:=0
	for profile in profiles:
		var actor: Node2D=load("res://scripts/HubActor.gd").new()
		actor.actor_name=str(profile.name)
		actor.position=Vector2(float(profile.activity.work[0]),float(profile.activity.work[1]))
		actor.walkable=Callable(collision,"is_walkable")
		root.add_child(actor)
		actor.set_process(false)
		actor.configure_activity(profile)
		clock.visual_minutes=float(profile.activity.startMinute)+30
		actor.call("_process",0.1)
		assert(actor.activity_state().phase=="work",str(profile.name)+" must work within opening hours")
		var nearby_player:=Node2D.new()
		root.add_child(nearby_player)
		nearby_player.position=actor.position
		actor.player=nearby_player
		actor.call("_process",.2)
		assert(actor.activity_motion!=0 and actor.activity_state().phase=="work","Nearby dialogue must not freeze idle work")
		actor.player=null
		nearby_player.queue_free()
		var original:=actor.position
		clock.visual_minutes=float(profile.activity.endMinute)
		actor.call("_process",0.0)
		assert(actor.position==original,"Schedule changes cannot teleport")
		assert(str(actor.activity_state().phase).begins_with("walking_rest"))
		var destination:=Vector2(float(profile.activity.rest[0]),float(profile.activity.rest[1]))
		var iterations:=0
		while actor.position.distance_to(destination)>2 and iterations<3000:
			var previous:=actor.position
			actor.call("_process",0.1)
			assert(actor.position.distance_to(previous)<=2.601,"NPC exceeded walking pace")
			assert(collision.is_walkable(actor.position),str(profile.name)+" walked outside authored floors or through an obstacle")
			iterations+=1
			steps+=1
		assert(iterations<3000,str(profile.name)+" did not reach their connected home entrance: "+str(actor.activity_state()))
		actor.call("_process",0.0)
		assert(actor.activity_state().phase=="rest")
		clock.visual_minutes=float(profile.activity.startMinute)+30
		actor.call("_process",0.0)
		clock.clock_paused=true
		var paused:=actor.position
		actor.call("_process",1.0)
		assert(actor.position==paused and actor.activity_motion==0)
		clock.clock_paused=false
		clock.reduced_motion=true
		actor.call("_process",1.0)
		assert(actor.position==paused and actor.activity_motion==0)
		clock.reduced_motion=false
		var player:=Node2D.new()
		root.add_child(player)
		player.position=actor.position
		actor.player=player
		actor.call("_process",1.0)
		assert(actor.position==paused,"Approaching dialogue must pause walking")
		actor.player=null
		player.queue_free()
		clock.elapsed_seconds=180
		actor.call("_process",0.0)
		assert(str(actor.activity_state().phase).ends_with("shelter"),"Heavy local rain must request shelter")
		assert(actor.position==paused,"Rain cannot teleport villagers")
		clock.elapsed_seconds=0
		actor.queue_free()
	assert(before==JSON.stringify({"player":state.player,"dive":state.dive}),"Cosmetic village simulation must not mutate economy or progress")
	print("VILLAGE ACTIVITIES PASS:7 workers, ",steps," continuous collision-checked travel steps, opening/closing boundaries, rain shelter, reading/nearby/reduced-motion pauses, no teleport or gameplay mutation")
	quit()
