extends SceneTree

var clock:Node
var collision:Node2D
var profiles:Array=[]
var step_count:=0
var _barrier:=false
var _barrier_point:=Vector2(1210,1250)

class RigStage extends Node3D:
	func map_point(_point:Vector2,_height:float) -> Vector3: return Vector3.ZERO
	func ground_height(_point:Vector2) -> float: return 0.0
	func camera_forward() -> Vector3: return Vector3(0,0,-1)

func _initialize() -> void:
	call_deferred("run")

func _at(profile:Dictionary,key:String) -> Vector2:
	var point:Array=profile.activity[key]
	return Vector2(float(point[0]),float(point[1]))

func _can_walk(point:Vector2) -> bool:
	return collision.is_walkable(point) and (not _barrier or point.distance_to(_barrier_point)>24)

func _tick(actor:Node2D,delta:float=.1) -> void:
	var previous:=actor.position
	actor.call("_process",delta)
	assert(actor.position.distance_to(previous)<=26.0*delta+.001,"No teleport or excessive travel speed")
	assert(_can_walk(actor.position),actor.actor_name+" left real authored floors or entered a solid footprint")
	if actor.moved_velocity.length()>.1: step_count+=1

func _reach(actor:Node2D,destination:Vector2) -> void:
	for tick in range(3500):
		_tick(actor)
		if actor.position.distance_to(destination)<2:
			_tick(actor,0)
			return
	assert(false,actor.actor_name+" failed to reach a real connected station: "+str(actor.activity_state()))

func _person(profile:Dictionary) -> Node2D:
	var actor:Node2D=load("res://scripts/HubActor.gd").new()
	actor.actor_name=str(profile.name)
	actor.position=_at(profile,"work")
	actor.walkable=Callable(self,"_can_walk")
	root.add_child(actor)
	actor.set_process(false)
	actor.configure_activity(profile)
	return actor

func _work(actor:Node2D,profile:Dictionary) -> void:
	clock.visual_minutes=float(profile.activity.startMinute)
	clock.elapsed_seconds=0
	_reach(actor,_at(profile,"work"))
	for tick in range(20): _tick(actor)
	assert(actor.activity_state().phase=="work")
	assert(actor.body_animation_state().clip=="work_loop")

func _talk_and_resume(actor:Node2D,profile:Dictionary) -> void:
	var player:=Node2D.new()
	player.position=actor.position+Vector2(40,0)
	root.add_child(player)
	actor.player=player
	var station:=actor.position
	clock.clock_paused=true
	for tick in range(20):
		_tick(actor)
		assert(actor.position==station and actor.activity_motion==0)
		assert(not actor.body_animation_state().events.has("step"))
	assert(actor.body_animation_state().clip=="interact","Work must tidy before dialogue, without another work loop")
	clock.clock_paused=false
	actor.player=null
	player.free()
	_work(actor,profile)

func _commute_pause(actor:Node2D,profile:Dictionary) -> void:
	clock.visual_minutes=float(profile.activity.endMinute)
	var before:=actor.position
	_tick(actor,0)
	assert(actor.position==before,"Time boundary must not teleport")
	for tick in range(20): _tick(actor)
	assert(actor.activity_state().moving)
	var stopped:=actor.position
	var animation:Dictionary=actor.body_animation_state()
	clock.clock_paused=true
	for tick in range(10): _tick(actor)
	assert(actor.position==stopped and actor.moved_velocity==Vector2.ZERO)
	assert(actor.body_animation_state().elapsed==animation.elapsed,"Reading/menu/focus pause must freeze gait time")
	assert(actor.body_animation_state().events.is_empty())
	clock.clock_paused=false
	var player:=Node2D.new()
	player.position=actor.position
	root.add_child(player)
	actor.player=player
	for tick in range(10): _tick(actor)
	assert(actor.position.distance_to(stopped)>0,"A nearby player alone must not freeze a travelling resident")
	assert(actor.position.distance_to(stopped)<165,"The resident remains within dialogue reach over this short interval")
	actor.player=null
	player.free()
	_reach(actor,_at(profile,"rest"))
	assert(actor.activity_state().phase=="rest")

func _blocked_recovery() -> void:
	var profile:Dictionary=profiles.filter(func(value:Dictionary)->bool:return value.name=="Mang Ujang")[0]
	_barrier_point=_at(profile,"rest")
	var actor:=_person(profile)
	clock.reduced_motion=true
	clock.visual_minutes=float(profile.activity.endMinute)
	clock.elapsed_seconds=0
	_tick(actor,0)
	# The obstruction is introduced AFTER the real route was planned.
	_barrier=true
	var stopped:=false
	for tick in range(200):
		_tick(actor)
		if str(actor.activity_state().phase).begins_with("blocked_"):
			stopped=true
			break
	assert(stopped,"Test must reach an actually blocked segment")
	var at:=actor.position
	var distance:float=actor.body_animation_state().distance
	for tick in range(200):
		_tick(actor)
		assert(actor.position==at,"An unresolved obstacle must not be crossed or bypassed by teleport")
		assert(actor.moved_velocity==Vector2.ZERO)
		assert(actor.body_animation_state().distance==distance)
		assert(not actor.body_animation_state().events.has("step"),"Blocked actors must stop actual step events")
	assert(int(actor.activity_state().routeAttempts)<=7,"Blocked pathfinding must back off, not rebuild every frame")
	assert(float(actor.activity_state().retryIn)<=8.0)
	_barrier=false
	_reach(actor,_at(profile,"rest"))
	assert(actor.activity_state().phase=="rest","A cleared temporary obstruction must recover to the same real station")
	actor.free()

