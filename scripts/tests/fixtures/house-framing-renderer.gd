extends "res://scripts/land/LandWorld3D.gd"

var house_bounds: Dictionary={}

func _batch_static_geometry() -> void:
	# Preserve actual transformed mesh bounds before the shared renderer batches them.
	for entry in map.obstacles:
		if str(entry.kind)!="house": continue
		var building: Node3D=_geometry.get_node(str(entry.id))
		var points: Array[Vector3]=[]
		for mesh: MeshInstance3D in building.find_children("*","MeshInstance3D",true,false):
			var bounds:=mesh.get_aabb()
			for corner in range(8): points.append(mesh.global_transform*bounds.get_endpoint(corner))
		house_bounds[entry.id]=points
	super._batch_static_geometry()
