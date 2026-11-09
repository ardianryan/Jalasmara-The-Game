extends SceneTree

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var diagnostics=load("res://scripts/Diagnostics.gd")
	diagnostics.set_enabled(false)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(480,270)
	root.add_child(viewport)
	var camera:=Camera3D.new()
	viewport.add_child(camera)
	camera.current=true
	var parent:=Node3D.new()
	viewport.add_child(parent)
	var equipment=load("res://scripts/CharacterEquipment3D.gd").new()
	parent.add_child(equipment)
	var sprite:=Sprite3D.new()
	viewport.add_child(sprite)
	equipment.update_attachment(sprite,{"modular":true,"tank":true,"net":true},false,false)
	assert(equipment.visibility_diagnostics().is_empty(),"Default diagnostics must not expose gear fields")
	var land=load("res://scripts/land/LandActors3D.gd").new()
	viewport.add_child(land)
	land.set("_equipment",equipment)
	land.counts={"player":1}
	assert(not land.debug_counts().has("gearNodes"))
	var ocean=load("res://scripts/hybrid/OceanActors.gd").new()
	viewport.add_child(ocean)
	ocean.set("_equipment",equipment)
	assert(ocean.gear_node_diagnostics().is_empty())
	diagnostics.set_enabled(true)
	for mode in ["daily","diving","explorer"]:
		var diving:bool=mode=="diving"
		var explorer:bool=mode=="explorer"
		equipment.update_attachment(sprite,{"modular":true,"tank":diving,"net":diving,"satchel":explorer,"vest":false},false,false)
		var report:Dictionary=equipment.visibility_diagnostics()
		assert(report.visibilityScope=="scene-tree-not-pixel-occlusion" and report.rootInTree and report.rootVisibleInTree)
		assert(report.keys().size()==5 and report.nodes.keys().size()==4,"Allowlist must exclude account, path or mutable gameplay data")
		for key in ["tank","net","satchel","vest"]:
			var expected:bool=diving if key in ["tank","net"] else explorer if key=="satchel" else false
			assert(report.nodes[key].exists and report.nodes[key].meshCount>0)
			assert(report.nodes[key].visible==expected and report.nodes[key].visibleInTree==expected)
			assert((report.nodes[key].visibleMeshCount>0)==expected)
		assert(land.debug_counts().gearNodes==report and ocean.gear_node_diagnostics()==report)
		assert(not land.counts.has("gearNodes"),"Diagnostics must not mutate retained frame counts")
	parent.visible=false
	var hidden:Dictionary=equipment.visibility_diagnostics()
	assert(not hidden.rootVisibleInTree and hidden.nodes.satchel.visible and not hidden.nodes.satchel.visibleInTree and hidden.nodes.satchel.visibleMeshCount==0,"Parent-hidden gear must not be labelled visible in tree")
	parent.visible=true
	var tank:Node3D=equipment.get("_tank")
	tank.visible=true
	var tank_mesh:MeshInstance3D=tank.find_children("*","MeshInstance3D",true,false)[0]
	tank_mesh.visible=false
	var partial:Dictionary=equipment.visibility_diagnostics()
	assert(partial.nodes.tank.visibleMeshCount==partial.nodes.tank.meshCount-1,"Actual descendant visibility must be measured")
	diagnostics.set_enabled(false)
	assert(equipment.visibility_diagnostics().is_empty() and not land.debug_counts().has("gearNodes") and ocean.gear_node_diagnostics().is_empty())
	print("EQUIPMENT NODE DIAGNOSTICS PASS: opt-in allowlist, actual nodes/meshes, parent visibility, no counts mutation")
	quit()
