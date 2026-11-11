# Xprite pixel-grid recovery

This isolated authoring directory pins [`@xprite/pixelate` 0.1.2](https://github.com/rhinoc/xprite-pixelate) for recovering a native grid from upscaled or AI-produced pixel art. Install with `npm ci --prefix tools/xprite-pixelate`; verify with `npm run check --prefix tools/xprite-pixelate`. It is not imported by the game or host app.

Use the automatic grid detector only when its result is reliable and visually inspect the output, especially faces, feet, alpha, and frame-to-frame consistency. Existing [Pixel Snapper](../pixel-snapper/README.md) remains the simpler manual-size/palette cleanup path; [Image-to-Pixel](../image-to-pixel/README.md) remains the comfy-palette conversion path. Xprite does **not** make a pixel drawing photorealistic. It restores crisp, coherent cells. Keep originals and do not silently replace production sprites.

The package is MIT. [Its upstream notice](NOTICE.upstream.md) identifies bundled/ported MIT and Apache-2.0 components, with license text preserved in [`licenses/`](licenses/). The package's published version and the inspected source revision `49c62fccaaa776281c522089b1c8d30b3028cbd5` are recorded separately; the npm lockfile pins the installed artifact.
