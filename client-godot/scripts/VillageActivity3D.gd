extends Node3D

var renderer: Node
var _actors: Dictionary = {}
var _materials: Dictionary = {}

func configure(owner_renderer: Node) -> void:
	renderer=owner_renderer

func _material(color: String) -> Material:
	if not _materials.has(color):
		var material:=StandardMaterial3D.new()
		material.albedo_color=Color(color)
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		_materials[color]=material
	return _materials[color]

func _mesh(parent: Node3D,geometry: Mesh,color: String) -> MeshInstance3D:
	var instance:=MeshInstance3D.new()
	instance.mesh=geometry
	instance.material_override=_material(color)
	instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance

func _line(parent: Node3D,color: String,radius: float) -> MeshInstance3D:
	var cylinder:=CylinderMesh.new()
	cylinder.height=1
	cylinder.top_radius=radius
	cylinder.bottom_radius=radius
	cylinder.radial_segments=5
	return _mesh(parent,cylinder,color)

func _place_line(mesh: MeshInstance3D,a: Vector3,b: Vector3) -> void:
	mesh.position=(a+b)*.5
	mesh.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	mesh.scale=Vector3(1,maxf(.01,a.distance_to(b)),1)

func _box(parent: Node3D,dimensions: Vector3,color: String) -> MeshInstance3D:
	var box:=BoxMesh.new()
	box.size=dimensions
	return _mesh(parent,box,color)

func begin_frame() -> void:
	for id in _actors.keys():
		var entry: Dictionary=_actors[id]
		if not is_instance_valid(entry.actor) or entry.actor.is_queued_for_deletion():
			entry.root.queue_free()
			_actors.erase(id)
		else: entry.root.visible=false

func update_actor(actor: Node2D,sprite: Sprite3D) -> void:
	if not actor.has_method("activity_state"): return
	var activity: Dictionary=actor.activity_state()
	var kind:=str(activity.kind)
	if kind=="idle": return
	var id:=actor.get_instance_id()
	if not _actors.has(id):
		var holder:=Node3D.new()
		holder.name="Activity_"+str(actor.actor_name).validate_node_name()
		add_child(holder)
		_actors[id]={"actor":actor,"root":holder,"lines":[],"boxes":[],"kind":kind}
		_build(_actors[id])
	var entry: Dictionary=_actors[id]
	var motion:=0.0 if EnvironmentState.reduced_motion else float(entry.get("poseMotion",0)) if EnvironmentState.clock_paused else float(actor.activity_motion)
	entry["poseMotion"]=motion
	if bool(activity.moving) and not EnvironmentState.reduced_motion and not EnvironmentState.clock_paused:
		sprite.position+=renderer.camera_up()*absf(sin(float(actor.get("_elapsed"))*5))*.7
	var body: Dictionary=actor.body_animation_state() if actor.has_method("body_animation_state") else {}
	var layered:=bool(body.get("layered",false))
	entry.root.visible=(str(body.get("clip","")) in ["start_work","work_loop","end_work"]) if layered else str(activity.phase)=="work"
	if not entry.root.visible: return
	var feet: Vector3=renderer.map_point(actor.position,renderer.ground_height(actor.position))
	var up: Vector3=renderer.camera_up()
	var hand: Vector3=feet+up*35+Vector3(10,0,0)-renderer.camera_forward()*12
	var other_hand: Vector3=hand-Vector3(8,0,0)
	var phase:=str(body.get("workPhase","work"))
	var pose_time:=float(body.get("elapsed",0))
	if layered:
		var anchors: Dictionary=body.get("hands",{})
		if anchors.has("right"):
			var point: Array=anchors.right
			hand=to_local(Vector3(float(point[0]),float(point[1]),float(point[2])))
		if anchors.has("left"):
			var point: Array=anchors.left
			other_hand=to_local(Vector3(float(point[0]),float(point[1]),float(point[2])))
	if EnvironmentState.reduced_motion: phase="wait" if kind=="fishing" else "aim" if kind=="gardening" else "weave"
	var lines: Array=entry.lines
	var boxes: Array=entry.boxes
	if kind=="fishing":
		var grip: Vector3=(hand-other_hand).normalized()
		if grip.length()<.5: grip=Vector3(-1,0,0)
		var tip:=hand+grip*47
		var water_point: Vector3=renderer.map_point(actor.position+Vector2(-80,70),0)+Vector3(0,0,-11+motion*.6)
		var hook:=tip-up*9
		var float_point:=water_point
		if layered:
			if phase in ["prepare","tidy"]: float_point=hook
			elif phase=="cast": float_point=hook.lerp(water_point,clampf((fposmod(pose_time,9)-1.0)/.8,0,1))
			elif phase=="pull": float_point=water_point.lerp(hook,clampf((fposmod(pose_time,9)-6.7)/1.3,0,1))
		_place_line(lines[0],other_hand-grip*3,tip)
		_place_line(lines[1],tip,float_point)
		boxes[0].position=float_point
		entry["gripMeasurement"]={"status":"unknown","reason":"Rod geometry is constructed from the same hand sockets; no independent palm grip pixel authored"}
	elif kind=="weaving":
		var left:=other_hand
		var right:=hand
		var vertical:=up*7
		_place_line(lines[0],left-vertical,right-vertical)
		_place_line(lines[1],left+vertical,right+vertical)
		_place_line(lines[2],left-vertical,left+vertical)
		_place_line(lines[3],right-vertical,right+vertical)
		for index in range(5):
			var center:=left.lerp(right,float(index)/4.0)
			_place_line(lines[index+4],center-vertical,center+vertical)
		boxes[0].position=left.lerp(right,(motion+1)*.5)+renderer.camera_forward()*-.2
		entry["gripError"]=0.0
	elif kind=="gardening":
		var center:=hand-up*4
		boxes[0].position=center
		var spout:=center+Vector3(15,0,0)-up
		_place_line(lines[0],center,spout)
		_place_line(lines[1],center+Vector3(-3,0,0),hand-Vector3(3,0,0))
		_place_line(lines[2],hand-Vector3(3,0,0),hand+Vector3(3,0,0))
		_place_line(lines[3],hand+Vector3(3,0,0),center+Vector3(3,0,0))
		for index in range(5):
			var t:=fposmod(float(index)/5.0+pose_time*.8,1)
			boxes[index+1].position=spout.lerp(feet+Vector3(95,0,30),t)-Vector3(0,0,sin(t*PI)*5)
			boxes[index+1].visible=phase=="pour" and not EnvironmentState.reduced_motion
		entry["gripError"]=0.0
	elif kind=="pump":
		var pivot:=hand+Vector3(motion*2,0,0)
		_place_line(lines[0],pivot-up*9,pivot+up*9)
		_place_line(lines[1],pivot+up*9,pivot+up*9+Vector3(7,0,0))
		boxes[0].position=feet+up*42+Vector3(-11,0,0)
	elif kind=="trading":
		for index in range(boxes.size()): boxes[index].position=hand+Vector3(index*5-6,0,0)+up*(motion*1.2+index%2*3)
	elif kind=="research":
		boxes[0].position=hand+Vector3(-4,0,0)+up*motion*.7
		boxes[1].position=hand+Vector3(5,0,0)+up*motion*.7

