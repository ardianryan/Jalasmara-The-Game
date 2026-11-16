extends SceneTree

var action: GDScript
var story: GDScript
const SIZES := [Vector2i(667,375),Vector2i(844,390)]
const OUTPUT := "res://../artifacts/godot/phase-one-hero-staging/"
const CASES := [
	{"id":"prologue","beat":4,"role":"raka","kind":"npc","feet":Vector2(.60,.50)},
	{"id":"prologue","beat":5,"role":"lurah","kind":"npc","feet":Vector2(.20,.54)},
	{"id":"garden_crisis","beat":1,"role":"darmi","kind":"resident","feet":Vector2(.47,.63)},
	{"id":"garden_crisis","beat":2,"role":"gito","kind":"child","feet":Vector2(.31,.63)},
	{"id":"garden_crisis","beat":3,"role":"guard","kind":"guard","feet":Vector2(.67,.63)},
	{"id":"garden_crisis","beat":4,"role":"lurah","kind":"npc","feet":Vector2(.47,.63)},
	{"id":"garden_crisis","beat":5,"role":"kinasih","kind":"child","feet":Vector2(.30,.63)},
	{"id":"earthquake","beat":1,"role":"lurah","kind":"npc","feet":Vector2(.31,.55)},
	{"id":"earthquake","beat":2,"role":"raka","kind":"npc","feet":Vector2(.82,.63)},
	{"id":"earthquake","beat":3,"role":"kinasih","kind":"child","feet":Vector2(.42,.59)},
	{"id":"earthquake","beat":4,"role":"saras","kind":"npc","feet":Vector2(.82,.63)},
	{"id":"earthquake","beat":5,"role":"beno","kind":"npc","feet":Vector2(.82,.63)},
	{"id":"earthquake","beat":6,"role":"wira","kind":"npc","feet":Vector2(.82,.63)},
	{"id":"epilogue","beat":7,"role":"nala","kind":"nala","feet":Vector2(.28,.69)},
	{"id":"epilogue","beat":8,"role":"nala","kind":"nala","feet":Vector2(.28,.69)},
]

func _initialize() -> void:
	_run.call_deferred()

func _region_for(kind: String, role: String) -> Dictionary:
	match kind:
		"npc": return {"texture": action.NPC_FACES[role],"region": Rect2i(0,0,64,64),"height":40.0}
		"guard": return {"texture": action.NPC_FACES["raka"],"region": Rect2i(0,0,64,64),"height":48.0}
		"child":
			var cell: Vector2i=action.CHILD_CELLS[role]
			return {"texture":action.CHILD_ATLAS,"region":Rect2i(cell.x*96,cell.y*128,96,128),"height":44.0}
		"resident": return {"texture":action.VILLAGE_PORTRAITS,"region":Rect2i(0,627,627,627),"height":44.0}
		"nala": return {"texture":action.NALA_DAILY["female_nusantara"],"region":Rect2i(2*128+40,0,48,128),"height":58.0}
	return {}

func _ink_height(spec: Dictionary, scale: float) -> float:
	var region: Rect2i=spec.region
	var image: Image=(spec.texture as Texture2D).get_image().get_region(region)
	return float(image.get_used_rect().size.y)/float(region.size.y)*float(spec.height)*scale

func _assert_nala_crop(atlas: Texture2D, crop: Rect2i, label: String) -> void:
	for direction in [0,2]:
		var full: Image=atlas.get_image().get_region(Rect2i(direction*128,0,128,128))
		var ink: Rect2i=full.get_used_rect()
		assert(crop.encloses(ink),"Nala atlas crop clips %s direction %d: %s" % [label,direction,ink])

