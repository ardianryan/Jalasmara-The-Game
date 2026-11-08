extends Node

class WeatherCanvas extends Node2D:
	var area := "hub"
	var rain := 0.0
	var daylight := 1.0
	var wind := 9.0
	var reduced_motion := false
	var elapsed := 0.0
	var drops: Array[Dictionary] = []
	var splash_cooldown := 0.0
	var lens_time := 0.0

	func _process(delta: float) -> void:
		elapsed += delta
		lens_time = maxf(0.0,lens_time-delta)
		splash_cooldown = maxf(0.0,splash_cooldown-delta)
		for i in range(drops.size()-1,-1,-1):
			drops[i].age += delta
			if float(drops[i].age)>=0.7:
				drops.remove_at(i)
		queue_redraw()

	func splash(point: Vector2) -> void:
		if splash_cooldown>0.0:
			return
		splash_cooldown = 0.12
		lens_time = 1.5
		while drops.size()>15:
			drops.pop_front()
		drops.append({"at":point,"age":0.0,"ripple":true,"velocity":Vector2.ZERO})
		for i in range(8):
			var angle := PI+float(i)/7.0*PI
			drops.append({"at":point,"age":0.0,"ripple":false,"velocity":Vector2(cos(angle)*64,sin(angle)*72-18)})

	func _draw() -> void:
		var dimensions := get_viewport_rect().size
		if area != "sea" and rain>0.015:
			var count := mini(20 if reduced_motion else 56,int(56*rain/0.6))
			for i in range(count):
				var seed_value := float(i)
				var x := fposmod(seed_value*137.0+elapsed*wind,dimensions.x+20.0)-10.0
				var y := fposmod(seed_value*79.0+elapsed*(185.0+fmod(seed_value,5.0)*13.0),dimensions.y+20.0)-10.0
				draw_line(Vector2(x,y),Vector2(x-wind*0.20,y+14.0),Color(0.77,0.87,0.82,0.22+rain*0.45),1.0)
		var particles := 0 if area=="sea" else 4 if reduced_motion else 12 if area=="forest" else 6
		for i in range(particles):
			var seed_value := float(i)
			var at := Vector2(fposmod(seed_value*153.0+elapsed*3.0,dimensions.x),fposmod(seed_value*97.0-elapsed*4.0,dimensions.y))
			at.x += sin(elapsed*0.4+seed_value)*6.0
			var color := Color(0.74,0.93,0.85,0.17) if area=="sea" else Color(0.95,0.83,0.52,(1.0-daylight)*0.35)
			if color.a>0.015:
				draw_circle(at,1.0,color)
		if lens_time>0.0 and not reduced_motion:
			var opacity := minf(1.0,lens_time/0.5)*0.28
			for i in range(3):
				var point := Vector2(18.0+float(i%2)*22.0,dimensions.y*(0.16+float(i)*0.15)+(1.5-lens_time)*8.0)
				if i==2:
					point.x = dimensions.x-19.0
				var radius := 2.5+float(i)*0.8
				draw_circle(point,radius,Color(0.7,0.9,0.82,opacity*0.25))
				draw_arc(point,radius,PI*0.9,PI*1.9,12,Color(0.84,0.96,0.92,opacity),1.0)
		for drop in drops:
			var age := float(drop.age)
			var alpha := maxf(0.0,1.0-age/0.7)
			if bool(drop.ripple):
				draw_set_transform(drop.at,0.0,Vector2(1.0,0.28))
				draw_arc(Vector2.ZERO,5.0+age*44.0,0,TAU,24,Color(0.75,0.94,0.85,alpha*0.7),1.5)
				draw_set_transform(Vector2.ZERO)
			else:
				var position: Vector2 = drop.at+drop.velocity*age+Vector2(0,120.0*age*age)
				draw_circle(position,1.6,Color(0.78,0.95,0.88,alpha*0.9))

var _area := "hub"
var _modulate: CanvasModulate
var _canvas: WeatherCanvas
var _layer: CanvasLayer
var _tint := Color.WHITE
var _water_layer: CanvasLayer
var _water_rect: ColorRect
var _water_material: ShaderMaterial
var _depth := 0.0
var _pixel_fx: Node2D
var _impact_clock := 0.0
var _impact_sequence := 0
var _rain_impact_count := 0
var _foliage: Array[Dictionary] = []
var _foliage_scan_clock := 3.0

func configure(area: String) -> void:
	_area = area if area in ["hub","forest","sea"] else "hub"
	if is_instance_valid(_canvas):
		_canvas.area = _area
	if is_instance_valid(_water_layer):
		_water_layer.visible = _area=="sea"

func update_depth(depth_m: float) -> void:
	_depth = maxf(0.0,depth_m)
	if is_instance_valid(_water_material):
		_water_material.set_shader_parameter("depth_m",_depth)

