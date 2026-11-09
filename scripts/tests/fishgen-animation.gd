extends SceneTree

const Animator = preload("res://scripts/FishGenAnimator.gd")

class MainSource extends Node:
	var entities: Node
	var nala: Node2D

class Entities extends Node:
	var wildlife: Node2D

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var data := Animator.sheet()
	assert(not data.is_empty())
	var image: Image = data.texture.get_image()
	assert(image.get_format() == Image.FORMAT_RGBA8)
	var animation := Animator.new()
	var clips: Dictionary = {}
	var frames: Dictionary = {}
	var yaw_samples := 0
	for step in range(960):
		var facing := -1 if step < 480 else 1
		var pose: Dictionary = animation.advance(1.0 / 120.0, facing)
		clips[pose.clip] = true
		frames[str(pose.clip) + ":" + str(pose.index)] = true
		assert(pose.source.position.x >= 0 and pose.source.end.x <= image.get_width())
		assert(pose.source.position.y >= 0 and pose.source.end.y <= image.get_height())
		if str(pose.clip).begins_with("turn"):
			yaw_samples += 1
			assert(absf(float(pose.yaw)) <= PI + 0.001)
	assert(clips.size() == 4 and frames.size() == 32 and yaw_samples > 0)
	var paused: Dictionary = animation.advance(0, 1)
	for _step in range(20):
		var next: Dictionary = animation.advance(0.1, 1, true)
		assert(next.clip == paused.clip and next.index == paused.index)
	var state = root.get_node("GameState")
	state.world = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.dive = {"id": "fishgen-test", "mode": "normal", "targets": []}
	var source := MainSource.new()
	source.entities = Entities.new()
	source.entities.wildlife = load("res://scripts/Wildlife.gd").new()
	source.nala = Node2D.new()
	var spawn: Dictionary = state.world.get("spawn", {"x": 1120, "y": 470})
	source.nala.position = Vector2(float(spawn.x), float(spawn.y)) + Vector2(180, 140)
	source.add_child(source.entities)
	source.entities.add_child(source.entities.wildlife)
	source.add_child(source.nala)
	root.add_child(source)
	source.entities.wildlife.set_process(false)
	var school = load("res://scripts/hybrid/FishGenSchool3D.gd").new()
	school.configure(source)
	source.add_child(school)
	school.set_process(false)
	var contacts := 0
	for step in range(1800):
		school._process(1.0 / 60.0)
		assert(school._fish.size() == 3)
		for fish in school._fish:
			assert(not source.entities.wildlife._blocked(fish.position, 12.0))
			contacts += 1
	var quality = root.get_node("RenderQuality")
	var previous: String = quality.get_profile().requested
	quality.set_profile("low", false)
	school._process(0.016)
	assert(school.visible_count <= 1)
	quality.set_profile("balanced", false)
	school._process(0.016)
	assert(school.visible_count <= 3)
	state.dive = {"id": "boss-test", "mode": "boss"}
	school._process(0.016)
	assert(school._fish.is_empty())
	state.dive = {}
	school._process(0.016)
	assert(not school.visible)
	quality.set_profile(previous, false)
	source.free()
	await process_frame
	print("PASS FishGen: 32 frames/four clips, timed turn next/yaw, pause, %d water contacts, quality caps and boss/session cleanup" % contacts)
	quit()
