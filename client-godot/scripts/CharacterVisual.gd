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
var _gait_texture: Texture2D
var _locomotion_driven := false
var _travel := 0.0
var _speed := 0.0
var _requested_direction := "east"
var _last_horizontal := 1
var _foot_contacts: Array[Dictionary] = []
var _alpha_bottom: Dictionary = {}
const STRIDE := 56.0
var directional_pilot_enabled := true
var _directional_walk: Texture2D
var _directional_idle: Texture2D
const DIRECTIONS := ["east","south_east","south","south_west","west","north_west","north","north_east"]
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
	var gait_path:="res://resources/art/player-gait/"+id.replace("_","-")+".png"
	_gait_texture=load(gait_path) if ResourceLoader.exists(gait_path) else null
	_load_directional()
	texture = _base_texture
	hframes = 3
	vframes = 3 if atlas_ready else 2
	animate(false,false,1,0)
func set_outfit(id: String) -> void:
	var chosen := id if id in ["daily","explorer","diving"] else "daily"
	if outfit==chosen: return
	outfit=chosen
	_load_directional()

func _load_directional() -> void:
	var stem := "res://resources/art/player-gait/"+appearance.replace("_","-")+"-"+outfit+"-"
	_directional_walk=load(stem+"walk-8way-v1.png") if ResourceLoader.exists(stem+"walk-8way-v1.png") else null
	_directional_idle=load(stem+"idle-8way-v1.png") if ResourceLoader.exists(stem+"idle-8way-v1.png") else null

func set_equipment(items: Dictionary) -> void:
	equipment = items.duplicate()

func get_equipment_state() -> Dictionary:
	var result := equipment_state(outfit,equipment,modular_ready,_in_water)
	result["clothingAtlas"] = clothing_ready and not _in_water
	if clothing_ready and not _in_water: result["vest"] = false
	result["facingDirection"]=_requested_direction if _locomotion_driven else "west" if flip_h else "east"
	result["gaitPhase"]=fposmod(_travel/_stride(),1.0) if _speed>.1 else 0.0
	result["moving"]=_speed>.1
	return result

static func equipment_state(id: String,overrides: Dictionary,modular: bool,in_water := false) -> Dictionary:
	var result := {"outfit":id,"modular":modular,"tank":id=="diving","net":id=="diving","satchel":id=="explorer","vest":id=="explorer","bodySize":SWIM_SIZE if in_water else LAND_SIZE}
	for key in ["tank","net","satchel","vest"]:
		if overrides.has(key): result[key]=bool(overrides[key])
	return result

func directional_pilot_active() -> bool:
	return _locomotion_driven and directional_pilot_enabled and _directional_walk!=null and _directional_idle!=null

func get_land_pivot() -> Vector2:
	return Vector2(64,104) if directional_pilot_active() and not _in_water else Vector2.ZERO

func _stride() -> float:
	return 64.0 if directional_pilot_active() else STRIDE

func set_locomotion(velocity: Vector2,delta: float,visual_velocity := Vector2.INF) -> void:
	_locomotion_driven=true
	_speed=velocity.length()
	if delta<=0 or _speed<.1 or _in_water: return
	var stride:=_stride()
	var before:=floori(_travel/(stride*.5))
	_travel+=_speed*delta
	var after:=floori(_travel/(stride*.5))
	for contact in range(before+1,mini(after,before+4)+1):
		_foot_contacts.append({"side":"left" if contact%2==0 else "right","distance":contact*stride*.5,"phase":0.0 if contact%2==0 else .5})
		if _foot_contacts.size()>8: _foot_contacts.pop_front()
	var facing_velocity:=velocity if not visual_velocity.is_finite() else visual_velocity
	if facing_velocity.is_zero_approx(): return
	if absf(facing_velocity.x)>.1: _last_horizontal=1 if facing_velocity.x>0 else -1
	var octant:=posmod(roundi(facing_velocity.angle()/(PI*.25)),8)
	var previous:=DIRECTIONS.find(_requested_direction)
	var difference:=absf(angle_difference(previous*PI*.25,facing_velocity.angle()))
	if difference>PI*.125+deg_to_rad(5): _requested_direction=DIRECTIONS[octant]

