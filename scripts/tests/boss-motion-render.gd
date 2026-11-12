extends SceneTree
class Swimmer extends Node2D:
	var velocity:=Vector2.ZERO
	var direction:=1
	var swim_sprite: Sprite2D
	func _ready() -> void:
		swim_sprite=load("res://scripts/CharacterVisual.gd").new()
		add_child(swim_sprite)
		swim_sprite.set_appearance("male_default")
		swim_sprite.set_outfit("diving")
		swim_sprite.animate(false,true,1,0)
class Source extends Node2D:
	var camera: Camera2D
	var nala: Swimmer
	var entities: Node2D
	var boss_motion=load("res://scripts/BossMotion.gd").new()
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(DisplayServer.get_name()!="headless")
	root.size=Vector2i(960,540)
	var state=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_default","coins":700,"progress":{"day":3,"stage":"boss","bossDefeated":false}}
	state.adventure={"discoveries":[],"puzzles":[]}
	state.dive={"id":"boss-native","mode":"boss","hits":0,"requiredHits":6,"oxygen":77,"loot":[],"targets":[]}
	var clock=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.update_story(3,"boss")
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
	var anchor:=Vector2(3820,3140)
	source.nala.position=anchor+Vector2(-350,0)
	source.camera.position=anchor+Vector2(-90,0)
	source.camera.force_update_scroll()
	var directory:="res://../artifacts/godot/boss-motion"
	DirAccess.make_dir_recursive_absolute(directory)
	var positions: Array=[]
	for i in range(70):
		if i==35: state.dive.hits=3
		source.boss_motion.advance(.1,"boss-native",int(state.dive.hits),6,false,true,false)
		await process_frame
		if i in [5,20,34,40,55,69]:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(directory+"/frame-%02d.png"%i)
			positions.append([i,source.boss_motion.position.x,source.boss_motion.position.y,int(state.dive.hits),source.boss_motion.telegraph])
	assert(is_instance_valid(ocean.actors))
	assert(int(ocean.actors.debug_counts.boss)==1)
	assert(Vector2(positions[0][1],positions[0][2]).distance_to(Vector2(positions[-1][1],positions[-1][2]))>70)
	FileAccess.open(directory+"/results.json",FileAccess.WRITE).store_string(JSON.stringify({"source":"production HybridOcean/OceanActors", "positions":positions,"bossTexture":ocean.actors.sprites["boss"].texture.resource_path},"  "))
	print("BOSS MOTION NATIVE PASS: six rendered phase1/phase2 frames, real hybrid actor, moving location")
	source.queue_free()
	await process_frame
	quit()
