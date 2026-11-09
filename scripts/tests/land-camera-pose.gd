extends SceneTree

const CameraPose = preload("res://scripts/land/LandCameraPose.gd")
var samples:=0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view:=SubViewport.new()
	root.add_child(view)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect=Camera3D.KEEP_HEIGHT
	camera.size=720.0
	camera.near=5
	camera.far=9000
	view.add_child(camera)
	camera.current=true
	var center:=Vector3(163,-870,96)
	var old_position:=center+Vector3(0,-sin(deg_to_rad(55.0))*3300.0,cos(deg_to_rad(55.0))*3300.0)
	var legacy:=CameraPose.pose(center,0,35,3300,720,270)
	assert(legacy.origin.distance_to(old_position)<.001,"Legacy camera position must stay unchanged")
	camera.position=old_position
	camera.look_at(center,Vector3(0,0,1))
	assert(camera.basis.is_equal_approx(legacy.basis),"Legacy look-at basis must stay unchanged")
	for dimensions in [Vector2i(480,270),Vector2i(238,421),Vector2i(960,540)]:
		view.size=dimensions
		for angles in [Vector2(0,35),Vector2(45,30),Vector2(45,35.26438968),Vector2(-45,35),Vector2(135,35)]:
			for snapping in [false,true]:
				var transform:=CameraPose.pose(center,angles.x,angles.y,3300,camera.size,dimensions.y,snapping)
				camera.transform=transform
				await process_frame
				assert(absf(transform.basis.determinant()-1.0)<.0001)
				assert(absf(transform.basis.x.dot(transform.basis.y))<.0001)
				if snapping:
					var step: float=camera.size/dimensions.y
					for axis in [transform.basis.x,transform.basis.y]:
						assert(absf(transform.origin.dot(axis)/step-round(transform.origin.dot(axis)/step))<.001)
				for height in [0.0,48.0,96.0,144.0]:
					for offset in [Vector2.ZERO,Vector2(120,60),Vector2(-140,-75),Vector2(200,-90)]:
						var point:=Vector3(center.x+offset.x,center.y+offset.y,height)
						var projected:=CameraPose.project(point,transform,camera.size,dimensions)
						assert(projected.distance_to(camera.unproject_position(point))<.002,"Projection must agree with actual Camera3D")
						var ray_origin:=camera.project_ray_origin(projected)
						var ray_direction:=camera.project_ray_normal(projected)
						var actual: Vector3=ray_origin+ray_direction*((height-ray_origin.z)/ray_direction.z)
						assert(actual.distance_to(point)<.01,"Actual Camera3D ray must return the same elevation")
						assert(CameraPose.ray_to_height(projected,transform,camera.size,dimensions,height).distance_to(actual)<.01)
						samples+=1
	view.size=Vector2i(480,270)
	camera.transform=CameraPose.pose(center,-45,35.26438968,3300,720,270)
	await process_frame
	var origin:=camera.unproject_position(center)
	var lengths: Array[float]=[]
	for axis in [Vector3.RIGHT,Vector3(0,1,0),Vector3(0,0,1)]:
		lengths.append(camera.unproject_position(center+axis*100).distance_to(origin))
	assert(lengths.max()-lengths.min()<.002,"True isometric pose must give equal projected world-axis lengths")
	print("LAND CAMERA POSE PASS: ",samples," actual Camera3D projection/ray samples, legacy parity, pixel snap, and equal-axis isometric pose")
	quit()
