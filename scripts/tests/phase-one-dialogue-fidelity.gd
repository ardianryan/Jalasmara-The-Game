extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _never_seen(_id: String) -> bool:
	return false

func _run() -> void:
	var story = load("res://scripts/PhaseOneCutscenes.gd")
	var prologue: Dictionary = story.sequence("prologue")
	var garden: Dictionary = story.sequence("garden_crisis")
	var quake: Dictionary = story.sequence("earthquake")
	assert(prologue.lines.size() == 12)
	assert(garden.lines.size() == 5)
	assert(prologue.lines[5].name == "Beno")
	assert(prologue.lines[6].name == "Nala")
	assert(str(prologue.lines[6].text).contains("warga di pasar"))
	assert(prologue.lines[7].name == "Mbah Wira")
	assert(str(prologue.lines[7].text).contains("Kedai Waras"))
	assert(garden.lines[1].name == "Gito")
	assert(garden.lines[2].name == "Petugas Korporasi")
	assert(str(garden.lines[2].text).contains("kadar garam dan unsur hara"))
	assert(garden.lines[3].name == "Ki Lurah Wirabhumi")
	assert(garden.lines[4].name == "Kinasih")
	assert(str(quake.lines[0].shot).contains("Pagi"))
	assert(str(quake.lines[0].shot).contains("malam ketiga"))
	assert(story.eligible_on_load({"progress":{"tutorial":true,"day":3,"stage":"boss"}}, {}, {}) == "earthquake")
	assert(story.eligible_on_load({"progress":{"tutorial":true,"day":3,"stage":"boss"}}, {"mode":"boss","hits":3,"requiredHits":6}, {}) == "boss_phase_two")
	var boss_player := {"progress":{"tutorial":true,"day":3,"stage":"boss"}}
	var interrupted_intro := {"mode":"boss","hits":0,"requiredHits":6}
	assert(story.next_unseen_on_load(boss_player, interrupted_intro, {}, Callable(self, "_never_seen")) == "boss_intro")
	interrupted_intro.hits = 3
	assert(story.next_unseen_on_load(boss_player, interrupted_intro, {}, Callable(self, "_never_seen")) == "boss_phase_two")
	var frame: Control = load("res://scripts/CutsceneFrame.gd").new()
	root.add_child(frame)
	await process_frame
	for index in [6, 7, 8]:
		frame.present(str(prologue.title), prologue.lines[index - 1], index, prologue.lines.size(), "prologue")
		assert(frame.backdrop_key == "griya-arrival-dock", "Return exchange left the Griya dock")
	frame.present(str(prologue.title), prologue.lines[8], 9, prologue.lines.size(), "prologue")
	assert(frame.backdrop_key == "kedai-interior", "Kedai handoff used the dock backdrop")
	frame.present(str(garden.title), garden.lines[2], 3, garden.lines.size(), "garden_crisis")
	assert(frame.backdrop_key == "garden-crisis", "Guard threat left the garden")
	frame.free()
	print("PHASE ONE DIALOGUE FIDELITY PASS: return exchange, garden threat, morning quake and backdrop gates")
	quit()
