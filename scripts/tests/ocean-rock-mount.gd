extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var unchanged:=JSON.stringify(data)
	var terrain=load("res://scripts/hybrid/TerrainGeometry.gd").new()
	root.add_child(terrain)
	terrain.configure(data)
	var mounting=load("res://scripts/hybrid/OceanRockMount.gd")
	var mounts: Array=terrain.get_meta("model_rock_mounts")
	assert(mounts.size()==3 and terrain.model_instances==3,"All three original GLB decorations retain genuine volume")
	var checked:=0
	for model in terrain.get_children():
		if not model.has_meta("reef_mount"):continue
		var mount: Dictionary=model.get_meta("reef_mount")
		assert(mount.supported and mount.allVerticesWithinTerrain)
		assert(absf(mount.depth-115)>20,"Mount depth must derive from the support mesh, not the old floating constant")
		var at:=Vector2(mount.at[0],mount.at[1])
		assert(mounting.projected(model.position,deg_to_rad(12)).distance_to(at)<.001,"Authored projected origin cannot move")
		var contact:=Vector3(mount.contact[0],mount.contact[1],mount.contact[2])
		var mesh: MeshInstance3D=terrain.get_node("ReefRelief%d"%mount.terrain)
		var hit: Variant=mounting.front_at(mesh,mounting.projected(contact,deg_to_rad(12)),deg_to_rad(12))
		assert(hit is Vector3 and is_equal_approx(hit.z-contact.z,float(mount.penetration)),"An actual transformed mesh vertex must penetrate the existing reef surface by the bounds-derived overlap")
		assert(float(mount.modelDepthRange[1])-float(mount.modelDepthRange[0])>20,"Do not flatten the real GLB to a2D image")
		for instance in model.find_children("*","MeshInstance3D",true,false):
			var material: StandardMaterial3D=instance.material_override
			assert(material.albedo_texture!=null and material.uv1_triplanar,"The UV-less GLB needs real triplanar reef texture, not a single sampled pixel")
			assert(material.albedo_texture.get_width()==128)
		checked+=1
	assert(checked==3)
	var unsupported: Node3D=load("res://resources/models/reef-rock.glb").instantiate()
	unsupported.scale=Vector3.ONE*95
	assert(not mounting.solve(terrain,data,unsupported,Vector2(1550,620),deg_to_rad(12)).supported,"Free water cannot support decorative rocks")
	unsupported.free()
	assert(terrain.find_children("*","CollisionObject3D",true,false).is_empty())
	assert(JSON.stringify(data)==unchanged)
	print("OCEAN ROCK MOUNT PASS:3 real GLBs, actual vertex/reef triangle contact from model depth-span, original XY pivots, volume retained, unsupported free-water rejected, no collision/world mutation; depths ",mounts.map(func(m: Dictionary) -> float:return float(m.depth)))
	terrain.free()
	quit()
