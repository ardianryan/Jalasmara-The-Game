extends Node

const WaterFieldScript = preload("res://scripts/land/WaterField.gd")
const CREST_PHASE := 0.34

var actor: Node2D
var area := "hub"
var _previous := Vector2.ZERO
var _distance := 0.0
var _cadence := 0.0
var _breath := 0.0
var _ambience := 0.0
var _step := 0
var _initialized := false
var _was_underwater := false
var _has_traversal := false
var _material := ""
var _last_step := ""
var _water_clock := 0.0
var _wave_cooldown := 0.0
var _water_distance := 999.0
var _water_steps := 0
var _last_water_sfx := ""
var _emitter_phases: Dictionary = {}
var _water_fields: Dictionary = {}
var _map_signatures: Dictionary = {}
var _surface_polygons: Dictionary = {}
var _foot_contact_source := Callable()
var _foot_source_configured := false
var _contact_epoch := ""
var _contact_mode := ""
var _contact_sequence := 0
var _retired_contact_epochs: Dictionary = {}
var _contact_audio := {"played":0,"discarded":0,"duplicates":0,"invalidBatches":0,"lastId":"","lastReason":"unwired"}

func set_foot_contact_source(source: Callable) -> void:
	_foot_contact_source = source
	_foot_source_configured = not source.is_null()
	if not _contact_epoch.is_empty(): _retired_contact_epochs[_contact_epoch] = true
	_contact_epoch = ""
	_contact_mode = ""
	_contact_sequence = 0
	_drain_legacy_contacts()
	_distance = 0.0
	_cadence = 0.0

func _drain_legacy_contacts() -> void:
	if is_instance_valid(actor) and "swim_sprite" in actor and is_instance_valid(actor.get("swim_sprite")) and actor.get("swim_sprite").has_method("consume_foot_contacts"):
		actor.get("swim_sprite").consume_foot_contacts()

func _contact_paused() -> bool:
	return ViewportLayout.host_paused or EnvironmentState.clock_paused or ("frozen" in actor and bool(actor.get("frozen")))

func _poll_foot_contacts(underwater: bool, relocated: bool) -> Dictionary:
	var raw: Variant = _foot_contact_source.call() if _foot_contact_source.is_valid() else {"mode":"legacy"}
	if not raw is Dictionary: raw = {}
	var batch: Dictionary = raw
	var mode := str(batch.get("mode","suppressed"))
	if mode not in ["pilot","legacy","suppressed"]: mode = "suppressed"
	var epoch := str(batch.get("epoch",""))
	var latest := maxi(0,int(batch.get("latestSequence",0)))
	var events: Array = batch.get("contacts",[]) if batch.get("contacts",[]) is Array else []
	var retired: bool = not epoch.is_empty() and _retired_contact_epochs.has(epoch)
	var barrier := mode!=_contact_mode or epoch!=_contact_epoch
	var handled := mode!="legacy" or barrier or retired
	if handled: _drain_legacy_contacts()
	if retired:
		_contact_audio.discarded += events.size()
		_contact_audio.lastReason = "retired_epoch"
		return {"handled":true,"contacts":[]}
	if barrier:
		var same_epoch := epoch==_contact_epoch
		if not _contact_epoch.is_empty() and epoch!=_contact_epoch: _retired_contact_epochs[_contact_epoch] = true
		_contact_epoch = epoch
		_contact_mode = mode
		_contact_sequence = maxi(_contact_sequence,latest) if same_epoch else latest
		_contact_audio.discarded += events.size()
		_contact_audio.lastReason = "source_barrier"
		return {"handled":true,"contacts":[]}
	if mode=="legacy": return {"handled":false,"contacts":[]}
	var suppressed := mode!="pilot" or epoch.is_empty() or not bool(batch.get("validated",false)) or bool(batch.get("paused",false)) or _contact_paused() or underwater or relocated or not AudioManager.can_play_environment()
	if suppressed:
		_contact_sequence = maxi(_contact_sequence,latest)
		_contact_audio.discarded += events.size()
		_contact_audio.lastReason = "suppressed"
		return {"handled":true,"contacts":[]}
	var accepted: Array[Dictionary] = []
	var seen := _contact_sequence
	var invalid := latest<_contact_sequence
	for value in events:
		if not value is Dictionary:
			invalid = true
			continue
		var event: Dictionary = value
		var sequence := int(event.get("sequence",-1))
		if sequence<=_contact_sequence:
			_contact_audio.duplicates += 1
			continue
		if sequence==seen:
			_contact_audio.duplicates += 1
			continue
		var logical: Variant = event.get("logical")
		var plant: Variant = event.get("worldPlant")
		if sequence<seen or sequence>latest or str(event.get("side","")) not in ["left","right"] or str(event.get("kind","")) not in ["landing","stop_settlement"] or not FOOTSTEPS.has(str(event.get("material",""))) or str(event.get("supportId","")).is_empty() or not logical is Vector2 or not plant is Vector3:
			invalid = true
			continue
		if not logical.is_finite() or not plant.is_finite():
			invalid = true
			continue
		seen = sequence
		accepted.append(event)
	_contact_sequence = maxi(_contact_sequence,latest)
	if invalid:
		_contact_audio.invalidBatches += 1
		_contact_audio.discarded += events.size()
		_contact_audio.lastReason = "invalid_batch"
		return {"handled":true,"contacts":[]}
	_contact_audio.lastReason = "validated"
	return {"handled":true,"contacts":accepted}

