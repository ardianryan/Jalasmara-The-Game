extends Node3D

var renderer: Node
var source: Node2D
var actor: Node2D
var sprites: Dictionary={}
var _frames: Dictionary={}
var _npcs: Array[Node2D]=[]
var _creatures: Array[Node2D]=[]
var _scan_clock:=0.0
var counts: Dictionary={}
var _alpha_bottom: Dictionary={}
var _shadows: Dictionary={}
var _shadow_material: ShaderMaterial
var max_foot_error:=0.0
var _equipment: Node3D
var _activities: Node3D
var _body_rigs: Dictionary={}
var _wet_effects: MultiMeshInstance3D

func configure(owner_renderer: Node, scene: Node2D, player: Node2D) -> void:
	renderer=owner_renderer
	source=scene
	actor=player
	_scan()

func _scan() -> void:
	_npcs.clear()
	_creatures.clear()
	for child in source.find_children("*","Node2D",true,false):
		if child.is_queued_for_deletion(): continue
		var script: Script=child.get_script()
		if script!=null and script.resource_path.ends_with("HubActor.gd"):
			_npcs.append(child)
		elif "species" in child and "elapsed" in child and "width" in child:
			_creatures.append(child)
	var live_keys: Dictionary={}
	for npc in _npcs: live_keys["NPC_"+str(npc.actor_name)]=true
	for key in sprites.keys():
		if str(key).begins_with("NPC_") and not live_keys.has(key):
			if is_instance_valid(sprites[key]): sprites[key].queue_free()
			sprites.erase(key)
			if _shadows.has(key):
				if is_instance_valid(_shadows[key]): _shadows[key].queue_free()
				_shadows.erase(key)

func _frame(texture: Texture2D, rect: Rect2) -> AtlasTexture:
	var key:=str(texture.get_instance_id())+str(rect)
	if not _frames.has(key):
		var frame:=AtlasTexture.new()
		frame.atlas=texture
		frame.region=rect
		frame.filter_clip=true
		_frames[key]=frame
	return _frames[key]

func _sprite(key: String, texture: Texture2D, feet: Vector2, dimensions: Vector2, rise: float, flip:=false, authored_pivot_y := -1.0, visual_lift := 0.0) -> Sprite3D:
	var sprite: Sprite3D=sprites.get(key)
	if sprite==null:
		sprite=Sprite3D.new()
		sprite.name=key.validate_node_name()
		sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		sprite.shaded=false
		sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.alpha_scissor_threshold=.5
		sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sprite)
		sprites[key]=sprite
	sprite.texture=texture
	sprite.pixel_size=1
	sprite.scale=Vector3(dimensions.x/texture.get_width(),dimensions.y/texture.get_height(),1)
	if authored_pivot_y<0 and not _alpha_bottom.has(texture.get_instance_id()):
		var image:=texture.get_image()
		var bottom:=texture.get_height()
		if image!=null and not image.is_empty():
			if image.is_compressed(): image.decompress()
			var found:=false
			for y in range(image.get_height()-1,-1,-1):
				for x in range(image.get_width()):
					if image.get_pixel(x,y).a>.5:
						bottom=y+1
						found=true
						break
				if found: break
		_alpha_bottom[texture.get_instance_id()]=float(bottom)/texture.get_height()
	rise=(authored_pivot_y/texture.get_height()-.5)*dimensions.y if authored_pivot_y>=0 else (float(_alpha_bottom[texture.get_instance_id()])-.5)*dimensions.y
	var height: float=renderer.ground_height(feet)
	var up: Vector3=renderer.camera_up()
	var forward: Vector3=renderer.camera_forward()
	var lift:=Vector3(0,0,visual_lift)
	var support: Vector3=renderer.ground_point(feet) if renderer.has_method("ground_point") else renderer.map_point(feet,height)
	sprite.position=support+up*rise-forward*8+lift
	var projected: Vector2=renderer.logical_on_height(sprite.position-up*rise-lift,height)
	max_foot_error=maxf(max_foot_error,projected.distance_to(feet))
	if key=="Nala":
		counts["playerGrounding"]={"height":height,"visualLift":visual_lift,"support":[feet.x,feet.y],"visualFoot":[sprite.position.x-up.x*rise+forward.x*8,sprite.position.y-up.y*rise+forward.y*8,sprite.position.z-up.z*rise+forward.z*8],"rootMotion":false}
	_shadow(key,feet,height,dimensions.x*.18)
	sprite.modulate=_readable_tint(feet,height)
	sprite.flip_h=flip
	sprite.visible=true
	return sprite

