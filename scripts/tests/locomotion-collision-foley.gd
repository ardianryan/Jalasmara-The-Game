extends SceneTree
func _initialize() -> void: call_deferred('_run')
func _run() -> void:
	var state:=root.get_node('GameState')
	state.world=JSON.parse_string(FileAccess.get_file_as_string('res://../.runtime/world-map.json'))
	state.player={'appearance':'male_default','progress':{'day':1,'stage':'dive'}}
	state.dive={}
	var before:=JSON.stringify(state.player)
	var clock:=root.get_node('EnvironmentState')
	clock.set_process(false)
	clock.clock_paused=false
	clock.reduced_motion=false
	var audio:=root.get_node('AudioManager')
	audio.audio_unlocked=true
	audio.muted=false
	audio.set('_focused',true)
	AudioServer.set_bus_mute(AudioServer.get_bus_index('Master'),true)
	var collision: Node2D=load('res://scripts/land/LandCollision.gd').new()
	collision.configure(state.world.landMaps.hub)
	root.add_child(collision)
	var player: CharacterBody2D=load('res://scripts/Player.gd').new()
	player.position=Vector2(850,550)
	player.land_mask=Callable(collision,'is_walkable')
	root.add_child(player)
	player.touch=Vector2.LEFT
	var foley: Node=load('res://scripts/WorldFoley.gd').new()
	root.add_child(foley)
	foley.configure(player,'hub')
	for frame in range(90):
		await physics_frame
		player.land_path.acknowledge(player.land_path.snapshot(player.position).ticket)
	var stopped: Vector2=player.position
	var gait: Dictionary=player.swim_sprite.locomotion_state()
	var steps: int=foley.debug_status().steps
	assert(stopped.x<830 and stopped.x>650,'Actual player must reach the authored house obstruction')
	assert(collision.is_walkable(stopped) and not collision.is_walkable(stopped+Vector2(-6,0)))
	assert(gait.speed==0 and steps>0,'Collision must stop actual velocity and preserve prior footstep events')
	for frame in range(45):await physics_frame
	assert(player.position.distance_to(stopped)<.1)
	assert(is_equal_approx(player.swim_sprite.locomotion_state().distance,gait.distance),'Blocked feet cannot keep walking in place')
	assert(foley.debug_status().steps==steps,'No extra footstep SFX after physical collision stop')
	assert(steps==floori(float(gait.distance)/(float(gait.stride)*.5)),'Foley must follow actual half-stride contact count')
	assert(before==JSON.stringify(state.player),'Locomotion/audio must not change player economy/progress')
	print('LOCOMOTION COLLISION FOLEY PASS: actual100px/s controller hit solid house, stopped phase/SFX, ',steps,' contact-synced footsteps')
	foley.queue_free()
	player.queue_free()
	collision.queue_free()
	await process_frame
	await process_frame
	quit()
