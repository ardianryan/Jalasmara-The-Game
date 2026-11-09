extends RefCounted

const SEGMENT_LENGTH:=34.0
const WOOD:=["dock","wood","bridge"]
var surfaces:=0
var segments:=0
var bevels:=0
var excluded:=0
var _root_material: ShaderMaterial
var _shade_material: ShaderMaterial
var _floors: Array=[]
var _backing:=PackedVector2Array()
var _routes: Array=[]

func build_surface(renderer: Node, surface: Dictionary, polygon: PackedVector2Array, height: float) -> bool:
	if str(surface.get("material","")) in WOOD: return false
	if polygon.size()<3: return false
	var profile:=make_profile(renderer,surface,polygon,height)
	if profile.is_empty(): return true
	var top: Dictionary=_buffer()
	var soil: Dictionary=_buffer()
	var stone: Dictionary=_buffer()
	var shade: Dictionary=_buffer()
	var root: Dictionary=_buffer()
	var nodes: Array=profile.nodes
	for index in range(nodes.size()):
		if not profile.active[index]: continue
		var next: int=(index+1)%nodes.size()
		var a: Array=nodes[index].rings
		var b: Array=nodes[next].rings
		var outward: Vector2=(nodes[index].outward+nodes[next].outward).normalized()
		var normal:=Vector3(outward.x,outward.y,0)
		_quad(top,a[0],b[0],b[1],a[1],index,Vector3(0,0,1))
		_quad(soil,a[1],b[1],b[2],a[2],index,normal)
		for band in range(2,5):
			var target: Dictionary=stone if (index+band*2)%5 in [0,1,4] else shade
			if band==4: target=root if index%3==0 else shade
			_quad(target,a[band],b[band],b[band+1],a[band+1],index+band,normal)
		segments+=1
	var material_id:=str(surface.get("material","grass"))
	_emit(renderer,"NaturalTerrainLip",top,renderer._materials.get_material(material_id))
	_emit(renderer,"NaturalTerrainSoil",soil,renderer._materials.get_material("stone" if material_id=="stone" else "dirt"))
	_emit(renderer,"NaturalTerrainShoulder",stone,renderer._materials.get_material("stone"))
	if _root_material==null:
		var base: Color=renderer._materials.get_material("stone").get_shader_parameter("base_color")
		_shade_material=renderer._materials.get_material("stone").duplicate()
		_shade_material.set_shader_parameter("base_color",Color(base.r*.84,base.g*.87,base.b*.89))
		_root_material=renderer._materials.get_material("stone").duplicate()
		_root_material.set_shader_parameter("base_color",Color(base.r*.68,base.g*.73,base.b*.77))
	_emit(renderer,"NaturalTerrainRockShade",shade,_shade_material)
	_emit(renderer,"NaturalTerrainRoot",root,_root_material)
	surfaces+=1
	bevels+=int(profile.bevels)
	excluded+=int(profile.excluded)
	return true

