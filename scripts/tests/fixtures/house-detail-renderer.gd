extends "res://scripts/land/LandWorld3D.gd"

var detail_enabled := false

func _house_parts(entry: Dictionary, rect: Rect2, center: Vector3) -> void:
	super._house_parts(entry,rect,center)
	if not detail_enabled or str(entry.get("variant","")) in ["metal","director_rv","balai","workshop"]: return
	var width: float=rect.size.x
	var depth: float=rect.size.y/cos(TILT)
	var height: float=float(entry.get("height3d",145))
	_shelter_architecture.add_house_details(self,entry,center,width,depth,height*.70,height)
