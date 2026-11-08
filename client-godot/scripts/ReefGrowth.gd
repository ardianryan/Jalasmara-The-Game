extends RefCounted

static func placements(world: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 18342
	var contours: Array = world.get("terrainContours",[])
	var rectangles: Array = world.get("terrain",[])
	for index in rectangles.size():
		var entry: Array = rectangles[index]
		var rect := Rect2(float(entry[0]),float(entry[1]),float(entry[2]),float(entry[3]))
		if rect.position.y<550 or rect.position.y>3300 or rect.size.x<250 or index>=contours.size(): continue
		var x := rect.position.x+rng.randf_range(45,110)
		while x<rect.end.x-45:
			var top := INF
			var polygon: Array = contours[index]
			for edge in polygon.size():
				var a := Vector2(float(polygon[edge][0]),float(polygon[edge][1]))
				var b := Vector2(float(polygon[(edge+1)%polygon.size()][0]),float(polygon[(edge+1)%polygon.size()][1]))
				if absf(b.x-a.x)<0.01 or x<minf(a.x,b.x) or x>maxf(a.x,b.x): continue
				top = minf(top,lerpf(a.y,b.y,(x-a.x)/(b.x-a.x)))
			if is_finite(top) and rng.randf()>0.18:
				var width := rng.randf_range(90,170)
				result.append({"at":Vector2(x,top+7),"kind":rng.randi_range(0,2),"size":Vector2(width,width*rng.randf_range(0.65,0.95)),"flip":rng.randf()>0.5})
			x += rng.randf_range(180,380)
	return result
