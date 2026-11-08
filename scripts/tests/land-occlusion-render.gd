extends SceneTree

const BASE := Vector2(454,610)
const OUTLINE := [Vector2(338,449),Vector2(395,407),Vector2(467,430),Vector2(528,480),Vector2(553,558),Vector2(483,549),Vector2(475,609),Vector2(434,620),Vector2(411,537),Vector2(335,530)]
var output := "res://../artifacts/godot/land-occlusion"

func _initialize() -> void:
	call_deferred("run")

func _capture() -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func _difference(a: Image,b: Image) -> int:
	var count := 0
	for y in range(a.get_height()):
		for x in range(a.get_width()):
			var first := a.get_pixel(x,y)
			var second := b.get_pixel(x,y)
			if absf(first.r-second.r)+absf(first.g-second.g)+absf(first.b-second.b)>0.1:
				count += 1
	return count

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size = Vector2i(960,540)
	var environment := root.get_node_or_null("EnvironmentState")
	if environment != null: environment.set_reduced_motion(true)
	var stage := Node2D.new()
	root.add_child(stage)
	var texture := load("res://resources/art/forest-muara.png") as Texture2D
	var ground := Sprite2D.new()
	ground.texture = texture
	ground.centered = false
	ground.scale = Vector2(1.5625,1.5625)
	stage.add_child(ground)
	var actors := Node2D.new()
	actors.y_sort_enabled = true
	stage.add_child(actors)
	var tree = load("res://scripts/ForestOcclusion.gd").new()
	tree.configure(texture,BASE,OUTLINE,22.0,1.5625,[Vector2(438,535),Vector2(474,530),Vector2(477,610),Vector2(434,620)])
	actors.add_child(tree)
	var actor := Node2D.new()
	actors.add_child(actor)
	var visual = load("res://scripts/CharacterVisual.gd").new()
	actor.add_child(visual)
	visual.set_appearance("male_default")
	tree.set_focus(actor)
	var camera := Camera2D.new()
	camera.position = Vector2(740,850)
	stage.add_child(camera)
	var report := {}
	for placement in [{"id":"behind","at":Vector2(740,880)},{"id":"front","at":Vector2(740,1000)}]:
		actor.position = placement.at
		actor.visible = false
		tree.visible = true
		var no_actor := await _capture()
		actor.visible = true
		var layered := await _capture()
		layered.save_png(output+"/"+placement.id+".png")
		var visible_pixels := _difference(no_actor,layered)
		tree.visible = false
		actor.visible = false
		var reference_ground := await _capture()
		actor.visible = true
		var reference := await _capture()
		reference.save_png(output+"/"+placement.id+"-without-layer.png")
		var full_pixels := _difference(reference_ground,reference)
		assert(full_pixels>200,"Character reference is not visibly rendered")
		report[placement.id] = {"visiblePixels":visible_pixels,"referencePixels":full_pixels,"visibility":float(visible_pixels)/full_pixels,"tree":tree.debug_status()}
	assert(float(report.behind.visibility)<0.90,"Canopy did not visibly cover Nala behind its trunk")
	assert(float(report.front.visibility)>0.97,"Nala must be fully drawn in front of the trunk")
	assert(float(report.front.visibility)>float(report.behind.visibility)+0.05,"Front/back renders did not show actual depth ordering")
	var file := FileAccess.open(output+"/results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("LAND OCCLUSION RENDER PASS: actual Nala visibility behind=",report.behind.visibility," front=",report.front.visibility)
	stage.free()
	quit()
