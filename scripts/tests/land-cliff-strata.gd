extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var stage:=Node2D.new()
	root.add_child(stage)
	var player:=Node2D.new()
	stage.add_child(player)
	var camera:=Camera2D.new()
	stage.add_child(camera)
	var land: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(land)
	land.setup(stage,player,camera,"hub")
	land.set_process(false)
	var ordinary: ShaderMaterial=land._materials.get_material("stone")
	var edge: ShaderMaterial=land._natural_edges.get("_stone_material")
	var shade: ShaderMaterial=land._natural_edges.get("_shade_material")
	var root_stone: ShaderMaterial=land._natural_edges.get("_root_material")
	assert(edge!=null and shade!=null and root_stone!=null)
	assert(not ordinary.get_shader_parameter("cliff_strata"),"Shared stone must not inherit cliff markings")
	for material in [edge,shade,root_stone]:
		assert(material.get_shader_parameter("cliff_strata"),"All exposed cliff buffers need continuous strata")
		assert(material.shader==ordinary.shader,"Cliff layers reuse the existing shader and draw buffers")
	assert(land._components.get("NaturalTerrainShoulder",0)>0)
	assert(land._natural_edges.debug_status().get("changesPhysics",true)==false)
	stage.free()
	print("LAND CLIFF STRATA PASS: edge-only markings on existing stone buffers; shared stone unchanged")
	quit()
