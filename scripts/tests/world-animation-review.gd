extends SceneTree

class Swimmer extends Node2D:
	var velocity := Vector2(90,0)
	var direction := 1
	var swim_sprite: Sprite2D
	func _ready() -> void:
		swim_sprite=load("res://scripts/CharacterVisual.gd").new()
		add_child(swim_sprite)
		swim_sprite.set_appearance("male_nusantara")
		swim_sprite.set_outfit("diving")
		swim_sprite.animate(false,true,1,0)

class OceanSource extends Node2D:
	var camera: Camera2D
	var nala: Swimmer
	var entities: Node2D

var output := "res://../artifacts/godot/overnight-world-motion"
var report: Dictionary = {"kind":"native-component-animation-review","limits":["Controlled component placements, not a real-input traversal or server transaction.","Frame sequence is visual evidence, not an FPS benchmark or a Windows/S23 result."]}

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> String:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(output+"/"+label+".png")
	return image.get_data().hex_encode().sha256_text()

func forest_review(state: Node,clock: Node) -> void:
	state.dive={}
	var stage := Node2D.new()
	root.add_child(stage)
	var player: Node2D = load("res://scripts/Player.gd").new()
	stage.add_child(player)
	player.set_physics_process(false)
	player.swim_sprite.set_appearance("male_nusantara")
	player.swim_sprite.set_outfit("explorer")
	player.swim_sprite.animate(false,false,1,0)
	player.visible=false
	var camera := Camera2D.new()
	stage.add_child(camera)
	var land: Node2D = load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(land)
	land.setup(stage,player,camera,"forest")
	land.set_process(false)
	land.water_node.set_process(false)
	var collision: Node2D = load("res://scripts/land/LandCollision.gd").new()
	collision.configure(land.map)
	var helper = land.get("_canopy_readability")
	var target := Vector2.ZERO
	var found := false
	for path in land.map.routes:
		for segment in range(1,path.size()):
			var start := Vector2(path[segment-1][0],path[segment-1][1])
			var finish := Vector2(path[segment][0],path[segment][1])
			for step in range(ceili(start.distance_to(finish)/20.0)+1):
				var at := start.move_toward(finish,step*20.0)
				if not collision.is_walkable(at): continue
				helper.update(land.ground_point(at),land.camera_up(),land.camera_forward(),.5,land.camera_right())
				if helper.debug_status().revealed>0:
					target=at
					found=true
					break
			if found: break
		if found: break
	assert(found,"Derive a real walkable alpha-covered canopy from current camera and authored routes")
	player.position=target
	camera.position=target
	camera.force_update_scroll()
	land._process(.5)
	var canopy: Dictionary = helper.debug_status().duplicate(true)
	assert(canopy.revealed>0 and canopy.revealed<canopy.crowns/4)
	await capture("forest-canopy-revealed")
	var bridge: Dictionary = land.map.bridges[0]
	var start := Vector2(bridge.path[0][0],bridge.path[0][1])
	var finish := Vector2(bridge.path[-1][0],bridge.path[-1][1])
	player.position=start.lerp(finish,.5)
	assert(collision.is_walkable(player.position),"River sequence must stand on the current authored bridge")
	camera.position=player.position
	camera.force_update_scroll()
	clock.clock_paused=true
	land._process(.5)
	var water_start: float = land.water_node.elapsed
	var hashes: Array[String] = []
	for frame in range(6):
		land._process(.2)
		land.water_node._process(.2)
		hashes.append(await capture("forest-reading-river-%02d"%frame))
		await create_timer(.2).timeout
	assert(land.water_node.elapsed>water_start+1.1,"Water shader clock must continue during reading")
	assert(hashes[0]!=hashes[-1],"Actual rendered forest frames must change over the time sequence")
	helper.update(land.ground_point(target)+land.camera_right()*15000,land.camera_up(),land.camera_forward(),.6,land.camera_right())
	assert(helper.debug_status().revealed==0,"Every local canopy must restore outside the occlusion footprint")
	report.forest={"canopyTarget":[target.x,target.y],"canopy":canopy,"bridge":bridge.id,"waterClockDelta":land.water_node.elapsed-water_start,"water":land.water_node.debug_status(),"renderedFrameHashes":hashes,"readingPause":true,"restoreRevealed":helper.debug_status().revealed}
	collision.free()
	stage.free()
	await process_frame

