extends RefCounted

const METADATA := "res://resources/art/fishgen/clownfish_48x32_1519.json"
static var _sheet: Dictionary = {}
var _clip := "swim_right"
var _seconds := 0.0
var _facing := 1
var _requested := 1

static func sheet() -> Dictionary:
	if not _sheet.is_empty():
		return _sheet
	if not FileAccess.file_exists(METADATA):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(METADATA))
	if not parsed is Dictionary:
		return {}
	var meta: Dictionary = parsed.get("meta", {})
	if meta.get("generator", "") != "fishgen" or meta.get("image", "") != "clownfish_48x32_1519.png":
		return {}
	var texture_path := METADATA.get_base_dir().path_join(str(meta.image))
	if not ResourceLoader.exists(texture_path):
		return {}
	var texture: Texture2D = load(texture_path)
	var clips: Dictionary = parsed.get("animations", {})
	for name in ["swim_right", "turn_right_to_left", "swim_left", "turn_left_to_right"]:
		var clip: Dictionary = clips.get(name, {})
		var frames: Array = clip.get("frames", [])
		if frames.is_empty() or not clips.has(str(clip.get("next", ""))):
			return {}
		for frame in frames:
			var rectangle := Rect2(float(frame.x), float(frame.y), float(frame.w), float(frame.h))
			if rectangle.position.x < 0 or rectangle.position.y < 0 or rectangle.end.x > texture.get_width() or rectangle.end.y > texture.get_height() or float(frame.get("duration_ms", 0)) <= 0:
				return {}
	_sheet = {"texture": texture, "clips": clips, "size": Vector2(float(meta.frame_size[0]), float(meta.frame_size[1]))}
	return _sheet

func reset(facing := 1) -> void:
	_facing = 1 if facing >= 0 else -1
	_requested = _facing
	_clip = "swim_right" if _facing > 0 else "swim_left"
	_seconds = 0.0

func advance(delta: float, facing: int, paused := false) -> Dictionary:
	var data := sheet()
	if data.is_empty():
		return {}
	_requested = 1 if facing >= 0 else -1
	if not paused:
		_seconds += clampf(delta, 0.0, 0.25)
		for _guard in range(4):
			var clip: Dictionary = data.clips[_clip]
			var duration := 0.0
			for frame in clip.frames:
				duration += float(frame.duration_ms) / 1000.0
			if _seconds < duration:
				break
			_seconds -= duration
			if bool(clip.loop):
				if _requested != _facing:
					_clip = "turn_right_to_left" if _facing > 0 else "turn_left_to_right"
			else:
				_clip = str(clip.next)
				_facing = 1 if _clip == "swim_right" else -1
	var frames: Array = data.clips[_clip].frames
	var remaining := _seconds
	var index := frames.size() - 1
	for i in range(frames.size()):
		var duration := float(frames[i].duration_ms) / 1000.0
		if remaining < duration:
			index = i
			break
		remaining -= duration
	var frame: Dictionary = frames[index]
	return {"texture": data.texture, "source": Rect2(float(frame.x), float(frame.y), float(frame.w), float(frame.h)), "size": data.size, "clip": _clip, "index": index, "yaw": float(frame.yaw), "facing": _facing}
