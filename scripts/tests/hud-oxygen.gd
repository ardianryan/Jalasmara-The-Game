extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var hud=load("res://scripts/GameHud.gd").new()
	root.add_child(hud)
	hud.set_process(false)
	var state={"diving":true,"oxygen":100,"maxOxygen":100,"reducedMotion":false}
	hud.update_state(state)
	assert(hud.debug_layout().oxygen.status=="normal")
	assert(hud.debug_layout().oxygen.lossText=="")
	state.oxygen=36
	hud.update_state(state)
	assert(not hud.debug_layout().oxygen.warning)
	state.oxygen=35
	hud.update_state(state)
	assert(hud.debug_layout().oxygen.status=="low" and hud.debug_layout().oxygen.warning)
	assert(hud.get("_warning").text=="O2 MENIPIS - CARI TANGGA")
	state.oxygen=15
	hud.update_state(state)
	assert(hud.debug_layout().oxygen.status=="critical")
	assert(hud.debug_layout().oxygen.lossText=="-20 O2")
	hud._process(.5)
	var remaining:float=hud.get("_loss_seconds")
	hud.update_state(state)
	assert(is_equal_approx(hud.get("_loss_seconds"),remaining),"Repeated state must not renew feedback")
	state.reducedMotion=true
	hud.update_state(state)
	hud._process(.1)
	assert(hud.debug_layout().oxygen.reducedMotion and hud.get("_instrument").loss_feedback==0)
	hud.set_modal(true)
	assert(not hud.debug_layout().oxygen.visible and not hud.debug_layout().oxygen.warning)
	hud.set_modal(false)
	hud._process(2)
	assert(hud.debug_layout().oxygen.lossText=="" and not hud.get("_oxygen_loss").visible)
	state.maxOxygen=120
	state.oxygen=10
	hud.update_state(state)
	assert(hud.debug_layout().oxygen.lossText=="","Capacity changes must not appear as damage")
	state.diving=false
	hud.update_state(state)
	assert(not hud.debug_layout().oxygen.visible)
	hud.free()
	print("HUD OXYGEN PASS: inclusive35/15 thresholds, labels, authoritative loss delta, no feedback replay, capacity guard, reduced motion, expiry, modal and surface states")
	quit()
