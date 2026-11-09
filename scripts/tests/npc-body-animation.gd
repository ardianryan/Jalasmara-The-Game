extends SceneTree
func _initialize() -> void:
	var animation=load('res://scripts/NpcAnimationState.gd').new()
	animation.update(.9,Vector2.ZERO,true,false,false,false,false,'fishing')
	assert(animation.clip=='work_loop')
	animation.update(1.1,Vector2.ZERO,true,false,false,false,false,'fishing')
	assert(animation.work_phase()=='cast' and animation.events.has('cast'))
	animation.update(.01,Vector2.ZERO,true,false,false,false,false,'fishing')
	assert(not animation.events.has('cast'),'Cast event cannot repeat every frame')
	animation.begin_departure()
	assert(animation.movement_locked and animation.clip=='end_work')
	animation.update(.7,Vector2.ZERO,false,false,false,false,false,'fishing')
	assert(not animation.movement_locked)
	var travelled:=0.0
	for velocity in [Vector2(26,0),Vector2(-26,0),Vector2(0,-26),Vector2(0,26)]:
		animation.update(.1,velocity,false,false,false,false,false,'fishing')
		travelled+=velocity.length()*.1
		assert(animation.clip=='walk' and is_equal_approx(animation.distance,travelled))
	var before: float=animation.elapsed
	animation.update(5,Vector2.ZERO,false,false,false,true,false,'fishing')
	assert(animation.elapsed==before,'Paused body must not advance')
	animation.update(.1,Vector2.ZERO,false,false,true,true,false,'fishing')
	assert(animation.clip=='interact')
	animation.update(.1,Vector2.ZERO,false,true,false,false,true,'fishing')
	assert(animation.clip=='rest' and animation.frame==0)
	for id in ['ujang','darmi','sari']:
		var metadata: Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://resources/art/npc-rigs/'+id+'.json'))
		assert(metadata.parts.size()==16 and float(metadata.footPivot[0])==0 and float(metadata.footPivot[1])==0)
		assert(metadata.sourceSha256.length()==64)
	print('NPC BODY ANIMATION PASS: clips, one-shot action events, tidy lock, four-direction distance gait, pause/reduced motion, 48 original cutout parts')
	quit()
