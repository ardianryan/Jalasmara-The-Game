extends CharacterBody2D
const LAND_WALK_SPEED := 100.0
var land_path := preload("res://scripts/land/LandPath.gd").new()
var surface_traversal := preload("res://scripts/SurfaceTraversal.gd").new()
var traversal_state: Dictionary = {}
var speed := 160.0
var in_water := false
var frozen := false
var direction := 1
var walk_time := 0.0
var touch := Vector2.ZERO
var land_mask := Callable()
var input_transform := Callable()
var visual_motion_transform := Callable()
var land_velocity_transform := Callable()
var land_position_transform := Callable()
var swim_sprite: Sprite2D
var hybrid_visual := false
var was_water := false
var wet_remaining := 0.0
var effect_clock := 0.0
var bubbles: Array[Dictionary] = []
var wet_marks: Array[Dictionary] = []
var outfit := "daily"
var equipment: Dictionary = {}
var _traversal_bob := 0.0
func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 12
	shape.height = 26
	collision.shape = shape
	collision.position.y = -1
	add_child(collision)
	swim_sprite = preload("res://scripts/CharacterVisual.gd").new()
	add_child(swim_sprite)

func _physics_process(delta: float) -> void:
	walk_time += delta
	in_water = not GameState.dive.is_empty()
	if was_water and not in_water:
		wet_remaining = 5
	was_water = in_water
	wet_remaining = maxf(0,wet_remaining-delta)
	effect_clock += delta
	for i in range(bubbles.size()-1,-1,-1):
		bubbles[i].age += delta
		if float(bubbles[i].age)>2.2:
			bubbles.remove_at(i)
	for i in range(wet_marks.size()-1,-1,-1):
		wet_marks[i].age += delta
		if float(wet_marks[i].age)>5:
			wet_marks.remove_at(i)
	var low_oxygen := float(GameState.dive.get("oxygen",100))<25
	var interval := .16 if low_oxygen else .28 if velocity.length()>70 else 1.5
	if in_water and not frozen and effect_clock>interval:
		effect_clock = 0
		if bubbles.size()<24:
			bubbles.append({"at":position+Vector2(direction*33,-9),"age":0.0,"radius":2.0+fmod(walk_time*3,2)})
	elif not in_water and wet_remaining>0 and effect_clock>.23:
		effect_clock = 0
		if wet_marks.size()<24:
			wet_marks.append({"at":position+Vector2(sin(walk_time*16)*12,12),"age":0.0})
	if frozen or ViewportLayout.host_paused or (not in_water and land_path.full()):
		velocity = Vector2.ZERO
	else:
		var input := touch if touch.length_squared()>0 else Input.get_vector("left","right","up","down")
		input = input.limit_length()
		if in_water:
			velocity = velocity.move_toward(input*speed,delta*500)
		else:
			if input_transform.is_valid(): input = input_transform.call(input,position)
			velocity = velocity.move_toward(input*LAND_WALK_SPEED*float(traversal_state.get("paceScale",1.0)),delta*850)
		if absf(velocity.x)>3:
			direction = 1 if velocity.x>0 else -1
	var previous := position
	if not in_water and land_velocity_transform.is_valid(): velocity=land_velocity_transform.call(position,velocity,delta)
	move_and_slide()
	if in_water:
		position.x = clampf(position.x,20,float(GameState.world.get("width",6144))-44)
		position.y = clampf(position.y,400,float(GameState.world.get("height",3584))-114)
	else:
		var hub: Dictionary = GameState.world.get("hub",{})
		position.x = clampf(position.x,40,float(hub.get("width",2400))-40)
		position.y = clampf(position.y,12,float(hub.get("height",1600))-80)
		if land_mask.is_valid() and not land_mask.call(position):
			var along_x := Vector2(position.x,previous.y)
			var along_y := Vector2(previous.x,position.y)
			if land_mask.call(along_x):
				position = along_x
				velocity.y = 0
			elif land_mask.call(along_y):
				position = along_y
				velocity.x = 0
			else:
				position = previous
				velocity = Vector2.ZERO
	if not in_water and land_position_transform.is_valid():
		var limited:Vector2=land_position_transform.call(previous,position,delta)
		if limited!=position:
			position=limited if not land_mask.is_valid() or land_mask.call(limited) else previous
			velocity=(position-previous)/maxf(delta,.001)
	var moved_velocity := (position-previous)/maxf(delta,0.001) if not in_water else velocity
	if not in_water and moved_velocity.length()<8.0:
		velocity = Vector2.ZERO
		moved_velocity = Vector2.ZERO
	if not in_water:
		surface_traversal.set_reduced_motion(EnvironmentState.reduced_motion)
		traversal_state = surface_traversal.sample(position,moved_velocity,delta,frozen or ViewportLayout.host_paused or EnvironmentState.clock_paused)
		land_path.record(position)
	else:
		traversal_state = {}
	if swim_sprite:
		swim_sprite.position.y -= _traversal_bob
		_traversal_bob = 0.0
		# The dock's changing arch separates the village from the dive ladder.
		# Hysteresis prevents swapping repeatedly while standing in the curtain.
		if in_water:
			outfit = "diving"
		elif position.x>1450 and position.y>1230:
			outfit = "diving"
		elif position.x<1390 or position.y<1200:
			outfit = "daily"
		equipment = {"tank":outfit=="diving","net":outfit=="diving","satchel":outfit=="explorer"}
		swim_sprite.set_appearance(str(GameState.player.get("appearance","male_default")))
		swim_sprite.set_outfit(outfit)
		swim_sprite.set_equipment(equipment)
		var visual_velocity: Vector2=visual_motion_transform.call(previous,position,delta) if not in_water and visual_motion_transform.is_valid() else moved_velocity
		swim_sprite.set_locomotion(moved_velocity,delta,visual_velocity)
		swim_sprite.animate(moved_velocity.length()>10,in_water,direction,walk_time)
		if not in_water:
			_traversal_bob = float(traversal_state.get("footBob",0.0))
			swim_sprite.position.y += _traversal_bob
		swim_sprite.visible = not hybrid_visual
	queue_redraw()
