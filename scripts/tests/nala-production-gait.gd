extends "res://../scripts/tests/nala-lower-body.gd"

var controller:Node2D
var production_cases:Array=[]
var sample_log:FileAccess
var case_limit:=32
var first_case:=0
var case_index:=0
var legacy_contacts:=0
var elapsed_physics:=0.0
var logical_travel:=0.0
var physical_travel:=0.0
var last_physics_frame:=0
var began_usec:=0
var windows:Dictionary={}
var prior_planner_contacts:=0
var physical_pilot:=false
var delivered_input:=Vector2.ZERO
var input_driver:Node
var analog_probe:=false
var joystick_probe:=false
var raw_joystick_radius:Variant=null
const Joystick=preload("res://scripts/AnalogJoystick.gd")
const PhysicalMotion=preload("res://scripts/NalaPhysicalMotion.gd")

class PhysicalInputDriver extends Node:
	var renderer:Node
	var actor:Node2D
	var controller:Node
	var requested:=Vector2.ZERO
	var delivered:=Vector2.ZERO
	var observations:Array=[]
	func _physics_process(_delta:float) -> void:
		delivered=preload("res://scripts/NalaPhysicalMotion.gd").screen_input(renderer,requested,actor.position)
		observations.append({"tick":Engine.get_physics_frames(),"position":actor.position,"requested":requested,"delivered":delivered,"gradient":renderer.ground_gradient(actor.position)})
		if observations.size()>64: observations.pop_front()
		if controller.has_method("_is_walkable"): controller.set("touch_direction",delivered)
		else: actor.set("touch",delivered)

func _input(value:Vector2) -> void:
	if is_instance_valid(input_driver): input_driver.set("requested",value)
	delivered_input=PhysicalMotion.screen_input(renderer,value,player.position) if physical_pilot else value
	if controller.has_method("_is_walkable"): controller.set("touch_direction",delivered_input)
	else: player.set("touch",delivered_input)

func _controller_enabled(enabled:bool) -> void:
	if is_instance_valid(input_driver): input_driver.set_physics_process(enabled)
	if controller.has_method("_is_walkable"): controller.set_physics_process(enabled)
	else: player.set_physics_process(enabled)

func _open(outfit:String) -> void:
	triangles.clear()
	triangle_grid.clear()
	controller=load("res://scripts/Forest.gd").new() if outfit=="explorer" else Node2D.new()
	root.add_child(controller)
	controller.set_process(false)
	if outfit=="explorer":
		controller.set_physics_process(false)
		controller.set("syncing",true)
		controller.get("world_foley").set_process(false)
		controller.get("world_foley").set_physics_process(false)
		player=controller.get("avatar")
		renderer=controller.get("land_renderer")
		collision=controller.get("land_collision")
	else:
		collision=load("res://scripts/land/LandCollision.gd").new()
		collision.configure(root.get_node("GameState").world.landMaps.hub)
		controller.add_child(collision)
		player=load("res://scripts/Player.gd").new()
		controller.add_child(player)
		player.set_physics_process(false)
		player.set("hybrid_visual",true)
		var camera:=Camera2D.new()
		camera.zoom=Vector2(.88,.88)
		player.add_child(camera)
		renderer=load("res://scripts/land/LandWorld3D.gd").new()
		controller.add_child(renderer)
		renderer.setup(controller,player,camera,"hub")
		player.set("land_mask",collision.is_walkable)
		player.set("input_transform",renderer.input_motion)
		player.set("visual_motion_transform",renderer.visual_locomotion)
		player.get("surface_traversal").configure(root.get_node("GameState").world.landMaps.hub)
	player.set_meta("nala_lower_body_pilot",true)
	player.set_meta("nala_physical_walk_pilot",physical_pilot)
	player.get("swim_sprite").call("set_appearance","male_nusantara")
	renderer.set_process(false)
	if physical_pilot:
		var hook:=func(at:Vector2,velocity:Vector2,delta:float) -> Vector2: return PhysicalMotion.limit_velocity(renderer,at,velocity,delta)
		var position_hook:=func(from:Vector2,to:Vector2,delta:float) -> Vector2: return PhysicalMotion.limit_position(renderer,from,to,delta)
		if outfit=="explorer":
			controller.set("land_velocity_transform",hook)
			controller.set("land_position_transform",position_hook)
		else:
			player.set("land_velocity_transform",hook)
			player.set("land_position_transform",position_hook)
		input_driver=PhysicalInputDriver.new()
		input_driver.set("renderer",renderer)
		input_driver.set("actor",player)
		input_driver.set("controller",controller)
		input_driver.process_physics_priority=-100
		controller.add_child(input_driver)
		input_driver.set_physics_process(false)
	_index_meshes()

