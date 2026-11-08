extends Node2D
const CreatureAnimator = preload("res://scripts/CreatureAnimator.gd")

var player: Node2D
var elapsed := 0.0
var creatures: Array[Dictionary] = []
var session_id := ""
var rng := RandomNumberGenerator.new()
var environment_current := Vector2.ZERO

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	visible = not GameState.dive.is_empty()
	if not visible or not is_instance_valid(player):
		return
	var active_id := str(GameState.dive.get("id", ""))
	if active_id != session_id:
		session_id = active_id
		_populate()
	var environment := get_node_or_null("/root/EnvironmentState")
	if environment:
		var weather: Dictionary = environment.snapshot()
		environment_current = Vector2(float(weather.get("current_x", 0)), float(weather.get("current_y", 0))) * 0.35
	elapsed += delta
	var step := minf(delta, 0.05)
	for creature in creatures:
		_move_creature(creature, step)
	queue_redraw()

# Sizes and speeds are authored for the fictional coastal species, in world pixels.
const PROFILES := {
	1: {"speed": 64.0, "size": 29.0, "radius": 9.0, "span": 185.0, "fear": 190.0},
	2: {"speed": 53.0, "size": 33.0, "radius": 10.0, "span": 155.0, "fear": 210.0},
	5: {"speed": 42.0, "size": 93.0, "radius": 17.0, "span": 290.0, "fear": 110.0},
	6: {"speed": 24.0, "size": 47.0, "radius": 13.0, "span": 100.0, "fear": 145.0},
	7: {"speed": 78.0, "size": 118.0, "radius": 18.0, "span": 380.0, "fear": 95.0},
	8: {"speed": 37.0, "size": 73.0, "radius": 12.0, "span": 155.0, "fear": 145.0},
	9: {"speed": 27.0, "size": 62.0, "radius": 14.0, "span": 110.0, "fear": 150.0},
}
var contour_shapes: Array[Dictionary] = []
var geometry_ready := false

func _cache_geometry() -> void:
	contour_shapes.clear()
	for points in GameState.world.get("terrainContours", []):
		var polygon := PackedVector2Array()
		for point in points:
			polygon.append(Vector2(float(point[0]), float(point[1])))
		if polygon.size() >= 3:
			var bounds := Rect2(polygon[0], Vector2.ZERO)
			for point in polygon:
				bounds = bounds.expand(point)
			contour_shapes.append({"polygon": polygon, "bounds": bounds})
	geometry_ready = true

func _populate() -> void:
	creatures.clear()
	rng.seed = hash(session_id)
	_cache_geometry()
	var targets: Array = GameState.dive.get("targets", [])
	for school in range(mini(4, ceili(targets.size() / 6.0))):
		var anchor: Dictionary = targets[mini(school * 6, targets.size() - 1)]
		var origin := Vector2(float(anchor.x), float(anchor.y))
		if school == 0 and GameState.dive.get("mode", "") != "boss":
			var entry: Dictionary = GameState.world.get("spawn", {"x":1120,"y":470})
			origin = Vector2(float(entry.x), float(entry.y)) + Vector2(65, 50)
		var home := _find_water(origin + Vector2(110, 65), 14)
		for member in range(6):
			var species := 1 if member % 3 else 2
			_add_creature(species, home, school, Vector2((member % 3 - 1) * 44, (member / 3.0 - 0.8) * 25))
	if GameState.dive.get("mode", "") != "boss":
		var spawn_y := float(targets[0].y) if not targets.is_empty() else 650.0
		for species in [5, 6, 7, 8, 9]:
			var home := _find_water(Vector2(1450 + posmod(species - 5, 3) * 420, spawn_y + 160 + (80 if species > 7 else 0)), 20)
			if species == 7 and creatures.size() >= 18:
				home = _find_water(Vector2(creatures[12].home) + Vector2(-280,80),20)
			_add_creature(species, home, -species, Vector2.ZERO)

