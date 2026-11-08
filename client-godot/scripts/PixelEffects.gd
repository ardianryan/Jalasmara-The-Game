extends Node2D

const ROOT := "res://resources/art/pixelbolt/"
var _ambient: Array[Dictionary] = []
var _clock := 0.0

func add_effect(kind: String, at: Vector2, size: float = 1.0, phase: int = 0, one_shot: bool = false) -> AnimatedSprite2D:
	if not kind in ["lantern-flame","bubble-splash","pot-steam","memory-spark"]:
		return null
	var path := ROOT+kind+".tres"
	if not ResourceLoader.exists(path):
		return null
	var effect := AnimatedSprite2D.new()
	effect.sprite_frames = load(path) as SpriteFrames
	effect.position = at
	effect.scale = Vector2.ONE*size
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# These are emitted light/steam pixels; existing PointLight2D still lights the world.
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	effect.material = material
	add_child(effect)
	if one_shot:
		effect.sprite_frames = effect.sprite_frames.duplicate() as SpriteFrames
		effect.sprite_frames.set_animation_loop("idle",false)
		effect.animation_finished.connect(effect.queue_free)
	else:
		_ambient.append({"node":effect,"kind":kind,"phase":float(phase),"base":at})
	effect.play("idle")
	effect.frame = posmod(phase,effect.sprite_frames.get_frame_count("idle"))
	return effect

func configure(area: String) -> void:
	if area == "hub":
		for district in GameState.world.get("surface_hub",{}).get("districts",[]):
			var at := Vector2(float(district.x),float(district.y))
			add_effect("lantern-flame",at+Vector2(-28,-80),0.7,int(at.x)%4)
			if str(district.id) == "dist_kedai":
				add_effect("pot-steam",at+Vector2(32,-45),0.9,1)
	elif area == "forest":
		add_effect("lantern-flame",Vector2(430,418),0.65,1)
		add_effect("pot-steam",Vector2(390,407),0.85,3)

func _process(delta: float) -> void:
	_clock += delta
	var state := get_node_or_null("/root/EnvironmentState")
	var environment: Dictionary = state.snapshot() if state != null else {"daylight":0.9}
	var daylight := float(environment.get("daylight",0.9))
	var wind := float(environment.get("wind_x",9.0))
	var rain := float(environment.get("rain",0.0))
	var reduced := bool(environment.get("reduced_motion",false))
	for entry in _ambient:
		var effect: AnimatedSprite2D = entry.node
		if not is_instance_valid(effect):
			continue
		if str(entry.kind) == "lantern-flame":
			effect.modulate.a = lerpf(0.88,0.42,daylight)
			effect.rotation = 0.0 if reduced else sin(_clock*2.1+float(entry.phase))*minf(0.08,wind*0.002)
			effect.speed_scale = 0.6 if reduced else 1.0+wind*0.006
		elif str(entry.kind) == "pot-steam":
			effect.modulate.a = 0.48+rain*0.14
			effect.position = entry.base if reduced else Vector2(entry.base)+Vector2(sin(_clock*0.8+float(entry.phase))*wind*0.07,0)
			effect.speed_scale = 0.5 if reduced else 1.0
		else:
			effect.modulate.a = 0.45+sin(_clock*1.5+float(entry.phase))*0.15
