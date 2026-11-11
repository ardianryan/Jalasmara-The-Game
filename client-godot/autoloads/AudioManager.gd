extends Node
signal mute_changed(value: bool)

const SFX_PATH := "res://audio/sfx/"
const BGM_PATH := "res://audio/bgm/"
const ENVIRONMENT_BUS := "Jalasmara Environment"
const BGM_BUS := "Jalasmara Music"
const UI_BUS := "Jalasmara UI"
const BGM_VOLUME_DB := -14.0
const SFX_VOLUME_DB := -9.0
const SILENCE_DB := -60.0
var sfx_streams: Dictionary = {}
var bgm_streams: Dictionary = {}
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players := 8
var current_sfx_idx := 0
var water_sfx_players: Array[AudioStreamPlayer] = []
var max_water_sfx_players := 2
var current_water_sfx_idx := 0
var bgm_player: AudioStreamPlayer
var panic_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var victory_player: AudioStreamPlayer
var current_bgm_track := ""
var is_underwater := false
var audio_unlocked := false
var muted := false
var _bgm_players: Array[AudioStreamPlayer] = []
var _fade: Tween
var _duck_fade: Tween
var _filter: AudioEffectLowPassFilter
var _environment_bus_index := -1
var _ui_bus_index := -1
var _filter_slot := -1
var _pending_bgm := ""
var _poll_clock := 0.0
var _focused := true
var _last_player := ""
var _last_dive := ""
var _last_coins := 0
var _last_loot := 0
var _last_discoveries := 0
var _last_oxygen := 100.0
var _oxygen_updated_at := 0.0
var _baseline_ready := false
var _menu_override := false
var _played_sfx := 0
var _last_sfx := ""
var _played_water_sfx := 0
var _last_water_sfx := ""
var _ambience_target_db := SILENCE_DB
var _ambience_desired := false

func can_play_environment() -> bool:
	return audio_unlocked and not muted and _focused

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_preferences()
	_setup_buses()
	_setup_audio_players()
	_load_audio_resources()
	_apply_mute()

func _setup_buses() -> void:
	_environment_bus_index = _ensure_bus(ENVIRONMENT_BUS)
	var music_bus := _ensure_bus(BGM_BUS)
	AudioServer.set_bus_send(music_bus,ENVIRONMENT_BUS)
	_ui_bus_index = _ensure_bus(UI_BUS)
	_filter = AudioEffectLowPassFilter.new()
	_filter.cutoff_hz = 1400.0
	_filter.resonance = 0.45
	_filter_slot = AudioServer.get_bus_effect_count(_environment_bus_index)
	AudioServer.add_bus_effect(_environment_bus_index,_filter)
	AudioServer.set_bus_effect_enabled(_environment_bus_index,_filter_slot,false)

func _ensure_bus(bus_name: String) -> int:
	var index := AudioServer.get_bus_index(bus_name)
	if index<0:
		AudioServer.add_bus()
		index = AudioServer.bus_count-1
		AudioServer.set_bus_name(index,bus_name)
	AudioServer.set_bus_send(index,"Master")
	return index

func _setup_audio_players() -> void:
	for i in range(max_sfx_players):
		var sound := AudioStreamPlayer.new()
		sound.bus = ENVIRONMENT_BUS
		sound.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		add_child(sound)
		sfx_players.append(sound)
	for i in range(max_water_sfx_players):
		var water_sound := AudioStreamPlayer.new()
		water_sound.bus = ENVIRONMENT_BUS
		water_sound.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		add_child(water_sound)
		water_sfx_players.append(water_sound)
	for i in range(2):
		var music := AudioStreamPlayer.new()
		music.bus = BGM_BUS
		music.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		music.volume_db = SILENCE_DB
		add_child(music)
		_bgm_players.append(music)
	bgm_player = _bgm_players[0]
	victory_player = AudioStreamPlayer.new()
	victory_player.bus = UI_BUS
	victory_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	victory_player.volume_db = -7.0
	add_child(victory_player)
	victory_player.finished.connect(_restore_bgm_after_jingle)
	panic_player = AudioStreamPlayer.new()
	panic_player.bus = ENVIRONMENT_BUS
	panic_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	panic_player.volume_db = -18.0
	add_child(panic_player)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.bus = ENVIRONMENT_BUS
	ambience_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	ambience_player.volume_db = SILENCE_DB
	add_child(ambience_player)

