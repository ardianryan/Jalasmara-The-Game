extends Node2D

var actor_name := ""
var crate := false
var _elapsed := 0.0
var _frame := -1

func _process(delta: float) -> void:
	visible = GameState.dive.is_empty()
	_elapsed += delta
	var frame := int(_elapsed*8)
	if frame != _frame:
		_frame = frame
		queue_redraw()

func _draw() -> void:
	if crate:
		draw_texture_rect(preload("res://scripts/ItemIcons.gd").texture("cache"),Rect2(-35,-44,70,70),false)
		return
	var index: int = {"Mbah Wira":0,"Beno":1,"Bu Darmi":2,"Inspektur Raka":3}.get(actor_name,0)
	var phase := float(index)*1.9
	var breath := roundf(sin(_elapsed*1.1+phase)*0.75)
	var glance := roundf(sin(_elapsed*0.19+phase)*0.65)
	var sheet: Texture2D = preload("res://resources/art/npc-atlas.png")
	var cell := Vector2(sheet.get_size())/2.0
	draw_rect(Rect2(-16,12,32,5),Color(0.08,0.10,0.08,0.15))
	draw_rect(Rect2(-11,10,22,8),Color(0.08,0.10,0.08,0.12))
	draw_texture_rect_region(sheet,Rect2(-50+glance,-84+breath,100,100-breath),Rect2(Vector2(index%2,floori(float(index)/2.0))*cell,cell))
