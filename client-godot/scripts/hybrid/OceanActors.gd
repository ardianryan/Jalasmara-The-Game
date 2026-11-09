extends Node3D

const Animator = preload("res://scripts/CreatureAnimator.gd")
const Wildlife = preload("res://scripts/Wildlife.gd")
var source: Node
var sprites: Dictionary = {}
var atlas_frames: Dictionary = {}
var _active: Dictionary = {}
var _session := ""
var debug_counts: Dictionary = {}
var _equipment: Node3D

func configure(main: Node) -> void:
	source = main

func _process(delta: float) -> void:
	update_actors(delta)

func update_actors(_delta: float = 0.0) -> void:
	if not is_instance_valid(source) or GameState.dive.is_empty():
		visible = false
		return
	visible = true
	var entities: Node = source.get("entities")
	var nala: Node2D = source.get("nala")
	if not is_instance_valid(entities) or not is_instance_valid(nala):
		return
	var session := str(GameState.dive.get("id",""))
	if _session != session:
		_clear()
		_session = session
	_active.clear()
	debug_counts = {"player":0,"targets":0,"wildlife":0,"props":0,"boss":0}
	_mirror_player(nala)
	_mirror_targets(entities,nala.position)
	_mirror_wildlife(entities,nala.position)
	_mirror_props(entities,nala.position)
	for key in sprites:
		var sprite: Sprite3D = sprites[key]
		sprite.visible = _active.has(key)

func _clear() -> void:
	for sprite in sprites.values():
		if is_instance_valid(sprite):
			sprite.queue_free()
	sprites.clear()
	atlas_frames.clear()

func _frame(texture: Texture2D, rectangle: Rect2) -> Texture2D:
	var key := str(texture.get_instance_id())+":"+str(rectangle)
	if not atlas_frames.has(key):
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = rectangle
		frame.filter_clip = true
		atlas_frames[key] = frame
	return atlas_frames[key]

func _sprite(key: String, texture: Texture2D, at: Vector2, dimensions: Vector2, depth: float, tint := Color.WHITE) -> Sprite3D:
	var sprite: Sprite3D = sprites.get(key)
	if not is_instance_valid(sprite):
		sprite = Sprite3D.new()
		sprite.name = "Actor_"+key.validate_node_name()
		sprite.pixel_size = 1.0
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.shaded = true
		sprite.transparent = true
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.alpha_scissor_threshold = 0.5
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sprite)
		sprites[key] = sprite
	sprite.texture = texture
	sprite.position = Vector3(at.x,-at.y,depth)
	sprite.scale = Vector3(dimensions.x/maxf(texture.get_width(),1),dimensions.y/maxf(texture.get_height(),1),1)
	sprite.modulate = tint
	sprite.visible = true
	_active[key] = true
	return sprite

func _mirror_player(nala: Node2D) -> void:
	var visual: Sprite2D = nala.get("swim_sprite")
	if not is_instance_valid(visual) or visual.texture == null:
		return
	var cell := visual.texture.get_size()/Vector2(visual.hframes,visual.vframes)
	var rectangle := Rect2(Vector2(visual.frame%visual.hframes,floori(float(visual.frame)/visual.hframes))*cell,cell)
	var sprite := _sprite("player",_frame(visual.texture,rectangle),nala.position+visual.position,cell*visual.scale.abs(),12)
	sprite.flip_h = visual.flip_h
	sprite.flip_v = visual.flip_v
	if not is_instance_valid(_equipment):
		_equipment=preload("res://scripts/CharacterEquipment3D.gd").new()
		add_child(_equipment)
	var gear: Dictionary=visual.get_equipment_state() if visual.has_method("get_equipment_state") else {}
	_equipment.update_attachment(sprite,gear,true,visual.flip_h)
	debug_counts.player = 1

func _mirror_targets(entities: Node, origin: Vector2) -> void:
	var boss_mode := str(GameState.dive.get("mode","")) == "boss"
	var required := ceili(float(GameState.dive.get("requiredHits",6))/2.0)
	var hits := int(GameState.dive.get("hits",0))
	var index := 0
	for target in GameState.dive.get("targets",[]):
		var available: bool = not boss_mode or ((index<required)==(hits<required))
		index += 1
		if bool(target.get("caught",false)) or not available:
			continue
		var at: Vector2 = entities.target_position(target)
		if at.distance_to(origin)>1000:
			continue
		var id := str(target.id)
		if boss_mode:
			var texture := _memory_texture()
			_sprite("target:"+id,texture,at,Vector2(28,28),14,Color("a2d8ca"))
		else:
			var species: int = entities._target_species(target)
			var previous: Vector2 = entities.target_position(target,-0.04)
			var facing := 1.0 if at.x>=previous.x else -1.0
			var phase := float(posmod(hash(id),1000))/100.0
			_creature("target:"+id,species,at,58.0 if species==0 else 65.0,float(entities.elapsed)+phase/7.0,facing,12,Color.WHITE)
		debug_counts.targets += 1

