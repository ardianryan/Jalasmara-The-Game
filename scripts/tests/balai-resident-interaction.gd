extends SceneTree

const NAME:="Ki Lurah Wirabhumi"
const DAY:="Ukiran tongkat ini mencatat pasang."
const NIGHT:="Lentera sudah menyala. Periksa bekalmu."
var checks:=0

func _initialize() -> void: call_deferred("run")

func settle() -> void:
	for frame in range(5): await process_frame

func key(code: Key) -> void:
	var event:=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=true
	root.push_input(event)
	await process_frame
	event.pressed=false
	root.push_input(event)
	await settle()

func actions(page: Node) -> Array[Button]:
	var result: Array[Button]=[]
	for child in page.content.get_children():
		if child is Button: result.append(child)
	return result

func run() -> void:
	root.get_node("CalendarSync").set_process(false)
	var api:=root.get_node("ApiClient")
	var serial: int=api.serial
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":200,"inventory":[],"progress":{"day":2,"stage":"dive","tutorial":true,"missions":["akar"]}}
	state.homestead={"permit":false,"pendingStoryAdvance":false}
	state.dive={}
	var before:=JSON.stringify({"world":state.world,"player":state.player,"home":state.homestead})
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.authoritative=true
	clock.reduced_motion=true
	clock.visual_minutes=1200
	clock._process(0)
	var main:=Node2D.new()
	root.add_child(main)
	# Attach after ready so the actual Main methods run without startup authentication or networking.
	main.set_script(load("res://scripts/Main.gd"))
	main.set_process(false)
	main.set_physics_process(false)
	main._setup_input()
	main.nala=load("res://scripts/Player.gd").new()
	main.add_child(main.nala)
	main.nala.set_physics_process(false)
	main.nala.frozen=true
	main.nala.position=Vector2(940,310)
	main._build_ui()
	main.homestead_ui=load("res://scripts/HomesteadUI.gd").new()
	main.add_child(main.homestead_ui)
	main.homestead_ui.configure(main,false)
	var page: Node=main.homestead_ui
	var chief: Node2D=load("res://scripts/HubActor.gd").new()
	chief.actor_name=NAME
	chief.position=Vector2(940,310)
	chief.set_meta("conversation",DAY)
	chief.set_meta("evening_conversation",NIGHT)
	main.add_child(chief)
	chief.set_process(false)
	main.surface_actors.append(chief)
	for physical in [Vector2i(667,375),Vector2i(844,390),Vector2i(390,844)]:
		root.size=physical
		await settle()
		for offset in [0.0,-1.0,1.0]:
			chief.position=Vector2(940+offset,310)
			main.nala.position=chief.position
			main._find_nearby()
			assert(str(main.nearby.id)==NAME,"Actual tie ordering selects the resident; all one-pixel resident-selected cases must use the same service page")
			if offset==0: print("BALAI ACTUAL EXACT TIE: ",str(main.nearby.id))
			assert(main.service_resident("balai")=={"name":NAME,"text":NIGHT})
			main._interact()
			await settle()
			var buttons:=actions(page)
			assert(buttons.size()==3 and buttons[0].text=="Bicara dengan Ki Lurah" and buttons[1].text=="Catat izin rakit kebun" and buttons[2].text=="Kembali")
			assert(not buttons[1].disabled and root.gui_get_focus_owner()==buttons[0])
			assert(main.modal_open and main.nala.frozen and clock.clock_paused)
			page.busy=true
			buttons[0].pressed.emit()
			await settle()
			assert(page.is_open and main.modal_open and main.modal==null,"Pending service operation must keep its page and must not open dialogue")
			page.busy=false
			var scale: float=root.get_final_transform().x.length()
			assert(root.get_visible_rect().grow(2).encloses(page.panel.get_global_rect()))
			for button in buttons:
				assert(button.size.y*scale>=56 and button.get_theme_font_size("font_size")*scale>=16)
			for label in page.panel.find_children("*","Label",true,false):
				assert(label.get_theme_font_size("font_size")*scale>=16)
			await key(KEY_TAB)
			assert(root.gui_get_focus_owner()==buttons[1],"Permit action must remain reachable by Tab")
			await key(KEY_TAB)
			assert(root.gui_get_focus_owner()==buttons[2])
			await key(KEY_ENTER)
			assert(not page.is_open and not main.modal_open and not main.nala.frozen,"Keyboard Enter on Back closes the service page")
			main._find_nearby()
			main._interact()
			await settle()
			await key(KEY_ENTER)
			assert(not page.is_open and main.modal_open and main.nala.frozen and is_instance_valid(main.modal))
			assert(main.modal.get_script().resource_path.ends_with("/DialoguePresenter.gd"),"Use the shared presenter, not a service-page dialogue imitation")
			assert(main.modal.nameplate.text==NAME and main.modal.text_view.get_parsed_text()==NIGHT)
			assert(root.get_visible_rect().grow(2).encloses(main.modal.get_global_rect()))
			assert(main.modal.text_view.get_theme_font_size("normal_font_size")*scale>=15.99)
			await key(KEY_ENTER)
			assert(not main.modal_open and main.modal==null,"Keyboard Enter completes the real Main dialogue chain")
			assert(api.serial==serial,"Talking and closing must not mutate server state")
			checks+=1
	chief.position=Vector2(941,310)
	main.nala.position=Vector2(940,310)
	main._find_nearby()
	assert(str(main.nearby.id)=="balai","The genuinely board-selected path must reach the identical service page")
	main._interact()
	await settle()
	assert(actions(page)[0].text=="Bicara dengan Ki Lurah")
	page.close()
	checks+=1
	for scenario in ["day-near","day-at-work","absent","far-from-board","far-from-player","player-outside-board","diving"]:
		state.dive={}
		clock.visual_minutes=600 if scenario.begins_with("day") else 1200
		clock._process(0)
		chief.position=Vector2(940,310)
		main.nala.position=chief.position
		main.surface_actors.clear()
		if scenario!="absent": main.surface_actors.append(chief)
		if scenario=="day-at-work": chief.position=Vector2(580,950)
		elif scenario=="far-from-board": chief.position=Vector2(1021,310)
		elif scenario=="far-from-player":
			chief.position=Vector2(1010,310)
			main.nala.position=Vector2(860,310)
		elif scenario=="player-outside-board":
			chief.position=Vector2(990,310)
			main.nala.position=Vector2(1041,310)
		elif scenario=="diving": state.dive={"id":"not-a-network-session"}
		page.open_for("balai")
		await settle()
		var buttons:=actions(page)
		if scenario=="day-near":
			assert(main.service_resident("balai")=={"name":NAME,"text":DAY})
			assert(buttons[0].text=="Bicara dengan Ki Lurah")
		else:
			assert(main.service_resident("balai").is_empty())
			assert(buttons.size()==2 and buttons[0].text=="Catat izin rakit kebun","Absent or out-of-range chief must not create a phantom talk action: "+scenario)
		page.close()
		checks+=1
	state.dive={}
	chief.position=Vector2(940,310)
	main.nala.position=chief.position
	main.surface_actors.clear()
	main.surface_actors.append(chief)
	for permit in [false,true]:
		state.homestead.permit=permit
		state.player.progress.missions=[]
		page.open_for("balai")
		await settle()
		var buttons:=actions(page)
		assert(buttons.size()==2 and buttons[0].text=="Bicara dengan Ki Lurah" and buttons[1].text=="Kembali","Dialogue stays available without falsely offering an ineligible or already-granted permit")
		page.close()
		checks+=1
	state.homestead.permit=false
	state.player.progress.missions=["akar"]
	assert(JSON.stringify({"world":state.world,"player":state.player,"home":state.homestead})==before)
	assert(api.serial==serial)
	main.hint.free()
	main.free()
	print("BALAI RESIDENT INTERACTION PASS: ",checks," actual Main/UI scenarios,exact tie and +/-1px selection,shared presenter,Tab/Enter,667/844/390 layouts16px/56px,day/proximity/dive/permit guards;API serial unchanged")
	quit()
