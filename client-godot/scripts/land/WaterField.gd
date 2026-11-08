extends RefCounted

const MASK_SIZE := Vector2i(160, 112)
const MAX_SHORE_DISTANCE := 110.0

var extent := Vector2(2400.0, 1600.0)
var cell_size := Vector2(15.0, 14.285714)
var is_river := false
var area := "hub"
var wet_cells := 0
var shoreline_texture: ImageTexture
var emitters: Array[Dictionary] = []

var _distance := PackedFloat32Array()
var _normal_x := PackedFloat32Array()
var _normal_y := PackedFloat32Array()
var _flow_x := PackedFloat32Array()
var _flow_y := PackedFloat32Array()
var _land_polygons: Array[PackedVector2Array] = []
var _rock_rects: Array[Rect2] = []

func configure(map: Dictionary) -> void:
	area = str(map.get("id", "hub"))
	is_river = area == "forest"
	extent = Vector2(float(map.get("width", 2400.0)), float(map.get("height", 1600.0)))
	cell_size = extent / Vector2(MASK_SIZE)
	_extract_geometry(map)
	_build_distance_and_normals()
	_build_emitters(map)
	_build_texture()

func _extract_geometry(map: Dictionary) -> void:
	_land_polygons.clear()
	_rock_rects.clear()
	for surface in map.get("surfaces", []):
		if not bool(surface.get("walkable", true)):
			continue
		if str(surface.get("material", "")) in ["dock", "bridge", "wood"]:
			continue
		var points := PackedVector2Array()
		for point in surface.get("polygon", []):
			points.append(Vector2(float(point[0]), float(point[1])))
		if points.size() > 2:
			_land_polygons.append(points)
	var backing := PackedVector2Array()
	for point in map.get("landmass", []):
		backing.append(Vector2(float(point[0]), float(point[1])))
	if backing.size() > 2:
		_land_polygons.append(backing)
	elif is_river and _land_polygons.size() >= 2:
		_land_polygons.append(PackedVector2Array([
			Vector2(-420.0, -260.0),
			Vector2(1300.0, -260.0),
			Vector2(1320.0, 120.0),
			Vector2(1300.0, 800.0),
			Vector2(1315.0, 1480.0),
			Vector2(1240.0, 1820.0),
			Vector2(-420.0, 1820.0),
		]))
		_land_polygons.append(PackedVector2Array([
			Vector2(1585.0, 120.0),
			Vector2(1615.0, -260.0),
			Vector2(2820.0, -260.0),
			Vector2(2820.0, 1820.0),
			Vector2(1610.0, 1820.0),
			Vector2(1565.0, 1430.0),
			Vector2(1580.0, 800.0),
		]))
	for obs in map.get("obstacles", []):
		if str(obs.get("kind", "")) in ["rock", "cliff"]:
			_rock_rects.append(Rect2(float(obs.get("x", 0.0)), float(obs.get("y", 0.0)), float(obs.get("width", 32.0)), float(obs.get("height", 32.0))).grow(28.0))

func _is_dry_land(point: Vector2) -> bool:
	for polygon in _land_polygons:
		if Geometry2D.is_point_in_polygon(point, polygon):
			return true
	return false

