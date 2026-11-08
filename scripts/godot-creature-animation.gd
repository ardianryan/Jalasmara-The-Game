extends SceneTree
const Animator = preload("res://scripts/CreatureAnimator.gd")
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var Wildlife = load("res://scripts/Wildlife.gd")
	var ids := ["reef_seruni", "pari_lamun", "sidat_smara", "ubur_smaragd", "sotong_karang", "ular_muara", "kepiting_bandar", "buntal_pasir", "hiu_segaran", "kura_pesisir"]
	var count := 0
	for id in ids:
		for facing in [1.0, -1.0]:
			var first := Animator.frame_data(id, 0.0, facing)
			assert(not first.is_empty(), id + " missing animation")
			assert(first.direction == (0 if facing > 0 else 4))
			var base_image: Image = first.texture.get_image()
			var first_pixels := base_image.get_region(Rect2i(first.source)).get_data()
			var changed := false
			for frame in range(1, int(first.frame_count)):
				var next := Animator.frame_data(id, float(frame) / float(first.fps), facing)
				var rectangle: Rect2 = next.source
				assert(rectangle.position.x >= 0 and rectangle.position.y >= 0)
				assert(rectangle.end.x <= next.texture.get_width() and rectangle.end.y <= next.texture.get_height())
				if next.texture.get_image().get_region(Rect2i(rectangle)).get_data() != first_pixels:
					changed = true
			assert(changed, id + " has static locomotion frames")
			count += 1
	for species in range(12):
		assert(not Wildlife._generated_species(species).is_empty(), "species unmapped " + str(species))
	print("PASS procedural animator: %d E/W clips, 10 species, frame bounds and changing pixels; all 12 sea visual slots procedural" % count)
	quit()