const FOOTSTEPS := {
	"dock":"footstep_dock", "bridge":"footstep_bridge", "sand":"footstep_sand",
	"stone":"footstep_stone", "dirt":"footstep_dirt", "grass":"footstep_grass",
	"wood":"footstep_wood", "water_shallow":"footstep_water_shallow",
}

func configure(player: Node2D, place := "hub") -> void:
	actor = player
	area = place
	_initialized = false
	_cadence = 0
	_ambience = 0
	_wave_cooldown = 0.0
	_emitter_phases.clear()
	_surface_polygons.clear()
	if _foot_source_configured:
		if not _contact_epoch.is_empty(): _retired_contact_epochs[_contact_epoch] = true
		_contact_epoch = ""
		_contact_mode = ""
		_contact_sequence = 0
	_has_traversal = false
	for property in actor.get_property_list():
		if str(property.name) == "traversal_state": _has_traversal = true

func _get_water_field(map: Dictionary):
	var surfaces: Array = map.get("surfaces", [])
	var sig := "%s:%d:%d:%d" % [
		area,
		surfaces.size(),
		int(map.get("width", 0)),
		int(map.get("height", 0)),
	]
	if _water_fields.has(area) and str(_map_signatures.get(area, "")) == sig:
		return _water_fields[area]
	var wf = WaterFieldScript.new()
	var enriched := map.duplicate()
	if not enriched.has("id"):
		enriched["id"] = area
	wf.configure(enriched)
	_water_fields[area] = wf
	_map_signatures[area] = sig
	return wf

func material_at(point: Vector2) -> String:
	var maps: Dictionary = GameState.world.get("landMaps",{})
	var map: Dictionary = maps.get(area,{})
	if _has_traversal:
		var traversal: Dictionary = actor.get("traversal_state")
		if bool(traversal.get("onConnector",false)):
			var surface := str(traversal.get("footstepMaterial",""))
			if FOOTSTEPS.has(surface): return surface
	for stair in map.get("stairs",[]):
		var path: Array = stair.get("path",[])
		if path.size()<2: continue
		for index in range(path.size()-1):
			var a := Vector2(float(path[index][0]),float(path[index][1]))
			var b := Vector2(float(path[index+1][0]),float(path[index+1][1]))
			var progress := (point-a).dot(b-a)/maxf(1,(b-a).length_squared())
			if progress>=0 and progress<=1 and point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b)) <= float(stair.get("width",90))/2:
				var surface := str(stair.get("material","stone"))
				if FOOTSTEPS.has(surface): return surface
	var selected := ""
	var priority := -INF
	var elevation := -INF
	if not _surface_polygons.has(area):
		_surface_polygons[area] = preload("res://scripts/land/LandSurfaceQueryCache.gd").new()
	var queries:RefCounted = _surface_polygons[area]
	var surfaces:Array = map.get("surfaces",[])
	for index in range(surfaces.size()):
		var surface:Dictionary = surfaces[index]
		var polygon:Array = surface.get("polygon",[])
		if polygon.size()<3 or not queries.contains(point,polygon,index): continue
		var candidate := str(surface.get("material",""))
		var candidate_priority := float(surface.get("priority",0))
		var candidate_elevation := float(surface.get("elevation",0))
		if FOOTSTEPS.has(candidate) and (candidate_priority>priority or (candidate_priority==priority and candidate_elevation>elevation)):
			selected = candidate
			priority = candidate_priority
			elevation = candidate_elevation
	return selected

