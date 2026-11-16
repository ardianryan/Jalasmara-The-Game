extends PanelContainer

signal advance_requested
const HudArt = preload("res://scripts/HudSkin.gd")
const BODY = preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2")
const RANTO_PORTRAIT := preload("res://resources/art/cinematics-v2/pak-ranto-portrait.png")
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
var _portrait_slot:Control
var _portrait_frame:TextureRect
var _message_row:HBoxContainer
var _scroll_hint:Label
var _panel_style:StyleBox
var _compact_layout:=false
var _portrait_tween:Tween

const SPEAKER_INK := {
	"Nala": Color("a34f2c"),
	"Mbah Wira": Color("315c47"),
	"Beno": Color("366774"),
	"Saras": Color("315f72"),
	"Kinasih": Color("71547c"),
	"Ki Lurah Wirabhumi": Color("684326"),
	"Inspektur Raka": Color("79346d"),
	"Pak Ranto": Color("77532e"),
}

const SPEAKER_BLIP_PITCH := {
	"Mbah Wira": 0.79,
	"Beno": 1.26,
	"Kinasih": 1.15,
	"Saras": 1.04,
	"Inspektur Raka": 0.93,
}

class Emote extends Control:
	var mood := "neutral"
	func _draw() -> void:
		draw_rect(Rect2(0,0,30,28),Color("231710"))
		draw_rect(Rect2(2,2,26,24),Color("f4ebd9"))
		var ink := Color("654733")
		if mood=="happy":
			for mark in [Vector2(14,5),Vector2(7,12),Vector2(21,12)]:
				draw_rect(Rect2(mark,Vector2(3,3)),Color("d4a359"))
			draw_rect(Rect2(12,10,6,7),Color("f7c662"))
		elif mood=="thinking":
			draw_rect(Rect2(8,10,3,3),ink)
			draw_rect(Rect2(14,10,3,3),ink)
			draw_rect(Rect2(20,10,3,3),ink)
		elif mood=="angry":
			draw_line(Vector2(5,9),Vector2(11,15),Color("a7442b"),3)
			draw_line(Vector2(11,15),Vector2(17,7),Color("a7442b"),3)
			draw_line(Vector2(17,7),Vector2(24,13),Color("a7442b"),3)
		else:
			for x in [9,18]:
				draw_rect(Rect2(x,5,3,11),Color("a7442b"))
				draw_rect(Rect2(x,20,3,3),Color("a7442b"))

func _ready() -> void:
	set_meta("dialogue",true)
	_panel_style=HudArt.panel("dialogue")
	add_theme_stylebox_override("panel",_panel_style)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var row := HBoxContainer.new()
	_row=row
	row.add_theme_constant_override("separation",18)
	add_child(row)
	_portrait_slot = Control.new()
	_portrait_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(_portrait_slot)
	_portrait_frame = TextureRect.new()
	_portrait_frame.texture = HudArt.texture("portrait-frame")
	_portrait_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_frame.stretch_mode = TextureRect.STRETCH_SCALE
	_portrait_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.anchor_top = 1.0
	_portrait_frame.anchor_bottom = 1.0
	_portrait_slot.add_child(_portrait_frame)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.anchor_top = 1.0
	portrait.anchor_bottom = 1.0
	_portrait_slot.add_child(portrait)
	portrait.hide()
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
	nameplate.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var name_style := StyleBoxFlat.new()
	name_style.bg_color = Color("f0dab0")
	name_style.border_color = Color("8a5a2b")
	name_style.set_border_width_all(2)
	name_style.content_margin_left = 8
	name_style.content_margin_right = 8
	name_style.content_margin_top = 2
	name_style.content_margin_bottom = 2
	nameplate.add_theme_stylebox_override("normal",name_style)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation",8)
	column.add_child(name_row)
	name_row.add_child(nameplate)
	_scroll_hint = Label.new()
	_scroll_hint.text = "↓ Gulir teks"
	_scroll_hint.add_theme_font_override("font",BODY)
	_scroll_hint.add_theme_color_override("font_color",Color("795c3c"))
	_scroll_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll_hint.hide()
	name_row.add_child(_scroll_hint)
	_message_row = HBoxContainer.new()
	_message_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_message_row)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_FILL
	_scroll.follow_focus = true
	_message_row.add_child(_scroll)
	_scroll.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)
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
	_message_row.add_child(next_button)
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
	nameplate.add_theme_color_override("font_color",SPEAKER_INK.get(_speaker,Color("654733")))
	text_view.text = formatted(text)
	_total = text.replace("**","").length()
	_revealed = 0.0
	text_view.visible_characters = -1 if EnvironmentState.reduced_motion else 0
	portrait.texture = _portrait(_speaker)
	portrait.visible = portrait.texture != null
	_portrait_slot.visible = portrait.visible
	_scroll.scroll_vertical = 0
	_layout()
	_schedule_layout()
	_pop_portrait()
	_refresh_scroll_hint.call_deferred()
	next_button.grab_focus()

