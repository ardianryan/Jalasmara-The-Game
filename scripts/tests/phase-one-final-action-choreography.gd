extends SceneTree

const OUTPUT := "res://../artifacts/godot/phase-one-final-action/"
const SIZES := [Vector2i(667,375),Vector2i(844,390)]
const CASES := [
	{"id":"first_service","beat":1,"times":[.12,1.7],"backdrop":"kedai-interior"},
	{"id":"first_service","beat":1,"times":[1.7],"backdrop":"kedai-interior","customer":"Bu Darmi","label":"first_service_darmi"},
	{"id":"garden_crisis","beat":2,"times":[.12,.95,1.65],"backdrop":"garden-crisis"},
	{"id":"garden_crisis","beat":3,"times":[1.7],"backdrop":"garden-crisis"},
	{"id":"garden_crisis","beat":4,"times":[.18,.92,1.55],"backdrop":"garden-crisis"},
	{"id":"saras_visit","beat":2,"times":[1.7],"backdrop":"kedai-interior"},
	{"id":"boss_intro","beat":2,"times":[1.7],"backdrop":"tamansari"},
	{"id":"boss_phase_two","beat":1,"times":[.12,.95,1.8],"backdrop":"tamansari-neutralized"},
	{"id":"victory","beat":1,"times":[1.7],"backdrop":"tamansari-neutralized"},
	{"id":"victory","beat":2,"times":[.12,.95,2.2],"backdrop":"tamansari-sealed"},
	{"id":"victory","beat":3,"times":[.12,1.4,3.1],"backdrop":"prologue"},
	{"id":"epilogue","beat":1,"times":[1.7],"backdrop":"kedai-interior"},
	{"id":"epilogue","beat":2,"times":[1.7],"backdrop":"kedai-interior"},
	{"id":"epilogue","beat":4,"times":[.12,1.1,2.2],"backdrop":"griya-map-room"},
]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var capture:=OS.get_environment("CINEMATIC_CAPTURE")=="1"
	var case_filter:=OS.get_environment("CINEMATIC_CASE_FILTER")
	assert(not capture or DisplayServer.get_name()!="headless","Native renderer required for action capture")
	if capture: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var story=load("res://scripts/PhaseOneCutscenes.gd")
	var environment: Node=root.get_node("EnvironmentState")
	var audio: Node=root.get_node("AudioManager")
	var state: Node=root.get_node("GameState")
	var was_muted: bool=audio.muted
	var prior_shift: Dictionary=state.shift.duplicate(true)
	audio.muted=true
	state.player={"appearance":"female_nusantara"}
	environment.reduced_motion=false
	var frame: Control=load("res://scripts/CutsceneFrame.gd").new()
	var dialogue: Control=load("res://scripts/DialoguePresenter.gd").new()
	root.add_child(frame)
	root.add_child(dialogue)
	state.shift={"customers":[{"id":"daun_kuning","customer":"Bu Darmi"}]}
	frame.action_layer.motif_speaker=""
	assert(frame.action_layer._tasting_subject()=="Bu Darmi","Legacy first service would show Ranto's face")
	frame.action_layer.motif_speaker="Pelanggan Kedai"
	assert(frame.action_layer._tasting_subject()=="Pelanggan Kedai","Generic customer identity was ignored")
	frame.action_layer.motif_speaker=""
	state.shift={}
	assert(frame.action_layer._tasting_subject()=="Pak Ranto","Default first service lost Ranto")
	assert(frame.action_layer.has_directed_action("prologue",6),"Griya arrival lost after dialogue expansion")
	assert(frame.action_layer.has_directed_action("prologue",8),"Wira arrival lost after dialogue expansion")
	assert(frame.action_layer.has_directed_action("garden_crisis",3),"Guard challenge lost after dialogue expansion")
	assert(frame.action_layer.has_directed_action("garden_crisis",4),"Lurah staff beat lost after dialogue expansion")
	var count:=0
	var saved:=0
	for physical in SIZES:
		root.size=physical
		for settle in range(4): await process_frame
		for scene_case in CASES:
			var id: String=scene_case.id
			var beat_index: int=scene_case.beat
			if not case_filter.is_empty() and case_filter!="%s:%d" % [id,beat_index]: continue
			var customer: String=str(scene_case.get("customer","Pak Ranto"))
			state.shift={"customers":[{"id":"daun_kuning","customer":customer}]} if scene_case.has("customer") else {}
			var sequence: Dictionary=story.sequence(id,customer)
			assert(beat_index<=sequence.lines.size(),"Missing story beat: %s %d" % [id,beat_index])
			var beat: Dictionary=sequence.lines[beat_index-1]
			for sample_index in range(scene_case.times.size()):
				frame.present(str(sequence.title),beat,beat_index,sequence.lines.size(),id)
				if scene_case.has("customer"):
					assert(frame.action_layer._tasting_subject()==customer,"Cut-in customer disagrees with spoken customer")
				dialogue.present(str(beat.name),str(beat.text),str(beat.get("emotion","neutral")))
				dialogue.text_view.visible_characters=-1
				var seconds: float=scene_case.times[sample_index]
				frame._process(seconds)
				for settle in range(3): await process_frame
				assert(frame.action_layer.has_directed_action(id,beat_index),"Missing action: %s %d" % [id,beat_index])
				assert(frame.backdrop_key==scene_case.backdrop,"Wrong plate: %s %d" % [id,beat_index])
				if id in ["boss_phase_two","victory"]:
					var at: Vector2=frame.action_layer._pipe_outlet(Vector2(physical),id=="victory" and beat_index==2)
					assert(at.x>frame.size.x*.56 and at.x<frame.size.x*.83,"Pipe X detached: %s at %s, frame %s" % [at,physical,frame.size])
					assert(at.y>frame.size.y*.10 and at.y<frame.size.y*.57,"Pipe Y detached: %s at %s, frame %s" % [at,physical,frame.size])
				if id in ["boss_intro","boss_phase_two","victory"] and beat_index<=2:
					var eye: Vector2=frame.action_layer._boss_sprite_point(frame.size,Vector2(57,65))
					assert(frame.boss_art.get_rect().grow(1).has_point(eye),"Boss eye overlay detached: %s %d" % [id,beat_index])
				if capture and (physical.x==667 or sample_index==scene_case.times.size()-1):
					var picture: Image=root.get_texture().get_image()
					assert(picture.get_width()==physical.x and picture.get_height()==physical.y,"Capture dimensions drifted")
					var case_label: String=str(scene_case.get("label",id))
					var path: String=OUTPUT+"%s-%02d-t%02d-%dx%d.png" % [case_label,beat_index,sample_index,physical.x,physical.y]
					assert(picture.save_png(ProjectSettings.globalize_path(path))==OK,"Cannot save "+path)
					saved+=1
				count+=1
	environment.reduced_motion=true
	var old_eye: Vector2=frame.action_layer._boss_sprite_point(frame.size,Vector2(57,65))
	frame.boss_art.anchor_left=.24
	frame.boss_art.anchor_right=.66
	for settle in range(2): await process_frame
	var shifted_eye: Vector2=frame.action_layer._boss_sprite_point(frame.size,Vector2(57,65))
	assert(shifted_eye.x<old_eye.x-frame.size.x*.10,"Eye overlay does not follow Mina's approach")
	var calm: Dictionary=story.sequence("victory")
	frame.present(str(calm.title),calm.lines[1],2,calm.lines.size(),"victory")
	frame._process(1.0)
	assert(frame.action_layer.elapsed==3.0,"Reduced-motion action did not settle")
	frame.free()
	dialogue.free()
	environment.reduced_motion=false
	state.shift=prior_shift
	audio.muted=was_muted
	print("PHASE ONE FINAL ACTION PASS: %d samples, %d native captures" % [count,saved])
	quit()