func make_profile(renderer: Node, surface: Dictionary, polygon: PackedVector2Array, height: float) -> Dictionary:
	if polygon.size()<3 or str(surface.get("material","")) in WOOD: return {}
	_prepare_support(renderer)
	var outline:=PackedVector2Array()
	for point in polygon:
		var world: Vector3=renderer.map_point(point,height)
		outline.append(Vector2(world.x,world.y))
	var orientation:=0.0
	for index in range(outline.size()): orientation+=outline[index].cross(outline[(index+1)%outline.size()])
	if absf(orientation)<.001: return {}
	var handedness:=signf(orientation)
	var nodes: Array=[]
	var corner_count:=0
	for index in range(outline.size()):
		var previous:=outline[(index+outline.size()-1)%outline.size()]
		var at:=outline[index]
		var next:=outline[(index+1)%outline.size()]
		var incoming: Vector2=(at-previous).normalized()
		var outgoing: Vector2=(next-at).normalized()
		var first:=Vector2(incoming.y,-incoming.x)*handedness
		var second:=Vector2(outgoing.y,-outgoing.x)*handedness
		var bisector: Vector2=(first+second).normalized()
		if bisector.is_zero_approx(): bisector=second
		# Convex corners share a three-facet fan; they are not separately placed rocks.
		if incoming.cross(outgoing)*handedness>.02:
			for normal in [first,bisector,second]: nodes.append(_node(polygon[index],at,normal,height))
			corner_count+=1
		else:
			nodes.append(_node(polygon[index],at,bisector,height))
		var parts:=maxi(1,ceili(at.distance_to(next)/SEGMENT_LENGTH))
		for part in range(1,parts):
			var t:=float(part)/parts
			nodes.append(_node(polygon[index].lerp(polygon[(index+1)%polygon.size()],t),at.lerp(next,t),second,height))
	for node in nodes: _shape_node(renderer,node,outline,height)
	var active: Array[bool]=[]
	var cutouts:=0
	for index in range(nodes.size()):
		var a: Dictionary=nodes[index]
		var b: Dictionary=nodes[(index+1)%nodes.size()]
		var allowed:=_allowed(renderer,surface,a,b)
		active.append(allowed)
		if not allowed: cutouts+=1
	for index in range(nodes.size()):
		var node: Dictionary=nodes[index]
		var endpoint:=not active[index] or not active[(index+nodes.size()-1)%nodes.size()]
		var flare:=0.0 if endpoint else 1.0
		var lip_xy: Vector2=node.world+node.outward*float(node.lip)*flare
		var soil_xy: Vector2=node.world+node.outward*(float(node.lip)+float(node.toe)*.04)*flare
		var tangent:=Vector2(-node.outward.y,node.outward.x)
		var stagger:=minf(SEGMENT_LENGTH*.60,float(node.toe)*.24)
		var upper_xy: Vector2=node.world+node.outward*float(node.upper)*flare+tangent*(float(node.noise)-.5)*stagger*.75*flare
		var belly_xy: Vector2=node.world+node.outward*float(node.belly)*flare+tangent*(.5-float(node.wave))*stagger*flare
		var toe_xy: Vector2=node.world+node.outward*float(node.toe)*flare
		var support:=_support_height(renderer,toe_xy,height)
		var bottom:=support-5.0
		var drop:=height-bottom
		var noise: float=node.noise
		var lip_z:=height-minf(1.5+noise*2.5,drop*.12)
		var soil_z:=height-minf(10.0+noise*5.0,drop*.30)
		node["support"]=support
		node["rings"]=[Vector3(node.world.x,node.world.y,height+.10),Vector3(lip_xy.x,lip_xy.y,lip_z),Vector3(soil_xy.x,soil_xy.y,soil_z),Vector3(upper_xy.x,upper_xy.y,lerpf(soil_z,bottom,.30+noise*.08)),Vector3(belly_xy.x,belly_xy.y,lerpf(soil_z,bottom,.66+float(node.wave)*.08)),Vector3(toe_xy.x,toe_xy.y,bottom)]
	return {"nodes":nodes,"active":active,"bevels":corner_count,"excluded":cutouts}

func _node(logical: Vector2, at: Vector2, outward: Vector2, height: float) -> Dictionary:
	# Coordinate noise is independent of edge order, global RNG, time and the camera.
	var noise:=_noise(at*.039+Vector2(height*.13,height*.071))
	var wave:=.5+.5*sin(at.x*.031+at.y*.024)
	var lip:=7.0+noise*8.0+wave*3.0
	return {"logical":logical,"world":at,"outward":outward,"noise":noise,"wave":wave,"lip":lip,"toe":lip+11.0+noise*7.0}

func _shape_node(renderer: Node, node: Dictionary, outline: PackedVector2Array, height: float) -> void:
	var at: Vector2=node.world
	var out: Vector2=node.outward
	var support:=_support_height(renderer,at+out*24.0,height)
	var desired:=clampf((22.0+(height-support+5.0)*.95)*(.85+float(node.noise)*.30),34.0,150.0)
	# Broad slopes may approach another shore or a lower walking route, never cover it.
	var width:=desired
	var distance:=8.0
	while distance<=desired:
		var point:=at+out*distance
		if Geometry2D.is_point_in_polygon(point,outline):
			width=maxf(8.0,distance-8.0)
			break
		var near_route:=false
		for route in _routes:
			if float(route.ceiling)>height-10.0: continue
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,route.start,route.end))<20.0:
				near_route=true
				break
		if near_route:
			width=maxf(8.0,distance-8.0)
			break
		distance+=8.0
	width=maxf(8.0,width)
	node.toe=width
	node.lip=minf(float(node.lip),width*.26)
	node.upper=width*(.38+float(node.noise)*.05)
	node.belly=width*(.69+float(node.wave)*.05)

func _noise(point: Vector2) -> float:
	return fposmod(sin(point.dot(Vector2(12.9898,78.233)))*43758.5453,1.0)

