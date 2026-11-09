extends Node3D

var _tank: Node3D
var _net: Node3D
var _satchel: Node3D
var _vest: Node3D
var _built := false
var state: Dictionary = {}

func _material(color: String, metal := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color)
	material.roughness = .55 if metal else .95
	material.metallic = .28 if metal else 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func _mesh(parent: Node3D, geometry: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = geometry
	instance.material_override = material
	instance.position = at
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance

func _box(parent: Node3D, dimensions: Vector3, at: Vector3, material: Material) -> void:
	var box := BoxMesh.new()
	box.size = dimensions
	_mesh(parent,box,material,at)

func _cylinder(parent: Node3D, radius: float, height: float, at: Vector3, material: Material) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 8
	return _mesh(parent,cylinder,material,at)

func _ring(parent: Node3D, radius: float, tube: float, at: Vector3, material: Material) -> MeshInstance3D:
	var ring := TorusMesh.new()
	ring.inner_radius = radius-tube
	ring.outer_radius = radius+tube
	ring.rings = 12
	ring.ring_segments = 5
	return _mesh(parent,ring,material,at)

func _build() -> void:
	_built = true
	var copper := _material("ad8350",true)
	var dark := _material("3a4547")
	var teal := _material("568d91",true)
	var cloth := _material("8b7854")
	_tank = Node3D.new()
	_tank.name = "DetachableOxygenTank"
	add_child(_tank)
	_cylinder(_tank,5.3,23,Vector3.ZERO,teal)
	_cylinder(_tank,4.3,3,Vector3(0,13,0),copper)
	_cylinder(_tank,1.8,4,Vector3(0,16,0),dark)
	for y in [-8.0,8.0]: _ring(_tank,5.4,.8,Vector3(0,y,0),copper)
	_box(_tank,Vector3(4,2,1),Vector3(0,4,5.4),_material("bed3cb"))
	_net = Node3D.new()
	_net.name = "DetachableJala"
	add_child(_net)
	var handle := _cylinder(_net,1.4,17,Vector3(-6,0,0),copper)
	handle.rotation.z = PI*.5
	var rim := _ring(_net,5.5,.7,Vector3(7,0,0),copper)
	rim.rotation.x = PI*.5
	var fibers := _material("b2a583")
	for index in range(-2,3):
		var span := sqrt(maxf(0,25-index*index*2.25))
		_box(_net,Vector3(span*2,.45,.45),Vector3(7,index*1.5,0),fibers)
		_box(_net,Vector3(.45,span*2,.45),Vector3(7+index*1.5,0,0),fibers)
	_satchel = Node3D.new()
	_satchel.name = "DetachableFieldSatchel"
	add_child(_satchel)
	_box(_satchel,Vector3(10,11,3),Vector3.ZERO,cloth)
	_box(_satchel,Vector3(11,4,3.7),Vector3(0,4,.3),copper)
	_box(_satchel,Vector3(2,3,1),Vector3(1,1,2.2),dark)
	_box(_satchel,Vector3(7,6,.6),Vector3(0,7,.8),_material("d1c4a0"))
	_vest = Node3D.new()
	_vest.name = "DetachableExplorerVest"
	add_child(_vest)
	for side in [-1.0,1.0]:
		_box(_vest,Vector3(5.5,17,.8),Vector3(side*4,0,0),cloth)
		_box(_vest,Vector3(4.2,4.5,1.2),Vector3(side*4,-4,.6),copper)
		_box(_vest,Vector3(1,1,1),Vector3(side*4,-3,1.3),dark)

func update_attachment(sprite: Sprite3D,equipment: Dictionary,in_water: bool,flip: bool) -> void:
	if not _built: _build()
	state = equipment.duplicate()
	visible = sprite.visible and bool(equipment.get("modular",false))
	if not visible: return
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	global_transform = Transform3D(camera.global_basis.orthonormalized(),sprite.global_position)
	var body_size := float(equipment.get("bodySize",112.0 if in_water else 100.0))/100.0
	scale = Vector3.ONE*body_size
	var facing := -1.0 if flip else 1.0
	_tank.visible = bool(equipment.get("tank",false))
	_net.visible = bool(equipment.get("net",false))
	_satchel.visible = bool(equipment.get("satchel",false))
	_vest.visible = bool(equipment.get("vest",false))
	if in_water:
		_tank.position=Vector3(-9*facing,14,-1.8)
		_tank.rotation.z=-PI*.5*facing
		_net.position=Vector3(30*facing,-2,3)
		_net.scale.x=facing
		_satchel.position=Vector3(-10*facing,-14,3)
	else:
		var layout:=land_layout(str(equipment.get("facingDirection","west" if flip else "east")),float(equipment.get("gaitPhase",0)),bool(equipment.get("moving",false)))
		_tank.position=layout.tank
		_tank.rotation.z=0
		_net.position=layout.net
		_net.scale.x=float(layout.handFacing)
		_satchel.position=layout.satchel
	_vest.position=Vector3(0,0,2.3)

static func land_layout(direction: String,phase: float,moving: bool) -> Dictionary:
	var north:=direction in ["north","north_east","north_west"]
	var west:=direction in ["west","north_west","south_west"]
	var east:=direction in ["east","north_east","south_east"]
	var side:=-1.0 if west else 1.0
	var tank_x:=14.0 if west else -14.0 if east else 0.0
	if direction in ["north_east","north_west","south_east","south_west"]: tank_x*=.55
	var bob:=sin(phase*TAU)*1.1 if moving else 0.0
	var bag_x:=13.0 if north else -13.0
	var hand_x:=side*21 if east or west else -18.0 if north else 18.0
	return {"tank":Vector3(tank_x,4,7 if north else -7),"net":Vector3(hand_x,-10+bob,-3 if north else 4),"satchel":Vector3(bag_x,-14-absf(bob)*.4,4 if north else 3),"handFacing":side}

func debug_status() -> Dictionary:
	return {"facingDirection":state.get("facingDirection","east"),"gaitPhase":state.get("gaitPhase",0.0),"tankDepth":_tank.position.z if is_instance_valid(_tank) else 0.0,"netDepth":_net.position.z if is_instance_valid(_net) else 0.0,"modular":bool(state.get("modular",false)),"tank":is_instance_valid(_tank) and _tank.visible and visible,"net":is_instance_valid(_net) and _net.visible and visible,"satchel":is_instance_valid(_satchel) and _satchel.visible and visible,"vest":is_instance_valid(_vest) and _vest.visible and visible,"meshes":find_children("*","MeshInstance3D",true,false).size()}