func _mirror_wildlife(entities: Node, origin: Vector2) -> void:
	var wildlife: Node = entities.get("wildlife")
	if not is_instance_valid(wildlife):
		return
	var index := 0
	for creature in wildlife.creatures:
		var at: Vector2 = creature.position
		var key := "wildlife:"+str(index)
		index += 1
		if at.distance_to(origin)>1100:
			continue
		_creature(key,int(creature.species),at,float(creature.size),float(creature.get("animation_time", wildlife.elapsed)),float(creature.facing),-4,Color(0.68,0.86,0.87,0.90),str(creature.get("animation_state","walk")))
		debug_counts.wildlife += 1

func _creature(key: String, species: int, at: Vector2, width: float, seconds: float, facing: float, depth: float, tint: Color, state: String = "walk") -> void:
	var id: String = Wildlife._generated_species(species)
	var data: Dictionary = Animator.frame_data(id,seconds,facing,state)
	if data.is_empty():
		return
	var size: Vector2 = data.size
	var color := tint*Color(1,0.91,0.78) if species==2 else tint
	_sprite(key,_frame(data.texture,data.source),at,Vector2(width,width*size.y/maxf(size.x,1)),depth,color)

func _prop(entities: Node, key: String, index: int, at: Vector2, dimensions: Vector2, tint := Color.WHITE) -> void:
	var atlas: Texture2D = entities.get("props_atlas")
	if atlas == null:
		return
	var cell := atlas.get_size()/Vector2(4,2)
	var rectangle := Rect2(Vector2(index%4,floori(float(index)/4.0))*cell,cell)
	_sprite(key,_frame(atlas,rectangle),at,dimensions,10,tint)
	debug_counts.props += 1

func _mirror_props(entities: Node, origin: Vector2) -> void:
	for item in GameState.world.get("landmarks",[]):
		var at := Vector2(float(item.x),float(item.y))
		if at.distance_to(origin)>1100: continue
		var variation := float(posmod(hash(str(item.id)),3))
		var found: bool = GameState.adventure.get("discoveries",[]).has(item.id)
		_prop(entities,"landmark:"+str(item.id),0,at+Vector2(0,18),Vector2(91+variation*8,110+variation*6),Color(0.87,0.98,0.91) if found else Color.WHITE)
	for item in GameState.world.get("puzzles",[]):
		var at := Vector2(float(item.x),float(item.y))
		if at.distance_to(origin)>1100: continue
		var kind := str(item.get("kind","light"))
		var index := 1 if kind=="valve" else 2 if kind=="filter" else 3
		var dimensions := Vector2(140,135) if index==1 else Vector2(127,162) if index==2 else Vector2(152,139)
		var done: bool = GameState.adventure.get("puzzles",[]).has(item.id)
		_prop(entities,"puzzle:"+str(item.id),index,at+Vector2(0,18),dimensions,Color(0.83,1.0,0.89) if done else Color.WHITE)
	for item in GameState.world.get("caches",[]):
		var at := Vector2(float(item.x),float(item.y))
		if at.distance_to(origin)>1100: continue
		var opened: bool = GameState.adventure.get("discoveries",[]).has(item.id)
		_prop(entities,"cache:"+str(item.id),7,at+Vector2(0,12),Vector2(95,91),Color(0.8,0.87,0.84,0.55) if opened else Color.WHITE)
	for item in GameState.world.get("hazards",[]):
		var at := Vector2(float(item.x),float(item.y))
		if at.distance_to(origin)>1100: continue
		var urchin := str(item.kind)=="urchin"
		_prop(entities,"hazard:"+str(item.id),4 if urchin else 5,at if urchin else at+Vector2(-13,12),Vector2.ONE*float(item.radius)*2.0 if urchin else Vector2(122,132))
	if int(GameState.player.get("progress",{}).get("day",1))>=3:
		var at := Vector2(3820,3140)
		var boss: Texture2D = entities.get("boss_texture")
		if at.distance_to(origin)<1300 and boss != null:
			_sprite("boss",boss,at-Vector2(0,5),Vector2(420,280),10,Color(1,1,1,0.6) if bool(GameState.player.get("progress",{}).get("bossDefeated",false)) else Color.WHITE)
			debug_counts.boss = 1

func _memory_texture() -> Texture2D:
	var path := "res://resources/art/pixelbolt/memory-spark.png"
	if ResourceLoader.exists(path):
		var texture: Texture2D = load(path)
		return _frame(texture,Rect2(64,0,32,32))
	return preload("res://scripts/ItemIcons.gd").texture("cache")
