extends RefCounted

const ROOT := "res://resources/art/hud-bahari-v1/"
const CREAM := Color("f4ebd9")
const INK := Color("302d2a")
static var _textures: Dictionary = {}

static func texture(filename: String) -> Texture2D:
	if _textures.has(filename): return _textures[filename]
	var path := ROOT+filename+".png"
	if not ResourceLoader.exists(path): return null
	var result := load(path) as Texture2D
	if result != null: _textures[filename] = result
	return result

static func _frame(filename: String,border: float,padding: Vector2,fallback: Color) -> StyleBox:
	var art := texture(filename)
	var style: StyleBox
	if art != null:
		var nine := StyleBoxTexture.new()
		nine.texture = art
		for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: nine.set_texture_margin(side,border)
		nine.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		nine.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		style = nine
	else:
		# Allows source-only checks before the generated art has been imported.
		var plain := StyleBoxFlat.new()
		plain.bg_color = fallback
		plain.border_color = Color("bb9052")
		plain.set_border_width_all(2)
		style = plain
	style.content_margin_left = padding.x
	style.content_margin_right = padding.x
	style.content_margin_top = padding.y
	style.content_margin_bottom = padding.y
	return style

static func panel(kind := "dark") -> StyleBox:
	if kind=="dialogue": return _frame("dialogue-frame",20,Vector2(32,28),Color("362419"))
	return _frame("panel-paper" if kind in ["paper","parchment"] else "panel-dark",16,Vector2(22,16),Color("f1e1bc") if kind in ["paper","parchment"] else Color("362419"))

static func button(state := "normal",_kind := "dark") -> StyleBox:
	if state=="focus":
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = Color("ffe3a0")
		focus.set_border_width_all(3)
		focus.expand_margin_left = -4
		focus.expand_margin_right = -4
		focus.expand_margin_top = -4
		focus.expand_margin_bottom = -4
		return focus
	var styled := _frame("button-"+state,8,Vector2(14,10),Color("543b28"))
	if state=="hover" and styled is StyleBoxTexture:
		styled.modulate_color=Color(.60,.60,.60)
	return styled

static func slot() -> StyleBox:
	return _frame("slot",8,Vector2(14,10),Color("543b28"))

static func apply_button(control: Button,kind := "dark") -> void:
	control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for state in ["normal","hover","pressed","focus","disabled"]:
		control.add_theme_stylebox_override(state,button("normal" if state=="disabled" else state,kind))
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
		control.add_theme_color_override(state,CREAM)
	control.add_theme_color_override("font_disabled_color",Color("b9ad99"))
	control.add_theme_color_override("font_outline_color",Color("231710"))
	control.add_theme_constant_override("outline_size",1)

static func icon(name: String) -> Texture2D:
	var aliases := {"bag":"satchel","oxygen":"oxygen-tank","net":"jala-net","quest":"quest-scroll"}
	return texture("icon-"+str(aliases.get(name,name)))

static func set_icon(control: Button,name: String,max_width := 32) -> void:
	control.icon = icon(name)
	control.expand_icon = true
	control.add_theme_constant_override("icon_max_width",max_width)
	control.add_theme_constant_override("h_separation",8)

static func assets_ready() -> bool:
	for filename in ["panel-dark","panel-paper","button-normal","button-hover","button-pressed","button-selected","slot"]:
		if texture(filename)==null: return false
	return true