func _reduced_rigs() -> void:
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(192,192)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var stage:=RigStage.new()
	viewport.add_child(stage)
	var camera:=Camera3D.new()
	camera.position=Vector3(0,45,500)
	stage.add_child(camera)
	camera.make_current()
	clock.reduced_motion=true
	for name in ["Mang Ujang","Bu Darmi","Yu Sari"]:
		var profile:Dictionary=profiles.filter(func(value:Dictionary)->bool:return value.name==name)[0]
		var actor:=_person(profile)
		var rig:Node3D=load("res://scripts/NpcBodyRig3D.gd").new()
		stage.add_child(rig)
		assert(rig.configure(stage,actor))
		var animation=actor.get("_body_animation")
		animation.update(.1,Vector2(26,0),false,false,false,false,true,actor.activity_kind)
		actor.moved_velocity=Vector2(26,0)
		rig.update_pose(Color.WHITE)
		var foot:Vector3=rig.sprites.foot_left.position
		var hand:Vector3=rig.sprites.hand_left.position
		animation.update(.2,Vector2(26,0),false,false,false,false,true,actor.activity_kind)
		rig.update_pose(Color.WHITE)
		assert(foot.distance_to(rig.sprites.foot_left.position)>.1,"Reduced-motion essential gait must not slide in a static pose")
		assert(hand.distance_to(rig.sprites.hand_left.position)>.1,"Hands follow actual travel, not a frozen work tool pose")
		actor.moved_velocity=Vector2.ZERO
		animation.update(.1,Vector2.ZERO,false,false,false,false,true,actor.activity_kind)
		rig.update_pose(Color.WHITE)
		var blocked:Vector3=rig.sprites.foot_left.position
		animation.update(1,Vector2.ZERO,false,false,false,false,true,actor.activity_kind)
		rig.update_pose(Color.WHITE)
		assert(rig.sprites.foot_left.position==blocked and animation.events.is_empty())
		animation.update(1,Vector2.ZERO,true,false,false,false,true,actor.activity_kind)
		rig.update_pose(Color.WHITE)
		var still_hand:Vector3=rig.sprites.hand_left.position
		animation.update(3,Vector2.ZERO,true,false,false,false,true,actor.activity_kind)
		rig.update_pose(Color.WHITE)
		assert(rig.sprites.hand_left.position==still_hand and animation.events.is_empty(),"Reduced-motion work flourishes remain still and do not emit action events")
		animation.update(1,Vector2.ZERO,false,false,true,true,true,actor.activity_kind)
		animation.update(1,Vector2.ZERO,false,false,true,true,true,actor.activity_kind)
		rig.update_pose(Color.WHITE)
		var talking_foot:Vector3=rig.sprites.foot_left.position
		animation.update(1,Vector2.ZERO,false,false,true,true,true,actor.activity_kind)
		rig.update_pose(Color.WHITE)
		assert(animation.clip=="interact" and rig.sprites.foot_left.position==talking_foot)
		assert(not animation.events.has("step"))
		rig.free()
		actor.free()
	viewport.free()

func run() -> void:
	var state:Node=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var before:=JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive,"adventure":state.adventure})
	clock=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.authoritative=false
	clock.clock_paused=false
	collision=load("res://scripts/land/LandCollision.gd").new()
	collision.configure(state.world.landMaps.hub)
	root.add_child(collision)
	profiles=state.world.surface_hub.residents.duplicate(true)
	var gardener:Dictionary=state.world.surface_hub.districtActivities["Bu Darmi"].duplicate(true)
	gardener.name="Bu Darmi"
	profiles.append(gardener)
	var new_ids:Array[String]=["npc_direktur_cakrawala","npc_kid_bagas","npc_kid_kinasih","npc_kid_danu","npc_kid_gito","npc_kid_cempaka"]
	var has_expansion:bool=profiles.any(func(profile:Dictionary)->bool:return str(profile.get("visual",{}).get("kind","")) in ["child","director"])
	var ids:Dictionary={}
	var names:Dictionary={}
	for profile in profiles:
		assert(not names.has(str(profile.name)),"One actor per resident, including Bu Darmi")
		names[str(profile.name)]=true
		if profile.has("id"):
			assert(not ids.has(str(profile.id)),"Canonical resident IDs remain unique")
			ids[str(profile.id)]=true
	assert(profiles.size()==(13 if has_expansion else 7),"Exercise every declared resident in the active world package")
	if has_expansion:
		for id in new_ids: assert(ids.has(id),"Expanded routine must include all five children and the distinct director")
	for reduced in [false,true]:
		clock.reduced_motion=reduced
		for profile in profiles:
			clock.elapsed_seconds=0
			clock.visual_minutes=float(profile.activity.startMinute)-1
			var actor:=_person(profile)
			_tick(actor,0)
			assert(str(actor.activity_state().phase).ends_with("rest"))
			_work(actor,profile)
			_talk_and_resume(actor,profile)
			_commute_pause(actor,profile)
			_work(actor,profile)
			clock.elapsed_seconds=180
			var dry_position:=actor.position
			_tick(actor,0)
			assert(actor.position==dry_position and str(actor.activity_state().phase).ends_with("shelter"))
			_reach(actor,_at(profile,"shelter"))
			assert(actor.activity_state().phase=="shelter")
			_work(actor,profile)
			if reduced: assert(actor.activity_motion==0)
			actor.free()
	_blocked_recovery()
	_reduced_rigs()
	assert(JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive,"adventure":state.adventure})==before,"Local routines cannot award items, alter progression or rewrite routes")
	print("VILLAGE06 PASS:",profiles.size()," real profiles normal/reduced; work-talk-resume-home-rain-return; actual collision-checked steps=",step_count,"; modal pause; bounded blocked recovery;3 reduced-motion rigs; no world/player mutation")
	collision.free()
	quit()
