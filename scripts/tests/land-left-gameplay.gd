extends SceneTree

var checks:=0
func _initialize() -> void: call_deferred("run")

func _release_keys() -> void:
	for action in ["left","right","up","down"]: Input.action_release(action)

func _verify_motion(renderer: Node,previous: Vector2,current: Vector2,wanted: Vector2) -> void:
	var view: Vector2=renderer.visual_locomotion(previous,current,1)
	assert(view.length()>.1,"Actual accepted controller movement must not be zero")
	assert(view.normalized().dot(wanted.normalized())>.995,"Actual logical controller displacement must appear in the requested screen direction")
	checks+=1

func run() -> void:
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":200,"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive={}
	state.surface={"area":"hub","x":1120,"y":1230}
	var before:=JSON.stringify({"world":state.world,"player":state.player,"surface":state.surface})
	root.get_node("EnvironmentState").set_process(false)
	for action in ["left","right","up","down"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var scene:=Node2D.new()
	root.add_child(scene)
	var collision: Node2D=load("res://scripts/land/LandCollision.gd").new()
	collision.configure(state.world.landMaps.hub)
	scene.add_child(collision)
	var player: CharacterBody2D=load("res://scripts/Player.gd").new()
	scene.add_child(player)
	player.set_physics_process(false)
	player.position=Vector2(1120,1230)
	player.land_mask=collision.is_walkable
	player.surface_traversal.configure(state.world.landMaps.hub)
	var camera:=Camera2D.new()
	scene.add_child(camera)
	var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	scene.add_child(renderer)
	renderer.setup(scene,player,camera,"hub")
	renderer.set_process(false)
	player.input_transform=renderer.input_motion
	player.visual_motion_transform=renderer.visual_locomotion
	assert(renderer.camera_azimuth==-45 and renderer.camera_elevation==35)
	assert(renderer.camera_right().distance_to(Vector3.RIGHT)>.5,"Actual camera must use the left pose before the first physics frame")
	for direction in range(8):
		for strength in [1.0,.35]:
			player.position=Vector2(1120,1230)
			player.velocity=Vector2.ZERO
			player.traversal_state={}
			player.land_path.reset(player.position)
			player.touch=Vector2.RIGHT.rotated(direction*PI*.25)*strength
			var previous: Vector2=player.position
			var distance_before: float=player.swim_sprite.locomotion_state().distance
			for frame in range(16):
				await physics_frame
				player._physics_process(1.0/60)
			_verify_motion(renderer,previous,player.position,player.touch)
			assert(player.position.distance_to(previous)<=100*16.0/60+.01,"Screen inverse must preserve logical speed limit")
			var gait: Dictionary=player.swim_sprite.locomotion_state()
			assert(absf(gait.distance-distance_before-player.position.distance_to(previous))<.01,"Projected velocity must never drive the physical gait phase")
			assert(gait.requestedDirection==player.swim_sprite.DIRECTIONS[direction])
			var saved_distance: float=gait.distance
			player.frozen=true
			player._physics_process(.25)
			assert(is_equal_approx(player.swim_sprite.locomotion_state().distance,saved_distance),"Paused controls must not advance gait")
			player.frozen=false
	player.touch=Vector2.ZERO
	for screen in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		player.position=Vector2(1120,1230)
		player.velocity=Vector2.ZERO
		player.land_path.reset(player.position)
		var previous: Vector2=player.position
		var action: String="right" if screen.x>0 else "left" if screen.x<0 else "down" if screen.y>0 else "up"
		Input.action_press(action)
		for frame in range(12):
			await physics_frame
			player._physics_process(1.0/60)
		_release_keys()
		_verify_motion(renderer,previous,player.position,screen)
	for stair in renderer._stair_queries:
		var midpoint: Vector2=(stair.start+stair.end)*.5
		for direction in range(8):
			var wanted:=Vector2.RIGHT.rotated(direction*PI*.25)
			var logical: Vector2=renderer.input_motion(wanted,midpoint)
			var view: Vector2=renderer.visual_locomotion(midpoint,midpoint+logical*.02,1)
			assert(view.normalized().dot(wanted)>.999,"Actual authored connector gradient must retain screen-relative steering")
			checks+=1
	# Follow target includes the actor's real floor height, even near map bounds.
	for position in [Vector2(160,615),Vector2(1120,1230),Vector2(2295,125)]:
		player.position=position
		renderer._update_view(0,true)
		var center: Vector2=renderer.view_projection.project_logical(position,renderer.ground_height(position))
		assert(center.distance_to(Vector2(renderer.viewport_3d.size)*.5)<.01)
	assert(renderer.water_node.get_node("DistantWaterBacking").mesh.get_faces().size()==6,"Far water coverage adds only two triangles")
	scene.free()
	await process_frame
	var forest: Node2D=load("res://scripts/Forest.gd").new()
	root.add_child(forest)
	forest.set_process(false)
	forest.set_physics_process(false)
	forest.avatar.set_physics_process(false)
	forest.syncing=true
	for direction in range(8):
		forest.avatar.position=Vector2(200,1320)
		forest.avatar.velocity=Vector2.ZERO
		forest.land_path.reset(forest.avatar.position)
		forest.traversal_state={}
		forest.touch_direction=Vector2.RIGHT.rotated(direction*PI*.25)
		var previous: Vector2=forest.avatar.position
		for frame in range(12):
			await physics_frame
			forest._physics_process(1.0/60)
		_verify_motion(forest.land_renderer,previous,forest.avatar.position,forest.touch_direction)
		assert(forest.avatar.swim_sprite.locomotion_state().requestedDirection==forest.avatar.swim_sprite.DIRECTIONS[direction])
	forest.free()
	await process_frame
	assert(JSON.stringify({"world":state.world,"player":state.player,"surface":state.surface})==before,"Camera/input proof must not mutate save, manifest or economy")
	print("LAND LEFT GAMEPLAY PASS: ",checks," actual Player/Forest controller and authored connector direction checks; analog magnitude, keyboard, physical gait distance, pause, elevated follow, water backing; no save mutation")
	quit()
