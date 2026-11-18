extends SceneTree

const TILT := deg_to_rad(12.0)
const DISTANCE := 2200.0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	print("CAVE_ISOLATED: initialize")
	var variant := OS.get_environment("OCEAN_CAVE_VARIANT")
	if variant.is_empty(): variant = "baseline"
	var directory := "res://../artifacts/godot/ocean-cave-isolated/" + variant
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var stage := Node3D.new()
	stage.scale.y = 1.0 / cos(TILT)
	root.add_child(stage)
	var terrain: Node3D = load("res://scripts/hybrid/TerrainGeometry.gd").new()
	terrain.set_process(false)
	stage.add_child(terrain)
	var rock := StandardMaterial3D.new()
	rock.albedo_color = Color("789a9d")
	rock.roughness = 1.0
	rock.cull_mode = BaseMaterial3D.CULL_DISABLED
	var materials: Array[Material] = [rock, rock, rock]
	terrain.set("_materials", materials)
	terrain.call("_build_cave_backwall")
	assert(terrain.get_node_or_null("CaveRearRockWall") != null)
	print("CAVE_ISOLATED: wall built")
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("17616b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b4d6d5")
	environment.ambient_light_energy = 1.0
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	root.add_child(world_environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-24, -25, -12)
	light.light_energy = 1.25
	light.light_color = Color("e6eedb")
	root.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.near = 5.0
	camera.far = 4500.0
	camera.current = true
	root.add_child(camera)
	var center := Vector2(750, 900)
	for size in [Vector2i(844,390), Vector2i(667,375)]:
		root.size = size
		var eye := Vector3(center.x, -center.y / cos(TILT), 0)
		camera.position = eye + Vector3(0, sin(TILT) * DISTANCE, cos(TILT) * DISTANCE)
		camera.look_at(eye, Vector3.UP)
		camera.size = size.y
		print("CAVE_ISOLATED: waiting frames %dx%d" % [size.x, size.y])
		for tick in range(8): await process_frame
		print("CAVE_ISOLATED: waiting draw %dx%d" % [size.x, size.y])
		await RenderingServer.frame_post_draw
		var path := directory + "/%dx%d.png" % [size.x, size.y]
		var error := root.get_texture().get_image().save_png(path)
		assert(error == OK, "Could not save " + path)
		print("CAVE_ISOLATED: saved " + path)
	quit()
