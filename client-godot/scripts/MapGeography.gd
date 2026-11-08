extends RefCounted

static func coastline(forest_offset: Vector2) -> PackedVector2Array:
	var corners := PackedVector2Array([
		Vector2(-150,-200),Vector2(500,-320),Vector2(1100,-260),Vector2(1800,-280),
		forest_offset+Vector2(-100,150),forest_offset+Vector2(600,-20),
		forest_offset+Vector2(1750,30),forest_offset+Vector2(2360,200),
		forest_offset+Vector2(2430,900),forest_offset+Vector2(2350,1500),
		forest_offset+Vector2(1600,1690),forest_offset+Vector2(780,1510),
		Vector2(2450,360),Vector2(2330,600),Vector2(2140,790),Vector2(2050,1040),
		Vector2(1770,1220),Vector2(1640,1230),Vector2(1560,1320),Vector2(1510,1380),
		Vector2(1350,1350),Vector2(1200,1340),Vector2(1010,1320),Vector2(850,1260),
		Vector2(660,1190),Vector2(330,1130),Vector2(-100,1090),Vector2(-180,650),
	])
	var curve := Curve2D.new()
	curve.bake_interval = 30
	for index in range(corners.size()+1):
		var at := index % corners.size()
		var previous := corners[posmod(at-1,corners.size())]
		var next := corners[(at+1)%corners.size()]
		var tangent := (next-previous)*0.12
		curve.add_point(corners[at],-tangent,tangent)
	var outline := curve.get_baked_points()
	outline.remove_at(outline.size()-1)
	return outline

static func forest_outline(offset: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in [Vector2(-50,450),Vector2(250,60),Vector2(1000,30),Vector2(1800,130),Vector2(2280,400),Vector2(2260,1250),Vector2(1600,1530),Vector2(900,1400),Vector2(430,1450),Vector2(100,1250)]:
		points.append(offset+point)
	return points

static func stream(offset: Vector2) -> Array:
	var points: Array = []
	for point in [Vector2(2360,60),Vector2(2290,210),Vector2(2230,400),Vector2(2010,435),Vector2(1830,470),Vector2(1950,650),Vector2(2160,820),Vector2(2330,1120),Vector2(2470,1410)]:
		points.append([offset.x+point.x,offset.y+point.y])
	return points
