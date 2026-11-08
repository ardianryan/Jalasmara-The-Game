extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func _positions(backdrop: Node) -> Dictionary:
	var result := {}
	for mesh in backdrop.find_children("*","MeshInstance3D",true,false):
		result[str(mesh.get_path())] = mesh.global_position
	return result

func _distinct_motion(before: Dictionary, after: Dictionary, axis: int) -> int:
	var values := {}
	for key in before:
		if not after.has(key): continue
		var delta: Vector3 = Vector3(after[key])-Vector3(before[key])
		var movement := delta.x if axis == 0 else delta.y
		if absf(movement)>0.1: values[roundi(movement*10)] = true
	return values.size()

func run() -> void:
	var atlas_texture := load("res://resources/art/ocean-atmosphere-atlas.png") as Texture2D
	var atlas := atlas_texture.get_image()
	assert(not atlas.is_empty())
	assert(atlas.get_width()%3==0 and atlas.get_height()%2==0)
	var cell := Vector2i(atlas.get_width()/3,atlas.get_height()/2)
	var transparent_samples := 0
	for index in range(6):
		var origin := Vector2i((index%3)*cell.x,(index/3)*cell.y)
		for corner in [Vector2i.ZERO,Vector2i(cell.x-1,0),Vector2i(0,cell.y-1),cell-Vector2i.ONE]:
			assert(atlas.get_pixelv(origin+corner).a<0.12,"Backdrop gutter would render an opaque card")
			transparent_samples += 1
		var visible := 0
		for y in range(0,cell.y,8):
			for x in range(0,cell.x,8):
				if atlas.get_pixelv(origin+Vector2i(x,y)).a>0.5: visible += 1
		assert(visible>30,"Atlas slot has no visible environmental silhouette")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var world_before := JSON.stringify(data)
	var state := root.get_node("GameState")
	var saved_player: Dictionary = state.player
	var saved_dive: Dictionary = state.dive
	state.player = {"coins":73,"inventory":[{"fragmentId":"fixture","quantity":2}],"progress":{"day":2,"stage":"dive"}}
	state.dive = {"oxygen":67,"weight":3,"loot":[]}
	var player_before := JSON.stringify(state.player)
	var dive_before := JSON.stringify(state.dive)
	var backdrop = load("res://scripts/hybrid/OceanBackdrop.gd").new()
	root.add_child(backdrop)
	backdrop.configure(data)
	var weather := {"daylight":1.0,"clouds":0.0,"rain":0.0,"current_x":0.12,"current_y":0.03,"reduced_motion":false}
	backdrop.update_camera(Vector2(1550,620),weather,10.0)
	var start: Dictionary = backdrop.debug_status()
	assert(start.active and start.atlasAvailable)
	assert(start.layers.size()==3)
	assert(start.layers[0].depth<start.layers[1].depth and start.layers[1].depth<start.layers[2].depth)
	assert(start.layers[0].contrast<start.layers[1].contrast and start.layers[1].contrast<start.layers[2].contrast)
	assert(start.layers[0].parallax[0]<start.layers[1].parallax[0] and start.layers[1].parallax[0]<start.layers[2].parallax[0])
	assert(start.layers[0].parallax[1]<start.layers[1].parallax[1] and start.layers[1].parallax[1]<start.layers[2].parallax[1])
	var before := _positions(backdrop)
	assert(before.size()>10,"Rich backdrop needs several environmental forms")
	assert(before.size()<=49,"Backdrop exceeded its bounded 48-card plus gradient budget")
	var cards := 0
	for layer in start.layers: cards += int(layer.cards)
	assert(cards==48,"Expected deterministic atmospheric card count")
	backdrop.update_camera(Vector2(1790,740),weather,10.0)
	var moved := _positions(backdrop)
	assert(_distinct_motion(before,moved,0)>=3,"Horizontal parallax collapsed to a single plane")
	assert(_distinct_motion(before,moved,1)>=3,"Vertical parallax collapsed to a single plane")
	var normal: Dictionary = backdrop.debug_status()
	weather.reduced_motion = true
	backdrop.update_camera(Vector2(1790,740),weather,10.0)
	var reduced: Dictionary = backdrop.debug_status()
	assert(reduced.reducedMotion and reduced.swayAmplitude==0)
	assert(normal.swayAmplitude>reduced.swayAmplitude)
	var reduced_before := _positions(backdrop)
	backdrop.update_camera(Vector2(1890,790),weather,10.0)
	assert(_distinct_motion(reduced_before,_positions(backdrop),0)>=3,"Reduced motion must preserve spatial depth")
	for depth in [10.0,45.0,90.0]:
		backdrop.update_camera(Vector2(1550,620),weather,depth)
		var snapshot: Dictionary = backdrop.debug_status()
		assert(is_equal_approx(float(snapshot.depth),depth))
		for layer in snapshot.layers:
			assert(float(layer.visibility)>=0 and float(layer.visibility)<=1)
	assert(backdrop.find_children("*","CollisionObject3D",true,false).is_empty())
	assert(backdrop.find_children("*","CollisionObject2D",true,false).is_empty())
	assert(backdrop.find_children("*","CollisionShape3D",true,false).is_empty())
	assert(JSON.stringify(data)==world_before,"Parallax must not alter collision/world metadata")
	assert(JSON.stringify(state.player)==player_before and JSON.stringify(state.dive)==dive_before,"Atmosphere must not alter progression or dive resources")
	state.player = saved_player
	state.dive = saved_dive
	backdrop.free()
	print("OCEAN BACKDROP PASS: ",transparent_samples," alpha gutter samples, three atmospheric distances, actual horizontal/vertical mesh parallax, reduced motion and unchanged collision/progression")
	quit()