func consume_foot_contacts() -> Array[Dictionary]:
	var result:=_foot_contacts.duplicate()
	_foot_contacts.clear()
	return result

func locomotion_state() -> Dictionary:
	var phase:=fposmod(_travel/_stride(),1.0)
	var pilot:=directional_pilot_active()
	return {"driven":_locomotion_driven,"distance":_travel,"speed":_speed,"phase":phase,"frame":floori(phase*8)%8,"requestedDirection":_requested_direction,"artworkDirection":_requested_direction if pilot else "east" if _last_horizontal>0 else "west","supportedDirections":DIRECTIONS if pilot else ["east","west"],"directionalFallback":not pilot and _requested_direction not in ["east","west"],"directionalPilot":pilot,"phaseName":["contact","down","passing","up"][floori(phase*8)%4],"stride":_stride(),"rootMotion":false,"pendingContacts":_foot_contacts.size()}

func animate(moving: bool, in_water: bool, facing: int, elapsed: float) -> void:
	_in_water = in_water
	if in_water: _foot_contacts.clear()
	if not in_water and directional_pilot_active():
		var walking:=_locomotion_driven and _speed>.1
		texture=_directional_walk if walking else _directional_idle
		hframes=8
		vframes=8 if walking else 1
		var direction:=DIRECTIONS.find(_requested_direction)
		frame=direction*8+floori(fposmod(_travel/_stride(),1.0)*8)%8 if walking else direction
		flip_h=false
		scale=Vector2.ONE
		position.y=-40
		return
	var gait:=_locomotion_driven and _speed>.1 and not in_water and _gait_texture!=null
	texture = _gait_texture if gait else _land_texture if clothing_ready and not in_water else _base_texture
	if not texture: return
	hframes=8 if gait else 3
	vframes=3 if atlas_ready else 2
	flip_h = _last_horizontal<0 if _locomotion_driven and not in_water else facing<0
	var cell := Vector2(texture.get_size())/Vector2(hframes,vframes)
	scale = Vector2(SWIM_SIZE/cell.x,SWIM_SIZE/cell.y) if in_water else Vector2(LAND_SIZE/cell.x,LAND_SIZE/cell.y)
	position.y = 0 if in_water else -48.0 if gait else FOOT_Y-LAND_SIZE/2.0
	if gait:
		frame=int({"daily":0,"explorer":1,"diving":2}.get(outfit,0))*8+floori(fposmod(_travel/STRIDE,1.0)*8)%8
	elif atlas_ready:
		var pose := 1+int(elapsed*7)%2 if moving else 0
		frame = 3+int(elapsed*7)%6 if in_water else int({"daily":0,"explorer":1,"diving":2}.get(outfit,0))*3+pose if clothing_ready else pose
	else:
		frame = int(elapsed*7)%6 if moving else 2
		visible = in_water

	if _locomotion_driven and not in_water and not gait:
		var key:=str(texture.get_instance_id())+":"+str(frame)
		if not _alpha_bottom.has(key):
			var image:=texture.get_image()
			var bottom:=cell.y
			if image!=null:
				if image.is_compressed(): image.decompress()
				var origin:=Vector2i(frame%hframes,floori(float(frame)/hframes))*Vector2i(cell)
				var found:=false
				for y in range(int(cell.y)-1,-1,-1):
					for x in range(int(cell.x)):
						if image.get_pixel(origin.x+x,origin.y+y).a>.5:
							bottom=y+1
							found=true
							break
					if found: break
			_alpha_bottom[key]=bottom
		position.y=(cell.y*.5-float(_alpha_bottom[key]))*scale.y
