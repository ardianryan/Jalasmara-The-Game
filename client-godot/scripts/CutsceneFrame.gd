extends Control
signal skip_requested

const BODY = preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2")
var shade: ColorRect
var upper: ColorRect
var lower: ColorRect
var title_label: Label
var shot_label: Label
var progress_label: Label
var boss_art: TextureRect
var boss_atlas: AtlasTexture
var boss_phase := 0.0
var backdrop: Texture2D
var living_plate: TextureRect
var living_material: ShaderMaterial
var backdrop_key := ""
var backdrop_time := 0.0
var motif_id := ""
var motif_beat := 0
var motif_time := 0.0
var skip_button: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade = ColorRect.new()
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	living_plate = TextureRect.new()
	living_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	living_plate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	living_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	living_plate.stretch_mode = TextureRect.STRETCH_SCALE
	living_material = ShaderMaterial.new()
	living_material.shader = preload("res://shaders/cinematic_living_plate.gdshader")
	living_plate.material = living_material
	add_child(living_plate)
	move_child(living_plate, 0)
	upper = ColorRect.new()
	upper.color = Color("161129")
	upper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upper.anchor_right = 1.0
	upper.anchor_bottom = 0.11
	add_child(upper)
	lower = ColorRect.new()
	lower.color = Color("161129")
	lower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lower.anchor_top = 0.90
	lower.anchor_right = 1.0
	lower.anchor_bottom = 1.0
	add_child(lower)
	title_label = _label(upper, 26, Color("f3c677"))
	title_label.anchor_right = 0.82
	title_label.offset_left = 24
	title_label.offset_top = 7
	skip_button = Button.new()
	skip_button.text = "Lewati"
	skip_button.add_theme_font_override("font",BODY)
	skip_button.add_theme_font_size_override("font_size",18)
	skip_button.anchor_left = 0.84
	skip_button.anchor_right = 1.0
	skip_button.offset_right = -12
	skip_button.offset_top = 4
	skip_button.offset_bottom = 52
	skip_button.pressed.connect(func(): skip_requested.emit())
	preload("res://scripts/HudSkin.gd").apply_button(skip_button)
	upper.add_child(skip_button)
	shot_label = _label(lower, 21, Color("f4ebd9"))
	shot_label.anchor_right = 0.84
	shot_label.offset_left = 24
	shot_label.offset_top = 5
	progress_label = _label(lower, 17, Color("f3c677"))
	progress_label.anchor_left = 0.85
	progress_label.anchor_right = 1.0
	progress_label.offset_right = -24
	progress_label.offset_top = 5
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	boss_art = TextureRect.new()
	boss_atlas = AtlasTexture.new()
	boss_atlas.atlas = load("res://resources/art/gajah-mina-motion-v1/swim.png")
	boss_atlas.region = Rect2(0,0,224,160)
	boss_art.texture = boss_atlas
	boss_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	boss_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	boss_art.anchor_left = 0.50
	boss_art.anchor_top = 0.12
	boss_art.anchor_right = 0.98
	boss_art.anchor_bottom = 0.68
	boss_art.modulate = Color(0.81,1.0,0.95,0.92)
	boss_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(boss_art)
	boss_art.hide()
	visible = false

func _process(delta: float) -> void:
	if not visible: return
	if EnvironmentState.reduced_motion:
		if living_plate.visible:
			living_plate.hide()
			queue_redraw()
		return
	motif_time += delta
	backdrop_time += delta
	living_material.set_shader_parameter("elapsed", backdrop_time)
	_update_living_plate()
	queue_redraw()
	if boss_art.visible:
		boss_phase += delta
		var cell := int(boss_phase*7.0)%12
		boss_atlas.region = Rect2(cell*224,0,224,160)

