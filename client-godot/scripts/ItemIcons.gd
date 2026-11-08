extends RefCounted
const SHEET = preload("res://resources/art/item-atlas.png")
const INDEX = {"klorofil":0,"ekosistem":1,"rasio":2,"netralisasi":3,"cache":4,"prasasti_smara_kuno":5,"oxygen":6,"net":7}
static func texture(id: String) -> Texture2D:
	var index := int(INDEX.get(id,5))
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	var cell := Vector2(SHEET.get_size())/Vector2(4,2)
	atlas.region = Rect2(Vector2(index%4,floori(index/4.0))*cell,cell)
	return atlas
