extends Node2D
var elapsed := 0.0
var font: Font = ThemeDB.fallback_font
var player: Node2D
var nearest := ""
var boss_texture: Texture2D
func _ready() -> void:
	if ResourceLoader.exists("res://resources/art/gajah-mina.png"):
		boss_texture = load("res://resources/art/gajah-mina.png")
func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
func _draw() -> void:
	if not player:
		return
	var state = GameState
	var at: Vector2 = player.position
	for district in state.world.get("surface_hub",{}).get("districts",[]):
		var p := Vector2(float(district.x),306)
		if p.distance_to(at)>850:
			continue
		_npc(p,str(district.npc))
		_label(p+Vector2(-40,-45),str(district.npc),Color("f1e6c6"))
	for item in state.world.get("landmarks",[]):
		var p := Vector2(float(item.x),float(item.y))
		if p.distance_to(at)>800:
			continue
		var found: bool = state.adventure.get("discoveries",[]).has(item.id)
		draw_rect(Rect2(p-Vector2(18,28),Vector2(36,48)),Color("466d6c"))
		draw_rect(Rect2(p-Vector2(12,23),Vector2(24,37)),Color("a3b9a0") if found else Color("88d4bf"))
		for i in range(4):
			draw_rect(Rect2(p+Vector2(-8,-17+i*7),Vector2(16-i*2,2)),Color("416967"))
		_label(p+Vector2(-70,-40),str(item.name),Color("b9e2cc"))
	for item in state.world.get("puzzles",[]):
		var p := Vector2(float(item.x),float(item.y))
		if p.distance_to(at)>800:
			continue
		var done: bool = state.adventure.get("puzzles",[]).has(item.id)
		draw_rect(Rect2(p-Vector2(42,30),Vector2(84,60)),Color("4d675b"))
		draw_rect(Rect2(p-Vector2(36,24),Vector2(72,46)),Color("263e40"))
		for i in range(3):
			draw_rect(Rect2(p+Vector2(-28+i*24,-15),Vector2(12,30)),Color("8bc5a0") if done else Color("b89762"))
		_label(p+Vector2(-75,-42),str(item.name),Color("f1d59e"))
	for item in state.world.get("caches",[]):
		var p := Vector2(float(item.x),float(item.y))
		if p.distance_to(at)>800:
			continue
		var opened: bool = state.adventure.get("discoveries",[]).has(item.id)
		draw_rect(Rect2(p-Vector2(18,12),Vector2(36,24)),Color("755b41"))
		draw_rect(Rect2(p-Vector2(19,14 if not opened else 26),Vector2(38,8)),Color("b19c6b"))
		draw_rect(Rect2(p-Vector2(3,4),Vector2(6,7)),Color("d7c58f"))
	for hazard in state.world.get("hazards",[]):
		var hp := Vector2(float(hazard.x),float(hazard.y))
		if hp.distance_to(at)>850:
			continue
		var radius := float(hazard.radius)
		if hazard.kind=="urchin":
			draw_circle(hp,radius*.45,Color("514461"))
			for i in range(16):
				var angle := i*TAU/16.0
				draw_line(hp,hp+Vector2(cos(angle),sin(angle))*radius,Color("b499b9"),3)
		else:
			for i in range(6):
				draw_circle(hp+Vector2(sin(elapsed+i)*radius*.5,cos(elapsed*.7+i)*radius*.5),radius*.45,Color(.55,.28,.65,.18))
	var target_index := 0
	for target in state.dive.get("targets",[]):
		var available: bool = state.dive.get("mode","")!="boss" or ((target_index<3)==(int(state.dive.get("hits",0))<3))
		target_index += 1
		if target.get("caught",false) or not available:
			continue
		var p := Vector2(float(target.x),float(target.y))
		if p.distance_to(at)>750:
			continue
		p.y += sin(elapsed*1.4+float(target.x)*.01)*6
		var subject := str(target.subject)
		var color := Color("90ceb1") if subject=="Biologi" else Color("80cdd3") if subject=="Lingkungan" else Color("e8c789") if subject=="Matematika" else Color("beaccc")
		if subject=="Biologi":
			draw_circle(p,13,color)
			draw_rect(Rect2(p-Vector2(14,0),Vector2(28,8)),color)
			for i in range(4):
				draw_line(p+Vector2(-9+i*6,7),p+Vector2(-9+i*6+sin(elapsed*2+i)*3,22),color,2)
		elif subject=="Matematika":
			draw_circle(p,12,color)
			draw_arc(p,7,0,TAU*1.5,16,Color("65766c"),2)
			draw_rect(Rect2(p+Vector2(-18,5),Vector2(34,7)),color)
		else:
			draw_colored_polygon(PackedVector2Array([p+Vector2(-18,0),p+Vector2(-10,-8),p+Vector2(10,-8),p+Vector2(17,0),p+Vector2(8,8),p+Vector2(-10,8)]),color)
			draw_colored_polygon(PackedVector2Array([p+Vector2(-16,0),p+Vector2(-25,-9),p+Vector2(-25,9)]),color)
			draw_rect(Rect2(p+Vector2(8,-3),Vector2(3,3)),Color("173b44"))
		if str(target.id)==nearest:
			draw_arc(p,30,0,TAU,24,Color("f0d48a"),2)
	if state.player.get("progress",{}).get("day",1)>=3:
		var bp := Vector2(3820,3140)
		if bp.distance_to(at)<1000:
			var recovered: bool = state.player.get("progress",{}).get("bossDefeated",false)
			if boss_texture:
				draw_texture_rect(boss_texture,Rect2(bp-Vector2(210,145),Vector2(420,280)),false,Color(1,1,1,.6 if recovered else 1))
			else:
				draw_ellipse_shape(bp,recovered)
			_label(bp-Vector2(150,160),"Gajah Mina · Penjaga Tamansari",Color("e8d7aa"))
