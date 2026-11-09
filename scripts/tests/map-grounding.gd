extends SceneTree

class Actor extends Node2D:
	var swim_sprite: Sprite2D

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_default","progress":{"day":1,"stage":"dive"}}
	state.dive={}
	var before:=JSON.stringify(state.world)
	var scene:=Node2D.new()
	root.add_child(scene)
	var actor:=Actor.new()
	scene.add_child(actor)
	actor.swim_sprite=load("res://scripts/CharacterVisual.gd").new()
	actor.add_child(actor.swim_sprite)
	actor.swim_sprite.set_appearance("male_default")
	var camera:=Camera2D.new()
	scene.add_child(camera)
	camera.position=Vector2(1370,790)
	camera.zoom=Vector2(.88,.88)
	camera.force_update_scroll()
	var renderer=load("res://scripts/land/LandWorld3D.gd").new()
	scene.add_child(renderer)
	renderer.setup(scene,actor,camera,"hub")
	var helper=load("res://scripts/land/BridgeLandings.gd")
	var sample_deck:=PackedVector2Array([Vector2(0,-50),Vector2(300,-50),Vector2(300,50),Vector2(0,50)])
	assert(helper.foundations(Vector2.ZERO,Vector2(300,0),100,sample_deck,[],0).is_empty(),"An unsupported crossing must not receive floating foundations")
	var crumb: Array=[{"id":"tiny-contact","material":"grass","elevation":0,"polygon":[[0,-50],[2,-50],[2,50],[0,50]]}]
	assert(helper.foundations(Vector2.ZERO,Vector2(300,0),100,sample_deck,crumb,0).is_empty(),"A sliver of bank cannot support a full bridge-end foundation")
	var foundation_count:=0
	for area in ["hub","forest"]:
		renderer.set_area(area)
		renderer._process(.3)
		var status: Dictionary=renderer.debug_status()
		var expected_sides:=0
		for stair in renderer.map.get("stairs",[]):
			expected_sides+=2*(int(stair.steps) if str(stair.type)=="stairs" else 1)
		assert(int(status.components.get("StairSideCheek",0))==expected_sides,"Every tread/ramp needs both closed supporting sides")
		for bridge in renderer.map.get("bridges",[]):
			var surface: Dictionary={}
			for floor_surface in renderer.map.surfaces:
				if str(floor_surface.get("bridgeId",floor_surface.id))==str(bridge.id): surface=floor_surface; break
			assert(not surface.is_empty())
			var a:=Vector2(float(bridge.path[0][0]),float(bridge.path[0][1]))
			var b:=Vector2(float(bridge.path[-1][0]),float(bridge.path[-1][1]))
			var deck: PackedVector2Array=renderer._polygon(surface.polygon)
			var foundations: Array=load("res://scripts/land/BridgeLandings.gd").foundations(a,b,float(bridge.width),deck,renderer.map.surfaces,float(bridge.elevation))
			var ends: Dictionary={}
			for foundation in foundations:
				ends[foundation.end]=true
				assert(float(foundation.supportFraction)>=.20)
				for point in foundation.polygon:
					assert(_inside_or_edge(point,deck),"Below-deck foundations may not extend the existing deck footprint")
				assert(not foundation.contacts.is_empty(),"Each foundation must actually overlap a bank at the same elevation")
				for contact in foundation.contacts:
					var bank: PackedVector2Array=PackedVector2Array()
					for floor_surface in renderer.map.surfaces:
						if str(floor_surface.id)==str(contact.bankId): bank=renderer._polygon(floor_surface.polygon); break
					for point in contact.polygon:
						assert(_inside_or_edge(point,bank) and _inside_or_edge(point,deck),"Foundation contact must be on real bank and existing deck")
			assert(ends.size()==2,"Each bridge must meet solid bank foundations at both ends")
			var emitted: Dictionary=status.bridges[str(bridge.id)]
			assert(emitted.bankFoundations==foundations.size())
			assert(emitted.planks>=7 and emitted.railBeams>=4,"Grounding must retain existing oriented deck and both railings")
			foundation_count+=foundations.size()
		if "--capture" in OS.get_cmdline_user_args():
			camera.position=Vector2(1425,680) if area=="forest" else Vector2(1370,790)
			camera.force_update_scroll()
			renderer._process(.3)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var directory: String=ProjectSettings.globalize_path("res://../artifacts/godot/map-followup")
			DirAccess.make_dir_recursive_absolute(directory)
			get_root().get_texture().get_image().save_png(directory+"/"+area+".png")
	assert(JSON.stringify(state.world)==before,"Visual grounding must not change collision data or save IDs")
	scene.free()
	await process_frame
	print("MAP GROUNDING PASS: three authored bridges grounded at both banks, clipped footprints, retained rails, closed stair side faces, unchanged authoritative world; foundations=",foundation_count)
	quit()

func _inside_or_edge(point: Vector2, polygon: PackedVector2Array) -> bool:
	if Geometry2D.is_point_in_polygon(point,polygon): return true
	for index in range(polygon.size()):
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point,polygon[index],polygon[(index+1)%polygon.size()]))<.02: return true
	return false
