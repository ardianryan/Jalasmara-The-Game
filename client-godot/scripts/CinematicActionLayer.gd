extends Control

# Code-driven screenplay accents reuse approved character atlases without adding physics.
const DIRECTED_BEATS := {
	"prologue": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
	"first_dive": [1, 2],
	"first_kedai": [1],
	"first_service": [1, 2],
	"saras_visit": [2],
	"garden_crisis": [1, 2, 3, 4, 5],
	"cave_warning": [1, 2],
	"earthquake": [1, 2, 3, 4, 5, 6],
	"boss_intro": [1, 2, 3],
	"boss_phase_two": [1, 2],
	"victory": [1, 2, 3],
	"epilogue": [1, 2, 3, 4, 5, 6, 7, 8]
}
const CHILD_ATLAS := preload("res://resources/art/village-expansion-v1/residents.png")
const VILLAGE_PORTRAITS := preload("res://resources/art/npc-atlas.png")
const VILLAGE_RESIDENTS := preload("res://resources/art/village-residents-v1.png")
const PHASE_ONE_STORY := preload("res://scripts/PhaseOneCutscenes.gd")
const RANTO_PORTRAIT := preload("res://resources/art/cinematics-v2/pak-ranto-portrait.png")
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
const PIXEL_FONT := preload("res://resources/fonts/ark-pixel-12px-proportional-latin.otf")
const BODY_FONT := preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2")
const UPPER_PIPE_BREAK_SOURCE := Vector2(730,132)
const LOWER_PIPE_SEAL_SOURCE := Vector2(683,244)
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
const RESIDENT_CELLS := {"darmi": Rect2(0,627,627,627),"ujang": Rect2(1024,0,512,512),"sari": Rect2(512,512,512,512)}
const SUPPORT_STAGE_SCALES := {
	"prologue_child": 1.65,
	"garden_child": 1.75,
	"balai_council": 1.65,
	"feast_ratih": 1.70,
	"feast_tedi": 1.70,
	"feast_darmi": 1.70,
	"feast_ujang": 1.70,
	"feast_sari": 1.70,
	"feast_wira": 1.70,
	"feast_beno": 1.70
}
const WIDE_STAGE_SCALES := {
	"harbor_lurah": 2.30,
	"harbor_child": 1.75,
	"capsule_crowd": 1.68,
	"victory_nala": 2.38,
	"victory_beno": 1.78,
	"victory_child": 1.72,
	"victory_resident": 1.55
}
const HARBOR_CHILD_X := [.055,.145,.235]
const CAPSULE_CROWD_X := [.065,.145,.225,.305,.385]
const VICTORY_CHILD_MARKS := [Vector2(.045,.62),Vector2(.13,.62),Vector2(.215,.62),Vector2(.30,.62),Vector2(.65,.59)]
const FOCAL_SCALES := {
	"prologue:4:raka": 2.68,
	"prologue:5:lurah": 2.65,
	"garden_crisis:1:darmi": 2.22,
	"garden_crisis:2:gito": 2.48,
	"garden_crisis:3:guard": 1.67,
	"garden_crisis:4:lurah": 3.25,
	"garden_crisis:5:kinasih": 2.48,
	"earthquake:1:lurah": 3.20,
	"earthquake:2:raka": 2.68,
	"earthquake:3:kinasih": 2.48,
	"earthquake:4:saras": 2.52,
	"earthquake:5:beno": 2.52,
	"earthquake:6:wira": 2.52,
	"epilogue:4:saras": 2.52,
	"epilogue:5:lurah": 2.48,
	"epilogue:6:beno": 2.52,
	"epilogue:7:nala": 2.52,
	"epilogue:8:nala": 2.52,
}
var motif_id := ""
var motif_beat := 0
var motif_speaker := ""
var elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

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
		"boss_intro":
			_draw_boss_intro(size, motion)
			if motif_beat<=2: _draw_boss_condition(size,false,motif_beat==2,motion)
		"boss_phase_two":
			if motif_beat == 1: _draw_fractured_pipe(size, motion)
			else: _draw_crystal(size, motion)
			_draw_boss_condition(size,false,false,motion)
		"victory":
			_draw_victory(size, motion)
			if motif_beat<=2: _draw_boss_condition(size,true,false,motion)
		"epilogue":
			if motif_beat <= 3: _draw_feast(size, motion)
			elif motif_beat <= 6: _draw_ancient_map(size, motion)
			else: _draw_finale(size, motion)

func _draw_arrival_boat(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	var boat_unit:=unit*1.64
	var pose:=_arrival_pose(view,motion,motif_beat)
	var origin: Vector2=pose.boat_origin
	draw_set_transform(origin,0.0,Vector2(boat_unit,boat_unit))
	var hull:=PackedVector2Array([Vector2(-43,0),Vector2(42,0),Vector2(33,12),Vector2(20,17),Vector2(-27,17),Vector2(-39,10)])
	draw_colored_polygon(hull,Color("41291d"))
	draw_rect(Rect2(-38,1,74,3),Color("d39a55"))
	draw_rect(Rect2(-31,5,55,3),Color("86512c"))
	draw_rect(Rect2(-20,12,40,2),Color("b16b36"))
	var stroke:=sin(motion*4.0)*5.0
	draw_line(Vector2(10,-7),Vector2(33+stroke,12),Color("f0c184"),2.0)
	draw_line(Vector2(33+stroke,12),Vector2(39+stroke,17),Color("90d8d4"),2.0)
	draw_set_transform(Vector2.ZERO)
	_draw_nala_daily(pose.nala_feet,unit*2.65,4)
	if motif_beat<=7:
		_actor(Vector2(view.x*.32,view.y*.68),unit*2.53,Color("9b734f"),false,0.0,"beno")
	for i in range(3):
		var wake:=origin+Vector2((-55.0-float(i)*17.0)*boat_unit,(10.0+float(i%2)*4.0)*boat_unit)
		draw_rect(Rect2(wake,Vector2((12.0-float(i)*2.0)*unit,unit)),Color(.48,.94,.88,.28))

func _arrival_pose(view: Vector2, motion: float, beat: int) -> Dictionary:
	var unit:=_unit(view)
	var arrival:=smoothstep(0.0,1.0,clampf(motion/2.0,0.0,1.0)) if beat==6 else 1.0
	var disembark:=smoothstep(0.0,1.0,clampf(motion/2.0,0.0,1.0)) if beat==7 else (1.0 if beat>=8 else 0.0)
	var origin:=Vector2(view.x*(.86-arrival*.20),view.y*.60+sin(motion*2.0)*unit)
	var boat_feet:=origin+Vector2(-3,5)*unit*1.64
	var dock_feet:=Vector2(view.x*.46,view.y*.65)
	var nala_feet:=boat_feet.lerp(dock_feet,disembark)
	nala_feet.y-=sin(disembark*PI)*5.0*unit
	return {"boat_origin":origin,"nala_feet":nala_feet}

func _draw_fractured_pipe(view: Vector2, motion: float) -> void:
	var unit:=maxf(1.0,view.y/270.0)
	var break_ratio:=smoothstep(0.0,1.0,_progress(motion,1.1))
	var origin:=_pipe_outlet(view)
	# The painted Tamansari pipe is already severed; a dark open bore and a falling
	# brace make that break readable over Mina's foreground silhouette.
	draw_circle(origin,15*unit,Color("284c55"))
	draw_circle(origin,11*unit,Color("122b37"))
	draw_arc(origin,15*unit,PI*.4,PI*1.6,15,Color("bb7452"),4*unit)
	draw_arc(origin,11*unit,-PI*.5,PI*.5,13,Color("d39864"),2*unit)
	for i in range(4):
		var angle:=PI*.58+float(i)*PI*.30
		var base:=origin+Vector2(cos(angle),sin(angle))*14*unit
		draw_line(base,base+Vector2(cos(angle),sin(angle))*5*unit,Color("dba173"),2*unit)
	var broken_end:=origin+Vector2(22.0*break_ratio,40.0*break_ratio)*unit
	draw_set_transform(broken_end,-.30*break_ratio,Vector2(unit,unit))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12,-8),Vector2(8,-9),Vector2(12,-5),Vector2(12,6),
		Vector2(4,9),Vector2(-12,7)]),Color("71463a"))
	draw_rect(Rect2(-10,-5,17,10),Color("9b6952"))
	draw_rect(Rect2(-7,-4,13,2),Color("d1986a"))
	draw_circle(Vector2(9,0),6,Color("c48359"))
	draw_circle(Vector2(9,0),3,Color("243f47"))
	draw_set_transform(Vector2.ZERO)
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
	_draw_nala_daily(Vector2(view.x*.17,view.y*.68),actor_unit*1.75,2)
	var bagas_pose:=_map_bagas_pose(view,motion)
	var speaker: String={4:"saras",5:"lurah",6:"beno"}.get(motif_beat,"")
	var center:=Vector2(view.x*.50,view.y*.38)
	var unit:=maxf(1.0,view.y/270.0)
	var reveal:=1.0 if motif_beat!=4 else smoothstep(0.0,1.0,_progress(motion,1.8))
	var path:=PackedVector2Array([
		center+Vector2(-35,-18)*unit,center+Vector2(-11,-7)*unit,
		center+Vector2(5,5)*unit,center+Vector2(27,20)*unit])
	for i in range(path.size()-1):
		var segment:=clampf(reveal*float(path.size()-1)-float(i),0.0,1.0)
		if segment>0.0:
			draw_line(path[i],path[i].lerp(path[i+1],segment),Color(.33,.94,1.0,.82),2.0)
	for i in range(path.size()):
		if float(i)>reveal*float(path.size()-1)+.01: continue
		var pulse:=.40+.45*absf(sin(motion*1.9-float(i)*.7))
		draw_rect(Rect2(path[i]-Vector2(2,2)*unit,Vector2(4,4)*unit),Color(.73,1.0,.89,pulse))
	draw_line(center+Vector2(-40,26)*unit,center+Vector2(-40+74*reveal,26)*unit,Color(.22,.88,.96,.50),unit)
	var marker:=center+Vector2(27,20)*unit
	for i in range(3):
		if reveal < .72+float(i)*.09: continue
		var depth_y:=marker.y+(8.0+float(i)*7.0)*unit
		draw_line(Vector2(marker.x,depth_y),Vector2(marker.x+(5.0+float(i)*3.0)*unit,depth_y),Color(.35,.90,1.0,.30),unit)
	var uv_lamp: Vector2=bagas_pose.feet+Vector2(-14,-53)*actor_unit
	draw_colored_polygon(PackedVector2Array([uv_lamp,center+Vector2(-35,-33)*unit,center+Vector2(32,16)*unit]),Color(.37,.90,.98,.05+.11*reveal))
	_actor(bagas_pose.feet,actor_unit*1.95,Color("638a83"),true,bagas_pose.stride,"bagas")
	draw_rect(Rect2(uv_lamp,Vector2(13,8)*unit),Color("66583e"))
	draw_rect(Rect2(uv_lamp+Vector2(2,1)*unit,Vector2(8,5)*unit),Color("6ce7ee"))
	if not speaker.is_empty():
		var coat:=Color("a79667") if speaker=="saras" else (Color("866c51") if speaker=="lurah" else Color("6f7891"))
		_actor(Vector2(view.x*.80,view.y*.68),actor_unit*_focal_scale(speaker),coat,false,0.0,speaker)