func _physical_inputs(at:Vector2) -> bool:
	var probes:=0
	for heading in range(32):
		for magnitude in [.10,.12,.15,.17,.18,.25,.5,1.0]:
			var input:=Vector2.from_angle(heading*TAU/32.0)*float(magnitude)
			var logical:=PhysicalMotion.logical_input(renderer,input,at)
			if not _check(logical.length()<=input.length()+.00001,"Physical input exceeds canonical logical cap"): return false
			var wrapped:Vector2=renderer.input_motion(PhysicalMotion.screen_input(renderer,input,at),at)
			if not _check(wrapped.distance_to(logical)<.00001,"Fixture screen-amplitude wrapper differs from intended renderer hook"): return false
			var actual:Vector3=renderer.ground_point(at+logical)-renderer.ground_point(at)
			var in_deadzone:=input.is_zero_approx()
			var expected:=0.0 if in_deadzone else input.length()*PhysicalMotion.WORLD_XY_SPEED/float(PhysicalMotion.LOGICAL_CAP)
			if not _check(absf(Vector2(actual.x,actual.y).length()-expected)<.0003,"Actual flat ground metric fails physical-speed input contract"): return false
			var screen:Vector2=renderer.view_projection.logical_motion_to_view(logical)
			if not in_deadzone and not _check(absf(screen.normalized().cross(input.normalized()))<.00001 and screen.dot(input)>0,"Physical input changes requested screen direction"): return false
			probes+=1
	print("NALA PHYSICAL INPUT PASS ",probes," actual-ground magnitude/direction/cap/wrapper probes")
	return true

func _origin() -> Vector2:
	for y in range(450,1200,30):
		for x in range(450,1350,30):
			var point:=Vector2(x,y)
			if not collision.is_walkable(point): continue
			var height:float=renderer.ground_point(point).z
			var valid:=true
			for heading in range(16):
				for radius in [35.0,70.0,105.0]:
					var probe:Vector2=point+Vector2.from_angle(heading*TAU/16.0)*float(radius)
					if not collision.is_walkable(probe) or absf(renderer.ground_point(probe).z-height)>.01:
						valid=false
						break
				if not valid: break
			if valid: return point
	return Vector2(INF,INF)

func _production_tick(value:Vector2,label:String) -> bool:
	_input(value)
	var before:=player.position
	var before_world:Vector3=renderer.ground_point(before)
	var prior_pose:Dictionary=renderer.actors_3d.counts.get("nalaLowerBody",{})
	var prior_distance:float=prior_pose.get("contacts",{}).get("acceptedDistance",0.0)
	await physics_frame
	await process_frame
	var now:=Engine.get_physics_frames()
	last_delta=float(now-last_physics_frame)/float(Engine.physics_ticks_per_second)
	last_physics_frame=now
	if is_instance_valid(input_driver): delivered_input=input_driver.get("delivered")
	if not _check(last_delta>0,"Production fixture must observe actual physics frames"): return false
	elapsed_physics+=last_delta
	logical_travel+=before.distance_to(player.position)
	var world_motion:Vector3=renderer.ground_point(player.position)-before_world
	world_motion.z=0
	physical_travel+=world_motion.length()
	renderer.call("_process",last_delta)
	var prior:=checks
	_measure(label)
	if checks==prior: return false
	var visual:Sprite2D=player.get("swim_sprite")
	var events:Array=visual.call("consume_foot_contacts")
	legacy_contacts+=events.size()
	var source:Dictionary=visual.call("locomotion_state")
	var pose:Dictionary=renderer.actors_3d.counts.nalaLowerBody
	if physical_pilot:
		if not _check(bool(pose.contacts.get("physicalContract",false)),"Physical input pilot did not select its explicit gait contract"): return false
		if not _check(float(pose.contacts.acceptedDistance)-prior_distance>=world_motion.length()-.003,"Accepted controller displacement froze physical-pilot feet"): return false
		if label.contains("joystick ") and value.is_zero_approx():
			if not _check(player.position.distance_to(before)<.0001,"Original joystick neutral zone moved actor from rest"): return false
	var phase:=label.split(" ",true,1)[1]
	if not windows.has(phase): windows[phase]={"seconds":0.0,"plannerContacts":0,"legacyContacts":0,"logicalDistance":0.0,"physicalDistance":0.0}
	windows[phase].seconds+=last_delta
	windows[phase].plannerContacts+=int(pose.contacts.contacts)-prior_planner_contacts
	windows[phase].legacyContacts+=events.size()
	windows[phase].logicalDistance+=before.distance_to(player.position)
	windows[phase].physicalDistance+=world_motion.length()
	prior_planner_contacts=int(pose.contacts.contacts)
	var rig:Node3D=renderer.actors_3d.get("_nala_lower")
	var upper:Sprite3D=rig.get("_parts").upper
	var region:Rect2=(upper.texture as AtlasTexture).region
	var equipment:Node3D=renderer.actors_3d.get("_equipment")
	var swing:=str(pose.contacts.swingSide)
	var planner_phase:Variant=null
	if swing!="": planner_phase=(0.0 if swing=="right" else .5)+float(pose.contacts.swingDistance)/maxf(.001,float(pose.contacts.landingDistance))*.5
	var record:={"case":label,"physicsFrame":now,"physicsDelta":last_delta,"elapsedPhysics":elapsed_physics,"elapsedWall":float(Time.get_ticks_usec()-began_usec)/1000000.0,"input":[value.x,value.y],"rawJoystickRadius":raw_joystick_radius,"deliveredInput":[delivered_input.x,delivered_input.y],"physicalPilot":physical_pilot,"position":[player.position.x,player.position.y],"acceptedLogical":logical_travel,"acceptedPhysical":physical_travel,"source":source,"upperAtlasRegion":[region.position.x,region.position.y,region.size.x,region.size.y],"actualEquipmentState":equipment.get("state").duplicate(true),"plannerCyclePhase":planner_phase,"legacyContacts":legacy_contacts,"pose":pose.duplicate(true)}
	sample_log.store_line(JSON.stringify(record))
	sample_log.flush()
	if capture and checks%capture_stride==0:
		RenderingServer.force_draw(false)
		var index:=frames.size()
		renderer.viewport_3d.get_texture().get_image().save_png(output+"/%04d.png"%index)
		record["frame"]=index
		frames.append(record)
		capture_log.store_line(JSON.stringify(record))
		capture_log.flush()
	return true

