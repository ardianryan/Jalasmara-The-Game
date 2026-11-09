# Mang Ujang: rear upper body and west fishing grip

Original Jalasmara artwork under the original-art terms in the repository `LICENSE`, section 2. No upstream character or PixelDoll asset is included. This is a small direction pilot, not a four-direction animation pack.

The built-in `image_gen` tool produced `generated.png` on 2026-11-09 as an identity-preserving edit. The inputs were the project's `village-residents-v1.png` and `npc-rigs/ujang.png`, inspected before generation. No external paid API or Sprite AI credentials were used.

The full generation prompt is saved in `prompt.txt`. A second built-in edit, `generated-torso-v2.png` with `prompt-torso-v2.txt`, removes baked cream sleeves from the torso so the existing articulated arms remain separate. The final rear vest is 27 × 34 pixels. `tools/npc-rig/ujang_rear.py` thresholds alpha at 128, crops the three visible parts, resizes with nearest-neighbour sampling, and quantizes opaque colours to the existing Ujang portrait atlas. It packs the reviewed parts into a versioned runtime atlas, preserving the old `ujang.png` source. No painting code fabricates a rear from the front silhouette.

The runtime north head has its own centre `[0, -81.5]`; the north torso uses `[0, -52.5]`. These centres align the newly drawn rear neck and vest with the existing joints. Other direction art and rear limbs remain the earlier cutout pilot.

The 7 × 7 west fist was inspected after packing. Its `gripPixel` `[3.5, 3.5]` is the centre of an opaque finger pixel. `wristPixel` `[3.5, 6]` is at the bottom wrist; `rodAxis` runs from `[1, 6]` towards `[6, 1]` through the curled fingers. Pixel coordinates are measured from the cropped part's top-left edge. The rod is drawn behind the fist; the fist does not contain a baked rod. These annotations are artwork coordinates, not a hand socket used to construct the rod geometry.

Reproduce packing with `python3 tools/npc-rig/ujang_rear.py`. Running the full original cutout generator also applies this override after regenerating the three original atlases. Native rendering and mesh contact tests are still required for acceptance.

The turn follow-up adds `generated-west-head-v1.png`, made with the same built-in tool from the original resident image and approved rear source. Its exact prompt is `prompt-west-head-v1.txt`. The packed original `head_west.png` is 29 × 27 with centre `[-1, -81.5]`, in cell 17. Nose and eyes look left in the actual artwork; no mirroring is needed. Ujang now has eighteen parts. This supplies a west head, not a complete independently drawn west body. See `docs/reviews/06b2-ujang-transition-step.md` for final native review and the unchanged original-art terms.
