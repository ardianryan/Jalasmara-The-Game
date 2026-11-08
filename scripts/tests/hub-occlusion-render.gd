extends SceneTree

var _capture_region := Rect2i()
var output := "res://../artifacts/godot/hub-occlusion"
func _initialize() -> void:
	call_deferred("run")
func _capture() -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func _difference(a: Image,b: Image) -> int:
	var count := 0
	for y in range(maxi(0,_capture_region.position.y),mini(a.get_height(),_capture_region.end.y)):
		for x in range(maxi(0,_capture_region.position.x),mini(a.get_width(),_capture_region.end.x)):
			var first := a.get_pixel(x,y)
			var second := b.get_pixel(x,y)
			if absf(first.r-second.r)+absf(first.g-second.g)+absf(first.b-second.b)>0.1: count += 1
	return count
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size = Vector2i(960,540)
	var environment := root.get_node_or_null("EnvironmentState")
	if environment != null: environment.set_reduced_motion(true)
	var state := root.get_node("GameState")
	state.world = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player = {"appearance":"male_default","progress":{"day":1,"stage":"dive"}}
	state.dive = {}
	var stage := Node2D.new()
	root.add_child(stage)
	var hub = load("res://scripts/HubScenery.gd").new()
	hub.configure(state.world.hub)
	stage.add_child(hub)
	var actors := Node2D.new()
	actors.y_sort_enabled = true
	stage.add_child(actors)
	var actor = load("res://scripts/Player.gd").new()
	actors.add_child(actor)
	actor.set_physics_process(false)
	actor.swim_sprite.set_appearance("male_default")
	actor.swim_sprite.animate(false,false,1,0)
	hub.add_foreground_to(actors)
	hub.get("_surface_water").set_process(false)
	hub.get("_surface_water").set_time(0.0)
	var selected: Node2D = hub.get("_trees")[0]
	var behind := Vector2(780,637)
	var front := Vector2(925.625,944.375)
	assert(selected.alpha_at_world(behind+Vector2(0,-76))>.35,"Brown-road proof must be under real fronds")
	assert(not hub.is_walkable(Vector2(870.625,704.375)),"Painted rock must not become proof ground")
	assert(not hub.is_walkable(Vector2(870.625,859.375)),"Blocked rock edge must not be presented as reachable wood proof")
	var camera := Camera2D.new()
	camera.position = selected.position+Vector2(0,-100)
	stage.add_child(camera)
	var report := {"treeBase":[selected.position.x,selected.position.y],"walkable":true,"waterTimeFrozen":0.0}
	for placement in [{"id":"behind","at":behind},{"id":"front","at":front}]:
		actor.position = placement.at
		_capture_region = Rect2i(Vector2i(actor.position-camera.position+Vector2(480,270)+Vector2(-70,-110)),Vector2i(140,140))
		assert(hub.is_walkable(actor.position),"Proof position must be reachable ground, not a trunk or obstacle")
		hub.camera_point = actor.position
		actor.visible = false
		selected.visible = true
		var no_actor := await _capture()
		actor.visible = true
		var layered := await _capture()
		layered.save_png(output+"/"+placement.id+".png")
		var visible_pixels := _difference(no_actor,layered)
		selected.visible = false
		actor.visible = false
		var reference_ground := await _capture()
		actor.visible = true
		var reference := await _capture()
		reference.save_png(output+"/"+placement.id+"-without-layer.png")
		var full_pixels := _difference(reference_ground,reference)
		assert(full_pixels>200,"Hub player reference is not visible")
		report[placement.id] = {"position":[actor.position.x,actor.position.y],"visiblePixels":visible_pixels,"referencePixels":full_pixels,"visibility":float(visible_pixels)/full_pixels,"tree":selected.debug_status()}
	assert(float(report.behind.visibility)<.95,"Hub crown did not cover actual Player")
	assert(float(report.front.visibility)>.97,"Hub Player did not draw in front")
	var file := FileAccess.open(output+"/results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("HUB OCCLUSION RENDER PASS: actual Player reachable behind=",report.behind.visibility," front=",report.front.visibility)
	stage.free()
	quit()
