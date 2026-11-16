extends Control

# Code-driven screenplay accents reuse approved character atlases without adding physics.
const DIRECTED_BEATS := {
	"prologue": [2, 3, 4, 5, 6, 7, 8, 9],
	"first_dive": [1, 2],
	"first_kedai": [1],
	"first_service": [1, 2],
	"saras_visit": [2],
	"garden_crisis": [1, 2, 3],
	"cave_warning": [1, 2],
	"earthquake": [1, 3, 4],
	"boss_intro": [1, 2, 3],
	"boss_phase_two": [1, 2],
	"victory": [1, 2, 3],
	"epilogue": [1, 2, 3, 4, 5, 6, 7, 8]
}
const CHILD_ATLAS := preload("res://resources/art/village-expansion-v1/residents.png")
const NALA_DIVING := {
	"female_nusantara": preload("res://resources/art/player-gait/female-nusantara-diving-idle-8way-v1.png"),
	"female_default": preload("res://resources/art/player-gait/female-default-diving-idle-8way-v1.png"),
	"male_nusantara": preload("res://resources/art/player-gait/male-nusantara-diving-idle-8way-v1.png"),
	"male_default": preload("res://resources/art/player-gait/male-default-diving-idle-8way-v1.png")
}
const NALA_DAILY := {
	"female_nusantara": preload("res://resources/art/player-gait/female-nusantara-daily-idle-8way-v1.png"),
	"female_default": preload("res://resources/art/player-gait/female-default-daily-idle-8way-v1.png"),
	"male_nusantara": preload("res://resources/art/player-gait/male-nusantara-daily-idle-8way-v1.png"),
	"male_default": preload("res://resources/art/player-gait/male-default-daily-idle-8way-v1.png")
}
const NPC_ATLAS := preload("res://resources/art/npc-atlas.png")
const RANTO_PORTRAIT := preload("res://resources/art/cinematics-v2/pak-ranto-portrait.png")
const PhaseOneCutscenes := preload("res://scripts/PhaseOneCutscenes.gd")
const PIXEL_FONT := preload("res://resources/fonts/ark-pixel-12px-proportional-latin.otf")
const BODY_FONT := preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2")
const NPC_FACES := {
	"lurah": preload("res://resources/art/npc-facing-v2/ki_lurah_wirabhumi-front.png"),
	"raka": preload("res://resources/art/npc-facing-v2/inspektur_raka-front.png"),
	"beno": preload("res://resources/art/npc-facing-v2/beno-front.png"),
	"ratih": preload("res://resources/art/npc-facing-v2/mbok_ratih-front.png"),
	"saras": preload("res://resources/art/npc-facing-v2/saras-front.png"),
	"wira": preload("res://resources/art/npc-facing-v2/mbah_wira-front.png"),
	"tedi": preload("res://resources/art/npc-facing-v2/kang_tedi-front.png")
}
const CHILD_CELLS := {"bagas": Vector2i(1,0),"kinasih": Vector2i(2,0),"danu": Vector2i(0,1),"gito": Vector2i(1,1),"cempaka": Vector2i(2,1)}
var motif_id := ""
var motif_beat := 0
var elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func ranto_portrait_texture() -> Texture2D:
	return RANTO_PORTRAIT

func has_directed_action(id: String, beat: int) -> bool:
	return DIRECTED_BEATS.has(id) and beat in DIRECTED_BEATS[id]

func _draw() -> void:
	if not visible or size.x < 1.0 or size.y < 1.0: return
	var motion := 3.0 if EnvironmentState.reduced_motion else elapsed
	match motif_id:
		"prologue": _draw_prologue(size, motion)
		"first_dive": _draw_first_dive(size, motion)
		"first_kedai": _draw_first_kedai(size, motion)
		"first_service": _draw_service(size, motion)
		"saras_visit": _draw_saras(size, motion)
		"garden_crisis": _draw_garden(size, motion)
		"cave_warning": _draw_cave(size, motion)
		"earthquake": _draw_earthquake(size, motion)
		"boss_intro": _draw_boss_intro(size, motion)
		"boss_phase_two":
			if motif_beat == 1: _draw_fractured_pipe(size, motion)
			else: _draw_crystal(size, motion)
		"victory": _draw_victory(size, motion)
		"epilogue":
			if motif_beat <= 3: _draw_feast(size, motion)
			elif motif_beat <= 6: _draw_ancient_map(size, motion)
			else: _draw_finale(size, motion)