func _label(p: Vector2, text: String, color: Color) -> void:
	draw_string(font,p+Vector2(1,1),text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("0a2c33"))
	draw_string(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,color)
func _npc(p: Vector2, name_text: String) -> void:
	var cloth := Color("9b704c") if name_text=="Mbah Wira" else Color("385d70") if name_text=="Beno" else Color("63875d") if name_text=="Bu Darmi" else Color("c7d2ca")
	draw_rect(Rect2(p-Vector2(7,25),Vector2(14,12)),Color("b98b62"))
	draw_rect(Rect2(p-Vector2(8,28),Vector2(16,6)),Color("7c493b") if name_text=="Beno" else Color("3b4b42"))
	draw_rect(Rect2(p-Vector2(11,11),Vector2(22,24)),cloth)
	draw_rect(Rect2(p+Vector2(-9,13),Vector2(7,11)),Color("243b40"))
	draw_rect(Rect2(p+Vector2(3,13),Vector2(7,11)),Color("243b40"))
	if name_text=="Mbah Wira":
		draw_rect(Rect2(p-Vector2(7,17),Vector2(14,8)),Color("e1debe"))
	if name_text=="Beno":
		draw_rect(Rect2(p-Vector2(8,22),Vector2(16,5)),Color("bdc8aa"))
	if name_text=="Bu Darmi":
		draw_circle(p+Vector2(-9,-4),15,Color("b39c65"))
	if name_text=="Inspektur Raka":
		draw_rect(Rect2(p-Vector2(8,22),Vector2(16,3)),Color("cb7464"))
func draw_ellipse_shape(p: Vector2, recovered: bool) -> void:
	draw_colored_polygon(PackedVector2Array([p+Vector2(-160,-35),p+Vector2(-90,-70),p+Vector2(80,-55),p+Vector2(170,0),p+Vector2(80,65),p+Vector2(-80,65),p+Vector2(-160,20)]),Color("49746b") if recovered else Color("36554d"))
	draw_rect(Rect2(p+Vector2(-180,-45),Vector2(70,95)),Color("6b8772"))
	draw_rect(Rect2(p+Vector2(-190,15),Vector2(24,95)),Color("6b8772"))
	draw_rect(Rect2(p+Vector2(-160,-55),Vector2(38,22)),Color("a0d5c4"))
	draw_rect(Rect2(p+Vector2(-162,-25),Vector2(10,5)),Color("efce8e"))