func _draw() -> void:
	if hybrid_visual and not in_water: return
	for mark in wet_marks:
		var at: Vector2 = mark.at-position
		draw_set_transform(at,0,Vector2(1,.35))
		draw_circle(Vector2.ZERO,5,Color(.06,.23,.23,(1-float(mark.age)/5)*.45))
		draw_set_transform(Vector2.ZERO)
	for bubble in bubbles:
		var age := float(bubble.age)
		var at: Vector2 = bubble.at-position+Vector2(sin(age*4+float(bubble.radius))*8,-age*38)
		draw_arc(at,float(bubble.radius),0,TAU,10,Color(.7,.93,.87,(1-age/2.2)*.65),1)
	if not in_water and wet_remaining>0:
		for i in range(3):
			draw_line(Vector2(-12+i*12,fmod(walk_time*42+i*13,34)),Vector2(-12+i*12,fmod(walk_time*42+i*13,34)+3),Color(.6,.85,.86,.65),1)
	if not in_water:
		draw_set_transform(Vector2(0,12),0,Vector2(1,.35))
		draw_circle(Vector2.ZERO,19,Color(.04,.13,.11,.3))
		draw_set_transform(Vector2.ZERO)
	if hybrid_visual or (swim_sprite and swim_sprite.visible):
		return
	var step := sin(walk_time*9)*3 if absf(velocity.x)>5 else 0.0
	draw_rect(Rect2(-8,-22,16,8),Color("232e32"))
	draw_rect(Rect2(-7,-15,14,10),Color("bb8054"))
	draw_rect(Rect2(-9,-20,18,3),Color("bcb384"))
	draw_rect(Rect2(-10,-4,20,16),Color("d27e42"))
	draw_rect(Rect2(-4,-3,8,13),Color("b2c5bf"))
	draw_rect(Rect2(-13,-1,5,15),Color("bc855a"))
	draw_rect(Rect2(8,-1,5,15),Color("bc855a"))
	draw_rect(Rect2(-8,12,7,10+step),Color("263f49"))
	draw_rect(Rect2(2,12,7,10-step),Color("263f49"))
	draw_rect(Rect2(-10,20+step,10,4),Color("243a40"))
	draw_rect(Rect2(2,20-step,10,4),Color("243a40"))
	draw_rect(Rect2(-15,-6,6,21),Color("549e9c"))
	draw_rect(Rect2(-14,-2,4,12),Color("a0d3b1"))
