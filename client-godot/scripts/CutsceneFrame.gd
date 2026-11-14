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
var skip_button: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade = ColorRect.new()
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
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
	boss_art.modulate = Color(0.69,0.94,0.92,0.67)
	boss_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(boss_art)
	boss_art.hide()
	visible = false

func _process(delta: float) -> void:
	if not visible or not boss_art.visible or EnvironmentState.reduced_motion: return
	boss_phase += delta
	var cell := int(boss_phase*7.0)%12
	boss_atlas.region = Rect2(cell*224,0,224,160)

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
	title_label.text = title
	shot_label.text = str(beat.get("shot", ""))
	progress_label.text = "%d / %d" % [index, total]
	var tone := str(beat.get("tone", "warm"))
	shade.color = {"warm":Color(0.34,0.19,0.08,0.19),"plum":Color(0.22,0.06,0.29,0.34),"teal":Color(0.02,0.32,0.34,0.20),"deep":Color(0.02,0.08,0.19,0.46)}.get(tone,Color.TRANSPARENT)
	boss_art.visible = cinematic_id in ["boss_intro", "boss_phase_two", "victory"]
	if cinematic_id=="boss_intro" and index==1: boss_phase = 0.0
