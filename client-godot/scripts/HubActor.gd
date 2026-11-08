extends Node2D
var actor_name := ""
var crate := false
func _process(_delta: float) -> void:
	visible = GameState.dive.is_empty()
func _draw() -> void:
	if crate:
		draw_rect(Rect2(-35,-30,70,52),Color("785a3d"))
		draw_colored_polygon(PackedVector2Array([Vector2(-35,-30),Vector2(-22,-44),Vector2(47,-44),Vector2(35,-30)]),Color("b18a59"))
		draw_line(Vector2(-24,-15),Vector2(25,-15),Color("bc9e67"),3)
		return
	draw_set_transform(Vector2(0,16),0,Vector2(1,.35))
	draw_circle(Vector2.ZERO,14,Color(0.04,.13,.11,.3))
	draw_set_transform(Vector2.ZERO)
	var cloth := Color("9b704c") if actor_name=="Mbah Wira" else Color("385d70") if actor_name=="Beno" else Color("63875d") if actor_name=="Bu Darmi" else Color("c7d2ca")
	draw_rect(Rect2(-7,-25,14,12),Color("b98b62"))
	draw_rect(Rect2(-8,-28,16,6),Color("7c493b") if actor_name=="Beno" else Color("3b4b42"))
	draw_rect(Rect2(-11,-11,22,24),cloth)
	draw_rect(Rect2(-9,13,7,11),Color("243b40"))
	draw_rect(Rect2(3,13,7,11),Color("243b40"))
	if actor_name=="Mbah Wira":
		draw_rect(Rect2(-7,-17,14,8),Color("e1debe"))
	if actor_name=="Beno":
		draw_rect(Rect2(-8,-22,16,5),Color("bdc8aa"))
	if actor_name=="Bu Darmi":
		draw_circle(Vector2(-9,-4),15,Color("b39c65"))
	if actor_name=="Inspektur Raka":
		draw_rect(Rect2(-8,-22,16,3),Color("cb7464"))
	draw_string(ThemeDB.fallback_font,Vector2(-40,-40),actor_name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f1e6c6"))
