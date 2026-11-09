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
	root.size=Vector2i(1440,810)
	var state=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_default","coins":700,"progress":{"day":2,"stage":"dive"}}
	state.adventure={"discoveries":[],"puzzles":[]}
	state.dive={"id":"ocean-proof","oxygen":77,"loot":[],"targets":[]}
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
	for warmup in range(30):
		await process_frame
	assert(is_instance_valid(ocean.headlamp),"Hybrid world must build before controlled captures")
	var variant:=OS.get_environment("OCEAN_06_VARIANT")
	if variant.is_empty(): variant="baseline"
	var directory:="res://../artifacts/godot/06a-ocean/"+variant
	DirAccess.make_dir_recursive_absolute(directory)
	var report:Dictionary={"variant":variant,"viewport":[1440,810],"minutes":600,"weather":clock.snapshot(),"appearance":"male_default","outfit":"diving","quality":"balanced","cases":{}}
	var cases:Array[Dictionary]=[
		{"id":"passage-right-on","at":Vector2(750,900),"camera":Vector2(750,900),"facing":1,"lamp":true},
		{"id":"passage-left-on","at":Vector2(750,900),"camera":Vector2(750,900),"facing":-1,"lamp":true},
		{"id":"passage-right-off","at":Vector2(750,900),"camera":Vector2(750,900),"facing":1,"lamp":false},
		{"id":"passage-camera-west","at":Vector2(750,900),"camera":Vector2(660,900),"facing":1,"lamp":true},
		{"id":"passage-camera-east","at":Vector2(750,900),"camera":Vector2(840,900),"facing":1,"lamp":true},
		{"id":"reef","at":Vector2(1550,620),"camera":Vector2(1550,620),"facing":1,"lamp":true},
	]
	for shot in cases:
		source.nala.position=shot.at
		source.nala.direction=int(shot.facing)
		source.nala.velocity=Vector2.ZERO
		source.camera.position=shot.camera
		source.camera.force_update_scroll()
		for tick in range(20):
			source.nala.swim_sprite.animate(false,true,int(shot.facing),0)
			await process_frame
			ocean.headlamp.visible=bool(shot.lamp)
			await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory+"/"+str(shot.id)+".png")
		report.cases[shot.id]={"player":[shot.at.x,shot.at.y],"camera":[shot.camera.x,shot.camera.y],"facing":shot.facing,"lamp":shot.lamp,"hybrid":ocean.debug_status()}
	assert(state.dive.oxygen==77 and state.player.coins==700)
	FileAccess.open(directory+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("OCEAN06 NATIVE PASS: six controlled full-scene captures, lamp on/off, both facings, camera seam checks, reef control; no gameplay resource mutation")
	source.queue_free()
	await process_frame
	quit()
