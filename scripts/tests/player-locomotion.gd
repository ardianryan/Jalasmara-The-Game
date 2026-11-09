extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var visual: Sprite2D=load("res://scripts/CharacterVisual.gd").new()
	root.add_child(visual)
	var gear_script=load("res://scripts/CharacterEquipment3D.gd")
	for id in ["male_default","male_nusantara","female_default","female_nusantara"]:
		visual.set_appearance(id)
		for outfit in ["daily","explorer","diving"]:
			visual.set_outfit(outfit)
			visual.animate(false,false,1,0)
			for index in range(8):
				var velocity:=Vector2.RIGHT.rotated(index*PI*.25)*175
				visual.set_locomotion(velocity,.08)
				visual.animate(true,false,1,0)
				var state: Dictionary=visual.locomotion_state()
				assert(visual.hframes==8 and visual.vframes==8)
				assert(state.supportedDirections.size()==8 and not state.directionalFallback)
				assert(not visual.flip_h and visual.frame/8==index)
				assert(visual.get_land_pivot()==Vector2(64,104))
				var gear: Dictionary=visual.get_equipment_state()
				assert(gear.facingDirection==visual.DIRECTIONS[index])
				var layout: Dictionary=gear_script.land_layout(gear.facingDirection,gear.gaitPhase,true)
				assert((layout.tank.z>0)==(index in [5,6,7]))
				var before: float=state.distance
				visual.set_locomotion(Vector2.ZERO,.4)
				visual.animate(false,false,1,0)
				assert(visual.vframes==1 and visual.frame==index)
				assert(visual.locomotion_state().distance==before)
	visual.consume_foot_contacts()
	var before: float=visual.locomotion_state().distance
	visual.set_locomotion(Vector2(64,0),1)
	assert(is_equal_approx(visual.locomotion_state().distance,before+64))
	assert(visual.consume_foot_contacts().size()==2)
	assert(visual.consume_foot_contacts().is_empty())
	visual.animate(true,true,1,0)
	before=visual.locomotion_state().distance
	visual.set_locomotion(Vector2(175,0),2)
	assert(visual.locomotion_state().distance==before)
	assert(visual.hframes==3 and visual.frame>=3)
	print("PLAYER LOCOMOTION PASS:12 outfits x8 drawn directions,175 displacement phase, neutral idle, once-only contacts, water isolation, directional modular gear")
	quit()
