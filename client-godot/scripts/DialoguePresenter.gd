extends PanelContainer

signal advance_requested
const HudArt = preload("res://scripts/HudSkin.gd")
const BODY = preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2")
var text_view: RichTextLabel
var nameplate: Label
var portrait: TextureRect
var next_button: Button
var _revealed := 0.0
var _blip_at := 0.0
var _speaker := ""
var _total := 0
var _scroll: ScrollContainer
var _layout_pending := false
var _emotion := "neutral"
var _emote: Emote
var _row:HBoxContainer
var _column:VBoxContainer
var _panel_style:StyleBox
var _compact_layout:=false

class Emote extends Control:
	var mood := "neutral"
	func _draw() -> void:
		draw_rect(Rect2(0,0,30,28),Color("231710"))
		draw_rect(Rect2(2,2,26,24),Color("f4ebd9"))
		var ink := Color("654733")
		if mood=="happy":
			draw_rect(Rect2(8,7,3,3),ink)
			draw_rect(Rect2(19,7,3,3),ink)
			draw_polyline(PackedVector2Array([Vector2(8,15),Vector2(12,19),Vector2(18,19),Vector2(22,15)]),ink,2)
		elif mood=="thinking":
			draw_rect(Rect2(8,10,3,3),ink)
			draw_rect(Rect2(14,10,3,3),ink)
			draw_rect(Rect2(20,10,3,3),ink)
		else:
			draw_rect(Rect2(13,5,4,11),Color("a7442b"))
			draw_rect(Rect2(13,20,4,3),Color("a7442b"))

func _ready() -> void:
	set_meta("dialogue",true)
	_panel_style=HudArt.panel("dialogue")
	add_theme_stylebox_override("panel",_panel_style)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var row := HBoxContainer.new()
	_row=row
	row.add_theme_constant_override("separation",18)
	add_child(row)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(108,128)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	var portrait_border := TextureRect.new()
	portrait_border.texture = HudArt.texture("portrait-frame")
	portrait_border.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_border.stretch_mode = TextureRect.STRETCH_SCALE
	portrait_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.add_child(portrait_border)
	_emote = Emote.new()
	_emote.position = Vector2(68,-8)
	_emote.size = Vector2(30,28)
	_emote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.add_child(_emote)
	_emote.hide()
	var column := VBoxContainer.new()
	_column=column
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",10)
	row.add_child(column)
	nameplate = Label.new()
	nameplate.add_theme_color_override("font_color",Color("654733"))
	nameplate.add_theme_font_size_override("font_size",22)
	nameplate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(nameplate)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.follow_focus = true
	column.add_child(_scroll)
	text_view = RichTextLabel.new()
	text_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_view.fit_content = true
	text_view.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_view.bbcode_enabled = true
	text_view.scroll_active = false
	text_view.add_theme_font_override("normal_font",BODY)
	text_view.add_theme_font_override("bold_font",BODY)
	text_view.add_theme_color_override("default_color",Color("302d2a"))
	text_view.add_theme_constant_override("line_separation",0)
	_scroll.add_child(text_view)
	next_button = Button.new()
	next_button.text = "Lanjut"
	next_button.add_theme_font_override("font",BODY)
	HudArt.apply_button(next_button)
	HudArt.set_icon(next_button,"interact-hand",28)
	next_button.custom_minimum_size.y = 56
	next_button.pressed.connect(advance)
	column.add_child(next_button)
	get_viewport().size_changed.connect(_layout)
	resized.connect(_schedule_layout)
	_layout()
	_schedule_layout()
	if not EnvironmentState.reduced_motion:
		modulate.a = 0
		create_tween().tween_property(self,"modulate:a",1.0,.16)

static func formatted(raw: String) -> String:
	# Escape authored bracket text before allowing our limited keyword markup.
	var parts := raw.replace("[","\u0001").replace("]","\u0002").split("**")
	var result := ""
	for index in range(parts.size()):
		var part := str(parts[index]).replace("\u0001","[lb]").replace("\u0002","[rb]")
		result += "[color=#16655f]"+part+"[/color]" if index%2==1 else part
	return result

func present(speaker: String,text: String,emotion := "neutral") -> void:
	_speaker = speaker.split(" · ")[0]
	_emotion = emotion if emotion in ["neutral","happy","shock","angry","thinking"] else "neutral"
	_emote.mood = _emotion
	_emote.visible = _emotion!="neutral"
	_emote.queue_redraw()
	nameplate.text = speaker
	text_view.text = formatted(text)
	_total = text.replace("**","").length()
	_revealed = 0.0
	text_view.visible_characters = -1 if EnvironmentState.reduced_motion else 0
	portrait.texture = _portrait(_speaker)
	portrait.visible = portrait.texture != null
	_scroll.scroll_vertical = 0
	_layout()
	_schedule_layout()
	next_button.grab_focus()

func _portrait(speaker: String) -> Texture2D:
	var sheet: Texture2D
	var grid := Vector2i(2,2)
	var index := int({"Mbah Wira":0,"Beno":1,"Bu Darmi":2,"Inspektur Raka":3}.get(speaker,-1))
	if index>=0:
		sheet = load("res://resources/art/npc-atlas.png")
	else:
		for resident in GameState.world.get("surface_hub",{}).get("residents",[]):
			if str(resident.name)==speaker:
				var extra:Texture2D=preload("res://scripts/VillagePortraits.gd").for_resident(str(resident.get("id","")))
				if extra!=null: return extra
				sheet = load("res://resources/art/village-residents-v1.png")
				grid = Vector2i(3,2)
				index = int(resident.appearance)
				break
	if speaker=="Nala":
		var path := "res://resources/art/"+str(GameState.player.get("appearance","male_default")).replace("_","-")+"-outfits-v1.png"
		if ResourceLoader.exists(path):
			sheet = load(path)
			grid = Vector2i(3,3)
			index = 0
	if sheet==null or index<0 or index>=grid.x*grid.y: return null
	var cell := Vector2(sheet.get_size())/Vector2(grid)
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(index%grid.x,index/grid.x)*cell+cell*Vector2(.20,.02),cell*Vector2(.62,.60))
	return atlas

