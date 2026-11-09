extends "res://scripts/land/LandWorld3D.gd"

var home_state: Dictionary = {}
var _display_signature := ""

func _build_ground_details() -> void:
	pass

func _build_corridor_landmarks() -> void:
	var wood:Material=_materials.get_material("wood")
	var bamboo:Material=_materials.get_material("bamboo")
	var rear:=map_point(Vector2(480,146))
	_box("HomeBackWall",rear+Vector3(0,0,60),Vector3(808,8,120),bamboo)
	for side in [-1.0,1.0]:
		var at:=map_point(Vector2(480+side*404,395))
		_box("HomeSideWall",at+Vector3(0,0,44),Vector3(8,490/cos(TILT),88),wood)
	for x in [150.0,480.0,810.0]:
		var post:=map_point(Vector2(x,147))
		_column(post,post+Vector3(0,0,124),5,wood)
	for x in [250.0,750.0]:
		var window:=map_point(Vector2(x,149))+Vector3(0,0,74)
		_box("HomeWindowFrame",window,Vector3(88,10,55),wood)
		_box("HomeWindowLight",window-Vector3(0,6,0),Vector3(72,2,43),_materials.get_material("office_glass"))
		_box("HomeWindowMullion",window-Vector3(0,8,0),Vector3(4,3,45),bamboo)
	_lantern(map_point(Vector2(110,260))+Vector3(0,0,88))
	_lantern(map_point(Vector2(845,485))+Vector3(0,0,88))
	var mat:=map_point(Vector2(480,550))+Vector3(0,0,.6)
	_box("HomeWovenMat",mat,Vector3(250,120,1.2),_materials.get_material("woven_teal"))
	for x in [-110.0,110.0]: _box("HomeMatBorder",mat+Vector3(x,0,.8),Vector3(5,120,.5),_materials.get_material("cloth_cream"))
	# Low front returns keep the cutaway readable without hiding the entry or changing its floor boundary.
	for side in [-1.0,1.0]:
		var wall_at:=map_point(Vector2(480+side*300,644))
		_box("CutawayFrontReturn",wall_at+Vector3(0,0,14),Vector3(200,8,28),wood)
		_box("CutawayReturnCap",wall_at+Vector3(0,0,30),Vector3(202,10,4),bamboo)
		var cap_at:=map_point(Vector2(480+side*404,395))+Vector3(0,0,90)
		_box("SideWallTimberCap",cap_at,Vector3(12,490/cos(TILT),6),bamboo)
	for x in [-94.0,94.0]:
		for stripe in range(9): _box("WovenMatEdgePattern",mat+Vector3(x,stripe*12-48,1),Vector3(7,5,.6),_materials.get_material("cloth_cream"))
	var threshold:=map_point(Vector2(480,630))
	_box("HomeDoorThreshold",threshold+Vector3(0,0,2),Vector3(110,12,4),bamboo)

