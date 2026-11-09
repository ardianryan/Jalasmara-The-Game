extends SceneTree

class Walker extends Node2D:
	var swim_sprite: Sprite2D
	var traversal_state := {"onConnector":true,"footstepMaterial":"stone"}
	var frozen := false

class ContactSource extends Node:
	var batch: Dictionary = {}
	func drain() -> Dictionary:
		var result := batch.duplicate(true)
		batch["contacts"] = []
		return result

var actor: Walker
var source: ContactSource
var foley: Node
var audio: Node
var checks := 0

func _initialize() -> void: call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
		return false
	checks += 1
	return true

func _event(sequence: int, material := "wood", kind := "landing") -> Dictionary:
	return {"sequence":sequence,"side":"left" if sequence%2==0 else "right","kind":kind,"logical":Vector2(50,50) if material=="stone" else Vector2(220,50),"worldPlant":Vector3(50,-50,0) if material=="stone" else Vector3(220,-50,0),"supportId":"court" if material=="stone" else "wood_platform","material":material,"acceptedDistance":float(sequence*32),"physicsFrame":sequence,"processFrame":sequence}

func _offer(epoch: String, latest: int, events: Array, paused := false, valid := true, mode := "pilot") -> void:
	source.batch = {"mode":mode,"epoch":epoch,"latestSequence":latest,"contacts":events,"paused":paused,"validated":valid}

func _played() -> int: return int(audio.debug_status().sfxPlayed)

func _legacy_contact() -> void:
	actor.swim_sprite.set_locomotion(Vector2(100,0),.4)

func _tick() -> void: foley._process(.1)