func _add_creature(species: int, home: Vector2, school: int, offset: Vector2) -> void:
	var profile: Dictionary = PROFILES[species]
	var phase := rng.randf_range(0, TAU)
	creatures.append({
		"position": _find_water(home + offset, float(profile.radius)), "home": home, "school": school,
		"velocity": Vector2(float(profile.speed) * 0.65, 0), "species": species,
		"size": float(profile.size), "phase": phase, "speed": float(profile.speed), "facing": 1.0,
		"state": "swim", "animation_state": "walk", "animation_time": phase,
		"cycle": 22.0 + posmod(school, 5) * 3.0, "turns": 0,
	})

func _find_water(point: Vector2, radius: float) -> Vector2:
	if not _blocked(point, radius):
		return point
	for ring in range(1, 17):
		for direction in range(12):
			var candidate := point + Vector2.from_angle(direction * TAU / 12.0) * ring * 30.0
			if not _blocked(candidate, radius):
				return candidate
	var spawn: Dictionary = GameState.world.get("spawn", {"x":1120,"y":470})
	return Vector2(float(spawn.x), float(spawn.y))

func current_at(point: Vector2, seconds: float) -> Vector2:
	var depth := clampf((point.y - 400.0) / 3000.0, 0, 1)
	return Vector2(lerpf(11.0, 4.0, depth) * sin(seconds * 0.085 + point.y * 0.0018), 2.2 * sin(seconds * 0.11 + point.x * 0.001)) + environment_current * lerpf(1.0, 0.45, depth)

func _move_creature(creature: Dictionary, delta: float) -> void:
	var at: Vector2 = creature.position
	var home: Vector2 = creature.home
	var species := int(creature.species)
	var profile: Dictionary = PROFILES[species]
	var school := int(creature.school)
	var phase := float(creature.phase)
	# A shared school route gives the group a destination without orbiting Nala.
	var route_time := elapsed * (0.10 if species == 7 else 0.15) + school * 1.7
	var goal := home + Vector2(sin(route_time) * float(profile.span), sin(route_time * 0.63) * 38)
	var cycle := fposmod(elapsed + phase * 2.0, float(creature.cycle))
	var state := "swim"
	if species != 7 and cycle < 3.0:
		state = "idle"
	elif species != 7 and cycle < 7.0:
		state = "feed"
		goal = _find_water(home + Vector2(45 * sin(phase), 80), float(profile.radius))
	var desired := (goal - at) * 0.7
	var center := Vector2.ZERO
	var alignment := Vector2.ZERO
	var separation := Vector2.ZERO
	var neighbors := 0
	var predator_away := Vector2.ZERO
	var prey_goal := Vector2.ZERO
	var prey_distance := 330.0
	for other in creatures:
		if is_same(other, creature):
			continue
		var offset: Vector2 = at - Vector2(other.position)
		var distance := offset.length()
		if int(other.school) == school and distance < 160:
			center += Vector2(other.position)
			alignment += Vector2(other.velocity)
			neighbors += 1
		if distance > 0.1 and distance < (40 if species < 3 else 65):
			separation += offset.normalized() * (1 - distance / (40 if species < 3 else 65)) * 95
		if species != 7 and int(other.species) == 7 and distance < 250:
			predator_away += offset.normalized() * (1 - distance / 250) * 210
		elif species == 7 and int(other.species) in [1, 2] and distance < prey_distance:
			prey_distance = distance
			prey_goal = Vector2(other.position)
	if neighbors > 0:
		desired += (center / neighbors - at) * 0.45 + alignment / neighbors * 0.38
	desired += separation
	if not prey_goal.is_zero_approx():
		# Visual pursuit only: wildlife cannot consume rewards or hurt the player.
		desired = desired.lerp((prey_goal - at).normalized() * 90, 0.55)
		state = "hunt"
	var away := at - player.position if is_instance_valid(player) else Vector2(10000, 0)
	var near := away.length()
	if near > 0.1 and near < float(profile.fear):
		desired += away.normalized() * (1 - near / float(profile.fear)) * 240
		state = "flee"
	if predator_away.length_squared() > 1:
		desired += predator_away
		state = "flee"
	var speed := float(profile.speed)
	if state == "idle": speed *= 0.13
	elif state == "feed": speed *= 0.32
	elif state == "flee": speed *= 1.65
	elif state == "hunt": speed *= 1.18
	var velocity: Vector2 = creature.velocity
	var target_velocity := desired.limit_length(speed) + current_at(at, elapsed)
	velocity = velocity.move_toward(target_velocity, delta * (145 if state == "flee" else 70))
	var radius := float(profile.radius)
	# Probe ahead, then steer into a clear heading rather than flipping every hit.
	if _blocked(at + velocity.normalized() * (radius + 48), radius):
		var clear_heading := Vector2.ZERO
		for angle in [0.55, -0.55, 1.1, -1.1, 1.7, -1.7, PI]:
			var heading := velocity.normalized().rotated(angle)
			if not _blocked(at + heading * (radius + 48), radius):
				clear_heading = heading
				break
		velocity = velocity.move_toward(clear_heading * maxf(speed * 0.7, 8), delta * 260)
	var next := at + velocity * delta
	if _blocked(next, radius):
		var along_x := at + Vector2(velocity.x * delta, 0)
		var along_y := at + Vector2(0, velocity.y * delta)
		if not _blocked(along_x, radius):
			next = along_x
			velocity.y = 0
		elif not _blocked(along_y, radius):
			next = along_y
			velocity.x = 0
		else:
			next = at
			velocity = Vector2.ZERO
	creature.position = next
	creature.velocity = velocity
	creature.state = state
	creature.animation_state = "idle" if state in ["idle", "feed"] else "walk"
	creature.animation_time = float(creature.animation_time) + delta * clampf(velocity.length() / float(profile.speed), 0.3, 1.6)
	if absf(velocity.x) > 6:
		var facing := 1.0 if velocity.x > 0 else -1.0
		if facing != float(creature.facing): creature.turns = int(creature.turns) + 1
		creature.facing = facing

