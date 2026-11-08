import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { createHash } from "node:crypto";
import { inflateSync } from "node:zlib";
import { resolve } from "node:path";
const directory = resolve(
  process.argv[2] ?? "client-godot/resources/art/procedural",
);
const hash = (bytes) => createHash("sha256").update(bytes).digest("hex");
function decode(name) {
  const b = readFileSync(`${directory}/${name}`);
  let width = 0,
    height = 0;
  const chunks = [];
  for (let i = 8; i < b.length;) {
    const length = b.readUInt32BE(i),
      kind = b.toString("ascii", i + 4, i + 8),
      data = b.subarray(i + 8, i + 8 + length);
    if (kind === "IHDR") {
      width = data.readUInt32BE(0);
      height = data.readUInt32BE(4);
      assert.equal(data[8], 8);
      assert.equal(data[9], 6);
    }
    if (kind === "IDAT") chunks.push(data);
    i += length + 12;
  }
  const raw = inflateSync(Buffer.concat(chunks)),
    rgba = Buffer.alloc(width * height * 4);
  for (let y = 0; y < height; y++) {
    assert.equal(
      raw[y * (width * 4 + 1)],
      0,
      "Pinned PNG encoder filter changed",
    );
    raw.copy(
      rgba,
      y * width * 4,
      y * (width * 4 + 1) + 1,
      (y + 1) * (width * 4 + 1),
    );
  }
  return { width, height, rgba, sha256: hash(b) };
}
const manifest = JSON.parse(readFileSync(`${directory}/manifest.json`));
let totalFrames = 0;
for (const species of manifest.species) {
  const data = JSON.parse(readFileSync(`${directory}/${species.metadata}`));
  assert.equal(data.format, "ppc.spritesheet");
  assert.equal(data.generatorVersion, 2);
  const pages = data.pages.map((p) => decode(p.file));
  for (const [i, page] of pages.entries()) {
    assert.equal(page.sha256, species.pages[i].sha256);
    let transparent = 0,
      opaque = 0;
    for (let at = 3; at < page.rgba.length; at += 4) {
      if (page.rgba[at] === 0) transparent++;
      else opaque++;
    }
    assert(
      transparent > 0 && opaque > 0,
      "Expected transparent creature sprite",
    );
  }
  for (const clip of data.clips) {
    assert.equal(clip.frames.length, clip.frameCount);
    const states = new Set();
    for (const frame of clip.frames) {
      const page = pages[frame.page];
      assert(
        frame.x >= 0 &&
          frame.y >= 0 &&
          frame.x + data.frameWidth <= page.width &&
          frame.y + data.frameHeight <= page.height,
      );
      const pixels = Buffer.alloc(data.frameWidth * data.frameHeight * 4);
      for (let y = 0; y < data.frameHeight; y++)
        page.rgba.copy(
          pixels,
          y * data.frameWidth * 4,
          ((frame.y + y) * page.width + frame.x) * 4,
          ((frame.y + y) * page.width + frame.x + data.frameWidth) * 4,
        );
      states.add(hash(pixels));
    }
    if (clip.state === "walk")
      assert(
        states.size > 1,
        `Static locomotion clip: ${species.id}/${clip.name}`,
      );
    totalFrames += clip.frames.length;
  }
  console.log(
    `${species.id}: transparent PNG, valid frame bounds, animated locomotion PASS`,
  );
}
if (process.argv[3]) {
  const other = resolve(process.argv[3]);
  for (const file of readdirSync(directory).filter((x) =>
    /\.(png|json)$/.test(x),
  ))
    assert.equal(
      hash(readFileSync(`${directory}/${file}`)),
      hash(readFileSync(`${other}/${file}`)),
      `Non-deterministic output ${file}`,
    );
  console.log("Independent second-generation byte comparison PASS");
}
console.log(
  `${manifest.species.length} species / ${totalFrames} frames verified.`,
);