func _shadow(key: String,feet: Vector2,height: float,radius: float) -> void:
	var mesh: MeshInstance3D=_shadows.get(key)
	if mesh==null:
		if _shadow_material==null:
			var shader:=Shader.new()
			shader.code="shader_type spatial; render_mode unshaded,cull_disabled,depth_draw_never; void fragment(){ALBEDO=vec3(.08,.07,.05);ALPHA=.17;}"
			_shadow_material=ShaderMaterial.new()
			_shadow_material.shader=shader
		var tool:=SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in range(16):
			for angle in [null,float(index)*TAU/16.0,float(index+1)*TAU/16.0]:
				var vertex: Vector3=Vector3.ZERO if angle==null else renderer.map_point(Vector2(cos(float(angle))*radius,sin(float(angle))*radius*.3),0)
				tool.set_normal(Vector3(0,0,1))
				tool.add_vertex(vertex)
		tool.index()
		mesh=MeshInstance3D.new()
		mesh.mesh=tool.commit()
		mesh.material_override=_shadow_material
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mesh)
		_shadows[key]=mesh
	var support: Vector3=renderer.ground_point(feet) if renderer.has_method("ground_point") else renderer.map_point(feet,height)
	mesh.position=support+renderer.map_point(feet,height+.35)-renderer.map_point(feet,height)

