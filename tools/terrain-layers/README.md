# Godot terrain layer adaptation

Strata is a Unity 6 / URP editor tool. Its pinned repository has no declared code license; no source, shader, texture or example is copied. `source.json` records the reference revision and boundary.

The original Godot implementation separates elevation, top, side and edge roles. `TerrainLayerProfile.gd` selects limestone/karst/basalt depth profiles; `TerrainGeometry.gd` bakes three or four irregular terrace bands per authoritative polygon edge. Every projected vertex remains inside the same server contour, including the 12-degree camera compensation. Current output contains 521 band panels and 1,554 terrain triangles; collision and gameplay data remain unchanged.

Native GPU proof:

```sh
godot --path client-godot --script ../tools/terrain-layers/render-proof.gd
```

This writes `assets/source-3d/terrain-layers-gpu.png`. It is an adaptation of the workflow, not installation of a Unity plugin in Godot.
