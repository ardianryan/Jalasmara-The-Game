extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state:=root.get_node("GameState")
	var before:=JSON.stringify({"player":state.player,"dive":state.dive})
	var visual:=preload("res://scripts/CharacterVisual.gd").new()
	root.add_child(visual)
	for identity in ["male_default","male_nusantara","female_default","female_nusantara"]:
		visual.set_appearance(identity)
		assert(visual.modular_ready,"Equipment-free base atlas is required")
		assert(visual.clothing_ready,"Three distinct standing clothing rows are required")
		assert(visual.hframes==3 and visual.vframes==3)
		for outfit in ["daily","explorer","diving"]:
			visual.set_outfit(outfit)
			visual.set_equipment({})
			visual.animate(true,false,-1,1.0)
			var first: int=int({"daily":0,"explorer":1,"diving":2}[outfit])*3
			assert(visual.frame in [first+1,first+2] and visual.flip_h)
			assert(visual.texture.resource_path.ends_with("-outfits-v1.png"))
			var gear: Dictionary=visual.get_equipment_state()
			assert(gear.modular and gear.outfit==outfit)
			assert(bool(gear.tank)==(outfit=="diving"))
			assert(bool(gear.net)==(outfit=="diving"))
			assert(not bool(gear.vest),"Explorer clothing is in the outfit atlas; no duplicate modelvest")
			assert(bool(gear.satchel)==(outfit=="explorer"))
		visual.animate(true,true,1,2.0)
		assert(visual.frame>=3 and visual.frame<=8 and not visual.flip_h)
		assert(visual.texture.resource_path.ends_with("-base-v1.png"))
		assert(visual.get_equipment_state().bodySize==112.0)
	visual.set_equipment({"tank":false,"net":false})
	assert(not visual.get_equipment_state().tank and not visual.get_equipment_state().net)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(480,270)
	root.add_child(viewport)
	var camera:=Camera3D.new()
	viewport.add_child(camera)
	camera.current=true
	var sprite:=Sprite3D.new()
	sprite.texture=visual.texture
	viewport.add_child(sprite)
	var equipment:=preload("res://scripts/CharacterEquipment3D.gd").new()
	viewport.add_child(equipment)
	for outfit in ["daily","explorer","diving"]:
		var gear: Dictionary=visual.equipment_state(outfit,{},true)
		equipment.update_attachment(sprite,gear,outfit=="diving",false)
		var report: Dictionary=equipment.debug_status()
		assert(report.modular and report.meshes>20 and report.meshes<40)
		assert(bool(report.tank)==(outfit=="diving"))
		assert(bool(report.vest)==(outfit=="explorer"))
	equipment.update_attachment(sprite,{"modular":false,"tank":true},true,false)
	assert(not equipment.visible,"Baked legacy atlas must not get duplicate equipment")
	var scene:=Node2D.new()
	root.add_child(scene)
	var npc: Node2D=load("res://scripts/HubActor.gd").new()
	npc.actor_name="RetiredResident"
	scene.add_child(npc)
	var mirrors: Node3D=load("res://scripts/land/LandActors3D.gd").new()
	root.add_child(mirrors)
	mirrors.source=scene
	var stale:=Sprite3D.new()
	mirrors.add_child(stale)
	mirrors.sprites["NPC_RetiredResident"]=stale
	var stale_shadow:=MeshInstance3D.new()
	mirrors.add_child(stale_shadow)
	mirrors.get("_shadows")["NPC_RetiredResident"]=stale_shadow
	npc.queue_free()
	mirrors.call("_scan")
	assert(not mirrors.sprites.has("NPC_RetiredResident") and stale.is_queued_for_deletion())
	assert(not mirrors.get("_shadows").has("NPC_RetiredResident") and stale_shadow.is_queued_for_deletion())
	assert(before==JSON.stringify({"player":state.player,"dive":state.dive}),"Appearance cannot mutate gameplay data")
	print("CHARACTER OUTFITS PASS: four equipment-free identities, three outfit states, 9 animation cells, independent bounded3D gear, no duplicate legacytank or gameplay mutation")
	quit()
