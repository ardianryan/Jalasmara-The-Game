extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var motion = load("res://scripts/BossMotion.gd").new()
	var steps = load("res://scripts/NpcSimpleSteps.gd")
	var main_script: Script = load("res://scripts/Main.gd")
	assert(main_script != null,"Main scene must parse with the shared boss controller")
	for name in steps.FILES:
		var idle: Texture2D = steps.frame(name,{"clip":"idle","distance":0.0})
		assert(idle!=null and idle.get_size()==Vector2(64,64),"Missing 64px original-identity frame for "+name)
		var values: Array=[]
		for i in range(4):
			var frame: Texture2D = steps.frame(name,{"clip":"walk","distance":float(i)*6.5})
			assert(frame!=null and frame.get_size()==Vector2(64,64))
			values.append(frame)
		assert(values[0]!=values[1] and values[1]!=values[2] and values[2]!=values[3],"Four poses must be distinct resources")
	motion.advance(0.0,"session",0,6,false,false,false)
	var start: Vector2 = motion.position
	var seen: Array=[]
	var warnings:=0
	var attacks:=0
	for i in range(160):
		motion.advance(0.1,"session",0,6,false,true,false)
		assert(motion.position.distance_to(motion.ANCHOR)<300,"Boss must remain inside the authored arena envelope")
		if motion.telegraph: warnings+=1
		if motion.attack_event: attacks+=1
		seen.append(motion.frame())
	assert(start.distance_to(motion.position)>10 and warnings>0 and attacks>=3,"Boss must patrol and telegraph real attack cycles")
	assert(seen[0]!=seen[7],"Boss parts must advance through different rendered frames")
	var state:=root.get_node("GameState")
	var old_dive: Dictionary=state.dive
	state.dive={"id":"motion-test","mode":"boss","hits":0,"requiredHits":6}
	var main: Node2D=main_script.new()
	var player:=CharacterBody2D.new()
	var status:=Label.new()
	main.add_child(player)
	main.add_child(status)
	main.set("nala",player)
	main.set("status",status)
	main.set("boss_motion",motion)
	assert(main.get("nala")==player,"Test fixture must retain the player reference")
	for i in range(40):
		motion.advance(.1,"session",0,6,false,true,false)
		if motion.attack_event: break
	assert(motion.attack_event)
	main.call("_boss_tick",0.0)
	assert(main.attacks.size()==1 and main.attacks[0].node.position==motion.attack_origin(),"Projectile must originate at the moving trunk")
	for attack in main.attacks: attack.node.free()
	main.attacks.clear()
	state.dive.hits=3
	var before_phase: Vector2=motion.position
	for i in range(32):
		motion.advance(.1,"session",3,6,false,true,false)
		if i==0: assert(motion.position.distance_to(before_phase)<35,"Phase transition cannot teleport the boss")
		if motion.attack_event: break
	assert(motion.attack_event)
	main.call("_boss_tick",0.0)
	assert(main.attacks.size()==2 and main.attacks[0].node.position==motion.attack_origin(),"Second phase must emit from the moving boss")
	main.free()
	state.dive=old_dive
	var frozen: Dictionary=motion.snapshot()
	motion.advance(1.0,"session",0,6,true,true,false)
	assert(motion.position==Vector2(float(frozen.x),float(frozen.y)) and motion.attack_clock==float(frozen.attackClock),"Quiz pause freezes boss patrol and attack timer")
	motion.advance(0.1,"session",3,6,false,true,false)
	assert(motion.phase==2,"Second phase starts after half the recovery hits")
	var second: Vector2=motion.position
	for i in range(50): motion.advance(0.1,"session",3,6,false,true,false)
	assert(motion.position.distance_to(second)>30,"Second phase patrol must visibly move")
	motion.advance(0.1,"session",6,6,false,true,true)
	assert(motion.phase==0 and not motion.telegraph and not motion.attack_event,"Recovered boss must be calm")
	motion.advance(0.0,"new-session",0,6,false,false,false)
	assert(motion.elapsed==0.0 and motion.attack_clock==0.0,"New session resets animation and attack timer")
	print("VILLAGE BOSS MOTION PASS: seven original-portrait short-step sheets, two patrol phases, telegraph, pause, recovery, session reset")
	quit()
