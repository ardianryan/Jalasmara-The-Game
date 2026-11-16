extends SceneTree

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var lookup=load("res://scripts/VillagePortraits.gd")
	var presenter=load("res://scripts/DialoguePresenter.gd").new()
	var seen:Dictionary={}
	var checked:=0
	for resident in state.world.surface_hub.residents:
		if str(resident.get("visual",{}).get("kind","")) not in ["child","director"]: continue
		var frame:AtlasTexture=lookup.for_resident(str(resident.id))
		assert(frame!=null and frame.filter_clip)
		assert(frame==lookup.for_resident(str(resident.id)),"Repeated dialogue reuses the bounded atlas frame")
		assert(not seen.has(frame.region),"Each person has a distinct original cell")
		seen[frame.region]=true
		var bust:AtlasTexture=presenter._portrait(str(resident.name))
		assert(bust!=null and bust.atlas==frame,"Actual dialogue resolves the canonical portrait before the old six-cell atlas")
		assert(bust.filter_clip and bust.region==Rect2(0,0,96,85),"Dialogue uses a bounded face and torso crop")
		var image:Image=frame.get_image()
		if image.is_compressed(): image.decompress()
		assert(image.get_size()==Vector2i(96,128))
		var opaque:=0
		for y in image.get_height():
			for x in image.get_width():
				var alpha:=image.get_pixel(x,y).a
				assert(alpha==0 or alpha==1,"Original source halos must not become visible portrait rectangles")
				if alpha==1: opaque+=1
		assert(opaque>1000 and opaque<7000)
		checked+=1
	assert(checked==6)
	assert(lookup.for_resident("unknown")==null)
	assert(presenter._portrait("Unknown visitor")==null)
	presenter.free()
	print("VILLAGE PORTRAITS PASS:6 unique original identities, actual dialogue lookup, bounded cached atlas and binary alpha; source one view only, no gait claim")
	quit()
