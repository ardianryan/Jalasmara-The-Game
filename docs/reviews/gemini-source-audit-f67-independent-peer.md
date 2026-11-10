# Independent source review of Gemini audit f67de11

Read-only CPU review of `/Users/ardianryan/Documents/Jalasmara-gemini-character-audit` commit `f67de11`, alongside the integrator HOLD review. No files or Git state in that worktree were written; its generator and engine/browser were not run. Python imports used `PYTHONDONTWRITEBYTECODE=1`. Diagnostic files and a small path-validator fixture were written only under this lane's ignored `.runtime`.

## Concrete false-positive orientation finding

The reported `female_default/explorer` NW/NE inversion is contradicted by enlarged original pixels. Manual inspection of original IDLE5 and every WALK row5 head shows rear-left facing with the brown bandana tail on the right. IDLE7 and every WALK row7 head face rear-right with the tail on the left. These18 original crops are preserved in own `.runtime/gemini-female-explorer-original-heads80-f67.png`; four larger original upper-body pairs are in `gemini-female-explorer-original-pairs-f67.png`.

The audit's `get_face_profile` nevertheless labels NW frame0 `RIGHT`: head center64.6, alleged skin center64.8, alleged hair center63.5, offset1.33. Its rule counts every head pixel with red>120 and red>blue as skin. Original NW frame0 `(75,37)` RGBA `(170,97,73,255)` lies in the visible brown bandana tail and satisfies that rule. The real exposed left-face pixel `(55,37)` is `(166,128,92,255)`. This threshold cannot distinguish the two materials. The defect is interpretation, not manufactured proof pixels:8622 opaque interior pixels across the four female explorer proof cells match the corresponding original atlas pixels exactly.

Actual female explorer atlas SHA256 values are WALK `c9fcd98430fc7fb27f0d08470e69030bd768a87a550f65f8033ce3c1398ab38f` (RGBA1024×1024) and IDLE `e11f9d3a45dcbf40f8c7ef1702a5e590d3d5398aff215e943839034caa1a6f92` (RGBA1024×128). WALK row5 cells are `[128*f,640,128*(f+1),768)`, row7 `[128*f,896,128*(f+1),1024)` for f0..7; IDLE5 is `[640,0,768,128)` and IDLE7 `[896,0,1024,128)`. The enlarged18-crop sheet uses local `[44,18,84,68)` from those original cells, nearest-neighbor×3. The four proof-interior comparisons exclude their one-pixel borders and compare every fully opaque source pixel without reclassification.

Do not repair or swap these female explorer rows on the basis of the reported P0. Other unreviewed orientations remain unknown. The report's female-North head-centroid signal likewise does not establish a turned head or anatomical symmetry requirement.

## Useful evidence, with narrower conclusions

The male-default daily proof contains genuine original pixels:7238 opaque interior pixels across its four NW/NE WALK0/IDLE cells match the atlas exactly. The displayed NW and NE head silhouettes face opposite sides under their canonical labels; this is a useful source-orientation concern for deliberate review. It does not authorize an automatic row swap, nor verify every remaining frame or identity.

Original male-default daily SW frame0 has alpha bbox `(41,18,87,104)` and frame7 `(49,17,84,99)`; the maximum opaque y values are103 and98. Diving SW has corresponding bbox bottoms104 and100. These confirm source bounding-box differences of5 and4 pixels. Bbox bottom is exclusive and is not an independently identified planted sole. No runtime teleport, contact failure, or required normalization follows from these measurements alone.

The tool's last-ten-alpha-row horizontal width is an image-space extent, not world stride or original anatomical extension. East/West versus diagonal widths therefore cannot justify prescribing40–52 source-pixel steps. The source might still have artwork issues, but those require actual pose/pivot/phase evidence. The gear check inspects only North WALK0 and North IDLE in x58..69/y44..71 using two color thresholds. It cannot prove all-direction/all-frame gear cleanliness or modular-runtime compatibility.

## Reproduced provenance and path problems

Both disputed manifest files are byte-identical to `git show 5dd4ac4:<path>`:

| File | Actual SHA256 |
| --- | --- |
| `assets/source-2d/nala-eightway-batch/manifest.json` | `21fa13f548ea4d582ec624d3dd6c3162e237dc455366d1c9a0415aa221d49f79` |
| `assets/source-2d/nala-daily-eightway/source.json` | `8e65f4e8d22d18060e6b21bf889c558c39631a1c942e66cee65d33e48d9e9c74` |

Their different reported hashes are reporting errors, not evidence of source mutation. The special daily inventory also sets `sha_matches_manifest:true` while `manifest_sha256:null`; that is not a comparison.

Direct read-only calls confirm that `validate_output_path` accepts the existing other-agent file `docs/reviews/overnight-terrain-height-boundary-audit.md`. An actual symlink fixture created only in this lane's fake root—`docs/reviews/alias.md` pointing to `existing-other.md`—is also accepted and resolved to its target. Resolution precedes `is_symlink`, losing the original path identity. The same validator accepts an existing output file. These reproduce the allowlist/fresh-output/symlink failures without writing the Gemini worktree or invoking generation.

The implemented fallback assigns `reviewed_no_obvious_issue` to every direction without a hardcoded issue. That cannot establish65 visual passes. The existing six tests check their coded scope/schema/hash assertions and gallery size; they do not establish visual correctness or close the reproduced path cases. Keep the audit on HOLD until corrected evidence, unknown labels and output guards are reviewed. No new runtime/art repair is proposed by this peer report.
