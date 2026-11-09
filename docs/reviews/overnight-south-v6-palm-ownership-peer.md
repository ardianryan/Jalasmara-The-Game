# SOUTH v6 isolated-palm cloth ownership peer

Read-only CPU image/source review of the website lane's `artifacts/player-gait/south-upper-ownership-draft-v6/south-daily0-alpha-contour-and-separate-arms.png`. No mask, authoring tool, image or runtime edits; no engine/browser. This review concerns SOUTH daily frame0 only.

The isolated anatomical LEFT arm visibly carries a gray/teal triangular flap beside the fist. The flap comes from original shirt pixels assigned to `left/palm`, not the explicitly authored hidden-cloth plate. Original cell coordinates and RGBA include:

| Source coordinate | Original RGBA | Current owner |
| --- | --- | --- |
|(70,58)|(91,109,107,255)|left/palm|
|(69,59)|(86,106,104,255)|left/palm|
|(70,59)|(84,104,100,255)|left/palm|
|(68,60)|(82,101,99,255)|left/palm|
|(69,60)|(90,113,109,255)|left/palm|
|(68,61)|(85,99,100,255)|left/palm|
|(68,62)|(78,93,89,255)|left/palm|
|(68,63)|(99,116,110,255)|left/palm|

These pixels form the visible shirt-side continuation from the unmoved cloth at x67/68. The v6 authored extreme uses the same−45° fore/palm transform. It maps (70,58) to(72.6360,64.3640), (68,60) to(72.6360,67.1924), and (68,63) to(74.7574,69.3137). This independently connects the source ownership to the observed rotated flap around y64–69. A byte-exact rest recomposition does not validate anatomical ownership: the wrong component assignment is hidden when the parts are at rest.

The listed cloth pixels should remain on the torso component rather than rotate with the fist. Dark border pixels such as(69,61),(69,62),(69,64),(70,65) require deliberate silhouette review; this is not a recommendation to delete pixels by a blanket gray/color threshold. Reassign ownership before applying hidden-cloth repair, preserving original rest reconstruction and explicit authored provenance. Separate forearm/palm previews after the change are needed before accepting a moving-arm mask. No judgment for other source frames/outfits or complete gait follows from this one frame.

Exact coordinates/RGBA and the transformation mechanism were sent to the website author and root before source changes. Source data were inspected via the existing authoring module's pure `split` function, without invoking its artifact-writing entrypoint.

Provenance:

- Original daily atlas SHA256 `342724d1724490279cd0f65c0340c5b35cdf366ecc36a99af716c51f751b8fc3`.
- Original daily0 upper-cell RGBA SHA256 `2f8c2e372c562619fe1890fdcd90f01237fc86196bfa45ba6c21ef0ea23fc237`.
- v6 manifest SHA256 `465405a0503c86038fc72438e3bea3b85e8dd926b323e63e0741abd1d6167a36`.
- v6 ownership spec SHA256 `4f8b65a434c701615c9c06361b9714cde437288722995aefa9511f68f7ff6d24` (matched current spec at review time).
- v6 authoring script SHA256 `80e9f71358f7323c668f16bb56ab298f66d8d7e3f1eb2cb53550d6dae310bc0a`.
