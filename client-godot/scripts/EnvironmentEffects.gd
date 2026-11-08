extends Node

class WeatherCanvas extends Node2D:
	var area := "hub"
	var rain := 0.0
	var daylight := 1.0
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
		if area == "sea":
			for i in range(3):
				var x := dimensions.x*(0.17+float(i)*0.29)+sin(elapsed*0.12+float(i))*12.0
				var polygon := PackedVector2Array([Vector2(x,0),Vector2(x+24,0),Vector2(x+170,dimensions.y*0.8),Vector2(x+60,dimensions.y*0.8)])
				draw_colored_polygon(polygon,Color(0.65,0.88,0.74,0.028*daylight))
		if area != "sea" and rain>0.015:
			var count := mini(56,int(56*rain/0.6))
			for i in range(count):
				var seed_value := float(i)
				var x := fposmod(seed_value*137.0+elapsed*18.0,dimensions.x+20.0)-10.0
				var y := fposmod(seed_value*79.0+elapsed*(185.0+fmod(seed_value,5.0)*13.0),dimensions.y+20.0)-10.0
				draw_line(Vector2(x,y),Vector2(x-2.5,y+9.0),Color(0.77,0.87,0.82,0.13+rain*0.22),1.0)
				var impact_phase := fposmod(elapsed*1.2+seed_value*0.37,1.0)
				if i<12 and impact_phase<0.3:
					var impact := Vector2(fposmod(seed_value*151.0+43.0,dimensions.x),dimensions.y*(0.74+fmod(seed_value,4.0)*0.055))
					draw_set_transform(impact,0.0,Vector2(1.0,0.3))
					draw_arc(Vector2.ZERO,1.0+impact_phase*11.0,0,TAU,10,Color(0.72,0.88,0.8,(1.0-impact_phase/0.3)*rain*0.3),1.0)
					draw_set_transform(Vector2.ZERO)
		var particles := 16 if area=="sea" else 12 if area=="forest" else 6
		for i in range(particles):
			var seed_value := float(i)
			var at := Vector2(fposmod(seed_value*153.0+elapsed*3.0,dimensions.x),fposmod(seed_value*97.0-elapsed*4.0,dimensions.y))
			at.x += sin(elapsed*0.4+seed_value)*6.0
			var color := Color(0.74,0.93,0.85,0.17) if area=="sea" else Color(0.95,0.83,0.52,(1.0-daylight)*0.35)
			if color.a>0.015:
				draw_circle(at,1.0,color)
		if lens_time>0.0:
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
		target = target.darkened(clouds*0.075)
	_tint = _tint.lerp(target,1.0-exp(-delta*1.8))
	if is_instance_valid(_modulate):
		_modulate.color = _tint
	if is_instance_valid(_water_material):
		_water_material.set_shader_parameter("daylight",daylight)
	if is_instance_valid(_canvas):
		_canvas.rain = float(data.get("rain",0.0))
		_canvas.daylight = daylight
