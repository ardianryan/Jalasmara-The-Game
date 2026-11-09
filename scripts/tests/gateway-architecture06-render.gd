extends SceneTree

var output:="res://../artifacts/godot/06f-gateways"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(1280,720)
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":200,"inventory":[],"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive={}
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=true
	clock.authoritative=true
	clock.reduced_motion=true
	clock.visual_minutes=600
	clock._process(0)
	var stage:=Node2D.new()
	root.add_child(stage)
	var player: Node2D=load("res://scripts/Player.gd").new()
	stage.add_child(player)
	player.set_physics_process(false)
	player.swim_sprite.set_appearance("male_nusantara")
	player.swim_sprite.set_outfit("explorer")
	player.swim_sprite.animate(false,false,1,0)
	player.visible=false
	var camera:=Camera2D.new()
	camera.zoom=Vector2(1.55,1.55)
	stage.add_child(camera)
	var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	var report: Dictionary={}
	for area in ["hub","forest"]:
		var gate: Dictionary=state.world.landMaps[area].gateways[0]
		var center:=Vector2(float(gate.center[0]),float(gate.center[1]))
		player.position=center
		if area=="hub": renderer.setup(stage,player,camera,area)
		else: renderer.set_area(area)
		renderer.set_process(false)
		for phase in ["before","aperture","after"]:
			var value: Array=gate.center if phase=="aperture" else gate.crossing[0 if phase=="before" else 1]
			player.position=Vector2(float(value[0]),float(value[1]))
			camera.position=player.position
			camera.force_update_scroll()
			renderer._process(.5)
			for tick in range(5): await process_frame
			await RenderingServer.frame_post_draw
			var id:=area+"-"+phase
			root.get_texture().get_image().save_png(output+"/"+id+".png")
			report[id]={"player":[player.position.x,player.position.y],"land":renderer.debug_status()}
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("GATEWAY06 NATIVE CAPTURES PASS: ",report.size()," actual left-camera approach/aperture/exit frames")
	stage.free()
	quit()
