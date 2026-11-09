extends SceneTree

var output:="res://../artifacts/godot/06b-shelter"
var report: Dictionary={}

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(1440,810)
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":200,"inventory":[],"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive={}
	state.surface={"area":"hub","x":160,"y":615}
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=true
	clock.authoritative=true
	clock.reduced_motion=true
	var stage:=Node2D.new()
	root.add_child(stage)
	var player: Node2D=load("res://scripts/Player.gd").new()
	stage.add_child(player)
	player.set_physics_process(false)
	player.swim_sprite.set_appearance("male_nusantara")
	player.swim_sprite.set_outfit("daily")
	player.swim_sprite.animate(false,false,1,0)
	player.visible=false
	var camera:=Camera2D.new()
	camera.zoom=Vector2(1.15,1.15)
	stage.add_child(camera)
	var profiles: Array=state.world.surface_hub.residents.duplicate(true)
	var gardener: Dictionary=state.world.surface_hub.districtActivities["Bu Darmi"].duplicate(true)
	gardener.name="Bu Darmi"
	profiles.append(gardener)
	for profile in profiles:
		var npc: Node2D=load("res://scripts/HubActor.gd").new()
		npc.actor_name=str(profile.name)
		if profile.has("appearance"):
			npc.appearance_index=int(profile.appearance)
			npc.custom_sheet=load("res://resources/art/village-residents-v1.png")
			npc.custom_grid=Vector2i(3,2)
		npc.position=Vector2(profile.activity.shelter[0],profile.activity.shelter[1])
		npc.set_meta("land_hidden",true)
		stage.add_child(npc)
		npc.configure_activity(profile)
		npc.set_process(false)
	var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	renderer.setup(stage,player,camera,"hub")
	for quality in ["low","balanced"]:
		root.get_node("RenderQuality").set_profile(quality,false)
		for condition in [{"id":"day","minute":600,"rain":false},{"id":"night","minute":1200,"rain":false},{"id":"rain","minute":600,"rain":true}]:
			clock.visual_minutes=condition.minute
			clock.set("_server_rain",condition.rain)
			clock.set("_rain_amount",.55 if condition.rain else 0)
			clock._process(0)
			for placement in [{"id":"sasmita-front","at":Vector2(160,615)},{"id":"sasmita-side","at":Vector2(265,700)},{"id":"ratih","at":Vector2(510,325)},{"id":"balai","at":Vector2(980,345)},{"id":"sari","at":Vector2(1265,320)},{"id":"tedi","at":Vector2(960,990)},{"id":"booth","at":Vector2(1430,1315)}]:
				player.position=placement.at
				camera.position=placement.at+Vector2(0,-35)
				camera.force_update_scroll()
				renderer._process(.5)
				for tick in range(6): await process_frame
				await RenderingServer.frame_post_draw
				var id:="%s-%s-%s"%[quality,condition.id,placement.id]
				root.get_texture().get_image().save_png(output+"/"+id+".png")
				report[id]=renderer.debug_status()
				report[id]["player"]=[player.position.x,player.position.y]
				report[id]["weather"]=condition
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("SHELTER06 NATIVE CAPTURES: ",report.size())
	quit()
