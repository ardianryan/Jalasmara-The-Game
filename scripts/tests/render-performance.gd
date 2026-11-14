extends SceneTree

class Actor extends Node2D:
	var swim_sprite: Sprite2D

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var budget=load("res://scripts/RenderBudget.gd")
	assert(budget.viewport_size(Vector2(960,540))==Vector2i(480,270))
	assert(budget.viewport_size(Vector2(960,540),budget.quality_budget("balanced"))==Vector2i(640,360))
	assert(budget.viewport_size(Vector2(960,540),budget.quality_budget("sharp"))==Vector2i(960,540))
	assert(budget.quality_budget("low")==129600)
	for logical in [Vector2(667,540),Vector2(1290,540),Vector2(960,2077),Vector2(3840,1080)]:
		for profile in ["low","balanced","sharp"]:
			var pixel_limit: int=budget.quality_budget(profile)
			var size: Vector2i=budget.viewport_size(logical,pixel_limit)
			assert(size.x*size.y<=pixel_limit)
			assert(absf(float(size.x)/size.y-logical.x/logical.y)<.015,"Render budget must preserve fullscreen aspect")
	var diagnostics=load("res://scripts/Diagnostics.gd")
	diagnostics.set_enabled(false)
	assert(not diagnostics.enabled())
	assert(diagnostics.performance_sample().is_empty(),"Disabled diagnostics must not sample performance")
	diagnostics.set_enabled(true)
	assert(diagnostics.enabled())
	var quality=root.get_node("RenderQuality")
	var old_profile: String=quality.get_profile().requested
	var old_path: String=quality.settings_path
	var old_coarse: bool=quality.get("_coarse")
	var old_auto_drop: int=quality.get("_auto_drop")
	var config_path: String="user://render-quality-test.cfg"
	quality.settings_path=config_path
	quality.set_profile("balanced",false)
	assert(not quality.set_profile("ultra"),"Unknown graphics profiles must be rejected")
	assert(quality.set_profile("low"))
	assert(quality.get_profile().effective=="low" and not quality.get_profile().sunShadows)
	assert(quality.get_profile().spotShadowAtlasSize==512,"Diver occlusion retains a bounded shadow atlas")
	var saved:=ConfigFile.new()
	assert(saved.load(config_path)==OK and saved.get_value("graphics","quality")=="low")
	assert(quality.set_profile("balanced") and quality.get_profile().sunShadows)
	assert(quality.set_profile("sharp",false) and quality.get_profile().effective=="sharp")
	quality.set("_coarse",true)
	quality.set_profile("auto")
	assert(quality.get_profile().effective=="balanced","Auto should keep touch graphics legible")
	quality.set("_coarse",false)
	assert(quality.get_profile().effective=="sharp")
	quality.set("_auto_drop",1)
	assert(quality.get_profile().effective=="balanced")
	quality.set("_coarse",true)
	assert(quality.get_profile().effective=="low")
	quality.set("_coarse",old_coarse)
	quality.set_profile(old_profile,false)
	quality.set("_auto_drop",old_auto_drop)
	quality.settings_path=old_path
	DirAccess.remove_absolute(config_path)
	var metrics: Dictionary=diagnostics.performance_sample(quality)
	assert(metrics.has("fps") and metrics.has("processMs") and metrics.has("physicsMs") and metrics.has("drawCalls"))
	var state=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_default","progress":{"day":1,"stage":"dive"}}
	state.dive={}
	state.homestead={"plots":[{"id":"plot_1","stage":"empty","needsCare":false},{"id":"plot_2","stage":"empty","needsCare":false}]}
	var scene:=Node2D.new()
	root.add_child(scene)
	var actor:=Actor.new()
	scene.add_child(actor)
	actor.position=Vector2(1120,1230)
	actor.swim_sprite=load("res://scripts/CharacterVisual.gd").new()
	actor.add_child(actor.swim_sprite)
	actor.swim_sprite.set_appearance("male_default")
	actor.swim_sprite.animate(false,false,1,0)
	var camera:=Camera2D.new()
	camera.position=actor.position
	camera.zoom=Vector2(.88,.88)
	scene.add_child(camera)
	camera.force_update_scroll()
	var renderer=load("res://scripts/land/LandWorld3D.gd").new()
	scene.add_child(renderer)
	renderer.setup(scene,actor,camera,"hub")
	await process_frame
	renderer._process(0)
	assert(renderer.viewport_3d.positional_shadow_atlas_size==512)
	quality.set_profile("low",false)
	renderer._process(.3)
	assert(not renderer.sunlight.shadow_enabled,"Low graphics must disable the actual directional shadow map")
	quality.set_profile("balanced",false)
	renderer._process(.3)
	quality.set_profile(old_profile,false)
	var geometry_id: int=renderer.get("_geometry").get_instance_id()
	var water_id: int=renderer.water_node.get_instance_id()
	var actors_id: int=renderer.actors_3d.get_instance_id()
	var plot2_id: int=renderer.get("_plot_nodes")["home_plot_2"].get_instance_id()
	var builds: int=renderer.debug_status().performance.staticBuilds
	for stage in ["seed","sprout","young","ready","empty"]:
		var home: Dictionary=state.homestead.duplicate(true)
		home.plots[0].stage=stage
		renderer.set_homestead_state(home)
		renderer._process(0)
		assert(renderer.get("_geometry").get_instance_id()==geometry_id,"Crop updates must not rebuild architecture")
		assert(renderer.water_node.get_instance_id()==water_id,"Crop updates must retain shoreline and water simulation")
		assert(renderer.actors_3d.get_instance_id()==actors_id,"Crop updates must retain NPC actor rigs")
		assert(renderer.get("_plot_nodes")["home_plot_2"].get_instance_id()==plot2_id,"Only the changed crop plot may be replaced")
		assert(renderer.debug_status().performance.staticBuilds==builds)
		assert(renderer.debug_status().components.HomeGardenBed==2)
		assert(renderer.get("_plot_nodes")["home_plot_1"].get_child_count()<=4,"Dynamic crop geometry must stay batched by material")
		if stage=="seed": assert(renderer.debug_status().components.HomeSeedMound==4)
		if stage=="ready": assert(renderer.debug_status().components.HomeHarvestLeaf==8)
	var before_updates: int=renderer.debug_status().performance.plotUpdates
	var no_visual_change: Dictionary=state.homestead.duplicate(true)
	no_visual_change.plots[0].watered=true
	renderer.set_homestead_state(no_visual_change)
	renderer._process(0)
	assert(renderer.debug_status().performance.plotUpdates==before_updates,"Nonvisual revisions must not rebuild crop geometry")
	var water=renderer.water_node
	state.dive={"id":"performance-test"}
	renderer._process(0)
	var elapsed: float=water.elapsed
	water._process(1)
	assert(water.elapsed==elapsed and water.process_mode==Node.PROCESS_MODE_DISABLED,"Inactive land water must not simulate during a dive")
	state.dive={}
	renderer._process(0)
	water._process(.1)
	assert(water.elapsed>elapsed,"Water animation must resume after returning to land")
	var field_script=load("res://scripts/land/WaterField.gd")
	var stats: Dictionary=field_script.cache_stats()
	var field=field_script.new()
	field.configure(state.world.landMaps.hub)
	assert(field_script.cache_stats().builds==stats.builds)
	assert(field_script.cache_stats().hits==stats.hits+1)
	assert(field.shoreline_texture==water.water_field.shoreline_texture)
	var original_sample: Dictionary=water.water_field.sample_world(Vector2(940,310))
	var original_emitters: int=water.water_field.emitters.size()
	var other_geometry: Dictionary=state.world.landMaps.hub.duplicate(true)
	other_geometry.surfaces=[]
	other_geometry.obstacles=[]
	other_geometry.landmass=[]
	field.configure(other_geometry)
	assert(not field.sample_world(Vector2(940,310)).on_land,"Different geometry with the same layout version needs its own shoreline cache entry")
	assert(field_script.cache_stats().builds==stats.builds+1)
	assert(water.water_field.sample_world(Vector2(940,310))==original_sample,"Reconfiguring another field must not mutate cached shoreline samples")
	assert(water.water_field.emitters.size()==original_emitters,"Cached emitter arrays must not be cleared by another field")
	for index in range(7):
		var changed: Dictionary=state.world.landMaps.hub.duplicate(true)
		changed.layoutVersion=1000+index
		field.configure(changed)
	assert(field_script.cache_stats().entries<=6,"Shoreline cache must be bounded")
	state.dive={"id":"hidden-simulation-test","mode":"dive"}
	var entities=load("res://scripts/Entities.gd").new()
	entities.player=actor
	entities.visible=false
	scene.add_child(entities)
	var target: Dictionary={"id":"test-moving-target","x":1250,"y":530,"fragmentId":"klorofil","subject":"Biologi"}
	var before_target: Vector2=entities.target_position(target)
	entities._process(.1)
	var wildlife=entities.wildlife
	wildlife._process(.1)
	assert(entities.elapsed>0 and wildlife.elapsed>0,"Hiding 2D presentation must preserve simulation used by 3D actors")
	assert(entities.target_position(target).distance_to(before_target)>.001)
	assert(not wildlife.creatures.is_empty())
	var fish_position: Vector2=wildlife.creatures[0].position
	wildlife._process(.1)
	assert(Vector2(wildlife.creatures[0].position).distance_to(fish_position)>.001,"Hidden fish must keep swimming for OceanActors")
	assert(entities.presentation_updates==0 and wildlife.presentation_updates==0,"Hidden 2D visual layers must not request redraws")
	state.dive={}
	scene.free()
	await process_frame
	print("RENDER PERFORMANCE PASS: aspect-preserving129600/230400/518400pixelbudgets, touch balanced and desktop sharp auto with low-FPS downgrade, opt-in diagnostics, five crop stage changes without static/water/NPC rebuilds, unchanged-plot identity, bounded shorelinecache, inactivewater pause/resume")
	quit()