func _ready() -> void:
	_water_layer = CanvasLayer.new()
	_water_layer.layer = 3
	_water_layer.visible = _area=="sea"
	add_child(_water_layer)
	_water_rect = ColorRect.new()
	_water_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_water_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_water_material = ShaderMaterial.new()
	_water_material.shader = preload("res://shaders/water.gdshader")
	_water_material.set_shader_parameter("depth_m",_depth)
	_water_rect.material = _water_material
	_water_layer.add_child(_water_rect)
	_modulate = CanvasModulate.new()
	add_child(_modulate)
	_layer = CanvasLayer.new()
	_layer.layer = 5
	add_child(_layer)
	_canvas = WeatherCanvas.new()
	_canvas.area = _area
	_layer.add_child(_canvas)
	_pixel_fx = preload("res://scripts/PixelEffects.gd").new()
	_layer.add_child(_pixel_fx)

func splash(screen_point: Vector2) -> void:
	if is_instance_valid(_canvas):
		_canvas.splash(screen_point)

func _process(delta: float) -> void:
	var state := get_node_or_null("/root/EnvironmentState")
	var data: Dictionary = state.snapshot() if state != null and state.has_method("snapshot") else {"daylight":0.9,"rain":0.0,"clouds":0.0}
	var daylight := float(data.get("daylight",0.9))
	var clouds := float(data.get("clouds",0.0))
	var tint := Color(0.64,0.77,0.82) if _area=="sea" else Color(0.53,0.64,0.71)
	var target := tint.lerp(Color(1.0,0.99,0.94),daylight)
	if bool(data.get("night",false)):
		target = Color(0.31,0.43,0.54) if _area != "sea" else Color(0.24,0.40,0.49)
	if _area != "sea":
		target = target.darkened(clouds*0.12)
	_tint = _tint.lerp(target,1.0-exp(-delta*1.8))
	if is_instance_valid(_modulate):
		_modulate.color = _tint
	if is_instance_valid(_water_material):
		_water_material.set_shader_parameter("daylight",daylight)
	if is_instance_valid(_canvas):
		_canvas.rain = float(data.get("rain",0.0))
		_canvas.daylight = daylight
		_canvas.wind = float(data.get("wind_x",9.0))
		_canvas.reduced_motion = bool(data.get("reduced_motion",false))
	if is_instance_valid(_water_material):
		_water_material.set_shader_parameter("refraction_strength",0.00025 if bool(data.get("reduced_motion",false)) else 0.0015)
	_foliage_scan_clock += delta
	_impact_clock += delta
	if _impact_clock>0.4:
		_impact_clock = 0.0
		_ground_rain_impacts(data)
		_update_foliage(data)

func _ground_rain_impacts(data: Dictionary) -> void:
	if _area=="sea" or float(data.get("rain",0))<0.12 or bool(data.get("reduced_motion",false)) or not is_instance_valid(_pixel_fx): return
	if _pixel_fx.get_child_count()>8: return
	var zone: Dictionary = GameState.world.get("forest",{}) if _area=="forest" else GameState.world.get("hub",{})
	var paths: Array = zone.get("walkablePaths",[]) if _area=="forest" else zone.get("paths",[])
	if paths.is_empty(): return
	for attempt in range(6):
		_impact_sequence += 1
		var path: Array = paths[posmod(_impact_sequence,paths.size())]
		if path.size()<2: continue
		var index := posmod(_impact_sequence*3,path.size()-1)
		var a := Vector2(float(path[index][0]),float(path[index][1]))
		var b := Vector2(float(path[index+1][0]),float(path[index+1][1]))
		var fraction := fposmod(_impact_sequence*0.371,1.0)
		var point := a.lerp(b,fraction)
		var screen := get_viewport().get_canvas_transform()*point
		if get_viewport().get_visible_rect().grow(-12).has_point(screen):
			var splash: AnimatedSprite2D = _pixel_fx.add_effect("bubble-splash",screen,0.3,0,true)
			if is_instance_valid(splash):
				splash.modulate.a = float(data.get("rain",0))*0.7
				_rain_impact_count += 1
			break

func _update_foliage(data: Dictionary) -> void:
	if _foliage_scan_clock>2.0:
		_foliage_scan_clock = 0.0
		var scene := get_tree().current_scene
		if scene != null:
			var current_materials: Array[Dictionary] = []
			for item in scene.find_children("*","CanvasItem",true,false):
				var material: Material = item.material
				if not material is ShaderMaterial or material.shader == null or not material.shader.resource_path.ends_with("/foliage.gdshader"): continue
				var base := float(material.get_shader_parameter("strength"))
				for entry in _foliage:
					if entry.material==material:
						base = float(entry.base)
						break
				var known := false
				for entry in current_materials:
					if entry.material==material: known = true; break
				if not known: current_materials.append({"material":material,"base":base})
			_foliage = current_materials
	var strength := 0.12 if bool(data.get("reduced_motion",false)) else 0.65+float(data.get("wind_x",9))/40.0
	for entry in _foliage:
		var material: ShaderMaterial = entry.material
		material.set_shader_parameter("strength",clampf(float(entry.base)*strength,0.0,8.0))

func debug_status() -> Dictionary:
	return {"area":_area,"rainImpacts":_rain_impact_count,"activeImpactSprites":_pixel_fx.get_child_count() if is_instance_valid(_pixel_fx) else 0,"foliageMaterials":_foliage.size(),"depth":_depth}
