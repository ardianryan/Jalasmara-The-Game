extends RefCounted

var _fish: MultiMeshInstance3D
var _center:=Vector3.ZERO
var capture_transforms:=false
var emitted_transforms:Array[Transform3D]=[]

func build(renderer: Node) -> void:
	_fish=null
	if renderer.area!="hub": return
	var definition:Dictionary=GameState.world.get("homestead",{}).get("fishPen",{})
	if definition.is_empty(): return
	var anchor:Dictionary=definition.waterAnchor
	_center=renderer.map_point(Vector2(float(anchor.x),float(anchor.y)),float(anchor.z))
	var bamboo:Material=renderer._materials.get_material("bamboo")
	var wood:Material=renderer._materials.get_material("wood")
	var corners:Array[Vector3]=[]
	for offset in [Vector3(-36,-28,0),Vector3(36,-28,0),Vector3(36,28,0),Vector3(-36,28,0)]:
		corners.append(_center+offset)
	for index in range(4):
		var next:=(index+1)%4
		renderer._column(corners[index],corners[next],4,bamboo)
		renderer._column(corners[index]-Vector3(0,0,26),corners[index]+Vector3(0,0,6),2,wood)
		for section in range(7):
			var at:Vector3=corners[index].lerp(corners[next],float(section)/6)
			renderer._column(at-Vector3(0,0,22),at,0.6,wood)
		for depth in [8,16,22]: renderer._column(corners[index]-Vector3(0,0,depth),corners[next]-Vector3(0,0,depth),.6,wood)
	var deck:Vector3=renderer.map_point(Vector2(305,850),renderer.ground_height(Vector2(305,850)))
	for side in [-1.0,1.0]: renderer._column(deck+Vector3(0,side*18,6),_center+Vector3(-36,side*23,0),.7,wood)
	var body:=ArrayMesh.new()
	var vertices:=PackedVector3Array([Vector3(-7,0,0),Vector3(5,-3,0),Vector3(8,0,0),Vector3(5,3,0),Vector3(3,0,3),Vector3(3,0,-3),Vector3(-11,-4,0),Vector3(-11,4,0)])
	var triangles:=PackedInt32Array([0,1,4,1,2,4,2,3,4,3,0,4,0,5,1,1,5,2,2,5,3,3,5,0,0,6,7,0,7,6])
	var arrays:Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_INDEX]=triangles
	var normals:=PackedVector3Array()
	for vertex in vertices: normals.append(Vector3(0,0,1))
	arrays[Mesh.ARRAY_NORMAL]=normals
	body.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color("e5b36e")
	material.roughness=1
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	_fish=MultiMeshInstance3D.new()
	_fish.name="HomesteadPenFish"
	_fish.multimesh=MultiMesh.new()
	_fish.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	_fish.multimesh.mesh=body
	_fish.multimesh.instance_count=7
	_fish.multimesh.visible_instance_count=0
	_fish.material_override=material
	# Dynamic residents never enter the static world material batches.
	renderer.world_root.add_child(_fish)
	renderer._components["HomesteadFishPen"]=1
	update(renderer,0)

func update(renderer: Node, elapsed: float) -> void:
	if not is_instance_valid(_fish): return
	var state:Dictionary=renderer._homestead_state.get("fishPen",{})
	var count:=clampi(int(state.get("breeders",0))+int(state.get("offspring",0)),0,7)
	_fish.multimesh.visible_instance_count=count
	if capture_transforms: emitted_transforms.clear()
	var clock:=0.0 if EnvironmentState.reduced_motion else elapsed
	for index in range(count):
		var phase:=clock*.45+index*TAU/7
		# The coastal surface is opaque at Z=-14; shallow backs can breach it naturally.
		var at:=_center+Vector3(sin(phase)*24,cos(phase)*17,-3-float(index%2)*.4)
		var direction:=Vector3(cos(phase)*24,-sin(phase)*17,0)
		var transform:=Transform3D(Basis(Vector3(0,0,1),atan2(direction.y,direction.x)),at)
		_fish.multimesh.set_instance_transform(index,transform)
		if capture_transforms: emitted_transforms.append(transform)
