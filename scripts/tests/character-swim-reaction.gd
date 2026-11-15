extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var visual:Sprite2D=load("res://scripts/CharacterVisual.gd").new()
	root.add_child(visual)
	visual.set_appearance("male_nusantara")
	visual.set_outfit("diving")
	visual.animate(false,true,1,0.0)
	assert(visual.frame==4 and visual.texture.get_size()==Vector2(896,112),"Stopped swimmer should use the compact level-fin pose")
	var frames:Array[int]=[]
	for step in range(8):
		visual.set_locomotion(Vector2(140,0),.1)
		visual.animate(true,true,1,float(step+1)*.1)
		frames.append(visual.frame)
	assert(frames==[1,2,3,4,5,6,7,0],"Kick cadence must follow distance through the full eight-frame cycle")
	var phase:float=visual._swim_phase
	visual.set_locomotion(Vector2.ZERO,.5)
	visual.animate(false,true,1,1.3)
	assert(visual._swim_phase==phase and visual.frame==4,"Idle may bob but cannot paddle in place")
	visual.trigger_shot(1.3)
	visual.animate(false,true,1,1.3)
	assert(float(visual.get_equipment_state().shotPulse)>.9 and visual.position.x<0,"Shot input should recoil body and separate launcher")
	visual.trigger_hit(1.4)
	visual.animate(false,true,1,1.4)
	assert(visual.modulate.g<.8 and visual.scale.x>visual.scale.y,"Hit must make a visible, short body reaction")
	visual.animate(false,true,1,2.0)
	assert(visual.modulate==Color.WHITE and is_zero_approx(float(visual.get_equipment_state().shotPulse)),"Reactions must settle without sticking")
	var environment:=root.get_node("EnvironmentState")
	environment.set("reduced_motion",true)
	visual.animate(false,true,1,2.4)
	assert(is_zero_approx(visual.position.y),"Reduced motion must remove idle water bob")
	environment.set("reduced_motion",false)
	visual.free()
	print("CHARACTER SWIM REACTION PASS: distance-cadenced kick, idle hold, shot recoil, hit recovery")
	quit()