func run() -> void:
	root.size=Vector2i(1440,810)
	physical_pilot=OS.get_environment("NALA_PHYSICAL_WALK")=="1"
	analog_probe=OS.get_environment("NALA_PRODUCTION_ANALOG")=="1"
	joystick_probe=OS.get_environment("NALA_PRODUCTION_JOYSTICK")=="1"
	first_case=clampi(int(OS.get_environment("NALA_PRODUCTION_FIRST")) if OS.has_environment("NALA_PRODUCTION_FIRST") else 0,0,31)
	case_limit=clampi(int(OS.get_environment("NALA_PRODUCTION_CASES")) if OS.has_environment("NALA_PRODUCTION_CASES") else 32,1,32-first_case)
	capture=OS.get_environment("NALA_LOWER_CAPTURE")=="1"
	capture_stride=clampi(int(OS.get_environment("NALA_LOWER_CAPTURE_STRIDE")) if OS.has_environment("NALA_LOWER_CAPTURE_STRIDE") else 2,1,24)
	output=OS.get_environment("NALA_LOWER_OUTPUT") if OS.has_environment("NALA_LOWER_OUTPUT") else "res://../artifacts/godot/nala-production-"+str(int(Time.get_unix_time_from_system()))
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)),"Preserve prior production evidence; use a fresh output directory"): return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	sample_log=FileAccess.open(output+"/samples.jsonl",FileAccess.WRITE)
	capture_log=FileAccess.open(output+"/frames.jsonl",FileAccess.WRITE)
	var hashes:Dictionary={}
	for path in ["res://scripts/Player.gd","res://scripts/Forest.gd","res://scripts/CharacterVisual.gd","res://scripts/NalaFootPlant.gd","res://scripts/NalaLowerBody3D.gd","res://scripts/NalaPhysicalMotion.gd","res://scripts/AnalogJoystick.gd","res://scripts/land/LandActors3D.gd","res://../scripts/tests/nala-production-gait.gd","res://../scripts/tests/nala-lower-body.gd"]: hashes[path]=FileAccess.get_sha256(path)
	FileAccess.open(output+"/source.json",FileAccess.WRITE).store_string(JSON.stringify({"fixtureWorldSha256":FileAccess.get_sha256("res://../.runtime/world-map.json"),"files":hashes,"firstCase":first_case,"requestedCases":case_limit,"physicalPilot":physical_pilot,"analogProbe":analog_probe,"joystickProbe":joystick_probe,"additionalPhysicalDeadzone":false,"postAccelerationSegmentLimiter":physical_pilot,"acceptedPositionLimiter":physical_pilot,"physicsHz":Engine.physics_ticks_per_second,"captureStride":capture_stride,"acceptance":"Geometry diagnostic; cadence and arm opposition require sequence review. No default adoption."},"  "))
	var state:=root.get_node("GameState")
	if not _check(float(load("res://scripts/Player.gd").LAND_WALK_SPEED)==PhysicalMotion.LOGICAL_CAP,"Physical input contract differs from actual controller authority cap"): return
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var unchanged:=JSON.stringify({"world":state.world,"player":state.player})
	clock=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=false
	for action in ["left","right","up","down","interact","journal","inventory","map","character"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
		Input.action_release(action)
	for outfit in ["daily","explorer"]:
		var outfit_base:=0 if outfit=="daily" else 16
		if first_case>=outfit_base+16 or first_case+case_limit<=outfit_base: continue
		_open(outfit)
		var origin:=_origin()
		if not _check(is_finite(origin.x),"No 105-logical-radius authoritative flat floor for "+outfit): return
		if physical_pilot and not _physical_inputs(origin): return
		for reduced in [false,true]:
			clock.reduced_motion=reduced
			for heading in range(8):
				var scheduled:=outfit_base+(8 if reduced else 0)+heading
				if scheduled<first_case or scheduled>=first_case+case_limit: continue
				var label:String=str(outfit)+"/"+str(reduced)+"/"+str(heading)
				_reset_case(origin,outfit)
				_input(Vector2.ZERO)
				_controller_enabled(true)
				await physics_frame
				await process_frame
				_controller_enabled(false)
				player.get("swim_sprite").call("consume_foot_contacts")
				renderer.call("_process",0.0)
				last_delta=0.0
				var before_idle:=checks
				_measure(label+" idle")
				if checks==before_idle: return
				_controller_enabled(true)
				await physics_frame
				await process_frame
				_controller_enabled(false)
				var path:RefCounted=controller.get("land_path") if outfit=="explorer" else player.get("land_path")
				path.call("reset",origin)
				_input(Vector2.ZERO)
				elapsed_physics=0
				logical_travel=0
				physical_travel=0
				legacy_contacts=0
				prior_planner_contacts=0
				windows.clear()
				began_usec=Time.get_ticks_usec()
				last_physics_frame=Engine.get_physics_frames()
				_controller_enabled(true)
				var direction:=Vector2.from_angle(heading*PI*.25)
				var phases:Array=[]
				if joystick_probe:
					for radius in [.10,.14,.15,.16,.18,.20,.25,.30]:
						phases.append({"name":"joystick "+str(radius),"input":Joystick.analog(direction*float(radius)*100.0,100.0),"rawRadius":radius,"frames":12})
					phases.append({"name":"joystick-release","input":Vector2.ZERO,"frames":12})
				if analog_probe:
					for magnitude in [.10,.12,.15,.17,.18]: phases.append({"name":"analog "+str(magnitude),"input":direction*float(magnitude),"frames":12})
					phases.append({"name":"analog-release","input":Vector2.ZERO,"frames":12})
				phases.append_array([{"name":"walk","input":direction,"frames":48},{"name":"stop","input":Vector2.ZERO,"frames":18},{"name":"restart turn","input":-direction,"frames":30}])
				for phase in phases:
					raw_joystick_radius=phase.get("rawRadius",null)
					for frame in range(int(phase.frames)):
						if not await _production_tick(phase.input,label+" "+str(phase.name)): return
				_controller_enabled(false)
				var contacts:int=renderer.actors_3d.counts.nalaLowerBody.contacts.contacts
				production_cases.append({"case":label,"physicsSeconds":elapsed_physics,"wallSeconds":float(Time.get_ticks_usec()-began_usec)/1000000.0,"logicalDistance":logical_travel,"physicalDistance":physical_travel,"plannerContacts":contacts,"legacyContacts":legacy_contacts,"windows":windows.duplicate(true),"cadenceAccepted":false,"cameraZoom":renderer.source_camera.zoom.x})
				case_index+=1
				if case_index>=case_limit: break
			if case_index>=case_limit: break
		controller.free()
		if case_index>=case_limit: break
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(frames,"  "))
	FileAccess.open(output+"/cadence.json",FileAccess.WRITE).store_string(JSON.stringify({"cases":production_cases,"geometrySamples":checks,"complete32Cases":first_case==0 and case_index==32,"naturalWalkingAccepted":false,"armOppositionAccepted":false},"  "))
	if not _check(JSON.stringify({"world":state.world,"player":state.player})==unchanged,"Production fixture changed authoritative data"): return
	print("NALA PRODUCTION GEOMETRY DIAGNOSTIC PASS ",checks," samples/",case_index," cases. Cadence/arms pending; default lower-body stays OFF.")
	quit(0)
