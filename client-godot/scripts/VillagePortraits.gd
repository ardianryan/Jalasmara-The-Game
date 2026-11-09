extends RefCounted

const METADATA := "res://resources/art/village-expansion-v1/residents.json"
const IMAGE := "res://resources/art/village-expansion-v1/residents.png"
static var _frames: Dictionary = {}

static func for_resident(id: String) -> Texture2D:
	if _frames.is_empty():
		if not FileAccess.file_exists(METADATA) or not ResourceLoader.exists(IMAGE): return null
		var metadata = JSON.parse_string(FileAccess.get_file_as_string(METADATA))
		if not metadata is Dictionary or metadata.get("people",[]).size()!=6: return null
		var texture: Texture2D=load(IMAGE)
		var candidates: Dictionary={}
		for person in metadata.people:
			var key:=str(person.get("id",""))
			var cell:Array=person.get("cell",[])
			if key.is_empty() or candidates.has(key) or cell.size()!=4: return null
			var rect:=Rect2(float(cell[0]),float(cell[1]),float(cell[2]),float(cell[3]))
			if rect.size!=Vector2(96,128) or not Rect2(Vector2.ZERO,texture.get_size()).encloses(rect): return null
			var frame:=AtlasTexture.new()
			frame.atlas=texture
			frame.region=rect
			frame.filter_clip=true
			candidates[key]=frame
		_frames=candidates
	return _frames.get(id,null)
