extends Node3D

const TILT := deg_to_rad(12.0)
var connections: Array[Dictionary] = []
var triangle_count := 0
var _camera_offset := Vector2.ZERO

func _point(at: Vector2, depth: float) -> Vector3:
	return Vector3(at.x,-at.y+sin(TILT)*depth,depth)

func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	if (b-a).cross(c-a).z<0:
		var swap:=b
		b=c
		c=swap
	var normal:=(b-a).cross(c-a).normalized()
	for vertex in [a,b,c]:
		tool.set_normal(normal)
		tool.set_color(color)
		tool.set_uv(Vector2(vertex.x,-vertex.y+sin(TILT)*vertex.z)/360.0)
		tool.add_vertex(vertex)
	triangle_count+=1

func configure(world: Dictionary, materials: Array[Material]) -> void:
	var rectangles: Array[Rect2] = []
	for entry in world.get("terrain",[]): rectangles.append(Rect2(float(entry[0]),float(entry[1]),float(entry[2]),float(entry[3])))
	var floor_y:=float(world.get("height",3584))-84.0
	for index in range(rectangles.size()):
		var upper:=rectangles[index]
		if upper.position.y<500 or upper.position.y>=floor_y or upper.size.x<180 or upper.size.y>1000: continue
		var anchor_x:=upper.get_center().x
		var bottom_y:=floor_y+40
		var destination:=-1
		var overlap_left:=upper.position.x
		var overlap_right:=upper.end.x
		for candidate in range(rectangles.size()):
			var lower:=rectangles[candidate]
			if lower.position.y<=upper.end.y+40 or lower.position.y>=bottom_y: continue
			var left:=maxf(upper.position.x,lower.position.x)
			var right:=minf(upper.end.x,lower.end.x)
			if right-left<80: continue
			bottom_y=lower.position.y+minf(65,lower.size.y*.45)
			destination=candidate
			overlap_left=left
			overlap_right=right
		anchor_x=lerpf(overlap_left,overlap_right,.38+sin(index*1.73)*.12)
		var top_y:=upper.end.y-minf(42,upper.size.y*.22)
		if bottom_y-top_y<65: continue
		var spread:=minf(230,upper.size.x*.22)
		var column:=0 if upper.get_center().y<2080 else 1 if upper.get_center().y<3060 else 2
		_build_root(index,anchor_x,top_y,bottom_y,spread,materials[column],index==13 and destination==4)
		connections.append({"terrain":index,"anchoredTo":destination,"top":[anchor_x,top_y],"base":[anchor_x,bottom_y],"rearDepth":-210 if index==13 and destination==4 else -240,"decorativeRear":true,"collision":false,"profile":"flared_collar" if index==13 and destination==4 else "stratum"})

func _build_root(seed: int, x: float, top: float, bottom: float, spread: float, material: Material, collar := false) -> void:
	var rows:=maxi(7 if collar else 4,ceili((bottom-top)/105.0))
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(rows):
		for face in range(4):
			var corners: Array[Vector3] = []
			for pair in [Vector2i(row,face),Vector2i(row+1,face),Vector2i(row+1,face+1),Vector2i(row,face+1)]:
				var t:=float(pair.x)/rows
				var cross_section:=float(pair.y)/4.0
				var bend:=sin(t*PI)*sin(seed*2.17+t*4.1)*spread*.22
				var width:=spread*(.64+.48*t+sin(t*PI*3+seed)*.10)
				if collar:
					# The shoulder nests inside the existing ledge; the foot flares into terrain4.
					width=spread*(.96+.40*pow(1.0-t,5.0)+.75*pow(t,3.0))
				var at:=Vector2(x+bend+(cross_section-.5)*width*2,lerpf(top,bottom,t))
				var depth:=-240.0+sin(cross_section*PI)*65+sin(pair.x*1.73+seed)*18
				if collar: depth=-210.0+sin(cross_section*PI)*72.0+sin(pair.x*1.73+seed)*12.0
				corners.append(_point(at,depth))
			var shade:=Color(.42,.62,.63).lerp(Color(.58,.72,.68),float(face)/4.0)
			if collar:
				shade=Color(.64,.72,.68).lerp(Color(.80,.81,.70),sin((float(face)+.5)/4.0*PI))
				if row in [1,4]: shade=shade.darkened(.06)
			elif row%3==1: shade=shade.darkened(.10)
			_triangle(tool,corners[0],corners[1],corners[2],shade)
			_triangle(tool,corners[0],corners[2],corners[3],shade)
	var mesh:=MeshInstance3D.new()
	mesh.name="RearAnchoredStratum%d"%seed
	mesh.mesh=tool.commit()
	mesh.material_override=material
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)

func update_camera(_center: Vector2) -> void:
	# These roots join the playable reef; moving them would detach their seams.
	# Distant atmosphere has its own parallax in OceanBackdrop.
	_camera_offset=Vector2.ZERO
	position=Vector3.ZERO

func debug_status() -> Dictionary:
	return {"rearConnections":connections.size(),"connections":connections,"triangles":triangle_count,"parallaxOffset":[_camera_offset.x,_camera_offset.y],"collision":false}
