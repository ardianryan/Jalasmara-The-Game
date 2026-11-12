extends RefCounted

const ROOT := "res://resources/art/npc-simple-steps-v1/"
const FILES := {
	"Ki Lurah Wirabhumi": "ki_lurah_wirabhumi.png",
	"Mbok Ratih": "mbok_ratih.png",
	"Kang Tedi": "kang_tedi.png",
	"Saras": "saras.png",
	"Mbah Wira": "mbah_wira.png",
	"Beno": "beno.png",
	"Inspektur Raka": "inspektur_raka.png",
}
static var _frames: Dictionary = {}

static func frame(name: String, body: Dictionary) -> Texture2D:
	if not FILES.has(name): return null
	var frame_index := 0
	if str(body.get("clip", "")) == "walk":
		frame_index = 1 + posmod(floori(float(body.get("distance", 0.0)) / 6.5), 4)
	var key := name + ":" + str(frame_index)
	if not _frames.has(key):
		var sheet: Texture2D = load(ROOT + str(FILES[name]))
		if sheet == null: return null
		var cell := AtlasTexture.new()
		cell.atlas = sheet
		cell.region = Rect2(frame_index * 64, 0, 64, 64)
		cell.filter_clip = true
		_frames[key] = cell
	return _frames[key]
