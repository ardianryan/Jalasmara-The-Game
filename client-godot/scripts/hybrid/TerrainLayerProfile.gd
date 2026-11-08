extends RefCounted

# Original Godot profile: separate elevation, top, wall and edge roles before baking meshes.
# Strata's Unity workflow is a design reference; no upstream code or assets are copied.
static func at_depth(depth: float) -> Dictionary:
	if depth < 2080:
		return {"id":"porous_limestone","inset":0.13,"extrusion":340.0,"peak":38.0,"terraces":3,"top":Color(1.20,1.17,1.00),"side":Color(0.70,0.96,0.94),"edge":Color(0.94,1.07,0.96)}
	if depth < 3060:
		return {"id":"karst_sediment","inset":0.16,"extrusion":400.0,"peak":48.0,"terraces":4,"top":Color(1.05,1.10,0.91),"side":Color(0.60,0.83,0.84),"edge":Color(0.81,0.98,0.91)}
	return {"id":"fractured_basalt","inset":0.18,"extrusion":470.0,"peak":56.0,"terraces":4,"top":Color(0.91,1.04,1.08),"side":Color(0.55,0.73,0.84),"edge":Color(0.76,0.92,1.02)}

static func outline_band_factor(layer: int, count: int, vertex: int, seed: int) -> float:
	var t := float(layer) / count
	return clampf(t + sin(vertex * 1.71 + seed * 2.19) * sin(t * PI) * 0.08,0,1)
