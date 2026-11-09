extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.get_node("EnvironmentState").reduced_motion = false
	var joystick = load("res://scripts/AnalogJoystick.gd").new()
	joystick.position = Vector2(20,200)
	joystick.size = Vector2(176,176)
	root.add_child(joystick)
	assert(joystick.analog(Vector2(4,0),56)==Vector2.ZERO)
	var gentle: Vector2 = joystick.analog(Vector2(28,0),56)
	assert(gentle.x>0 and gentle.x<.5,"Half radius must preserve analog magnitude")
	assert(is_equal_approx(joystick.analog(Vector2(100,100),56).length(),1))
	var event := InputEventScreenTouch.new()
	event.index = 3
	event.position = joystick.position+joystick.size/2
	event.pressed = true
	joystick._input(event)
	assert(joystick.pointer==3)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = event.position+Vector2(44,-22)
	joystick._input(drag)
	assert(joystick.direction.x>0 and joystick.direction.y<0)
	var other := InputEventScreenTouch.new()
	other.index = 5
	other.pressed = false
	joystick._input(other)
	assert(joystick.pointer==3 and joystick.direction.length()>0,"Action finger release must not cancel joystick")
	joystick._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(joystick.pointer==-1 and joystick.direction==Vector2.ZERO)
	joystick.free()
	var presenter = load("res://scripts/DialoguePresenter.gd").new()
	root.add_child(presenter)
	var fired: Array = []
	presenter.advance_requested.connect(func(): fired.append(true))
	presenter.present("Beno","Kita butuh **Klorofil**. Tanda [b] harus terbaca literal.")
	assert(not presenter.text_view.get_parsed_text().contains("**"))
	assert(presenter.text_view.get_parsed_text().contains("[b]"))
	assert(presenter.portrait.texture!=null)
	presenter.present("Bu Darmi · Kebun Pulih","Pucuk hijau sudah tumbuh.","happy")
	assert(presenter.debug_state().portrait and presenter.debug_state().emotion=="happy","Speaker subtitles must retain their actual portrait and authored emotion")
	presenter.advance()
	assert(fired.is_empty() and presenter.text_view.visible_characters==-1,"First press reveals only")
	presenter.advance()
	assert(fired.size()==1,"Second press advances exactly once")
	for physical in [Vector2i(667,375),Vector2i(844,390),Vector2i(390,844),Vector2i(1920,1080)]:
		root.size = physical
		for frame in range(4): await process_frame
		presenter._layout()
		var viewport := root.get_visible_rect()
		assert(viewport.grow(1).encloses(presenter.get_global_rect()),"Dialogue must stay inside portrait/landscape viewport")
		assert(presenter.nameplate.get_theme_font_size("font_size")*root.get_final_transform().x.length()>=16,"Speaker names must remain readable in portrait")
	presenter.free()
	print("ANALOG DIALOGUE PASS: radial deadzone, analog magnitude, diagonal clamp, pointer ownership, focus cancellation, keyword parsing, two-stage advance, portrait and responsive bounds")
	quit()
