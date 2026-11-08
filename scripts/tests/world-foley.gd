extends SceneTree
class Walker extends Node2D:
	var traversal_state: Dictionary = {}

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
	for name in ["footstep_dock","footstep_bridge","footstep_sand","footstep_stone","footstep_water_shallow","footstep_dirt","punch_swing","punch_hit","hit_wood","hit_stone","machete_cut_bush","wood_break_barricade","boulder_push_slide","path_reveal_chime","coastal_wave_lap","coastal_wave_surge","wave_crash_rock","ambient_coastal_waves"]:
		assert(audio.sfx_streams.has(name), "Supplied SFX was not imported/loaded: "+name)
		var stream: AudioStreamWAV = audio.sfx_streams[name]
		assert(stream.mix_rate==44100 and stream.get_length()>0.08 and stream.get_length()<=12.5, "Godot must load playable supplied SFX at the authored rate/duration")
	var actor := Walker.new()
	root.add_child(actor)
	var surfaces := [{"id":"base","material":"grass","priority":0,"elevation":0,"polygon":[[0,0],[1200,0],[1200,900],[0,900]]}]
	var materials := ["dock","bridge","sand","stone","dirt","grass","wood","water_shallow"]
	for index in range(materials.size()):
		var x := 100+index*100
		surfaces.append({"id":materials[index],"material":materials[index],"priority":10,"elevation":0,"polygon":[[x,480],[x+90,480],[x+90,560],[x,560]]})
	state.world = {"landMaps":{"hub":{"surfaces":surfaces,"stairs":[]},"forest":{"surfaces":surfaces,"stairs":[]}}}
	var foley = load("res://scripts/WorldFoley.gd").new()
	root.add_child(foley)
	foley.set_process(false)
	for index in range(materials.size()):
		actor.position = Vector2(120+index*100,500)
		foley.configure(actor,"hub")
		foley._process(0.1)
		var before_step := int(audio.debug_status().sfxPlayed)
		for tick in range(4):
			actor.position.x += 10
			foley._process(0.1)
		assert(int(audio.debug_status().sfxPlayed)==before_step+1, "Actual walking distance must produce one footstep")
		assert(audio.debug_status().lastSfx=="footstep_"+materials[index], "Surface polygon must choose the sound, not world Y")
	var before := int(audio.debug_status().sfxPlayed)
	for tick in range(30): foley._process(0.1)
	assert(int(audio.debug_status().sfxPlayed)==before, "Stationary or blocked movement must not produce steps")
	audio.muted = true
	for tick in range(8):
		actor.position.x += 10
		foley._process(0.1)
	assert(int(audio.debug_status().sfxPlayed)==before, "Mute must suppress motion audio")
	audio.muted = false
	foley._process(0.1)
	assert(int(audio.debug_status().sfxPlayed)==before, "Muted travel must not queue steps after unmute")
	actor.position = Vector2(120,500)
	foley.configure(actor,"forest")
	foley._process(0.1)
	for tick in range(4):
		actor.position.x += 10
		foley._process(0.1)
	assert(audio.debug_status().lastSfx=="footstep_dock", "Area must read its own manifest")
	actor.traversal_state = {"onConnector":true,"footstepMaterial":"stone"}
	assert(foley.material_at(actor.position)=="stone", "Actual stair traversal must override floor material")
	actor.traversal_state = {}
	state.world.landMaps.forest.stairs = [{"path":[[100,500],[200,500]],"width":30,"material":"bridge"}]
	assert(foley.material_at(actor.position)=="bridge", "Authored bridge connector must override floor without traversal state")
	state.world.landMaps.forest.stairs = []
	state.world.landMaps.forest.surfaces.append({"id":"raised","material":"stone","priority":10,"elevation":2,"polygon":[[100,480],[190,480],[190,560],[100,560]]})
	assert(foley.material_at(actor.position)=="stone", "Equal priority must prefer the higher floor")
	assert(foley.material_at(Vector2(-10,-10)).is_empty(), "No footstep material outside authored surfaces")
	state.dive = {"id":"foley-check","oxygen":83}
	actor.position.y = 600
	foley._process(0.1)
	for tick in range(36): foley._process(0.1)
	assert(audio.debug_status().lastSfx=="diver_breath", "Underwater breathing must remain audible while still")
	assert(state.dive.oxygen==83, "Foley may not alter authoritative oxygen")
	state.dive = {}
	audio.play_bgm("coastal_day", 0.0)
	actor.position = Vector2(180, 520)
	foley.configure(actor, "hub")
	for tick in range(40):
		foley._process(0.1)
	var shore_status: Dictionary = audio.debug_status()
	assert(shore_status.track=="coastal_day", "Coastal wave ambience must never overwrite active BGM track")
	assert(bool(shore_status.get("coastalAmbiencePlaying",false)), "Coastal wave ambience loop must play near shore")
	assert(int(shore_status.get("waterSfxPlayed",0))>0 and str(shore_status.get("lastWaterSfx","")) in ["coastal_wave_lap","coastal_wave_surge","wave_crash_rock"], "Swell crest events must trigger synchronized wave one-shots")
	var near_db := float(shore_status.get("coastalAmbienceDb",-60.0))
	actor.position = Vector2(600, 450)
	for tick in range(20):
		foley._process(0.1)
	var far_db := float(audio.debug_status().get("coastalAmbienceDb",-60.0))
	assert(near_db > far_db, "Coastal ambience must attenuate when moving inland away from water")
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
	print("PASS world foley: 8 explicit floor materials at identical Y, surface priority/elevation, connector override, distance cadence, stationary/mute silence, breathing, unchanged oxygen")
	quit()