func _process(delta: float) -> void:
	if not is_instance_valid(actor): return
	var underwater := not GameState.dive.is_empty()
	if not _initialized or underwater!=_was_underwater:
		_previous = actor.position
		_distance = 0
		_breath = 0
		_wave_cooldown = 0.0
		_emitter_phases.clear()
		_initialized = true
		_was_underwater = underwater
	var travelled := actor.position.distance_to(_previous)
	_previous = actor.position
	var pilot_contacts := {"handled":false,"contacts":[]}
	if _foot_source_configured: pilot_contacts = _poll_foot_contacts(underwater,travelled>80)
	if travelled>80:
		_distance = 0
		return
	_material = "underwater" if underwater else material_at(actor.position)
	if not AudioManager.can_play_environment():
		if "swim_sprite" in actor and is_instance_valid(actor.get("swim_sprite")) and actor.get("swim_sprite").has_method("consume_foot_contacts"):
			actor.get("swim_sprite").consume_foot_contacts()
		_distance = 0
		_cadence = 0
		_breath = 0
		_ambience = 0
		_wave_cooldown = 0.0
		_emitter_phases.clear()
		AudioManager.update_coastal_ambience(-60.0, false, 30.0)
		return
	_cadence += delta
	_breath += delta
	_ambience += delta
	_water_clock += delta
	_wave_cooldown = maxf(0.0, _wave_cooldown - delta)
	if underwater:
		AudioManager.update_coastal_ambience(-60.0, false, 24.0)
		if _breath>3.4:
			_breath = 0
			AudioManager.play_sfx("diver_breath",0.97+float(_step%3)*0.025,-18)
		if travelled>0.4 and _cadence>1.6:
			_cadence = 0
			AudioManager.play_sfx("swoosh_water",0.94+float(_step%3)*0.035,-23)
			_step += 1
		if actor.position.y>1900 and _ambience>7.5:
			_ambience = 0
			AudioManager.play_sfx("water_drip",0.88+float(_step%4)*0.04,-22)
	else:
		_distance += travelled
		if bool(pilot_contacts.handled):
			_distance = 0.0
			_cadence = 0.0
			for event in pilot_contacts.contacts:
				_last_step = FOOTSTEPS[str(event.material)]
				AudioManager.play_sfx(_last_step,0.94+float(_step%4)*0.035,-17)
				_step += 1
				_contact_audio.played += 1
				_contact_audio.lastId = _contact_epoch+":"+str(event.sequence)
		else:
			var contact := false
			var has_gait: bool = "swim_sprite" in actor and is_instance_valid(actor.get("swim_sprite")) and actor.get("swim_sprite").has_method("consume_foot_contacts")
			if has_gait:
				contact = not actor.get("swim_sprite").consume_foot_contacts().is_empty()
			if (contact if has_gait else _distance>38 and _cadence>0.24):
				_distance = fmod(_distance,38)
				_cadence = 0
				if FOOTSTEPS.has(_material):
					_last_step = FOOTSTEPS[_material]
					AudioManager.play_sfx(_last_step,0.94+float(_step%4)*0.035,-17)
					_step += 1
		if _material in ["dock","bridge"] and _ambience>13:
			_ambience = 0
			AudioManager.play_sfx("rope_creak",0.94,-25)
		_update_water_audio(delta)

