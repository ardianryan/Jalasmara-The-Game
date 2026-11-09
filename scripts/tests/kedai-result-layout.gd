extends SceneTree

func _initialize() -> void: run.call_deferred()
func settle() -> void:
	for frame in range(8): await process_frame
func run() -> void:
	root.get_node("CalendarSync").set_process(false)
	var state=root.get_node("GameState")
	state.dive={}
	state.player={"inventory":[{"fragmentId":"klorofil","stars":3,"quantity":1}]}
	state.homestead={"pantry":{"kangkung":1}}
	state.shift={"customers":[{"id":"ui_recipe","customer":"Bu Darmi","complaint":"Daun menguning.","fragmentId":"klorofil"}],"served":[]}
	var scene=load("res://scripts/Main.gd").new()
	var hud=load("res://scripts/GameHud.gd").new()
	root.add_child(hud)
	scene.hud=hud
	scene.nala=load("res://scripts/Player.gd").new()
	scene.ui=Control.new()
	hud.add_child(scene.ui)
	for physical in [Vector2i(1440,900),Vector2i(667,375),Vector2i(390,844)]:
		root.size=physical
		await settle()
		scene._show_kedai_result({"id":"daun_kuning","customer":"Bu Darmi"},{"solution":"Periksa cahaya, unsur hara, dan kesehatan akar sebelum mengubah perawatan kebun.","earned":145})
		await settle()
		var rect:Rect2=scene.modal.get_global_rect()
		assert(root.get_visible_rect().grow(1).encloses(rect))
		assert(scene.modal.get_theme_stylebox("panel") is StyleBoxTexture)
		assert(rect.size.x<=680.1)
		var frame:StyleBox=scene.modal.get_theme_stylebox("panel")
		var measured:float=scene.modal_box.get_combined_minimum_size().y+frame.get_margin(SIDE_TOP)+frame.get_margin(SIDE_BOTTOM)
		assert(absf(rect.size.y-minf(measured,float(scene.modal.get_meta("fit_max_height"))))<3,"Short result height must fit settled content, not the full reading panel")
		var next:Button=scene.modal.find_children("*","Button",true,false)[0]
		assert(root.gui_get_focus_owner()==next)
		var scale:float=root.get_final_transform().x.length()
		assert(next.size.y*scale>=56)
		for label in scene.modal_box.find_children("*","Label",true,false): assert(label.get_theme_font_size("font_size")*scale>=16)
		var scroll:ScrollContainer=scene.modal.get_child(0)
		assert(scroll.follow_focus and scroll.get_global_rect().grow(2).encloses(next.get_global_rect()))
		assert(scene.nala.frozen and hud.get("_modal"))
		next.pressed.emit()
		await settle()
		assert(not scene.modal.get_meta("compact_result",false),"Next customer must return to the full reading layout")
		assert(scene.modal_box.get_child(0).text=="Meja Racik · Malam di Kedai Waras")
		scene._show_kedai_result({"id":"akar","customer":"Bu Darmi"},{"solution":"Akar perlu oksigen.","earned":145})
		await settle()
		assert(root.get_visible_rect().grow(1).encloses(scene.modal.get_global_rect()),"Longer garden recovery result stays scroll-safe")
		scene._close()
		await settle()
	hud.free()
	scene.nala.free()
	scene.free()
	print("KEDAI RESULT LAYOUT PASS: actual result/next-customer UI, content height, texture frame,1440/667/390 bounds,16px text,56px actions, focus/scroll and pause")
	quit()
