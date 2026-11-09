extends Node2D

signal interaction_requested(id: String)
signal nearby_changed(info: Dictionary)

var player: CharacterBody2D
var avatar: CharacterBody2D:
	get: return player
var camera: Camera2D
var land_renderer: Node2D
var terrain: Node2D
var home: Dictionary = {}
var _nearby := ""
var _modal := false
var _interior: Dictionary = {}

func _ready() -> void:
	y_sort_enabled=true
	_setup_input()
	_interior=GameState.world.get("homestead",{}).get("interior",{})
	if _interior.is_empty():
		push_error("Homestead interior manifest unavailable")
		interaction_requested.emit("exit")
		return
	terrain=preload("res://scripts/land/LandCollision.gd").new()
	terrain.configure(_interior)
	add_child(terrain)
	player=preload("res://scripts/Player.gd").new()
	var saved:Dictionary=GameState.get("homestead") if "homestead" in GameState else {}
	var point:Dictionary=saved.get("position",_interior.get("entry",{"x":480,"y":580}))
	player.position=terrain.nearest_walkable(Vector2(float(point.get("x",480)),float(point.get("y",580))))
	player.land_mask=Callable(terrain,"is_walkable")
	add_child(player)
	player.surface_traversal.configure(_interior)
	player.outfit="daily"
	player.swim_sprite.set_appearance(str(GameState.player.get("appearance","male_default")))
	player.swim_sprite.set_outfit("daily")
	player.swim_sprite.animate(false,false,1,0)
	player.hybrid_visual=true
	camera=Camera2D.new()
	camera.position=Vector2(480,395)
	camera.zoom=Vector2(.80,.80)
	add_child(camera)
	land_renderer=preload("res://scripts/land/HomesteadRenderer.gd").new()
	add_child(land_renderer)
	land_renderer.setup(self,player,camera,"home",_interior)
	set_state(saved)

func _setup_input() -> void:
	var bindings={"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"up":[KEY_W,KEY_UP],"down":[KEY_S,KEY_DOWN],"interact":[KEY_E]}
	for action in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			for key in bindings[action]:
				var event:=InputEventKey.new()
				event.physical_keycode=key
				InputMap.action_add_event(action,event)

func set_state(state: Dictionary) -> void:
	home=state.duplicate(true)
	if is_instance_valid(land_renderer): land_renderer.set_state(home)

func set_modal(open: bool) -> void:
	_modal=open
	if is_instance_valid(player):
		player.frozen=open
		if open: player.touch=Vector2.ZERO

func get_nearby() -> String:
	return _nearby

func nearby_info() -> Dictionary:
	var labels={"bed":"Dipan rotan","archive":"Meja arsip","chest":"Peti penyimpanan","display":"Rak pameran","exit":"Keluar ke beranda"}
	return {"id":_nearby,"label":str(labels.get(_nearby,"")),"distance":player.position.distance_to(_object_point(_nearby)) if not _nearby.is_empty() else -1}

func _object_point(id: String) -> Vector2:
	var point:Dictionary=_interior.get(id,{})
	return Vector2(float(point.get("x",480)),float(point.get("y",580)))

func interact() -> void:
	if not _modal and not _nearby.is_empty(): interaction_requested.emit(_nearby)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		interact()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not is_instance_valid(player): return
	# Interior movement must not fill the outdoor network breadcrumb queue.
	player.land_path.reset(player.position)
	var nearest:=""
	var distance:=110.0
	for id in ["bed","archive","chest","display","exit"]:
		var candidate:=player.position.distance_to(_object_point(id))
		if candidate<distance:
			distance=candidate
			nearest=id
	if nearest!=_nearby:
		_nearby=nearest
		nearby_changed.emit(nearby_info())

func debug_snapshot() -> Dictionary:
	return {"area":"home","x":player.position.x if is_instance_valid(player) else 0,"y":player.position.y if is_instance_valid(player) else 0,"nearby":_nearby,"modal":_modal,"renderer":land_renderer.debug_status() if is_instance_valid(land_renderer) else {}}