func _build_distance_and_normals() -> void:
	var total := MASK_SIZE.x * MASK_SIZE.y
	_distance.resize(total)
	_normal_x.resize(total)
	_normal_y.resize(total)
	_flow_x.resize(total)
	_flow_y.resize(total)
	wet_cells = 0
	for y in range(MASK_SIZE.y):
		for x in range(MASK_SIZE.x):
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) * cell_size
			var on_land := _is_dry_land(p)
			var idx := y * MASK_SIZE.x + x
			_distance[idx] = 0.0 if on_land else 9999.0
			if not on_land:
				wet_cells += 1
	var dx := cell_size.x
	var dy := cell_size.y
	var dd := cell_size.length()
	for y in range(MASK_SIZE.y):
		for x in range(MASK_SIZE.x):
			var at := y * MASK_SIZE.x + x
			if x > 0:
				_distance[at] = minf(_distance[at], _distance[at - 1] + dx)
			if y > 0:
				_distance[at] = minf(_distance[at], _distance[at - MASK_SIZE.x] + dy)
			if x > 0 and y > 0:
				_distance[at] = minf(_distance[at], _distance[at - MASK_SIZE.x - 1] + dd)
			if x < MASK_SIZE.x - 1 and y > 0:
				_distance[at] = minf(_distance[at], _distance[at - MASK_SIZE.x + 1] + dd)
	for y in range(MASK_SIZE.y - 1, -1, -1):
		for x in range(MASK_SIZE.x - 1, -1, -1):
			var at := y * MASK_SIZE.x + x
			if x < MASK_SIZE.x - 1:
				_distance[at] = minf(_distance[at], _distance[at + 1] + dx)
			if y < MASK_SIZE.y - 1:
				_distance[at] = minf(_distance[at], _distance[at + MASK_SIZE.x] + dy)
			if x < MASK_SIZE.x - 1 and y < MASK_SIZE.y - 1:
				_distance[at] = minf(_distance[at], _distance[at + MASK_SIZE.x + 1] + dd)
			if x > 0 and y < MASK_SIZE.y - 1:
				_distance[at] = minf(_distance[at], _distance[at + MASK_SIZE.x - 1] + dd)

	var base_flow := Vector2(0.08, 0.996).normalized() if is_river else Vector2(0.32, -0.947).normalized()
	for y in range(MASK_SIZE.y):
		for x in range(MASK_SIZE.x):
			var at := y * MASK_SIZE.x + x
			var xl := maxi(0, x - 1)
			var xr := mini(MASK_SIZE.x - 1, x + 1)
			var yu := maxi(0, y - 1)
			var yd := mini(MASK_SIZE.y - 1, y + 1)
			var gx := (_distance[y * MASK_SIZE.x + xr] - _distance[y * MASK_SIZE.x + xl]) / maxf(1.0, float(xr - xl) * dx)
			var gy := (_distance[yd * MASK_SIZE.x + x] - _distance[yu * MASK_SIZE.x + x]) / maxf(1.0, float(yd - yu) * dy)
			var outward := Vector2(gx, gy)
			if outward.length_squared() > 0.0001:
				outward = outward.normalized()
			else:
				outward = Vector2(0.0, 1.0)
			_normal_x[at] = outward.x
			_normal_y[at] = outward.y
			var flow := base_flow
			if is_river:
				# River tangent bends smoothly along bank normals near riverbanks
				var tangent := Vector2(-outward.y, outward.x)
				if tangent.dot(base_flow) < 0.0:
					tangent = -tangent
				var bank_weight := 1.0 - clampf(_distance[at] / 95.0, 0.0, 1.0)
				flow = base_flow.lerp(tangent, bank_weight * 0.68).normalized()
			_flow_x[at] = flow.x
			_flow_y[at] = flow.y

func _build_emitters(map: Dictionary) -> void:
	emitters.clear()
	var seen_positions: Array[Vector2] = []
	var min_spacing := 92.0 if not is_river else 105.0

	# 1. Explicit dock support pile emitters (wet piles under/around dock_main)
	for surface in map.get("surfaces", []):
		if str(surface.get("material", "")) != "dock":
			continue
		var poly: Array = surface.get("polygon", [])
		if poly.size() < 4:
			continue
		var a := Vector2(float(poly[0][0]), float(poly[0][1]))
		var b := Vector2(float(poly[1][0]), float(poly[1][1]))
		var c := Vector2(float(poly[2][0]), float(poly[2][1]))
		var d := Vector2(float(poly[3][0]), float(poly[3][1]))
		var candidates := [
			d,
			d.lerp(c, 0.25),
			d.lerp(c, 0.50),
			d.lerp(c, 0.75),
			c,
			a.lerp(d, 0.55),
			b.lerp(c, 0.55),
		]
		var center := (a + b + c + d) * 0.25
		for idx in range(candidates.size()):
			var p: Vector2 = candidates[idx]
			if _is_dry_land(p):
				continue
			var outward := (p - Vector2(center.x, a.y)).normalized()
			if outward.length_squared() < 0.01:
				outward = Vector2(0.0, 1.0)
			emitters.append({
				"id": "%s_pile_%d" % [str(surface.get("id", "dock")), idx],
				"area": area,
				"position": p,
				"normal": -outward,
				"outward": outward,
				"kind": "pile",
				"radius": 24.0,
				"phase_offset": fposmod(p.x * 0.019 + p.y * 0.013, TAU),
			})
			seen_positions.append(p)

	# 2. Explicit bridge support pile emitters in river channel
	for bridge in map.get("bridges", []):
		var path: Array = bridge.get("path", [])
		if path.size() < 2:
			continue
		var a := Vector2(float(path[0][0]), float(path[0][1]))
		var b := Vector2(float(path[-1][0]), float(path[-1][1]))
		var axis := (b - a).normalized()
		var side := Vector2(-axis.y, axis.x)
		var width := float(bridge.get("width", 110.0))
		var pile_index := 0
		for fraction in [0.16, 0.48, 0.84]:
			for sign_value in [-1.0, 1.0]:
				var offset := side * (width * 0.5 - 7.0) * float(sign_value)
				var p := a.lerp(b, float(fraction)) + offset
				if _is_dry_land(p):
					continue
				emitters.append({
					"id": "%s_pile_%d" % [str(bridge.get("id", "bridge")), pile_index],
					"area": area,
					"position": p,
					"normal": Vector2(0.0, -1.0),
					"outward": Vector2(0.0, 1.0),
					"kind": "pile",
					"radius": 20.0,
					"phase_offset": fposmod(p.x * 0.023 + p.y * 0.017, TAU),
				})
				seen_positions.append(p)
				pile_index += 1
				# Deflect local water normal/flow around bridge piles
				var cell := Vector2i((p / cell_size).floor())
				for oy in range(-2, 3):
					for ox in range(-2, 3):
						var cx := clampi(cell.x + ox, 0, MASK_SIZE.x - 1)
						var cy := clampi(cell.y + oy, 0, MASK_SIZE.y - 1)
						var cpos := (Vector2(cx, cy) + Vector2(0.5, 0.5)) * cell_size
						var delta := cpos - p
						var dist := delta.length()
						if dist < 38.0 and dist > 0.1:
							var at := cy * MASK_SIZE.x + cx
							var push := delta / dist
							var blend := (1.0 - dist / 38.0) * 0.65
							var n := Vector2(_normal_x[at], _normal_y[at]).lerp(push, blend).normalized()
							_normal_x[at] = n.x
							_normal_y[at] = n.y

	# 3. Shoreline & riverbank emitters sampled along wet contour band
	var shore_index := 0
	for y in range(2, MASK_SIZE.y - 2):
		for x in range(2, MASK_SIZE.x - 2):
			var at := y * MASK_SIZE.x + x
			var d := _distance[at]
			if d < 9.0 or d > 24.0:
				continue
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) * cell_size
			var too_close := false
			for prev in seen_positions:
				if p.distance_to(prev) < min_spacing:
					too_close = true
					break
			if too_close:
				continue
			var outward := Vector2(_normal_x[at], _normal_y[at])
			if outward.length_squared() < 0.01:
				continue
			var kind := "bank" if is_river else "sand"
			for rock_rect in _rock_rects:
				if rock_rect.has_point(p):
					kind = "rock"
					break
			if not is_river and (p.x < 420.0 or p.x > 1950.0 or p.y < 420.0):
				kind = "rock"
			emitters.append({
				"id": "%s_shore_%d" % [area, shore_index],
				"area": area,
				"position": p,
				"normal": -outward,
				"outward": outward,
				"kind": kind,
				"radius": 34.0 if kind != "bank" else 26.0,
				"phase_offset": fposmod(p.x * 0.015 + p.y * 0.011, TAU),
			})
			seen_positions.append(p)
			shore_index += 1

