extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var original:=JSON.stringify(world)
	var atlas_script=load("res://scripts/WorldAtlas.gd")
	for physical in [Vector2i(1440,900),Vector2i(667,375),Vector2i(390,844)]:
		root.size=physical
		for frame in range(5): await process_frame
		var view:=root.get_visible_rect().size
		var ratio:=view.x/float(physical.x)
		var layer:=CanvasLayer.new()
		root.add_child(layer)
		var panel:=PanelContainer.new()
		panel.position=Vector2(16,ceilf(60*ratio))
		panel.size=view-Vector2(32,panel.position.y+16)
		var paper:=StyleBoxFlat.new()
		paper.bg_color=Color("f1e1bc")
		paper.content_margin_left=12
		paper.content_margin_right=12
		paper.content_margin_top=12
		paper.content_margin_bottom=12
		panel.add_theme_stylebox_override("panel",paper)
		layer.add_child(panel)
		var atlas=atlas_script.new()
		atlas.configure(world,{"progress":{"day":1}},"hub")
		panel.add_child(atlas)
		atlas.set_player_position(Vector2(595,650))
		for frame in range(6): await process_frame
		assert(root.get_visible_rect().grow(1).encloses(panel.get_global_rect()),"Map host must fit portrait and short landscape")
		assert(panel.get_global_rect().grow(1).encloses(atlas.get_global_rect()),"Atlas must fit its container, without a fixed650px minimum")
		for button in atlas.get("_buttons"):
			assert(button.size.y/ratio>=48,"Map buttons remain48physical pixels")
			assert(atlas.get_global_rect().grow(1).encloses(button.get_global_rect()))
			assert(button.get_theme_color("font_focus_color")==Color("302d2a"))
		assert(float(atlas.get("_font_size"))/ratio>=16)
		var map=atlas.get("_map")
		assert(map.size.y>=96)
		map.grab_focus()
		assert(root.gui_get_focus_owner()==map,"Map surface must be keyboard reachable")
		var next:=InputEventKey.new()
		next.keycode=KEY_PAGEDOWN
		next.physical_keycode=KEY_PAGEDOWN
		next.pressed=true
		root.push_input(next)
		await process_frame
		assert(not map.selected.is_empty() and atlas.get("_info").text.contains(map.selected.name),"Keyboard selection must publish real POI details")
		assert(map._screen(map.selected.point).distance_to(map.size/2)<1,"Selected POI must stay visible")
		var old_pan:Vector2=map.pan
		next.keycode=KEY_RIGHT
		next.physical_keycode=KEY_RIGHT
		root.push_input(next)
		await process_frame
		assert(map.pan.x>old_pan.x,"Arrow keys must pan the focused map")
		for point in [Vector2(595,650),Vector2(2200,270),Vector2(1485,1330)]:
			assert(map._world_at(map._screen(point)).distance_to(point)<.01,"World/screen map projection remains exact")
		map.zoom=2.5
		map.pan=Vector2(34,-82)
		atlas._layout()
		assert(map.zoom==2.5 and map.pan==Vector2(34,-82),"Responsive layout must not reset user pan/zoom")
		atlas._place_selected({"name":"Gerbang Kebun Lama","reason":"Coming soon. Jalur ini belum terbuka dalam demo; alasan panjang harus terbungkus dan dapat dibaca tanpa melewati batas panel."})
		for frame in range(3): await process_frame
		var info:Label=atlas.get("_info")
		assert(info.autowrap_mode==TextServer.AUTOWRAP_WORD_SMART and not info.clip_text)
		assert(info.text.contains("Coming soon"))
		assert(info.size.x<=atlas.size.x)
		atlas._change_section("sea")
		assert(map.area=="sea" and map.player_point==Vector2(-100000,-100000),"Land position must not appear as a sea marker")
		atlas.set_player_position(Vector2(610,660))
		assert(map.player_point==Vector2(-100000,-100000))
		atlas._change_section("hub")
		assert(map.player_point==Vector2(610,660))
		var closed:Array=[]
		atlas.close_requested.connect(func(): closed.append(true))
		atlas.close()
		assert(closed.size()==1)
		layer.free()
	assert(JSON.stringify(world)==original,"Atlas must not mutate world locks or collision metadata")
	print("WORLD ATLAS LAYOUT PASS: portrait/landscape container bounds,48px targets,16px text, multiline locked info, projection, resize pan preservation, correct section marker, close signal and no world mutation")
	quit()
