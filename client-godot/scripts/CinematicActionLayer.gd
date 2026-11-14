extends Control

# Small editable pixel constructions for three screenplay actions; no textures or physics.
var motif_id := ""
var motif_beat := 0
var elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	if not visible or size.x < 1.0 or size.y < 1.0: return
	var motion := 0.0 if EnvironmentState.reduced_motion else elapsed
	if motif_id == "prologue" and motif_beat == 6:
		_draw_arrival_boat(size, motion)
	elif motif_id == "boss_phase_two" and motif_beat == 1:
		_draw_fractured_pipe(size, motion)
	elif motif_id == "epilogue" and motif_beat >= 4:
		_draw_ancient_map(size, motion)

func _draw_arrival_boat(view: Vector2, motion: float) -> void:
	# A small deliberately pixel-stepped Nala and sampan, authored as editable shapes.
	var unit:=maxf(1.0,view.y/270.0)
	var crossing:=minf(motion/6.0,1.0)
	var origin:=Vector2(view.x*(.18+crossing*.19),view.y*.72+sin(motion*2.0)*unit)
	draw_set_transform(origin,0.0,Vector2(unit,unit))
	var hull:=PackedVector2Array([Vector2(-43,0),Vector2(42,0),Vector2(33,12),Vector2(20,17),Vector2(-27,17),Vector2(-39,10)])
	draw_colored_polygon(hull,Color("41291d"))
	draw_rect(Rect2(-38,1,74,3),Color("d39a55"))
	draw_rect(Rect2(-31,5,55,3),Color("86512c"))
	draw_rect(Rect2(-20,12,40,2),Color("b16b36"))
	draw_rect(Rect2(-3,-6,4,7),Color("24333c"))
	draw_rect(Rect2(3,-6,4,7),Color("27333a"))
	draw_rect(Rect2(-5,-18,14,13),Color("9a4d2d"))
	draw_rect(Rect2(-3,-17,8,10),Color("d8783c"))
	draw_rect(Rect2(8,-14,4,9),Color("5b382b"))
	draw_rect(Rect2(-2,-24,9,7),Color("c99468"))
	draw_rect(Rect2(5,-23,3,5),Color("3f2b23"))
	draw_rect(Rect2(-5,-26,15,3),Color("28343b"))
	draw_rect(Rect2(-1,-29,8,3),Color("54646b"))
	draw_rect(Rect2(7,-17,3,5),Color("c99468"))
	var stroke:=sin(motion*4.0)*5.0
	draw_line(Vector2(10,-7),Vector2(33+stroke,12),Color("f0c184"),2.0)
	draw_line(Vector2(33+stroke,12),Vector2(39+stroke,17),Color("90d8d4"),2.0)
	draw_set_transform(Vector2.ZERO)
	for i in range(3):
		var wake:=origin+Vector2((-55.0-float(i)*17.0)*unit,(10.0+float(i%2)*4.0)*unit)
		draw_rect(Rect2(wake,Vector2((12.0-float(i)*2.0)*unit,unit)),Color(.48,.94,.88,.28))

func _draw_fractured_pipe(view: Vector2, motion: float) -> void:
	var unit:=maxf(1.0,view.y/270.0)
	var break_ratio:=minf(motion/1.4,1.0)
	# The crack aligns with the large background pipe instead of inventing a second pipe.
	var origin:=Vector2(view.x*.84,view.y*.15)
	draw_set_transform(origin,0.0,Vector2(unit,unit))
	var crack:=PackedVector2Array([Vector2(-8,-11),Vector2(-1,-5),Vector2(-5,0),Vector2(4,6),Vector2(1,14)])
	for i in range(crack.size()-1):
		draw_line(crack[i],crack[i+1],Color(.10,.16,.19,.65*break_ratio),2.0)
	draw_line(Vector2(-4,-7),Vector2(7,-2),Color(.99,.78,.51,.85*break_ratio),1.0)
	draw_set_transform(Vector2.ZERO)
	for i in range(5):
		var angle:=float(i)*TAU/5.0+.18
		var end:=origin+Vector2(cos(angle),sin(angle))*(15.0+float(i%2)*5.0)*unit
		draw_line(origin,end,Color(.44,.99,.94,.56*break_ratio),unit)
	for i in range(12):
		var angle:=float(i)*2.399
		var drift:=Vector2(cos(angle),sin(angle))*(6.0+break_ratio*(8.0+float(i%4)*4.0))*unit
		var shard:=origin+drift
		draw_rect(Rect2(shard,Vector2(2.0+float(i%3),2.0)*unit),Color(.68,.93,.84,.68*break_ratio))

func _draw_ancient_map(view: Vector2, motion: float) -> void:
	var center:=Vector2(view.x*.43,view.y*.54)
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

