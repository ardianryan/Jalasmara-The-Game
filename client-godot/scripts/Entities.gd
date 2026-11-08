extends Node2D
const WildlifeScript = preload("res://scripts/Wildlife.gd")
var wildlife: Node2D
var elapsed := 0.0
var player: Node2D
var nearest := ""
var boss_texture: Texture2D
var props_atlas: Texture2D
func _ready() -> void:
	wildlife = WildlifeScript.new()
	wildlife.z_index = 0
	add_child(wildlife)
	if ResourceLoader.exists("res://resources/art/ocean-props-atlas.png"):
		props_atlas = load("res://resources/art/ocean-props-atlas.png")
	if ResourceLoader.exists("res://resources/art/gajah-mina.png"):
		boss_texture = load("res://resources/art/gajah-mina.png")
func _process(delta: float) -> void:
	elapsed += delta
	if wildlife:
		wildlife.player = player
	queue_redraw()
func _draw() -> void:
	if not player:
		return
	var state = GameState
	var at: Vector2 = player.position
	if state.dive.is_empty():
		return
	for item in state.world.get("landmarks",[]):
		var p := Vector2(float(item.x),float(item.y))
		if p.distance_to(at)>800:
			continue
		var found: bool = state.adventure.get("discoveries",[]).has(item.id)
		var variation := float(posmod(hash(str(item.id)),3))
		_draw_prop(0,p+Vector2(0,18),Vector2(91+variation*8,110+variation*6),Color(0.87,0.98,0.91) if found else Color.WHITE)
	for item in state.world.get("puzzles",[]):
		var p := Vector2(float(item.x),float(item.y))
		if p.distance_to(at)>800:
			continue
		var done: bool = state.adventure.get("puzzles",[]).has(item.id)
		var kind := str(item.get("kind","light"))
		var index := 1 if kind=="valve" else 2 if kind=="filter" else 3
		var dimensions := Vector2(140,135) if index==1 else Vector2(127,162) if index==2 else Vector2(152,139)
		_draw_prop(index,p+Vector2(0,18),dimensions,Color(0.83,1.0,0.89) if done else Color.WHITE)
	for item in state.world.get("caches",[]):
		var p := Vector2(float(item.x),float(item.y))
		if p.distance_to(at)>800:
			continue
		var opened: bool = state.adventure.get("discoveries",[]).has(item.id)
		if props_atlas != null:
			_draw_prop(7,p+Vector2(0,12),Vector2(95,91),Color(0.8,0.87,0.84,0.55) if opened else Color.WHITE)
		else:
			var icon: Texture2D = preload("res://scripts/ItemIcons.gd").texture("cache")
			draw_texture_rect(icon,Rect2(p-Vector2(26,26),Vector2(52,52)),false,Color(1,1,1,.45 if opened else 1))
	for hazard in state.world.get("hazards",[]):
		var hp := Vector2(float(hazard.x),float(hazard.y))
		if hp.distance_to(at)>850:
			continue
		var radius := float(hazard.radius)
		if hazard.kind=="urchin":
			_draw_prop(4,hp,Vector2.ONE*radius*2.0)
		else:
			_draw_prop(5,hp+Vector2(-13,12),Vector2(122,132))
			for i in range(8):
				var age := fmod(elapsed*0.22+i*0.137,1.0)
				var center := hp+Vector2(sin(elapsed*0.4+i)*radius*0.28,-age*120)
				draw_circle(center,6+age*13,Color(0.46,0.40,0.62,(1.0-age)*0.075))
	var target_index := 0
	for target in state.dive.get("targets",[]):
		var available: bool = state.dive.get("mode","")!="boss" or ((target_index<ceili(float(state.dive.get("requiredHits",6))/2.0))==(int(state.dive.get("hits",0))<ceili(float(state.dive.get("requiredHits",6))/2.0)))
		target_index += 1
		if target.get("caught",false) or not available:
			continue
		var p := target_position(target)
		if p.distance_to(at)>750:
			continue
		if state.dive.get("mode", "") == "boss":
			draw_circle(p, 9 + sin(elapsed * 2) * 2, Color("9cdbcc"))
			draw_arc(p, 16, elapsed, elapsed + PI * 1.5, 16, Color("d8c78e"), 2)
		else:
			var species := _target_species(target)
			var seed_phase := float(posmod(hash(str(target.id)), 1000)) / 100.0
			var before := target_position(target, -0.04)
			var facing := 1.0 if p.x >= before.x else -1.0
			var size := 58.0 if species == 0 else 65.0
			WildlifeScript.draw_creature(self, null, p, species, size, facing, elapsed * 7 + seed_phase)
		if str(target.id)==nearest:
			var bracket := Color("f0d48a")
			for side in [-1, 1]:
				draw_line(p + Vector2(side * 39, -15), p + Vector2(side * 39, 15), bracket, 2)
				draw_line(p + Vector2(side * 39, -15), p + Vector2(side * 30, -15), bracket, 2)
				draw_line(p + Vector2(side * 39, 15), p + Vector2(side * 30, 15), bracket, 2)
	if state.player.get("progress",{}).get("day",1)>=3:
		var bp := Vector2(3820,3140)
		if bp.distance_to(at)<1000:
			var recovered: bool = state.player.get("progress",{}).get("bossDefeated",false)
			if boss_texture:
				draw_texture_rect(boss_texture,Rect2(bp-Vector2(210,145),Vector2(420,280)),false,Color(1,1,1,.6 if recovered else 1))
			else:
				draw_ellipse_shape(bp,recovered)
