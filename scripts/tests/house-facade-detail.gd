extends SceneTree

const HouseDetails = preload("res://scripts/land/ShelterArchitecture3D.gd")

class FakeMaterials extends RefCounted:
	func get_material(_kind: String) -> Material:
		return StandardMaterial3D.new()

class FakeRenderer extends Node:
	var _materials = FakeMaterials.new()
	var _glow_material: Material = StandardMaterial3D.new()
	var boxes: Array[Dictionary] = []
	var meshes: Array[Dictionary] = []

	func _box(label: String, center: Vector3, dimensions: Vector3, _material: Material) -> void:
		boxes.append({"label":label,"center":center,"size":dimensions})

	func _mesh(label: String, vertices: PackedVector3Array, indices: PackedInt32Array, _material: Material) -> void:
		meshes.append({"label":label,"vertices":vertices,"indices":indices})

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var details:=HouseDetails.new()
	for variant in ["", "home_pelana", "lurah_home"]:
		var renderer:=FakeRenderer.new()
		root.add_child(renderer)
		details.add_house_details(renderer,{"variant":variant},Vector3.ZERO,180.0,150.0,95.0,145.0)
		assert(renderer.meshes.size()==1 and renderer.boxes.size()==19,"House detail draw budget must stay bounded")
		var roof: Dictionary=renderer.meshes[0]
		assert(roof.label=="RoofCourseBinding" and roof.vertices.size()==12 and roof.indices.size()==18)
		for point in roof.vertices:
			assert(absf(point.x)<=100.0 and absf(point.y)<=88.0,"Roof courses must stay in the existing eave")
			assert(point.z>100.0 and point.z<180.0,"Roof courses need to sit on the roof slope")
		for box in renderer.boxes:
			var at: Vector3=box.center
			assert(absf(at.x)<=94.0 and absf(at.y)<=75.0,"Porch detail must stay close to the house frame")
		root.remove_child(renderer)
		renderer.free()
	for variant in ["metal", "director_rv", "balai", "workshop"]:
		var renderer:=FakeRenderer.new()
		root.add_child(renderer)
		details.add_house_details(renderer,{"variant":variant},Vector3.ZERO,180.0,150.0,95.0,145.0)
		assert(renderer.meshes.is_empty() and renderer.boxes.is_empty(),"Non-stilt architecture is unchanged")
		root.remove_child(renderer)
		renderer.free()
	print("HOUSE FACADE DETAIL PASS: three wood-house variants, four excluded structures, bounded meshes and local frame")
	quit()
