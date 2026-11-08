extends Node2D
var camera_point := Vector2(1000, 220)
var elapsed := 0.0
var gardens_restored := false
var solved: Array = []
var rocks: Array[Rect2] = []
var font: Font = ThemeDB.fallback_font
var ocean_art: Texture2D
func _ready() -> void:
	for rect in GameState.world.get("terrain",[]):
		rocks.append(Rect2(float(rect[0]),float(rect[1]),float(rect[2]),float(rect[3])))
	ocean_art = load("res://resources/art/muara-sungsang.png")
	for r in rocks:
		var body := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		collision.shape = shape
		body.position = r.get_center()
		body.add_child(collision)
		add_child(body)
func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
func _draw() -> void:
	var view := Rect2(camera_point-Vector2(560,340),Vector2(1120,680))
	draw_rect(Rect2(0,-200,6144,600),Color("73b4b2"))
	for i in range(20):
		var cx := float(i*340)+fmod(camera_point.x*0.08,340.0)
		draw_rect(Rect2(cx,65+sin(i*4.3)*20,130,12),Color("b6d1be"))
		draw_rect(Rect2(cx+35,53+sin(i*4.3)*20,65,12),Color("b6d1be"))
	for i in range(24):
		var x := i*270
		draw_rect(Rect2(x,210,160,115),Color("508d8a"))
		draw_colored_polygon(PackedVector2Array([Vector2(x-10,215),Vector2(x+80,160),Vector2(x+170,215)]),Color("447877"))
	for depth in range(100):
		var col := Color("176b73").lerp(Color("071d2c"),clampf(depth/90.0,0.0,1.0))
		draw_rect(Rect2(0,400+depth*32,6144,33),col)
	if ocean_art:
		for bx in range(maxi(0,int(view.position.x/1600)),mini(4,int(view.end.x/1600)+1)):
			for by in range(maxi(0,int((view.position.y-400)/1050)),mini(3,int((view.end.y-400)/1050)+1)):
				draw_texture_rect_region(ocean_art,Rect2(bx*1600,400+by*1050,1600,1050),Rect2(0,420,1536,604),Color(0.8,0.95,0.9,.27))
	for i in range(18):
		var x := i*380.0+sin(elapsed*.22+i)*8
		draw_colored_polygon(PackedVector2Array([Vector2(x,400),Vector2(x+22,400),Vector2(x+260,1400),Vector2(x+160,1400)]),Color(0.5,0.85,0.75,.045))
	for i in range(80):
		var bx := fmod(i*173.0+sin(elapsed+i)*14,6144.0)
		var by := 420.0+fmod(i*197.0-elapsed*(8+i%7)+3100.0,3000.0)
		if view.has_point(Vector2(bx,by)):
			draw_arc(Vector2(bx,by),2+i%3,0,TAU,8,Color(.5,.8,.8,.25),1)
	for r in rocks:
		if not r.intersects(view):
			continue
		var surface := r.position.y < 400
		draw_rect(r,Color("795b3e") if surface else Color("24434a"))
		draw_rect(Rect2(r.position,Vector2(r.size.x,8)),Color("b79659") if surface else Color("6a8b74"))
		var start := maxi(0,int((view.position.x-r.position.x)/32))
		var end := mini(int(r.size.x/32)+1,start+38)
		for ix in range(start,end):
			var x := r.position.x+ix*32
			for iy in range(int(r.size.y/24)):
				var y := r.position.y+iy*24
				var n := posmod(ix*31+iy*17+int(r.position.y),11)
				if n<4:
					draw_rect(Rect2(x+3,y+8,19+n,5),Color("37545a") if not surface else Color("906d46"))
			if not surface:
				_coral(Vector2(x+10,r.position.y),ix%5)
	if view.position.y < 500:
		_building(270,340,"Kedai Waras",0)
		_building(900,310,"Galangan Bubat",1)
		_building(1700,360,"Tanggulangen",2)
		_building(2370,300,"Pos Cakrawala",3)
		for x in range(40,3080,96):
			draw_rect(Rect2(x,340,8,150),Color("4b5650"))
			draw_rect(Rect2(x+2,340,3,150),Color("85816a"))
		draw_rect(Rect2(1280,350,12,160),Color("b3a477"))
		for y in range(360,520,17):
			draw_rect(Rect2(1275,y,23,3),Color("786749"))
	for i in range(45):
		var x := 1850.0+fmod(i*151.0,3600.0)
		var base := 1810.0+(i%4)*22
		if not view.grow(200).has_point(Vector2(x,base)):
			continue
		var h := 220+i%6*54
		for j in range(0,h,18):
			var sway := sin(elapsed*.65+i+j*.018)*14
			draw_rect(Rect2(x+sway,base-j,7,20),Color("3f8467"))
			if j%36==0:
				draw_colored_polygon(PackedVector2Array([Vector2(x+sway,base-j),Vector2(x+sway-28,base-j-15),Vector2(x+sway-8,base-j+9)]),Color("539975"))
				if i%3==0:
					draw_rect(Rect2(x+sway+7,base-j-5,19,7),Color("78b68b"))
	for i in range(9):
		var px := 3500+i*120
		draw_rect(Rect2(px,2130,18,260+(i%3)*75),Color("705e50"))
		draw_rect(Rect2(px+3,2130,4,260+(i%3)*75),Color("9b8063"))
		for py in range(2150,2390+(i%3)*75,45):
			draw_rect(Rect2(px-4,py,26,7),Color("35494a"))
	if view.position.y>2500:
		for x in range(2700,4400,180):
			draw_rect(Rect2(x,3210,60,275),Color("253a40"))
			draw_rect(Rect2(x-9,3205,78,14),Color("57726b"))
			draw_rect(Rect2(x+9,3230,9,230),Color("36514f"))
		draw_rect(Rect2(2920,3440,1580,45),Color("738071"))
		draw_rect(Rect2(3050,3470,1320,15),Color("b5b891"))
