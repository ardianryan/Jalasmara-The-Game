extends Control

class RoundMask extends Control:
	func _draw() -> void:
		draw_circle(size/2,minf(size.x,size.y)/2,Color.WHITE)

var map: GeoMap
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var mask:=RoundMask.new()
	mask.position=Vector2(10,10)
	mask.size=Vector2(108,108)
	mask.clip_children=CanvasItem.CLIP_CHILDREN_ONLY
	mask.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(mask)
	map=GeoMap.new()
	map.mini=true
	map.size=mask.size
	mask.add_child(map)
	var rim:=TextureRect.new()
	rim.texture=preload("res://scripts/HudSkin.gd").texture("minimap-rim")
	rim.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	rim.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	rim.size=Vector2(128,128)
	rim.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(rim)
