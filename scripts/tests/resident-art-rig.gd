extends SceneTree

var output:=""

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	_run.call_deferred()

func _run() -> void:
	root.size=Vector2i(1440,810)
	var state=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var clock=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=false
	clock.reduced_motion=false
	var stage:=Node2D.new()
	root.add_child(stage)
	var player:Node2D=load("res://scripts/Player.gd").new()
	stage.add_child(player)
	player.set_physics_process(false)
	player.visible=false
	player.position=Vector2(1100,650)
	player.swim_sprite.set_appearance("male_nusantara")
	player.swim_sprite.set_outfit("daily")
	player.swim_sprite.set_locomotion(Vector2.ZERO,0)
	player.swim_sprite.animate(false,false,1,0)
	var camera:=Camera2D.new()
	camera.zoom=Vector2(2,2)
	stage.add_child(camera)
	var renderer:Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	renderer.setup(stage,player,camera,"hub")
	renderer.set_process(false)
	renderer._process(.3)
	assert(renderer.active and renderer.display.size.x>0 and renderer.viewport_3d.render_target_update_mode==SubViewport.UPDATE_ALWAYS,"Capture must activate actual world viewport, not an empty canvas")
	var collision:Node2D=load("res://scripts/land/LandCollision.gd").new()
	stage.add_child(collision)
	collision.configure(state.world.landMaps.hub)
	var profiles:Array=[]
	for profile in state.world.surface_hub.residents:
		if profile.has("visual"): profiles.append(profile)
	assert(profiles.size()==6)
	var anchors:Array[Vector2]=[]
	for index in range(6): anchors.append(player.position+renderer.logical_view_delta(Vector2((index-2.5)*66,0)))
	var rigs:Array=[]
	var people:Array=[]
	var samples:=0
	var maximum_drop:=0.0
	for index in range(profiles.size()):
		var profile:Dictionary=profiles[index]
		var actor:Node2D=load("res://scripts/HubActor.gd").new()
		actor.actor_name=profile.name
		actor.configure_activity(profile)
		actor.position=anchors[index]
		stage.add_child(actor)
		actor.visible=false
		actor.set_process(false)
		assert(collision.is_walkable(actor.position))
		var rig:Node3D=load("res://scripts/ResidentArtRig3D.gd").new()
		renderer.world_root.add_child(rig)
		assert(rig.configure(renderer,actor))
		for sample in range(96):
			clock.reduced_motion=sample>=48
			var step:=sample%48
			if sample==48:
				actor.position=anchors[index]
				rig._plant._ready=false
				rig._contacts.clear()
			var before:Vector2=actor.position
			if step<24: actor.position+=Vector2.RIGHT*.8
			elif step<36: actor.position+=Vector2.LEFT*.8
			actor.moved_velocity=(actor.position-before)/.05
			actor._elapsed+=.05
			actor._body_animation.update(.05,actor.moved_velocity,false,false,false,false,clock.reduced_motion,"research")
			rig.update_pose(Color.WHITE)
			var status:Dictionary=rig.debug_status()
			assert(status.authoredViews==1 and not status.mirrored and status.separateProp)
			assert(is_equal_approx(float(status.contacts.stride),25*float(profile.get("bodyScale",1))))
			for link in status.links.values():
				assert(absf(link.start.distance_to(link.joint)-float(link.first))<.04,"First bone cannot stretch")
				assert(absf(link.joint.distance_to(link.end)-float(link.second))<.04,"Second bone cannot stretch")
			for side in ["left","right"]:
				var leg:Dictionary=status.links["leg_"+side]
				for segment in ["upper_leg_","lower_leg_"]:
					var name:String=segment+side
					if bool(rig.data.parts[name].hiddenByAuthoredClothing): continue
					var endpoints:Array=rig.data.parts[name].bone
					var expected:Array=[leg.start,leg.joint] if segment=="upper_leg_" else [leg.joint,leg.end]
					for endpoint in range(2):
						assert(_part_pixel(rig,name,endpoints[endpoint]).distance_to(rig.to_global(expected[endpoint]))<.01,"Actual leg quad endpoints must join in all three dimensions")
				var foot:Dictionary=rig.data.parts["foot_"+side]
				var bounds:Array=foot.sourceBounds
				var rect:Array=foot.rect
				var pixel:=Vector3((float(foot.sole[0])-float(bounds[0]))/float(rect[2])-.5,.5-(float(foot.sole[1])-float(bounds[1]))/float(rect[3]),0)
				var transform:Transform3D=rig._part_transforms["foot_"+side]
				if DisplayServer.get_name()!="headless":
					var readback:Transform3D=rig.body_mesh.multimesh.get_instance_transform(int(rig.sprites["foot_"+side]))
					assert(readback.is_equal_approx(transform),"Native body quad must match the actual submitted part transform")
					transform=readback
				var actual:Vector3=rig.to_global(transform*pixel)
				assert(actual.distance_to(status.contacts.feet[side].sole)<.25,"Actual original alpha sole must follow physical support, not merely the actor origin")
				if status.contacts.feet[side].grounded: assert(Vector3(status.contacts.feet[side].sole).distance_to(renderer.ground_point(status.contacts.feet[side].logical))<.001)
			for side in ["left","right"]:
				assert(_part_pixel(rig,"hand_"+side,rig.data.parts["hand_"+side].grip).distance_to(rig.hands[side])<.001,"Separate item socket must touch an original opaque palm pixel")
			assert(rig._held.global_position.distance_to(rig.hands.right)<.001)
			maximum_drop=maxf(maximum_drop,float(status.pelvisDrop))
			assert(float(status.pelvisDrop)<9*float(profile.get("bodyScale",1)),"Child gait cannot solve reach by excessive body crouching")
			samples+=1
		clock.reduced_motion=false
		actor.moved_velocity=Vector2.ZERO
		clock.clock_paused=true
		var frozen:Dictionary=rig.pose_snapshot()
		rig.update_pose(Color.WHITE)
		assert(rig.pose_snapshot()==frozen,"Pause must preserve physical contacts and pose")
		clock.clock_paused=false
		actor.position=anchors[index]
		rig._plant._ready=false
		rig._contacts.clear()
		actor.moved_velocity=Vector2.ZERO
		actor._elapsed+=2
		rig.update_pose(Color.WHITE)
		rigs.append(rig)
		people.append(actor)
	if not output.is_empty() and DisplayServer.get_name()!="headless":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
		renderer._update_view(0,true)
		for frame in range(6): await process_frame
		RenderingServer.force_draw()
		var shown:Image=root.get_texture().get_image()
		shown.save_png(output+"/six-residents-same-zoom.png")
		for rig in rigs: rig.visible=false
		for frame in range(3): await process_frame
		RenderingServer.force_draw()
		var hidden:Image=root.get_texture().get_image()
		var visible_pixels:Array=[]
		for rig in rigs:
			var at:Vector2=renderer.camera_3d.unproject_position(rig.global_position)
			var framing:=Rect2(Vector2(10,10),Vector2(renderer.viewport_3d.size)-Vector2(20,20))
			for name in rig.data.parts:
				if bool(rig.data.parts[name].hiddenByAuthoredClothing): continue
				var transform:Transform3D=rig._part_transforms[name]
				for corner in [Vector3(-.5,-.5,0),Vector3(-.5,.5,0),Vector3(.5,.5,0),Vector3(.5,-.5,0)]:
					assert(framing.has_point(renderer.camera_3d.unproject_position(rig.to_global(transform*corner))),str(rig.actor.resident_id)+" actual body quad must be inside native frame")
			at*=Vector2(root.size)/Vector2(renderer.viewport_3d.size)
			var changed:=0
			for y in range(maxi(0,int(at.y)-220),mini(shown.get_height(),int(at.y)+24)):
				for x in range(maxi(0,int(at.x)-75),mini(shown.get_width(),int(at.x)+75)):
					if shown.get_pixel(x,y)!=hidden.get_pixel(x,y): changed+=1
			assert(changed>150,"Actual resident must change captured framebuffer; command/readback alone cannot prove visibility")
			visible_pixels.append({"id":str(rig.actor.resident_id),"framebufferChangedPixels":changed})
		for rig in rigs: rig.visible=true
		FileAccess.open(output+"/visibility.json",FileAccess.WRITE).store_string(JSON.stringify(visible_pixels,"  "))
		var report:Array=[]
		for rig in rigs: report.append(rig.pose_snapshot())
		FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
		var sizes:Array=[]
		player.position=Vector2(1320,650)
		renderer._update_view(0,true)
		renderer.actors_3d._scan_clock=0
		renderer.actors_3d.update_actors(0)
		var nala:Sprite3D=renderer.actors_3d.sprites.Nala
		for rig in rigs: rig.visible=false
		for frame in range(3): await process_frame
		RenderingServer.force_draw()
		var nala_shown:Image=root.get_texture().get_image()
		nala.visible=false
		for frame in range(3): await process_frame
		RenderingServer.force_draw()
		var nala_bounds:=_changed_bounds(nala_shown,root.get_texture().get_image())
		assert(nala_bounds.size.y>150,"Reference must contain actual runtime directional Nala alpha")
		nala.visible=true
		for index in range(rigs.size()):
			var rig:Node3D=rigs[index]
			var person:Node2D=people[index]
			person.position=player.position+renderer.logical_view_delta(Vector2(65,0))
			assert(collision.is_walkable(person.position),"Pair reference must remain on authoritative floor")
			person.moved_velocity=Vector2.ZERO
			person._body_animation.update(1,Vector2.ZERO,false,false,false,false,false,"research")
			rig._plant._ready=false
			rig._contacts.clear()
			rig.update_pose(Color.WHITE)
			rig.visible=true
			for frame in range(3): await process_frame
			RenderingServer.force_draw()
			var pair:Image=root.get_texture().get_image()
			pair.save_png(output+"/pair-"+str(person.resident_id)+".png")
			rig.body_mesh.visible=false
			for frame in range(3): await process_frame
			RenderingServer.force_draw()
			var bounds:=_changed_bounds(pair,root.get_texture().get_image())
			var ratio:=float(bounds.size.y)/float(nala_bounds.size.y)
			assert(bounds.size.y>140 and ratio>.65,"Child body cannot read as a toddler beside actual Nala")
			var pixels_per_world:float=float(root.size.y)/float(renderer.camera_3d.size)
			sizes.append({"id":str(person.resident_id),"bodyScale":float(person.body_scale),"visibleAlphaPixels":bounds.size.y,"visibleAlphaWorldHeight":float(bounds.size.y)/pixels_per_world,"nalaAlphaPixels":nala_bounds.size.y,"nalaWorldHeight":float(nala_bounds.size.y)/pixels_per_world,"ratioToNala":ratio,"authoredWorldHeight":112*rig._factor,"logicalFoot":[person.position.x,person.position.y]})
			rig.body_mesh.visible=true
			rig.visible=false
		FileAccess.open(output+"/measured-alpha-heights.json",FileAccess.WRITE).store_string(JSON.stringify(sizes,"  "))
		for index in range(rigs.size()):
			var person:Node2D=people[index]
			var rig:Node3D=rigs[index]
			rig.visible=str(person.resident_id)=="npc_kid_danu"
			if not rig.visible: continue
			person.position=Vector2(150,850)
			person.activity_phase="work"
			person._body_animation.update(2.0,Vector2.ZERO,true,false,false,false,false,"fishing")
			rig._plant._ready=false
			rig._contacts.clear()
			rig.update_pose(Color.WHITE)
			var work:Dictionary=rig.pose_snapshot()
			var target:Dictionary=person.body_animation_state().workFacing
			assert(Vector2(float(target.point[0]),float(target.point[1]))==Vector2(275,990) and float(target.height)==-11)
			assert(Vector2(float(work.workFacing[0]),float(work.workFacing[1])).x>.1,"Danu work direction derives from real pen, not arrival west")
		player.position=Vector2(275,850)
		renderer._update_view(0,true)
		renderer.actors_3d._scan_clock=0
		renderer.actors_3d.update_actors(0)
		for frame in range(4): await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(output+"/danu-actual-pen-work.png")
	stage.free()
	await process_frame
	print("RESIDENT ART RIG PASS:6 original single-view pixel partitions, ",samples," measured locomotion/turn/stop poses, actual alpha soles, fixed limb lengths, child stride scaling, separate role props, pause; max pelvis drop=",maximum_drop,". Native visual quality and alternate-view art require separate review.")
	quit()