func _building(x: float, width: float, title: String, kind: int) -> void:
	var wood := Color("77523b") if kind!=3 else Color("71868a")
	draw_rect(Rect2(x,175,width,155),wood)
	for line in range(185,330,13):
		draw_rect(Rect2(x,line,width,2),Color("a17a4c") if kind!=3 else Color("a8b6b1"))
	draw_colored_polygon(PackedVector2Array([Vector2(x-25,180),Vector2(x+width*.5,112),Vector2(x+width+25,180)]),Color("453c34"))
	for i in range(9):
		draw_line(Vector2(x-10+i*width/9,174),Vector2(x+width*.5+i*6,120+i*6),Color("7a5940"),3)
	draw_rect(Rect2(x+width*.38,230,56,100),Color("253b37"))
	for wx in [x+32,x+width-85]:
		draw_rect(Rect2(wx,220,48,52),Color("e4b86b"))
		draw_rect(Rect2(wx+4,224,40,44),Color("f0d398"))
		draw_line(Vector2(wx+24,220),Vector2(wx+24,272),wood,4)
	draw_rect(Rect2(x+width*.15,185,width*.7,25),Color("284940"))
	draw_string(font,Vector2(x+width*.15+8,203),title,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("f4e5bc"))
	if kind==2:
		for j in range(5):
			var gx := x+20+j*60
			draw_rect(Rect2(gx,310,44,14),Color("3c4d42"))
			draw_rect(Rect2(gx+22,280,4,34),Color("69985c") if gardens_restored else Color("8c8c48"))
			draw_circle(Vector2(gx+18,280),11,Color("78b06b") if gardens_restored else Color("b6a458"))
func _coral(at: Vector2, kind: int) -> void:
	if kind==0:
		for i in range(3):
			draw_rect(Rect2(at+Vector2(i*7,-20-i*6),Vector2(5,25+i*6)),Color("c28364"))
	elif kind==1:
		draw_rect(Rect2(at+Vector2(-5,-10),Vector2(28,10)),Color("6c9c91"))
		draw_rect(Rect2(at+Vector2(0,-16),Vector2(18,7)),Color("a0bd9e"))
