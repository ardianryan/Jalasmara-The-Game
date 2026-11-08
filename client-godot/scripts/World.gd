extends Node2D
const OceanScript = preload("res://scripts/OceanScenery.gd")
const HubScript = preload("res://scripts/land/LandCollision.gd")
var camera_point := Vector2(1000,220)
var gardens_restored := false
var solved: Array = []
var rocks: Array[Rect2] = []
var solid_polygons: Array[PackedVector2Array] = []
var underwater := false
var scenery: Node2D
var foreground_host: Node2D

func _ready() -> void:
	for rect in GameState.world.get("terrain",[]):
		rocks.append(Rect2(float(rect[0]),float(rect[1]),float(rect[2]),float(rect[3])))
	set_mode(not GameState.dive.is_empty())

func set_mode(diving: bool) -> void:
	underwater = diving
	if is_instance_valid(scenery):
		remove_child(scenery)
		scenery.queue_free()
	solid_polygons.clear()
	if diving:
		scenery = OceanScript.new()
		scenery.configure(GameState.world,rocks)
	else:
		scenery = HubScript.new()
		scenery.configure(GameState.world.get("landMaps",{}).get("hub",{}))
	add_child(scenery)
	if diving:
		solid_polygons.assign(scenery.solid_polygons)
	elif is_instance_valid(foreground_host):
		scenery.add_foreground_to(foreground_host)

func _process(_delta: float) -> void:
	if underwater != (not GameState.dive.is_empty()):
		set_mode(not GameState.dive.is_empty())
	if not is_instance_valid(scenery):
		return
	scenery.camera_point = camera_point
	if not underwater:
		scenery.gardens_restored = gardens_restored
		scenery.solved = solved

func is_walkable(point: Vector2) -> bool:
	return is_instance_valid(scenery) and scenery.has_method("is_walkable") and scenery.is_walkable(point)

func add_foreground_to(actors: Node2D) -> void:
	foreground_host = actors
	if is_instance_valid(scenery) and scenery.has_method("add_foreground_to"):
		scenery.add_foreground_to(actors)
