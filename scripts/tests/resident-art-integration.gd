extends SceneTree

const RESIDENT_IDS:=["npc_direktur_cakrawala","npc_kid_bagas","npc_kid_kinasih","npc_kid_danu","npc_kid_gito","npc_kid_cempaka"]
var _clock:Node
var _state:Node
var _source:Node2D
var _renderer:Node2D
var _collision:Node2D
var _people:Array[Node2D]=[]
var _profiles:Array[Dictionary]=[]

func _initialize() -> void:
	_run.call_deferred()

func _spawn(profile:Dictionary) -> Node2D:
	var actor:Node2D=load("res://scripts/HubActor.gd").new()
	actor.actor_name=str(profile.name)
	actor.appearance_index=int(profile.appearance)
	actor.custom_sheet=load("res://resources/art/village-residents-v1.png")
	actor.custom_grid=Vector2i(3,2)
	actor.walkable=_collision.is_walkable
	actor.configure_activity(profile)
	var point:Array=profile.activity.work
	actor.position=Vector2(float(point[0]),float(point[1]))
	assert(_collision.is_walkable(actor.position),"Integration actor must use real authored work station")
	_source.add_child(actor)
	actor.set_process(false)
	actor.visible=false
	actor.activity_phase="work"
	actor._body_animation.update(2,Vector2.ZERO,true,false,false,false,false,str(actor.activity_kind))
	return actor

func _rig(actor:Node2D) -> Node3D:
	return _renderer.actors_3d._body_rig(actor)

func _assert_resident(actor:Node2D) -> void:
	var rig:Node3D=_rig(actor)
	assert(rig!=null and rig.get_script().resource_path.ends_with("ResidentArtRig3D.gd"),"Actual LandActors must select original-art rig by canonical resident ID")
	assert(_rig(actor)==rig,"Repeated production lookup must reuse one rig")
	var pose:Dictionary=rig.pose_snapshot()
	assert(str(pose.id)==str(actor.resident_id) and pose.authoredViews==1 and not pose.mirrored)
	assert(rig.find_children("OriginalResidentParts","MultiMeshInstance3D",true,false).size()==1,"One original-body draw holder per resident")
	assert(rig.find_children("SeparateHeldProp","Node3D",true,false).size()==1 and pose.separateProp,"One independent role prop holder per resident")
	assert(rig._held.global_position.distance_to(rig.hands.right)<.001,"Actual integrated prop remains attached to opaque palm")
	var billboard:Sprite3D=_renderer.actors_3d.sprites["NPC_"+str(actor.actor_name)]
	assert(not billboard.visible,"Fallback billboard must be hidden while original-art rig renders")
	assert(billboard.texture.get_size()==Vector2(96,128),"Six new appearances cannot address old 3x2 portrait atlas out of bounds")
	var texture_image:Image=billboard.texture.get_image()
	assert(texture_image!=null and not texture_image.is_empty() and texture_image.get_used_rect().size.y==112,"Hidden fallback still needs a valid canonical frame")
	assert(not _renderer.actors_3d._activities._actors.has(actor.get_instance_id()),"Generic book/watering can cannot duplicate this rig's owned role prop")
	var tint:Color=rig._body_material.get_shader_parameter("readable_tint")
	assert(tint.is_equal_approx(billboard.modulate) and tint.is_equal_approx(rig._tint),"Night readability tint must reach original pixel shader")
	for side in ["left","right"]:
		var foot:Dictionary=pose.contacts.feet[side]
		assert(Vector3(foot.sole).distance_to(_renderer.ground_point(foot.logical))<.001,"Stationary integrated sole must use actual support")
		assert(foot.grounded,"Idle/work station sole must remain planted")
	assert(rig.global_position.distance_to(_renderer.ground_point(actor.position))<.001,"Body origin must follow actual elevation, not a flat billboard offset")