func _blocked(point: Vector2, radius: float = 14.0) -> bool:
	if not geometry_ready:
		_cache_geometry()
	if point.x < 32 + radius or point.x > float(GameState.world.get("width", 6144)) - 32 - radius or point.y < float(GameState.world.get("surface", 400)) + 24 + radius or point.y > float(GameState.world.get("height", 3584)) - 80 - radius:
		return true
	if not contour_shapes.is_empty():
		for shape in contour_shapes:
			var bounds: Rect2 = shape.bounds
			if not bounds.grow(radius).has_point(point): continue
			var polygon: PackedVector2Array = shape.polygon
			if Geometry2D.is_point_in_polygon(point, polygon): return true
			for index in range(polygon.size()):
				if point.distance_to(Geometry2D.get_closest_point_to_segment(point, polygon[index], polygon[(index + 1) % polygon.size()])) <= radius:
					return true
	else:
		for terrain in GameState.world.get("terrain", []):
			if Rect2(float(terrain[0]), float(terrain[1]), float(terrain[2]), float(terrain[3])).grow(radius).has_point(point): return true
	return false

func debug_status() -> Dictionary:
	var states := {}
	var schools := {}
	for creature in creatures:
		states[creature.state] = int(states.get(creature.state, 0)) + 1
		if int(creature.school) >= 0: schools[creature.school] = true
	var positions: Array = []
	for creature in creatures:
		var point: Vector2 = creature.position
		positions.append([snappedf(point.x,0.1),snappedf(point.y,0.1)])
	return {"creatures": creatures.size(), "schools": schools.size(), "states": states, "contours": contour_shapes.size(), "generated": true,"positions":positions}

