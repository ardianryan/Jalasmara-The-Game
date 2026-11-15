extends SceneTree

func _initialize() -> void:
	var helper=load("res://scripts/land/NaturalTerrainEdges3D.gd").new()
	var buffer: Dictionary=helper._buffer()
	var a:=Vector3(0,0,20)
	var b:=Vector3(34,0,20)
	var c:=Vector3(34,0,0)
	var d:=Vector3(0,0,0)
	helper._triangle(buffer,a,b,c,Vector3(0,-1,0))
	helper._triangle(buffer,a,c,d,Vector3(0,-1,0))
	assert(buffer.vertices.size()==6 and buffer.indices.size()==6)
	var area:=0.0
	for index in range(0,buffer.indices.size(),3):
		var vertices: PackedVector3Array=buffer.vertices
		var indices: PackedInt32Array=buffer.indices
		var p: Vector3=vertices[indices[index]]
		var q: Vector3=vertices[indices[index+1]]
		var r: Vector3=vertices[indices[index+2]]
		var normal:=-(q-p).cross(r-p)
		assert(normal.normalized().dot(Vector3(0,-1,0))>.99)
		area+=normal.length()*.5
	assert(is_equal_approx(area,680.0),"Two differently shaded facets must cover exactly the original wall face")
	var first: Dictionary=helper._node(Vector2(200,300),Vector2(200,300),Vector2.RIGHT,96.0)
	var again: Dictionary=helper._node(Vector2(200,300),Vector2(200,300),Vector2.RIGHT,96.0)
	assert(first==again and first.lip>=12.0 and first.lip<=29.0,"The visual lip must remain deterministic and bounded")
	print("TERRAIN FACETS PASS: exact face coverage, outward winding, deterministic bounded cap")
	quit()