func _build_texture() -> void:
	var raster := Image.create(MASK_SIZE.x, MASK_SIZE.y, false, Image.FORMAT_RGBA8)
	for y in range(MASK_SIZE.y):
		for x in range(MASK_SIZE.x):
			var at := y * MASK_SIZE.x + x
			var d := _distance[at]
			var nx := clampf(_normal_x[at] * 0.5 + 0.5, 0.0, 1.0)
			var ny := clampf(_normal_y[at] * 0.5 + 0.5, 0.0, 1.0)
			raster.set_pixel(
				x,
				y,
				Color(
					1.0 if d == 0.0 else 0.0,
					clampf(d / MAX_SHORE_DISTANCE, 0.0, 1.0),
					nx,
					ny
				)
			)
	shoreline_texture = ImageTexture.create_from_image(raster)

func sample_world(point: Vector2) -> Dictionary:
	var cell := (point / cell_size).floor()
	var x := clampi(int(cell.x), 0, MASK_SIZE.x - 1)
	var y := clampi(int(cell.y), 0, MASK_SIZE.y - 1)
	var at := y * MASK_SIZE.x + x
	var d := _distance[at]
	return {
		"on_land": d == 0.0,
		"distance": d,
		"outward_normal": Vector2(_normal_x[at], _normal_y[at]),
		"shore_normal": -Vector2(_normal_x[at], _normal_y[at]),
		"flow": Vector2(_flow_x[at], _flow_y[at]),
	}

func nearest_water_distance(point: Vector2) -> float:
	var best := 9999.0
	for emitter in emitters:
		var pos: Vector2 = emitter.position
		var dist := point.distance_to(pos)
		if dist < best:
			best = dist
	return best

func emitters_near(point: Vector2, radius: float, max_count := 8) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	var all_sorted: Array[Dictionary] = []
	var r2 := radius * radius
	for emitter in emitters:
		var pos: Vector2 = emitter.position
		var d2 := point.distance_squared_to(pos)
		var item := emitter.duplicate()
		item["distance_sq"] = d2
		if d2 <= r2:
			matches.append(item)
		all_sorted.append(item)
	if matches.is_empty():
		matches = all_sorted
	matches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.distance_sq) < float(b.distance_sq)
	)
	if matches.size() > max_count:
		matches.resize(max_count)
	return matches