func _draw_prop(index: int,at: Vector2,dimensions: Vector2,tint := Color.WHITE) -> void:
	if props_atlas == null:
		return
	var cell := props_atlas.get_size()/Vector2(4,2)
	var source := Rect2(Vector2(index%4,floori(float(index)/4.0))*cell,cell)
	draw_texture_rect_region(props_atlas,Rect2(at-dimensions/2.0,dimensions),source,tint)

func draw_ellipse_shape(p: Vector2, recovered: bool) -> void:
	draw_colored_polygon(PackedVector2Array([p+Vector2(-160,-35),p+Vector2(-90,-70),p+Vector2(80,-55),p+Vector2(170,0),p+Vector2(80,65),p+Vector2(-80,65),p+Vector2(-160,20)]),Color("49746b") if recovered else Color("36554d"))
	draw_rect(Rect2(p+Vector2(-180,-45),Vector2(70,95)),Color("6b8772"))
	draw_rect(Rect2(p+Vector2(-190,15),Vector2(24,95)),Color("6b8772"))
	draw_rect(Rect2(p+Vector2(-160,-55),Vector2(38,22)),Color("a0d5c4"))
	draw_rect(Rect2(p+Vector2(-162,-25),Vector2(10,5)),Color("efce8e"))

func _target_species(target: Dictionary) -> int:
	var fragment := str(target.get("fragmentId", ""))
	if fragment.contains("klorofil") or fragment.contains("sel"):
		return 0
	if fragment.contains("rasio") or fragment.contains("osmosis"):
		return 4
	if fragment.contains("filtrasi") or fragment.contains("zeolit"):
		return 3
	return 1 if str(target.get("subject", "")) == "Lingkungan" else 2

func target_position(target: Dictionary, time_offset: float = 0.0) -> Vector2:
	var anchor := Vector2(float(target.x), float(target.y))
	if GameState.dive.get("mode", "") == "boss":
		return anchor
	var phase := float(posmod(hash(str(target.get("id", ""))), 1000)) / 100.0
	var time := elapsed + time_offset
	var species := _target_species(target)
	var amplitude := Vector2(8,17) if species == 0 else Vector2(10,5) if species == 4 else Vector2(9,2) if species == 3 else Vector2(22,8)
	var frequency := 0.42 if species == 0 else 0.32 if species in [3,4] else 0.65
	var offset := Vector2(sin(time * frequency + phase) * amplitude.x, cos(time * frequency * 1.3 + phase) * amplitude.y)
	if is_instance_valid(player):
		var away := anchor - player.position
		var distance := away.length()
		if distance > 0.1 and distance < 160:
			offset += away.normalized() * (1 - distance / 160) * 9
	if offset.length() > 30:
		offset = offset.normalized() * 30
	var point := anchor + offset
	if is_instance_valid(wildlife) and wildlife._blocked(point, 12.0):
		return anchor
	return point