func _draw_arrival_boat(view: Vector2, motion: float) -> void:
	var unit:=maxf(1.0,view.y/270.0)
	var crossing:=minf(motion/6.0,1.0)
	var origin:=Vector2(view.x*(.18+crossing*.19),view.y*.53+sin(motion*2.0)*unit)
	draw_set_transform(origin,0.0,Vector2(unit,unit))
	var hull:=PackedVector2Array([Vector2(-43,0),Vector2(42,0),Vector2(33,12),Vector2(20,17),Vector2(-27,17),Vector2(-39,10)])
	draw_colored_polygon(hull,Color("41291d"))
	draw_rect(Rect2(-38,1,74,3),Color("d39a55"))
	draw_rect(Rect2(-31,5,55,3),Color("86512c"))
	draw_rect(Rect2(-20,12,40,2),Color("b16b36"))
	var stroke:=sin(motion*4.0)*5.0
	draw_line(Vector2(10,-7),Vector2(33+stroke,12),Color("f0c184"),2.0)
	draw_line(Vector2(33+stroke,12),Vector2(39+stroke,17),Color("90d8d4"),2.0)
	draw_set_transform(Vector2.ZERO)
	_draw_nala_daily(origin+Vector2(-3,1)*unit,unit*.92,4)
	_actor(Vector2(view.x*.08,view.y*.54),_unit(view),Color("9b734f"),false,0.0,"beno")
	for i in range(3):
		var wake:=origin+Vector2((-55.0-float(i)*17.0)*unit,(10.0+float(i%2)*4.0)*unit)
		draw_rect(Rect2(wake,Vector2((12.0-float(i)*2.0)*unit,unit)),Color(.48,.94,.88,.28))

func _draw_fractured_pipe(view: Vector2, motion: float) -> void:
	var unit:=maxf(1.0,view.y/270.0)
	var break_ratio:=minf(motion/1.4,1.0)
	var origin:=Vector2(view.x*.77,view.y*.22)
	for i in range(5):
		var angle:=float(i)*TAU/5.0+.18
		var end:=origin+Vector2(cos(angle),sin(angle))*(9.0+float(i%2)*5.0)*unit
		draw_line(origin+Vector2(cos(angle),sin(angle))*4*unit,end,Color(.62,.98,.94,.35*break_ratio),unit)
	for i in range(12):
		var angle:=float(i)*2.399
		var drift:=Vector2(cos(angle),sin(angle))*(6.0+break_ratio*(8.0+float(i%4)*4.0))*unit
		var shard:=origin+drift
		draw_rect(Rect2(shard,Vector2(1.0+float(i%3),2.0)*unit),Color(.76,1.0,.92,.55*break_ratio))
	for i in range(7):
		var rise:=fposmod(motion*(8.0+float(i%2)*3.0)+float(i)*10.0,57.0)
		var bubble:=origin+Vector2((-7.0-float(i%3)*5.0)*unit,-rise*unit)
		draw_arc(bubble,(1.7+float(i%2))*unit,0,TAU,8,Color(.80,1.0,.98,.50*(1.0-rise/57.0)),unit)

func _draw_ancient_map(view: Vector2, motion: float) -> void:
	var actor_unit:=_unit(view)
	var actor_ground:=view.y*.55
	_draw_nala_daily(Vector2(view.x*.13,actor_ground),actor_unit,2)
	_actor(Vector2(view.x*.21,actor_ground),actor_unit,Color("876943"),false,0.0,"wira")
	_actor(Vector2(view.x*.75,actor_ground),actor_unit,Color("a79667"),false,0.0,"saras")
	_actor(Vector2(view.x*.83,actor_ground),actor_unit,Color("866c51"),false,0.0,"lurah")
	_actor(Vector2(view.x*.91,actor_ground),actor_unit,Color("6f7891"),false,0.0,"beno")
	var center:=Vector2(view.x*.50,view.y*.38)
	var unit:=maxf(1.0,view.y/270.0)
	var path:=PackedVector2Array([
		center+Vector2(-35,-18)*unit,center+Vector2(-11,-7)*unit,
		center+Vector2(5,5)*unit,center+Vector2(27,20)*unit])
	for i in range(path.size()-1):
		draw_line(path[i],path[i+1],Color(.33,.94,1.0,.82),2.0)
	for i in range(path.size()):
		var pulse:=.40+.45*absf(sin(motion*1.9-float(i)*.7))
		draw_rect(Rect2(path[i]-Vector2(2,2)*unit,Vector2(4,4)*unit),Color(.73,1.0,.89,pulse))
	draw_line(center+Vector2(-40,26)*unit,center+Vector2(34,26)*unit,Color(.22,.88,.96,.50),unit)
	var marker:=center+Vector2(27,20)*unit
	for i in range(3):
		var depth_y:=marker.y+(8.0+float(i)*7.0)*unit
		draw_line(Vector2(marker.x,depth_y),Vector2(marker.x+(5.0+float(i)*3.0)*unit,depth_y),Color(.35,.90,1.0,.30),unit)
	var uv_lamp:=Vector2(view.x*.80,view.y*.46)
	draw_colored_polygon(PackedVector2Array([uv_lamp,center+Vector2(-35,-33)*unit,center+Vector2(32,16)*unit]),Color(.37,.90,.98,.12))
	draw_rect(Rect2(uv_lamp,Vector2(13,8)*unit),Color("66583e"))
	draw_rect(Rect2(uv_lamp+Vector2(2,1)*unit,Vector2(8,5)*unit),Color("6ce7ee"))

func _unit(view: Vector2) -> float:
	return maxf(.8,view.y/375.0)

func _progress(motion: float, seconds: float) -> float:
	return clampf(motion/seconds,0.0,1.0)

