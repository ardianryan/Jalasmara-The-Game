extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var phase := OS.get_environment("HUD_REGION_PHASE")
	if phase.is_empty(): phase="after"
	assert(phase in ["before","after","after-ascii"])
	var output := "res://../artifacts/godot/hud-region-overflow/"+phase
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(667,375)
	for frame in range(3): await process_frame
	var hud=load("res://scripts/GameHud.gd").new()
	hud.touch_enabled=true
	root.add_child(hud)
	hud.set_process(false)
	for frame in range(3): await process_frame
	var server:=TextServerManager.get_primary_interface()
	var region:Label=hud.get("_region")
	var report:Dictionary={"phase":phase,"textServer":server.get_name(),"viewport":[667,375],"physicalScale":root.get_final_transform().x.length(),"names":[],"rectangles":{}}
	for key in ["_identity_plate","_identity_portrait","_region","_resources","_objective_toggle","_sound_button","_dpad"]:
		var rect:Rect2=hud.get(key).get_global_rect()
		report.rectangles[key]=[rect.position.x,rect.position.y,rect.size.x,rect.size.y]
	for full_name in ["Hutan Pesisir Wringin","Bandar Hujung","Dangkalan Segaran","Wilayah Pesisir yang Sangat Panjang"]:
		hud.update_state({"area":full_name,"coins":200,"weight":0,"capacity":20,"clock":"14:05","weather":"Cerah"})
		for frame in range(3): await process_frame
		var font:=region.get_theme_font("font")
		var font_size:=region.get_theme_font_size("font_size")
		var line:=TextLine.new()
		line.add_string(region.text,font,font_size)
		line.width=region.size.x
		line.text_overrun_behavior=region.text_overrun_behavior
		line.get_size()
		var rid:=line.get_rid()
		var shaped:Dictionary={"scope":"TextLine with actual Label font/size/width/overrun; not private Label RID"}
		for method in ["shaped_text_get_trim_pos","shaped_text_get_ellipsis_pos","shaped_text_get_ellipsis_glyph_count"]:
			if server.has_method(method): shaped[method]=server.call(method,rid)
		var measured:=font.get_string_size(region.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		var row:Dictionary={"fullName":full_name,"labelText":region.text,"tooltip":region.tooltip_text,"logicalWidth":region.size.x,"fontSize":font_size,"measuredTextWidth":measured,"overrun":region.text_overrun_behavior,"clip":region.clip_text,"shaped":shaped}
		report.names.append(row)
		assert(region.tooltip_text==full_name,"Full location name must remain available without changing state")
		if phase!="before":
			assert(measured<=region.size.x,"Displayed location including ellipsis must fit actual font/width")
			if font.get_string_size(full_name,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>region.size.x:
				assert(region.text.ends_with("..."),"Overflow must be explicit rather than an unmarked clipped name")
			else: assert(region.text==full_name,"Short names must not be abbreviated")
			assert(region.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Noninteractive location must not acquire input handling")
		if DisplayServer.get_name()!="headless" and full_name=="Hutan Pesisir Wringin":
			await RenderingServer.frame_post_draw
			var image:=root.get_texture().get_image()
			image.save_png(output+"/667-wringin.png")
			var before_png:="res://../artifacts/godot/hud-region-overflow/before/667-wringin.png"
			if phase!="before" and FileAccess.file_exists(before_png):
				var original:=Image.load_from_file(before_png)
				assert(image.get_data()!=original.get_data(),"Native correction must change the actual previously clipped image")
	if phase!="before":
		var original_rectangles:Dictionary={"_identity_plate":[10.0,10.0,382.0,96.0],"_identity_portrait":[26.0,22.0,46.0,36.0],"_region":[80.0,22.0,228.0,36.0],"_resources":[26.0,56.0,282.0,36.0],"_objective_toggle":[316.0,16.0,70.0,70.0],"_sound_button":[874.0,16.0,70.0,70.0],"_dpad":[16.0,380.0,144.0,144.0]}
		assert(report.rectangles==original_rectangles,"Actual BEFORE fixture rectangles must remain unchanged")
		var font:=region.get_theme_font("font")
		var font_size:=region.get_theme_font_size("font_size")
		var hud_script=load("res://scripts/GameHud.gd")
		for name in ["A\u0301bc defghijklmnop","Pesisir ❤️‍🔥 Wringin","Kawasan 👨‍👩‍👧‍👦 Nusantara"]:
			var boundaries:=server.string_get_character_breaks(name)
			for width in [20.0,45.0,90.0,150.0]:
				var fitted:String=hud_script.fit_region_name(name,font,font_size,width)
				assert(font.get_string_size(fitted,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x<=width)
				if fitted.ends_with("...") and fitted!="...":
					var prefix:=fitted.left(fitted.length()-3)
					assert(name.begins_with(prefix) and prefix.length() in boundaries,"Fitting must preserve whole grapheme clusters")
		hud.update_state({"area":"Hutan Pesisir Wringin"})
		root.size=Vector2i(1440,900)
		for frame in range(4): await process_frame
		assert(region.text=="Hutan Pesisir Wringin","Resizing must restore the preserved full name when it fits")
		assert(region.tooltip_text=="Hutan Pesisir Wringin")
		root.size=Vector2i(667,375)
		for frame in range(4): await process_frame
		assert(region.text.ends_with("..."),"Returning to narrow width must refit without a state update")
		report["resizeAndGraphemesVerified"]=true
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("HUD REGION ",phase," OBSERVED ",JSON.stringify(report))
	if phase!="before": print("HUD REGION FIT PASS: actual font bounds, preserved badge/input geometry, grapheme boundaries and resize restoration")
	hud.free()
	quit()
