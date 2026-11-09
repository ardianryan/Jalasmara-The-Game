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
	var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	renderer.setup(stage,player,camera,"hub")
	renderer.set_process(false)
	renderer._process(0)
	assert(renderer._shelter_architecture.roofs.size()==5)
	assert(renderer._components.ShelterCollisionPosts==10)
	assert(renderer._components.SasmitaPileFrame==1)
	assert(renderer._components.SasmitaPileFooting==4)
	assert(renderer._components.SasmitaSubmergedFoundationBed==1)
	var profiles: Array=state.world.surface_hub.residents.duplicate(true)
	var gardener: Dictionary=state.world.surface_hub.districtActivities["Bu Darmi"].duplicate(true)
	gardener.name="Bu Darmi"
	profiles.append(gardener)
	var body_samples:=0
	for profile in profiles:
		var point:=Vector2(profile.activity.shelter[0],profile.activity.shelter[1])
		var covered:=false
		for shelter in renderer.map.shelters:
			var corners: Array=[]
			if bool(shelter.get("existing",false)):
				for value in shelter.roof: corners.append(renderer.map_point(Vector2(value[0],value[1]),0)+Vector3(0,0,120))
			else: corners=renderer._shelter_architecture.roofs[shelter.id]
			var plan:=PackedVector2Array()
			for vertex in corners: plan.append(Vector2(vertex.x,vertex.y))
			var fits:=true
			for height in [0.0,35.0,70.0]:
				for direction in range(16):
					var offset:=Vector2.from_angle(direction*TAU/16.0)*13
					var sample: Vector3=renderer.map_point(point+offset,renderer.ground_height(point))+renderer.camera_3d.global_basis.y*height
					if not Geometry2D.is_point_in_polygon(Vector2(sample.x,sample.y),plan): fits=false
					if sample.z>minf(float(corners[0].z),float(corners[2].z))-5: fits=false
			if fits:
				covered=true
				body_samples+=48
				break
		assert(covered,str(profile.name)+" body extends beyond the actual vertical-rain roof silhouette")
	player.position=Vector2(160,615)
	renderer._shelter_architecture.update(renderer,1)
	for id in renderer._shelter_architecture._panels:
		var panel: Dictionary=renderer._shelter_architecture._panels[id]
		assert(float(panel.amount)==(1.0 if id=="griya_sasmita_serambi" else 0.0),"Only the roof above Nala may open")
		for material in panel.materials:
			assert(material.get_shader_parameter("base_color")!=null,"Cutaway keeps the existing material palette")
	renderer.camera_3d.rotation_degrees=Vector3(22,45,13)
	renderer._shelter_architecture.update(renderer,1)
	var shown: Dictionary=renderer._shelter_architecture._panels.griya_sasmita_serambi
	for material in shown.materials:
		assert(material.get_shader_parameter("reveal_right").is_equal_approx(renderer.camera_3d.global_basis.x))
		assert(material.get_shader_parameter("reveal_up").is_equal_approx(renderer.camera_3d.global_basis.y))
	player.position=Vector2(1120,1230)
	renderer._shelter_architecture.update(renderer,1)
	for panel in renderer._shelter_architecture._panels.values(): assert(float(panel.amount)==0.0,"All roof panels restore after leaving")
	print("SHELTER ARCHITECTURE06 PASS: 5 attached solid roofs,10 authoritative posts,4 pile footings with submerged bed,",body_samples," world-space foot/torso/head rain samples; camera unchanged")
	stage.free()
	quit()
