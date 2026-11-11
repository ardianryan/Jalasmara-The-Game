extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var quality: Node=root.get_node("RenderQuality")
	var original: String=str(quality.get_profile().requested)
	assert(quality.set_profile("low",false))
	var hub: Node=load("res://scripts/Main.gd").new()
	var forest: Node=load("res://scripts/Forest.gd").new()
	assert(not hub._gait_capacity(false) and not hub._gait_capacity(true))
	assert(not forest._gait_capacity(false) and not forest._gait_capacity(true))
	assert(quality.set_profile("balanced",false))
	hub._gait_retry_after_ms=Time.get_ticks_msec()+30000
	forest._gait_retry_after_ms=Time.get_ticks_msec()+30000
	assert(not hub._gait_capacity(false) and not forest._gait_capacity(false))
	quality.set_profile(original,false)
	hub.free()
	forest.free()
	print("NALA QUALITY GATE PASS: low profile disables physical gait; balanced cooldown blocks immediate retry")
	quit()