func _draw() -> void:
	if not visible: return
	var view := size
	if view.x<1 or view.y<1: return
	var motion := 0.0 if EnvironmentState.reduced_motion else motif_time
	if backdrop!=null:
		var source:=Vector2(backdrop.get_size())
		var scale:=maxf(view.x/source.x,view.y/source.y)*1.08
		var painted:=source*scale
		var pan:=Vector2.ZERO if EnvironmentState.reduced_motion else Vector2(sin(backdrop_time*.22)*10.0,cos(backdrop_time*.17)*5.0)
		draw_texture_rect(backdrop,Rect2((view-painted)*.5+pan,painted),false)
	if motif_id=="prologue":
		if motif_beat<=1:
			for i in range(6):
				var x:=view.x*(0.13+float(i)*0.15)
				draw_line(Vector2(x,-10),Vector2(x-90,view.y*.64),Color(1.0,.79,.42,.075),8)
		else:
			for i in range(20):
				var x:=fposmod(float(i)*79.0+motion*9.0,view.x)
				var y:=view.y*(.22+.028*float(i%12))+sin(float(i)*2.1+motion*.4)*8.0
				draw_rect(Rect2(x,y,32+float(i%3)*16,6),Color(.54,.24,.65,.12+float(i%3)*.025))
		# Foreground pollen and reflected lanterns move at different speeds.
		for i in range(14):
			var x:=fposmod(float(i)*137.0+motion*(4.0+float(i%3)*2.0),view.x)
			var y:=view.y*(0.18+float((i*7)%13)*0.053)+sin(motion*0.8+float(i)*2.7)*3.0
			draw_rect(Rect2(x,y,2.0,2.0),Color(1.0,0.82,0.42,0.36))
	if motif_id in ["first_dive","cave_warning","boss_intro","boss_phase_two"]:
		for i in range(6):
			var x:=view.x*(.12+float(i)*.16)
			draw_line(Vector2(x,-10),Vector2(x-view.x*.20,view.y*.77),Color(.31,.91,.91,.06),6)
		for i in range(22):
			var x:=fposmod(float(i)*107.0+sin(motion*.8+float(i))*9.0,view.x)
			var y:=fposmod(float(i)*67.0-motion*(12.0+float(i%5)*3.0),view.y*.8)
			draw_arc(Vector2(x,y),2.5+float(i%3),0,TAU,12,Color(.57,.95,.94,.22),1)
	if motif_id=="earthquake" and motif_beat<=2:
		var shake:=2.0 if EnvironmentState.reduced_motion else sin(motion*28.0)*4.0
		for i in range(5):
			var y:=view.y*(.20+float(i)*.12)
			draw_line(Vector2(0,y+shake),Vector2(view.x,y-shake),Color(.89,.52,.69,.07),2)
	if motif_id=="boss_phase_two" or motif_id=="victory":
		var count:=24 if motif_id=="boss_phase_two" else 38
		for i in range(count):
			var x:=fposmod(float(i)*149.0+sin(motion+float(i))*18.0,view.x)
			var y:=fposmod(float(i)*43.0-motion*(22.0+float(i%7)*5.0),view.y*.78)
			var tint:=Color(.94,.91,.73,.38) if motif_id=="boss_phase_two" else Color(.28,.98,.91,.48)
			draw_rect(Rect2(x,y,2+float(i%3),2+float(i%3)),tint)
	if motif_id=="epilogue" and motif_beat>=4:
		var center:=Vector2(view.x*.62,view.y*.36)
		var radius:=minf(view.x,view.y)*.16
		for i in range(7):
			var angle:=float(i)*TAU/7.0+motion*.10
			var point:=center+Vector2(cos(angle),sin(angle)*.55)*radius
			draw_line(center,point,Color(.24,.91,.99,.28),1)
			draw_circle(point,2.5,Color(.43,.98,1.0,.75))
		draw_arc(center,radius*.78,0,TAU,48,Color(.24,.91,.99,.34),1)
	if motif_id=="epilogue":
		for i in range(18):
			var x:=view.x*(0.50+float((i*19)%47)*0.010)
			var y:=view.y*(0.15+float((i*7)%48)*0.010)
			var pulse:=0.4+0.6*absf(sin(motion*(0.8+float(i%3)*0.2)+float(i)*1.9))
			draw_rect(Rect2(x,y,2.0,2.0),Color(0.39,0.96,0.93,0.28*pulse))

func _update_living_plate() -> void:
	if backdrop==null:
		living_plate.hide()
		return
	var source:=Vector2(backdrop.get_size())
	var scale:=maxf(size.x/source.x,size.y/source.y)*1.08
	var painted:=source*scale
	var pan:=Vector2.ZERO if EnvironmentState.reduced_motion else Vector2(sin(backdrop_time*.22)*10.0,cos(backdrop_time*.17)*5.0)
	living_plate.position=(size-painted)*.5+pan
	living_plate.size=painted
	living_plate.visible=not EnvironmentState.reduced_motion

func _label(parent: Control, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", BODY)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func present(title: String, beat: Dictionary, index: int, total: int, cinematic_id: String) -> void:
	visible = true
	var scene_key := ""
	match cinematic_id:
		"prologue", "earthquake", "first_service": scene_key = "prologue"
		"boss_intro", "boss_phase_two": scene_key = "tamansari"
		"victory": scene_key = "tamansari" if index<=2 else "epilogue"
		"epilogue": scene_key = "epilogue"
	if scene_key!=backdrop_key:
		backdrop_key = scene_key
		backdrop = load("res://resources/art/cinematics-v1/"+scene_key+".png") if not scene_key.is_empty() else null
		backdrop_time = 0.0
	living_plate.texture = backdrop
	living_material.set_shader_parameter("plate",{"prologue":1,"tamansari":2,"epilogue":3}.get(scene_key,0))
	living_material.set_shader_parameter("elapsed",backdrop_time)
	_update_living_plate()
	motif_id = cinematic_id
	motif_beat = index
	motif_time = 0.0
	title_label.text = title
	shot_label.text = str(beat.get("shot", ""))
	progress_label.text = "%d / %d" % [index, total]
	var tone := str(beat.get("tone", "warm"))
	shade.color = {"warm":Color(0.34,0.19,0.08,0.19),"plum":Color(0.22,0.06,0.29,0.34),"teal":Color(0.02,0.32,0.34,0.20),"deep":Color(0.02,0.08,0.19,0.46)}.get(tone,Color.TRANSPARENT)
	boss_art.visible = cinematic_id in ["boss_intro", "boss_phase_two", "victory"]
	if cinematic_id=="boss_intro" and index==1: boss_phase = 0.0
	queue_redraw()
