extends SceneTree

class ViewFixture extends Node3D:
	var _lanterns: Array=[]
	func ground_height(_feet: Vector2) -> float: return 0
	func camera_up() -> Vector3: return Vector3.UP
	func camera_forward() -> Vector3: return Vector3.FORWARD
	func map_point(feet: Vector2,height: float) -> Vector3: return Vector3(feet.x,feet.y,height)
	func logical_on_height(point: Vector3,_height: float) -> Vector2: return Vector2(point.x,point.y)

var output:="res://../artifacts/godot/06b-npc-alpha"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	call_deferred("run")

func settle() -> void:
	for frame in range(3): await process_frame
	await RenderingServer.frame_post_draw

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(640,360)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(512,512)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var projection:=ViewFixture.new()
	viewport.add_child(projection)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color(.13,.28,.34)
	viewport.add_child(environment)
	var camera:=Camera3D.new()
	viewport.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=128
	camera.position=Vector3(0,40,400)
	camera.current=true
	var actors: Node3D=load("res://scripts/land/LandActors3D.gd").new()
	projection.add_child(actors)
	actors.renderer=projection
	var report: Dictionary={}
	for appearance in [0,1,3,5]:
		var sheet: Texture2D=load("res://resources/art/village-residents-v1.png")
		var rect:=Rect2(Vector2(appearance%3,floori(float(appearance)/3))*512,Vector2(512,512))
		var frame: Texture2D=actors._frame(sheet,rect)
		var sprite: Sprite3D=actors._sprite("probe",frame,Vector2.ZERO,Vector2(100,100),36)
		for shadow in actors._shadows.values(): shadow.visible=false
		sprite.visible=false
		await settle()
		var background: Image=viewport.get_texture().get_image()
		for variant in ["atlas","crop","blend"]:
			sprite.texture=frame if variant!="crop" else ImageTexture.create_from_image(sheet.get_image().get_region(Rect2i(rect)))
			sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISABLED if variant=="blend" else SpriteBase3D.ALPHA_CUT_DISCARD
			sprite.visible=true
			await settle()
			var capture: Image=viewport.get_texture().get_image()
			capture.save_png(output+"/minimal-"+str(appearance)+"-"+variant+".png")
			var source: Image=sheet.get_image().get_region(Rect2i(rect))
			var zero_samples:=0
			var changed:=0
			var opaque_changed:=0
			for y in range(16,496,8):
				for x in range(16,496,8):
					var world: Vector3=sprite.position+Vector3((x+.5-256)*100/512.0,(256-y-.5)*100/512.0,0)
					var at:=Vector2i(camera.unproject_position(world).floor())
					var pixel: Color=capture.get_pixelv(at)
					var behind: Color=background.get_pixelv(at)
					var delta:=Vector3(pixel.r-behind.r,pixel.g-behind.g,pixel.b-behind.b)
					var transparent_neighborhood:=true
					for offset in [Vector2i.ZERO,Vector2i(-3,-3),Vector2i(3,-3),Vector2i(-3,3),Vector2i(3,3)]:
						if source.get_pixelv(Vector2i(x,y)+offset).a>0: transparent_neighborhood=false
					if transparent_neighborhood:
						zero_samples+=1
						if delta.length()>.015: changed+=1
					elif source.get_pixel(x,y).a>.9 and delta.length()>.015: opaque_changed+=1
			report[str(appearance)+"-"+variant]={"transparentSamples":zero_samples,"changedTransparent":changed,"changedOpaque":opaque_changed,"transparentFlag":sprite.transparent,"alphaCut":sprite.alpha_cut}
	FileAccess.open(output+"/minimal-results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("NPC PORTRAIT ALPHA DIAGNOSTIC: ",JSON.stringify(report))
	viewport.free()
	await world_capture()
	quit()

func world_capture() -> void:
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":200,"inventory":[],"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive={}
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=true
	clock.authoritative=true
	clock.visual_minutes=1200
	clock.set("_server_rain",false)
	clock.set("_rain_amount",0)
	clock._process(0)
	var stage:=Node2D.new()
	root.add_child(stage)
	var person: Node2D=load("res://scripts/HubActor.gd").new()
	person.actor_name="Saras"
	person.appearance_index=5
	person.custom_sheet=load("res://resources/art/village-residents-v1.png")
	person.custom_grid=Vector2i(3,2)
	person.position=Vector2(1480,680)
	person.set_meta("land_hidden",true)
	stage.add_child(person)
	person._process(0)
	person.set_process(false)
	assert(not person.visible,"The original CanvasItem must be hidden while its 3D counterpart renders")
	var camera:=Camera2D.new()
	camera.zoom=Vector2(2,2)
	stage.add_child(camera)
	var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	renderer.setup(stage,person,camera,"hub")
	renderer.set_process(false)
	renderer._update_view(0,true)
	renderer._process(.5)
	await settle()
	var sprite: Sprite3D=renderer.actors_3d.sprites["NPC_Saras"]
	var texture: Texture2D=sprite.texture
	for mode in ["atlas","sprite-hidden","shadow-hidden","crop"]:
		sprite.visible=mode!="sprite-hidden"
		for shadow in renderer.actors_3d._shadows.values(): shadow.visible=mode!="shadow-hidden"
		if mode=="crop": sprite.texture=ImageTexture.create_from_image(texture.get_image())
		await settle()
		root.get_texture().get_image().save_png(output+"/night-saras-"+mode+".png")
		renderer.viewport_3d.get_texture().get_image().save_png(output+"/night-saras-"+mode+"-world.png")
	stage.free()