func _run() -> void:
	var capture:=OS.get_environment("CINEMATIC_CAPTURE")=="1"
	var case_filter:=OS.get_environment("CINEMATIC_CASE_FILTER")
	assert(not capture or DisplayServer.get_name()!="headless","Native renderer required for hero staging capture")
	if capture: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	action=load("res://scripts/CinematicActionLayer.gd")
	story=load("res://scripts/PhaseOneCutscenes.gd")
	for appearance in action.NALA_DIVING.keys():
		_assert_nala_crop(action.NALA_DIVING[appearance],Rect2i(40,14,48,96),"diving "+appearance)
		_assert_nala_crop(action.NALA_DAILY[appearance],Rect2i(40,0,48,128),"daily "+appearance)
	var environment: Node=root.get_node("EnvironmentState")
	var audio: Node=root.get_node("AudioManager")
	var state: Node=root.get_node("GameState")
	var was_muted: bool=audio.muted
	var old_player: Dictionary=state.player.duplicate(true)
	audio.muted=true
	state.player={"appearance":"female_nusantara"}
	environment.reduced_motion=false
	var frame: Control=load("res://scripts/CutsceneFrame.gd").new()
	var dialogue: Control=load("res://scripts/DialoguePresenter.gd").new()
	root.add_child(frame)
	root.add_child(dialogue)
	var checked:=0
	var saved:=0
	for physical in SIZES:
		root.size=physical
		for settle in range(4): await process_frame
		for scene_case in CASES:
			var id: String=scene_case.id
			var beat_index: int=scene_case.beat
			if not case_filter.is_empty() and case_filter!="%s:%d" % [id,beat_index]: continue
			var sequence: Dictionary=story.sequence(id)
			var beat: Dictionary=sequence.lines[beat_index-1]
			frame.present(str(sequence.title),beat,beat_index,sequence.lines.size(),id)
			dialogue.present(str(beat.name),str(beat.text),str(beat.get("emotion","neutral")))
			dialogue.text_view.visible_characters=-1
			frame._process(2.0)
			for settle in range(3): await process_frame
			assert(frame.action_layer.has_directed_action(id,beat_index),"Missing directed action: %s %d" % [id,beat_index])
			var role: String=scene_case.role
			var scale: float=frame.action_layer._focal_scale(role)
			var screen_unit: float=frame.action_layer._unit(frame.action_layer.size)*root.get_final_transform().y.length()
			var ink_height:=_ink_height(_region_for(scene_case.kind,role),scale*screen_unit)
			assert(ink_height>=59.0 and ink_height<=80.0,"Focal figure %s/%d %s ink %.1f px at %s" % [id,beat_index,role,ink_height,physical])
			var feet: Vector2=Vector2(scene_case.feet)*Vector2(physical)
			assert(feet.y-ink_height>frame.upper.size.y*root.get_final_transform().y.length()-5.0,"Focal head under title bar: %s/%d" % [id,beat_index])
			assert(feet.y<dialogue.position.y+5.0,"Focal feet under dialogue: %s/%d" % [id,beat_index])
			if id=="epilogue" and beat_index==8:
				assert(feet.x+30.0<physical.x*.42,"Final Nala is behind the ending card")
			if capture:
				var picture: Image=root.get_texture().get_image()
				var path:=OUTPUT+"%s-%02d-%dx%d.png" % [id,beat_index,physical.x,physical.y]
				assert(picture.save_png(ProjectSettings.globalize_path(path))==OK,"Cannot save "+path)
				saved+=1
			checked+=1
		var diver: Dictionary={"texture":action.NALA_DIVING["female_nusantara"],"region":Rect2i(2*128+40,14,48,96),"height":72.0}
		var diver_height:=_ink_height(diver,frame.action_layer._unit(frame.action_layer.size)*root.get_final_transform().y.length())
		assert(diver_height>=60.0 and diver_height<=80.0,"First-dive Nala ink %.1f px at %s" % [diver_height,physical])
		if capture:
			var sequence: Dictionary=story.sequence("first_dive")
			frame.present(str(sequence.title),sequence.lines[0],1,2,"first_dive")
			dialogue.present("Nala",str(sequence.lines[0].text),"happy")
			dialogue.text_view.visible_characters=-1
			frame._process(1.7)
			for settle in range(3): await process_frame
			var path:=OUTPUT+"first_dive-01-%dx%d.png" % [physical.x,physical.y]
			assert(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))==OK,"Cannot save "+path)
			saved+=1
	frame.free()
	dialogue.free()
	state.player=old_player
	environment.reduced_motion=false
	audio.muted=was_muted
	print("PHASE ONE HERO STAGING PASS: %d focal size/layout checks, %d native captures" % [checked,saved])
	quit()
