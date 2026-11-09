extends SceneTree
var visuals: Array[Sprite2D]=[]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(960,540)
	var background:=ColorRect.new()
	background.color=Color("344950")
	background.size=Vector2(1280,720)
	root.add_child(background)
	var title:=Label.new()
	title.position=Vector2(20,10)
	root.add_child(title)
	var identities:=["male_default","male_nusantara","female_default","female_nusantara"]
	var outfits:=["daily","explorer","diving"]
	for row in range(3):
		for col in range(4):
			var visual: Sprite2D=load("res://scripts/CharacterVisual.gd").new()
			root.add_child(visual)
			visual.set_appearance(identities[col])
			visual.set_outfit(outfits[row])
			visual.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
			visual.scale=Vector2(1.3,1.3)
			visuals.append(visual)
			var label:=Label.new()
			label.position=Vector2(12+col*240,155+row*170)
			label.text=identities[col]+" / "+outfits[row]
			root.add_child(label)
	var directory:="res://../artifacts/godot/player-batch"
	DirAccess.make_dir_recursive_absolute(directory)
	var frame:=0
	var results: Array=[]
	for speed in [32,100,175]:
		for direction in range(8):
			var vector: Vector2=Vector2.RIGHT.rotated(direction*PI*.25)*speed
			for tick in range(24):
				for index in range(12):
					var visual:=visuals[index]
					visual.set_locomotion(vector,1.0/30)
					visual.animate(true,false,1,0)
					visual.scale=Vector2(1.3,1.3)
					visual.position=Vector2(120+(index%4)*240,112+(index/4)*170)
					title.text="Actual-displacement gait: %d world px/s | %s | all 12 identity/outfits"%[speed,visuals[0].DIRECTIONS[direction]]
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(directory+"/%04d.png"%frame)
				if tick==12: root.get_texture().get_image().save_png(directory+"/speed-%d-direction-%d.png"%[speed,direction])
				frame+=1
			results.append({"speed":speed,"direction":direction,"gait":visuals[0].locomotion_state()})
		var stopped:Array=[]
		for visual in visuals:
			stopped.append(visual.locomotion_state().distance)
			visual.consume_foot_contacts()
		for tick in range(15):
			for index in range(visuals.size()):
				var visual:=visuals[index]
				visual.set_locomotion(Vector2.ZERO,1.0/30)
				visual.animate(false,false,1,0)
				visual.scale=Vector2(1.3,1.3)
				assert(visual.locomotion_state().distance==stopped[index] and visual.consume_foot_contacts().is_empty())
				if tick>=7: assert(visual.vframes==1,"The visual landing must finish within200ms without physical movement")
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(directory+"/%04d.png"%frame)
			frame+=1
	FileAccess.open(directory+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(results,"  "))
	print("BATCH NATIVE PASS:12 identities/outfits x8 directions at32/100/175 and neutral stop; ",frame," rendered frames")
	quit()
