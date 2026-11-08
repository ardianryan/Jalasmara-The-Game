extends SceneTree

var output := "res://../artifacts/godot/land-rock-3d"
func _initialize() -> void:
	call_deferred("run")
func _alpha_bounds(image: Image) -> Rect2i:
	var minimum := Vector2i(image.get_width(),image.get_height())
	var maximum := Vector2i(-1,-1)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x,y).a<.2: continue
			minimum = minimum.min(Vector2i(x,y))
			maximum = maximum.max(Vector2i(x,y))
	assert(maximum.x>=minimum.x,"3D viewport rendered no visible model")
	return Rect2i(minimum,maximum-minimum+Vector2i.ONE)
func _brightness(image: Image) -> float:
	var total := 0.0
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x,y)
			if pixel.a<.5: continue
			total += pixel.r*.2126+pixel.g*.7152+pixel.b*.0722
			count += 1
	assert(count>50)
	return total/count
func _clipped_fraction(image: Image) -> float:
	var clipped := 0
	var opaque := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x,y)
			if pixel.a<.5: continue
			opaque += 1
			if minf(pixel.r,minf(pixel.g,pixel.b))>.96: clipped += 1
	return float(clipped)/maxi(opaque,1)
func _render(viewport: SubViewport) -> Image:
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var state := root.get_node("GameState")
	var before := JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})
	var rock = load("res://scripts/LandRockVisual.gd").new()
	root.add_child(rock)
	var foot := Vector2(480,380)
	var dimensions := Vector2(160,100)
	var solid := Rect2(390,280,180,100)
	assert(rock.configure(foot,dimensions,solid,.2),"Actual GLB helper could not initialize")
	for frame in range(16): await process_frame
	var status: Dictionary = rock.debug_status()
	assert(status.ready and status.meshCount>0)
	assert(str(status.modelPath).ends_with(".glb"),"Land rock must load a real 3D scene")
	assert(status.contained,"Projected rock must remain inside its original solid footprint")
	assert(rock.find_children("*","MeshInstance3D",true,false).size()>0)
	assert(rock.find_children("*","CollisionObject2D",true,false).is_empty())
	assert(rock.find_children("*","CollisionObject3D",true,false).is_empty())
	var viewports: Array = rock.find_children("*","SubViewport",true,false)
	assert(viewports.size()==1)
	var viewport: SubViewport = viewports[0]
	assert(viewport.transparent_bg and viewport.size==Vector2i(128,128))
	var sprites: Array = rock.find_children("*","Sprite2D",true,false)
	assert(sprites.size()==1 and sprites[0].texture is ViewportTexture,"A static PNG cannot substitute for the live 3D viewport")
	rock.set_process(false)
	rock.update_weather({"daylight":1.0,"clouds":0.0,"night":false})
	var day := await _render(viewport)
	day.save_png(output+"/day.png")
	var day_bounds := _alpha_bounds(day)
	var daylight := _brightness(day)
	var clipped_fraction := _clipped_fraction(day)
	assert(clipped_fraction<.3,"Day rock became a clipped white silhouette instead of readable facets")
	var sprite: Sprite2D = sprites[0]
	var top_left := sprite.to_global(sprite.get_rect().position+Vector2(day_bounds.position))
	var bottom_right := sprite.to_global(sprite.get_rect().position+Vector2(day_bounds.end))
	var rendered_foot := Vector2((top_left.x+bottom_right.x)*.5,bottom_right.y)
	assert(absf(rendered_foot.x-foot.x)<3.0,"Rock projection moved sideways from its ground pivot")
	assert(absf(bottom_right.y-foot.y)<3.0,"Rendered rock floats above or sinks below its ground pivot")
	assert(bottom_right.x-top_left.x<=dimensions.x+3 and bottom_right.y-top_left.y<=dimensions.y+3)
	rock.update_weather({"daylight":0.0,"clouds":0.0,"night":true})
	var night := await _render(viewport)
	night.save_png(output+"/night.png")
	var night_bounds := _alpha_bounds(night)
	var nightlight := _brightness(night)
	assert(day_bounds==night_bounds,"Lighting must not alter the rock's projected silhouette")
	assert(nightlight<daylight*.8,"Night lighting did not dim the actual 3D rock")
	assert(nightlight>0.005,"Night rock became entirely unreadable")
	assert(JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})==before)
	var report := {"model":status,"projectedFoot":[rendered_foot.x,rendered_foot.y],"dayClippedFraction":clipped_fraction,"alphaBounds":[day_bounds.position.x,day_bounds.position.y,day_bounds.size.x,day_bounds.size.y],"dayLuminance":daylight,"nightLuminance":nightlight,"nightRatio":nightlight/daylight}
	var file := FileAccess.open(output+"/results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("LAND ROCK RENDER PASS: actual GLB/meshes/live128px viewport, contained ground pivot, stable silhouette, day/night lighting ratio=",nightlight/daylight," and unchanged world/account/collision")
	rock.free()
	quit()
