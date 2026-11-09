extends SceneTree
var _capture:=false
var _capture_index:=0
var _capture_title:Label
var _sequence:Array=[]
const OUTPUT:="res://../artifacts/godot/nala-gait-transitions"
class MotionOwner extends Node2D:
	var frozen:=false

func _initialize() -> void: call_deferred("_run")

func _step(visual:Sprite2D,velocity:Vector2,delta:float,tag:String) -> Dictionary:
	if not _capture: await process_frame
	visual.set_locomotion(velocity,delta)
	visual.animate(velocity.length()>.1,false,1,0)
	var state:Dictionary=visual.locomotion_state()
	if _capture:
		visual.position=Vector2(320,300)
		visual.scale=Vector2(2,2)
		_capture_title.text="%s / %s\nrequested %s | drawn %s | frame%d | settling %s | distance %.2f"%[visual.outfit,tag,state.requestedDirection,state.artworkDirection,state.frame,state.settling,state.distance]
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUTPUT+"/%04d.png"%_capture_index)
		_sequence.append({"index":_capture_index,"tag":tag,"outfit":visual.outfit,"reduced":root.get_node("EnvironmentState").reduced_motion,"state":state,"texture":visual.texture.resource_path,"atlasFrame":visual.frame})
		_capture_index+=1
	return state

func _walk_to_frame(visual:Sprite2D,wanted:int) -> void:
	for tick in range(40):
		var state:=await _step(visual,Vector2(100,0),.02,"walk-to-%d"%wanted)
		if state.frame==wanted and state.artworkDirection=="east": return
	assert(false,"Physical displacement must reach the requested painted pose")

func _transition_checks() -> void:
	var clock:=root.get_node("EnvironmentState")
	var checked:=0
	for outfit in ["daily","explorer"]:
		for reduced in [false,true]:
			clock.reduced_motion=reduced
			var owner:=MotionOwner.new()
			root.add_child(owner)
			var visual:Sprite2D=load("res://scripts/CharacterVisual.gd").new()
			owner.add_child(visual)
			visual.set_appearance("male_nusantara")
			visual.set_outfit(outfit)
			for raised in [3,7]:
				await _walk_to_frame(visual,raised)
				visual.consume_foot_contacts()
				var distance:float=visual.locomotion_state().distance
				var frames:Array[int]=[raised]
				for tick in range(12):
					var state:=await _step(visual,Vector2.ZERO,1.0/60,"stop-from-%d"%raised)
					assert(state.distance==distance and visual.consume_foot_contacts().is_empty(),"Visual landing must not fabricate physical travel or footstep events")
					if state.poseWalking and frames.back()!=state.frame: frames.append(state.frame)
					checked+=1
				assert(frames==([3,2,1] if raised==3 else [7,6,5]),"Reviewed knee-lowering frames must precede neutral; no backwards half-cycle swap")
				assert(not visual.locomotion_state().settling and visual.vframes==1)
			# Pause during the landing, rather than merely testing an already neutral sprite.
			await _walk_to_frame(visual,3)
			await _step(visual,Vector2.ZERO,1.0/60,"landing-before-pause")
			var held_frame:=visual.frame
			var held_distance:float=visual.locomotion_state().distance
			clock.clock_paused=true
			for tick in range(3):
				var state:=await _step(visual,Vector2.ZERO,.1,"paused-landing")
				assert(visual.frame==held_frame and state.distance==held_distance and state.poseFrozen)
			clock.clock_paused=false
			root.get_node("ViewportLayout").host_paused=true
			await _step(visual,Vector2.ZERO,.2,"host-paused-landing")
			assert(visual.frame==held_frame and visual.locomotion_state().distance==held_distance)
			root.get_node("ViewportLayout").host_paused=false
			owner.frozen=true
			await _step(visual,Vector2.ZERO,.2,"owner-frozen-landing")
			assert(visual.frame==held_frame and visual.locomotion_state().distance==held_distance)
			owner.frozen=false
			for tick in range(12): await _step(visual,Vector2.ZERO,1.0/60,"resume-landing")
			assert(visual.vframes==1)
			await _walk_to_frame(visual,0)
			visual.consume_foot_contacts()
			var distance:float=visual.locomotion_state().distance
			var drawn:="east"
			var seen:Array[String]=[drawn]
			for tick in range(12):
				var state:=await _step(visual,Vector2(-100,0),1.0/60,"reverse-180")
				var before:int=visual.DIRECTIONS.find(drawn)
				var after:int=visual.DIRECTIONS.find(state.artworkDirection)
				assert(posmod(after-before,8) in [0,1,7],"A rendered turn must visit neighboring authored views instead of reflecting or jumping across the body")
				assert(state.requestedDirection=="west" and not visual.flip_h)
				var equipment:Dictionary=visual.get_equipment_state()
				assert(equipment.facingDirection==state.artworkDirection and is_equal_approx(equipment.gaitPhase,state.posePhase),"Detachable gear must follow the displayed body row and phase")
				if drawn!=state.artworkDirection: seen.append(state.artworkDirection)
				drawn=state.artworkDirection
				checked+=1
			assert(drawn=="west" and seen.size()==5)
			assert(is_equal_approx(visual.locomotion_state().distance,distance+20.0),"Turn art must not alter accepted movement distance")
			for tick in range(6): await _step(visual,Vector2(0,-100),1.0/60,"turn-90")
			assert(visual.locomotion_state().artworkDirection=="north")
			for cadence in [1.0/30,.1]:
				for tick in range(4): await _step(visual,Vector2(175,0),cadence,"stress-prepare-east")
				assert(visual.locomotion_state().artworkDirection=="east")
				visual.consume_foot_contacts()
				var before_distance:float=visual.locomotion_state().distance
				drawn="east"
				for tick in range(6):
					var state:=await _step(visual,Vector2(-175,0),cadence,"stress-turn-%0.3f"%cadence)
					var step:int=posmod(visual.DIRECTIONS.find(state.artworkDirection)-visual.DIRECTIONS.find(drawn),8)
					assert(step in [0,1,7],"175px/s at30Hz or a100ms spike must not skip an authored view")
					drawn=state.artworkDirection
					checked+=1
				var after_distance:float=visual.locomotion_state().distance
				assert(drawn=="west" and is_equal_approx(after_distance-before_distance,175*cadence*6))
				assert(visual.consume_foot_contacts().size()==floori(after_distance/32)-floori(before_distance/32),"Render-facing throttling must not change accepted-distance footstep cadence")
			for tick in range(4): await _step(visual,Vector2(175,0),1.0/30,"prepare-multiple-physics")
			var rows:Array[String]=[visual.locomotion_state().artworkDirection]
			for tick in range(4):
				visual.set_locomotion(Vector2(-175,0),1.0/60)
				visual.animate(true,false,-1,0)
				var row:String=visual.locomotion_state().artworkDirection
				if not rows.has(row): rows.append(row)
			assert(rows.size()<=2,"Four physics samples in one render frame may expose at most one new facing view")
			assert(owner.position==Vector2.ZERO,"Visual settling and turns must not translate the actor root")
			visual.free()
			owner.free()
	clock.reduced_motion=false
	if _capture: FileAccess.open(OUTPUT+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(_sequence,"  "))
	print("NALA TRANSITIONS PASS: ",checked," stop/turn samples, daily/explorer drawn lowering poses3-2-1 and7-6-5; adjacent-view180/90 turns, gear-row agreement, frozen landing, unchanged distance/step events, normal/reduced. Component sequence is not a world-sole-lock claim")

