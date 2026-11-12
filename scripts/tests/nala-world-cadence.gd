extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var visual:Sprite2D=load("res://scripts/CharacterVisual.gd").new()
	root.add_child(visual)
	root.get_node("EnvironmentState").set("clock_paused",false)
	root.get_node("ViewportLayout").set("host_paused",false)
	var cases:=0
	for appearance in ["male_default","male_nusantara","female_default","female_nusantara"]:
		for outfit in ["daily","explorer","diving"]:
			visual.set_appearance(appearance)
			visual.set_outfit(outfit)
			var before:float=visual.locomotion_state().distance
			visual.set_locomotion(Vector2(100,0),.1,Vector2.RIGHT,12.5)
			if not visual.directional_pilot_active():
				push_error("Missing eight-way gait for "+appearance+"/"+outfit)
				quit(1)
				return
			var after:float=visual.locomotion_state().distance
			if absf(after-before-12.5)>.001:
				push_error("Gait cycle ignored accepted 3D ground travel "+appearance+"/"+outfit)
				quit(1)
				return
			visual.animate(true,false,1,0)
			if visual.hframes!=8 or visual.vframes!=8:
				push_error("Eight-way atlas not shown for "+appearance+"/"+outfit)
				quit(1)
				return
			cases+=1
	visual.queue_free()
	print("NALA WORLD CADENCE PASS ",cases," appearance/outfit combinations use accepted ground travel and eight-way frames")
	quit(0)
