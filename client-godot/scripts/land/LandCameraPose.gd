# Camera orbit and pixel snapping adapted from Noxe Pixel Engine, engine/pixel-engine.js.
# Copyright (c) 2026 Daniel Jankulovski. SPDX-License-Identifier: MIT.
# Upstream revision d619d856398b44ad084003fac0a9fbfc9c8393e7; see THIRD_PARTY_LICENSES.md.
extends RefCounted

static func pose(center: Vector3, azimuth_degrees: float, elevation_degrees: float, distance: float, view_height: float, pixel_height: int, snap := false) -> Transform3D:
	assert(is_finite(azimuth_degrees) and is_finite(elevation_degrees))
	assert(elevation_degrees>0 and elevation_degrees<90)
	assert(distance>0 and view_height>0 and pixel_height>0)
	var azimuth:=deg_to_rad(azimuth_degrees)
	var elevation:=deg_to_rad(elevation_degrees)
	# Jalasmara uses Z-up; Noxe uses Y-up.
	var outward:=Vector3(sin(azimuth)*cos(elevation),-cos(azimuth)*cos(elevation),sin(elevation))
	var forward: Vector3=-outward
	var right: Vector3=forward.cross(Vector3(0,0,1)).normalized()
	var up: Vector3=right.cross(forward).normalized()
	var origin:=center+outward*distance
	if snap:
		var units_per_pixel:=view_height/float(pixel_height)
		var projected_right:=origin.dot(right)
		var projected_up:=origin.dot(up)
		origin+=right*(round(projected_right/units_per_pixel)*units_per_pixel-projected_right)
		origin+=up*(round(projected_up/units_per_pixel)*units_per_pixel-projected_up)
	return Transform3D(Basis(right,up,outward),origin)

static func project(point: Vector3, camera_pose: Transform3D, view_height: float, pixels: Vector2i) -> Vector2:
	assert(view_height>0 and pixels.x>0 and pixels.y>0)
	var relative:=point-camera_pose.origin
	var scale:=float(pixels.y)/view_height
	return Vector2(pixels)*.5+Vector2(relative.dot(camera_pose.basis.x),-relative.dot(camera_pose.basis.y))*scale

static func ray_to_height(pixel: Vector2, camera_pose: Transform3D, view_height: float, pixels: Vector2i, height: float) -> Vector3:
	assert(view_height>0 and pixels.x>0 and pixels.y>0)
	var offset: Vector2=(pixel-Vector2(pixels)*.5)*view_height/float(pixels.y)
	var origin:=camera_pose.origin+camera_pose.basis.x*offset.x-camera_pose.basis.y*offset.y
	var direction: Vector3=-camera_pose.basis.z
	assert(absf(direction.z)>.00001)
	return origin+direction*((height-origin.z)/direction.z)
