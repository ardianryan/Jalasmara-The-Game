extends SceneTree

func _initialize() -> void:
	var path = load("res://scripts/land/LandPath.gd").new()
	path.reset(Vector2(100,100))
	for x in range(101,181): path.record(Vector2(x,100))
	for y in range(101,181): path.record(Vector2(180,y))
	var first: Dictionary = path.snapshot(Vector2(180,180))
	assert(first.path.size()>10 and first.path.size()<=64)
	var found_corner := false
	for point in first.path:
		if Vector2(float(point.x),float(point.y)).distance_to(Vector2(180,100))<2: found_corner = true
	assert(found_corner,"Direction changes must retain the turn instead of cutting through a roof")
	for x in range(181,221): path.record(Vector2(x,180))
	path.acknowledge(int(first.ticket))
	assert(path.size()>0,"In-flight movement must survive acknowledgement of an older request")
	var next: Dictionary = path.snapshot(Vector2(220,180))
	assert(float(next.path[0].x)>=180)
	for x in range(221,2000): path.record(Vector2(x,180))
	assert(path.full() and path.needs_flush())
	assert(path.snapshot(Vector2(2000,180)).path.size()<=64,"Payload must stay within the server's path bound")
	path.reset(Vector2(10,10))
	assert(path.size()==0 and not path.full())
	print("LAND PATH PASS: actual turns, bounded breadcrumbs, asynchronous acknowledgement and queue backpressure")
	quit()
