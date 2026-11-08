extends RefCounted

static var _cache: Dictionary = {}

static func _sheet(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var path := "res://resources/art/procedural/" + id + ".json"
	if not FileAccess.file_exists(path):
		_cache[id] = {}
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or parsed.get("format", "") != "ppc.spritesheet":
		_cache[id] = {}
		return {}
	var textures: Array[Texture2D] = []
	for page in parsed.get("pages", []):
		var texture_path := path.get_base_dir().path_join(str(page.get("file", "")))
		if not ResourceLoader.exists(texture_path):
			_cache[id] = {}
			return {}
		textures.append(load(texture_path) as Texture2D)
	var clips: Dictionary = {}
	for clip in parsed.get("clips", []):
		clips[str(clip.get("state", "idle")) + ":" + str(int(clip.get("direction", 0)))] = clip
	var data := {
		"textures": textures, "clips": clips,
		"size": Vector2(float(parsed.get("frameWidth", 1)), float(parsed.get("frameHeight", 1))),
		"pivot": Vector2(float(parsed.get("originX", 0)), float(parsed.get("originY", 0))),
		"creature": parsed.get("creature", {}),
	}
	_cache[id] = data
	return data

static func frame_data(id: String, seconds: float, facing: float, state := "walk") -> Dictionary:
	var data := _sheet(id)
	if data.is_empty():
		return {}
	var direction := 4 if facing < 0 else 0
	var clips: Dictionary = data.clips
	var clip: Dictionary = clips.get(state + ":" + str(direction), clips.get("idle:" + str(direction), {}))
	if clip.is_empty():
		return {}
	var frames: Array = clip.get("frames", [])
	if frames.is_empty():
		return {}
	var fps := maxf(1, float(clip.get("fps", 12)))
	var index := posmod(int(floor(seconds * fps)), frames.size())
	var frame: Dictionary = frames[index]
	var page := int(frame.get("page", 0))
	if page < 0 or page >= data.textures.size():
		return {}
	return {
		"texture": data.textures[page],
		"source": Rect2(Vector2(float(frame.get("x", 0)), float(frame.get("y", 0))), data.size),
		"pivot": data.pivot, "size": data.size, "index": index,
		"direction": direction, "clip": str(clip.get("name", state)), "fps": fps, "frame_count": frames.size(),
	}

static func draw_creature(canvas: Node2D, id: String, point: Vector2, width: float, seconds: float, facing: float, tint := Color.WHITE, centered := true) -> bool:
	var frame := frame_data(id, seconds, facing)
	if frame.is_empty():
		return false
	var size: Vector2 = frame.size
	var pivot: Vector2 = frame.pivot
	var scale := width / maxf(1, size.x)
	var ground_point := point
	if centered:
		ground_point += (pivot - size / 2) * scale
	var rectangle := Rect2(ground_point - pivot * scale, size * scale)
	canvas.draw_texture_rect_region(frame.texture, rectangle, frame.source, tint)
	return true
