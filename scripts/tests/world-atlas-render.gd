extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var folder:="res://../artifacts/godot/plan04-ui/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var world:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	for physical in [Vector2i(960,540),Vector2i(667,375),Vector2i(390,844)]:
		root.size=physical
		for frame in range(5): await process_frame
		var view:=root.get_visible_rect().size
		var ratio:=view.x/float(physical.x)
		var layer:=CanvasLayer.new()
		root.add_child(layer)
		var panel:=PanelContainer.new()
		panel.position=Vector2(16,ceilf(60*ratio))
		panel.size=view-Vector2(32,panel.position.y+16)
		var style:=StyleBoxFlat.new()
		style.bg_color=Color("f1e1bc")
		style.border_color=Color("654733")
		style.set_border_width_all(2)
		style.content_margin_left=12
		style.content_margin_right=12
		style.content_margin_top=12
		style.content_margin_bottom=12
		panel.add_theme_stylebox_override("panel",style)
		layer.add_child(panel)
		var atlas=load("res://scripts/WorldAtlas.gd").new()
		atlas.configure(world,{"progress":{"day":1}},"hub")
		panel.add_child(atlas)
		atlas.set_player_position(Vector2(595,650))
		for section in ["hub","sea"]:
			atlas._change_section(section)
			if section=="hub": atlas._place_selected({"name":"Gerbang Kebun Lama","reason":"Coming soon. Jalur hulu belum terbuka dalam demo; tetap jelajahi Bandar Hujung dan Hutan Pesisir Wringin."})
			for frame in range(6): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder+"%dx%d-atlas-%s.png" % [physical.x,physical.y,section])
		layer.free()
	print("WORLD ATLAS RENDER PASS: six native responsive map captures; locked information, land and ocean sections")
	quit()