func _run() -> void:
	_capture=OS.get_environment("NALA_GAIT_CAPTURE")=="1"
	if _capture:
		assert(DisplayServer.get_name()!="headless")
		root.size=Vector2i(960,540)
		DirAccess.make_dir_recursive_absolute(OUTPUT)
		var background:=ColorRect.new()
		background.color=Color("263b40")
		background.size=Vector2(960,540)
		root.add_child(background)
		_capture_title=Label.new()
		_capture_title.position=Vector2(18,16)
		root.add_child(_capture_title)
		var floor_line:=Line2D.new()
		floor_line.points=PackedVector2Array([Vector2(200,380),Vector2(440,380)])
		floor_line.width=1
		floor_line.default_color=Color("d0ad66")
		root.add_child(floor_line)
	var visual: Sprite2D=load("res://scripts/CharacterVisual.gd").new()
	root.add_child(visual)
	var gear_script=load("res://scripts/CharacterEquipment3D.gd")
	for id in ["male_default","male_nusantara","female_default","female_nusantara"]:
		visual.set_appearance(id)
		for outfit in ["daily","explorer","diving"]:
			visual.set_outfit(outfit)
			visual.animate(false,false,1,0)
			for index in range(8):
				var velocity:=Vector2.RIGHT.rotated(index*PI*.25)*175
				#17.5 accepted units, with real render boundaries for a maximum180turn.
				for tick in range(4):
					visual.set_locomotion(velocity,.025)
					visual.animate(true,false,1,0)
					await process_frame
				var state: Dictionary=visual.locomotion_state()
				assert(visual.hframes==8 and visual.vframes==8)
				assert(state.supportedDirections.size()==8 and not state.directionalFallback)
				assert(not visual.flip_h and visual.frame/8==index)
				assert(visual.get_land_pivot()==Vector2(64,104))
				var gear: Dictionary=visual.get_equipment_state()
				assert(gear.facingDirection==visual.DIRECTIONS[index])
				var layout: Dictionary=gear_script.land_layout(gear.facingDirection,gear.gaitPhase,true)
				assert((layout.tank.z>0)==(index in [5,6,7]))
				var before: float=state.distance
				visual.set_locomotion(Vector2.ZERO,.4)
				visual.animate(false,false,1,0)
				assert(visual.vframes==1 and visual.frame==index)
				assert(visual.locomotion_state().distance==before)
			visual.set_locomotion(Vector2(100,0),.2)
			visual.animate(true,false,1,0)
			visual.set_locomotion(Vector2(-100,0),.01)
			visual.animate(true,false,-1,0)
			var turn_stop_distance:float=visual.locomotion_state().distance
			for tick in range(4):
				visual.set_locomotion(Vector2.ZERO,.1)
				visual.animate(false,false,-1,0)
				await process_frame
			assert(visual.vframes==1 and visual.frame==4 and visual.get_equipment_state().facingDirection=="west","All12sets must finish a pending turn while standing, rather than retain an unrelated intermediate direction")
			assert(visual.locomotion_state().distance==turn_stop_distance)
	visual.consume_foot_contacts()
	var before: float=visual.locomotion_state().distance
	visual.set_locomotion(Vector2(64,0),1)
	assert(is_equal_approx(visual.locomotion_state().distance,before+64))
	assert(visual.consume_foot_contacts().size()==2)
	assert(visual.consume_foot_contacts().is_empty())
	visual.animate(true,true,1,0)
	before=visual.locomotion_state().distance
	visual.set_locomotion(Vector2(175,0),2)
	assert(visual.locomotion_state().distance==before)
	assert(visual.hframes==3 and visual.frame>=3)
	visual.free()
	await _transition_checks()
	print("PLAYER LOCOMOTION PASS:12 outfits x8 drawn directions,175 displacement phase, neutral idle, once-only contacts, water isolation, directional modular gear")
	quit()
