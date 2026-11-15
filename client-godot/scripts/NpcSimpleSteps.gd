extends RefCounted

const ROOT := "res://resources/art/npc-facing-v2/"
const FILES := {
	"Ki Lurah Wirabhumi": "ki_lurah_wirabhumi",
	"Mbok Ratih": "mbok_ratih",
	"Kang Tedi": "kang_tedi",
	"Saras": "saras",
	"Mbah Wira": "mbah_wira",
	"Beno": "beno",
	"Inspektur Raka": "inspektur_raka",
}
static var _frames: Dictionary = {}

static func view_for_motion(visual_motion: Vector2) -> String:
	if visual_motion.y < -absf(visual_motion.x) * 0.75:
		return "rear"
	if absf(visual_motion.x) > absf(visual_motion.y) * 0.75:
		return "side"
	return "front"

static func frame(name: String, body: Dictionary, visual_motion := Vector2.DOWN) -> Texture2D:
	if not FILES.has(name): return null
	var frame_index := 0
	if str(body.get("clip", "")) == "walk":
		frame_index = 1 + posmod(floori(float(body.get("distance", 0.0)) / 6.5), 4)
	var view := view_for_motion(visual_motion)
	var key := name + ":" + view + ":" + str(frame_index)
	if not _frames.has(key):
		var sheet: Texture2D = load(ROOT + str(FILES[name]) + "-" + view + ".png")
		if sheet == null: return null
		var cell := AtlasTexture.new()
		cell.atlas = sheet
		cell.region = Rect2(frame_index * 64, 0, 64, 64)
		cell.filter_clip = true
		_frames[key] = cell
	return _frames[key]
