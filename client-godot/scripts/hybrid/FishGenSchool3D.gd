extends Node3D

const Animator = preload("res://scripts/FishGenAnimator.gd")
var source: Node
var _session := ""
var _fish: Array[Dictionary] = []
var _elapsed := 0.0
var visible_count := 0

func configure(main: Node) -> void:
	source = main

func _process(delta: float) -> void:
	visible_count = 0
	if not is_instance_valid(source) or GameState.dive.is_empty():
		visible = false
		return
	var entities: Node = source.get("entities")
	var nala: Node2D = source.get("nala")
	if not is_instance_valid(entities) or not is_instance_valid(nala):
		return
	var wildlife: Node = entities.get("wildlife")
	if not is_instance_valid(wildlife) or not wildlife.has_method("_find_water"):
		return
	var session := str(GameState.dive.get("id", ""))
	if _session != session:
		_clear()
		_session = session
		if GameState.dive.get("mode", "") != "boss":
			_populate(wildlife)
	visible = true
	_elapsed += minf(delta, 0.05)
	var low := str(RenderQuality.get_profile().effective) == "low"
	for i in range(_fish.size()):
		var fish: Dictionary = _fish[i]
		var sprite: Sprite3D = fish.sprite
		sprite.visible = (i < 1 if low else i < 3) and Vector2(fish.position).distance_to(nala.position) < 900
		if not sprite.visible:
			continue
		var at: Vector2 = fish.position
		var home: Vector2 = fish.home
		var phase := float(i) * 1.7
		var target := home.x + sin(_elapsed * 0.22 + phase) * 70.0
		var desired := clampf((target - at.x) * 0.7, -24, 24)
		if absf(desired) > 2:
			fish.requested = 1 if desired > 0 else -1
		var pose: Dictionary = fish.animator.advance(delta, int(fish.requested))
		if pose.is_empty():
			continue
		var velocity := Vector2(cos(float(pose.yaw)) * absf(desired), sin(_elapsed * 0.5 + phase) * 2.0)
		var next := at + velocity * minf(delta, 0.05)
		if not wildlife._blocked(next, 12.0):
			fish.position = next
		else:
			fish.requested = -int(pose.facing)
		var texture: AtlasTexture = fish.frame
		texture.region = pose.source
		var point: Vector2 = fish.position
		sprite.position = Vector3(point.x, -point.y, -4)
		visible_count += 1

func _populate(wildlife: Node) -> void:
	var sheet := Animator.sheet()
	if sheet.is_empty():
		return
	var spawn: Dictionary = GameState.world.get("spawn", {"x": 1120, "y": 470})
	var center := Vector2(float(spawn.x), float(spawn.y)) + Vector2(180, 140)
	for i in range(3):
		var at: Vector2 = wildlife._find_water(center + Vector2(i * 44, i * 20), 12.0)
		if wildlife._blocked(at, 12.0):
			continue
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet.texture
		atlas.region = Rect2(Vector2.ZERO, sheet.size)
		atlas.filter_clip = true
		var sprite := Sprite3D.new()
		sprite.name = "FishGenClownfish" + str(i)
		sprite.texture = atlas
		sprite.pixel_size = 1
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.alpha_scissor_threshold = 0.5
		sprite.shaded = true
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sprite.scale = Vector3.ONE * 0.75
		sprite.modulate = Color(0.86, 0.96, 0.96, 0.94)
		add_child(sprite)
		var animator := Animator.new()
		animator.reset(1)
		_fish.append({"sprite": sprite, "frame": atlas, "animator": animator, "position": at, "home": at, "requested": 1})

func _clear() -> void:
	for fish in _fish:
		if is_instance_valid(fish.sprite):
			fish.sprite.queue_free()
	_fish.clear()
	_elapsed = 0.0