func _pop_portrait() -> void:
	if _portrait_tween and _portrait_tween.is_running(): _portrait_tween.kill()
	portrait.scale = Vector2.ONE
	portrait.rotation = 0.0
	_emote.scale = Vector2.ONE*preload("res://scripts/UiMetrics.gd").ratio(self)
	if EnvironmentState.reduced_motion or not portrait.visible: return
	portrait.pivot_offset = portrait.size*Vector2(.5,.83)
	portrait.scale = Vector2(.78,1.12) if _emotion in ["shock","angry"] else Vector2(.88,1.05)
	_portrait_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_portrait_tween.tween_property(portrait,"scale",Vector2.ONE,.29)

func _portrait(speaker: String) -> Texture2D:
	if speaker=="Pak Ranto": return RANTO_PORTRAIT
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
	var gap:=ceilf(4*ratio)
	_compact_layout=compact
	_panel_style.content_margin_left=padding.x
	_panel_style.content_margin_right=padding.x
	_panel_style.content_margin_top=padding.y
	_panel_style.content_margin_bottom=padding.y
	_row.add_theme_constant_override("separation",ceili(8*ratio))
	_column.add_theme_constant_override("separation",int(gap))
	_message_row.add_theme_constant_override("separation",ceili(6*ratio))
	_scroll_hint.add_theme_font_size_override("font_size",ceili(14*ratio))
	if portrait_screen and next_button.get_parent()!=_column:
		next_button.reparent(_column)
	elif not portrait_screen and next_button.get_parent()!=_message_row:
		next_button.reparent(_message_row)
	nameplate.add_theme_font_size_override("font_size",title_size)
	text_view.add_theme_font_size_override("normal_font_size",font_size)
	next_button.custom_minimum_size=Vector2(ceilf(112*ratio),ceilf(48*ratio))
	next_button.size_flags_horizontal=Control.SIZE_SHRINK_END
	next_button.add_theme_font_size_override("font_size",font_size)
	HudArt.apply_button(next_button)
	HudArt.set_icon(next_button,"interact-hand",28)
	var portrait_side:=ceilf((84 if portrait_screen else 124 if compact else 156)*ratio)
	var frame_side:=ceilf((68 if portrait_screen else 92 if compact else 112)*ratio)
	_portrait_slot.custom_minimum_size=Vector2(portrait_side,0)
	_portrait_slot.visible=portrait.visible
	_portrait_frame.offset_left=ceilf(8*ratio)
	_portrait_frame.offset_right=_portrait_frame.offset_left+frame_side
	_portrait_frame.anchor_top=0.0 if portrait_screen or not compact else 1.0
	_portrait_frame.anchor_bottom=_portrait_frame.anchor_top
	_portrait_frame.offset_top=ceilf(8*ratio) if portrait_screen or not compact else -frame_side
	_portrait_frame.offset_bottom=_portrait_frame.offset_top+frame_side
	portrait.offset_left=0
	portrait.offset_right=portrait_side
	portrait.anchor_top=0.0 if portrait_screen or not compact else 1.0
	portrait.anchor_bottom=portrait.anchor_top
	portrait.offset_top=-maxf(ceilf(40*ratio),padding.y+ceilf(16*ratio)) if portrait_screen or not compact else -portrait_side
	portrait.offset_bottom=portrait.offset_top+portrait_side
	_emote.position=Vector2(portrait_side-25*ratio,-8*ratio)
	_emote.scale=Vector2.ONE*ratio
	var width:=minf(ceilf(1040*ratio),view.x-ceilf(32*ratio)-insets.x-insets.z)
	var name_available:float=width-padding.x*2-(portrait_side+ceilf(8*ratio) if portrait.visible else 0)
	nameplate.custom_minimum_size.x=minf(name_available,ceilf(nameplate.get_theme_font("font").get_string_size(nameplate.text,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x+20*ratio))
	_scroll_hint.set_meta("has_space",name_available-nameplate.custom_minimum_size.x>=ceilf(94*ratio))
	var text_width:=maxf(80,width-padding.x*2-(portrait_side+ceilf(8*ratio) if portrait.visible else 0)-(next_button.custom_minimum_size.x+ceilf(6*ratio) if not portrait_screen else 0))
	var title_height:=nameplate.get_theme_font("font").get_multiline_string_size(nameplate.text,HORIZONTAL_ALIGNMENT_LEFT,nameplate.custom_minimum_size.x-ceilf(20*ratio),title_size).y+ceilf(4*ratio)
	var line_height:=ceilf(BODY.get_height(font_size))
	var body_height:=maxf(line_height,BODY.get_multiline_string_size(text_view.get_parsed_text(),HORIZONTAL_ALIGNMENT_LEFT,text_width,font_size).y+2)
	var available:=view.y-ceilf(60*ratio)-ceilf(16*ratio)-insets.y-insets.w
	var maximum:=minf(available,view.y*(.30 if portrait_screen else .32))
	var action_height:=next_button.custom_minimum_size.y
	var fixed_height:float=title_height+padding.y*2+gap+(action_height+gap if portrait_screen else 0)
	var body_limit:=maxf(line_height,minf((72 if portrait_screen else 64)*ratio,maximum-fixed_height))
	var body_target:=maxf(line_height,minf(body_limit,maxf(body_height,action_height if not portrait_screen else line_height)))
	var visible_body:=maxf(line_height,floorf(body_target/line_height)*line_height)
	_scroll.custom_minimum_size.y=visible_body
	_scroll.size_flags_vertical=Control.SIZE_FILL
	var h:=maxf(minf(maximum,fixed_height+maxf(visible_body,action_height if not portrait_screen else 0)),get_combined_minimum_size().y)
	size=Vector2(width,h)
	position=Vector2(insets.x+(view.x-insets.x-insets.z-width)/2,view.y-h-ceilf(8*ratio)-insets.w)

func _schedule_layout() -> void:
	if _layout_pending: return
	_layout_pending=true
	_finish_layout.call_deferred()

func _finish_layout() -> void:
	_layout_pending=false
	if is_inside_tree():
		_layout()
		_refresh_scroll_hint()

func _on_scroll_changed(_value:float) -> void:
	_refresh_scroll_hint()

func _refresh_scroll_hint() -> void:
	if not is_instance_valid(_scroll_hint) or not is_instance_valid(_scroll): return
	var bar:=_scroll.get_v_scroll_bar()
	_scroll_hint.visible=bool(_scroll_hint.get_meta("has_space",false)) and bar.max_value-bar.page-_scroll.scroll_vertical>1.0

func advance() -> void:
	AudioManager.play_sfx("wooden_click_light",1.0,-8.0)
	if text_view.visible_characters>=0 and text_view.visible_characters<_total:
		text_view.visible_characters = -1
		return
	advance_requested.emit()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventKey: return
	if event.pressed and not event.echo and event.physical_keycode in [KEY_SPACE,KEY_ENTER]:
		advance()
		get_viewport().set_input_as_handled()
	elif event.pressed and event.physical_keycode in [KEY_DOWN,KEY_UP,KEY_PAGEDOWN,KEY_PAGEUP]:
		var sign:=1 if event.physical_keycode in [KEY_DOWN,KEY_PAGEDOWN] else -1
		var step:=_scroll.size.y*.8 if event.physical_keycode in [KEY_PAGEDOWN,KEY_PAGEUP] else BODY.get_height(text_view.get_theme_font_size("normal_font_size"))
		_scroll.scroll_vertical=clampi(_scroll.scroll_vertical+roundi(sign*step),0,maxi(0,roundi(_scroll.get_v_scroll_bar().max_value-_scroll.get_v_scroll_bar().page)))
		_refresh_scroll_hint()
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
			AudioManager.play_sfx("wooden_click_light",float(SPEAKER_BLIP_PITCH.get(_speaker,1.0)),-28)
	if count>=_total: text_view.visible_characters = -1

func debug_state() -> Dictionary:
	return {"speaker":_speaker,"emotion":_emotion,"visibleCharacters":text_view.visible_characters,"total":text_view.get_total_character_count(),"portrait":portrait.texture!=null,"position":[position.x,position.y],"size":[size.x,size.y],"compact":_compact_layout}
