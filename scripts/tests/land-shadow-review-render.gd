extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var output:="res://../artifacts/godot/06b2-shadow-normals"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(1280,720)
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.authoritative=true
	clock.clock_paused=true
	clock.visual_minutes=600
	clock._process(0)
	root.get_node("RenderQuality").set_profile("balanced",false)
	var scene:=Node2D.new()
	root.add_child(scene)
	var actor:=Node2D.new()
	actor.position=Vector2(1370,835)
	scene.add_child(actor)
	var camera:=Camera2D.new()
	camera.zoom=Vector2(.75,.75)
	scene.add_child(camera)
	var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	scene.add_child(renderer)
	renderer.setup(scene,actor,camera,"hub")
	renderer.set_process(false)
	var report: Dictionary={}
	for setting in [{"id":"current","bias":.035,"normal":1.0,"enabled":true},{"id":"bias015","bias":.15,"normal":2.0,"enabled":true},{"id":"bias040","bias":.40,"normal":2.0,"enabled":true},{"id":"no-shadows","bias":.035,"normal":1.0,"enabled":false}]:
		renderer._process(.5)
		renderer.sunlight.shadow_bias=setting.bias
		renderer.sunlight.shadow_normal_bias=setting.normal
		renderer.sunlight.shadow_enabled=setting.enabled
		for frame in range(6): await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(output+"/"+str(setting.id)+".png")
		report[setting.id]=setting
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("LAND SHADOW REVIEW CAPTURES PASS:4 identical camera/time/profile diagnostic variants; visual review required")
	scene.free()
	quit()