func _map_bagas_pose(view: Vector2, motion: float) -> Dictionary:
	var arrival:=smoothstep(0.0,1.0,_progress(motion,.8))
	return {"feet":Vector2(view.x*lerpf(.59,.64,arrival),view.y*.68),"stride":sin(motion*10.0)*.4 if arrival<1.0 else 0.0}

func _unit(view: Vector2) -> float:
	return maxf(.8,view.y/375.0)

func _draw_near_pier(view: Vector2) -> void:
	var unit:=_unit(view)
	var deck:=PackedVector2Array([
		Vector2(0,view.y*.585),Vector2(view.x*.46,view.y*.575),
		Vector2(view.x*.49,view.y*.715),Vector2(0,view.y*.74)
	])
	draw_colored_polygon(deck,Color("694326"))
	draw_line(deck[0],deck[1],Color("d9a05b"),3*unit)
	draw_line(deck[2],deck[3],Color("32251b"),4*unit)
	for i in range(6):
		var t:=float(i)/6.0
		var near:=Vector2(0,lerpf(deck[0].y,deck[3].y,t))
		var far:=Vector2(lerpf(deck[1].x,deck[2].x,t),lerpf(deck[1].y,deck[2].y,t))
		draw_line(near,far,Color("362b22"),unit)
		draw_line(near+Vector2(0,2)*unit,far+Vector2(0,2)*unit,Color("a87945"),unit)
	for x_fraction in [.11,.30,.45]:
		var post:=Vector2(view.x*float(x_fraction),view.y*.58)
		draw_rect(Rect2(post,Vector2(5,72)*unit),Color("4d3828"))
		draw_rect(Rect2(post,Vector2(5,4)*unit),Color("b68751"))

func _focal_scale(role: String, fallback: float = 1.0) -> float:
	return float(FOCAL_SCALES.get("%s:%d:%s" % [motif_id,motif_beat,role],fallback))

func _pipe_outlet(view: Vector2, sealed: bool = false) -> Vector2:
	var source:=LOWER_PIPE_SEAL_SOURCE if sealed else UPPER_PIPE_BREAK_SOURCE
	var parent:=get_parent()
	if parent!=null and parent.has_method("_backdrop_rect"):
		var plate_rect: Rect2=parent.call("_backdrop_rect")
		return plate_rect.position+Vector2(source.x*plate_rect.size.x/960.0,source.y*plate_rect.size.y/540.0)
	return Vector2(view.x*source.x/960.0,view.y*source.y/540.0)

func _progress(motion: float, seconds: float) -> float:
	return clampf(motion/seconds,0.0,1.0)

func _actor(feet: Vector2, unit: float, coat: Color, child: bool = false, stride: float = 0.0, sprite_key: String = "") -> void:
	# The contact line stays on the deck while the near-camera figure grows.
	draw_line(feet + Vector2(-13, 1) * unit, feet + Vector2(13, 1) * unit, Color(.12, .13, .13, .24), maxf(1.0, 2.0 * unit))
	if RESIDENT_CELLS.has(sprite_key):
		var atlas: Texture2D=VILLAGE_PORTRAITS if sprite_key=="darmi" else VILLAGE_RESIDENTS
		var source: Rect2=RESIDENT_CELLS[sprite_key]
		var dest:=Rect2(feet+Vector2(-20,-43)*unit,Vector2(40,44)*unit)
		draw_texture_rect_region(atlas,dest,source)
		return
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
	# All four approved daily atlases end their visible boots at row 104 of 128.
	var dest:=Rect2(feet+Vector2(-13,-47)*unit,Vector2(26,58)*unit)
	draw_line(feet + Vector2(-8, 1) * unit, feet + Vector2(8, 1) * unit, Color(.12, .13, .13, .24), maxf(1.0, 2.0 * unit))
	draw_texture_rect_region(atlas,dest,source)

func _draw_corporate_guard(feet: Vector2, unit: float, recoil: float = 0.0, stride: float = 0.0) -> void:
	var anchor:=Vector2(roundf(feet.x+recoil*4.0*unit),roundf(feet.y))
	var frame:=0 if absf(stride)<.18 else (1 if stride>0 else 3)
	draw_line(anchor+Vector2(-11,1)*unit,anchor+Vector2(11,1)*unit,Color(.12,.13,.13,.26),maxf(1.0,2.0*unit))
	draw_texture_rect_region(
		NPC_FACES["raka"],
		Rect2(anchor+Vector2(-18,-47)*unit,Vector2(36,48)*unit),
		Rect2(frame*64,0,64,64),Color(.74,.85,.85))
	draw_set_transform(anchor,0.0,Vector2(unit,unit))
	draw_rect(Rect2(-10,-43,20,3),Color("334a4e"))
	draw_rect(Rect2(-7,-46,14,4),Color("536e70"))
	draw_rect(Rect2(-5,-45,10,1),Color("d7d9c4"))
	draw_rect(Rect2(-9,-22,4,5),Color("b14f5c"))
	draw_rect(Rect2(-8,-21,2,2),Color("e9c49b"))
	draw_set_transform(Vector2.ZERO)

func _draw_seal_letter(at: Vector2, unit: float, crumpled: bool = false) -> void:
	draw_set_transform(Vector2(roundf(at.x),roundf(at.y)),0.0,Vector2(unit,unit))
	var paper:=PackedVector2Array([Vector2(0,0),Vector2(16,0),Vector2(16,20),Vector2(0,20)])
	if crumpled:
		paper=PackedVector2Array([Vector2(2,0),Vector2(13,1),Vector2(16,8),Vector2(11,18),Vector2(0,15),Vector2(3,8)])
	draw_colored_polygon(paper,Color("e7d8b3"))
	var outline:=paper.duplicate()
	outline.append(paper[0])
	draw_polyline(outline,Color("714d3d"),1.0)
	draw_rect(Rect2(3,3,10,2),Color("927762"))
	draw_rect(Rect2(3,7,8,1),Color("927762"))
	draw_rect(Rect2(5,11,7,6),Color("a64f5a"))
	draw_rect(Rect2(7,12,3,4),Color("e8b59c"))
	draw_set_transform(Vector2.ZERO)

