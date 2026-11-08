extends Node2D

const WATER_SHADER = preload("res://scripts/surface-water.gdshader")
var _area := "hub"
var _extent := Vector2(2400,1600)
var _raster: Texture2D
var _image: Image
var _mask: Image
var _mask_texture: ImageTexture
var _material: ShaderMaterial
var _elapsed := 0.0
var _water_pixels := 0
var _reduced := false
static var _masks: Dictionary = {}

# Source-image coordinates, not walkability: paths do not describe the shoreline.
const REGIONS := {
	"hub": [
		[[0,780],[70,770],[270,790],[480,840],[600,780],[840,775],[1090,800],[1260,765],[1370,745],[1536,730],[1536,1024],[0,1024]],
		[[1536,270],[1485,288],[1460,420],[1450,520],[1360,590],[1420,755],[1536,755]],
	],
	"forest": [
		[[0,835],[150,880],[310,965],[535,1024],[0,1024]],
		[[800,280],[970,320],[1020,370],[850,408],[730,405],[735,350]],
		[[1170,90],[1360,50],[1400,300],[1536,390],[1536,480],[1300,350],[1180,260]],
	],
}
const EXCLUSIONS := {
	"hub": [
		[[475,745],[870,730],[1010,790],[1020,970],[900,970],[890,890],[510,960],[465,925]],
		[[0,805],[400,805],[435,985],[0,1015]],
		[[1370,275],[1450,265],[1460,420],[1536,495],[1536,580],[1370,465]],
	],
	"forest": [
		[[1100,145],[1460,145],[1460,240],[1100,240]],
	],
}

func configure(area: String, extent: Vector2, raster: Texture2D = null) -> void:
	_area = area
	_extent = extent
	_raster = raster
	if _raster == null:
		var path := "res://resources/art/forest-muara.png" if area == "forest" else "res://resources/art/coastal-village-map.png"
		if ResourceLoader.exists(path): _raster = load(path)
	if _raster == null or not REGIONS.has(_area): return
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_water_pixels = 0
	_image = _raster.get_image()
	if _image.is_compressed(): _image.decompress()
	_build_mask()
	_material = ShaderMaterial.new()
	_material.shader = WATER_SHADER
	_material.set_shader_parameter("region_mask",_mask_texture)
	_material.set_shader_parameter("raster_texture",_raster)
	_material.set_shader_parameter("raster_texel",Vector2.ONE/_raster.get_size())
	_material.set_shader_parameter("river",area == "forest")
	material = _material
	_update_parameters()
	queue_redraw()

func _polygon(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points: result.append(Vector2(float(point[0]),float(point[1])))
	return result

func _build_mask() -> void:
	if _masks.has(_area):
		_mask = _masks[_area].image
		_mask_texture = _masks[_area].texture
		_water_pixels = int(_masks[_area].pixels)
		return
	var regions: Array[PackedVector2Array] = []
	var exclusions: Array[PackedVector2Array] = []
	for points in REGIONS[_area]: regions.append(_polygon(points))
	for points in EXCLUSIONS[_area]: exclusions.append(_polygon(points))
	_mask = Image.create(384,256,false,Image.FORMAT_L8)
	_mask.fill(Color.BLACK)
	for y in range(256):
		for x in range(384):
			var point := Vector2((x+0.5)*4,(y+0.5)*4)
			var inside := false
			for polygon in regions:
				if Geometry2D.is_point_in_polygon(point,polygon):
					inside = true
					break
			if not inside: continue
			for polygon in exclusions:
				if Geometry2D.is_point_in_polygon(point,polygon):
					inside = false
					break
			if inside:
				_mask.set_pixel(x,y,Color.WHITE)
				_water_pixels += 1
	_mask_texture = ImageTexture.create_from_image(_mask)
	_masks[_area] = {"image":_mask,"texture":_mask_texture,"pixels":_water_pixels}

func _process(delta: float) -> void:
	_elapsed += minf(delta,0.1)
	_update_parameters()

func set_time(seconds: float) -> void:
	_elapsed = maxf(seconds,0)
	_update_parameters()

func _update_parameters() -> void:
	if _material == null: return
	var state := get_node_or_null("/root/EnvironmentState")
	var weather: Dictionary = state.snapshot() if state else {}
	_reduced = bool(weather.get("reduced_motion",false))
	_material.set_shader_parameter("phase",_elapsed)
	_material.set_shader_parameter("motion",0.12 if _reduced else 1.0)
	_material.set_shader_parameter("sea_state",clampf(float(weather.get("sea_state",0.3)),0,1))
	_material.set_shader_parameter("daylight",clampf(float(weather.get("daylight",0.9)),0,1))
	_material.set_shader_parameter("rain",clampf(float(weather.get("rain",0)),0,1))
	_material.set_shader_parameter("flow",Vector2(float(weather.get("current_x",7)),float(weather.get("current_y",0)))/20.0)

func sample_is_water(point: Vector2) -> bool:
	if _image == null or not Rect2(Vector2.ZERO,_extent).has_point(point): return false
	var uv := point/_extent
	var pixel := Vector2i(clampi(int(uv.x*_image.get_width()),0,_image.get_width()-1),clampi(int(uv.y*_image.get_height()),0,_image.get_height()-1))
	var cell := Vector2i(clampi(int(uv.x*384),0,383),clampi(int(uv.y*256),0,255))
	if _mask.get_pixelv(cell).r < 0.5: return false
	var color := _image.get_pixelv(pixel)
	return color.g > 0.12 and color.r < color.g*0.88 and color.b > color.g*0.62 and color.b > color.r*1.06

func debug_status() -> Dictionary:
	return {"active":_material != null,"area":_area,"phase":_elapsed,"regionCells":_water_pixels,"maskResolution":[384,256],"reducedMotion":_reduced,"refractionMaxTexels":0.24 if _reduced else 2.0,"geometryChanged":false}

func _draw() -> void:
	if _raster != null and _material != null:
		draw_texture_rect(_raster,Rect2(Vector2.ZERO,_extent),false)
