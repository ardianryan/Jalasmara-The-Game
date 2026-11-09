extends SceneTree

const Pose = preload("res://scripts/land/LandCameraPose.gd")
const Projection = preload("res://scripts/land/LandViewProjection.gd")
var projection_samples:=0
var motion_samples:=0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var viewport:=SubViewport.new()
	root.add_child(viewport)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect=Camera3D.KEEP_HEIGHT
	camera.size=720
	camera.near=5
	camera.far=9000
	viewport.add_child(camera)
	camera.current=true
	var reference: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	var adapter:=Projection.new()
	for dimensions in [Vector2i(480,270),Vector2i(238,421),Vector2i(960,540)]:
		viewport.size=dimensions
		for angles in [Vector2(0,35),Vector2(-45,30),Vector2(-45,35.26438968),Vector2(45,35)]:
			for snap in [false,true]:
				camera.transform=Pose.pose(Vector3(160,-930,96),angles.x,angles.y,3300,camera.size,dimensions.y,snap)
				adapter.configure(camera.transform,camera.size,dimensions)
				await process_frame
				assert(adapter.camera_right().is_equal_approx(camera.global_basis.x))
				assert(adapter.camera_up().is_equal_approx(camera.global_basis.y))
				assert(adapter.camera_forward().is_equal_approx(-camera.global_basis.z))
				for height in [0.0,24.0,48.0,72.0,96.0,144.0]:
					for logical in [Vector2(160,615),Vector2(1120,1230),Vector2(1370,775),Vector2(350,1250)]:
						var world:=adapter.world_point(logical,height)
						assert(world.distance_to(reference.map_point(logical,height))<.001,"Adapter must preserve the actual map embedding and server coordinates")
						assert(adapter.logical_from_world(world).distance_to(logical)<.001)
						var pixel: Vector2=camera.unproject_position(world)
						assert(adapter.project_logical(logical,height).distance_to(pixel)<.003)
						assert(adapter.logical_from_screen(pixel,height).distance_to(logical)<.01)
						var sole:=world-adapter.camera_forward()*8
						assert(adapter.foot_error_pixels(sole,logical,height)<.003,"Cosmetic depth offset along the camera ray must not become foot drift")
						assert(adapter.logical_on_height(sole,height).distance_to(logical)<.01)
						for host in [Rect2(0,0,1440,810),Rect2(18,44,667,375),Rect2(10,390,370,820)]:
							var display_point:=adapter.project_to_host(logical,height,host)
							assert(adapter.logical_from_host(display_point,height,host).distance_to(logical)<.02)
						projection_samples+=1
				for gradient in [Vector2.ZERO,Vector2(0,.6),Vector2(.13,-.2)]:
					for direction in range(8):
						for strength in [0.0,.25,1.0,2.0]:
							var screen:=Vector2.RIGHT.rotated(direction*PI*.25)*strength
							var logical:=adapter.input_motion(screen,gradient)
							assert(absf(logical.length()-minf(1,strength))<.0001,"Do not change logical walking speed or the server distance budget")
							var view:=adapter.logical_motion_to_view(logical,gradient.dot(logical))
							if strength>0:
								assert(view.normalized().dot(screen.normalized())>.99999,"Keyboard and joystick direction must agree with visible motion")
							else: assert(view.is_zero_approx())
							var delta:=Vector2(7,-11)
							var movement:=adapter.pixels_to_logical_delta(delta,gradient)
							var start:=Vector2(160,615)
							var actual:=camera.unproject_position(adapter.world_point(start+movement,96+gradient.dot(movement)))-camera.unproject_position(adapter.world_point(start,96))
							assert(actual.distance_to(delta)<.005,"Inverse 2x2 must agree with actual Camera3D including connector slope")
							if angles==Vector2(0,35): assert(logical.distance_to(screen.limit_length())<.0001,"Legacy input must remain identical")
							motion_samples+=1
	viewport.free()
	reference.free()
	print("LAND VIEW PROJECTION PASS: ",projection_samples," actual Camera3D embedding/ray/foot/host samples; ",motion_samples," keyboard/joystick and connector-gradient motion samples; legacy parity; no default camera change")
	quit()
