extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var scene:=Node2D.new()
	root.add_child(scene)
	var player:=Node2D.new()
	player.position=Vector2(1775,515)
	scene.add_child(player)
	var camera:=Camera2D.new()
	scene.add_child(camera)
	var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	scene.add_child(renderer)
	renderer.setup(scene,player,camera,"hub")
	var material: ShaderMaterial=renderer._materials.get_material("wind_leaves")
	var flower: ShaderMaterial=renderer._materials.get_material("wind_flower")
	assert(int(material.get_shader_parameter("kind"))==12)
	assert(int(flower.get_shader_parameter("kind"))==13)
	assert(int(renderer.get("_components").get("SmallFlower",0))>0,"Visible ground flowers need a wind material")
	assert(int(renderer.get("_components").get("CropLeaves",0))>0,"Garden crops need wind heads")
	var fern_nodes:=0
	for sprite in renderer.get("_geometry").find_children("*","Sprite3D",true,false):
		if sprite.texture!=null and sprite.texture.resource_path.ends_with("fern-plant.png"): fern_nodes+=1
	var registered:=0
	for leaf in renderer.get("_leaves"):
		var sprite: Sprite3D=leaf.node as Sprite3D
		if sprite!=null and sprite.texture!=null and sprite.texture.resource_path.ends_with("fern-plant.png"): registered+=1
	assert(fern_nodes>0 and fern_nodes==registered,"All surface ferns must enter the existing wind updater")
	var reduced_pos: Array[Vector3]=[]
	var motion=load("res://scripts/FoliageMotion.gd")
	for leaf in renderer.get("_leaves"):
		var home: Vector3=leaf.home
		reduced_pos.append(home)
		assert(motion.land_offset(4.01,Vector2(home.x,home.y),22.0,float(leaf.pixel),float(leaf.size))==motion.land_offset(4.07,Vector2(home.x,home.y),22.0,float(leaf.pixel),float(leaf.size)),"Wind should hold for 100 ms")
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.reduced_motion=true
	renderer._process(.1)
	for index in range(renderer.get("_leaves").size()): assert(renderer.get("_leaves")[index].node.position==reduced_pos[index],"Reduced-motion should return every leaf to its home pose")
	assert(bool(material.get_shader_parameter("wind_reduced")) and bool(flower.get_shader_parameter("wind_reduced")),"Reduced-motion must disable wind shaders")
	renderer.free()
	scene.free()
	print("LAND WIND COVERAGE PASS: trees, ground ferns, crop heads, flowers, reduced motion")
	quit()