func _update_water_audio(delta: float) -> void:
	var maps: Dictionary = GameState.world.get("landMaps", {})
	var map: Dictionary = maps.get(area, {})
	if map.is_empty():
		AudioManager.update_coastal_ambience(-60.0, false, 18.0)
		return
	var wf = _get_water_field(map)
	if wf.wet_cells <= 0 or wf.emitters.is_empty():
		AudioManager.update_coastal_ambience(-60.0, false, 18.0)
		return

	var weather: Dictionary = EnvironmentState.snapshot()
	var wind := clampf(absf(float(weather.get("wind_x", 0.0))) / 30.0, 0.08, 1.0)
	var rain := clampf(float(weather.get("rain", 0.0)), 0.0, 1.0)
	var motion := 0.2 if bool(weather.get("reduced_motion", false)) else 1.0

	_water_distance = wf.nearest_water_distance(actor.position)
	var is_river: bool = wf.is_river
	var near_db := -24.5 if is_river else -17.5
	var far_db := -38.5 if is_river else -31.5
	var atten := clampf((_water_distance - 45.0) / 420.0, 0.0, 1.0)
	var target_db := lerpf(near_db, far_db, atten) + wind * 1.8 + rain * 1.0
	AudioManager.update_coastal_ambience(target_db, true, maxf(1.5, delta * 22.0))

	# Synchronized wave/splash one-shots driven by swell crest events
	var events: Array[Dictionary] = []
	var parent_scene := actor.get_parent()
	if is_instance_valid(parent_scene):
		var lr: Variant = parent_scene.get("land_renderer")
		if lr is Node and is_instance_valid(lr):
			var wn: Variant = lr.get("water_node")
			if wn is Node and is_instance_valid(wn) and wn.has_method("pop_swell_events"):
				events = wn.pop_swell_events()

	if events.is_empty():
		var rate := (0.36 if is_river else 0.28) * (0.92 + wind * 0.26)
		var energy := clampf(0.58 + wind * 0.32 + rain * 0.10, 0.35, 1.0)
		var nearby: Array[Dictionary] = wf.emitters_near(actor.position, 440.0, 6)
		for emitter in nearby:
			var id := str(emitter.id)
			var offset := float(emitter.get("phase_offset", 0.0)) / TAU
			var curr := fposmod(_water_clock * rate * motion + offset, 1.0)
			var prev := float(_emitter_phases.get(id, fposmod(curr - delta * rate * motion, 1.0)))
			_emitter_phases[id] = curr
			if prev < CREST_PHASE and curr >= CREST_PHASE:
				events.append({
					"id": id,
					"position": emitter.position,
					"kind": str(emitter.kind),
					"energy": energy,
				})

	if _wave_cooldown > 0.0 or events.is_empty():
		return

	var best_event: Dictionary = {}
	var best_dist := 440.0
	for ev in events:
		var pos: Vector2 = ev.get("position", Vector2(-9999, -9999))
		var dist := actor.position.distance_to(pos)
		if dist < best_dist:
			best_dist = dist
			best_event = ev

	if best_event.is_empty():
		return

	var kind := str(best_event.get("kind", "sand"))
	var energy := float(best_event.get("energy", 0.65))
	var sound_name := "coastal_wave_lap"
	if kind in ["pile", "rock"] and (not is_river or energy >= 0.72):
		sound_name = "wave_crash_rock"
	elif not is_river and (wind >= 0.42 or energy >= 0.76):
		sound_name = "coastal_wave_surge"
	else:
		sound_name = "coastal_wave_lap"

	var dist_ratio := clampf(best_dist / 440.0, 0.0, 1.0)
	var base_vol := -14.5 if is_river else -11.5
	var vol_db := lerpf(base_vol, base_vol - 14.0, dist_ratio)
	var pitch := 0.94 + float(_water_steps % 4) * 0.03
	AudioManager.play_water_sfx(sound_name, pitch, vol_db)
	_last_water_sfx = sound_name
	_water_steps += 1
	_wave_cooldown = 2.1 if is_river else 1.55

func _exit_tree() -> void:
	if is_instance_valid(AudioManager):
		AudioManager.update_coastal_ambience(-60.0, false, 60.0)

func debug_status() -> Dictionary:
	var status := {
		"steps":_step,
		"area":area,
		"underwater":_was_underwater,
		"material":_material,
		"lastStep":_last_step,
		"waterDistance":_water_distance,
		"waterSfxSteps":_water_steps,
		"lastWaterSfx":_last_water_sfx,
	}
	if _foot_source_configured:
		status["contactSource"] = {"epoch":_contact_epoch,"mode":_contact_mode,"sequence":_contact_sequence,"audio":_contact_audio.duplicate()}
	return status