func _allowed(renderer: Node, surface: Dictionary, a: Dictionary, b: Dictionary) -> bool:
	var id:=str(surface.get("id",""))
	if id in ["WestForestBacking","EastForestBacking"]: return false
	for t in [0.0,.25,.5,.75,1.0]:
		var point: Vector2=a.logical.lerp(b.logical,t)
		if id in ["forest_west_land","forest_east_land"] and (point.x<1250.0 or point.x>1650.0 or point.y<=125.0 or point.y>=1425.0): return false
		if renderer._connector_at(point) or renderer._shared_floor_edge(point,b.logical-a.logical,surface): return false
		# The expanded shoulder, not just its original midpoint, must clear stair mouths.
		var at: Vector2=a.world.lerp(b.world,t)
		var outward: Vector2=a.outward.lerp(b.outward,t).normalized()
		var toe: float=lerpf(float(a.toe),float(b.toe),t)
		var height: float=float(surface.get("heightPixels",float(surface.get("elevation",0))*renderer.LEVEL_HEIGHT))+float(surface.get("priority",0))*.018
		for width in [0.0,toe]:
			var xy: Vector2=at+outward*width
			var support:=_support_height(renderer,xy,height)
			for z in [height,lerpf(height,support,.5),support]:
				if renderer._connector_at(renderer.ground_projection(Vector3(xy.x,xy.y,z))): return false
	return true

func _support_height(renderer: Node, world_xy: Vector2, ceiling: float) -> float:
	var support:=-40.0
	for floor in _floors:
		var height: float=floor.height
		if height>ceiling-4.0 or height<support: continue
		var logical: Vector2=renderer.ground_projection(Vector3(world_xy.x,world_xy.y,height))
		if Geometry2D.is_point_in_polygon(logical,floor.polygon): support=height
	if support< -8.0 and ceiling> -4.0 and _backing.size()>=3:
		var logical: Vector2=renderer.ground_projection(Vector3(world_xy.x,world_xy.y,-8.0))
		if Geometry2D.is_point_in_polygon(logical,_backing): support=-8.0
	return minf(support,ceiling-4.0)

func _prepare_support(renderer: Node) -> void:
	_floors.clear()
	_backing.clear()
	_routes.clear()
	for floor in renderer.map.get("surfaces",[]):
		if not bool(floor.get("walkable",true)): continue
		var polygon:=PackedVector2Array()
		for value in floor.get("polygon",[]): polygon.append(Vector2(value[0],value[1]))
		_floors.append({"height":float(floor.get("heightPixels",float(floor.get("elevation",0))*renderer.LEVEL_HEIGHT)),"polygon":polygon})
	for value in renderer.map.get("landmass",[]): _backing.append(Vector2(value[0],value[1]))
	for route in renderer.map.get("routes",[]):
		for index in range(1,route.size()):
			var first:=Vector2(route[index-1][0],route[index-1][1])
			var second:=Vector2(route[index][0],route[index][1])
			var h0: float=renderer.ground_height(first)
			var h1: float=renderer.ground_height(second)
			var a: Vector3=renderer.map_point(first,h0)
			var b: Vector3=renderer.map_point(second,h1)
			_routes.append({"start":Vector2(a.x,a.y),"end":Vector2(b.x,b.y),"ceiling":maxf(h0,h1)})

func _buffer() -> Dictionary:
	return {"vertices":PackedVector3Array(),"indices":PackedInt32Array()}

func _quad(buffer: Dictionary, a: Vector3, b: Vector3, c: Vector3, d: Vector3, alternating: int, desired_normal: Vector3) -> void:
	var start: int=buffer.vertices.size()
	buffer.vertices.append_array(PackedVector3Array([a,b,c,d]))
	var triangles: Array=[[0,1,2],[0,2,3]] if alternating%2==0 else [[0,1,3],[1,2,3]]
	for triangle in triangles:
		var vertices: PackedVector3Array=buffer.vertices
		var normal:=-(vertices[start+triangle[1]]-vertices[start+triangle[0]]).cross(vertices[start+triangle[2]]-vertices[start+triangle[0]])
		if normal.length_squared()<.00001: continue
		if normal.dot(desired_normal)<0:
			var swap: int=triangle[1]
			triangle[1]=triangle[2]
			triangle[2]=swap
		for index in triangle: buffer.indices.append(start+index)

func _emit(renderer: Node, label: String, buffer: Dictionary, material: Material) -> void:
	if not buffer.indices.is_empty(): renderer._mesh(label,buffer.vertices,buffer.indices,material)

func debug_status() -> Dictionary:
	return {"surfaces":surfaces,"segments":segments,"bevels":bevels,"excluded":excluded,"changesPhysics":false}