func _actor(feet: Vector2, unit: float, coat: Color, child: bool = false, stride: float = 0.0, sprite_key: String = "") -> void:
	if NPC_FACES.has(sprite_key):
		var frame:=0 if absf(stride)<.18 else (1 if stride>0 else 3)
		var source:=Rect2(frame*64,0,64,64)
		var dest:=Rect2(feet+Vector2(-18,-39)*unit,Vector2(36,40)*unit)
		draw_texture_rect_region(NPC_FACES[sprite_key],dest,source)
		return
	if CHILD_CELLS.has(sprite_key):
		var cell:Vector2i=CHILD_CELLS[sprite_key]
		var source:=Rect2(cell.x*96,cell.y*128,96,128)
		var dest:=Rect2(feet+Vector2(-17,-43)*unit,Vector2(34,44)*unit)
		draw_texture_rect_region(CHILD_ATLAS,dest,source)
		return
	var scale:=unit*(.72 if child else 1.0)
	draw_set_transform(feet,0.0,Vector2(scale,scale))
	var step:=roundf(stride*2.0)
	draw_rect(Rect2(-7,-1,15,2),Color(.08,.14,.16,.28))
	draw_rect(Rect2(-5+step,-8,4,8),Color("283944"))
	draw_rect(Rect2(1-step,-8,4,8),Color("29343d"))
	draw_rect(Rect2(-6+step,-2,6,3),Color("342820"))
	draw_rect(Rect2(1-step,-2,6,3),Color("342820"))
	draw_rect(Rect2(-7,-21,14,14),Color("302321"))
	draw_rect(Rect2(-6,-20,12,12),coat)
	draw_rect(Rect2(-4,-30,8,9),Color("cc9f7a"))
	draw_rect(Rect2(-5,-31,10,3),Color("392d2c"))
	draw_rect(Rect2(2,-27,2,2),Color("282228"))
	draw_rect(Rect2(-10+step,-18,3,9),Color("cc9f7a"))
	draw_rect(Rect2(7-step,-18,3,9),Color("cc9f7a"))
	draw_set_transform(Vector2.ZERO)

func _draw_nala_daily(feet: Vector2, unit: float, direction: int = 2) -> void:
	var appearance:=str(GameState.player.get("appearance","female_nusantara"))
	var atlas: Texture2D=NALA_DAILY.get(appearance,NALA_DAILY["female_nusantara"])
	var source:=Rect2(direction*128+40,0,48,128)
	var dest:=Rect2(feet+Vector2(-13,-55)*unit,Vector2(26,58)*unit)
	draw_texture_rect_region(atlas,dest,source)

