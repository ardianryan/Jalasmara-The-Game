extends SceneTree

const OUTPUT="res://../artifacts/godot/swim-reaction-v2"

func _initialize() -> void:
	call_deferred("run")

func capture(name:String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT+"/"+name+".png")

func run() -> void:
	root.size=Vector2i(960,540)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var stage:=Node2D.new()
	root.add_child(stage)
	var background:=ColorRect.new()
	background.color=Color("315d65")
	background.size=Vector2(960,540)
	stage.add_child(background)
	var visual:Sprite2D=load("res://scripts/CharacterVisual.gd").new()
	stage.add_child(visual)
	visual.set_appearance("male_nusantara")
	visual.set_outfit("diving")
	visual.position=Vector2(480,270)
	visual.animate(false,true,1,0)
	visual.position+=Vector2(480,270)
	await capture("00-idle")
	for step in range(4):
		visual.set_locomotion(Vector2(140,0),.1)
		visual.animate(true,true,1,float(step+1)*.1)
		visual.position+=Vector2(480,270)
		await capture("%02d-kick"%(step+1))
	visual.trigger_shot(.5)
	visual.animate(true,true,1,.5)
	visual.position+=Vector2(480,270)
	await capture("05-shot")
	visual.trigger_hit(.6)
	visual.animate(true,true,1,.6)
	visual.position+=Vector2(480,270)
	await capture("06-hit")
	visual.animate(false,true,1,1.1)
	visual.position+=Vector2(480,270)
	await capture("07-recovered")
	print("SWIM REACTION NATIVE PASS: eight source-derived pose/recoil/hit/recovery frames")
	quit()