func _run() -> void:
	_state=root.get_node("GameState")
	_clock=root.get_node("EnvironmentState")
	_state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	_state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive"}}
	_state.dive={}
	_clock.set_process(false)
	_clock.clock_paused=false
	_clock.reduced_motion=false
	_clock.authoritative=true
	_clock.set("_server_rain",false)
	_clock.set("_rain_amount",0)
	var immutable:=JSON.stringify(_state.world)
	_source=Node2D.new()
	root.add_child(_source)
	_collision=load("res://scripts/land/LandCollision.gd").new()
	_source.add_child(_collision)
	_collision.configure(_state.world.landMaps.hub)
	var player:Node2D=load("res://scripts/Player.gd").new()
	_source.add_child(player)
	player.position=Vector2(1320,650)
	player.set_physics_process(false)
	player.visible=false
	player.swim_sprite.set_appearance("male_nusantara")
	player.swim_sprite.set_outfit("daily")
	player.swim_sprite.set_locomotion(Vector2.ZERO,0)
	player.swim_sprite.animate(false,false,1,0)
	for profile in _state.world.surface_hub.residents:
		if RESIDENT_IDS.has(str(profile.id)):
			_profiles.append(profile)
			_people.append(_spawn(profile))
	assert(_people.size()==6)
	var legacy:Node2D
	for profile in _state.world.surface_hub.residents:
		if str(profile.name)=="Mang Ujang": legacy=_spawn(profile)
	assert(is_instance_valid(legacy),"Old Ujang rig must remain in the same production selector test")
	var camera:=Camera2D.new()
	_source.add_child(camera)
	_renderer=load("res://scripts/land/LandWorld3D.gd").new()
	_source.add_child(_renderer)
	_renderer.setup(_source,player,camera,"hub")
	_renderer.set_process(false)
	var day_tints:Dictionary={}
	for minute in [600,1320]:
		_clock.visual_minutes=minute
		_clock._process(0)
		_renderer._process(.3)
		assert(_renderer.actors_3d._body_rigs.size()==7,"Six resident rigs and original Ujang must coexist without duplicate body caches")
		for actor in _people:
			_assert_resident(actor)
			if minute==600: day_tints[str(actor.resident_id)]=_rig(actor)._tint
			else: assert(not Color(day_tints[str(actor.resident_id)]).is_equal_approx(_rig(actor)._tint),"Night must alter actual shader tint")
		assert(_rig(legacy).get_script().resource_path.ends_with("NpcBodyRig3D.gd"),"Legacy Ujang selection cannot silently migrate to resident helper")
		assert(_renderer.actors_3d._activities._actors.has(legacy.get_instance_id()),"Original fishing prop path must remain active for Ujang")
	_clock.clock_paused=true
	var paused:Array=[]
	for actor in _people: paused.append(_rig(actor).pose_snapshot())
	_renderer._process(.25)
	for index in range(_people.size()): assert(_rig(_people[index]).pose_snapshot()==paused[index],"Pause preserves integrated contact and work pose")
	_clock.clock_paused=false
	_state.dive={"id":"resident-integration-hidden","oxygen":77}
	_renderer._process(.25)
	assert(not _renderer.active and not _renderer.display.visible and _renderer.viewport_3d.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Dive transition must hide and stop the land viewport")
	for index in range(_people.size()): assert(_rig(_people[index]).pose_snapshot()==paused[index],"Disabled viewport cannot continue resident pose updates")
	assert(_state.dive.oxygen==77)
	_state.dive={}
	_renderer._process(.1)
	assert(_renderer.active and _renderer.display.visible and _renderer.viewport_3d.render_target_update_mode==SubViewport.UPDATE_ALWAYS)
	var detached:Node2D=_people[0]
	var old_rig:Node3D=_rig(detached)
	_source.remove_child(detached)
	_renderer.actors_3d._scan()
	_renderer._process(.1)
	await process_frame
	assert(not is_instance_valid(old_rig),"Detaching live source actor must remove its 3D rig and held prop")
	assert(not _renderer.actors_3d._body_rigs.has(detached.get_instance_id()))
	assert(not _renderer.actors_3d.sprites.has("NPC_"+str(detached.actor_name)))
	_source.add_child(detached)
	detached.set_process(false)
	detached.visible=false
	_renderer.actors_3d._scan()
	_renderer._process(.1)
	_assert_resident(detached)
	assert(_renderer.actors_3d._body_rigs.size()==7)
	var removed:Node2D=_people.pop_back()
	var removed_name:=str(removed.actor_name)
	var removed_id:=removed.get_instance_id()
	var removed_rig:Node3D=_rig(removed)
	removed.queue_free()
	await process_frame
	_renderer._process(2.1)
	await process_frame
	assert(not is_instance_valid(removed_rig) and not _renderer.actors_3d._body_rigs.has(removed_id),"Freed source actor cannot retain body/held prop")
	assert(not _renderer.actors_3d.sprites.has("NPC_"+removed_name) and not _renderer.actors_3d._shadows.has("NPC_"+removed_name))
	var recreated:Node2D=_spawn(_profiles[-1])
	_people.append(recreated)
	_renderer.actors_3d._scan()
	_renderer._process(.1)
	_assert_resident(recreated)
	assert(_renderer.actors_3d._body_rigs.size()==7)
	assert(JSON.stringify(_state.world)==immutable,"Resident rendering cannot mutate canonical world contract")
	_source.free()
	await process_frame
	print("RESIDENT ART INTEGRATION PASS:6 canonical production LandActors rigs + unchanged Ujang, valid hidden original frames, one body/role prop each, no generic duplicate, day/night shader tint, actual support, pause/dive disable/resume, live detach/reattach/free/recreate lifecycle; no world mutation")
	quit()
