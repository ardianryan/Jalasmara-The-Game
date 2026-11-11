import { CellColorPicker, PixelationAlgorithm, PixelationMode, detectWithAlgorithm, pixelateImage } from '@xprite/pixelate';

const cell = 4;
const nativeSize = 12;
const width = nativeSize * cell;
const height = nativeSize * cell;
const data = new Uint8ClampedArray(width * height * 4);
for (let y = 0; y < height; y++) {
  for (let x = 0; x < width; x++) {
    const i = (y * width + x) * 4;
    const value = ((Math.floor(x / cell) * 13 + Math.floor(y / cell) * 17) % 7) * 34;
    data.set([value, 255 - value, (value * 3) % 255, 255], i);
  }
}
const image = { width, height, data };
const grid = detectWithAlgorithm(image, PixelationAlgorithm.Auto);
if (!grid.reliable) throw new Error('Expected a reliable 12×12 grid from the synthetic fixture');
const art = pixelateImage(image, { mode: PixelationMode.RecoverGrid, grid, colorPicker: CellColorPicker.TwoStage });
if (art.width !== nativeSize || art.height !== nativeSize) throw new Error(`Unexpected recovered size: ${art.width}×${art.height}`);
console.log(`Xprite 0.1.2 recovered ${art.width}×${art.height} grid`);
