extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	for fixture in [{"size":Vector2i(844,390),"touch":false},{"size":Vector2i(667,375),"touch":true},{"size":Vector2i(960,540),"touch":false}]:
		root.size=fixture.size
		for frame in range(3): await process_frame
		var hud=load("res://scripts/GameHud.gd").new()
		hud.touch_enabled=fixture.touch
		root.add_child(hud)
		hud.set_navigation(world,"hub",Vector2(1000,1200))
		hud.update_state({"area":"Bandar Hujung","coins":110,"weight":0,"capacity":12,"clock":"20:38","weather":"Berawan","canInteract":true,"action":"Bicara dengan Mang Ujang","diving":false})
		hud.message("Fragmen tersimpan ke tas. Datangi Mbah Wira di Kedai Waras untuk membantu warga malam ini.")
		for frame in range(3): await process_frame
		var layout:Dictionary=hud.debug_layout()
		var mini:Dictionary=layout.minimap
		var status:Dictionary=layout.status
		var shell:Control=hud.get("_minimap_shell")
		var side:float=shell.size.x*shell.scale.x*fixture.size.x/float(layout.logicalSize[0])
		print("HUD fixture ",fixture.size," logical=",layout.logicalSize," mini=",mini," status=",status)
		assert(side<=69 if fixture.size.y<=480 else side>=127,"Short landscape minimap must shrink without changing desktop size")
		if fixture.size.y<=480:
			var physical_scale:float=fixture.size.x/float(layout.logicalSize[0])
			var prompt:Rect2=hud.get("_action_plate").get_global_rect()
			assert(prompt.size.x*physical_scale<=300,"Short landscape action prompt must not span the center of the game")
			assert(mini.position[0]+mini.size[0]<prompt.position.x,"Minimap and action prompt must leave a clear play corridor")
		assert(status.position[0]>=0 and status.position[0]+status.size[0]<=layout.logicalSize[0])
		assert(status.position[1]>=0 and status.position[1]+status.size[1]+7<=mini.position[1],"Status must stay clear of minimap")
		assert(hud.get("_status_panel").size.y*fixture.size.y/float(layout.logicalSize[1])<100,"Status text must not create a central 120px panel")
		if fixture.size.y<=480:
			assert(status.size[0]*fixture.size.x/float(layout.logicalSize[0])<=321,"Short landscape notice must leave a central play corridor")
			assert(status.position[0]>=hud.get("_identity_plate").get_global_rect().end.x,"Notice must not overlap the identity panel")
		assert(hud.get("_action").get_global_rect().size.x>=48 if fixture.touch else true,"Touch target must remain at least 48px")
		print("HUD SHORT LANDSCAPE ",fixture.size," touch=",fixture.touch," minimap=",mini," status=",status)
		var output:="res://../artifacts/godot/hud-visibility"
		if DisplayServer.get_name()!="headless":
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"/%dx%d-%s-land.png"%[fixture.size.x,fixture.size.y,"touch" if fixture.touch else "keyboard"])
		hud.update_state({"area":"Bandar Hujung","coins":110,"weight":0,"capacity":12,"clock":"20:38","weather":"Berawan","canInteract":true,"action":"Bersihkan & Amati: Aliran Hulu Bandar","diving":false})
		var long_prompt:Label=hud.get("_action_label")
		var needed_height:float=long_prompt.get_theme_font("font").get_multiline_string_size(long_prompt.text,HORIZONTAL_ALIGNMENT_RIGHT,long_prompt.size.x,long_prompt.get_theme_font_size("font_size")).y+4
		assert(needed_height<=long_prompt.size.y+1,"Long interaction text must remain fully visible after compact layout")
		hud.update_state({"area":"Dangkalan Segaran","coins":110,"weight":2,"capacity":12,"clock":"08:45","weather":"Cerah","diving":true,"oxygen":208,"maxOxygen":220,"depth":32,"canNet":true})
		var dive_status:Rect2=hud.get("_status_panel").get_global_rect()
		var instrument:Rect2=hud.get("_instrument").get_global_rect()
		assert(dive_status.position.x>=instrument.end.x,"Dive notification must not cover the oxygen and depth instrument")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"/%dx%d-%s.png"%[fixture.size.x,fixture.size.y,"touch" if fixture.touch else "keyboard"])
		hud.free()
	print("HUD SHORT LANDSCAPE PASS: compact minimap, bounded status, retained touch target")
	quit()
