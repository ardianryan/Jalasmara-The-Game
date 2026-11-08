extends Node2D
var actor_name := ""
var crate := false
func _process(_delta: float) -> void:
	visible = GameState.dive.is_empty()
func _draw() -> void:
	if crate:
		draw_texture_rect(preload("res://scripts/ItemIcons.gd").texture("cache"),Rect2(-35,-44,70,70),false)
		return
	draw_set_transform(Vector2(0,16),0,Vector2(1,.35))
	draw_circle(Vector2.ZERO,14,Color(0.04,.13,.11,.3))
	draw_set_transform(Vector2.ZERO)
	var index: int = {"Mbah Wira":0,"Beno":1,"Bu Darmi":2,"Inspektur Raka":3}.get(actor_name,0)
	var sheet: Texture2D = preload("res://resources/art/npc-atlas.png")
	var cell := Vector2(sheet.get_size())/2.0
	draw_texture_rect_region(sheet,Rect2(-39,-57,78,78),Rect2(Vector2(int(index)%2,floori(float(index)/2.0))*cell,cell))
	draw_string(ThemeDB.fallback_font,Vector2(-40,-65),actor_name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f1e6c6"))