func _layout() -> void:
	var view:=get_viewport().get_visible_rect().size
	var physical:=Vector2(get_window().size)
	var portrait_screen:=physical.x<physical.y
	var compact:=not portrait_screen and physical.y<=480
	var ratio:=view.x/maxf(1,physical.x)
	var insets:=ViewportLayout.insets()
	var font_size:=preload("res://scripts/UiMetrics.gd").body(self)
	var title_size:=maxi(font_size,ceili(18*ratio))
	var padding:=Vector2(maxf(20,ceilf(20*ratio)),maxf(20,ceilf(12*ratio)))
	var gap:=ceilf((1 if compact else 4)*ratio)
	_compact_layout=compact
	_panel_style.content_margin_left=padding.x
	_panel_style.content_margin_right=padding.x
	_panel_style.content_margin_top=padding.y
	_panel_style.content_margin_bottom=padding.y
	_row.add_theme_constant_override("separation",ceili(12*ratio))
	_column.add_theme_constant_override("separation",int(gap))
	nameplate.add_theme_font_size_override("font_size",title_size)
	text_view.add_theme_font_size_override("normal_font_size",font_size)
	next_button.custom_minimum_size=Vector2(ceilf(104*ratio),ceilf(48*ratio))
	next_button.size_flags_horizontal=Control.SIZE_SHRINK_END
	next_button.add_theme_font_size_override("font_size",font_size)
	HudArt.apply_button(next_button)
	HudArt.set_icon(next_button,"interact-hand",28)
	portrait.custom_minimum_size=(Vector2(72,92) if compact else Vector2(96,112))*ratio
	portrait.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	_emote.position=Vector2(50,-8)*ratio
	_emote.scale=Vector2.ONE*ratio
	var width:=minf(ceilf(1040*ratio),view.x-ceilf(32*ratio)-insets.x-insets.z)
	var text_width:=maxf(80,width-padding.x*2-(portrait.custom_minimum_size.x+ceilf(12*ratio) if portrait.visible else 0))
	var title_height:=nameplate.get_theme_font("font").get_multiline_string_size(nameplate.text,HORIZONTAL_ALIGNMENT_LEFT,text_width,title_size).y
	var line_height:=ceilf(BODY.get_height(font_size))
	var body_height:=maxf(line_height,BODY.get_multiline_string_size(text_view.get_parsed_text(),HORIZONTAL_ALIGNMENT_LEFT,text_width,font_size).y+2)
	var column_height:=title_height+body_height+gap*2+next_button.custom_minimum_size.y
	var available:=view.y-ceilf(60*ratio)-ceilf(16*ratio)-insets.y-insets.w
	var maximum:=minf(available,view.y*(.42 if compact else .38 if portrait_screen else .32))
	var h:=minf(maximum,maxf(portrait.custom_minimum_size.y if portrait.visible else 0,column_height)+padding.y*2)
	var body_space:=maxf(line_height,h-padding.y*2-title_height-gap*2-next_button.custom_minimum_size.y)
	var visible_body:=maxf(line_height,floorf(body_space/line_height)*line_height)
	_scroll.custom_minimum_size.y=visible_body
	_scroll.size_flags_vertical=Control.SIZE_FILL
	h=minf(maximum,maxf(portrait.custom_minimum_size.y if portrait.visible else 0,title_height+visible_body+gap*2+next_button.custom_minimum_size.y)+padding.y*2)
	size=Vector2(width,h)
	position=Vector2(insets.x+(view.x-insets.x-insets.z-width)/2,view.y-h-ceilf(8*ratio)-insets.w)

func _schedule_layout() -> void:
	if _layout_pending: return
	_layout_pending=true
	_finish_layout.call_deferred()

func _finish_layout() -> void:
	_layout_pending=false
	if is_inside_tree(): _layout()

func advance() -> void:
	if text_view.visible_characters>=0 and text_view.visible_characters<_total:
		text_view.visible_characters = -1
		return
	advance_requested.emit()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventKey: return
	if event.pressed and not event.echo and event.physical_keycode in [KEY_SPACE,KEY_ENTER]:
		advance()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if text_view.visible_characters<0: return
	_revealed += delta/0.022
	var count := mini(int(_revealed),_total)
	if count>text_view.visible_characters:
		text_view.visible_characters = count
		_blip_at += delta
		if _blip_at>.10 and AudioManager.can_play_environment():
			_blip_at = 0
			AudioManager.play_sfx("wooden_click_light",.85 if _speaker=="Mbah Wira" else 1.1,-28)
	if count>=_total: text_view.visible_characters = -1

func debug_state() -> Dictionary:
	return {"speaker":_speaker,"emotion":_emotion,"visibleCharacters":text_view.visible_characters,"total":text_view.get_total_character_count(),"portrait":portrait.texture!=null,"position":[position.x,position.y],"size":[size.x,size.y],"compact":_compact_layout}
