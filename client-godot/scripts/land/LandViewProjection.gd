extends RefCounted

const CameraPose = preload("res://scripts/land/LandCameraPose.gd")
const EPSILON := 0.000001
var camera_pose := Transform3D.IDENTITY
var view_height := 720.0
var pixels := Vector2i(480,270)
var _cos_tilt := cos(deg_to_rad(55.0))
var _tan_tilt := tan(deg_to_rad(55.0))

func configure(pose: Transform3D,height: float,resolution: Vector2i,tilt_degrees := 55.0) -> void:
	assert(is_finite(height) and height>0 and resolution.x>0 and resolution.y>0)
	assert(pose.origin.is_finite() and pose.basis.x.is_finite() and pose.basis.y.is_finite() and pose.basis.z.is_finite())
	assert(is_finite(tilt_degrees) and absf(tilt_degrees)<89)
	assert(absf(pose.basis.determinant()-1.0)<.0001,"Camera basis must be orthonormal and preserve handedness")
	assert(pose.basis.is_equal_approx(pose.basis.orthonormalized()),"Camera basis must not contain parent scale or shear")
	assert(absf(pose.basis.x.dot(pose.basis.y))<.0001)
	assert(absf(pose.basis.x.length()-1.0)<.0001 and absf(pose.basis.y.length()-1.0)<.0001)
	assert(pose.basis.z.z>EPSILON,"Land picking requires a camera looking down onto Z-up ground")
	camera_pose=pose
	view_height=height
	pixels=resolution
	_cos_tilt=cos(deg_to_rad(tilt_degrees))
	_tan_tilt=tan(deg_to_rad(tilt_degrees))
	assert(absf(_determinant(_columns(Vector2.ZERO)))>EPSILON)

func camera_right() -> Vector3:
	return camera_pose.basis.x

func camera_up() -> Vector3:
	return camera_pose.basis.y

func camera_forward() -> Vector3:
	return -camera_pose.basis.z

func world_point(logical: Vector2,height := 0.0) -> Vector3:
	return Vector3(logical.x,-logical.y/_cos_tilt-height*_tan_tilt,height)

func logical_from_world(point: Vector3) -> Vector2:
	return Vector2(point.x,-(point.y+point.z*_tan_tilt)*_cos_tilt)

func screen_vector(world_delta: Vector3) -> Vector2:
	return Vector2(world_delta.dot(camera_right()),-world_delta.dot(camera_up()))

func logical_motion_to_view(logical_velocity: Vector2,height_velocity := 0.0) -> Vector2:
	return screen_vector(Vector3(logical_velocity.x,-logical_velocity.y/_cos_tilt-height_velocity*_tan_tilt,height_velocity))

func _columns(height_gradient: Vector2) -> Array[Vector2]:
	var elevation:=screen_vector(Vector3(0,-_tan_tilt,1))
	return [screen_vector(Vector3.RIGHT)+elevation*height_gradient.x,screen_vector(Vector3(0,-1.0/_cos_tilt,0))+elevation*height_gradient.y]

func _determinant(columns: Array[Vector2]) -> float:
	return columns[0].cross(columns[1])

func logical_vector_from_view(view_vector: Vector2,height_gradient := Vector2.ZERO) -> Vector2:
	var columns:=_columns(height_gradient)
	var determinant:=_determinant(columns)
	assert(absf(determinant)>EPSILON,"Projected local ground plane is edge-on; do not invent a movement inverse")
	return Vector2(view_vector.cross(columns[1]),columns[0].cross(view_vector))/determinant

func input_motion(screen_input: Vector2,height_gradient := Vector2.ZERO) -> Vector2:
	var bounded:=screen_input.limit_length()
	if bounded.is_zero_approx(): return Vector2.ZERO
	# Keep the existing logical speed/server distance budget; preserve the screen direction.
	return logical_vector_from_view(bounded,height_gradient).normalized()*bounded.length()

func pixels_to_logical_delta(pixel_delta: Vector2,height_gradient := Vector2.ZERO) -> Vector2:
	return logical_vector_from_view(pixel_delta*view_height/float(pixels.y),height_gradient)

func motion_contract(height_gradient := Vector2.ZERO) -> Dictionary:
	var columns:=_columns(height_gradient)
	return {"schemaVersion":1,"columns":[[columns[0].x,columns[0].y],[columns[1].x,columns[1].y]],"heightGradient":[height_gradient.x,height_gradient.y],"determinant":_determinant(columns),"pixelsPerViewUnit":float(pixels.y)/view_height}

func project_world(point: Vector3) -> Vector2:
	return CameraPose.project(point,camera_pose,view_height,pixels)

func project_logical(point: Vector2,height := 0.0) -> Vector2:
	return project_world(world_point(point,height))

func logical_on_height(point: Vector3,height: float) -> Vector2:
	var direction:=camera_forward()
	var on_floor:=point+direction*((height-point.z)/direction.z)
	return logical_from_world(on_floor)

func logical_from_screen(pixel: Vector2,height: float) -> Vector2:
	return logical_from_world(CameraPose.ray_to_height(pixel,camera_pose,view_height,pixels,height))

func foot_error_pixels(actual_sole: Vector3,logical_feet: Vector2,height: float) -> float:
	return project_world(actual_sole).distance_to(project_logical(logical_feet,height))

func render_to_host(pixel: Vector2,display_rect: Rect2) -> Vector2:
	assert(display_rect.size.x>0 and display_rect.size.y>0)
	return display_rect.position+pixel/Vector2(pixels)*display_rect.size

func host_to_render(point: Vector2,display_rect: Rect2) -> Vector2:
	assert(display_rect.size.x>0 and display_rect.size.y>0)
	return (point-display_rect.position)/display_rect.size*Vector2(pixels)

func project_to_host(logical: Vector2,height: float,display_rect: Rect2) -> Vector2:
	return render_to_host(project_logical(logical,height),display_rect)

func logical_from_host(point: Vector2,height: float,display_rect: Rect2) -> Vector2:
	return logical_from_screen(host_to_render(point,display_rect),height)
