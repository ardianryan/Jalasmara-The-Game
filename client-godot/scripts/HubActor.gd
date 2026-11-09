extends Node2D

var actor_name := ""
var crate := false
var appearance_index := -1
var custom_tint := Color.WHITE
var custom_sheet: Texture2D
var custom_grid := Vector2i(2,2)
var route: Array = []
var walkable := Callable()
var route_index := 1
var rest_time := 2.0
var _elapsed := 0.0
var _frame := -1
var player: Node2D
var _attention := 0.0
var _facing := 1.0
var _anchor := Vector2.ZERO
var _anchored := false

func _process(delta: float) -> void:
	if not _anchored and position != Vector2.ZERO:
		_anchor = position
		_anchored = true
	visible = GameState.dive.is_empty() and not bool(get_meta("land_hidden",false))
	_elapsed += delta
	var check_pos := _anchor if _anchored else position
	var nearby := is_instance_valid(player) and player.position.distance_to(check_pos)<165
	_attention = move_toward(_attention,1.0 if nearby else 0.0,delta*2.4)
	if not route.is_empty() and not crate:
		if not nearby and not EnvironmentState.reduced_motion:
			rest_time = maxf(0,rest_time-delta)
			if rest_time<=0:
				var target: Vector2 = route[route_index]
				var candidate := position.move_toward(target,delta*22.0)
				if not walkable.is_valid() or walkable.call(candidate):
					if absf(candidate.x-position.x)>.01: _facing = signf(candidate.x-position.x)
					position = candidate
				else:
					route_index = (route_index+1)%route.size()
					rest_time = 3
				if position.distance_to(target)<2:
					route_index = (route_index+1)%route.size()
					rest_time = 4.0+float(appearance_index)
		_anchor = position
	elif _anchored and not crate:
		var motion := 0.0 if EnvironmentState.reduced_motion else (1.0-_attention)
		var offset := Vector2.ZERO
		if actor_name == "Bu Darmi":
			offset = Vector2(sin(_elapsed*0.65)*14.0,cos(_elapsed*0.65)*5.0)*motion
		elif actor_name == "Beno":
			offset = Vector2(sin(_elapsed*0.85+1.1)*12.0,0.0)*motion
		elif actor_name == "Mbah Wira":
			offset = Vector2(sin(_elapsed*0.55+2.0)*9.0,0.0)*motion
		elif actor_name == "Inspektur Raka":
			offset = Vector2(cos(_elapsed*0.48+0.7)*10.0,0.0)*motion
		var next_pos := _anchor + offset
		if motion > 0.15 and absf(next_pos.x - position.x) > 0.08:
			_facing = 1.0 if next_pos.x > position.x else -1.0
		position = next_pos
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
	if appearance_index>=0: index = appearance_index
	var phase := float(index)*1.9
	var motion := 0.0 if EnvironmentState.reduced_motion else 1.0
	var breath := roundf(sin(_elapsed*1.1+phase)*0.75)*motion
	var glance := roundf(sin(_elapsed*0.19+phase)*0.65+_attention*_facing*1.5)
	var sheet: Texture2D = preload("res://resources/art/npc-atlas.png")
	if custom_sheet!=null: sheet = custom_sheet
	var grid := custom_grid if custom_sheet!=null else Vector2i(2,2)
	var cell := Vector2(sheet.get_size())/Vector2(grid)
	draw_rect(Rect2(-16,12,32,5),Color(0.08,0.10,0.08,0.15))
	draw_rect(Rect2(-11,10,22,8),Color(0.08,0.10,0.08,0.12))
	var working := (1.0-_attention)*sin(_elapsed*(1.6 if index==1 else 0.9)+phase)*motion
	# Pivot at the feet keeps the character grounded while their upper body leans.
	draw_set_transform(Vector2(glance,12),working*0.014,Vector2.ONE)
	draw_texture_rect_region(sheet,Rect2(-50,-96+breath,100,100-breath),Rect2(Vector2(index%grid.x,floori(float(index)/grid.x))*cell,cell))
	draw_set_transform(Vector2.ZERO)
