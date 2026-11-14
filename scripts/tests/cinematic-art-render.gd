extends SceneTree

const OUTPUT := "res://../artifacts/godot/cinematic-art/"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var frame: Control = load("res://scripts/CutsceneFrame.gd").new()
	root.add_child(frame)
	for physical in [Vector2i(960, 540), Vector2i(844, 390), Vector2i(667, 375)]:
		root.size = physical
		for scene in [
			["prologue", 1, "Prolog — Bandar Hujung"],
			["boss_intro", 1, "Gajah Mina — Tamansari"],
			["epilogue", 5, "Epilog — Griya Sasmita"]
		]:
			frame.present(scene[2], {"shot": "Cahaya ingatan kembali ke Bandar Hujung.", "tone": "warm"}, scene[1], 6, scene[0])
			for i in range(5): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUTPUT + scene[0] + "-%dx%d.png" % [physical.x, physical.y])
	frame.free()
	print("CINEMATIC ART RENDER PASS")
	quit()
