extends SceneTree

class HomeHost extends Node:
	func set_interaction_modal(_active: bool) -> void: pass

func _initialize() -> void: run.call_deferred()
func settle() -> void:
	for frame in range(4): await process_frame
func button(ui,prefix: String) -> Button:
	for control in ui.content.get_children():
		if control is Button and control.text.begins_with(prefix): return control
	return null
func run() -> void:
	root.get_node("CalendarSync").set_process(false)
	var state:=root.get_node("GameState")
	state.player={"coins":25,"inventory":[],"progress":{"day":2}}
	state.calendar={"calendarDay":2}
	state.homestead_definitions={"market":{"price":20,"dailyStock":6},"crops":[{"id":"kangkung","seedId":"benih_kangkung","name":"Kangkung kebun","growthDays":3,"price":20},{"id":"jahe","seedId":"benih_jahe","name":"Jahe pesisir","growthDays":4,"price":30}],"servings":{"kangkung":{"itemId":"kangkung","name":"Kangkung kebun"},"jahe":{"itemId":"jahe","name":"Jahe pesisir"},"ikan_seruni":{"itemId":"ikan_seruni","name":"Ikan seruni budidaya"}},"fishPen":{"speciesId":"reef_seruni","parentCount":2,"growthDays":2,"feedCost":2,"capacity":5,"unlockStoryDay":2}}
	state.homestead={"permit":true,"seeds":{"benih_kangkung":0,"benih_jahe":1},"produce":{"kangkung":1,"jahe":2,"ikan_seruni":1},"pantry":{},"liveCatch":{"reef_seruni":1},"fishPen":{"unlocked":false},"plots":[{"id":"plot_1","stage":"empty"}],"market":{"day":2,"bought":1}}
	var host:=HomeHost.new()
	root.add_child(host)
	var ui=load("res://../scripts/tests/support/homestead-capture.gd").new()
	host.add_child(ui)
	ui.configure(host,false)
	ui.open_for("market")
	await settle()
	assert(not button(ui,"Beli satu bibit Kangkung").disabled)
	assert(button(ui,"Beli satu bibit Jahe").disabled,"Authoritative per-crop price governs affordability")
	state.player.coins=30
	ui.open_for("market")
	await settle()
	button(ui,"Beli satu bibit Jahe").pressed.emit()
	assert(ui.requests.back()=={"action":"buy_seed","extra":{"itemId":"benih_jahe","qty":1}})
	ui.open_for("plot_1")
	await settle()
	assert(button(ui,"Tanam Kangkung")==null)
	button(ui,"Tanam Jahe").pressed.emit()
	assert(ui.requests.back()=={"action":"plant","extra":{"plotId":"plot_1","itemId":"benih_jahe"}})
	ui.open_for("fish_pen")
	await settle()
	assert(button(ui,"Masukkan")==null,"Locked pen has no active stock operation")
	state.homestead.fishPen={"unlocked":true,"breeders":0}
	ui.open_for("fish_pen")
	await settle()
	assert(button(ui,"Masukkan").disabled,"One live catch cannot provide two parents")
	state.homestead.liveCatch.reef_seruni=2
	ui.open_for("fish_pen")
	await settle()
	assert(not button(ui,"Masukkan").disabled)
	button(ui,"Masukkan").pressed.emit()
	assert(ui.requests.back()=={"action":"stock_pen","extra":{"itemId":"reef_seruni","qty":2}})
	state.homestead.fishPen={"unlocked":true,"breeders":2,"fed":false,"progressDays":1,"ready":true,"offspring":1}
	state.player.coins=1
	ui.open_for("fish_pen")
	await settle()
	assert(button(ui,"Beri pakan").disabled)
	state.player.coins=2
	ui.open_for("fish_pen")
	await settle()
	button(ui,"Beri pakan").pressed.emit()
	assert(ui.requests.back()=={"action":"feed_pen","extra":{}})
	button(ui,"Panen satu").pressed.emit()
	assert(ui.requests.back()=={"action":"harvest_pen","extra":{"qty":1}})
	state.homestead.fishPen.fed=true
	ui.open_for("fish_pen")
	await settle()
	assert(button(ui,"Pakan hari ini").disabled)
	ui.open_for("kedai_stock")
	await settle()
	for name in ["Kangkung kebun","Jahe pesisir","Ikan seruni budidaya"]: assert(button(ui,"Titipkan satu "+name)!=null)
	button(ui,"Titipkan satu Ikan seruni").pressed.emit()
	assert(ui.requests.back()=={"action":"stock_kedai","extra":{"itemId":"ikan_seruni","qty":1}})
	ui.close()
	host.free()
	print("HOMESTEAD OPTIONS PASS: real controls, crop prices/seeds, live-parent minimum, daily feed/affordability, harvest and all3pantry actions; capture-only payload fixture, no server request or reward proof")
	quit()