func _load_audio_resources() -> void:
	var all_sfx := [
		"bubble_pop", "water_splash", "player_hit", "diver_breath",
		"harpoon_shoot", "coin_collect", "item_pickup", "oxygen_alarm",
		"heartbeat", "menu_click", "boss_roar",
		# Gerakan & Desau (Swoosh, Whoosh, Swish, Swesh)
		"swoosh_light", "swoosh_heavy", "swoosh_water", "dodge_swish", "net_throw",
		# Hantaman & Pertarungan (Pukulan, Senjata, Tebasan)
		"hit_heavy", "hit_flesh", "hit_critical", "hit_shield",
		"knife_slash", "monster_bite", "rock_smash",
		"punch_swing", "punch_hit", "hit_wood", "hit_stone",
		# Langkah Kaki Berbagai Permukaan (Dermaga, Jembatan, Pasir, Batu, Air Dangkal, Tanah, Rumput)
		"footstep_grass", "footstep_wood", "footstep_dock", "footstep_bridge",
		"footstep_sand", "footstep_stone", "footstep_water_shallow", "footstep_dirt",
		"quest_complete",
		# Membuka Jalan & Rintangan
		"machete_cut_bush", "wood_break_barricade", "boulder_push_slide", "path_reveal_chime",
		# Ledakan & Dentuman (Boom, Shockwave)
		"explosion_heavy", "underwater_boom",
		# Pintu & Peti Harta
		"door_open_wood", "door_close_wood", "chest_open", "chest_close",
		# Interaksi Taktil Kayu & Menu UI
		"wooden_click_light", "wooden_click_heavy", "wooden_toggle", "page_turn", "recipe_cooked",
		# Mekanisme, Katup & Tetesan
		"rope_creak", "metal_valve_turn", "bell_ding", "water_drip",
		# Deburan Ombak Pesisir & Deru Air Pantai (Coast Surf, Wave Lap & Crash)
		"coastal_wave_lap", "coastal_wave_surge", "wave_crash_rock", "ambient_coastal_waves"
	]
	for sound_name in all_sfx:
		var path: String = SFX_PATH + sound_name + ".wav"
		if ResourceLoader.exists(path):
			sfx_streams[sound_name] = load(path)
	var victory_path := SFX_PATH + "jingle_victory_fanfare.mp3"
	if ResourceLoader.exists(victory_path):
		sfx_streams["jingle_victory_fanfare"] = load(victory_path)
		victory_player.stream = sfx_streams["jingle_victory_fanfare"]
	if sfx_streams.has("heartbeat"):
		sfx_streams["heartbeat"] = _looping_copy(sfx_streams.heartbeat)
	if sfx_streams.has("ambient_coastal_waves"):
		sfx_streams["ambient_coastal_waves"] = _looping_copy(sfx_streams.ambient_coastal_waves)
		if is_instance_valid(ambience_player):
			ambience_player.stream = sfx_streams.ambient_coastal_waves
	var definitions := {
		"title_theme":["bgm_title_theme.mp3"],
		"mangrove_forest":["bgm_mangrove_forest.mp3"],
		"coastal_dusk":["bgm_coastal_dusk.mp3"],
		"village_hall":["bgm_village_hall.mp3"],
		"underwater_cave_deep":["bgm_underwater_cave_deep.mp3"],
		"coastal_day":["bgm_coastal_day.mp3"],
		"underwater_segaran":["bgm_underwater_segaran.mp3"],
		"kedai_waras_night":["bgm_kedai_waras_night.mp3"],
		"boss_gajah_mina":["bgm_boss_gajah_mina.mp3"]}
	for key in definitions:
		for filename in definitions[key]:
			var path := BGM_PATH+str(filename)
			if ResourceLoader.exists(path):
				var stream := _looping_copy(load(path))
				bgm_streams[key] = stream
				bgm_streams["bgm_"+str(key)] = stream
				break
	if bgm_streams.has("underwater_segaran"):
		bgm_streams["underwater_ambient"] = bgm_streams.underwater_segaran
		bgm_streams["bgm_underwater_ambient"] = bgm_streams.underwater_segaran

func _looping_copy(source: AudioStream) -> AudioStream:
	var stream := source.duplicate() as AudioStream
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = maxi(1,int(stream.get_length()*stream.mix_rate))
	return stream

func _input(event: InputEvent) -> void:
	var gesture: bool = (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventJoypadButton and event.pressed)
	if gesture and not audio_unlocked:
		unlock_audio()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_V:
		toggle_mute()

func unlock_audio() -> void:
	if audio_unlocked:
		return
	audio_unlocked = true
	_refresh_context()
	if not _pending_bgm.is_empty():
		play_bgm(_pending_bgm,0.5)

