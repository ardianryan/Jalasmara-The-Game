extends RefCounted

static func viewport(node: Node,fallback: Node = null) -> Viewport:
	if is_instance_valid(node) and node.is_inside_tree(): return node.get_viewport()
	if is_instance_valid(fallback) and fallback.is_inside_tree(): return fallback.get_viewport()
	return (Engine.get_main_loop() as SceneTree).root

static func ratio(node: Node,fallback: Node = null) -> float:
	var view:=viewport(node,fallback)
	return view.get_visible_rect().size.x/maxf(1,Vector2(view.get_window().size).x)

static func body(node: Node,fallback: Node = null) -> int:
	var pixels:=18 if viewport(node,fallback).get_window().size.x>=1024 else 16
	return maxi(8,ceili(pixels*ratio(node,fallback)))

static func target(node: Node,fallback: Node = null) -> float:
	return maxf(24,ceilf(56*ratio(node,fallback)))
