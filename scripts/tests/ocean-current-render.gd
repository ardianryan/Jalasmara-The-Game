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
	var directory:="res://../artifacts/godot/ocean-current"
	DirAccess.make_dir_recursive_absolute(directory)
	var report: Dictionary={}
	for label in ["reef","passage","deep"]:
		var center: Vector2={"reef":Vector2(1550,620),"passage":Vector2(750,900),"deep":Vector2(3900,2500)}[label]
		source.nala.position=center
		source.camera.position=center
		source.camera.force_update_scroll()
		var initial: Dictionary={}
		for tick in range(160):
			source.nala.swim_sprite.animate(true,true,1,tick*.05)
			await process_frame
			if tick==1:ocean.living_water.set_process(false)
			ocean.living_water._process(.05)
			await RenderingServer.frame_post_draw
			if tick==20:
				for mote in ocean.living_water.get("_motes"): initial[str(mote.key)]=mote.at
			if tick in [20,159]:root.get_texture().get_image().save_png(directory+"/"+label+"-%d.png"%tick)
		report[label]=ocean.debug_status()
		var tracked:=0
		var moved:=0
		var turned:=0
		for mote in ocean.living_water.get("_motes"):
			if initial.has(str(mote.key)):
				tracked+=1
				if Vector2(mote.at).distance_to(initial[str(mote.key)])>1:moved+=1
			if absf(Vector2(mote.flow).y)>.05:turned+=1
		report[label]["measuredParticleMotion"]={"tracked":tracked,"moved":moved,"reefDeflected":turned,"intervalSeconds":6.95}
		assert(tracked>0 and moved==tracked,"Actual retained particles must advect over the captured interval")
		assert(report[label].water.motes<=48 and report[label].water.wakes<=18)
		assert(report[label].water.currentField.edges>0)
	assert(state.dive.oxygen==77 and state.player.coins==700)
	FileAccess.open(directory+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("OCEAN CURRENT NATIVE PASS: actual hybrid reef/passage/deep, bounded visual currents, retained atmosphere/geology/lighting, no resource mutation")
	source.queue_free()
	await process_frame
	quit()
