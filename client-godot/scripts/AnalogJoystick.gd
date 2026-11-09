extends Control

signal direction_changed(direction: Vector2)

const DEAD_ZONE := 0.15
var direction := Vector2.ZERO
var pointer := -1
var _thumb := Vector2.ZERO

static func analog(offset: Vector2, radius: float) -> Vector2:
	var raw := offset / maxf(1.0, radius)
	var magnitude := minf(1.0, raw.length())
	if magnitude <= DEAD_ZONE: return Vector2.ZERO
	return raw.normalized() * ((magnitude - DEAD_ZONE) / (1.0 - DEAD_ZONE))

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(func():
		if not is_visible_in_tree(): release()
	)

func release() -> void:
	pointer = -1
	_thumb = Vector2.ZERO
	_set_direction(Vector2.ZERO)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		release()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		if event.pressed and pointer == -1 and _inside(event.position):
			pointer = event.index
			_update_thumb(event.position)
			get_viewport().set_input_as_handled()
		elif event.index == pointer and not event.pressed:
			release()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == pointer:
		_update_thumb(event.position)
		get_viewport().set_input_as_handled()

func _inside(at: Vector2) -> bool:
	return (get_global_transform_with_canvas().affine_inverse() * at - size / 2.0).length() <= size.x / 2.0

func _update_thumb(at: Vector2) -> void:
	var local := get_global_transform_with_canvas().affine_inverse() * at - size / 2.0
	var radius := size.x * 0.32
	_thumb = local.limit_length(radius)
	_set_direction(analog(local, radius))
	queue_redraw()

func _set_direction(value: Vector2) -> void:
	if direction.is_equal_approx(value): return
	direction = value
	direction_changed.emit(direction)

func _draw() -> void:
	var art := preload("res://scripts/HudSkin.gd")
	var ring := art.texture("joystick-ring")
	var thumb := art.texture("joystick-thumb")
	var diameter := size.x*.90
	var center := size/2.0
	if ring!=null: draw_texture_rect(ring,Rect2(center-Vector2.ONE*diameter/2,Vector2.ONE*diameter),false)
	if thumb!=null:
		var thumb_size := Vector2.ONE*diameter*.40
		draw_texture_rect(thumb,Rect2(center+_thumb-thumb_size/2,thumb_size),false)