func _part_pixel(rig:Node3D,name:String,pixel:Array) -> Vector3:
	var part:Dictionary=rig.data.parts[name]
	var rect:Array=part.rect
	var bounds:Array=part.sourceBounds
	var unit:=Vector3((float(pixel[0])-float(bounds[0]))/float(rect[2])-.5,.5-(float(pixel[1])-float(bounds[1]))/float(rect[3]),0)
	var transform:Transform3D=rig._part_transforms[name]
	if DisplayServer.get_name()!="headless":
		var readback:Transform3D=rig.body_mesh.multimesh.get_instance_transform(int(rig.sprites[name]))
		assert(readback.is_equal_approx(transform))
		transform=readback
	return rig.to_global(transform*unit)

func _changed_bounds(shown:Image,hidden:Image) -> Rect2i:
	var left:=shown.get_width()
	var top:=shown.get_height()
	var right:=-1
	var bottom:=-1
	for y in range(shown.get_height()):
		for x in range(shown.get_width()):
			if shown.get_pixel(x,y)==hidden.get_pixel(x,y): continue
			left=mini(left,x); right=maxi(right,x)
			top=mini(top,y); bottom=maxi(bottom,y)
	return Rect2i(left,top,maxi(0,right-left+1),maxi(0,bottom-top+1))
