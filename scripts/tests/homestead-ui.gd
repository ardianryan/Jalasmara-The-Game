extends SceneTree

class HomeHost extends Node:
	var modal := false
	func set_interaction_modal(active: bool) -> void: modal=active

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	root.get_node("CalendarSync").set_process(false)
	var host:=HomeHost.new()
	root.add_child(host)
	var ui=load("res://scripts/HomesteadUI.gd").new()
	host.add_child(ui)
	ui.configure(host,false)
	var fired:Array[int]=[]
	for screen in [Vector2i(844,390),Vector2i(667,375),Vector2i(390,844)]:
		root.size=screen
		for frame in range(3): await process_frame
		ui._page("Peti Griya Sasmita")
		var paragraph:Label=ui._text("Fragmen tersimpan dengan jumlah dan kualitas yang sama. Benda cerita tetap bersama Nala.")
		var first:Button=ui._button("Simpan satu ke peti",func(): fired.append(1))
		for line in range(8): ui._text("Catatan perawatan kebun dan hasil pengamatan Nala.")
		var last:Button=ui._button("Kembali",func(): fired.append(2))
		for frame in range(4): await process_frame
		var scale:float=root.get_final_transform().x.length()
		assert(root.get_visible_rect().grow(2).encloses(ui.panel.get_global_rect()),"Home page must fit portrait and landscape")
		assert(paragraph.get_theme_font_size("font_size")*scale>=16,"Home body must remain readable on narrow landscape")
		assert(first.size.y*scale>=56 and last.size.y*scale>=56,"Home actions need56physicalpx touch targets")
		assert(root.gui_get_focus_owner()==first,"Recreated pages must focus their first action")
		assert(host.modal and root.get_node("EnvironmentState").clock_paused)
		var tab:=InputEventKey.new()
		tab.keycode=KEY_TAB
		tab.physical_keycode=KEY_TAB
		tab.pressed=true
		root.push_input(tab)
		for frame in range(4): await process_frame
		assert(root.gui_get_focus_owner()==last,"Tab must reach lower actions")
		var scroll:ScrollContainer=ui.panel.get_child(0)
		assert(scroll.follow_focus and scroll.get_global_rect().grow(2).encloses(last.get_global_rect()),"Focused action must scroll into the visible panel")
		var enter:=InputEventKey.new()
		enter.keycode=KEY_ENTER
		enter.physical_keycode=KEY_ENTER
		enter.pressed=true
		root.push_input(enter)
		await process_frame
		enter.pressed=false
		root.push_input(enter)
		assert(fired.back()==2,"Enter invokes the focused action")
		ui.busy=true
		ui.close()
		assert(ui.is_open,"Unconfirmed operations cannot close mid-request")
		ui.busy=false
		ui.close()
		assert(not host.modal and not root.get_node("EnvironmentState").clock_paused)
	ui.show_objective("Kembali ke Kedai Waras untuk menyiapkan pesanan warga.")
	for frame in range(4): await process_frame
	assert(host.modal and root.get_node("EnvironmentState").clock_paused)
	var return_button: Button = root.gui_get_focus_owner()
	assert(return_button.text=="Kembali","Objective details need a reachable close action on touch and keyboard")
	return_button.pressed.emit()
	assert(not ui.is_open and not host.modal and not root.get_node("EnvironmentState").clock_paused)
	ui._pending={"body":{"action":"sleep"},"key":"ui-only"}
	ui.open_for("bed")
	for frame in range(4): await process_frame
	assert(root.gui_get_focus_owner() is Button and root.gui_get_focus_owner().text=="Periksa kegiatan sebelumnya","Pending operation recovery must be keyboard reachable")
	ui.close()
	host.queue_free()
	print("HOMESTEAD UI PASS: real844x390/667x375/390x844 layouts,16pxbody/56pxactions, page focus/Tab/Enter, focus-following scroll, busy guard, reading pause and pending-operation recovery; no network mutations")
	quit()
