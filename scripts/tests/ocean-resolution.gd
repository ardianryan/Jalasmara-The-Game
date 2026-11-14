extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size=Vector2i(960,540)
	var quality=root.get_node("RenderQuality")
	var previous: String=quality.get_profile().requested
	quality.set_profile("low",false)
	var host:=Node2D.new()
	root.add_child(host)
	var ocean=load("res://scripts/hybrid/HybridOcean.gd").new()
	host.add_child(ocean)
	ocean.setup(host)
	assert(ocean.viewport_3d.size==Vector2i(480,270))
	assert(ocean.debug_status().viewport==[480,270])
	quality.set_profile("balanced",false)
	assert(ocean.viewport_3d.size==Vector2i(640,360),"Diving viewport must respond to a live graphics setting change")
	assert(ocean.debug_status().viewport==[640,360])
	quality.set_profile("sharp",false)
	assert(ocean.viewport_3d.size==Vector2i(960,540),"Sharp profile should render at native logical resolution")
	assert(ocean.debug_status().viewport==[960,540])
	quality.set_profile("low",false)
	assert(ocean.viewport_3d.size==Vector2i(480,270),"Low profile must release the extra pixel budget")
	quality.set_profile(previous,false)
	host.free()
	print("PASS ocean live resolution profiles")
	quit()
