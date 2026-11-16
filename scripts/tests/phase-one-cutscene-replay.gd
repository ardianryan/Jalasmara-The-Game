extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var story = load("res://scripts/PhaseOneCutscenes.gd")
	var main_script = load("res://scripts/Main.gd")
	assert(story!=null and main_script!=null)
	var state := root.get_node("GameState")
	var previous_player: Dictionary = state.player
	var previous_dive: Dictionary = state.dive
	var previous_shift: Dictionary = state.shift
	var player := {"id":"cutscene-replay-fixture-%d" % Time.get_ticks_usec(),"progress":{"tutorial":true,"day":1,"stage":"dive"}}
	var seen := {}
	var has_seen := func(id: String) -> bool: return bool(seen.get(id,false))
	var dive := {"id":"first-dive","mode":"dive","challenge":{}}
	assert(story.next_unseen_on_load(player,dive,{},has_seen)=="first_dive")
	dive.challenge={"id":"active-quiz"}
	assert(story.next_unseen_on_load(player,dive,{},has_seen).is_empty())
	dive.challenge={}
	seen.first_dive=true
	assert(story.next_unseen_on_load(player,dive,{},has_seen).is_empty())
	player.progress.day=3
	player.progress.stage="boss"
	dive={"id":"boss-dive","mode":"boss","hits":2,"requiredHits":6,"challenge":{}}
	assert(story.next_unseen_on_load(player,dive,{},has_seen)=="boss_intro")
	dive.hits=3
	assert(story.next_unseen_on_load(player,dive,{},has_seen)=="boss_phase_two")
	seen.boss_intro=true
	assert(story.next_unseen_on_load(player,dive,{},has_seen)=="boss_phase_two")
	dive.challenge={"id":"unresolved-quiz"}
	assert(story.next_unseen_on_load(player,dive,{},has_seen).is_empty())
	dive.challenge={}
	seen.boss_phase_two=true
	assert(story.next_unseen_on_load(player,dive,{},has_seen).is_empty())
	player.progress.stage="done"
	assert(story.next_unseen_on_load(player,{}, {},has_seen)=="victory")
	seen.victory=true
	assert(story.next_unseen_on_load(player,{}, {},has_seen)=="epilogue")
	seen.epilogue=true
	assert(story.next_unseen_on_load(player,{}, {},has_seen).is_empty())
	assert(story.next_unseen_on_load(player,{}, {"id":"active-shift"},has_seen).is_empty())

	state.player=player
	state.dive={}
	state.shift={}
	var main: Node2D = main_script.new()
	main.modal_open=true
	var calls := {"count":0}
	main._play_cutscene("boss_phase_two",func(): calls.count+=1)
	main._play_cutscene("boss_phase_two",func(): calls.count+=10)
	assert(int(calls.count)==0,"A covered modal cannot acknowledge a cutscene")
	assert(main.cutscene_id.is_empty() and main.cutscene_queue.size()==1)
	assert(main.cutscene_queue[0].done.size()==2,"Repeated trigger must share one queued scene")
	main._resume_pending_cutscenes()
	assert(int(calls.count)==0 and main.cutscene_queue.size()==1)
	main._play_cutscene("unknown",func(): calls.count+=100)
	assert(int(calls.count)==0,"Unknown scene cannot report completion")
	main.cutscene_seen_session.boss_phase_two=true
	main.modal_open=false
	main._resume_pending_cutscenes()
	assert(int(calls.count)==11 and main.cutscene_queue.is_empty(),"Queued continuations run only after the scene has been seen")
	main._play_cutscene("boss_phase_two",func(): calls.count+=1)
	assert(int(calls.count)==12,"A completed local scene may release its continuation once")
	main.free()
	state.player=previous_player
	state.dive=previous_dive
	state.shift=previous_shift
	print("PHASE ONE CUTSCENE REPLAY PASS: reload milestones, modal queue and completion")
	quit()
