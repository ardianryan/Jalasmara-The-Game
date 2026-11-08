extends Node2D

var actor_name := ""
var crate := false
var _elapsed := 0.0
var _frame := -1
var player: Node2D
var _attention := 0.0
var _facing := 1.0

func _process(delta: float) -> void:
	visible = GameState.dive.is_empty() and not bool(get_meta("land_hidden",false))
	_elapsed += delta
	var nearby := is_instance_valid(player) and player.position.distance_to(position)<155
	_attention = move_toward(_attention,1.0 if nearby else 0.0,delta*2)
	if nearby and absf(player.position.x-position.x)>12:
		_facing = 1.0 if player.position.x>position.x else -1.0
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
	var motion := 0.0 if EnvironmentState.reduced_motion else 1.0
	var breath := roundf(sin(_elapsed*1.1+phase)*0.75)*motion
	var glance := roundf(sin(_elapsed*0.19+phase)*0.65+_attention*_facing*1.5)
	var sheet: Texture2D = preload("res://resources/art/npc-atlas.png")
	var cell := Vector2(sheet.get_size())/2.0
	draw_rect(Rect2(-16,12,32,5),Color(0.08,0.10,0.08,0.15))
	draw_rect(Rect2(-11,10,22,8),Color(0.08,0.10,0.08,0.12))
	var working := (1.0-_attention)*sin(_elapsed*(1.6 if index==1 else 0.9)+phase)*motion
	# Pivot at the feet keeps the character grounded while their upper body leans.
	draw_set_transform(Vector2(glance,12),working*0.014,Vector2.ONE)
	draw_texture_rect_region(sheet,Rect2(-50,-96+breath,100,100-breath),Rect2(Vector2(index%2,floori(float(index)/2.0))*cell,cell))
	draw_set_transform(Vector2.ZERO)
