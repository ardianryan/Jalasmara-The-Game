extends RefCounted

static func foundations(a: Vector2, b: Vector2, width: float, deck: PackedVector2Array, surfaces: Array, elevation: float) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	var axis:=(b-a).normalized()
	if axis.is_zero_approx(): return result
	var side:=Vector2(-axis.y,axis.x)*width*.5
	var length:=minf(64.0,a.distance_to(b)*.25)
	for end_index in range(2):
		var first:=a if end_index==0 else b-axis*length
		var last:=a+axis*length if end_index==0 else b
		var strip:=PackedVector2Array([first-side,last-side,last+side,first+side])
		for clipped_deck in Geometry2D.intersect_polygons(strip,deck):
			var contacts: Array[Dictionary]=[]
			var contact_area:=0.0
			for surface in surfaces:
				if not bool(surface.get("walkable",true)) or str(surface.get("material",""))=="bridge": continue
				if not is_equal_approx(float(surface.get("elevation",0)),elevation): continue
				var bank:=PackedVector2Array()
				for point in surface.get("polygon",[]): bank.append(Vector2(float(point[0]),float(point[1])))
				for footprint in Geometry2D.intersect_polygons(clipped_deck,bank):
					if footprint.size()<3 or absf(_area(footprint))<4.0: continue
					contact_area+=absf(_area(footprint))
					contacts.append({"bankId":str(surface.get("id","")),"polygon":footprint})
			var support_fraction:=minf(1.0,contact_area/maxf(1.0,absf(_area(clipped_deck))))
			if support_fraction>=.20: result.append({"end":end_index,"polygon":clipped_deck,"contacts":contacts,"supportFraction":support_fraction})
	return result

static func _area(polygon: PackedVector2Array) -> float:
	var sum:=0.0
	for index in range(polygon.size()): sum+=polygon[index].cross(polygon[(index+1)%polygon.size()])
	return sum*.5
