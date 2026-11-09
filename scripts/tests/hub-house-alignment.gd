extends SceneTree

func _initialize() -> void: call_deferred("run")

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
	var collision: Node2D=load("res://scripts/land/LandCollision.gd").new()
	stage.add_child(collision)
	collision.configure(renderer.map)
	var houses:=0
	var corners:=0
	for entry in renderer.map.obstacles:
		if str(entry.kind)!="house": continue
		var building: Node3D=renderer._geometry.get_node(str(entry.id))
		assert(absf(building.global_basis.x.dot(building.global_basis.y))<.00001,"Every hub house needs orthogonal actual native axes")
		assert(building.global_basis.x.dot(Vector3.RIGHT)>.99999)
		assert(building.global_basis.y.dot(Vector3.UP)>.99999)
		var center:=Vector2(float(entry.x)+float(entry.width)*.5,float(entry.y)+float(entry.height)*.5)
		var elevation: float=float(entry.elevation)*renderer.LEVEL_HEIGHT
		assert(building.global_position.distance_to(renderer.map_point(center,elevation))<.001)
		var width: float=float(entry.width)
		var depth: float=float(entry.height)/cos(renderer.TILT)
		var local_corners: Array[Vector3]=[Vector3(-width*.5,depth*.5,0),Vector3(width*.5,depth*.5,0),Vector3(width*.5,-depth*.5,0),Vector3(-width*.5,-depth*.5,0)]
		for index in range(4):
			var at:=Vector2(entry.footprint[index][0],entry.footprint[index][1])
			assert(building.to_global(local_corners[index]).distance_to(renderer.map_point(at,elevation))<.001,"Actual rendered frame must agree with authoritative footprint corners")
			assert(not collision.is_walkable(at),"The client's real collider must block each house corner")
			corners+=1
		houses+=1
	assert(houses==8 and corners==32)
	for shelter in renderer.map.shelters:
		if bool(shelter.get("existing",false)): continue
		var building: Node3D=renderer._geometry.get_node(str(shelter.buildingId))
		var roof: Array=renderer._shelter_architecture.roofs[shelter.id]
		assert((roof[1]-roof[0]).normalized().dot(building.global_basis.x)>.99999)
		var outward: Vector3=roof[3]-roof[0]
		outward.z=0
		assert(outward.normalized().dot(building.global_basis.y)<-.99999,"Physical awning must share the house frame, without independent skew")
	assert(renderer._shelter_architecture.support_count==10)
	assert(renderer.camera_azimuth==-45 and renderer.camera_elevation==35)
	print("HUB HOUSE ALIGNMENT PASS: 8 actual native frames,32 transformed footprint/collider corners,5 physical roof plans,10 supports; default left camera unchanged")
	stage.free()
	quit()
