extends SceneTree

var action: GDScript
var story: GDScript
const SIZES := [Vector2i(667,375),Vector2i(844,390)]
const OUTPUT := "res://../artifacts/godot/phase-one-character-closeup/"
const CAPTURE_ONLY := [
	{"id":"prologue","beat":1},{"id":"prologue","beat":4},
	{"id":"prologue","beat":6},{"id":"prologue","beat":9},
	{"id":"first_dive","beat":1},{"id":"first_kedai","beat":1},
	{"id":"first_service","beat":1},{"id":"garden_crisis","beat":2},{"id":"garden_crisis","beat":4},
	{"id":"saras_visit","beat":2},{"id":"cave_warning","beat":2},
	{"id":"earthquake","beat":1},{"id":"boss_intro","beat":1},
	{"id":"boss_phase_two","beat":1},{"id":"victory","beat":1},
	{"id":"victory","beat":3},{"id":"epilogue","beat":2},{"id":"epilogue","beat":4}
]
const WIDE_SHOT_CASES := [
	{"key":"harbor_lurah","kind":"npc","role":"lurah","feet":Vector2(.415,.57),"minimum":78.0,"maximum":110.0},
	{"key":"harbor_child","kind":"child","role":"bagas","feet":Vector2(.070,.57),"minimum":78.0,"maximum":90.0},
	{"key":"capsule_crowd","kind":"npc","role":"ratih","feet":Vector2(.065,.56),"minimum":52.0,"maximum":82.0},
	{"key":"victory_nala","kind":"nala","role":"nala","feet":Vector2(.52,.64),"minimum":85.0,"maximum":110.0},
	{"key":"victory_beno","kind":"npc","role":"beno","feet":Vector2(.40,.62),"minimum":55.0,"maximum":85.0},
	{"key":"victory_child","kind":"child","role":"gito","feet":Vector2(.045,.62),"minimum":55.0,"maximum":90.0},
	{"key":"victory_resident","kind":"resident","role":"darmi","feet":Vector2(.78,.62),"minimum":50.0,"maximum":85.0}
]
const CASES := [
	{"id":"prologue","beat":3,"role":"ranto","kind":"ranto","feet":Vector2(.27,.67),"scale":1.0},
	{"id":"prologue","beat":3,"role":"darmi","kind":"darmi_bust","feet":Vector2(.75,.67),"scale":1.0},
	{"id":"prologue","beat":4,"role":"raka","kind":"npc","feet":Vector2(.64,.59)},
	{"id":"prologue","beat":5,"role":"lurah","kind":"npc","feet":Vector2(.43,.66)},
	{"id":"prologue","beat":6,"role":"beno","kind":"npc","feet":Vector2(.32,.68),"scale":2.53},
	{"id":"prologue","beat":7,"role":"nala","kind":"nala","feet":Vector2(.46,.65),"scale":2.65},
	{"id":"prologue","beat":8,"role":"wira","kind":"npc","feet":Vector2(.36,.68),"scale":2.50},
	{"id":"prologue","beat":9,"role":"wira","kind":"npc","feet":Vector2(.50,.68),"scale":2.55},
	{"id":"prologue","beat":10,"role":"beno","kind":"npc","feet":Vector2(.78,.68),"scale":2.55},
	{"id":"prologue","beat":11,"role":"nala","kind":"nala","feet":Vector2(.22,.68),"scale":2.55},
	{"id":"first_kedai","beat":1,"role":"wira","kind":"npc","feet":Vector2(.23,.68),"scale":2.40},
	{"id":"garden_crisis","beat":1,"role":"darmi","kind":"resident","feet":Vector2(.47,.67)},
	{"id":"garden_crisis","beat":2,"role":"gito","kind":"child","feet":Vector2(.31,.67)},
	{"id":"garden_crisis","beat":3,"role":"guard","kind":"guard","feet":Vector2(.67,.63),"tier":"support"},
	{"id":"garden_crisis","beat":4,"role":"lurah","kind":"npc","feet":Vector2(.44,.66)},
	{"id":"garden_crisis","beat":5,"role":"kinasih","kind":"child","feet":Vector2(.30,.655)},
	{"id":"saras_visit","beat":2,"role":"saras","kind":"npc","feet":Vector2(.68,.68),"scale":2.52},
	{"id":"earthquake","beat":1,"role":"lurah","kind":"npc","feet":Vector2(.25,.67)},
	{"id":"earthquake","beat":2,"role":"raka","kind":"npc","feet":Vector2(.82,.66)},
	{"id":"earthquake","beat":3,"role":"kinasih","kind":"child","feet":Vector2(.42,.64)},
	{"id":"earthquake","beat":4,"role":"saras","kind":"npc","feet":Vector2(.82,.66)},
	{"id":"earthquake","beat":5,"role":"beno","kind":"npc","feet":Vector2(.82,.66)},
	{"id":"earthquake","beat":6,"role":"wira","kind":"npc","feet":Vector2(.82,.66)},
	{"id":"epilogue","beat":1,"role":"raka","kind":"npc","feet":Vector2(.79,.69),"scale":2.66},
	{"id":"epilogue","beat":2,"role":"lurah","kind":"npc","feet":Vector2(.60,.69),"scale":2.52},
	{"id":"epilogue","beat":3,"role":"gito","kind":"child","feet":Vector2(.69,.68),"scale":2.46},
	{"id":"epilogue","beat":4,"role":"saras","kind":"npc","feet":Vector2(.80,.68)},
	{"id":"epilogue","beat":5,"role":"lurah","kind":"npc","feet":Vector2(.80,.68)},
	{"id":"epilogue","beat":6,"role":"beno","kind":"npc","feet":Vector2(.80,.68)},
	{"id":"epilogue","beat":7,"role":"nala","kind":"nala","feet":Vector2(.28,.69)},
	{"id":"epilogue","beat":8,"role":"nala","kind":"nala","feet":Vector2(.28,.69)},
]
const SUPPORT_SCALES := [
	{"kind":"child","role":"bagas","group":"prologue_child"},
	{"kind":"child","role":"kinasih","group":"prologue_child"},
	{"kind":"child","role":"gito","group":"prologue_child"},
	{"kind":"child","role":"cempaka","group":"prologue_child"},
	{"kind":"child","role":"danu","group":"prologue_child"},
	{"kind":"child","role":"bagas","group":"garden_child"},
	{"kind":"child","role":"kinasih","group":"garden_child"},
	{"kind":"child","role":"cempaka","group":"garden_child"},
	{"kind":"child","role":"danu","group":"garden_child"},
	{"kind":"npc","role":"lurah","group":"balai_council"},
	{"kind":"npc","role":"wira","group":"balai_council"},
	{"kind":"npc","role":"saras","group":"balai_council"},
	{"kind":"npc","role":"beno","group":"balai_council"},
	{"kind":"npc","role":"raka","group":"balai_council"},
	{"kind":"npc","role":"ratih","group":"feast_ratih"},
	{"kind":"npc","role":"tedi","group":"feast_tedi"},
	{"kind":"resident","role":"darmi","group":"feast_darmi"},
	{"kind":"resident","role":"ujang","group":"feast_ujang"},
	{"kind":"resident","role":"sari","group":"feast_sari"},
	{"kind":"npc","role":"wira","group":"feast_wira"},
	{"kind":"npc","role":"beno","group":"feast_beno"}
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
		"resident":
			var atlas: Texture2D=action.VILLAGE_PORTRAITS if role=="darmi" else action.VILLAGE_RESIDENTS
			return {"texture":atlas,"region":Rect2i(action.RESIDENT_CELLS[role]),"height":44.0}
		"darmi_bust": return {"texture":action.VILLAGE_PORTRAITS,"region":Rect2i(0,512,512,512),"height":100.0}
		"ranto": return {"texture":action.RANTO_PORTRAIT,"region":Rect2i(0,0,160,160),"height":100.0}
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

func _capture_image() -> Image:
	RenderingServer.force_draw(false)
	return root.get_texture().get_image()

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
	var was_reduced_motion: bool=environment.reduced_motion
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
		var physical_scale:=root.get_final_transform().y.length()
		var screen_unit: float=frame.action_layer._unit(frame.action_layer.size)
		var focal_unit: float=screen_unit*physical_scale
		for adjacent in [[6,7],[7,8]]:
			var previous_pose: Dictionary=frame.action_layer._arrival_pose(frame.action_layer.size,3.0,adjacent[0])
			var next_pose: Dictionary=frame.action_layer._arrival_pose(frame.action_layer.size,0.0,adjacent[1])
			for anchor in ["boat_origin","nala_feet"]:
				var distance: float=(Vector2(previous_pose[anchor])-Vector2(next_pose[anchor])).length()*physical_scale
				assert(distance<=3.0,"Arrival discontinuity %d→%d %s: %.1f px" % [adjacent[0],adjacent[1],anchor,distance])
				checked+=1
		var final_arrival: Dictionary=frame.action_layer._arrival_pose(frame.action_layer.size,3.0,7)
		var dock_foot_x: float=Vector2(final_arrival.nala_feet).x/frame.action_layer.size.x
		assert(dock_foot_x<=.47,"Nala must land on the painted arrival pier, not over the water")
		checked+=1
		for support in SUPPORT_SCALES:
			var support_spec:=_region_for(str(support.kind),str(support.role))
			var support_height:=_ink_height(support_spec,float(action.SUPPORT_STAGE_SCALES[str(support.group)])*physical_scale*frame.action_layer._unit(frame.action_layer.size))
			var council: bool=str(support.group)=="balai_council"
			assert(support_height>=(72.0 if council else 55.0) and support_height<=(95.0 if council else 80.0),"Named support %s/%s ink %.1f px at %s" % [support.group,support.role,support_height,physical])
			checked+=1
		for wide_case in WIDE_SHOT_CASES:
			var wide_spec:=_region_for(str(wide_case.kind),str(wide_case.role))
			var wide_height:=_ink_height(wide_spec,float(action.WIDE_STAGE_SCALES[str(wide_case.key)])*physical_scale*frame.action_layer._unit(frame.action_layer.size))
			assert(wide_height>=float(wide_case.minimum) and wide_height<=float(wide_case.maximum),"Wide shot %s ink %.1f px at %s" % [wide_case.key,wide_height,physical])
			var wide_feet: Vector2=Vector2(wide_case.feet)*Vector2(physical)
			assert(wide_feet.y-wide_height>frame.upper.size.y*physical_scale-5.0,"Wide shot %s head behind title" % wide_case.key)
			assert(wide_feet.y<dialogue.position.y+5.0,"Wide shot %s feet behind dialogue" % wide_case.key)
			checked+=1
		for stage in range(2):
			var child_scale: float=(float(action.WIDE_STAGE_SCALES["harbor_child"]) if stage==0 else 1.72)*focal_unit
			var child_bounds: Array[Vector2]=[]
			for child_key in ["bagas","kinasih","gito"]:
				var cell: Vector2i=action.CHILD_CELLS[child_key]
				var ink: Rect2i=action.CHILD_ATLAS.get_image().get_region(Rect2i(cell.x*96,cell.y*128,96,128)).get_used_rect()
				var center: float=action.HARBOR_CHILD_X[child_bounds.size()]*physical.x
				child_bounds.append(Vector2(center+(-17.0+34.0*ink.position.x/96.0)*child_scale,center+(-17.0+34.0*ink.end.x/96.0)*child_scale))
			for i in range(1,child_bounds.size()):
				assert(child_bounds[i-1].y+4.0<=child_bounds[i].x,"Harbor children need distinct ink silhouettes")
				checked+=1
			assert(child_bounds[0].x>=8.0,"Harbor lesson first child clips the frame edge")
			var lurah_pose: Texture2D=action.LURAH_TEACHING_CLOSE
			var lurah_ink: Rect2i=lurah_pose.get_image().get_used_rect()
			var lurah_size: float=(98.0 if stage==0 else 124.0)*focal_unit
			var left_lurah: float=action.HARBOR_LURAH_X*physical.x+(-.51+float(lurah_ink.position.x)/128.0)*lurah_size
			assert(child_bounds[-1].y+4.0<=left_lurah,"Harbor lesson child and Lurah need ink clearance")
			checked+=2
		for i in range(1,action.CAPSULE_CROWD_X.size()):
			assert(action.CAPSULE_CROWD_X[i]-action.CAPSULE_CROWD_X[i-1]>=.075,"Capsule crowd adults must not collapse into one silhouette")
			checked+=1
		for i in range(1,4):
			assert(action.VICTORY_CHILD_MARKS[i].x-action.VICTORY_CHILD_MARKS[i-1].x>=.08,"Victory dock children need separate silhouettes")
			checked+=1
		var bagas_entering: Dictionary=frame.action_layer._map_bagas_pose(frame.action_layer.size,.05)
		var bagas_settled: Dictionary=frame.action_layer._map_bagas_pose(frame.action_layer.size,1.5)
		assert(bagas_entering.feet.x<bagas_settled.feet.x and is_equal_approx(bagas_settled.feet.y,frame.action_layer.size.y*.68),"Map-room Bagas must enter and settle on the floor")
		assert(is_zero_approx(bagas_settled.stride),"Map-room Bagas must stop stepping")
		var bagas_ink:=_ink_height(_region_for("child","bagas"),1.95*screen_unit*physical_scale)
		assert(bagas_ink>=65.0 and bagas_ink<=100.0,"Map-room Bagas is still miniature or clipped: %.1f px at %s" % [bagas_ink,physical])
		assert(bagas_settled.feet.y-bagas_ink>frame.upper.size.y*physical_scale-5.0 and bagas_settled.feet.y<dialogue.position.y+5.0,"Map-room Bagas must remain between title and dialogue")
		checked+=4
		for guard_index in range(2):
			var approach: Dictionary=frame.action_layer._garden_guard_pose(frame.action_layer.size,.18,guard_index)
			var landed: Dictionary=frame.action_layer._garden_guard_pose(frame.action_layer.size,1.5,guard_index)
			assert(approach.feet.x>landed.feet.x and approach.feet.x-landed.feet.x<24.0*screen_unit,"Garden guard must step into the same grounded mark")
			assert(is_zero_approx(landed.stride) and is_equal_approx(approach.feet.y,landed.feet.y),"Garden guard must settle without vertical drift")
			checked+=1
		var lurah_arriving: Dictionary=frame.action_layer._garden_lurah_pose(frame.action_layer.size,.05)
		var lurah_settled: Dictionary=frame.action_layer._garden_lurah_pose(frame.action_layer.size,1.5)
		assert(lurah_arriving.feet.x<lurah_settled.feet.x and is_equal_approx(lurah_settled.feet.y,frame.action_layer.size.y*.66),"Garden Lurah must enter and land at the foreground floor mark")
		assert(is_zero_approx(lurah_settled.stride),"Garden Lurah must stop stepping when planted")
		checked+=2
		for council_index in range(5):
			var arriving: Dictionary=frame.action_layer._balai_council_pose(frame.action_layer.size,.05,council_index)
			var settled: Dictionary=frame.action_layer._balai_council_pose(frame.action_layer.size,1.8,council_index)
			assert(absf(arriving.feet.x-settled.feet.x)>5.0 and absf(arriving.feet.x-settled.feet.x)<23.0*screen_unit,"Balai actor must join the map without sliding across the stage")
			var floor_y:=.67 if council_index==0 else .64
			assert(is_zero_approx(settled.stride) and is_equal_approx(settled.feet.y,frame.action_layer.size.y*floor_y),"Balai actor must finish at the floor mark")
			checked+=1
		for witness_index in range(2):
			var entering: Dictionary=frame.action_layer._feast_witness_pose(frame.action_layer.size,.05,witness_index)
			var settled_witness: Dictionary=frame.action_layer._feast_witness_pose(frame.action_layer.size,1.8,witness_index)
			assert(absf(entering.feet.x-settled_witness.feet.x)>25.0*screen_unit,"Feast witness must step into a foreground mark")
			assert(is_zero_approx(settled_witness.stride) and is_equal_approx(settled_witness.feet.y,frame.action_layer.size.y*.665),"Feast witness must settle on the painted floor")
			var witness_key: String=["ratih","tedi"][witness_index]
			var witness_height:=_ink_height(_region_for("npc",witness_key),2.45*screen_unit*physical_scale)
			assert(witness_height>=90.0 and witness_height<=110.0,"Feast foreground witness too small or clipped: %s %.1f px at %s" % [witness_key,witness_height,physical])
			assert(settled_witness.feet.y-witness_height>frame.upper.size.y*physical_scale-5.0 and settled_witness.feet.y<dialogue.position.y+5.0,"Feast witness must remain between title and dialogue")
			checked+=4
		for scene_case in CASES:
			var id: String=scene_case.id
			var beat_index: int=scene_case.beat
			if not case_filter.is_empty() and case_filter!="%s:%d" % [id,beat_index]: continue
			var sequence: Dictionary=story.sequence(id)
			var beat: Dictionary=sequence.lines[beat_index-1]
			frame.present(str(sequence.title),beat,beat_index,sequence.lines.size(),id)
			dialogue.present(str(beat.name),str(beat.text),str(beat.get("emotion","neutral")))
			dialogue.text_view.visible_characters=-1
			for second in range(3):
				frame._process(0.5 if second==0 else 0.75)
				for settle in range(3): await process_frame
				if capture:
					var picture: Image=_capture_image()
					var path:=OUTPUT+"%s-%02d-%s-t%d-%dx%d.png" % [id,beat_index,scene_case.role,second,physical.x,physical.y]
					assert(picture.save_png(ProjectSettings.globalize_path(path))==OK,"Cannot save "+path)
					saved+=1
			assert(frame.action_layer.has_directed_action(id,beat_index),"Missing directed action: %s %d" % [id,beat_index])
			var role: String=scene_case.role
			var scale: float=float(scene_case.get("scale",frame.action_layer._focal_scale(role)))
			var ink_height:=_ink_height(_region_for(scene_case.kind,role),scale*focal_unit)
			var foreground: bool=(id=="garden_crisis" and beat_index==4) or (id=="earthquake" and beat_index==1)
			var minimum:=115.0 if foreground else (45.0 if scene_case.get("tier","")=="support" else 90.0)
			var maximum:=145.0 if foreground else (80.0 if scene_case.get("tier","")=="support" else 110.0)
			assert(ink_height>=minimum and ink_height<=maximum,"On-stage %s/%d %s ink %.1f px at %s" % [id,beat_index,role,ink_height,physical])
			var feet: Vector2=Vector2(scene_case.feet)*Vector2(physical)
			assert(feet.y-ink_height>frame.upper.size.y*root.get_final_transform().y.length()-5.0,"Focal head under title bar: %s/%d" % [id,beat_index])
			assert(feet.y<dialogue.position.y+5.0,"Focal feet under dialogue: %s/%d" % [id,beat_index])
			if id=="epilogue" and beat_index==8:
				assert(feet.x+34.0<physical.x*.42,"Final Nala is behind the ending card")
			checked+=1
		var diver: Dictionary={"texture":action.NALA_DIVING["female_nusantara"],"region":Rect2i(2*128+40,14,48,96),"height":72.0}
		var diver_height:=_ink_height(diver,1.45*frame.action_layer._unit(frame.action_layer.size)*physical_scale)
		assert(diver_height>=90.0 and diver_height<=110.0,"First-dive Nala ink %.1f px at %s" % [diver_height,physical])
		if capture:
			for sample in CAPTURE_ONLY:
				var sample_id: String=sample.id
				var sample_beat: int=sample.beat
				var sample_sequence: Dictionary=story.sequence(sample_id)
				var sample_line: Dictionary=sample_sequence.lines[sample_beat-1]
				frame.present(str(sample_sequence.title),sample_line,sample_beat,sample_sequence.lines.size(),sample_id)
				dialogue.present(str(sample_line.name),str(sample_line.text),str(sample_line.get("emotion","neutral")))
				dialogue.text_view.visible_characters=-1
				for second in range(3):
					frame._process(0.5 if second==0 else 0.75)
					for settle in range(3): await process_frame
					var sample_path:=OUTPUT+"%s-%02d-t%d-%dx%d.png" % [sample_id,sample_beat,second,physical.x,physical.y]
					assert(_capture_image().save_png(ProjectSettings.globalize_path(sample_path))==OK,"Cannot save "+sample_path)
					saved+=1
		if capture:
			var sequence: Dictionary=story.sequence("first_dive")
			frame.present(str(sequence.title),sequence.lines[0],1,2,"first_dive")
			dialogue.present("Nala",str(sequence.lines[0].text),"happy")
			dialogue.text_view.visible_characters=-1
			frame._process(1.7)
			for settle in range(3): await process_frame
			var path:=OUTPUT+"first_dive-01-t1-%dx%d.png" % [physical.x,physical.y]
			assert(_capture_image().save_png(ProjectSettings.globalize_path(path))==OK,"Cannot save "+path)
			saved+=1
		for reduced_case in [{"id":"garden_crisis","beat":2},{"id":"epilogue","beat":8}]:
			environment.reduced_motion=true
			var reduced_sequence: Dictionary=story.sequence(str(reduced_case.id))
			var reduced_beat: Dictionary=reduced_sequence.lines[int(reduced_case.beat)-1]
			frame.present(str(reduced_sequence.title),reduced_beat,int(reduced_case.beat),reduced_sequence.lines.size(),str(reduced_case.id))
			dialogue.present(str(reduced_beat.name),str(reduced_beat.text),str(reduced_beat.get("emotion","neutral")))
			dialogue.text_view.visible_characters=-1
			frame._process(1.5)
			for settle in range(3): await process_frame
			assert(frame.action_layer.has_directed_action(str(reduced_case.id),int(reduced_case.beat)),"Reduced-motion action missing")
			if capture:
				var reduced_path:=OUTPUT+"reduced-motion-%s-%02d-%dx%d.png" % [reduced_case.id,reduced_case.beat,physical.x,physical.y]
				assert(_capture_image().save_png(ProjectSettings.globalize_path(reduced_path))==OK,"Cannot save "+reduced_path)
				saved+=1
			checked+=1
		environment.reduced_motion=false
		if capture:
			for appearance in action.NALA_DAILY.keys():
				state.player={"appearance":appearance}
				var ending: Dictionary=story.sequence("epilogue")
				var veranda: Dictionary=ending.lines[6]
				frame.present(str(ending.title),veranda,7,ending.lines.size(),"epilogue")
				dialogue.present(str(veranda.name),str(veranda.text),str(veranda.get("emotion","neutral")))
				dialogue.text_view.visible_characters=-1
				frame._process(1.0)
				for settle in range(3): await process_frame
				var appearance_path:=OUTPUT+"nala-daily-%s-%dx%d.png" % [appearance,physical.x,physical.y]
				assert(_capture_image().save_png(ProjectSettings.globalize_path(appearance_path))==OK,"Cannot save "+appearance_path)
				saved+=1
			state.player={"appearance":"female_nusantara"}
	frame.free()
	dialogue.free()
	state.player=old_player
	environment.reduced_motion=was_reduced_motion
	audio.muted=was_muted
	print("PHASE ONE HERO STAGING PASS: %d focal size/layout checks, %d native captures" % [checked,saved])
	quit()
