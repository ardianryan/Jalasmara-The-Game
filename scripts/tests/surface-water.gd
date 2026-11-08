extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var Helper = load("res://scripts/SurfaceWater.gd")
	var environment := root.get_node("EnvironmentState")
	var checked := 0
	for area in ["hub","forest"]:
		var water = Helper.new()
		root.add_child(water)
		water.configure(area,Vector2(2400,1600))
		water.set_process(false)
		assert(water.debug_status().active and water.debug_status().regionCells > 1000)
		var points := [[Vector2(1200,950),true],[Vector2(720,630),false],[Vector2(760,830),false],[Vector2(180,910),false]] if area == "hub" else [[Vector2(80,970),true],[Vector2(830,570),false],[Vector2(1280,185),false]]
		for sample in points:
			assert(water.sample_is_water(sample[0]*Vector2(2400.0/1536,1600.0/1024)) == sample[1],area+" water/land/dock/bridge clipping")
			checked += 1
		assert(not water.sample_is_water(Vector2(-1,1400)))
		assert(not water.sample_is_water(Vector2(2401,1400)))
		environment.reduced_motion = true
		water.set_time(10)
		assert(water.debug_status().reducedMotion and water.debug_status().refractionMaxTexels < 0.3)
		environment.reduced_motion = false
		water.set_time(20)
		assert(not water.debug_status().reducedMotion and water.debug_status().refractionMaxTexels <= 2)
		assert(not water.debug_status().geometryChanged)
		if OS.get_cmdline_user_args().has("--render-proof"):
			assert(DisplayServer.get_name() != "headless", "Native proof needs a real renderer")
			await render_proof(water,area)
		water.free()
	print("SURFACE WATER PASS: %d raster water/land/dock/bridge samples, bounds, weather parameters, reduced motion, no collision changes" % checked)
	quit()

func render_proof(water: Node2D, area: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1536,1024)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.world_2d = World2D.new()
	root.add_child(viewport)
	var source := Sprite2D.new()
	source.texture = water._raster
	source.centered = false
	source.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.add_child(source)
	water.reparent(viewport,false)
	water.scale = Vector2(1536.0/2400,1024.0/1600)
	water.set_time(0)
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var first := viewport.get_texture().get_image()
	first.save_png("res://../.runtime/surface-water-"+area+"-t0.png")
	water.set_time(3)
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var second := viewport.get_texture().get_image()
	second.save_png("res://../.runtime/surface-water-"+area+"-t3.png")
	assert(first.get_size() == Vector2i(1536,1024))
	var changed_water := 0
	var changed_land := 0
	var unchanged_land := 0
	for y in range(0,1024,2):
		for x in range(0,1536,2):
			var changed := first.get_pixel(x,y) != second.get_pixel(x,y)
			var point := Vector2(x+0.5,y+0.5)*Vector2(2400.0/1536,1600.0/1024)
			if water.sample_is_water(point):
				if changed: changed_water += 1
			elif changed: changed_land += 1
			else: unchanged_land += 1
	assert(changed_water > 500, "Surface water does not visibly evolve")
	assert(changed_land == 0, "Water animation affected land/docks/bridge pixels: "+str(changed_land))
	print("NATIVE SURFACE WATER PASS %s: %d animated water pixels, %d unchanged nonwater pixels, %d changed land/dock pixels" % [area,changed_water,unchanged_land,changed_land])
	var night_tint := CanvasModulate.new()
	night_tint.color = Color(0.4,0.5,0.65)
	viewport.add_child(night_tint)
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var night := viewport.get_texture().get_image()
	night.save_png("res://../.runtime/surface-water-"+area+"-night.png")
	var water_point := Vector2i(1200,950) if area == "hub" else Vector2i(80,970)
	var land_point := Vector2i(720,630) if area == "hub" else Vector2i(830,570)
	var water_ratio := night.get_pixelv(water_point).g / second.get_pixelv(water_point).g
	var land_ratio := night.get_pixelv(land_point).g / second.get_pixelv(land_point).g
	print("Night modulation %s water=%.4f land=%.4f" % [area,water_ratio,land_ratio])
	assert(absf(water_ratio-land_ratio)<0.035, "Water must receive the same CanvasModulate night shading as land")
	assert(absf(water_ratio-0.5)<0.035, "Night shading must apply exactly once")
	water.reparent(root,false)
	viewport.free()