func play_sfx(sound_name: String,pitch_scale: float=1.0,volume_db: float=0.0) -> void:
	if not audio_unlocked or muted or not sfx_streams.has(sound_name):
		return
	var sound := sfx_players[current_sfx_idx]
	current_sfx_idx = (current_sfx_idx+1)%max_sfx_players
	sound.stop()
	var is_ui: bool = sound_name in [
		"menu_click", "wooden_click_light", "wooden_click_heavy",
		"wooden_toggle", "page_turn", "recipe_cooked",
		"coin_collect", "item_pickup", "quest_complete", "bell_ding",
		"path_reveal_chime"
	]
	sound.bus = UI_BUS if is_ui else ENVIRONMENT_BUS
	sound.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE if is_ui else AudioServer.PLAYBACK_TYPE_STREAM
	sound.stream = sfx_streams[sound_name]
	sound.pitch_scale = clampf(pitch_scale,0.5,2.0)
	sound.volume_db = clampf(SFX_VOLUME_DB+volume_db,-60.0,0.0)
	sound.play()
	_played_sfx += 1
	_last_sfx = sound_name

func play_victory_jingle() -> void:
	if not audio_unlocked or muted or not is_instance_valid(victory_player) or victory_player.stream==null:
		return
	victory_player.stop()
	_duck_bgm(-13.0,0.18)
	victory_player.play()
	_played_sfx += 1
	_last_sfx = "jingle_victory_fanfare"

func _restore_bgm_after_jingle() -> void:
	_duck_bgm(0.0,0.65)

func _duck_bgm(target_db: float,duration: float) -> void:
	if _duck_fade!=null and _duck_fade.is_valid():
		_duck_fade.kill()
	var bus := AudioServer.get_bus_index(BGM_BUS)
	if bus<0:
		return
	_duck_fade = create_tween()
	_duck_fade.tween_method(func(level: float): AudioServer.set_bus_volume_db(bus,level),AudioServer.get_bus_volume_db(bus),target_db,duration)

func play_water_sfx(sound_name: String,pitch_scale: float=1.0,volume_db: float=0.0) -> void:
	if not can_play_environment() or _menu_paused() or not sfx_streams.has(sound_name) or water_sfx_players.is_empty():
		return
	var sound := water_sfx_players[current_water_sfx_idx]
	current_water_sfx_idx = (current_water_sfx_idx+1)%max_water_sfx_players
	sound.stop()
	sound.bus = ENVIRONMENT_BUS
	sound.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	sound.stream = sfx_streams[sound_name]
	sound.pitch_scale = clampf(pitch_scale,0.5,2.0)
	sound.volume_db = clampf(SFX_VOLUME_DB+volume_db,-60.0,0.0)
	sound.play()
	_played_water_sfx += 1
	_last_water_sfx = sound_name

func update_coastal_ambience(target_db: float,active: bool,step_db: float=18.0) -> void:
	_ambience_desired = active
	_ambience_target_db = clampf(target_db,SILENCE_DB,-8.0) if active else SILENCE_DB
	if not is_instance_valid(ambience_player):
		return
	var allowed := active and can_play_environment() and not _menu_paused() and not is_underwater and sfx_streams.has("ambient_coastal_waves")
	if not allowed:
		if ambience_player.playing:
			ambience_player.volume_db = move_toward(ambience_player.volume_db,SILENCE_DB,step_db)
			if ambience_player.volume_db<=SILENCE_DB+1.0 or not can_play_environment() or _menu_paused():
				ambience_player.stop()
		return
	if ambience_player.stream!=sfx_streams.ambient_coastal_waves:
		ambience_player.stream = sfx_streams.ambient_coastal_waves
	if not ambience_player.playing:
		ambience_player.volume_db = minf(_ambience_target_db,-28.0)
		ambience_player.play()
	ambience_player.volume_db = move_toward(ambience_player.volume_db,_ambience_target_db,step_db)

func play_bgm(track_name: String,fade_duration: float=1.0) -> void:
	var key := track_name.trim_prefix("bgm_")
	if key=="underwater_ambient":
		key = "underwater_segaran"
	if not bgm_streams.has(key):
		return
	_pending_bgm = key
	if not audio_unlocked:
		return
	if current_bgm_track==key and bgm_player.playing:
		return
	_kill_fade()
	var outgoing := bgm_player
	var incoming := _bgm_players[1] if outgoing==_bgm_players[0] else _bgm_players[0]
	incoming.stop()
	incoming.stream = bgm_streams[key]
	incoming.pitch_scale = 1.0
	incoming.volume_db = SILENCE_DB if fade_duration>0 else BGM_VOLUME_DB
	incoming.play()
	bgm_player = incoming
	current_bgm_track = key
	if fade_duration<=0:
		outgoing.stop()
		return
	_fade = create_tween().set_parallel(true)
	_fade.tween_property(incoming,"volume_db",BGM_VOLUME_DB,fade_duration)
	_fade.tween_property(outgoing,"volume_db",SILENCE_DB,fade_duration)
	_fade.chain().tween_callback(func():
		if outgoing!=bgm_player:
			outgoing.stop()
	)

