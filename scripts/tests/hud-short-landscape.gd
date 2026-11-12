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
		assert(side<=81 if fixture.size.y<=480 else side>=127,"Short landscape minimap must shrink without changing desktop size")
		assert(status.position[0]>=0 and status.position[0]+status.size[0]<=layout.logicalSize[0])
		assert(status.position[1]>=0 and status.position[1]+status.size[1]+7<=mini.position[1],"Status must stay clear of minimap")
		assert(hud.get("_status_panel").size.y*fixture.size.y/float(layout.logicalSize[1])<100,"Status text must not create a central 120px panel")
		assert(hud.get("_action").get_global_rect().size.x>=48 if fixture.touch else true,"Touch target must remain at least 48px")
		print("HUD SHORT LANDSCAPE ",fixture.size," touch=",fixture.touch," minimap=",mini," status=",status)
		hud.update_state({"area":"Dangkalan Segaran","coins":110,"weight":2,"capacity":12,"clock":"08:45","weather":"Cerah","diving":true,"oxygen":208,"maxOxygen":220,"depth":32,"canNet":true})
		var dive_status:Rect2=hud.get("_status_panel").get_global_rect()
		var instrument:Rect2=hud.get("_instrument").get_global_rect()
		assert(dive_status.position.x>=instrument.end.x,"Dive notification must not cover the oxygen and depth instrument")
		hud.free()
	print("HUD SHORT LANDSCAPE PASS: compact minimap, bounded status, retained touch target")
	quit()