func _draw() -> void:
	if not is_instance_valid(player):
		return
	for creature in creatures:
		var at: Vector2 = creature.position
		if at.distance_to(player.position) > 900:
			continue
		draw_creature(self, null, at, int(creature.species), float(creature.size), float(creature.facing), float(creature.animation_time) * 7, Color(0.68, 0.86, 0.87, 0.76), str(creature.animation_state))

static func draw_creature(canvas: Node2D, _texture: Texture2D, at: Vector2, species: int, width: float, facing: float, phase: float, tint: Color = Color.WHITE, animation_state: String = "walk") -> void:
	var generated := _generated_species(species)
	var color := tint * Color(1, 0.91, 0.78) if species == 2 else tint
	if not generated.is_empty() and CreatureAnimator.draw_creature(canvas, generated, at, width, phase / 7.0, facing, color, true, animation_state):
		return
	canvas.draw_set_transform(at, sin(phase) * 0.025, Vector2(facing, 1))
	_draw_fallback(canvas, species, width, phase, tint)
	canvas.draw_set_transform(Vector2.ZERO)

static func _draw_fallback(canvas: Node2D, species: int, width: float, phase: float, tint: Color) -> void:
	var palette := [Color("9fd7c9"), Color("d5ac65"), Color("87bec5"), Color("ab8761"), Color("c4bb91"), Color("748d9f"), Color("8eaa79"), Color("91a9b2")]
	var color: Color = palette[posmod(species, palette.size())] * tint
	var half := width / 2
	if species == 0:
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-half * 0.65, 2), Vector2(-half * 0.5, -half * 0.5), Vector2(0, -half * 0.7), Vector2(half * 0.5, -half * 0.5), Vector2(half * 0.65, 2)]), color)
		for strand in range(4):
			var x := (strand - 1.5) * width * 0.12
			canvas.draw_polyline(PackedVector2Array([Vector2(x, 0), Vector2(x + sin(phase + strand) * 4, half * 0.5), Vector2(x + sin(phase + strand + 1) * 5, half)]), color, 2)
	elif species in [4, 6, 11]:
		canvas.draw_circle(Vector2.ZERO, half * 0.66, color)
		for spine in range(12):
			var ray := Vector2.from_angle(spine * TAU / 12)
			canvas.draw_line(ray * half * 0.55, ray * half * 0.8, color, 2)
		canvas.draw_circle(Vector2(half * 0.35, -half * 0.15), 2, Color("132d36") * tint)
	elif species == 3:
		canvas.draw_circle(Vector2.ZERO, half * 0.5, color)
		for side in [-1, 1]:
			for leg in range(3):
				canvas.draw_line(Vector2(side * half * 0.3, leg * 4), Vector2(side * half * 0.9, leg * 5 + sin(phase + leg) * 3), color, 2)
	else:
		var body := PackedVector2Array([Vector2(-half * 0.7, 0), Vector2(-half * 0.1, -half * 0.34), Vector2(half * 0.65, -half * 0.22), Vector2(half, 0), Vector2(half * 0.65, half * 0.26), Vector2(-half * 0.1, half * 0.34)])
		canvas.draw_colored_polygon(body, color)
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-half * 0.6, 0), Vector2(-half, -half * 0.35 + sin(phase) * half * 0.12), Vector2(-half, half * 0.35 + sin(phase) * half * 0.12)]), color)
		canvas.draw_circle(Vector2(half * 0.65, -half * 0.08), maxf(1, width * 0.025), Color("132d36") * tint)

static func _generated_species(species: int) -> String:
	match species:
		0: return "ubur_smaragd"
		1, 2: return "reef_seruni"
		3: return "kepiting_bandar"
		4, 6, 11: return "buntal_pasir"
		7, 10: return "hiu_segaran"
		5: return "pari_lamun"
		8: return "sidat_smara"
		9: return "sotong_karang"
	return ""
