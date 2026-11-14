extends SceneTree

const OUTPUT := "res://../artifacts/godot/cinematic-motion/"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var frame: Control = load("res://scripts/CutsceneFrame.gd").new()
	root.add_child(frame)
	var environment := root.get_node("EnvironmentState")
	environment.set("reduced_motion", false)
	for physical in [Vector2i(960, 540), Vector2i(667, 375)]:
		root.size = physical
		for shot in [["prologue", 1], ["prologue", 6], ["boss_intro", 1], ["boss_phase_two", 1], ["epilogue", 4], ["epilogue", 5]]:
			print("CINEMATIC CAPTURE START ", shot[0], " ", physical)
			frame.present("Living plate", {"shot":"Gerak lingkungan", "tone":"warm"}, shot[1], 6, shot[0])
			for step in range(5): await process_frame
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png(OUTPUT + "%s-%d-%dx%d-before.png" % [shot[0],shot[1],physical.x,physical.y])
			frame._process(4.0)
			for step in range(3): await process_frame
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png(OUTPUT + "%s-%d-%dx%d-after.png" % [shot[0],shot[1],physical.x,physical.y])
			assert(frame.living_plate.visible, "Animated plate missing: " + shot[0])
			print("CINEMATIC CAPTURE DONE ", shot[0], " ", physical)
	environment.set("reduced_motion", true)
	frame.present("Reduced motion", {"shot":"Gerak lingkungan", "tone":"warm"}, 1, 6, "prologue")
	assert(not frame.living_plate.visible, "Animated plate visible with reduced motion")
	environment.set("reduced_motion", false)
	frame.free()
	print("CINEMATIC MOTION RENDER PASS")
	quit()
