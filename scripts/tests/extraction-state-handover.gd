extends SceneTree

var completed := false

func _initialize() -> void:
	call_deferred("run")

func finish(main: Node) -> void:
	await main._extract()
	completed=true

func run() -> void:
	root.get_node("CalendarSync").set_process(false)
	var state:=root.get_node("GameState")
	var api:=root.get_node("ApiClient")
	var original: Script=api.get_script()
	api.set_script(load("res://../scripts/tests/ExtractionControlledApi.gd"))
	state.world={"surfaceSpawn":{"x":1120,"y":1230}}
	for scenario in ["success","refresh_failed","extract_failed","drain_position"]:
		completed=false
		api.refresh_started=false
		api.requests.clear()
		state.player={"id":"extract-fixture","version":6,"coins":200}
		state.dive={"id":"owned-dive","oxygen":100}
		state.surface={"area":"hub","x":1120,"y":1230,"playerVersion":6,"positionAt":100}
		state.homestead={}
		state.calendar={}
		api.extract_result={"ok":true,"player":{"id":"extract-fixture","version":7,"coins":200},"surface":{"area":"hub","x":1485,"y":1290,"playerVersion":7,"positionAt":200}}
		api.refresh_result={"ok":true,"player":api.extract_result.player.duplicate(),"surface":api.extract_result.surface.duplicate(),"dive":{}}
		if scenario=="refresh_failed": api.refresh_result={"ok":false,"error":"controlled disconnected refresh"}
		if scenario=="extract_failed": api.extract_result={"ok":false,"error":"controlled extraction rejection"}
		var main: Node=load("res://../scripts/tests/ExtractionMainFixture.gd").new()
		root.add_child(main)
		main.nala.position=Vector2(1120,470)
		main.nala.velocity=Vector2(30,0)
		main.nala.touch=Vector2.RIGHT
		main.nala.land_path.reset(main.nala.position)
		main.surface_clock=2.0
		if scenario=="drain_position": main.syncing=true
		finish(main)
		if scenario=="drain_position":
			await process_frame
			assert(api.requests.is_empty() and main.network_busy and main.nala.frozen,"An in-flight position save must finish before extraction is requested")
			main.syncing=false
		for frame in range(20):
			if api.refresh_started or completed: break
			await process_frame
		if scenario=="extract_failed":
			assert(completed and not main.network_busy and not main.nala.frozen)
			assert(not state.dive.is_empty() and state.player.version==6)
			assert(main.nala.position==Vector2(1120,470) and main.messages==0)
		else:
			assert(api.refresh_started and not completed,"Refresh must remain deliberately pending")
			assert(main.network_busy and main.nala.frozen,"Periodic saves and player movement remain gated until refresh finishes")
			assert(state.player.version==7 and state.surface.playerVersion==7,"Extract response must publish the new player version atomically")
			assert(state.dive.is_empty() and main.nala.position==Vector2(1485,1290),"No frame may expose a surface player at underwater coordinates")
			assert(main.nala.velocity==Vector2.ZERO and main.nala.touch==Vector2.ZERO)
			assert(main.surface_clock==0 and main.nala.land_path.snapshot(main.nala.position).path.size()<=1)
			api.release_refresh.emit()
			for frame in range(20):
				if completed: break
				await process_frame
			assert(completed and not main.network_busy and main.messages==1)
			assert(state.player.version==7 and state.player.coins==200 and state.dive.is_empty())
			assert(main.nala.position==Vector2(1485,1290),"A failed ancillary refresh must retain the successful authoritative extraction")
		assert(not api.requests.has("/adventure/surface-position"))
		main.free()
	api.set_script(original)
	print("EXTRACTION STATE HANDOVER PASS: actual Main coroutine held at refresh, immediate canonical version/dock, frozen input, clean path, in-flight save ordering, refresh failure and extraction rejection; no network")
	quit()
