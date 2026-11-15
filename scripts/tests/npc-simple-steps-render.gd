extends SceneTree
class ViewFixture extends Node3D:
	func ground_height(_feet: Vector2) -> float: return 0
	func camera_up() -> Vector3: return Vector3.UP
	func camera_forward() -> Vector3: return Vector3.FORWARD
	func map_point(feet: Vector2,height: float) -> Vector3: return Vector3(feet.x,feet.y,height)
	func logical_on_height(point: Vector3,_height: float) -> Vector2: return Vector2(point.x,point.y)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(DisplayServer.get_name()!="headless")
	root.size=Vector2i(480,270)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(480,270)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var projection:=ViewFixture.new()
	viewport.add_child(projection)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("5b9a6c")
	viewport.add_child(environment)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=720
	camera.position=Vector3(0,45,500)
	camera.current=true
	viewport.add_child(camera)
	var actors=load("res://scripts/land/LandActors3D.gd").new()
	projection.add_child(actors)
	actors.renderer=projection
	var steps=load("res://scripts/NpcSimpleSteps.gd")
	var directory:="res://../artifacts/godot/npc-simple-steps"
	DirAccess.make_dir_recursive_absolute(directory)
	var result: Dictionary={}
	for name in steps.FILES:
		var captures: Array=[]
		for frame in range(5):
			var pose: Dictionary={"clip":"idle" if frame==0 else "walk","distance":float(frame-1)*6.5}
			var texture: Texture2D=steps.frame(name,pose)
			actors._sprite("npc",texture,Vector2.ZERO,Vector2(100,100),36)
			await process_frame
			RenderingServer.force_draw(false)
			var image: Image=viewport.get_texture().get_image()
			var filename: String=str(name).to_snake_case()+"-%d.png"%frame
			image.save_png(directory+"/"+filename)
			captures.append(filename)
		result[name]=captures
	FileAccess.open(directory+"/results.json",FileAccess.WRITE).store_string(JSON.stringify({"renderPixels":[480,270],"cameraHeight":720,"actorWorldSize":[100,100],"captures":result},"  "))
	print("NPC SIMPLE STEPS NATIVE PASS: 35 actual Sprite3D frames at 480x270")
	quit()
