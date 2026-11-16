extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.size=Vector2i(960,540)
	var story = load("res://scripts/PhaseOneCutscenes.gd")
	var frame_script = load("res://scripts/CutsceneFrame.gd")
	assert(story!=null and frame_script!=null)
	var ids := ["prologue","first_dive","first_kedai","first_service","garden_crisis","saras_visit","cave_warning","earthquake","boss_intro","boss_phase_two","victory","epilogue"]
	for id in ids:
		var sequence:Dictionary=story.sequence(id)
		assert(not sequence.is_empty() and sequence.lines.size()>=2,"Missing Phase 1 cinematic: "+id)
		for beat in sequence.lines:
			assert(not str(beat.get("shot","")).is_empty())
			assert(not str(beat.get("name","")).is_empty())
			assert(not str(beat.get("text","")).is_empty())
	assert(story.sequence("unknown").is_empty())
	assert(story.sequence("first_kedai").lines[0].name=="Pak Ranto")
	assert(story.sequence("first_service").lines[0].name=="Pak Ranto")
	assert(str(story.sequence("first_service").lines[0].text).contains("Klorofil"))
	assert(story.sequence("first_kedai","Bu Darmi").lines[0].name=="Bu Darmi")
	assert(story.sequence("first_service","Bu Darmi").lines[0].name=="Bu Darmi")
	assert(story.sequence("first_service","Pelanggan Kedai").lines[0].name=="Pelanggan Kedai")
	assert(story.first_customer_from_shift({})=="Pak Ranto")
	assert(story.first_customer_from_shift({"id":"legacy"})=="Pelanggan Kedai")
	assert(story.first_customer_from_shift({"customers":[{"id":"daun_kuning","customer":"Bu Darmi"}]})=="Bu Darmi")
	assert(story.first_customer_from_shift({"customers":[{"id":"daun_kuning","customer":"Pak Ranto"}]})=="Pak Ranto")
	assert(str(story.sequence("first_kedai","Bu Darmi").lines[1].text).contains("Darmi"))
	assert(str(story.sequence("garden_crisis").lines[2].text).contains("papan balai"))
	assert(not str(story.sequence("garden_crisis").lines[2].text).contains("kubuka kembali"))
	assert(str(story.sequence("earthquake").lines[0].shot).contains("setelah giliran kedai ketiga"))
	assert(str(story.sequence("boss_phase_two").lines[0].shot).contains("Tiga resonansi pertama"))
	assert(story.sequence("epilogue").lines[3].bgm=="coastal_dusk")
	var player := {"id":"fixture","progress":{"tutorial":false,"day":1,"stage":"dive"}}
	assert(story.eligible_on_load(player,{}, {})=="prologue")
	player.progress.tutorial=true
	assert(story.eligible_on_load(player,{}, {}).is_empty())
	player.progress.day=2
	assert(story.eligible_on_load(player,{}, {})=="garden_crisis")
	player.progress.day=3
	player.progress.stage="boss"
	assert(story.eligible_on_load(player,{}, {})=="earthquake")
	assert(story.eligible_on_load(player,{"id":"dive"},{}).is_empty())
	var boss_dive := {"id":"boss-dive","mode":"boss","hits":0,"requiredHits":6,"oxygen":40.0}
	assert(story.eligible_on_load(player,boss_dive,{})=="boss_intro")
	boss_dive.hits=2
	assert(story.eligible_on_load(player,boss_dive,{}).is_empty())
	boss_dive.hits=3
	assert(story.eligible_on_load(player,boss_dive,{})=="boss_phase_two")
	boss_dive.hits=5
	assert(story.eligible_on_load(player,boss_dive,{})=="boss_phase_two")
	boss_dive.challenge={"id":"unfinished-quiz"}
	assert(story.eligible_on_load(player,boss_dive,{}).is_empty())
	boss_dive.erase("challenge")
	boss_dive.hits=6
	assert(story.eligible_on_load(player,boss_dive,{}).is_empty())
	assert(story.ready_to_extract_on_load(boss_dive))
	boss_dive.oxygen=0.0
	assert(not story.ready_to_extract_on_load(boss_dive))
	boss_dive.oxygen=40.0
	boss_dive.mode="dive"
	assert(not story.ready_to_extract_on_load(boss_dive))
	player.progress.stage="done"
	assert(story.eligible_on_load(player,{}, {})=="victory")
	assert(story.eligible_on_load(player,{}, {"id":"night-shift"}).is_empty())
	var frame:Control=frame_script.new()
	root.add_child(frame)
	var environment := root.get_node("EnvironmentState")
	environment.set("reduced_motion", false)
	await process_frame
	frame.present("Gajah Mina",story.sequence("boss_intro").lines[0],1,3,"boss_intro")
	assert(frame.visible and frame.boss_art.visible)
	assert(frame.backdrop_key=="tamansari" and frame.backdrop!=null)
	assert(frame.living_plate.visible and frame.living_material.get_shader_parameter("plate")==2)
	assert(frame.progress_label.text=="1 / 3")
	frame.present("Prolog",story.sequence("prologue").lines[0],1,10,"prologue")
	assert(frame.backdrop_key=="prologue" and frame.backdrop!=null)
	assert(frame.living_material.get_shader_parameter("plate")==1)
	frame.present("Kepulangan",story.sequence("prologue").lines[5],6,10,"prologue")
	assert(frame.action_layer.motif_id=="prologue" and frame.action_layer.motif_beat==6)
	frame.present("Pipa retak",story.sequence("boss_phase_two").lines[0],1,2,"boss_phase_two")
	assert(frame.action_layer.motif_id=="boss_phase_two" and frame.action_layer.motif_beat==1)
	assert(frame.backdrop_key=="tamansari-neutralized" and frame.backdrop!=null and frame.boss_art.visible)
	frame.present("Pipa tersumbat",story.sequence("victory").lines[1],2,3,"victory")
	assert(frame.backdrop_key=="tamansari-sealed" and frame.backdrop!=null and frame.boss_art.visible)
	frame.present("Cahaya naik",story.sequence("victory").lines[2],3,3,"victory")
	assert(frame.backdrop_key=="prologue" and frame.backdrop!=null and not frame.boss_art.visible)
	assert(frame.living_material.get_shader_parameter("plate")==0)
	frame.present("Epilog",story.sequence("epilogue").lines[0],1,8,"epilogue")
	assert(frame.backdrop_key=="kedai-interior" and frame.backdrop!=null)
	assert(frame.living_material.get_shader_parameter("plate")==4)
	frame.present("Ruang peta",story.sequence("epilogue").lines[3],4,8,"epilogue")
	assert(frame.backdrop_key=="griya-map-room" and frame.backdrop!=null)
	assert(frame.living_material.get_shader_parameter("plate")==8)
	frame.present("Beranda",story.sequence("epilogue").lines[6],7,8,"epilogue")
	assert(frame.backdrop_key=="epilogue" and frame.backdrop!=null)
	assert(frame.living_material.get_shader_parameter("plate")==3)
	environment.set("reduced_motion", true)
	frame._process(0.1)
	assert(not frame.living_plate.visible)
	environment.set("reduced_motion", false)
	frame.present("Kebun",story.sequence("garden_crisis").lines[0],1,4,"garden_crisis")
	assert(not frame.boss_art.visible and frame.backdrop_key=="garden-crisis" and frame.living_plate.visible)
	assert(frame.living_material.get_shader_parameter("plate")==5)
	frame.present("Terjun",story.sequence("first_dive").lines[0],1,2,"first_dive")
	assert(frame.backdrop_key=="segaran-entry" and frame.backdrop!=null)
	assert(frame.living_material.get_shader_parameter("plate")==9)
	frame.present("Segaran",story.sequence("first_dive").lines[1],2,2,"first_dive")
	assert(frame.backdrop_key=="segaran-underwater" and frame.backdrop!=null)
	assert(frame.living_material.get_shader_parameter("plate")==10)
	frame.free()
	print("PHASE ONE CUTSCENES PASS: twelve beats, progression gates and cinematic frame")
	quit()
