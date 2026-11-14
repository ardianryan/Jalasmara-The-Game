extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.size=Vector2i(960,540)
	var story = load("res://scripts/PhaseOneCutscenes.gd")
	var frame_script = load("res://scripts/CutsceneFrame.gd")
	assert(story!=null and frame_script!=null)
	var ids := ["prologue","first_dive","first_kedai","first_service","garden_crisis","saras_visit","cave_warning","earthquake","boss_intro","boss_phase_two","victory","epilogue"]
	for id in ids:
		var sequence:Dictionary=story.sequence(id)
		assert(not sequence.is_empty() and sequence.lines.size()>=2,"Missing Phase 1 cinematic: "+id)
		for beat in sequence.lines:
			assert(not str(beat.get("shot","")).is_empty())
			assert(not str(beat.get("name","")).is_empty())
			assert(not str(beat.get("text","")).is_empty())
	assert(story.sequence("unknown").is_empty())
	var player := {"id":"fixture","progress":{"tutorial":false,"day":1,"stage":"dive"}}
	assert(story.eligible_on_load(player,{}, {})=="prologue")
	player.progress.tutorial=true
	assert(story.eligible_on_load(player,{}, {}).is_empty())
	player.progress.day=2
	assert(story.eligible_on_load(player,{}, {})=="garden_crisis")
	player.progress.day=3
	player.progress.stage="boss"
	assert(story.eligible_on_load(player,{}, {})=="earthquake")
	assert(story.eligible_on_load(player,{"id":"dive"},{}).is_empty())
	player.progress.stage="done"
	assert(story.eligible_on_load(player,{}, {})=="epilogue")
	var frame:Control=frame_script.new()
	root.add_child(frame)
	await process_frame
	frame.present("Gajah Mina",story.sequence("boss_intro").lines[0],1,3,"boss_intro")
	assert(frame.visible and frame.boss_art.visible)
	assert(frame.progress_label.text=="1 / 3")
	frame.present("Kebun",story.sequence("garden_crisis").lines[0],1,4,"garden_crisis")
	assert(not frame.boss_art.visible)
	frame.free()
	print("PHASE ONE CUTSCENES PASS: twelve beats, progression gates and cinematic frame")
	quit()
