extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var audio := root.get_node("AudioManager")
	var state := root.get_node("GameState")
	audio.set_process(false)
	audio.audio_unlocked = true
	audio.muted = false
	audio._focused = true
	state.dive = {}
	var actor := Node2D.new()
	actor.position = Vector2(1120,1230)
	root.add_child(actor)
	var foley = load("res://scripts/WorldFoley.gd").new()
	root.add_child(foley)
	foley.set_process(false)
	foley.configure(actor,"hub")
	foley._process(0.1)
	var before := int(audio.debug_status().sfxPlayed)
	for tick in range(4):
		actor.position.x += 10
		foley._process(0.1)
	assert(int(audio.debug_status().sfxPlayed)==before+1, "Actual walking distance must produce one footstep")
	assert(audio.debug_status().lastSfx=="footstep_wood")
	before = int(audio.debug_status().sfxPlayed)
	for tick in range(30): foley._process(0.1)
	assert(int(audio.debug_status().sfxPlayed)==before, "Stationary or blocked movement must not produce steps")
	audio.muted = true
	for tick in range(8):
		actor.position.x += 10
		foley._process(0.1)
	assert(int(audio.debug_status().sfxPlayed)==before, "Mute must suppress motion audio")
	audio.muted = false
	foley.area = "forest"
	for tick in range(4):
		actor.position.x += 10
		foley._process(0.1)
	assert(audio.debug_status().lastSfx=="footstep_grass")
	state.dive = {"id":"foley-check","oxygen":83}
	actor.position.y = 600
	foley._process(0.1)
	for tick in range(36): foley._process(0.1)
	assert(audio.debug_status().lastSfx=="diver_breath", "Underwater breathing must remain audible while still")
	assert(state.dive.oxygen==83, "Foley may not alter authoritative oxygen")
	foley.free()
	actor.free()
	state.dive = {}
	# Stop gesture callbacks and crossfades before draining the audio mixer.
	audio.set_process_input(false)
	audio.set_process_unhandled_input(false)
	audio.process_mode = Node.PROCESS_MODE_DISABLED
	audio.audio_unlocked = false
	audio.muted = true
	audio.stop_bgm(0.0)
	for sound in audio.get_children():
		if sound is AudioStreamPlayer:
			sound.stop()
			sound.stream = null
	audio.bgm_streams.clear()
	audio.sfx_streams.clear()
	# AudioServer retains bus effects independently of the autoload node.
	for bus_name in [audio.ENVIRONMENT_BUS, audio.UI_BUS]:
		var bus := AudioServer.get_bus_index(bus_name)
		if bus < 0: continue
		for effect in range(AudioServer.get_bus_effect_count(bus) - 1, -1, -1):
			AudioServer.remove_bus_effect(bus, effect)
	audio._filter = null
	audio.queue_free()
	# Flush node deletion first, then allow queued mixer playback references to retire.
	await process_frame
	await process_frame
	await create_timer(0.35).timeout
	print("PASS world foley: distance-based wood/grass steps, stationary silence, mute, breathing, unchanged oxygen")
	quit()
