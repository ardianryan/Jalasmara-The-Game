extends CharacterBody2D
var speed := 160.0
var in_water := false
var frozen := false
var direction := 1
var walk_time := 0.0
var touch := Vector2.ZERO
var swim_sprite: Sprite2D
func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 9
	shape.height = 30
	collision.shape = shape
	add_child(collision)
	if ResourceLoader.exists("res://resources/art/nala-swim.png"):
		swim_sprite = Sprite2D.new()
		swim_sprite.texture = load("res://resources/art/nala-swim.png")
		swim_sprite.hframes = 3
		swim_sprite.vframes = 2
		var frame_size := Vector2(swim_sprite.texture.get_size())/Vector2(3,2)
		swim_sprite.scale = Vector2(86.0/frame_size.x,86.0/frame_size.y)
		add_child(swim_sprite)
func _physics_process(delta: float) -> void:
	walk_time += delta
	in_water = position.y>400
	if frozen:
		velocity = Vector2.ZERO
	else:
		var input := Input.get_vector("left","right","up","down")+touch
		input = input.limit_length()
		if in_water:
			velocity = velocity.move_toward(input*speed,delta*500)
		else:
			velocity.x = move_toward(velocity.x,input.x*175,delta*850)
			velocity.y += 700*delta
			if Input.is_action_just_pressed("up") and is_on_floor():
				velocity.y = -250
		if absf(velocity.x)>3:
			direction = 1 if velocity.x>0 else -1
	move_and_slide()
	position.x = clampf(position.x,20,6100)
	position.y = clampf(position.y,80,3470)
	if swim_sprite:
		swim_sprite.visible = in_water
		swim_sprite.flip_h = direction<0
		swim_sprite.frame = int(walk_time*7)%6 if velocity.length()>10 else 2
	queue_redraw()
func _draw() -> void:
	if in_water and swim_sprite:
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