func _run() -> void:
	audio = root.get_node("AudioManager")
	audio.set_process(false)
	audio.audio_unlocked = true
	audio.muted = false
	audio._focused = true
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"),true)
	var clock := root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused = false
	root.get_node("ViewportLayout").host_paused = false
	var state := root.get_node("GameState")
	state.player = {"appearance":"male_default","progress":{"day":1,"stage":"dive"}}
	state.dive = {}
	state.world = {"landMaps":{"hub":{"width":400,"height":200,"stairs":[],"surfaces":[{"id":"court","material":"stone","elevation":0,"priority":0,"polygon":[[0,0],[400,0],[400,200],[0,200]]},{"id":"wood_platform","material":"wood","elevation":0,"priority":10,"polygon":[[200,0],[300,0],[300,100],[200,100]]}]}}}
	actor = Walker.new()
	actor.position = Vector2(50,50)
	actor.swim_sprite = load("res://scripts/CharacterVisual.gd").new()
	actor.add_child(actor.swim_sprite)
	root.add_child(actor)
	actor.swim_sprite.set_process(false)
	foley = load("res://scripts/WorldFoley.gd").new()
	root.add_child(foley)
	foley.set_process(false)
	foley.configure(actor,"hub")
	_tick()
	var before := _played()
	_legacy_contact()
	_tick()
	if not _check(_played()==before+1 and audio.debug_status().lastSfx=="footstep_stone","Unwired actual CharacterVisual contact must preserve legacy sound"): return
	before = _played()
	_tick()
	if not _check(_played()==before and not foley.debug_status().has("contactSource"),"Unwired idle/default diagnostics must remain unchanged"): return
	source = ContactSource.new()
	root.add_child(source)
	foley.set_foot_contact_source(Callable(source,"drain"))
	_offer("A",0,[])
	_tick()
	before = _played()
	var voice_start: int = audio.current_sfx_idx
	_offer("A",3,[_event(1,"stone"),_event(2),_event(3)])
	_tick()
	if not _check(_played()==before+3,"Provider batch must produce all three distinct contact requests"): return
	for i in range(3):
		var name := "footstep_stone" if i==0 else "footstep_wood"
		var voice: AudioStreamPlayer = audio.sfx_players[(voice_start+i)%audio.max_sfx_players]
		if not _check(voice.stream==audio.sfx_streams[name],"Each actual AudioManager voice must use its event material"): return
	if not _check(foley.material_at(Vector2(220,50))=="stone" and audio.debug_status().lastSfx=="footstep_wood","Validated plant wood must not inherit actor's stone traversal override"): return
	before = _played()
	_offer("A",3,[_event(1),_event(2),_event(3)])
	_tick()
	if not _check(_played()==before,"Repeated contact IDs must not replay"): return
	_offer("A",5,[_event(4),_event(5)])
	_tick()
	if not _check(_played()==before+2,"Second batch must preserve both records"): return
	before = _played()
	_offer("A",7,[_event(6),_event(7,"unknown")])
	_tick()
	if not _check(_played()==before and foley.debug_status().contactSource.audio.invalidBatches==1,"Malformed material must reject the entire batch before any play"): return
	_offer("A",7,[_event(6),_event(7)])
	_tick()
	if not _check(_played()==before,"Rejected batch must not replay after correction"): return

	audio.muted = true
	_legacy_contact()
	_offer("A",8,[_event(8)])
	_tick()
	audio.muted = false
	_tick()
	if not _check(_played()==before and actor.swim_sprite.locomotion_state().pendingContacts==0,"Mute must drain both sources without post-unmute backlog"): return
	_offer("A",9,[_event(9)])
	_tick()
	if not _check(_played()==before+1,"Fresh contact after unmute must still play"): return
	before = _played()
	_legacy_contact()
	_offer("A",10,[_event(10)],true)
	_tick()
	_offer("A",10,[])
	_tick()
	if not _check(_played()==before and actor.swim_sprite.locomotion_state().pendingContacts==0,"Provider pause must discard pending contacts without resume replay"): return
	_offer("A",11,[_event(11)],false,false)
	_tick()
	if not _check(_played()==before,"Geometry-unvalidated contact must remain silent"): return
	_offer("A",12,[_event(12,"wood","stop_settlement")])
	_tick()
	_tick()
	if not _check(_played()==before+1,"A real stop settlement plays exactly once while unchanged idle is silent"): return
	before = _played()
	clock.clock_paused = true
	_offer("A",13,[_event(13)])
	_tick()
	clock.clock_paused = false
	_tick()
	if not _check(_played()==before,"Clock pause must suppress pending pilot contact and backlog"): return
	root.get_node("ViewportLayout").host_paused = true
	_offer("A",14,[_event(14)])
	_tick()
	root.get_node("ViewportLayout").host_paused = false
	actor.frozen = true
	_offer("A",15,[_event(15)])
	_tick()
	actor.frozen = false
	_tick()
	if not _check(_played()==before,"Host and actor pause must suppress pilot contacts"): return
	audio._focused = false
	_offer("A",16,[_event(16)])
	_tick()
	audio._focused = true
	audio.audio_unlocked = false
	_offer("A",17,[_event(17)])
	_tick()
	audio.audio_unlocked = true
	_tick()
	if not _check(_played()==before,"Focus/locked-audio suppression must not accumulate a burst"): return
	_offer("B",1,[_event(1)])
	_legacy_contact()
	_tick()
	if not _check(_played()==before,"New epoch must baseline queued records and legacy contacts"): return
	_offer("B",2,[_event(2)])
	_tick()
	if not _check(_played()==before+1,"Fresh event in new epoch must play"): return
	before = _played()
	_offer("A",18,[_event(18)])
	_tick()
	if not _check(_played()==before,"Retired epoch cannot become a fresh contact source"): return
	_offer("B",0,[],false,false,"legacy")
	_tick()
	_offer("B",0,[])
	_tick()
	_offer("B",2,[_event(2)])
	_tick()
	if not _check(_played()==before,"Mode barriers within one epoch must not rewind its contact watermark"): return
	var oversized: Array = []
	for i in range(3,68): oversized.append(_event(i))
	_offer("B",68,oversized)
	_tick()
	if not _check(_played()==before and foley.debug_status().contactSource.audio.lastReason=="oversized_batch","Oversized producer batch must atomically discard without per-event playback"): return
	_offer("B",68,[_event(68)])
	_tick()
	if not _check(_played()==before,"Oversized batch watermark must prevent deferred replay"): return
	_offer("B",69,[_event(69)])
	_tick()
	if not _check(_played()==before+1,"Fresh bounded batch after an oversized rejection must recover"): return
	before = _played()
	_offer("B",70,[_event(70)])
	state.dive = {"id":"consumer-underwater"}
	_tick()
	state.dive = {}
	_tick()
	if not _check(_played()==before,"Underwater land contacts must be drained without surfacing replay"): return
	actor.position.x += 100
	_legacy_contact()
	_offer("B",71,[_event(71)])
	_tick()
	_tick()
	if not _check(_played()==before and actor.swim_sprite.locomotion_state().pendingContacts==0,"Relocation must drain both sources, not play stale contacts"): return
	_offer("",0,[],false,false,"legacy")
	_legacy_contact()
	_tick()
	if not _check(_played()==before,"Fallback transition must not replay hidden legacy queue"): return
	_legacy_contact()
	_tick()
	if not _check(_played()==before+1,"Stable explicit legacy mode resumes fresh actual CharacterVisual contacts"): return
	before = _played()
	var disposable := ContactSource.new()
	root.add_child(disposable)
	disposable.batch = {"mode":"pilot","epoch":"C","latestSequence":0,"validated":true,"contacts":[]}
	foley.set_foot_contact_source(Callable(disposable,"drain"))
	_tick()
	disposable.free()
	_legacy_contact()
	_tick()
	if not _check(_played()==before,"Freed provider must make a fresh fallback barrier"): return
	_legacy_contact()
	_tick()
	if not _check(_played()==before+1,"Invalid Callable must recover legacy without engine errors"): return
	before = _played()
	actor.swim_sprite.free()
	actor.swim_sprite = null
	foley.set_foot_contact_source(Callable(source,"drain"))
	_offer("D",0,[])
	_tick()
	for i in range(3):
		actor.position.x += 20
		_tick()
	_offer("",0,[],false,false,"legacy")
	_tick()
	for i in range(8): _tick()
	if not _check(_played()==before,"No-gait fallback must not turn prior pilot travel into a delayed distance step"): return
	actor.position.x += 40
	_tick()
	if not _check(_played()==before+1,"Fresh no-gait distance fallback must retain original behavior"): return
	print("VALIDATED CONTACT FOLEY PASS: ",checks," actual consumer/audio assertions; provider remains mocked and runtime unwired")
	foley.free()
	actor.free()
	source.free()
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
	for bus_name in [audio.ENVIRONMENT_BUS,audio.UI_BUS]:
		var bus := AudioServer.get_bus_index(bus_name)
		if bus<0: continue
		for effect in range(AudioServer.get_bus_effect_count(bus)-1,-1,-1):
			AudioServer.remove_bus_effect(bus,effect)
	audio._filter = null
	audio.queue_free()
	await process_frame
	await process_frame
	await create_timer(.35).timeout
	quit()
