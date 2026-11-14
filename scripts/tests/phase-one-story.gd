extends SceneTree

func _initialize() -> void:
	var story = load("res://scripts/PhaseOneStory.gd")
	assert(story != null)
	var state := {"player":{"progress":{"day":1,"stage":"dive","missions":[],"bossDefeated":false},"abilities":{"oxygen":1,"net":1}},"adventure":{"discoveries":[],"puzzles":[]},"homestead":{},"dive":{}}
	assert(story.goal(state).contains("Segaran"))
	assert(story.chapters(state).size() == 5)
	assert(load("res://scripts/FieldBook.gd").entries_for(state,"Misi").size() >= 5)
	assert(story.chapters(state)[0].unlocked and not story.chapters(state)[1].unlocked)
	state.player.progress.day = 2
	assert(story.goal(state).contains("kebun 0/3"))
	state.adventure.discoveries = ["garden_leaf","garden_root","garden_channel","forest_canopy","forest_roots","forest_stream","nitrogen","photosynthesis","osmosis"]
	assert(story.goal(state).contains("3/3"))
	assert(story.chapters(state)[1].unlocked and not story.chapters(state)[2].unlocked)
	state.player.progress.day = 3
	assert(story.goal(state).contains("pipa korporasi"))
	state.adventure.discoveries.append("corporate_pipe")
	assert(story.goal(state).contains("penyaring Jalatunda"))
	state.adventure.puzzles.append("filter")
	assert(story.goal(state).contains("tiga racikan terakhir"))
	state.player.progress.stage = "night"
	assert(story.goal(state).contains("Kedai Waras"))
	state.homestead.pendingStoryAdvance = {"storyDay":3}
	assert(story.goal(state).contains("tidur di dipan"))
	state.homestead.erase("pendingStoryAdvance")
	state.player.progress.stage = "boss"
	assert(story.goal(state).contains("level 3"))
	state.player.abilities = {"oxygen":3,"net":3}
	assert(story.goal(state).contains("enam resonansi"))
	assert(story.chapters(state)[3].unlocked and not story.chapters(state)[4].unlocked)
	state.player.progress.stage = "done"
	state.player.progress.bossDefeated = true
	assert(story.chapters(state)[4].unlocked)
	assert(story.goal(state).contains("Fase 1 selesai"))
	print("PHASE ONE STORY PASS: goals, chapter locks, day transitions and finale")
	quit()
