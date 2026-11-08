extends Sprite2D
const LAND_SIZE := 100.0
const SWIM_SIZE := 112.0
const FOOT_Y := 12.0
var appearance := ""
var atlas_ready := false
func set_appearance(id: String) -> void:
	if appearance==id and texture:
		return
	appearance = id
	var path := "res://resources/art/"+id.replace("_","-")+".png"
	atlas_ready = ResourceLoader.exists(path)
	texture = load(path) if atlas_ready else load("res://resources/art/nala-swim.png")
	hframes = 3
	vframes = 3 if atlas_ready else 2
	animate(false,false,1,0)
func animate(moving: bool, in_water: bool, facing: int, elapsed: float) -> void:
	if not texture:
		return
	flip_h = facing<0
	var cell := Vector2(texture.get_size())/Vector2(hframes,vframes)
	scale = Vector2(SWIM_SIZE/cell.x,SWIM_SIZE/cell.y) if in_water else Vector2(LAND_SIZE/cell.x,LAND_SIZE/cell.y)
	position.y = 0 if in_water else FOOT_Y-LAND_SIZE/2.0
	if atlas_ready:
		frame = 3+int(elapsed*7)%6 if in_water else 1+int(elapsed*7)%2 if moving else 0
	else:
		frame = int(elapsed*7)%6 if moving else 2
		visible = in_water
