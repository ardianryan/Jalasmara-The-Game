extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":321,"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive={}
	state.homestead={"plots":[{"id":"plot_1","cropId":"kangkung","stage":"mature"},{"id":"plot_2","cropId":"jahe","stage":"mature"}],"fishPen":{"breeders":2,"offspring":3}}
	var before:=JSON.stringify({"world":state.world,"player":state.player,"home":state.homestead})
	var stage:=Node2D.new()
	root.add_child(stage)
	var player:Node2D=load("res://scripts/Player.gd").new()
	stage.add_child(player)
	player.set_physics_process(false)
	player.visible=false
	player.position=Vector2(275,850)
	var camera:=Camera2D.new()
	stage.add_child(camera)
	var renderer:Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	renderer.setup(stage,player,camera,"hub")
	renderer.set_process(false)
	await process_frame
	var collision:Node2D=load("res://scripts/land/LandCollision.gd").new()
	stage.add_child(collision)
	collision.configure(state.world.landMaps.hub)
	assert(renderer.debug_status().houses==10)
	for home in state.world.homestead.privateHomes:
		var at:=Vector2(float(home.door.x),float(home.door.y))
		assert(collision.is_walkable(at),"Both closed private homes need a legal outdoor entrance")
	for key in ["WirabhumiLowerRoof","WirabhumiUpperRoof","WirabhumiPrivateDoor","DirectorRVContainer","DirectorRVPrivateDoor","DirectorRVSolarPanel","HomesteadFishPen"]:
		assert(renderer._components.get(key,0)>0,key+" must be real native geometry")
	assert(renderer._plot_components.home_plot_1.get("HomeCropLeaves",0)>0)
	assert(renderer._plot_components.home_plot_1.get("HomeGingerRhizome",0)==0)
	assert(renderer._plot_components.home_plot_2.get("HomeGingerRhizome",0)>0)
	var builds:int=renderer._static_builds
	var changed:Dictionary=state.homestead.duplicate(true)
	changed.plots[0].cropId="jahe"
	renderer.set_homestead_state(changed)
	renderer._update_home_plots()
	assert(renderer._plot_components.home_plot_1.get("HomeGingerRhizome",0)>0,"Changing only cropId at the same stage must rebuild the correct crop")
	assert(renderer._static_builds==builds,"Crop swaps cannot rebuild the entire village")
	var pen:MultiMeshInstance3D=renderer._fish_pen._fish
	assert(is_instance_valid(pen) and pen.get_parent()==renderer.world_root)
	assert(pen.multimesh.visible_instance_count==5)
	var samples:=0
	var readback:=DisplayServer.get_name()!="headless"
	renderer._fish_pen.capture_transforms=true
	var native_samples:=0
	for count in [0,2,7]:
		changed.fishPen={"breeders":mini(count,2),"offspring":maxi(count-2,0)}
		renderer.set_homestead_state(changed)
		for time in [0.0,.5,3.0,12.0]:
			renderer._fish_pen.update(renderer,time)
			assert(pen.multimesh.visible_instance_count==count)
			assert(renderer._fish_pen.emitted_transforms.size()==count)
			if readback: await process_frame
			for index in range(count):
				var emitted:Transform3D=renderer._fish_pen.emitted_transforms[index]
				var delta:Vector3=emitted.origin-renderer._fish_pen._center
				assert(absf(delta.x)<=24.01 and absf(delta.y)<=17.01 and delta.z<0,"Live fish stay below the physical pen frame: "+str(delta))
				if readback:
					assert(pen.multimesh.get_instance_transform(index).is_equal_approx(emitted),"Native readback must match the actual emitted transform")
					native_samples+=1
				samples+=1
	var clock:Node=root.get_node("EnvironmentState")
	var old_reduced:bool=clock.reduced_motion
	clock.reduced_motion=true
	renderer._fish_pen.update(renderer,0)
	var fixed:Transform3D=renderer._fish_pen.emitted_transforms[0]
	renderer._fish_pen.update(renderer,99)
	assert(renderer._fish_pen.emitted_transforms[0]==fixed)
	if readback: assert(pen.multimesh.get_instance_transform(0).is_equal_approx(fixed))
	clock.reduced_motion=old_reduced
	assert(JSON.stringify({"world":state.world,"player":state.player,"home":state.homestead})==before,"World geometry must not mutate authoritative crops, catch stock or coins")
	stage.free()
	await process_frame
	print("VILLAGE EXPANSION WORLD PASS:2 connected private homes, actual Lurah/RV components, distinct crops with same-stage swap/no full rebuild, counts0/2/7, no authoritative-state mutation; emitted fish transforms=",samples,", native readbacks=",native_samples)
	if not readback: print("LIMIT: headless DummyRenderingServer does not expose MultiMesh transforms; native run required for fish motion bounds/reduced-motion transform acceptance")
	quit()
