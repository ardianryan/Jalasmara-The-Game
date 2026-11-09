extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive={}
	var before:=JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})
	var scene:=Node2D.new()
	root.add_child(scene)
	var player: Node2D=load("res://scripts/Player.gd").new()
	scene.add_child(player)
	player.set_physics_process(false)
	player.position=Vector2(350,1250)
	player.swim_sprite.set_appearance("male_nusantara")
	player.swim_sprite.set_outfit("explorer")
	player.swim_sprite.set_locomotion(Vector2.ZERO,0)
	player.swim_sprite.animate(false,false,1,0)
	var camera:=Camera2D.new()
	scene.add_child(camera)
	var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	scene.add_child(renderer)
	renderer.setup(scene,player,camera,"forest")
	renderer.set_process(false)
	var helper=renderer.get("_canopy_readability")
	var feet: Vector3=renderer.map_point(player.position,renderer.ground_height(player.position))
	var up: Vector3=renderer.camera_up()
	var forward: Vector3=renderer.camera_forward()
	helper.update(feet,up,forward,.5)
	var settled: Dictionary=helper.debug_status()
	assert(settled.revealed>0 and settled.revealed<settled.crowns/4,"Gateway must reveal only its actual foreground occluders")
	var selected: Array=[]
	for index in range(helper.entries.size()):
		var entry: Dictionary=helper.entries[index]
		if entry.target:
			selected.append(index)
			assert(is_equal_approx(float(entry.amount),1.0))
		else: assert(is_zero_approx(float(entry.amount)),"Unrelated crowns must stay fully opaque")
	var masks:=int(settled.cachedMasks)
	for direction in range(8):
		player.swim_sprite.set_locomotion(Vector2.RIGHT.rotated(direction*PI*.25)*100,.02)
		player.swim_sprite.set_locomotion(Vector2.ZERO,.02)
		player.swim_sprite.animate(false,false,1,0)
		helper.update(feet,up,forward,.016)
		for index in selected: assert(helper.entries[index].target,"Turning in place must not flicker canopy selection")
	assert(int(helper.debug_status().cachedMasks)==masks,"Movement must reuse cached CPU masks")
	var entry: Dictionary=helper.entries[selected[0]]
	var node: Node3D=entry.node
	var original_position: Vector3=node.position
	# A one-sample texture gap must not switch a solid foreground crown instantly.
	helper.update(feet+Vector3(1500,0,0),up,forward,.016)
	assert(float(entry.amount)>.99 and entry.target,"Occlusion selection needs a short exit hold")
	helper.update(feet+Vector3(1500,0,0),up,forward,.5)
	assert(helper.debug_status().revealed==0,"Every local crown must restore after leaving")
	assert(node.position==original_position,"Readability must not move the authored canopy")
	# Put the same projected body in front of its crown: depth must reject the reveal.
	helper.update(node.global_position-forward*60-up*48+forward*8,up,forward,.5)
	assert(not entry.target and is_zero_approx(float(entry.amount)),"Crowns behind the player cannot be faded by screen overlap alone")
	assert(renderer.world_root.find_children("*","CollisionObject3D",true,false).is_empty())
	assert(renderer.debug_status().performance.softGroundVertices<6000,"Edge detail must stay a perimeter strip, not whole-surface tessellation")
	assert(renderer.debug_status().meshes<60,"Soft ground must retain shared material batches")
	assert(JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})==before,"Readability cannot change manifest, resources or save state")
	scene.free()
	print("FOREST READABILITY PASS: localized actual occluders, cached alpha masks, eight-direction stability, exit hold/full restoration, front/back depth, unchanged canopy position/collision/save and bounded batched edge geometry")
	quit()