func ocean_review(state: Node,clock: Node) -> void:
	clock.clock_paused=false
	state.dive={"id":"component-ocean-review","oxygen":77,"loot":[],"targets":[]}
	var stage := OceanSource.new()
	root.add_child(stage)
	stage.nala=Swimmer.new()
	stage.nala.position=Vector2(1550,620)
	stage.add_child(stage.nala)
	stage.camera=Camera2D.new()
	stage.camera.position=stage.nala.position
	stage.add_child(stage.camera)
	stage.camera.force_update_scroll()
	stage.entities=load("res://scripts/Entities.gd").new()
	stage.entities.player=stage.nala
	stage.add_child(stage.entities)
	stage.entities.visible=false
	var ocean: Node2D = load("res://scripts/hybrid/HybridOcean.gd").new()
	stage.add_child(ocean)
	ocean.setup(stage)
	ocean.set_process(false)
	ocean.living_water.set_process(false)
	for tick in range(8):
		ocean._process(.2)
		ocean.living_water._process(.2)
	var initial: Dictionary = {}
	for mote in ocean.living_water.get("_motes"): initial[str(mote.key)]=mote.at
	var hashes: Array[String] = []
	for frame in range(6):
		ocean._process(.2)
		ocean.living_water._process(.2)
		hashes.append(await capture("ocean-active-%02d"%frame))
		await create_timer(.2).timeout
	var tracked := 0
	var moved := 0
	for mote in ocean.living_water.get("_motes"):
		if initial.has(str(mote.key)):
			tracked+=1
			if Vector2(mote.at).distance_to(initial[str(mote.key)])>.1: moved+=1
	assert(tracked>0 and moved==tracked,"Retained actual current particles must advect")
	var active_status: Dictionary = ocean.debug_status()
	assert(active_status.water.causticPatches>0 and active_status.water.shafts>0)
	assert(hashes[0]!=hashes[-1])
	var layers_before: Array = active_status.backdrop.layers
	stage.camera.position+=Vector2(120,0)
	stage.camera.force_update_scroll()
	ocean._process(.2)
	var layers_after: Array = ocean.debug_status().backdrop.layers
	assert(layers_before[0].offset!=layers_after[0].offset)
	assert(layers_after[0].offset!=layers_after[-1].offset,"Far and near actual layers must have different parallax")
	clock.clock_paused=true
	var elapsed: float = ocean.living_water.elapsed
	var paused_hashes: Array[String] = []
	for frame in range(4):
		ocean._process(.2)
		ocean.living_water._process(.2)
		paused_hashes.append(await capture("ocean-reading-%02d"%frame))
		await create_timer(.2).timeout
	assert(ocean.living_water.elapsed==elapsed,"Reading freezes cosmetic mote advection")
	assert(paused_hashes[0]!=paused_hashes[-1],"Actual ocean shader idle motion must remain alive during reading")
	report.ocean={"active":active_status,"trackedMotes":tracked,"movedMotes":moved,"renderedFrameHashes":hashes,"readingFrameHashes":paused_hashes,"readingAdvectionFrozen":true,"parallaxBefore":layers_before,"parallaxAfter":layers_after}
	stage.free()
	await process_frame

func run() -> void:
	assert(DisplayServer.get_name()!="headless","This fixture requires actual native rendering")
	root.size=Vector2i(960,540)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var state := root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":700,"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.adventure={"discoveries":[],"puzzles":[]}
	var unchanged := JSON.stringify(state.player)
	var clock := root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.update_story(2,"dive")
	clock.visual_minutes=600
	clock.elapsed_seconds=0
	clock.reduced_motion=false
	root.get_node("RenderQuality").set_profile("balanced",false)
	await forest_review(state,clock)
	await ocean_review(state,clock)
	assert(JSON.stringify(state.player)==unchanged and state.dive.oxygen==77)
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("WORLD ANIMATION REVIEW PASS: current accessible canopy, river reading clock, active reef current/caustics, distinct parallax, paused advection with live shader frames; no server/account transaction")
	quit()
