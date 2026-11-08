extends Node2D
const CreatureAnimator = preload("res://scripts/CreatureAnimator.gd")

var player: Node2D
var elapsed := 0.0
var creatures: Array[Dictionary] = []
var session_id := ""
var rng := RandomNumberGenerator.new()

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
	elapsed += delta
	var step := minf(delta, 0.05)
	for creature in creatures:
		_move_creature(creature, step)
	queue_redraw()

func _populate() -> void:
	creatures.clear()
	rng.seed = hash(session_id)
	var targets: Array = GameState.dive.get("targets", [])
	for school in range(mini(4, ceili(targets.size() / 6.0))):
		var anchor: Dictionary = targets[mini(school * 6, targets.size() - 1)]
		var home := Vector2(float(anchor.x), float(anchor.y)) + Vector2(110, 85)
		for member in range(6):
			var spawn := home + Vector2(rng.randf_range(-85, 85), rng.randf_range(-32, 32))
			if _blocked(spawn):
				spawn = Vector2(float(anchor.x), float(anchor.y))
			creatures.append({
				"position": spawn, "home": home, "school": school,
				"velocity": Vector2(rng.randf_range(40, 65), 0),
				"species": 1 if member % 3 else 2,
				"size": rng.randf_range(22, 34), "phase": rng.randf_range(0, TAU),
				"speed": rng.randf_range(55, 82), "facing": 1.0,
			})
	if GameState.dive.get("mode", "") != "boss":
		var spawn_y := float(targets[0].y) if not targets.is_empty() else 650.0
		for species in [5, 6, 7, 8, 9]:
			var home := Vector2(1450 + posmod(species - 5, 3) * 420, spawn_y + 160 + (80 if species > 7 else 0))
			if _blocked(home):
				home.y -= 180
			creatures.append({
				"position": home, "home": home, "school": -species,
				"velocity": Vector2(45, 0), "species": species,
				"size": 112.0 if species == 7 else 46.0 if species == 6 else 88.0 if species == 5 else 66.0,
				"phase": float(species), "speed": 48.0, "facing": 1.0,
			})

func _move_creature(creature: Dictionary, delta: float) -> void:
	var at: Vector2 = creature.position
	var home: Vector2 = creature.home
	var school := int(creature.school)
	var phase := float(creature.phase)
	var goal := home + Vector2(cos(elapsed * 0.24 + school) * 175, sin(elapsed * 0.31 + phase) * 65)
	var force := (goal - at) * 0.55
	var alignment := Vector2.ZERO
	var neighbors := 0
	for other in creatures:
		if other == creature or int(other.school) != school:
			continue
		var offset: Vector2 = at - Vector2(other.position)
		var distance := offset.length()
		if distance < 110:
			alignment += Vector2(other.velocity)
			neighbors += 1
			if distance > 0.1 and distance < 34:
				force += offset.normalized() * (34 - distance) * 2.6
	if neighbors > 0:
		force += alignment / neighbors * 0.4
	var away := at - player.position
	var near := away.length()
	if near > 0.1 and near < 170 and int(creature.species) < 5:
		force += away.normalized() * (1 - near / 170) * 190
	var velocity: Vector2 = creature.velocity
	if force.length_squared() > 1:
		velocity = velocity.lerp(force.normalized() * float(creature.speed), minf(1, delta * 2.4))
	var next := at + velocity * delta
	if _blocked(next):
		velocity = Vector2(-velocity.x, -velocity.y)
		next = at + velocity * delta
		if _blocked(next):
			next = at
	creature.position = next
	creature.velocity = velocity
	if absf(velocity.x) > 8:
		creature.facing = 1.0 if velocity.x > 0 else -1.0

func _blocked(point: Vector2) -> bool:
	if point.x < 50 or point.x > 6094 or point.y < 430 or point.y > 3480:
		return true
	for terrain in GameState.world.get("terrain", []):
		var obstacle := Rect2(float(terrain[0]), float(terrain[1]), float(terrain[2]), float(terrain[3])).grow(14)
		if obstacle.has_point(point):
			return true
	return false

func _draw() -> void:
	if not is_instance_valid(player):
		return
	for creature in creatures:
		var at: Vector2 = creature.position
		if at.distance_to(player.position) > 900:
			continue
		draw_creature(self, null, at, int(creature.species), float(creature.size), float(creature.facing), elapsed * 7 + float(creature.phase), Color(0.68, 0.86, 0.87, 0.76))

static func draw_creature(canvas: Node2D, _texture: Texture2D, at: Vector2, species: int, width: float, facing: float, phase: float, tint: Color = Color.WHITE) -> void:
	var generated := _generated_species(species)
	var color := tint * Color(1, 0.91, 0.78) if species == 2 else tint
	if not generated.is_empty() and CreatureAnimator.draw_creature(canvas, generated, at, width, phase / 7.0, facing, color):
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
