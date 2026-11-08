extends RefCounted

const Icons = preload("res://scripts/ItemIcons.gd")
const INK := Color("302d2a")
const DETAIL := Color("62533f")

static func add_rows(parent: VBoxContainer, inventory: Array) -> Array[HBoxContainer]:
	var rows: Array[HBoxContainer] = []
	for item in inventory:
		var id := str(item.get("fragmentId", ""))
		var title := GameState.fragment_name(id)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size.y = 64
		row.add_theme_constant_override("separation", 14)
		parent.add_child(row)
		var icon := TextureRect.new()
		icon.texture = Icons.texture(id)
		icon.custom_minimum_size = Vector2(48, 48)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		text.custom_minimum_size.x = 160
		text.add_theme_constant_override("separation", 5)
		row.add_child(text)
		var name_label := Label.new()
		name_label.text = title
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", INK)
		text.add_child(name_label)
		var details := Label.new()
		details.text = "Kualitas: %d bintang · Jumlah: %d" % [int(item.get("stars", 1)), int(item.get("quantity", 0))]
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_theme_font_size_override("font_size", 13)
		details.add_theme_color_override("font_color", DETAIL)
		text.add_child(details)
		rows.append(row)
	return rows