func _build_obstacle(entry: Dictionary) -> void:
	var rect:=Rect2(float(entry.x),float(entry.y),float(entry.width),float(entry.height))
	var center:=map_point(rect.get_center())
	var wood:Material=_materials.get_material("wood")
	var bamboo:Material=_materials.get_material("bamboo")
	var cream:Material=_materials.get_material("cloth_cream")
	var depth:=rect.size.y/cos(TILT)
	match str(entry.id):
		"home_bed":
			_box("RattanBedFrame",center+Vector3(0,0,17),Vector3(rect.size.x,depth,34),bamboo)
			_box("HomeMattress",center+Vector3(0,0,38),Vector3(rect.size.x-12,depth-12,9),cream)
			for y in [-depth*.23,depth*.23]:
				_box("HomePillow",center+Vector3(-rect.size.x*.31,y,46),Vector3(34,depth*.34,9),cream)
			_box("HomeWovenBlanket",center+Vector3(25,0,44),Vector3(rect.size.x*.48,depth-10,3),_materials.get_material("woven_teal"))
			_box("RattanHeadboard",center+Vector3(-rect.size.x*.47,0,47),Vector3(6,depth,34),bamboo)
			for y in range(7): _column(center+Vector3(-rect.size.x*.49,-depth*.42+y*depth*.14,20),center+Vector3(-rect.size.x*.49,-depth*.42+y*depth*.14,61),1.5,wood)
			for y in [-depth*.42,depth*.42]: _box("BedWovenSideRail",center+Vector3(0,y,21),Vector3(rect.size.x-12,4,5),wood)
		"home_archive":
			_box("ArchiveTabletop",center+Vector3(0,0,65),Vector3(rect.size.x,depth,7),wood)
			for x in [-rect.size.x*.4,rect.size.x*.4]:
				for y in [-depth*.4,depth*.4]: _column(center+Vector3(x,y,0),center+Vector3(x,y,63),4,wood)
			_box("ArchiveOpenBook",center+Vector3(-16,0,71),Vector3(58,42,4),_materials.get_material("paper"))
			_box("ArchiveBookSpine",center+Vector3(-16,0,74),Vector3(3,42,3),wood)
			for i in range(3): _column(center+Vector3(35,i*9-9,72),center+Vector3(60,i*9-9,72),3,bamboo)
			_box("ArchiveBookShelf",center+Vector3(0,depth*.38,102),Vector3(rect.size.x-8,16,5),wood)
			for i in range(6):
				var book_at:=center+Vector3(-48+i*15,depth*.38,118+(i%3)*2)
				_box("ArchiveStandingBook",book_at,Vector3(10,14,26+(i%3)*4),_materials.get_material(["cloth_teal","terracotta","paper"][i%3]))
			for side in [-1.0,1.0]: _column(center+Vector3(side*rect.size.x*.44,depth*.38,64),center+Vector3(side*rect.size.x*.44,depth*.38,105),2,wood)
			var pot:=center+Vector3(52,-depth*.28,72)
			_column(pot,pot+Vector3(0,0,12),6,_materials.get_material("terracotta"))
			for branch in range(4): _column(pot+Vector3(0,0,11),pot+Vector3((branch%2*2-1)*7,(branch/2*2-1)*5,22+branch*2),1.5,_materials.get_material("leaves"))
		"home_chest":
			_box("StorageChestBody",center+Vector3(0,0,21),Vector3(rect.size.x,depth,42),wood)
			_box("StorageChestLid",center+Vector3(0,0,45),Vector3(rect.size.x+3,depth+3,7),bamboo)
			for x in [-rect.size.x*.32,rect.size.x*.32]: _box("ChestStrap",center+Vector3(x,0,25),Vector3(5,depth+5,50),_materials.get_material("metal"))
			_box("ChestLatch",center+Vector3(0,-depth*.5-2,30),Vector3(13,5,16),_materials.get_material("corporate_copper"))
		"home_display":
			_box("DisplayBack",center+Vector3(0,depth*.43,43),Vector3(rect.size.x,6,86),wood)
			for z in [8.0,43.0,82.0]: _box("DisplayShelf",center+Vector3(0,0,z),Vector3(rect.size.x,depth,6),bamboo)
			for x in [-rect.size.x*.47,rect.size.x*.47]: _box("DisplayUpright",center+Vector3(x,0,43),Vector3(6,depth,86),wood)
			for x in [-25.0,25.0]:
				var basket:=center+Vector3(x,0,12)
				_column(basket,basket+Vector3(0,0,19),10,bamboo)
				for stripe in range(3): _box("ShelfBasketWeave",basket+Vector3(0,-11,5+stripe*5),Vector3(17,2,2),wood)
			var owned:Array=GameState.player.get("adventure",{}).get("keyItems",[])
			var count:=mini(owned.size(),3)
			for index in range(count):
				var at:=center+Vector3((index-1)*25,-depth*.05,52)
				_box("OwnedMemoryArtifact",at,Vector3(14,10,15),_materials.get_material("corporate_copper"))
				_box("ArtifactMemoryInset",at-Vector3(0,6,0),Vector3(6,2,7),_materials.get_material("cloth_teal"))
		_:
			super._build_obstacle(entry)

func _refresh_homestead() -> void:
	if "homestead" in GameState: set_state(GameState.get("homestead"))

func set_state(home: Dictionary) -> void:
	var signature:=JSON.stringify(GameState.player.get("adventure",{}).get("keyItems",[]))
	if signature!=_display_signature and _built: _homestead_dirty=true
	_display_signature=signature
	home_state=home.duplicate(true)
	set_homestead_state(home)
