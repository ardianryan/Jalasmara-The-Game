extends "res://scripts/land/LandWorld3D.gd"

var pilot_pose:=Transform3D.IDENTITY
var pilot_active:=false

func camera_up() -> Vector3:
	return pilot_pose.basis.y if pilot_active else super.camera_up()

func camera_forward() -> Vector3:
	return -pilot_pose.basis.z if pilot_active else super.camera_forward()

func ground_projection(point: Vector3) -> Vector2:
	if not pilot_active: return super.ground_projection(point)
	# The static pilot contains one actor, with a known authored floor height.
	var height: float=ground_height(actor.position)
	var direction: Vector3=camera_forward()
	var floor_point:=point+direction*((height-point.z)/direction.z)
	return Vector2(floor_point.x,-(floor_point.y+height*tan(TILT))*cos(TILT))