func update_actors(delta: float) -> void:
	if not is_instance_valid(actor): return
	_update_wet_marks()
	_scan_clock+=delta
	if _scan_clock>2:
		_scan_clock=0
		_scan()
	max_foot_error=0
	counts={"player":0,"npcs":0,"creatures":0}
	if not is_instance_valid(_activities):
		_activities=preload("res://scripts/VillageActivity3D.gd").new()
		add_child(_activities)
		_activities.configure(renderer)
	_activities.begin_frame()
	var resident_states: Dictionary={}
	var body_clips: Dictionary={}
	for id in _body_rigs.keys():
		var old_rig: Node3D=_body_rigs[id]
		if not is_instance_valid(old_rig.actor) or old_rig.actor.is_queued_for_deletion():
			old_rig.queue_free()
			_body_rigs.erase(id)
	if "swim_sprite" in actor:
		var visual: Sprite2D=actor.get("swim_sprite")
		if visual!=null and visual.texture!=null:
			var cell:=visual.texture.get_size()/Vector2(visual.hframes,visual.vframes)
			var rect:=Rect2(Vector2(visual.frame%visual.hframes,floori(float(visual.frame)/visual.hframes))*cell,cell)
			var pivot: Vector2=visual.get_land_pivot() if visual.has_method("get_land_pivot") else Vector2.ZERO
			var traversal: Dictionary=actor.get("traversal_state") if "traversal_state" in actor else {}
			var lift:=clampf(float(traversal.get("bodyLift",0)),0,1.6)
			var nala := _sprite("Nala",_frame(visual.texture,rect),actor.position,cell*visual.scale.abs(),-visual.position.y,visual.flip_h,pivot.y if pivot!=Vector2.ZERO else -1.0,lift)
			var gear: Dictionary=visual.get_equipment_state() if visual.has_method("get_equipment_state") else {}
			_update_equipment(nala,gear,false,visual.flip_h)
			counts.player=1
	elif "sheet" in actor:
		var sheet: Texture2D=actor.get("sheet")
		if sheet:
			var moving: bool=actor.get("walking")
			var clock: float=actor.get("clock")
			var frame:=1+int(clock*8)%2 if moving else 0
			var outfit: String=str(actor.get("outfit")) if "outfit" in actor else "explorer"
			var clothing: bool=sheet.resource_path.ends_with("-outfits-v1.png")
			if clothing: frame+=int({"daily":0,"explorer":1,"diving":2}.get(outfit,1))*3
			var cell:=sheet.get_size()/3.0
			var facing: Vector2=actor.get("facing")
			var nala := _sprite("Nala",_frame(sheet,Rect2(Vector2((frame%3)*cell.x,floori(float(frame)/3)*cell.y),cell)),actor.position,Vector2(100,100),50,facing.x<0)
			var equipment: Dictionary=actor.get("equipment") if "equipment" in actor else {}
			var modular:=ResourceLoader.exists("res://resources/art/"+str(actor.get("variant")).replace("_","-")+"-base-v1.png") if "variant" in actor else false
			var gear: Dictionary=preload("res://scripts/CharacterVisual.gd").equipment_state(outfit,equipment,modular)
			if clothing: gear.vest=false
			_update_equipment(nala,gear,false,facing.x<0)
			counts.player=1
	for npc in _npcs:
		if not is_instance_valid(npc): continue
		var key: String=str(npc.actor_name)
		var sheet: Texture2D
		var frame: Texture2D
		if bool(npc.crate):
			frame=preload("res://scripts/ItemIcons.gd").texture("cache")
		else:
			sheet=preload("res://resources/art/npc-atlas.png")
			var grid:=Vector2i(2,2)
			if "custom_sheet" in npc and npc.get("custom_sheet")!=null:
				sheet=npc.get("custom_sheet")
				if "custom_grid" in npc: grid=npc.get("custom_grid")
			var index: int={"Mbah Wira":0,"Beno":1,"Bu Darmi":2,"Inspektur Raka":3}.get(key,0)
			if "appearance_index" in npc and int(npc.get("appearance_index"))>=0: index=int(npc.get("appearance_index"))
			var cell:=sheet.get_size()/Vector2(grid)
			frame=_frame(sheet,Rect2(Vector2(index%grid.x,floori(float(index)/grid.x))*cell,cell))
		var flip_npc := false
		if not bool(npc.crate):
			var logical_facing:=Vector2(float(npc.get("_facing")),0)
			if "moved_velocity" in npc and npc.moved_velocity.length()>.1:
				logical_facing=npc.moved_velocity
			elif npc.has_method("body_animation_state"):
				logical_facing={"east":Vector2.RIGHT,"west":Vector2.LEFT,"north":Vector2.UP,"south":Vector2.DOWN}.get(str(npc.body_animation_state().direction),logical_facing)
			var view_facing: Vector2=renderer.visual_motion(logical_facing,renderer.ground_gradient(npc.position).dot(logical_facing))
			flip_npc=view_facing.x<0
		var npc_sprite:=_sprite("NPC_"+key,frame,npc.position,Vector2(70,70) if bool(npc.crate) else Vector2(100,100),30 if bool(npc.crate) else 36,flip_npc)
		if "custom_tint" in npc: npc_sprite.modulate*=npc.get("custom_tint")
		var rig: Node3D=_body_rig(npc)
		if rig!=null:
			rig.update_pose(npc_sprite.modulate)
			npc_sprite.visible=false
			body_clips[key]=rig.pose_snapshot()
		_activities.update_actor(npc,npc_sprite)
		if npc.has_method("activity_state") and str(npc.activity_kind)!="idle": resident_states[key]=npc.activity_state()
		counts.npcs=int(counts.npcs)+1

	counts["bodyClips"]=body_clips
	counts["activities"]=_activities.debug_status()
	counts["residentStates"]=resident_states
	for creature in _creatures:
		if not is_instance_valid(creature): continue
		var species: String=str(creature.get("species"))
		var elapsed: float=float(creature.get("elapsed"))
		var width: float=float(creature.get("width"))
		var data: Dictionary=preload("res://scripts/CreatureAnimator.gd").frame_data(species,elapsed,cos(elapsed*.38),"walk")
		if data.is_empty(): continue
		var size: Vector2=data.size
		_sprite("Animal_"+str(creature.get_instance_id()),_frame(data.texture,data.source),creature.position,Vector2(width,width*size.y/maxf(1,size.x)),0)
		counts.creatures=int(counts.creatures)+1

