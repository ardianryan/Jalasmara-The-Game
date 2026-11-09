extends SceneTree

class RigStage extends Node3D:
	func map_point(_point: Vector2,_height: float) -> Vector3: return Vector3.ZERO
	func ground_height(_point: Vector2) -> float: return 0.0
	func camera_forward() -> Vector3: return Vector3(0,0,-1)

func _initialize() -> void: call_deferred('_run')

func _run() -> void:
	assert(DisplayServer.get_name()!='headless','Native rendering test requires a GPU window')
	var state:=root.get_node('GameState')
	state.dive={}
	var environment:=root.get_node('EnvironmentState')
	environment.set_process(false)
	environment.clock_paused=false
	environment.reduced_motion=false
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(192,192)
	viewport.transparent_bg=true
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var stage:=RigStage.new()
	viewport.add_child(stage)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=120
	camera.position=Vector3(0,45,500)
	camera.current=true
	stage.add_child(camera)
	DirAccess.make_dir_recursive_absolute('res://../artifacts/godot/npc-body-rig/isolated')
	var results: Dictionary={}
	for pair in [['Mang Ujang','fishing'],['Bu Darmi','gardening'],['Yu Sari','weaving']]:
		var person: Node2D=load('res://scripts/HubActor.gd').new()
		person.actor_name=pair[0]
		person.activity_kind=pair[1]
		root.add_child(person)
		person.set_process(false)
		var rig: Node3D=load('res://scripts/NpcBodyRig3D.gd').new()
		stage.add_child(rig)
		assert(rig.configure(stage,person))
		var animation=person.get('_body_animation')
		var images: Array[Image]=[]
		var bottoms: Array[int]=[]
		for index in range(4):
			animation.clip='work_loop' if index<2 else 'walk'
			animation.elapsed=.9 if index==0 else 3.2
			animation.distance=3.0 if index==2 else 13.0
			animation.direction=['south','south','east','north'][index]
			person.moved_velocity=Vector2(26,0) if index>1 else Vector2.ZERO
			animation.set('_work_kind',pair[1])
			rig.update_pose(Color.WHITE)
			await process_frame
			await RenderingServer.frame_post_draw
			var image:=viewport.get_texture().get_image()
			image.save_png('res://../artifacts/godot/npc-body-rig/isolated/'+str(pair[1])+'-'+str(index)+'.png')
			images.append(image)
			var bottom:=0
			for y in range(image.get_height()):
				for x in range(image.get_width()):
					if image.get_pixel(x,y).a>.5: bottom=maxi(bottom,y)
			bottoms.append(bottom)
		var changed:=0
		for y in range(192):
			for x in range(192):
				var a:=images[0].get_pixel(x,y)
				var b:=images[1].get_pixel(x,y)
				if (a.a>.5 or b.a>.5) and a!=b: changed+=1
		assert(changed>30,'Working BODY pixels must change without any tool, terrain or camera movement')
		assert(abs(bottoms[0]-bottoms[1])<=2,'Work cannot slide feet')
		results[str(pair[0])]={ 'bodyPixelsChanged':changed,'alphaBottoms':bottoms,'parts':rig.sprites.size(),'rootMotion':false }
		rig.queue_free()
		person.queue_free()
		await process_frame
	FileAccess.open('res://../artifacts/godot/npc-body-rig/isolated/results.json',FileAccess.WRITE).store_string(JSON.stringify(results,'  '))
	print('NPC BODY GPU PASS ',results)
	quit()
