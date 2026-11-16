extends SceneTree

const ORDER := [
	"prologue", "first_dive", "first_kedai", "first_service",
	"garden_crisis", "saras_visit", "cave_warning", "earthquake",
	"boss_intro", "boss_phase_two", "victory", "epilogue",
]

func _initialize() -> void:
	var trace_path := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--trace="):
			trace_path = argument.trim_prefix("--trace=")
	assert(not trace_path.is_empty(), "Pass -- --trace=/absolute/path/to/phase-one-journey.json")
	assert(FileAccess.file_exists(trace_path), "API journey trace does not exist")
	var payload = JSON.parse_string(FileAccess.get_file_as_string(trace_path))
	assert(payload is Dictionary and payload.get("status","") == "passed", "Only a passing local API trace can be replayed")
	var events: Array = payload.get("events",[])
	var cutscenes = load("res://scripts/PhaseOneCutscenes.gd")
	assert(cutscenes != null)
	var found: Array[String] = []
	for event in events:
		assert(event is Dictionary)
		var id := str(event.get("id",""))
		var player: Dictionary = event.get("player",{})
		var dive: Dictionary = event.get("dive",{})
		var shift: Dictionary = event.get("shift",{})
		assert(not player.is_empty())
		if id in ORDER:
			var sequence: Dictionary = cutscenes.sequence(id)
			assert(not sequence.is_empty() and sequence.get("lines",[]).size() >= 2, "Missing cutscene " + id)
			found.append(id)
		var expected := str(event.get("expectedEligible",""))
		if not expected.is_empty():
			assert(cutscenes.eligible_on_load(player,dive,shift) == expected, "Wrong reload cutscene for " + id)
		match id:
			"prologue":
				assert(not bool(player.progress.get("tutorial",true)))
			"first_dive":
				assert(str(dive.get("mode","")) == "dive" and int(player.progress.get("day",0)) == 1)
			"first_kedai":
				assert(not shift.is_empty() and int(player.progress.get("day",0)) == 1)
			"first_service":
				assert(player.progress.get("missions",[]).has("daun_kuning"))
			"garden_crisis":
				assert(int(player.progress.get("day",0)) == 2)
			"saras_visit":
				assert(player.progress.get("missions",[]).has("akar"))
			"cave_warning":
				var at: Dictionary = dive.get("position",{})
				assert(str(dive.get("mode","")) == "dive" and (float(at.get("y",0.0))-400.0)/28.0 >= 60.0)
			"earthquake":
				assert(str(player.progress.get("stage","")) == "boss")
			"boss_intro":
				assert(str(dive.get("mode","")) == "boss" and int(dive.get("hits",-1)) == 0)
			"boss_phase_two":
				assert(int(dive.get("hits",-1)) == 3 and int(dive.get("requiredHits",-1)) == 6)
			"victory", "epilogue":
				assert(str(player.progress.get("stage","")) == "done" and bool(player.progress.get("bossDefeated",false)))
	assert(found == ORDER, "The twelve cinematic milestones are missing or out of order: " + str(found))
	print("PHASE ONE JOURNEY CUTSCENE PASS: 12 ordered milestones, reload gates, six resonances")
	quit()
