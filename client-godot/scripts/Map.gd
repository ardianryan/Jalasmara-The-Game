extends Control
var rocks: Array[Rect2] = []
var player_point := Vector2.ZERO
func _draw() -> void:
	var scale_map := Vector2(590.0/6144.0,220.0/3584.0)
	draw_rect(Rect2(Vector2.ZERO,Vector2(590,220)),Color("0a2635"))
	var colors := [Color("286b70"),Color("235a5a"),Color("24434b"),Color("172d3c")]
	var starts := [400,1100,2080,3060]
	var ends := [1100,2080,3060,3500]
	for i in range(4):
		draw_rect(Rect2(Vector2(0,starts[i])*scale_map,Vector2(6144,ends[i]-starts[i])*scale_map),colors[i])
	for r in rocks:
		draw_rect(Rect2(r.position*scale_map,r.size*scale_map),Color("738373"))
	for landmark in GameState.world.get("landmarks",[]):
		var point := Vector2(float(landmark.x),float(landmark.y))*scale_map
		var known: bool = GameState.adventure.get("discoveries",[]).has(landmark.id)
		draw_circle(point,3,Color("e5c787") if known else Color("688b8b"))
	for item in GameState.world.get("puzzles",[]):
		var point := Vector2(float(item.x),float(item.y))*scale_map
		draw_rect(Rect2(point-Vector2(3,3),Vector2(6,6)),Color("91c6a1"))
	var p := player_point*scale_map
	draw_circle(p,5,Color("f2c27e"))
	draw_circle(p,2,Color("fff0c7"))
