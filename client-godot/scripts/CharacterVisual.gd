extends Sprite2D
const LAND_SIZE := 100.0
const SWIM_SIZE := 112.0
const FOOT_Y := 12.0
var appearance := ""
var atlas_ready := false
var modular_ready := false
var outfit := "daily"
var equipment: Dictionary = {}
var _in_water := false
var clothing_ready := false
var _base_texture: Texture2D
var _land_texture: Texture2D
func set_appearance(id: String) -> void:
	if appearance==id and texture:
		return
	appearance = id
	var stem := "res://resources/art/"+id.replace("_","-")
	modular_ready = ResourceLoader.exists(stem+"-base-v1.png")
	var path := stem+("-base-v1.png" if modular_ready else ".png")
	atlas_ready = ResourceLoader.exists(path)
	_base_texture = load(path) if atlas_ready else load("res://resources/art/nala-swim.png")
	clothing_ready = ResourceLoader.exists(stem+"-outfits-v1.png")
	_land_texture = load(stem+"-outfits-v1.png") if clothing_ready else null
	texture = _base_texture
	hframes = 3
	vframes = 3 if atlas_ready else 2
	animate(false,false,1,0)
func set_outfit(id: String) -> void:
	outfit = id if id in ["daily","explorer","diving"] else "daily"

func set_equipment(items: Dictionary) -> void:
	equipment = items.duplicate()

func get_equipment_state() -> Dictionary:
	var result := equipment_state(outfit,equipment,modular_ready,_in_water)
	result["clothingAtlas"] = clothing_ready and not _in_water
	if clothing_ready and not _in_water: result["vest"] = false
	return result

static func equipment_state(id: String,overrides: Dictionary,modular: bool,in_water := false) -> Dictionary:
	var result := {"outfit":id,"modular":modular,"tank":id=="diving","net":id=="diving","satchel":id=="explorer","vest":id=="explorer","bodySize":SWIM_SIZE if in_water else LAND_SIZE}
	for key in ["tank","net","satchel","vest"]:
		if overrides.has(key): result[key]=bool(overrides[key])
	return result

func animate(moving: bool, in_water: bool, facing: int, elapsed: float) -> void:
	_in_water = in_water
	texture = _land_texture if clothing_ready and not in_water else _base_texture
	if not texture:
		return
	flip_h = facing<0
	var cell := Vector2(texture.get_size())/Vector2(hframes,vframes)
	scale = Vector2(SWIM_SIZE/cell.x,SWIM_SIZE/cell.y) if in_water else Vector2(LAND_SIZE/cell.x,LAND_SIZE/cell.y)
	position.y = 0 if in_water else FOOT_Y-LAND_SIZE/2.0
	if atlas_ready:
		var pose := 1+int(elapsed*7)%2 if moving else 0
		frame = 3+int(elapsed*7)%6 if in_water else int({"daily":0,"explorer":1,"diving":2}.get(outfit,0))*3+pose if clothing_ready else pose
	else:
		frame = int(elapsed*7)%6 if moving else 2
		visible = in_water
