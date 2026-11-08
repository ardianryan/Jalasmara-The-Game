# img2threejs offline prop pipeline

Pinned upstream: `0c0c49bc168e648dbaf9c8c080474de0b3a941b6` (Apache-2.0). This project-local checkout stays in ignored `.runtime/img2threejs-upstream`; no agent-host installer or global configuration is used.

```sh
npm ci --prefix tools/img2threejs
IMG2_PYTHON=/path/to/python3.10-or-newer node tools/img2threejs/build.mjs
```

The authored spec reconstructs the slab body from a crop of Jalasmara's own atlas. Official forge image probing, local-spec assessment, reference-PBR extraction (confidence 0.838), strict spec validation and blockout factory generation were executed. Three.js runs only as an offline asset builder: Chromium renders front/side/rear views and GLTFExporter writes an embedded GLB. Godot consumes `resources/models/memory-slab.glb`; the game has no Three.js runtime.

The model has a physically open frame plus an inset backing panel (two meshes, 60 triangles, 1 × 1 × 0.18 relative bounds). It is a low-poly background backing for the original interactive PNG tablet, not a replacement for its artwork. Hidden sides and thickness are inferred. Only the blockout build has camera evidence; the complete eight-pass upstream fidelity review is **not** claimed. `state.json` remains an unfinished upstream checklist rather than a fabricated approval record.

The reference, analysis, authored spec, generated factory, independent material maps, three camera renders and output manifest live in `assets/source-3d/img2threejs/`. `LICENSE.upstream.txt` preserves the upstream notice; runtime copy is `resources/models/memory-slab-LICENSE.txt`.
