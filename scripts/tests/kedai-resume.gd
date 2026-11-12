extends SceneTree

func _initialize() -> void: run.call_deferred()
func settle() -> void:
	for frame in range(6): await process_frame
func physics_ticks(player: CharacterBody2D,count: int) -> void:
	player.set_physics_process(true)
	for frame in range(count):
		await physics_frame
		await process_frame
	player.set_physics_process(false)
func run() -> void:
	create_timer(10).timeout.connect(func():
		push_error("KEDAI RESUME fixture did not finish within10s; inspect the preceding assertion")
		quit(1)
	)
	root.get_node("CalendarSync").set_process(false)
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var wira:=Vector2.ZERO
	for district in state.world.surface_hub.districts:
		if district.npc=="Mbah Wira": wira=Vector2(district.x,district.y)
	assert(wira!=Vector2.ZERO)
	state.player={"coins":100,"version":0,"inventory":[{"fragmentId":"klorofil","stars":3,"quantity":1}],"progress":{"day":1,"stage":"night"}}
	state.surface={"area":"hub","x":wira.x,"y":wira.y,"playerVersion":0,"positionAt":1234}
	state.dive={}
	state.adventure={}
	state.homestead={"pantry":{},"inside":false}
	state.shift={"id":"existing-owned-shift-fixture","customers":[{"id":"ui_recipe","customer":"Warga","complaint":"Racikan","fragmentId":"klorofil"}],"served":[]}
	var initial:=JSON.stringify({"player":state.player,"surface":state.surface,"shift":state.shift})
	var api:=root.get_node("ApiClient")
	var original:Script=api.get_script()
	api.set_script(load("res://../scripts/tests/support/kedai-resume-api.gd"))
	var scene=load("res://scripts/Main.gd").new()
	var hud=load("res://scripts/GameHud.gd").new()
	root.add_child(hud)
	scene.hud=hud
	scene.nala=load("res://scripts/Player.gd").new()
	root.add_child(scene.nala)
	scene.nala.set_physics_process(false)
	scene.nala.position=wira
	scene.nala.land_path.reset(wira)
	scene.status=Label.new()
	scene.ui=Control.new()
	hud.add_child(scene.ui)
	assert(scene._can_resume_kedai("Mbah Wira"))
	await scene._npc_interact("Mbah Wira")
	await settle()
	assert(api.get("calls").size()==1 and api.get("calls")[0].path=="/kedai/start","Resume must use the authenticated shift endpoint without a forbidden redundant surface write")
	assert(scene.modal.get_meta("service_tray",false) and not scene.network_busy)
	scene.nala.velocity=Vector2(100,0)
	scene.nala.touch=Vector2.RIGHT
	scene._close()
	assert(scene.nala.frozen and scene.nala.velocity==Vector2.ZERO and scene.nala.touch==Vector2.ZERO,"Closing the service panel must retain the shift's land lock and clear queued inputs")
	assert(scene._action_label({"kind":"npc","name":"Mbah Wira"})=="Lanjutkan giliran kedai")
	scene.nala.touch=Vector2.RIGHT
	await physics_ticks(scene.nala,12)
	assert(scene.nala.position==wira and scene.nala.land_path.size()==0 and scene._can_resume_kedai("Mbah Wira"),"Actual Player physics must not create an unsavable path while the shift is active")
	scene.set_interaction_modal(false)
	assert(scene.nala.frozen and scene.nala.touch==Vector2.ZERO,"Interaction close must also preserve the active shift lock")
	scene.nala.frozen=false
	scene._restore_player_movement()
	assert(scene.nala.frozen,"Restoring controls after loading/refresh must preserve the active shift lock")
	var dock:=Vector2(1000,1200)
	state.surface.x=dock.x
	state.surface.y=dock.y
	scene.nala.position=dock
	scene.nala.land_path.reset(dock)
	assert(not scene._can_resume_kedai("Mbah Wira"))
	scene._kedai_customer()
	assert(scene.modal.get_meta("service_tray",false),"A stranded active shift must expose its service controls")
	var temporary_close:=false
	var dismiss_button:=false
	for button in scene.modal.find_children("*","Button",true,false):
		if button.text.begins_with("Tutup sementara"): temporary_close=true
		if button.text.begins_with("Tutup panel"): dismiss_button=true
	assert(temporary_close and not dismiss_button,"A stranded shift must offer recovery and hide the dead-end dismiss action")
	scene._close()
	assert(scene.modal.get_meta("service_tray",false) and scene.nala.frozen,"Escape cannot strand a locked player without recovery controls")
	scene._close()
	assert(scene.modal.get_meta("service_tray",false),"Repeated dismissals must retain recovery controls")
	state.surface.x=wira.x
	state.surface.y=wira.y
	scene.nala.position=wira
	scene.nala.land_path.reset(wira)
	scene._close()
	var active_shift:Dictionary=state.shift
	state.shift={}
	scene.set_interaction_modal(true)
	assert(scene.nala.frozen,"A modal must still lock movement after a shift ends")
	scene.set_interaction_modal(false)
	assert(not scene.nala.frozen,"A settled or abandoned shift with refreshed empty state must release movement")
	scene.nala.touch=Vector2.RIGHT
	await physics_ticks(scene.nala,6)
	assert(scene.nala.velocity.x>0 and scene.nala.position.distance_to(wira)>.5 and scene.nala.land_path.size()>0,"Scheduled Player physics must accept input, move and record a path once the shift is cleared")
	scene.nala.position=wira
	scene.nala.velocity=Vector2.ZERO
	scene.nala.touch=Vector2.ZERO
	scene.nala.land_path.reset(wira)
	state.shift=active_shift
	api.get("calls").clear()
	api.set("accept_start",false)
	await scene._npc_interact("Mbah Wira")
	await settle()
	assert(api.get("calls").size()==1 and api.get("calls")[0].path=="/kedai/start")
	assert(not scene.modal.get_meta("service_tray",false),"Server denial must not open cached service controls")
	scene._close()
	api.set("accept_start",true)
	for condition in ["no-shift","other-npc","far","unacknowledged","pending-path","wrong-stage","forest","inside","diving"]:
		var name:="Mbah Wira"
		state.shift.id="existing-owned-shift-fixture"
		state.surface.area="hub"
		state.surface.x=wira.x
		state.surface.y=wira.y
		state.homestead.inside=false
		state.dive={}
		state.player.progress.stage="night"
		scene.nala.position=wira
		scene.nala.land_path.reset(wira)
		match condition:
			"no-shift": state.shift.id=""
			"other-npc": name="Bu Darmi"
			"far":
				scene.nala.position=wira+Vector2(200,0)
				state.surface.x=scene.nala.position.x
			"unacknowledged": scene.nala.position+=Vector2(2,0)
			"pending-path":
				scene.nala.land_path.record(wira+Vector2(10,0))
				scene.nala.land_path.record(wira)
			"wrong-stage": state.player.progress.stage="dive"
			"forest": state.surface.area="forest"
			"inside": state.homestead.inside=true
			"diving": state.dive={"id":"dive-fixture"}
		assert(not scene._can_resume_kedai(name),"Resume cannot bypass the normal sync for "+condition)
	state.dive={}
	state.homestead.inside=false
	state.surface.area="hub"
	state.surface.x=wira.x
	scene.nala.position=wira
	scene.nala.land_path.reset(wira)
	state.player.progress.stage="night"
	api.get("calls").clear()
	await scene._enter_forest()
	assert(api.get("calls").size()==1 and api.get("calls")[0].path=="/adventure/surface-position","Active-shift travel must retain its server-validated surface write and reject travel on failure")
	assert(not scene.network_busy)
	assert(JSON.stringify({"player":state.player,"surface":state.surface,"shift":state.shift})==initial)
	scene.nala.free()
	scene.status.free()
	hud.free()
	scene.free()
	api.set_script(original)
	print("KEDAI RESUME PASS: active shift recovery controls persist at a stranded dock; stationary Wira resume, movement lock and empty-shift unlock; server denial, nine exclusion guards and travel rejection preserved; API capture only, no transaction")
	quit()