func _readable_tint(feet: Vector2,height: float) -> Color:
	var weather: Dictionary=EnvironmentState.snapshot()
	var daylight:=clampf((float(weather.get("daylight",.8))-.24)/.76,0,1)
	var tint:=Color(.74,.82,.86).lerp(Color(1,1,.98),daylight)
	var at: Vector3=renderer.map_point(feet,height+30)
	var warmth:=0.0
	for lamp in renderer.get("_lanterns"):
		var reach: float=lamp.omni_range
		var proximity:=clampf(1.0-at.distance_to(lamp.global_position)/reach,0,1)
		warmth=maxf(warmth,proximity*proximity*(1-daylight)*.42)
	return tint.lerp(Color(1,.89,.73),warmth)

func _update_equipment(sprite: Sprite3D,gear: Dictionary,in_water: bool,flip: bool) -> void:
	if not is_instance_valid(_equipment):
		_equipment=preload("res://scripts/CharacterEquipment3D.gd").new()
		add_child(_equipment)
	_equipment.update_attachment(sprite,gear,in_water,flip)

func _body_rig(actor: Node2D) -> Node3D:
	if not actor.has_method("body_animation_state"): return null
	var id:=actor.get_instance_id()
	if _body_rigs.has(id): return _body_rigs[id]
	if not preload("res://scripts/NpcBodyRig3D.gd").IDS.has(str(actor.actor_name)): return null
	var rig:=preload("res://scripts/NpcBodyRig3D.gd").new()
	add_child(rig)
	if not rig.configure(renderer,actor):
		rig.queue_free()
		return null
	_body_rigs[id]=rig
	return rig

func _update_wet_marks() -> void:
	if not "wet_marks" in actor: return
	if not is_instance_valid(_wet_effects):
		_wet_effects=MultiMeshInstance3D.new()
		_wet_effects.name="GroundWetMarks"
		var quad:=QuadMesh.new()
		quad.size=Vector2(10,3.5)
		var instances:=MultiMesh.new()
		instances.transform_format=MultiMesh.TRANSFORM_3D
		instances.use_colors=true
		instances.mesh=quad
		instances.instance_count=24
		_wet_effects.multimesh=instances
		var shader:=Shader.new()
		shader.code="shader_type spatial; render_mode unshaded,cull_disabled,depth_draw_never; void fragment(){float edge=1.0-smoothstep(.6,1.0,length(UV*2.0-1.0));ALBEDO=vec3(.06,.23,.23);ALPHA=COLOR.a*edge;}"
		var material:=ShaderMaterial.new()
		material.shader=shader
		_wet_effects.material_override=material
		_wet_effects.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_wet_effects)
	var marks: Array=actor.get("wet_marks")
	_wet_effects.multimesh.visible_instance_count=mini(24,marks.size())
	var basis:=Basis(Vector3.RIGHT,Vector3(0,-1.0/cos(renderer.TILT),0),Vector3(0,0,-1))
	for index in range(mini(24,marks.size())):
		var mark: Dictionary=marks[index]
		var feet: Vector2=mark.at
		_wet_effects.multimesh.set_instance_transform(index,Transform3D(basis,renderer.map_point(feet,renderer.ground_height(feet)+.6)))
		_wet_effects.multimesh.set_instance_color(index,Color(1,1,1,clampf(1-float(mark.age)/5,0,1)*.45))