func _build(entry: Dictionary) -> void:
	var holder: Node3D=entry.root
	var kind:=str(entry.kind)
	match kind:
		"fishing":
			entry.lines=[_line(holder,"92714c",.8),_line(holder,"d3cba9",.25)]
			entry.boxes=[_box(holder,Vector3(2,2,3),"c98b5d")]
		"weaving":
			for index in range(9): entry.lines.append(_line(holder,"92714c" if index<4 else "c8af7c",.7 if index<4 else .3))
			entry.boxes=[_box(holder,Vector3(5,2,2),"a46c56")]
		"gardening":
			entry.lines=[_line(holder,"819c9b",1),_line(holder,"819c9b",.7),_line(holder,"819c9b",.7),_line(holder,"819c9b",.7)]
			entry.boxes=[_box(holder,Vector3(9,8,6),"7e9990")]
			for index in range(5): entry.boxes.append(_box(holder,Vector3(1,1,2),"9ec8c3"))
		"pump":
			entry.lines=[_line(holder,"999c94",1.2),_line(holder,"999c94",1.4)]
			entry.boxes=[_box(holder,Vector3(3,8,3),"81b9b3")]
		"trading":
			for color in ["8c9e6f","a68e5f","779285"]: entry.boxes.append(_box(holder,Vector3(4,4,4),color))
		"research":
			entry.boxes=[_box(holder,Vector3(8,1,8),"d3c6a4"),_box(holder,Vector3(8,1,8),"c6b999")]

func debug_status() -> Dictionary:
	var active: Array[String]=[]
	for entry in _actors.values():
		if entry.root.visible: active.append(str(entry.kind))
	var grips: Dictionary={}
	var measurements:Dictionary={}
	for entry in _actors.values():
		if entry.root.visible and entry.has("gripError"): grips[str(entry.actor.actor_name)]=entry.gripError
		if entry.has("gripMeasurement"): measurements[str(entry.actor.actor_name)]=entry.gripMeasurement
	return {"gripErrors":grips,"gripMeasurements":measurements,"active":active,"actors":_actors.size(),"cosmeticOnly":true,"clockPaused":EnvironmentState.clock_paused}

func _distance_to_segment(point: Vector3,a: Vector3,b: Vector3) -> float:
	var span:=b-a
	var t:=clampf((point-a).dot(span)/maxf(.0001,span.length_squared()),0,1)
	return point.distance_to(a+span*t)
