extends SceneTree
class HomeHost extends Node:
	var modal:=false
	func set_interaction_modal(value:bool)->void: modal=value
func _initialize()->void: call_deferred("run")
func shot(name:String)->void:
	for frame in range(7): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../artifacts/godot/plan04-ui/"+name+".png")
func run()->void:
	root.get_node("CalendarSync").set_process(false)
	var state=root.get_node("GameState")
	state.player={"appearance":"male_default","progress":{"day":1},"inventory":[{"fragmentId":"klorofil","stars":3,"quantity":2}]}
	state.catalog={"fragments":[{"id":"klorofil","name":"Benih Hayati"}]}
	state.homestead={"storageLoot":[]}
	for physical in [Vector2i(667,375),Vector2i(390,844)]:
		root.size=physical
		for frame in range(4):await process_frame
		var tag:="%dx%d"%[physical.x,physical.y]
		state.dive={"id":"ui-only","challenge":{"id":"ui-question","question":{"prompt":"Bagaimana cara menjaga lingkungan perairan bandar?","options":["Amati sumber pencemaran sebelum memilih cara penanganan.","Buang limbah ke sungai.","Abaikan perubahan warna air.","Campur pembersih tanpa memeriksa sifat senyawanya."]}}}
		var main=load("res://scripts/Main.gd").new()
		var hud=load("res://scripts/GameHud.gd").new()
		hud.touch_enabled=true
		root.add_child(hud)
		main.hud=hud
		main.nala=load("res://scripts/Player.gd").new()
		main.ui=Control.new()
		hud.add_child(main.ui)
		main.network_busy=true
		main._show_quiz()
		await shot(tag+"-quiz")
		main.nala.free()
		hud.free()
		main.free()
		state.dive={}
		var host:=HomeHost.new()
		root.add_child(host)
		var home=load("res://scripts/HomesteadUI.gd").new()
		host.add_child(home)
		home.configure(host,false)
		home._chest()
		home._button("Kembali",home.close)
		await shot(tag+"-home-chest")
		host.free()
		var forest_script=load("res://scripts/Forest.gd")
		var forest=Node2D.new()
		root.add_child(forest)
		forest.set_script(forest_script)
		forest.set_physics_process(false)
		forest.set_process(false)
		forest.avatar=forest_script.ForestAvatar.new()
		forest._build_ui()
		forest._show_characters()
		await shot(tag+"-forest-appearance")
		forest.avatar.free()
		forest.free()
	print("LEGACY MODAL RENDER PASS: six actual quiz/home/forest captures667landscape+390portrait without network mutations")
	quit()