func stop_bgm(fade_duration: float=1.0) -> void:
	_pending_bgm = ""
	current_bgm_track = ""
	_kill_fade()
	if fade_duration<=0:
		for music in _bgm_players:
			music.stop()
		return
	_fade = create_tween().set_parallel(true)
	for music in _bgm_players:
		_fade.tween_property(music,"volume_db",SILENCE_DB,fade_duration)
	_fade.chain().tween_callback(func():
		if current_bgm_track.is_empty():
			for music in _bgm_players:
				music.stop()
	)

func _kill_fade() -> void:
	if _fade!=null and _fade.is_valid():
		_fade.kill()
	_fade = null

func set_underwater_filter(underwater: bool) -> void:
	if is_underwater==underwater:
		return
	is_underwater = underwater
	AudioServer.set_bus_effect_enabled(_environment_bus_index,_filter_slot,underwater)
	if underwater and is_instance_valid(ambience_player):
		ambience_player.stop()

func set_menu_paused(paused: bool) -> void:
	_menu_override = paused
	if paused:
		panic_player.stop()
		if is_instance_valid(ambience_player):
			ambience_player.stop()
		for water_sound in water_sfx_players:
			if is_instance_valid(water_sound):
				water_sound.stop()

func _menu_paused() -> bool:
	if _menu_override or get_tree().paused:
		return true
	var scene := get_tree().current_scene
	if scene!=null and bool(scene.get("modal_open")):
		return true
	var challenge: Variant = GameState.dive.get("challenge")
	return bool(GameState.dive.get("reading",false)) or (challenge is Dictionary and not challenge.is_empty())

func play_panic_heartbeat(active: bool) -> void:
	var allowed := active and audio_unlocked and not muted and _focused and not GameState.dive.is_empty() and not _menu_paused()
	if not allowed:
		panic_player.stop()
	elif not panic_player.playing and sfx_streams.has("heartbeat"):
		panic_player.stream = sfx_streams.heartbeat
		panic_player.play()

func toggle_mute() -> void:
	set_muted(not muted)

func set_muted(value: bool) -> void:
	muted = value
	_apply_mute()
	if muted:
		panic_player.stop()
		if is_instance_valid(ambience_player):
			ambience_player.stop()
		for water_sound in water_sfx_players:
			if is_instance_valid(water_sound):
				water_sound.stop()
	var config := ConfigFile.new()
	config.set_value("audio","muted",muted)
	config.save("user://audio.cfg")
	mute_changed.emit(muted)

func _load_preferences() -> void:
	var config := ConfigFile.new()
	if config.load("user://audio.cfg")==OK:
		muted = bool(config.get_value("audio","muted",false))

func _apply_mute() -> void:
	if _environment_bus_index>=0:
		AudioServer.set_bus_mute(_environment_bus_index,muted)
	if _ui_bus_index>=0:
		AudioServer.set_bus_mute(_ui_bus_index,muted)

func _process(delta: float) -> void:
	_poll_clock += delta
	if _poll_clock<0.15:
		return
	_poll_clock = 0.0
	_refresh_context()
	_observe_state()
	var low_oxygen := not GameState.dive.is_empty() and float(GameState.dive.get("oxygen",100))<20.0
	play_panic_heartbeat(low_oxygen)

func _refresh_context() -> void:
	var diving := not GameState.dive.is_empty()
	set_underwater_filter(diving)
	if GameState.player.is_empty():
		play_bgm("title_theme",0.4)
		return
	var desired := "coastal_day"
	if diving:
		var depth := float(GameState.dive.get("depth",0.0))
		var scene := get_tree().current_scene
		if depth<=0.0 and scene!=null and scene.get("nala") is Node2D:
			depth = maxf(0.0,(scene.nala.position.y-400.0)/28.0)
		var zone := str(GameState.dive.get("zone","")).to_lower()
		if str(GameState.dive.get("mode",""))=="boss":
			desired = "boss_gajah_mina"
		elif depth>=60.0 or "cave" in zone or "gua" in zone or "jalatunda" in zone:
			desired = "underwater_cave_deep"
		else:
			desired = "underwater_segaran"
	elif not GameState.shift.is_empty() or str(GameState.player.get("progress",{}).get("stage","dive"))=="night":
		desired = "kedai_waras_night"
	elif str(GameState.surface.get("area","hub"))=="forest":
		desired = "mangrove_forest"
	elif _near_village_hall():
		desired = "village_hall"
	elif str(EnvironmentState.snapshot().get("phase",""))=="senja":
		desired = "coastal_dusk"
	play_bgm(desired,1.0)