func _draw_prologue(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	match motif_beat:
		2:
			var mouth:=Vector2(view.x*.84,view.y*.42)
			for i in range(22):
				var phase:=fposmod(float(i)*.19+motion*(.33+float(i%3)*.06),1.0)
				var p:=mouth+Vector2((-17.0-phase*110.0)*unit,(17.0+phase*61.0)*unit)
				draw_rect(Rect2(p,Vector2(2+float(i%3),2+float(i%2))*unit),Color(.72,.33,.82,.18+.26*phase))
		3:
			var marker:=Vector2(view.x*.30,view.y*.42)
			draw_arc(marker,9*unit,PI,TAU,10,Color("b9f8ed"),2*unit)
			draw_rect(Rect2(marker+Vector2(7,-7)*unit,Vector2(3,7)*unit),Color("b9f8ed"))
			draw_rect(Rect2(marker+Vector2(1,7)*unit,Vector2(3,3)*unit),Color("b9f8ed"))
			for i in range(10):
				var fall:=fposmod(motion*13.0+float(i)*13.0,70.0)
				var p:=marker+Vector2(float(i%5)*6.0,fall)*unit
				draw_rect(Rect2(p,Vector2(2,2)*unit),Color(.21,.93,.99,.60*(1.0-fall/70.0)))
		4:
			_draw_capsule_ship(view,motion)
		5:
			var ground:=view.y*.54
			_actor(Vector2(view.x*.20,ground),unit*1.15,Color("7e623d"),false,0.0,"lurah")
			for i in range(5):
				var child_key: String=["bagas","kinasih","gito","cempaka","danu"][i]
				_actor(Vector2(view.x*(.07+float(i)*.022),ground+float(i%2)*3*unit),unit,Color("5c8580").lerp(Color("c4824a"),float(i%3)/2.0),true,sin(motion*4.0+float(i))*.2,child_key)
			draw_line(Vector2(view.x*.22,ground-43*unit),Vector2(view.x*.22,ground+2*unit),Color("4d3527"),3*unit)
			draw_rect(Rect2(view.x*.22-3*unit,ground-47*unit,7*unit,5*unit),Color("d6b577"))
		6:
			_draw_arrival_boat(view,motion)
			for i in range(7):
				var lift:=fposmod(motion*(5.0+float(i%3)*2.0)+float(i)*10.0,61.0)
				var p:=Vector2(view.x*.23+sin(float(i)*2.0+motion)*7*unit,view.y*.41-lift*unit)
				draw_circle(p,(3.0+float(i%3))*unit,Color(.25,.80,.96,.31*(1.0-lift/61.0)))
		7,8,9:
			_draw_tea_and_net(view,motion,motif_beat)

func _draw_capsule_ship(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	var arrive:=_progress(motion,2.0)
	var origin:=Vector2(view.x*(.66-arrive*.10),view.y*.50+sin(motion*1.5)*unit)
	draw_set_transform(origin,0.0,Vector2(unit,unit))
	var hull:=PackedVector2Array([Vector2(-59,-2),Vector2(49,-2),Vector2(56,4),Vector2(45,16),Vector2(-43,17),Vector2(-54,10)])
	draw_colored_polygon(hull,Color("1d2c37"))
	draw_line(Vector2(-51,13),Vector2(43,13),Color("8c6954"),2)
	draw_rect(Rect2(-57,-7,103,5),Color("ba8454"))
	draw_rect(Rect2(-56,-6,101,2),Color("ebbe77"))
	draw_rect(Rect2(-27,-24,53,17),Color("263a43"))
	draw_rect(Rect2(-29,-26,57,4),Color("ae7950"))
	draw_rect(Rect2(-22,-20,35,8),Color("65445d"))
	draw_rect(Rect2(-20,-18,31,3),Color("ddac75"))
	for i in range(5):
		var x:float=-38.0+float(i)*18.0
		draw_circle(Vector2(x,6),3,Color("c18b50"))
		draw_circle(Vector2(x,6),1.5,Color("74b7bc"))
	for x in [-42.0,-8.0,28.0]:
		draw_line(Vector2(x,-7),Vector2(x,-16),Color("b39b72"),2)
	draw_line(Vector2(-37,-25),Vector2(-37,-40),Color("817f70"),3)
	draw_rect(Rect2(-39,-42,8,4),Color("4c4c53"))
	draw_rect(Rect2(-15,-32,6,8),Color("3a4044"))
	draw_rect(Rect2(-16,-34,8,2),Color("b87757"))
	draw_line(Vector2(30,-23),Vector2(30,-46),Color("b99771"),2)
	draw_colored_polygon(PackedVector2Array([Vector2(31,-46),Vector2(49,-43),Vector2(31,-37)]),Color("8b3955"))
	draw_rect(Rect2(35,-43,5,3),Color("e3b57f"))
	draw_set_transform(Vector2.ZERO)
	_actor(origin+Vector2(27,-7)*unit,unit*.90,Color("e6e1d6"),false,0.0,"raka")
	for i in range(5):
		var feet:=Vector2(view.x*(.07+float(i)*.026),view.y*.54)
		var resident_key: String=["ratih","tedi","wira","beno","saras"][i]
		_actor(feet,unit*.9,Color("707972").lerp(Color("895e66"),float(i%3)/2.0),false,sin(motion*4.0+float(i))*.3,resident_key)
		draw_rect(Rect2(feet+Vector2(4,-19)*unit,Vector2(3,4)*unit),Color("ae80ca"))
	draw_line(origin+Vector2(-56,14)*unit,origin+Vector2(-79,18)*unit,Color(.52,.94,.94,.35),unit)

func _draw_tea_and_net(view: Vector2, motion: float, beat: int) -> void:
	var unit:=_unit(view)
	var desk_y:=view.y*.54
	draw_rect(Rect2(view.x*.28,desk_y,view.x*.44,8*unit),Color("3b241b"))
	draw_rect(Rect2(view.x*.28,desk_y,view.x*.44,3*unit),Color("c39960"))
	var mug:=Vector2(view.x*.43,desk_y-14*unit)
	draw_rect(Rect2(mug,Vector2(17,15)*unit),Color("b18755"))
	draw_rect(Rect2(mug+Vector2(2,1)*unit,Vector2(13,3)*unit),Color("7cad7e"))
	for i in range(3):
		var lift:=fposmod(motion*9.0+float(i)*11.0,34.0)
		draw_arc(mug+Vector2((5.0+float(i)*4.0)*unit,-(5.0+lift)*unit),(2.0+float(i%2))*unit,PI,TAU,6,Color(.87,.98,.83,.30*(1.0-lift/34.0)),unit)
	if beat==8:
		var net:=Vector2(view.x*.58,desk_y-15*unit)
		draw_line(net+Vector2(-14,12)*unit,net+Vector2(23,-3)*unit,Color("c68c56"),3*unit)
		draw_arc(net+Vector2(24,-5)*unit,13*unit,0,TAU,16,Color("64e0d5"),3*unit)
	if beat==9:
			_actor(Vector2(view.x*.69,desk_y),unit,Color("d4773d"))

func _draw_first_kedai(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	for i in range(3):
		var lamp:=Vector2(view.x*(.23+float(i)*.25),view.y*.25)
		draw_line(lamp+Vector2(0,-18)*unit,lamp,Color("4b3927"),2*unit)
		draw_rect(Rect2(lamp-Vector2(5,1)*unit,Vector2(10,11)*unit),Color("cf9146"))
		draw_circle(lamp+Vector2(0,5)*unit,(10.0+sin(motion*2+float(i))*2)*unit,Color(1.0,.77,.34,.08))
	_draw_tea_and_net(view,motion,7)

func _draw_saras(view: Vector2, motion: float) -> void:
	if motif_beat!=2: return
	var unit:=_unit(view)
	var ground:=view.y*.54
	_draw_tea_and_net(view,motion,7)
	_actor(Vector2(view.x*.70,ground),unit,Color("a79667"),false,0.0,"saras")
	var shard:=Vector2(view.x*(.67-.15*_progress(motion,1.8)),view.y*.47)
	draw_colored_polygon(PackedVector2Array([shard,shard+Vector2(10,-4)*unit,shard+Vector2(14,6)*unit,shard+Vector2(3,10)*unit]),Color("8e9e91"))
	draw_rect(Rect2(shard+Vector2(5,2)*unit,Vector2(3,3)*unit),Color("b96bb4"))

func _draw_first_dive(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	if motif_beat==1:
		var phase:=_progress(motion,3.6)
		var turn:=clampf((phase-.17)/.53,0.0,1.0)
		var pos:=Vector2(view.x*(.34+phase*.16),view.y*(.41+phase*.28)-sin(phase*PI)*24*unit)
		if phase<.95:
			_draw_diver(pos,unit,turn*TAU,phase<.17)
		else:
			_draw_diver(Vector2(view.x*.50,view.y*.72+(phase-.95)*view.y*.33),unit,-.12,false)
		var splash:=clampf((phase-.68)/.32,0.0,1.0)
		for i in range(7):
			var angle:=PI+float(i)*PI/6.0
			var drop:=Vector2(view.x*.49,view.y*.66)+Vector2(cos(angle),sin(angle))*(8.0+splash*24.0)*unit
			draw_rect(Rect2(drop,Vector2(2,2)*unit),Color(.66,1.0,.95,splash*(1.0-splash*.5)))
		draw_arc(Vector2(view.x*.49,view.y*.66),(4.0+splash*30.0)*unit,0,TAU,24,Color(.62,.98,.94,.50*splash),unit)
	else:
		_draw_swimmer(Vector2(view.x*.47,view.y*.52+sin(motion*1.8)*2*unit),unit,motion)
		for i in range(6):
			var rise:=fposmod(float(i)*19.0-motion*(10.0+float(i%3)*3.0),91.0)
			draw_arc(Vector2(view.x*.55+float(i%3)*6*unit,view.y*.58-rise*unit),(2.0+float(i%2))*unit,0,TAU,10,Color(.64,.96,.92,.42),unit)

func _draw_diver(pos: Vector2, unit: float, angle: float, thumb: bool) -> void:
	var appearance := str(GameState.player.get("appearance", "female_nusantara"))
	var atlas: Texture2D = NALA_DIVING.get(appearance, NALA_DIVING["female_nusantara"])
	var direction := 2 if thumb else 0
	var source := Rect2(direction * 128, 0, 128, 128)
	var scale := 68.0 * unit
	# Rotation is around the torso, not the feet; the 128px source includes transparent margins.
	draw_set_transform(pos + Vector2(0, -21 * unit), angle, Vector2.ONE)
	draw_texture_rect_region(atlas, Rect2(Vector2(-scale*.5,-scale*.5),Vector2.ONE*scale), source)
	if thumb:
		draw_rect(Rect2(7*unit,-24*unit,3*unit,12*unit),Color("d7a783"))
	draw_set_transform(Vector2.ZERO)

func _draw_swimmer(pos: Vector2, unit: float, motion: float) -> void:
	_draw_diver(pos,unit*1.22,PI*.5+sin(motion*1.7)*.055,false)
	for i in range(4):
		var drift:=fposmod(motion*(7.0+float(i)*2.0)+float(i)*13.0,46.0)
		var bubble:=pos+Vector2((-35.0-drift)*unit,(-20.0-float(i%2)*5.0-drift*.25)*unit)
		draw_arc(bubble,(1.6+float(i%2))*unit,0,TAU,8,Color(.72,1.0,.96,.40*(1.0-drift/46.0)),unit)

func _draw_service(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	if motif_beat==1:
		_draw_tea_and_net(view,motion,7)
		_draw_customer_tasting(view,motion)
	else:
		var retreat:=_progress(motion,2.0)
		_actor(Vector2(view.x*(.77+retreat*.12),view.y*.54),unit,Color("dfe3d8"),false,sin(motion*5.0)*.5,"raka")
		for i in range(11):
			var p:=Vector2(view.x*(.73+float(i%4)*.04),view.y*.52-fposmod(motion*8.0+float(i)*12.0,71.0)*unit)
			draw_rect(Rect2(p,Vector2(2,2)*unit),Color(.70,.37,.84,.18))

func _draw_customer_tasting(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	var center:=Vector2(view.x*.52,view.y*.35)
	var pulse:=.5+.5*sin(motion*3.8)
	for i in range(12):
		var angle:=float(i)*TAU/12.0
		var ray_end:=center+Vector2(cos(angle),sin(angle))*(51.0+pulse*8.0)*unit
		draw_line(center+Vector2(cos(angle),sin(angle))*34*unit,ray_end,Color(.69,1.0,.53,.30+pulse*.20),(2.0+float(i%2))*unit)
	var frame:=Rect2(center+Vector2(-55,-52)*unit,Vector2(110,111)*unit)
	draw_rect(frame,Color("25382d"))
	draw_rect(frame,Color("d4a359"),false,3*unit)
	draw_rect(Rect2(frame.position+Vector2(4,4)*unit,frame.size-Vector2(8,8)*unit),Color("a4bc6c"),false,unit)
	var source:=Rect2(160,627,320,320)
	var portrait:=Rect2(center+Vector2(-51,-48)*unit,Vector2(102,103)*unit)
	var first_customer: String = PhaseOneCutscenes.first_customer_from_shift(GameState.shift)
	if first_customer=="Bu Darmi": draw_texture_rect_region(NPC_ATLAS,portrait,source)
	elif first_customer=="Pak Ranto": draw_texture_rect(ranto_portrait_texture(),portrait,false)
	for i in range(9):
		var angle:=float(i)*2.399+motion*.24
		var drift:=Vector2(cos(angle),sin(angle))*(58.0+float(i%3)*7.0)*unit
		var sparkle:=center+drift
		draw_rect(Rect2(sparkle,Vector2(2.0+float(i%2),2.0)*unit),Color(.79,1.0,.68,.45+.25*pulse))
	var leaf:=Vector2(center.x+47*unit,center.y+36*unit)
	draw_colored_polygon(PackedVector2Array([leaf,leaf+Vector2(12,-7)*unit,leaf+Vector2(9,2)*unit,leaf+Vector2(2,7)*unit]),Color("9be084"))
	draw_line(leaf+Vector2(1,4)*unit,leaf+Vector2(9,-3)*unit,Color("3f855e"),unit)

func _draw_garden(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	var ground:=view.y*.54
	for i in range(3):
		var x:=view.x*(.43+float(i)*.075)
		draw_rect(Rect2(x,ground-10*unit,32*unit,9*unit),Color("785338"))
		for j in range(2):
			draw_line(Vector2(x+(6+j*15)*unit,ground-10*unit),Vector2(x+(10+j*15)*unit,ground-24*unit),Color("7c9167"),2*unit)
	if motif_beat<=2:
		for i in range(2):
			_actor(Vector2(view.x*(.68+float(i)*.06),ground),unit,Color("dce3d2"))
		if motif_beat==1:
			draw_rect(Rect2(view.x*.72,ground-53*unit,22*unit,15*unit),Color("b35a61"))
		else:
			for i in range(3):
				var t:=_progress(motion,1.0+float(i)*.25)
				var start:=Vector2(view.x*.23,ground-33*unit)
				var end:=Vector2(view.x*.69,ground-19*unit)
				var marble:=start.lerp(end,t)+Vector2(0,-sin(t*PI)*36*unit)
				draw_rect(Rect2(marble,Vector2(3,3)*unit),Color("dcb27c"))
			for i in range(5):
				var child_key: String=["gito","bagas","kinasih","cempaka","danu"][i]
				_actor(Vector2(view.x*(.16+float(i)*.035),ground+float(i%2)*4*unit),unit,Color("53766e").lerp(Color("d1814a"),float(i%3)/2.0),true,sin(motion*7.0+float(i))*.4,child_key)
	else:
		_actor(Vector2(view.x*.44,ground),unit*1.2,Color("7e623d"),false,0.0,"lurah")
		var staff:=Vector2(view.x*.47,ground)
		draw_line(staff+Vector2(0,-46)*unit,staff+Vector2(0,3)*unit,Color("533d2a"),3*unit)
		var ring:=_progress(motion,1.3)
		draw_arc(staff,(8.0+ring*30.0)*unit,PI,TAU,18,Color(.96,.80,.50,.55*(1.0-ring)),unit)

func _draw_cave(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	# The plume starts at the painted outlet mouth on the right cave wall.
	var mouth:=Vector2(view.x*.72,view.y*.45)
	for i in range(24):
		var phase:=fposmod(float(i)*.19+motion*(.30+float(i%4)*.05),1.0)
		var p:=mouth+Vector2(-phase*(75+i%5*7)*unit,(8+phase*75)*unit+sin(phase*5+float(i))*7*unit)
		draw_rect(Rect2(p,Vector2(2.0+float(i%3),2.0)*unit),Color(.77,.37,.85,.38*(1.0-phase*.55)))
	if motif_beat==2:
		var quake:=0.0 if EnvironmentState.reduced_motion else sin(motion*20.0)*(1.0-_progress(motion,2.0))
		for i in range(9):
			var fall:=_progress(motion,1.7+float(i%3)*.2)
			var rock:=Vector2(view.x*(.20+float(i)*.075),view.y*.14+fall*fall*120*unit+quake*5*unit)
			draw_rect(Rect2(rock,Vector2(3.0+float(i%3)*2.0,4)*unit),Color("a6b8af"))
		draw_arc(Vector2(view.x*.61,view.y*.56),(20+_progress(motion,2.0)*120)*unit,PI,TAU,40,Color(.37,.91,.97,.35*(1.0-_progress(motion,2.0))),2*unit)

func _draw_earthquake(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	var map_center:=Vector2(view.x*.70,view.y*.53)
	if motif_beat==1:
		for i in range(5):
			var council_key: String=["lurah","wira","beno","saras","raka"][i]
			_actor(Vector2(view.x*(.31+float(i)*.09),view.y*.55),unit,Color("72583e").lerp(Color("a1846a"),float(i%3)/2.0),false,sin(motion*10+float(i))*.15,council_key)
			var ring:=_progress(motion,1.2)
			draw_arc(Vector2(view.x*.73,view.y*.54),(7.0+ring*25)*unit,0,TAU,12,Color(.74,.35,.85,.35*(1.0-ring)),unit)
	elif motif_beat==3:
		_actor(Vector2(view.x*.46,view.y*.55),unit,Color("6c8e88"),true,0.0,"kinasih")
		for i in range(4):
			var p:=Vector2(view.x*(.53+float(i)*.045),view.y*(.36-float(i%2)*.06)+sin(motion*1.6+float(i))*3*unit)
			draw_circle(p,3*unit,Color(.45,.95,.94,.55))
	else:
		for i in range(4):
			var council_key: String=["lurah","wira","beno","saras"][i]
			_actor(Vector2(view.x*(.27+float(i)*.14),view.y*.55),unit,Color("5c7f77").lerp(Color("b06b46"),float(i%2)),false,0.0,council_key)
		if motif_beat==4:
			draw_line(map_center+Vector2(-16,-2)*unit,map_center+Vector2(17,4)*unit,Color(.47,.90,.89,.67),2*unit)
			draw_circle(map_center+Vector2(17,4)*unit,2*unit,Color("b5f8dc"))

func _draw_boss_intro(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	if motif_beat==1:
		var sweep:=_progress(motion,2.2)
		draw_rect(Rect2(Vector2.ZERO,view),Color(.01,.04,.10,.78*(1.0-_progress(motion,3.0))))
		var origin:=Vector2(view.x*.27,view.y*.52)
		var target:=Vector2(view.x*(.48+sweep*.34),view.y*(.44-sweep*.11))
		draw_colored_polygon(PackedVector2Array([origin,target+Vector2(-24,-25)*unit,target+Vector2(24,25)*unit]),Color(.31,.83,.93,.11+sweep*.15))
		draw_line(origin,target,Color(.52,.94,.97,.33),unit)
		if sweep>.45:
			for x in [.75,.78]:
				draw_rect(Rect2(view.x*x,view.y*.31,5*unit,5*unit),Color(.99,.21,.31,.84))
		if sweep>.75:
			var shock:=_progress((sweep-.75)*2.2,.6)
			draw_arc(Vector2(view.x*.75,view.y*.40),(10+shock*130)*unit,PI*.5,PI*1.5,28,Color(.54,.96,.99,.55*(1.0-shock)),2*unit)
	else:
		for i in range(7):
			var phase:=fposmod(motion*.5+float(i)*.22,1.0)
			var p:=Vector2(view.x*(.75+float(i%3)*.02),view.y*(.21+phase*.27))
			draw_rect(Rect2(p,Vector2(2+float(i%2),2)*unit),Color(.78,.25,.88,.54*(1.0-phase)))
		if motif_beat==3:
			var card:=Rect2(Vector2(view.x*.19,view.y*.275),Vector2(view.x*.62,view.y*.305))
			draw_rect(card,Color(.055,.10,.15,.91))
			draw_rect(card,Color("d4a359"),false,3*unit)
			draw_rect(Rect2(card.position+Vector2(5,5)*unit,card.size-Vector2(10,10)*unit),Color(.40,.86,.87,.80),false,unit)
			draw_string(BODY_FONT,Vector2(card.position.x,card.position.y+29*unit),"PENJAGA SAMUDRA YANG TERCEMAR",HORIZONTAL_ALIGNMENT_CENTER,card.size.x,roundi(16*unit),Color("efcd9c"))
			draw_string(PIXEL_FONT,Vector2(card.position.x,card.position.y+63*unit),"GAJAH MINA",HORIZONTAL_ALIGNMENT_CENTER,card.size.x,roundi(26*unit),Color("e8f9e7"))
			draw_string(BODY_FONT,Vector2(card.position.x,card.position.y+88*unit),"100 m  ·  TAMANSARI",HORIZONTAL_ALIGNMENT_CENTER,card.size.x,roundi(16*unit),Color("9ce5df"))

func _draw_crystal(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	var center:=Vector2(view.x*.77,view.y*.28)
	for i in range(12):
		var angle:=float(i)*TAU/12.0+motion*.25
		var radius:=(18.0+float(i%3)*5.0)*unit
		var p:=center+Vector2(cos(angle),sin(angle))*radius
		draw_rect(Rect2(p,Vector2(2.0+float(i%2),2)*unit),Color(.43,1.0,.94,.65))
	draw_arc(center,17*unit,0,TAU,24,Color(.73,1.0,.92,.64),2*unit)

func _draw_victory(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	if motif_beat==1:
		var nala:=Vector2(view.x*.34,view.y*.53)
		_draw_swimmer(nala,unit,motion)
		var core:=Vector2(view.x*.76,view.y*.28)
		var pull:=_progress(motion,2.5)
		draw_line(nala+Vector2(8,-20)*unit,core,Color(.34,.98,.98,.89),3*unit)
		for i in range(5):
			var angle:=float(i)*TAU/5.0+motion*.5
			draw_line(core,core+Vector2(cos(angle),sin(angle))*(10+pull*8)*unit,Color(.65,1.0,.97,.64),2*unit)
		var residue:=core.lerp(Vector2(view.x*.63,view.y*.18),pull)
		draw_circle(residue,(8.0-pull*3.0)*unit,Color(.32,.12,.43,.76*(1.0-pull*.65)))
		if pull>.7:
			draw_rect(Rect2(view.x*.75,view.y*.31,4*unit,4*unit),Color(.34,.95,1.0,.91))
	elif motif_beat==2:
		var origin:=Vector2(view.x*.735,view.y*.415)
		var seal:=_progress(motion,1.7)
		draw_arc(origin,(5+seal*19)*unit,0,TAU,24,Color(.59,.98,.94,.45*(1.0-seal*.5)),2*unit)
		var nala:=Vector2(view.x*.42,view.y*.53)
		_draw_swimmer(nala,unit,motion)
		var contact:=Vector2(view.x*.47,view.y*.46)
		draw_arc(contact,5*unit,0,TAU,16,Color(.71,1.0,.95,.66),unit)
		var slab:=Vector2(view.x*.52,view.y*(.46+.06*seal))
		draw_rect(Rect2(slab,Vector2(15,12)*unit),Color("c6a669"))
		draw_rect(Rect2(slab,Vector2(15,12)*unit),Color("705a3e"),false,unit)
		draw_rect(Rect2(slab+Vector2(5,3)*unit,Vector2(4,5)*unit),Color("5fe9eb"))
	else:
		var sweep:=_progress(motion,2.7)
		draw_rect(Rect2(0,view.y*(.52-.48*sweep),view.x,5*unit),Color(.56,1.0,.93,.08*(1.0-sweep)))
	for i in range(34):
		var rise:=fposmod(motion*(15.0+float(i%5)*4.0)+float(i)*12.0,view.y*.75)
		var x:=view.x*(.23+float((i*17)%67)*.009)
		var y:=view.y*.79-rise
		draw_rect(Rect2(x,y,(1.0+float(i%3))*unit,(1.0+float(i%3))*unit),Color(.38,.99,.96,.28+float(i%3)*.13))

func _draw_feast(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	var ground:=view.y*.54
	for i in range(5):
		var lamp:=Vector2(view.x*(.16+float(i)*.18),view.y*.27)
		draw_rect(Rect2(lamp,Vector2(7,9)*unit),Color("dd9d4a"))
		draw_circle(lamp+Vector2(3,4)*unit,(8+sin(motion*2+float(i)))*unit,Color(1.0,.78,.38,.12))
	if motif_beat<=2:
		_actor(Vector2(view.x*.76,ground),unit,Color("e0e3d9"),false,-.3,"raka")
		for i in range(2):
			_actor(Vector2(view.x*(.82+float(i)*.04),ground),unit,Color("424a54"))
		draw_rect(Rect2(view.x*.74,ground-23*unit,9*unit,11*unit),Color("b34e50"))
	if motif_beat>=2:
		for i in range(7):
			var villager_key: String=["ratih","tedi","wira","beno","saras","lurah","kinasih"][i]
			_actor(Vector2(view.x*(.25+float(i)*.052),ground+float(i%2)*4*unit),unit,Color("7c714b").lerp(Color("538377"),float(i%3)/2.0),false,sin(motion*3+float(i))*.2,villager_key)
	if motif_beat==3:
		var retreat:=_progress(motion,2.5)
		var boat:=Vector2(view.x*(.79+retreat*.22),view.y*.51)
		draw_colored_polygon(PackedVector2Array([boat+Vector2(-25,0)*unit,boat+Vector2(26,0)*unit,boat+Vector2(17,9)*unit,boat+Vector2(-18,9)*unit]),Color("2b343a"))
		draw_line(boat+Vector2(4,0)*unit,boat+Vector2(4,-29)*unit,Color("525d5c"),2*unit)
		draw_rect(Rect2(boat+Vector2(4,-27)*unit,Vector2(14,8)*unit),Color("75365c"))

func _draw_finale(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	for i in range(24):
		var x:=view.x*(.08+float((i*19)%83)*.01)
		var y:=view.y*(.13+float((i*7)%52)*.01)+sin(motion*.8+float(i))*2*unit
		draw_rect(Rect2(x,y,(1.0+float(i%2))*unit,(1.0+float(i%2))*unit),Color(.68,1.0,.91,.63))
	if motif_beat != 8: return
	var card:=Rect2(Vector2(view.x*.14,view.y*.275),Vector2(view.x*.72,view.y*.305))
	draw_rect(card,Color(.075,.13,.15,.88))
	draw_rect(card,Color("d4a359"),false,3*unit)
	draw_rect(Rect2(card.position+Vector2(5,5)*unit,card.size-Vector2(10,10)*unit),Color(.43,.78,.75,.80),false,unit)
	draw_string(PIXEL_FONT,Vector2(card.position.x,card.position.y+39*unit),"TERIMA KASIH TELAH BERMAIN",HORIZONTAL_ALIGNMENT_CENTER,card.size.x,roundi(20*unit),Color("f7ddae"))
	draw_string(BODY_FONT,Vector2(card.position.x,card.position.y+64*unit),"JALA SMARA · FASE 1",HORIZONTAL_ALIGNMENT_CENTER,card.size.x,roundi(16*unit),Color("9cf1df"))
	draw_string(BODY_FONT,Vector2(card.position.x,card.position.y+90*unit),"Bersiap menuju Zona Senja Abisal",HORIZONTAL_ALIGNMENT_CENTER,card.size.x,roundi(16*unit),Color("e8d8ae"))

