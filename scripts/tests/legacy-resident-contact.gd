extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state:Node=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var clock:Node=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=false
	var scene:=Node2D.new()
	root.add_child(scene)
	var player:=Node2D.new()
	scene.add_child(player)
	var camera:=Camera2D.new()
	camera.zoom=Vector2(1.5,1.5)
	scene.add_child(camera)
	var collision:Node2D=load("res://scripts/land/LandCollision.gd").new()
	collision.configure(state.world.landMaps.hub)
	scene.add_child(collision)
	var renderer:Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	scene.add_child(renderer)
	renderer.setup(scene,player,camera,"hub")
	renderer.set_process(false)
	var samples:=0
	var planted:=0
	for name in ["Bu Darmi","Yu Sari"]:
		var profile:Dictionary={}
		if name=="Bu Darmi":
			profile=state.world.surface_hub.districtActivities[name].duplicate(true)
			profile["name"]=name
		else:
			for resident in state.world.surface_hub.residents:
				if str(resident.name)==name: profile=resident
		assert(not profile.is_empty())
		var actor:Node2D=load("res://scripts/HubActor.gd").new()
		actor.actor_name=name
		actor.position=Vector2(float(profile.activity.work[0]),float(profile.activity.work[1]))
		actor.walkable=Callable(collision,"is_walkable")
		actor.set_meta("land_hidden",true)
		scene.add_child(actor)
		actor.set_process(false)
		actor.configure_activity(profile)
		var rig:Node3D=load("res://scripts/NpcBodyRig3D.gd").new()
		renderer.world_root.add_child(rig)
		assert(rig.configure(renderer,actor))
		rig.update_pose(Color.WHITE)
		var commute:Array=profile.activity.commute
		var return_route:Array=commute.duplicate(true)
		return_route.reverse()
		for reduced in [false,true]:
			clock.reduced_motion=reduced
			for route in [commute,return_route]:
				for point in route:
					var target:=Vector2(float(point[0]),float(point[1]))
					while actor.position.distance_to(target)>.001:
						var before:Vector2=actor.position
						actor.position=before.move_toward(target,2.6)
						assert(collision.is_walkable(actor.position),name+" must use its legal commute")
						actor.moved_velocity=(actor.position-before)/.1
						actor._elapsed+=.1
						actor.get("_body_animation").update(.1,actor.moved_velocity,false,false,false,false,reduced,actor.activity_kind)
						rig.update_pose(Color.WHITE)
						var pose:Dictionary=rig.pose_snapshot()
						var contact:Dictionary=pose.contacts
						if pose.direction=="west":
							assert(rig.sprites.head.flip_h and rig.sprites.torso.flip_h,name+" must turn its visible face west without reflecting the legs")
						elif pose.direction=="east":
							assert(not rig.sprites.head.flip_h and not rig.sprites.torso.flip_h)
						assert(contact.reachValid,name+" has an unreachable ankle")
						assert(float(contact.maxLengthError)<.02,name+" has stretched thigh/calf pixels")
						assert(rig.global_basis.determinant()>0,name+" cannot swap anatomical sides")
						for side in ["left","right"]:
							var entry:Dictionary=contact.feet[side]
							if entry.grounded:
								assert(Vector3(entry.sole).distance_to(renderer.ground_point(entry.logical))<.01,name+" foot must rest on its own ground point")
								planted+=1
							assert(absf(rig.sprites["upper_leg_"+side].global_basis.y.length()-1)<.001)
							assert(absf(rig.sprites["lower_leg_"+side].global_basis.y.length()-1)<.001)
						samples+=1
			actor.moved_velocity=Vector2.ZERO
			actor._elapsed+=.1
			actor.get("_body_animation").update(.1,Vector2.ZERO,false,false,false,false,reduced,actor.activity_kind)
			rig.update_pose(Color.WHITE)
			assert(rig.pose_snapshot().contacts.feet.left.grounded or rig.pose_snapshot().contacts.feet.right.grounded)
		rig.free()
		actor.free()
	assert(samples>500 and planted>samples/2)
	print("LEGACY RESIDENT CONTACT PASS ",samples," real commute samples, ",planted," planted sole samples, both schedules and reduced motion")
	scene.free()
	quit()
