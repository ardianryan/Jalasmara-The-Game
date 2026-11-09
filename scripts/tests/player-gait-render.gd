extends SceneTree
class Grid extends Node2D:
	var offset:=0.0
	func _draw() -> void:
		draw_rect(Rect2(0,0,960,540),Color('#283b40'))
		for x in range(-20,40):
			draw_line(Vector2(x*32-fposmod(offset,32),0),Vector2(x*32-fposmod(offset,32),540),Color('#526167'))
		for y in range(0,18):draw_line(Vector2(0,y*32),Vector2(960,y*32),Color('#526167'))
func _initialize() -> void: call_deferred('_run')
func _run() -> void:
	assert(DisplayServer.get_name()!='headless')
	root.size=Vector2i(960,540)
	var grid:=Grid.new()
	root.add_child(grid)
	var actors: Array[Sprite2D]=[]
	for index in range(4):
		var visual: Sprite2D=load('res://scripts/CharacterVisual.gd').new()
		visual.set_appearance(['male_default','male_nusantara','female_default','female_nusantara'][index])
		visual.set_outfit('daily')
		visual.position=Vector2(135+index*230,300)
		grid.add_child(visual)
		actors.append(visual)
	DirAccess.make_dir_recursive_absolute('res://../artifacts/godot/player-gait')
	for frame in range(96):
		var velocity:=Vector2(42 if frame<48 else 84,0)
		grid.offset+=velocity.x/12
		grid.queue_redraw()
		for visual in actors:
			visual.set_locomotion(velocity,1.0/12)
			var x:=visual.position.x
			visual.animate(true,false,1,0)
			visual.position=Vector2(x,300)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png('res://../artifacts/godot/player-gait/%03d.png'%frame)
	print('PLAYER GAIT GPU PASS:4 identities, slow/normal body phase on world grid')
	quit()
