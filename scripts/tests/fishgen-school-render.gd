extends SceneTree
class Swimmer extends Node2D:
	var velocity:=Vector2(90,0)
	var direction:=1
	var swim_sprite: Sprite2D
	func _ready() -> void:
		swim_sprite=load("res://scripts/CharacterVisual.gd").new()
		add_child(swim_sprite)
		swim_sprite.set_appearance("male_default")
		swim_sprite.set_outfit("diving")
		swim_sprite.animate(true,true,1,0)
class Source extends Node2D:
	var camera: Camera2D
	var nala: Swimmer
	var entities: Node2D
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(960,540)
	var state=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_default","coins":700,"progress":{"day":2,"stage":"dive"}}
	state.adventure={"discoveries":[],"puzzles":[]}
	state.dive={"id":"fishgen-native","oxygen":77,"loot":[],"targets":[]}
	var clock=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.update_story(2,"dive")
	clock.visual_minutes=600
	clock.elapsed_seconds=0
	clock.reduced_motion=false
	clock.clock_paused=false
	root.get_node("RenderQuality").set_profile("balanced",false)
	var source:=Source.new()
	root.add_child(source)
	source.nala=Swimmer.new()
	source.add_child(source.nala)
	source.nala.visible=false
	source.camera=Camera2D.new()
	source.camera.zoom=Vector2.ONE
	source.add_child(source.camera)
	source.entities=load("res://scripts/Entities.gd").new()
	source.entities.player=source.nala
	source.add_child(source.entities)
	source.entities.visible=false
	var ocean=load("res://scripts/hybrid/HybridOcean.gd").new()
	source.add_child(ocean)
	ocean.setup(source)
	var spawn: Dictionary = state.world.get("spawn", {"x":1120,"y":470})
	var center := Vector2(float(spawn.x),float(spawn.y)) + Vector2(220,160)
	source.nala.position=center+Vector2(-70,45)
	source.camera.position=center
	source.camera.force_update_scroll()
	for warmup in range(12):
		await process_frame
	assert(is_instance_valid(ocean.actors))
	var school = ocean.actors.get("_fishgen")
	assert(is_instance_valid(school) and school._fish.size()==3)
	school.set_process(false)
	var directory := "res://../artifacts/godot/fishgen-school"
	DirAccess.make_dir_recursive_absolute(directory)
	var result: Dictionary={"frames":[],"source":"production HybridOcean+FishGenSchool3D","size":[960,540]}
	for i in range(40):
		for fish in school._fish: fish.requested=-1 if i<20 else 1
		school._process(.1)
		await process_frame
		RenderingServer.force_draw(false)
		var file := "%03d.png" % i
		root.get_texture().get_image().save_png(directory+"/"+file)
		var poses := []
		for fish in school._fish:
			var pose: Dictionary=fish.animator.advance(0,int(fish.requested))
			poses.append({"clip":pose.clip,"index":pose.index,"yaw":pose.yaw,"position":[fish.position.x,fish.position.y]})
		result.frames.append({"file":file,"visible":school.visible_count,"poses":poses})
		assert(school.visible_count==3)
	assert(state.dive.oxygen==77 and state.player.coins==700)
	FileAccess.open(directory+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("PASS FishGen native:40 actual full-ocean frames,3 decorative actors,unchanged oxygen/coins")
	source.queue_free()
	await process_frame
	quit()