func _near_village_hall() -> bool:
	if str(GameState.surface.get("area","hub"))!="hub":
		return false
	var board: Dictionary = GameState.world.get("homestead",{}).get("permitBoard",{})
	if board.is_empty():
		return false
	var location := Vector2(float(GameState.surface.get("x",-10000)),float(GameState.surface.get("y",-10000)))
	return location.distance_to(Vector2(float(board.get("x",0)),float(board.get("y",0))))<320.0

func _observe_state() -> void:
	var id := str(GameState.player.get("id",""))
	if id.is_empty():
		_baseline_ready = false
		_last_player = ""
		return
	var dive_id := str(GameState.dive.get("id",""))
	var coins := int(GameState.player.get("coins",0))
	var loot := 0
	for item in GameState.dive.get("loot",[]):
		loot += int(item.get("quantity",1))
	var discoveries: int = GameState.adventure.get("discoveries",[]).size()+GameState.adventure.get("puzzles",[]).size()
	var oxygen := float(GameState.dive.get("oxygen",100))
	var now := Time.get_ticks_msec()/1000.0
	if _baseline_ready and id==_last_player:
		if dive_id!=_last_dive and (not dive_id.is_empty() or not _last_dive.is_empty()):
			play_sfx("water_splash",1.0,-1.0)
		if coins>_last_coins:
			play_sfx("coin_collect",1.0,-3.0)
		if (dive_id==_last_dive and loot>_last_loot) or discoveries>_last_discoveries:
			play_sfx("item_pickup",1.0,-2.0)
		if dive_id==_last_dive and not dive_id.is_empty() and _last_oxygen-oxygen>=6.0 and now-_oxygen_updated_at<4.0:
			play_sfx("player_hit",1.0,-2.0)
	if oxygen!=_last_oxygen:
		_oxygen_updated_at = now
	_last_player = id
	_last_dive = dive_id
	_last_coins = coins
	_last_loot = loot
	_last_discoveries = discoveries
	_last_oxygen = oxygen
	_baseline_ready = true

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_focused = false
		if is_instance_valid(panic_player):
			panic_player.stop()
		if is_instance_valid(ambience_player):
			ambience_player.stop()
		for water_sound in water_sfx_players:
			if is_instance_valid(water_sound):
				water_sound.stop()
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN or what==NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_focused = true

func _exit_tree() -> void:
	_kill_fade()
	if _duck_fade!=null and _duck_fade.is_valid():
		_duck_fade.kill()
	var music_bus := AudioServer.get_bus_index(BGM_BUS)
	if music_bus>=0: AudioServer.set_bus_volume_db(music_bus,0.0)
	if is_instance_valid(victory_player):
		victory_player.stop()
		victory_player.stream = null
	for music in _bgm_players:
		music.stop()
		music.stream = null
	for sound in sfx_players:
		sound.stop()
		sound.stream = null
	for water_sound in water_sfx_players:
		water_sound.stop()
		water_sound.stream = null
	if is_instance_valid(panic_player):
		panic_player.stop()
		panic_player.stream = null
	if is_instance_valid(ambience_player):
		ambience_player.stop()
		ambience_player.stream = null
	bgm_streams.clear()
	sfx_streams.clear()

func debug_status() -> Dictionary:
	return {
		"unlocked":audio_unlocked,
		"muted":muted,
		"track":current_bgm_track,
		"playing":is_instance_valid(bgm_player) and bgm_player.playing,
		"underwater":is_underwater,
		"heartbeat":is_instance_valid(panic_player) and panic_player.playing,
		"sfxPlayed":_played_sfx,
		"lastSfx":_last_sfx,
		"waterSfxPlayed":_played_water_sfx,
		"lastWaterSfx":_last_water_sfx,
		"coastalAmbiencePlaying":is_instance_valid(ambience_player) and ambience_player.playing,
		"coastalAmbienceDb":ambience_player.volume_db if is_instance_valid(ambience_player) else SILENCE_DB,
	}