func _draw_prologue(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	match motif_beat:
		1:
			_draw_harbor_lesson(view,motion)
		2:
			var mouth:=Vector2(view.x*.84,view.y*.42)
			for i in range(22):
				var phase:=fposmod(float(i)*.19+motion*(.33+float(i%3)*.06),1.0)
				var p:=mouth+Vector2((-17.0-phase*110.0)*unit,(17.0+phase*61.0)*unit)
				draw_rect(Rect2(p,Vector2(2+float(i%3),2+float(i%2))*unit),Color(.72,.33,.82,.18+.26*phase))
		3:
			_draw_forgotten_work(view,motion)
		4:
			_draw_capsule_ship(view,motion)
		5:
			var ground:=view.y*.66
			_draw_near_pier(view)
			_actor(Vector2(view.x*.43,ground),unit*_focal_scale("lurah"),Color("7e623d"),false,0.0,"lurah")
			for i in range(5):
				var child_key: String=["bagas","kinasih","gito","cempaka","danu"][i]
				_actor(Vector2(view.x*(.06+float(i)*.068),ground-4*unit+float(i%2)*3*unit),unit*SUPPORT_STAGE_SCALES["prologue_child"],Color("5c8580").lerp(Color("c4824a"),float(i%3)/2.0),true,sin(motion*4.0+float(i))*.2,child_key)
			var staff:=Vector2(view.x*.49,ground)
			draw_line(staff+Vector2(0,-87)*unit,staff+Vector2(0,2)*unit,Color("4d3527"),3*unit)
			draw_rect(Rect2(staff+Vector2(-3,-91)*unit,Vector2(7,5)*unit),Color("d6b577"))
		6,7,8:
			_draw_arrival_boat(view,motion)
			if motif_beat==6:
				for i in range(7):
					var lift:=fposmod(motion*(5.0+float(i%3)*2.0)+float(i)*10.0,61.0)
					var p:=Vector2(view.x*.23+sin(float(i)*2.0+motion)*7*unit,view.y*.41-lift*unit)
					draw_circle(p,(3.0+float(i%3))*unit,Color(.25,.80,.96,.31*(1.0-lift/61.0)))
			if motif_beat==8:
				_actor(Vector2(view.x*.36,view.y*.68),unit*2.50,Color("876943"),false,0.0,"wira")
		9,10,11:
			_draw_tea_and_net(view,motion,motif_beat)

func _draw_harbor_lesson(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	var pier_y:=view.y*.57
	var compass:=Vector2(view.x*.44,view.y*.475)
	draw_rect(Rect2(compass-Vector2(8,6)*unit,Vector2(17,13)*unit),Color("5b3b25"))
	draw_rect(Rect2(compass-Vector2(6,4)*unit,Vector2(13,9)*unit),Color("ddbd77"))
	draw_line(compass+Vector2(-4,0)*unit,compass+Vector2(5,0)*unit,Color("476b6a"),unit)
	draw_line(compass+Vector2(0,-3)*unit,compass+Vector2(0,4)*unit,Color("476b6a"),unit)
	draw_colored_polygon(PackedVector2Array([
		compass+Vector2(0,-4)*unit,compass+Vector2(-2,0)*unit,
		compass+Vector2(2,0)*unit]),Color("9d4536"))
	_actor(Vector2(view.x*.36,pier_y),unit*WIDE_STAGE_SCALES["harbor_lurah"],Color("7e623d"),false,0.0,"lurah")
	for i in range(3):
		var child_key: String=["bagas","kinasih","gito"][i]
		var feet:=Vector2(view.x*HARBOR_CHILD_X[i],pier_y+float(i%2)*2*unit)
		if not EnvironmentState.reduced_motion: feet.y+=sin(motion*1.5+float(i)*.9)*unit
		_actor(feet,unit*WIDE_STAGE_SCALES["harbor_child"],Color("6a8c75"),true,0.0,child_key)
	var pointer:=Vector2(view.x*.41,pier_y-18*unit)
	draw_line(pointer,compass+Vector2(-3,1)*unit,Color("826347"),2*unit)
	for i in range(3):
		var wake:=Vector2(view.x*(.44+float(i)*.04),view.y*(.51+float(i%2)*.025))
		draw_line(wake,wake+Vector2(7,1)*unit,Color(.66,1.0,.89,.32),unit)

func _draw_forgotten_work(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	var forget:=smoothstep(0.0,1.0,_progress(motion,2.2))
	var market_y:=view.y*.67
	var ranto:=Vector2(view.x*.27,market_y)
	var darmi:=Vector2(view.x*.75,market_y)
	for panel_x in [.115,.595]:
		var panel:=Rect2(view.x*float(panel_x),view.y*.34,view.x*.31,view.y*.36)
		draw_rect(panel,Color(.12,.10,.13,.86))
		draw_rect(panel,Color("d0a267"),false,3*unit)
		draw_rect(Rect2(panel.position+Vector2(5,5)*unit,panel.size-Vector2(10,10)*unit),Color("715237"),false,unit)
	draw_texture_rect(RANTO_PORTRAIT,Rect2(ranto+Vector2(-47,-102)*unit,Vector2(94,100)*unit),false)
	draw_texture_rect_region(VILLAGE_PORTRAITS,Rect2(darmi+Vector2(-48,-101)*unit,Vector2(96,100)*unit),Rect2(0,512,512,512))
	draw_string(BODY_FONT,Vector2(view.x*.13,view.y*.41),"PAK RANTO",HORIZONTAL_ALIGNMENT_LEFT,view.x*.18,roundi(13*unit),Color("eed5a7"))
	draw_string(BODY_FONT,Vector2(view.x*.61,view.y*.41),"BU DARMI",HORIZONTAL_ALIGNMENT_LEFT,view.x*.18,roundi(13*unit),Color("eed5a7"))
	var scale_top:=ranto+Vector2(65,-51)*unit
	draw_line(scale_top,scale_top+Vector2(0,39)*unit,Color("6e492c"),3*unit)
	draw_line(scale_top+Vector2(-17,9)*unit,scale_top+Vector2(17,9)*unit,Color("d8b176"),3*unit)
	for side in [-1.0,1.0]:
		var pan:=scale_top+Vector2(side*17,31)*unit
		draw_line(scale_top+Vector2(side*16,9)*unit,pan,Color("d8b176"),unit)
		draw_line(pan+Vector2(-7,0)*unit,pan+Vector2(7,0)*unit,Color("d8b176"),3*unit)
	var trough:=darmi+Vector2(-55,-14)*unit
	draw_rect(Rect2(trough,Vector2(66,13)*unit),Color("6b4528"))
	draw_rect(Rect2(trough+Vector2(3,2)*unit,Vector2(60,4)*unit),Color("9b7450"))
	for i in range(3):
		var stem:=trough+Vector2(9+float(i)*19,-4+forget*3)*unit
		draw_line(stem,stem+Vector2(1,-8+forget*5)*unit,Color("6d8b5c").lerp(Color("8e7864"),forget),unit)
		draw_rect(Rect2(stem+Vector2(0,-10+forget*5)*unit,Vector2(4,3)*unit),Color("7ca875").lerp(Color("9b8267"),forget))
	for anchor in [ranto+Vector2(-1,-105)*unit,darmi+Vector2(0,-105)*unit]:
		draw_string(PIXEL_FONT,anchor,"?",HORIZONTAL_ALIGNMENT_CENTER,14*unit,roundi(14*unit),Color(1.0,.90,.61,.35+.62*forget))
	for i in range(12):
		var origin:=ranto if i<6 else darmi
		var fall:=fposmod(motion*13.0+float(i)*11.0,53.0)
		var p:=origin+Vector2(float(i%6)*11.0-26.0,-86.0+fall)*unit
		draw_rect(Rect2(p,Vector2(2,2)*unit),Color(.21,.93,.99,.42*(1.0-fall/53.0)*forget))

func _draw_capsule_ship(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	var near_unit:=unit*1.68
	var arrive:=_progress(motion,2.0)
	# The original harbor remains the wide backdrop; this bow passes the near pier.
	var origin:=Vector2(view.x*(.70-arrive*.08),view.y*.62+sin(motion*1.5)*unit)
	draw_set_transform(origin,0.0,Vector2(near_unit,near_unit))
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
	var raka_feet:=origin+Vector2(9,-7)*near_unit
	_actor(raka_feet,unit*_focal_scale("raka",.90),Color("e6e1d6"),false,0.0,"raka")
	var horn:=raka_feet+Vector2(19,-48)*unit
	draw_colored_polygon(PackedVector2Array([
		horn+Vector2(0,1)*unit,horn+Vector2(16,-5)*unit,
		horn+Vector2(16,8)*unit,horn+Vector2(0,3)*unit
	]),Color("d9b178"))
	draw_line(horn+Vector2(16,-5)*unit,horn+Vector2(16,8)*unit,Color("f6d299"),2*unit)
	draw_rect(Rect2(horn+Vector2(-5,0)*unit,Vector2(6,5)*unit),Color("4b4240"))
	for i in range(5):
		var reach:=smoothstep(0.0,1.0,_progress(motion-.24-float(i)*.17,.72))
		var feet:=Vector2(view.x*CAPSULE_CROWD_X[i]+reach*4*unit,view.y*(.56+float(i%2)*.013))
		var resident_key: String=["ratih","tedi","wira","beno","saras"][i]
		_actor(feet,unit*WIDE_STAGE_SCALES["capsule_crowd"],Color("707972").lerp(Color("895e66"),float(i%3)/2.0),false,sin(motion*4.0+float(i))*.3,resident_key)
		var capsule:=feet+Vector2(9-5*reach,-16-12*reach)*unit
		draw_rect(Rect2(capsule,Vector2(4,6)*unit),Color("ae80ca"))
		draw_rect(Rect2(capsule+Vector2(1,1)*unit,Vector2(2,2)*unit),Color("d4a2e4"))
	for side in [-1.0,1.0]:
		var shoulder:=origin+Vector2(side*52,12)*near_unit
		draw_arc(shoulder,7*unit,0.0,PI,8,Color(.61,.95,.91,.40),unit)
		for i in range(3):
			var wake:=shoulder+Vector2(side*(11+float(i)*10),3+float(i%2)*3)*unit
			draw_line(wake,wake+Vector2(side*(7+float(i)*2),0)*unit,Color(.60,.96,.94,.30-float(i)*.07),unit)

func _draw_tea_and_net(view: Vector2, motion: float, beat: int) -> void:
	var unit:=_unit(view)
	var desk_y:=view.y*.46
	var mug:=Vector2(view.x*.43,desk_y-14*unit)
	draw_rect(Rect2(mug,Vector2(17,15)*unit),Color("b18755"))
	draw_rect(Rect2(mug+Vector2(2,1)*unit,Vector2(13,3)*unit),Color("7cad7e"))
	for i in range(3):
		var lift:=fposmod(motion*9.0+float(i)*11.0,34.0)
		draw_arc(mug+Vector2((5.0+float(i)*4.0)*unit,-(5.0+lift)*unit),(2.0+float(i%2))*unit,PI,TAU,6,Color(.87,.98,.83,.30*(1.0-lift/34.0)),unit)
	if beat==10:
		var net:=Vector2(view.x*.42,desk_y-15*unit)
		draw_line(net+Vector2(-14,12)*unit,net+Vector2(23,-3)*unit,Color("c68c56"),3*unit)
		draw_arc(net+Vector2(24,-5)*unit,13*unit,0,TAU,16,Color("64e0d5"),3*unit)
	if motif_id=="prologue":
		var near_y:=view.y*.68
		_draw_nala_daily(Vector2(view.x*.22,near_y),unit*2.55,2)
		_actor(Vector2(view.x*.50,near_y),unit*2.55,Color("876943"),false,0.0,"wira")
		_actor(Vector2(view.x*.78,near_y),unit*2.55,Color("6f7891"),false,0.0,"beno")

func _draw_first_kedai(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	for i in range(3):
		var lamp:=Vector2(view.x*(.23+float(i)*.25),view.y*.25)
		draw_line(lamp+Vector2(0,-18)*unit,lamp,Color("4b3927"),2*unit)
		draw_rect(Rect2(lamp-Vector2(5,1)*unit,Vector2(10,11)*unit),Color("cf9146"))
		draw_circle(lamp+Vector2(0,5)*unit,(10.0+sin(motion*2+float(i))*2)*unit,Color(1.0,.77,.34,.08))
	_draw_tea_and_net(view,motion,7)
	_actor(Vector2(view.x*.23,view.y*.68),unit*2.40,Color("876943"),false,0.0,"wira")
	var customer:=_tasting_subject()
	if customer=="Bu Darmi":
		_actor(Vector2(view.x*.77,view.y*.68),unit*2.22,Color("a1846a"),false,0.0,"darmi")
	elif customer=="Pak Ranto":
		var feet:=Vector2(view.x*.77,view.y*.68)
		var portrait:=Rect2(feet+Vector2(-46,-100)*unit,Vector2(92,98)*unit)
		var frame:=portrait.grow(5*unit)
		draw_rect(frame,Color("302017"))
		draw_rect(frame,Color("d6a35f"),false,2*unit)
		draw_rect(Rect2(frame.position+Vector2(4,4)*unit,frame.size-Vector2(8,8)*unit),Color("59402c"))
		draw_texture_rect(RANTO_PORTRAIT,portrait,false)
		for corner in [frame.position,frame.position+Vector2(frame.size.x-7*unit,0),frame.end-Vector2(7,7)*unit,frame.position+Vector2(0,frame.size.y-7*unit)]:
			draw_rect(Rect2(corner,Vector2(7,7)*unit),Color("e8be77"))

func _draw_saras(view: Vector2, motion: float) -> void:
	if motif_beat!=2: return
	var unit:=_unit(view)
	var ground:=view.y*.68
	_actor(Vector2(view.x*.68,ground),unit*2.52,Color("a79667"),false,0.0,"saras")
	var shard:=Vector2(view.x*.705,ground-48*unit+sin(motion*1.6)*unit)
	draw_colored_polygon(PackedVector2Array([shard,shard+Vector2(10,-4)*unit,shard+Vector2(14,6)*unit,shard+Vector2(3,10)*unit]),Color("8e9e91"))
	draw_rect(Rect2(shard+Vector2(5,2)*unit,Vector2(3,3)*unit),Color("b96bb4"))

func _draw_first_dive(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	if motif_beat==1:
		var phase:=_progress(motion,3.6)
		var turn:=clampf((phase-.17)/.53,0.0,1.0)
		var pos:=Vector2(view.x*(.34+phase*.16),view.y*(.41+phase*.28)-sin(phase*PI)*24*unit)
		if phase<.95:
			_draw_diver(pos,unit*1.45,turn*TAU,phase<.17)
		else:
			_draw_diver(Vector2(view.x*.50,view.y*.72+(phase-.95)*view.y*.33),unit*1.45,-.12,false)
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
	var source := Rect2(direction * 128 + 40, 14, 48, 96)
	# Crop the empty atlas gutters so the diver's 86-pixel silhouette reads at native size.
	# Keep the feet at the previous anchor while rotating around the torso.
	draw_set_transform(pos + Vector2(0, -32 * unit), angle, Vector2.ONE)
	draw_texture_rect_region(atlas, Rect2(Vector2(-21,-36)*unit,Vector2(42,72)*unit), source)
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
		_draw_customer_tasting(view,motion)
	else:
		var retreat:=_progress(motion,2.0)
		var window_x:=view.x*(.79+retreat*.105)
		var window_feet:=view.y*.475
		draw_texture_rect_region(
			NPC_FACES["raka"],
			Rect2(Vector2(window_x-12*unit,window_feet-27*unit),Vector2(24,27)*unit),
			Rect2(0,0,64,64),Color(.59,.67,.74,.92))
		# The lower rail cuts across his feet, keeping him outside the open window.
		draw_line(Vector2(view.x*.705,view.y*.49),Vector2(view.x*.965,view.y*.49),Color("64452f"),3*unit)
		for i in range(7):
			var drip:=fposmod(motion*16.0+float(i)*9.0,52.0)
			var p:=Vector2(view.x*(.73+float(i)*.031),view.y*.31+drip*unit)
			draw_line(p,p+Vector2(-2,6)*unit,Color(.55,.80,.87,.27),unit)

func _draw_customer_tasting(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	var center:=Vector2(view.x*.51,view.y*.35)
	var clarity:=smoothstep(0.0,1.0,_progress(motion-.35,1.2))
	var frame:=Rect2(center+Vector2(-59,-50)*unit,Vector2(118,105)*unit)
	draw_rect(frame,Color("30221d").lerp(Color("436340"),clarity*.65))
	draw_rect(frame,Color("d4a359"),false,3*unit)
	draw_rect(Rect2(frame.position+Vector2(5,5)*unit,frame.size-Vector2(10,10)*unit),Color("9b764b"),false,unit)
	var face:=Rect2(center+Vector2(-50,-49)*unit,Vector2(101,100)*unit)
	match _tasting_subject():
		"Pak Ranto": draw_texture_rect(RANTO_PORTRAIT,face,false)
		"Bu Darmi": draw_texture_rect_region(VILLAGE_PORTRAITS,face,Rect2(145,650,340,380))
		_: _draw_tasting_leaf(center,unit)
	var bloom:=center+Vector2(0,-15)*unit
	for i in range(10):
		var angle:=float(i)*TAU/10.0
		var direction:=Vector2(cos(angle),sin(angle))
		draw_line(bloom+direction*39*unit,bloom+direction*(44+clarity*7)*unit,Color(.79,1.0,.56,.26+.43*clarity),2*unit)
	for i in range(8):
		var release:=_progress(motion-.48-float(i)*.04,1.0)
		var mote:=bloom+Vector2(cos(float(i)*2.4),sin(float(i)*2.4))*(10+release*34)*unit
		draw_rect(Rect2(mote,Vector2(3,3)*unit),Color(.65,.33,.77,(1.0-release)*.7))
	var cup:=center+Vector2(29,22)*unit
	draw_rect(Rect2(cup,Vector2(17,15)*unit),Color("d3af72"))
	draw_rect(Rect2(cup+Vector2(2,1)*unit,Vector2(13,3)*unit),Color("6da76b"))
	draw_arc(cup+Vector2(17,8)*unit,5*unit,-PI*.5,PI*.5,8,Color("e3c38c"),2*unit)
	for i in range(2):
		var rise:=fposmod(motion*8.0+float(i)*9.0,24.0)
		draw_line(cup+Vector2((6+float(i)*6)*unit,-rise*unit),cup+Vector2((8+float(i)*6)*unit,(-5-rise)*unit),Color(.85,1.0,.79,.42*(1.0-rise/24.0)),2*unit)

func _tasting_subject() -> String:
	if not motif_speaker.strip_edges().is_empty(): return motif_speaker.strip_edges()
	return PHASE_ONE_STORY.first_customer_from_shift(GameState.shift)

func _draw_tasting_leaf(center: Vector2, unit: float) -> void:
	var stem:=center+Vector2(0,22)*unit
	draw_line(stem,stem+Vector2(0,-47)*unit,Color("d0b475"),4*unit)
	for side in [-1.0,1.0]:
		var leaf:=PackedVector2Array([
			stem+Vector2(0,-27)*unit,
			stem+Vector2(side*27,-47)*unit,
			stem+Vector2(side*31,-24)*unit,
			stem+Vector2(0,-13)*unit])
		draw_colored_polygon(leaf,Color("75aa63"))
		draw_line(stem+Vector2(0,-20)*unit,stem+Vector2(side*25,-32)*unit,Color("bfe0a0"),2*unit)

func _garden_guard_pose(view: Vector2, motion: float, index: int) -> Dictionary:
	var unit:=_unit(view)
	var arrival:=smoothstep(0.0,1.0,_progress(motion-.10-float(index)*.12,.70))
	var feet:=Vector2(view.x*(.67+float(index)*.12)+14.0*unit*(1.0-arrival),view.y*.63)
	var stride:=sin(motion*11.0+float(index)*PI)*.48 if arrival<1.0 else 0.0
	return {"feet":feet,"stride":stride}

func _garden_lurah_pose(view: Vector2, motion: float) -> Dictionary:
	var entrance:=smoothstep(0.0,1.0,_progress(motion,.85))
	var feet:=Vector2(view.x*(.32+.12*entrance),view.y*.66)
	var stride:=sin(motion*11.0)*.48 if entrance<1.0 else 0.0
	return {"feet":feet,"stride":stride}

func _draw_garden(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	if motif_beat<=3:
		for i in range(2):
			var first_hit:=.18+float(i)*.20+.75
			var recoil:=1.0-_progress(motion-first_hit,.43) if motion>=first_hit else 0.0
			var guard_scale:=_focal_scale("guard",1.67)
			var guard_pose:=_garden_guard_pose(view,motion,i) if motif_beat==2 else {"feet":Vector2(view.x*(.67+float(i)*.12),view.y*.63),"stride":0.0}
			_draw_corporate_guard(guard_pose.feet,unit*guard_scale,recoil,guard_pose.stride)
		if motif_beat==1:
			_actor(Vector2(view.x*.47,view.y*.67),unit*_focal_scale("darmi"),Color("a1846a"),false,0.0,"darmi")
		if motif_beat!=2:
			_draw_seal_letter(Vector2(view.x*.735,view.y*.405),unit*.85)
		if motif_beat==2:
			for i in range(3):
				var launch:=.18+float(i)*.20
				var t:=_progress(motion-launch,.75)
				var guard_x:=.67 if i<2 else .79
				var start:=Vector2(view.x*.31,view.y*.67-46*unit)
				var end:=Vector2(view.x*guard_x,view.y*.63-32*unit)
				if motion>=launch and t<1.0:
					var marble:=start.lerp(end,t)+Vector2(0,-sin(t*PI)*28*unit)
					draw_line(marble-Vector2(8,0)*unit,marble,Color(.97,.80,.49,.45),unit)
					draw_rect(Rect2(marble,Vector2(3,3)*unit),Color("e4bd7d"))
				if motion>=launch+.75 and motion<launch+1.12:
					var flash:=1.0-_progress(motion-launch-.75,.37)
					for side in [-1.0,1.0]:
						draw_line(end+Vector2(side*2,-2)*unit,end+Vector2(side*(4+6*flash),(-6-4*flash))*unit,Color(1.0,.84,.55,flash),unit)
			for i in range(5):
				var child_key: String=["gito","bagas","kinasih","cempaka","danu"][i]
				var child_x: float=[.31,.14,.43,.51,.59][i]
				var child_scale:=_focal_scale(child_key,SUPPORT_STAGE_SCALES["garden_child"])
				var child_ground:=view.y*.67 if child_key=="gito" else view.y*.63+float(i%2)*2*unit
				var rally:=smoothstep(0.0,1.0,_progress(motion-.12-float(i)*.13,.52))
				var child_feet:=Vector2(view.x*child_x,child_ground-sin(rally*PI)*4*unit)
				_actor(child_feet,unit*child_scale,Color("53766e"),true,0.0,child_key)
				if rally<1.0:
					var shadow:=Vector2(view.x*child_x,child_ground)
					draw_line(shadow-Vector2(6,0)*unit,shadow+Vector2(6,0)*unit,Color(.12,.13,.13,.28),unit)
	else:
		if motif_beat==4:
			var lurah_pose:=_garden_lurah_pose(view,motion)
			var lurah_feet: Vector2=lurah_pose.feet
			_actor(lurah_feet,unit*_focal_scale("lurah",1.15),Color("7e623d"),false,lurah_pose.stride,"lurah")
			var staff:=lurah_feet+Vector2(36,0)*unit
			var plant:=smoothstep(0.0,1.0,_progress(motion-.58,.35))
			draw_line(staff+Vector2(0,-91-9*(1.0-plant))*unit,staff+Vector2(0,2-9*(1.0-plant))*unit,Color("4a3325"),3*unit)
			draw_rect(Rect2(staff+Vector2(-2,-94-9*(1.0-plant))*unit,Vector2(5,5)*unit),Color("d1ae68"))
			var ring:=_progress(motion-.72,1.2)
			if motion>.72 and ring<1.0:
				draw_arc(staff+Vector2(0,2)*unit,(4+17*ring)*unit,0,TAU,20,Color(.96,.80,.50,.43*(1.0-ring)),unit)
				for i in range(5):
					var dust:=staff+Vector2((-14+float(i)*7)*unit,(1.0-4.0*ring-float(i%2)*3)*unit)
					draw_rect(Rect2(dust,Vector2(3,2)*unit),Color(.91,.74,.48,.35*(1.0-ring)))
		for i in range(2):
			_draw_corporate_guard(Vector2(view.x*(.73+float(i)*.12),view.y*.63),unit*1.67,0.0)
		if motif_beat==5:
			var kinasih_ground:=view.y*.655
			_actor(Vector2(view.x*.30,kinasih_ground),unit*_focal_scale("kinasih"),Color("6c8e88"),true,0.0,"kinasih")
			draw_rect(Rect2(view.x*.315,kinasih_ground-45*unit,5*unit,7*unit),Color("7bd5c2"))

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

func _balai_council_pose(view: Vector2, motion: float, index: int) -> Dictionary:
	var unit:=_unit(view)
	var x: float=[.25,.39,.53,.67,.86][index]
	var entrance:=smoothstep(0.0,1.0,_progress(motion-float(index)*.10,.86))
	var direction:=1.0 if index<3 else -1.0
	var shake:=0.0 if EnvironmentState.reduced_motion else sin(motion*23.0+float(index)*1.7)*2.0*unit*(1.0-_progress(motion,1.15))
	var floor_y:=.67 if index==0 else .64
	var feet:=Vector2(view.x*x-direction*13*unit*(1.0-entrance),view.y*floor_y+shake)
	var stride:=sin(motion*12.0+float(index)*PI*.65)*.50 if entrance<1.0 else 0.0
	return {"feet":feet,"stride":stride}

func _draw_earthquake(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	var map_center:=Vector2(view.x*.70,view.y*.53)
	if motif_beat==1:
		var ring:=_progress(motion,1.2)
		draw_arc(Vector2(view.x*.73,view.y*.54),(7.0+ring*25)*unit,0,TAU,12,Color(.74,.35,.85,.35*(1.0-ring)),unit)
		for i in range(5):
			var chip:=Vector2(view.x*(.28+float(i)*.12),view.y*(.565+float(i%2)*.015))
			var quake:=0.0 if EnvironmentState.reduced_motion else sin(motion*18.0+float(i)*1.8)*3*unit*(1.0-ring)
			draw_rect(Rect2(chip+Vector2(0,quake),Vector2(2,2)*unit),Color(.64,.43,.61,.30*(1.0-ring)))
		for i in [1,2,3,4,0]:
			var council_key: String=["lurah","wira","beno","saras","raka"][i]
			var pose:=_balai_council_pose(view,motion,i)
			var actor_scale:=_focal_scale("lurah") if i==0 else 2.05
			_actor(pose.feet,unit*actor_scale,Color("72583e").lerp(Color("a1846a"),float(i%3)/2.0),false,pose.stride,council_key)
	elif motif_beat==2:
		_actor(Vector2(view.x*.24,view.y*.64),unit*SUPPORT_STAGE_SCALES["balai_council"],Color("72583e"),false,0.0,"lurah")
		_actor(Vector2(view.x*.82,view.y*.66),unit*_focal_scale("raka"),Color("e6e1d6"),false,0.0,"raka")
	elif motif_beat==3:
		_actor(Vector2(view.x*.42,view.y*.64),unit*_focal_scale("kinasih"),Color("6c8e88"),true,0.0,"kinasih")
		for i in range(4):
			var p:=Vector2(view.x*(.53+float(i)*.045),view.y*(.36-float(i%2)*.06)+sin(motion*1.6+float(i))*3*unit)
			draw_circle(p,3*unit,Color(.45,.95,.94,.55))
	else:
		var speaker_key: String=["saras","beno","wira"][motif_beat-4]
		var support_index:=0
		for i in range(4):
			var council_key: String=["lurah","wira","beno","saras"][i]
			var feet:=Vector2(view.x*.82,view.y*.66)
			if council_key!=speaker_key:
				feet=Vector2(view.x*(.17+float(support_index)*.14),view.y*.64)
				support_index+=1
			_actor(feet,unit*_focal_scale(council_key,SUPPORT_STAGE_SCALES["balai_council"]),Color("5c7f77").lerp(Color("b06b46"),float(i%2)),false,0.0,council_key)
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

func _boss_sprite_point(view: Vector2, source: Vector2) -> Vector2:
	var boss: Control=get_parent().get("boss_art") if get_parent()!=null else null
	var display_rect:=boss.get_rect() if boss!=null else Rect2(view.x*.50,view.y*.12,view.x*.48,view.y*.56)
	var box:=display_rect.size
	var scale:=minf(box.x/224.0,box.y/160.0)
	var top_left:=display_rect.position+(box-Vector2(224,160)*scale)*.5
	return top_left+source*scale

func _draw_boss_condition(view: Vector2, healed: bool, tethered: bool, motion: float) -> void:
	var unit:=_unit(view)
	var eye:=_boss_sprite_point(view,Vector2(57,65))
	var healing:=smoothstep(0.0,1.0,_progress(motion,1.2)) if healed and motif_beat==1 else (1.0 if healed else 0.0)
	var eye_color:=Color("ef3f59").lerp(Color("59e6ed"),healing)
	draw_rect(Rect2(eye-Vector2(5,4)*unit,Vector2(10,8)*unit),Color("242b35"))
	draw_rect(Rect2(eye-Vector2(3,3)*unit,Vector2(7,6)*unit),eye_color)
	draw_rect(Rect2(eye+Vector2(0,-2)*unit,Vector2(2,2)*unit),Color("fff4c5"))
	var crown:=_boss_sprite_point(view,Vector2(45,50))
	draw_rect(Rect2(crown-Vector2(4,4)*unit,Vector2(9,9)*unit),Color("8e3cab" if not healed else "69e9e9",.41 if not healed else .32))
	if healed:
		for offset in [Vector2(-16,-6),Vector2(12,10),Vector2(36,27)]:
			var glint: Vector2=eye+offset*unit
			draw_rect(Rect2(glint,Vector2(3,3)*unit),Color(.54,1.0,.94,.73*healing))
		return
	var binding:=_boss_sprite_point(view,Vector2(76,77))
	draw_line(binding+Vector2(-12,-7)*unit,binding+Vector2(13,7)*unit,Color("442d54"),5*unit)
	draw_line(binding+Vector2(-12,-7)*unit,binding+Vector2(13,7)*unit,Color("ab56bf"),2*unit)
	for i in range(3):
		var bead:=binding+Vector2(-9+float(i)*9,-5+float(i)*5)*unit
		draw_rect(Rect2(bead,Vector2(3,3)*unit),Color("e18be5"))
	if tethered:
		var head_anchor:=_boss_sprite_point(view,Vector2(52,35))
		var joint:=head_anchor.lerp(_pipe_outlet(view),.48)+Vector2(0,7)*unit
		draw_line(head_anchor,joint,Color("4d325d"),5*unit)
		draw_line(joint,_pipe_outlet(view),Color("4d325d"),5*unit)
		draw_line(head_anchor,joint,Color("b963c8"),2*unit)
		draw_line(joint,_pipe_outlet(view),Color("b963c8"),2*unit)
		for i in range(3):
			var link:=head_anchor.lerp(joint,float(i+1)/4.0)
			draw_rect(Rect2(link-Vector2(2,2)*unit,Vector2(4,4)*unit),Color("d692da"))

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
		var origin:=_pipe_outlet(view,true)
		var seal:=_progress(motion,1.7)
		var stone_start:=Vector2(view.x*.59,view.y*.50)
		var stone_at:=stone_start.lerp(origin,seal)+Vector2(0,-sin(seal*PI)*24*unit)
		draw_colored_polygon(PackedVector2Array([
			stone_at+Vector2(-14,-9)*unit,stone_at+Vector2(3,-13)*unit,
			stone_at+Vector2(16,-4)*unit,stone_at+Vector2(13,10)*unit,
			stone_at+Vector2(-7,12)*unit,stone_at+Vector2(-17,3)*unit
		]),Color("33484b"))
		draw_colored_polygon(PackedVector2Array([
			stone_at+Vector2(-13,-10)*unit,stone_at+Vector2(2,-14)*unit,
			stone_at+Vector2(14,-6)*unit,stone_at+Vector2(10,7)*unit,
			stone_at+Vector2(-6,9)*unit,stone_at+Vector2(-15,1)*unit
		]),Color("b8aa82"))
		draw_line(stone_at+Vector2(-9,-7)*unit,stone_at+Vector2(1,-10)*unit,Color("e2cd97"),2*unit)
		draw_line(stone_at+Vector2(-3,1)*unit,stone_at+Vector2(5,5)*unit,Color("60797a"),2*unit)
		if seal>.82:
			var pulse:=.45+.30*absf(sin(motion*3.0))
			draw_arc(origin,18*unit,0,TAU,24,Color(.47,.97,.92,pulse),2*unit)
			for i in range(4):
				var brace:=origin+Vector2(cos(float(i)*TAU/4.0),sin(float(i)*TAU/4.0))*17*unit
				draw_rect(Rect2(brace,Vector2(3,3)*unit),Color("d9c493"))
		var nala:=Vector2(view.x*.38,view.y*.53)
		_draw_swimmer(nala,unit,motion)
		var trunk_tip:=_boss_sprite_point(view,Vector2(27,108))
		var helmet:=nala+Vector2(-14,-18)*unit
		if motion>1.0 and trunk_tip.distance_to(helmet)<85*unit:
			var touch_strength:=smoothstep(0.0,1.0,_progress(motion-1.0,.5))
			draw_line(trunk_tip,helmet,Color(.68,.98,.92,.27*touch_strength),3*unit)
			draw_arc(helmet,5*unit,0,TAU,16,Color(.71,1.0,.95,.66*touch_strength),unit)
		var handoff:=smoothstep(0.0,1.0,_progress(motion-1.05,1.2))
		var tablet_origin:=_boss_sprite_point(view,Vector2(42,94))
		var tablet:=tablet_origin.lerp(nala+Vector2(5,13)*unit,handoff)+Vector2(0,-sin(handoff*PI)*14*unit)
		draw_rect(Rect2(tablet,Vector2(16,12)*unit),Color("c6a669"))
		draw_rect(Rect2(tablet,Vector2(16,12)*unit),Color("705a3e"),false,unit)
		draw_rect(Rect2(tablet+Vector2(5,3)*unit,Vector2(6,5)*unit),Color("5fe9eb"))
	else:
		var sweep:=_progress(motion,2.7)
		if sweep<1.0:
			draw_line(Vector2(view.x*sweep,view.y*.15),Vector2(view.x*sweep,view.y*.69),Color(.55,1.0,.92,.30*(1.0-sweep)),3*unit)
		draw_rect(Rect2(0,view.y*(.52-.48*sweep),view.x,5*unit),Color(.56,1.0,.93,.08*(1.0-sweep)))
		_draw_victory_piers(view,unit)
		_draw_victory_sampan(view,unit,motion)
		var emerge:=smoothstep(0.0,1.0,clampf(motion/1.7,0.0,1.0))
		_draw_nala_daily(Vector2(view.x*.52,view.y*(.70-.06*emerge)),unit*WIDE_STAGE_SCALES["victory_nala"],4)
		var tablet:=Vector2(view.x*.52,view.y*(.42-.07*emerge))
		draw_rect(Rect2(tablet,Vector2(12,9)*unit),Color("d8ad69"))
		draw_rect(Rect2(tablet+Vector2(3,2)*unit,Vector2(5,4)*unit),Color("59e4df"))
		_actor(Vector2(view.x*.40,view.y*.62),unit*WIDE_STAGE_SCALES["victory_beno"],Color("7c7958"),false,0.0,"beno")
		for i in range(5):
			var child_key: String=["gito","bagas","kinasih","cempaka","danu"][i]
			var hop:=0.0 if EnvironmentState.reduced_motion else absf(sin(motion*4.0+float(i)*.9))*3.0*unit
			var mark: Vector2=VICTORY_CHILD_MARKS[i]
			_actor(Vector2(view.x*mark.x,view.y*mark.y-hop),unit*WIDE_STAGE_SCALES["victory_child"],Color("7c7958"),true,0.0,child_key)
		for i in range(2):
			var resident_key: String=["darmi","ujang"][i]
			var resident_feet:=Vector2(view.x*(.78+float(i)*.12),view.y*.62)
			_actor(resident_feet,unit*WIDE_STAGE_SCALES["victory_resident"],Color("8c7654"),false,0.0,resident_key)
			var release:=smoothstep(0.0,1.0,_progress(motion-.4-float(i)*.18,1.1))
			var capsule:=resident_feet+Vector2(16+release*8,-28+release*25)*unit
			draw_rect(Rect2(capsule,Vector2(5,9)*unit),Color("a854b3"))
			draw_rect(Rect2(capsule+Vector2(1,1)*unit,Vector2(3,2)*unit),Color("df9be1"))
	for i in range(34):
		var rise:=fposmod(motion*(15.0+float(i%5)*4.0)+float(i)*12.0,view.y*.75)
		var x:=view.x*(.23+float((i*17)%67)*.009)
		var y:=view.y*.79-rise
		draw_rect(Rect2(x,y,(1.0+float(i%3))*unit,(1.0+float(i%3))*unit),Color(.38,.99,.96,.28+float(i%3)*.13))

func _victory_berth(view: Vector2) -> Rect2:
	return Rect2(view.x*.43,view.y*.60,view.x*.25,view.y*.12)

func _draw_victory_piers(view: Vector2, unit: float) -> void:
	var berth:=_victory_berth(view)
	var rear:=Rect2(0,view.y*.53,view.x,view.y*.07)
	var left:=Rect2(0,berth.position.y,berth.position.x,berth.size.y)
	var right:=Rect2(berth.end.x,berth.position.y,view.x-berth.end.x,berth.size.y)
	var water:=PackedVector2Array([
		berth.position+Vector2(0,3)*unit,
		Vector2(berth.end.x,berth.position.y+3*unit),
		berth.end-Vector2(3,0)*unit,
		Vector2(berth.position.x+3*unit,berth.end.y)
	])
	draw_colored_polygon(water,Color("235f62"))
	for band in range(3):
		var ripple_y:=berth.position.y+(12+band*10)*unit
		draw_line(Vector2(berth.position.x+9*unit,ripple_y),Vector2(berth.end.x-11*unit,ripple_y-2*unit),Color("397f78",.48-band*.08),unit)
	for deck in [rear,left,right]:
		draw_rect(deck,Color("704d31"))
	for row in range(1,7):
		var y:=view.y*(.53+float(row)*.03)
		var spans: Array=[Vector2(0,view.x)] if y<view.y*.60 else [Vector2(0,left.end.x),Vector2(right.position.x,view.x)]
		for span in spans:
			draw_line(Vector2(span.x,y),Vector2(span.y,y),Color("4c3829"),unit)
			draw_line(Vector2(span.x,y+2*unit),Vector2(span.y,y+2*unit),Color("9f7148"),unit)
			for board in range(1,19):
				var seam_x: float=span.x+(float(board)+float(row%2)*.5)*38*unit
				if seam_x>=span.y-6*unit: break
				draw_line(Vector2(seam_x,y-6*unit),Vector2(seam_x,y-unit),Color("493326"),unit)
				draw_rect(Rect2(seam_x+3*unit,y-5*unit,2*unit,2*unit),Color("c39a62"))
	draw_line(Vector2(0,view.y*.53),Vector2(view.x,view.y*.53),Color("d49f64"),2*unit)
	draw_line(Vector2(0,view.y*.72),Vector2(left.end.x,view.y*.72),Color("d49f64"),2*unit)
	draw_line(Vector2(right.position.x,view.y*.72),Vector2(view.x,view.y*.72),Color("d49f64"),2*unit)
	for span in [Vector2(0,left.end.x),Vector2(right.position.x,view.x)]:
		draw_rect(Rect2(span.x,view.y*.72,span.y-span.x,5*unit),Color("3a2b23"))
		draw_line(Vector2(span.x,view.y*.72),Vector2(span.y,view.y*.72),Color("b6814c"),unit)
	for support_x in [.12,.36,.76,.91]:
		var x:=view.x*float(support_x)
		draw_rect(Rect2(x-3*unit,view.y*.735,7*unit,view.y*.075),Color("382d27"))
		draw_line(Vector2(x+2*unit,view.y*.735),Vector2(x+2*unit,view.y*.80),Color("795437"),unit)
	for mouth_x in [left.end.x,right.position.x]:
		var facing:=1.0 if mouth_x<view.x*.5 else -1.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(mouth_x,berth.position.y+3*unit),
			Vector2(mouth_x+facing*5*unit,berth.position.y+6*unit),
			Vector2(mouth_x+facing*4*unit,berth.end.y),
			Vector2(mouth_x,berth.end.y)
		]),Color("322b25"))
		draw_rect(Rect2(mouth_x-4*unit,view.y*.55,8*unit,view.y*.17),Color("4c3526"))
		draw_rect(Rect2(mouth_x-5*unit,view.y*.55,10*unit,4*unit),Color("c6965d"))
		draw_rect(Rect2(mouth_x-3*unit,view.y*.61,6*unit,2*unit),Color("b18a58"))

func _draw_victory_sampan(view: Vector2, unit: float, motion: float) -> void:
	var berth:=_victory_berth(view)
	var boat_unit:=unit*2.25
	var boat:=Vector2(view.x*.535,view.y*.635)
	var bob:=0.0 if EnvironmentState.reduced_motion else sin(motion*2.1)*unit*.7
	boat.y+=bob
	var hull:=PackedVector2Array([
		boat+Vector2(-31,0)*boat_unit,boat+Vector2(-25,-2)*boat_unit,
		boat+Vector2(25,-2)*boat_unit,boat+Vector2(32,0)*boat_unit,
		boat+Vector2(23,11)*boat_unit,boat+Vector2(13,13)*boat_unit,
		boat+Vector2(-18,13)*boat_unit,boat+Vector2(-27,10)*boat_unit
	])
	draw_colored_polygon(PackedVector2Array([
		boat+Vector2(-27,10)*boat_unit,boat+Vector2(26,10)*boat_unit,
		boat+Vector2(21,14)*boat_unit,boat+Vector2(-21,14)*boat_unit
	]),Color("123d45",.7))
	draw_colored_polygon(hull,Color("3d281e"))
	draw_colored_polygon(PackedVector2Array([
		boat+Vector2(-26,1)*boat_unit,boat+Vector2(27,1)*boat_unit,
		boat+Vector2(20,8)*boat_unit,boat+Vector2(-20,8)*boat_unit
	]),Color("734729"))
	draw_colored_polygon(PackedVector2Array([
		boat+Vector2(-23,0)*boat_unit,boat+Vector2(23,0)*boat_unit,
		boat+Vector2(16,4)*boat_unit,boat+Vector2(-16,4)*boat_unit
	]),Color("2d2824"))
	draw_line(boat+Vector2(-31,0)*boat_unit,boat+Vector2(31,0)*boat_unit,Color("d9a867"),2*unit)
	draw_line(boat+Vector2(-23,8)*boat_unit,boat+Vector2(21,8)*boat_unit,Color("ad7040"),unit)
	for rib in [-12.0,0.0,12.0]:
		draw_line(boat+Vector2(rib,4)*boat_unit,boat+Vector2(rib+3,8)*boat_unit,Color("a36b3f"),unit)
	for side in [-1.0,1.0]:
		var wake:=boat+Vector2(side*29,9)*boat_unit
		draw_line(wake,wake+Vector2(side*10,1)*unit,Color(.59,.91,.83,.43),unit)

func _feast_witness_pose(view: Vector2, motion: float, index: int) -> Dictionary:
	var arrival:=smoothstep(0.0,1.0,_progress(motion-float(index)*.12,.92))
	var x:=lerpf(.12,.18,arrival) if index==0 else lerpf(.45,.39,arrival)
	var feet:=Vector2(view.x*x,view.y*.665)
	var stride:=sin(motion*11.0+float(index)*PI)*.42 if arrival<1.0 else 0.0
	return {"feet":feet,"stride":stride}

func _draw_feast(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	for i in range(5):
		var lamp:=Vector2(view.x*(.16+float(i)*.18),view.y*.27)
		draw_rect(Rect2(lamp,Vector2(7,9)*unit),Color("dd9d4a"))
		draw_circle(lamp+Vector2(3,4)*unit,(8+sin(motion*2+float(i)))*unit,Color(1.0,.78,.38,.12))
	for table_fraction in [.405,.585]:
		var table_x:=view.x*float(table_fraction)
		var table_y:=view.y*.645
		draw_colored_polygon(PackedVector2Array([
			Vector2(table_x-31*unit,table_y),Vector2(table_x+31*unit,table_y),
			Vector2(table_x+36*unit,table_y+5*unit),Vector2(table_x-36*unit,table_y+5*unit)
		]),Color("a66a3c"))
		draw_line(Vector2(table_x-31*unit,table_y),Vector2(table_x+31*unit,table_y),Color("dfad70"),2*unit)
		for side in [-1.0,1.0]:
			draw_rect(Rect2(table_x+side*27*unit,table_y+5*unit,3*unit,9*unit),Color("583720"))
			var cup:=Vector2(table_x+side*13*unit,table_y-5*unit)
			draw_rect(Rect2(cup,Vector2(6,5)*unit),Color("e0ae70"))
			draw_rect(Rect2(cup+Vector2(1,1)*unit,Vector2(4,1)*unit),Color("699a6d"))
	var stand_t:=smoothstep(0.0,1.0,_progress(motion,1.1)) if motif_beat==2 else 0.0
	if motif_beat==2:
		var back_keys: Array[String]=["darmi","ujang","sari","beno"]
		var back_x: Array[float]=[.08,.29,.48,.55]
		for i in range(back_keys.size()):
			_actor(Vector2(view.x*back_x[i],view.y*.625),unit*SUPPORT_STAGE_SCALES["feast_"+back_keys[i]],Color("7c714b"),false,0.0,back_keys[i])
		for i in range(2):
			var witness_key: String=["ratih","tedi"][i]
			var pose:=_feast_witness_pose(view,motion,i)
			_actor(pose.feet,unit*2.45,Color("7c714b"),false,pose.stride,witness_key)
	else:
		var people_positions := [Vector2(.08,.67),Vector2(.16,.68),Vector2(.24,.67),Vector2(.32,.68),Vector2(.40,.67),Vector2(.48,.68)]
		var people_keys := ["ratih","tedi","darmi","ujang","sari","wira"]
		for i in range(people_positions.size()):
			var villager_key: String=people_keys[i]
			var hop:=0.0 if motif_beat!=3 or EnvironmentState.reduced_motion else absf(sin(motion*3.0+float(i)*.8))*2*unit
			var spot: Vector2=people_positions[i]
			_actor(Vector2(view.x*spot.x,view.y*spot.y-hop),unit*SUPPORT_STAGE_SCALES["feast_"+villager_key],Color("7c714b"),false,0.0,villager_key)
	var lurah_steps:=smoothstep(0.0,1.0,_progress(motion,.85)) if motif_beat==2 else 0.0
	var lurah_x:=lerpf(.685,.60,lurah_steps)
	var lurah_y:=lerpf(.655,.69,lurah_steps)
	var lurah_scale:=lerpf(1.35,2.52,lurah_steps)
	if motif_beat==3:
		lurah_x=lerpf(.60,.51,smoothstep(0.0,1.0,_progress(motion,1.5)))
		lurah_y=.69
		lurah_scale=2.52
	_actor(Vector2(view.x*lurah_x,view.y*lurah_y),unit*lurah_scale,Color("866c51"),false,0.0,"lurah")
	if motif_beat<=2:
		var arrive:=smoothstep(0.0,1.0,_progress(motion,1.3)) if motif_beat==1 else 1.0
		var raka_x:=lerpf(.96,.79,arrive)
		_actor(Vector2(view.x*raka_x,view.y*.69),unit*2.66,Color("e0e3d9"),false,0.0,"raka")
		for i in range(2):
			_draw_corporate_guard(Vector2(view.x*(raka_x+.08+float(i)*.065),view.y*.62),unit*1.65)
		var letter_at:=Vector2(view.x*(raka_x-.055),view.y*.69-39*unit)
		if motif_beat==2:
			letter_at=Vector2(view.x*.75,view.y*(.52+.15*stand_t))
		_draw_seal_letter(letter_at,unit*.85,motif_beat==2)
	if motif_beat==3:
		var retreat:=smoothstep(0.0,1.0,_progress(motion,2.5))
		_actor(Vector2(view.x*(.79+.30*retreat),view.y*.69),unit*2.66,Color("e0e3d9"),false,0.0,"raka")
		for i in range(2):
			_draw_corporate_guard(Vector2(view.x*(.87+.30*retreat+float(i)*.065),view.y*.62),unit*1.65)
		var gito_enter:=smoothstep(0.0,1.0,_progress(motion,1.3))
		_actor(Vector2(view.x*lerpf(.43,.69,gito_enter),view.y*lerpf(.63,.68,gito_enter)),unit*lerpf(1.70,2.46,gito_enter),Color("af7945"),true,0.0,"gito")
		var boat:=Vector2(view.x*(.79+retreat*.22),view.y*.51)
		draw_colored_polygon(PackedVector2Array([boat+Vector2(-25,0)*unit,boat+Vector2(26,0)*unit,boat+Vector2(17,9)*unit,boat+Vector2(-18,9)*unit]),Color("2b343a"))
		draw_line(boat+Vector2(4,0)*unit,boat+Vector2(4,-29)*unit,Color("525d5c"),2*unit)
		draw_rect(Rect2(boat+Vector2(4,-27)*unit,Vector2(14,8)*unit),Color("75365c"))

func _draw_finale(view: Vector2, motion: float) -> void:
	var unit:=_unit(view)
	var nala_feet:=Vector2(view.x*.28,view.y*.69)
	_draw_nala_daily(nala_feet+Vector2(0.0,sin(motion*1.1)*unit*.45),unit*_focal_scale("nala",.92),0)
	draw_line(Vector2(view.x*.40,view.y*.45),Vector2(view.x*.58,view.y*.37),Color(.60,.93,1.0,.16),2*unit)
	for i in range(24):
		var x:=view.x*(.08+float((i*19)%83)*.01)
		var y:=view.y*(.13+float((i*7)%52)*.01)+sin(motion*.8+float(i))*2*unit
		draw_rect(Rect2(x,y,(1.0+float(i%2))*unit,(1.0+float(i%2))*unit),Color(.68,1.0,.91,.63))
	if motif_beat != 8: return
	var card:=Rect2(Vector2(view.x*.42,view.y*.275),Vector2(view.x*.54,view.y*.305))
	draw_rect(card,Color(.075,.13,.15,.88))
	draw_rect(card,Color("d4a359"),false,3*unit)
	draw_rect(Rect2(card.position+Vector2(5,5)*unit,card.size-Vector2(10,10)*unit),Color(.43,.78,.75,.80),false,unit)
	draw_string(PIXEL_FONT,Vector2(card.position.x,card.position.y+39*unit),"TERIMA KASIH TELAH BERMAIN",HORIZONTAL_ALIGNMENT_CENTER,card.size.x,roundi(20*unit),Color("f7ddae"))
	draw_string(BODY_FONT,Vector2(card.position.x,card.position.y+64*unit),"JALA SMARA · FASE 1",HORIZONTAL_ALIGNMENT_CENTER,card.size.x,roundi(16*unit),Color("9cf1df"))
	draw_string(BODY_FONT,Vector2(card.position.x,card.position.y+90*unit),"Bersiap menuju Zona Senja Abisal",HORIZONTAL_ALIGNMENT_CENTER,card.size.x,roundi(16*unit),Color("e8d8ae"))

