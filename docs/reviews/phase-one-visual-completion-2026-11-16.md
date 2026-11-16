# Phase 1 visual asset package — 16 November 2026

Package branch: `work/phase1-visual-completion-20261116`, based on `007db14396c281c0a23dab1a793b4716467ac96d`. This package contains only new environment art, a restored Gajah Mina atlas, authoring/verification scripts, and documentation. It does not change cutscene selection, gameplay, API state, shaders, or dialogue layout. The integrator must review and connect it on `main`.

Two original Griya Sasmita plates provide an arrival dock for scene 0.3 and a moonlit veranda for scene 4.6. Both have open, physically coherent stage areas for existing code-driven characters and boat action. The healed Gajah Mina still removes industrial pipes and purple residue while retaining its left-facing body; a deterministic pixel-grid script converts it into a 12-frame jointed atlas compatible with the current 224×160 frame contract. Complete provenance, exact prompts, hashes, and licensing are in [asset provenance](../assets/phase-one-visual-completion-2026-11-16.md).

The first code-only reconstruction of the corrupted sprite was rejected because its body texture became visibly smeared. The accepted candidate is a single static source edit, curated against the original at 192×128, followed by deterministic code-driven articulation. This keeps animation authoring in code and preserves the source for future revision. The 12-frame test reports one connected silhouette per frame, 97.14% source-mask overlap, a 95.6% reduction in purple-classified pixels, and a normal loop seam. The actual [frame contact](../visual/gajah-mina-healed-frame-contact-20261116.png), [phone-size composite preview](../visual/gajah-mina-healed-composite-667x375-20261116.png), and [Griya pair](../visual/griya-phase1-plates-contact-20261116.png) were inspected visually. The phone composite is a Pillow preview, not a Godot screenshot.

Verification run in this isolated worktree:

- `python3 tools/boss-motion/generate_healed_boss_frames.py` — passed; manifest matches generated files.
- `python3 tools/boss-motion/verify_healed_boss.py` — passed all source hash, frame dimension, silhouette, purple-residue, connectivity and loop checks.
- Godot 4.7.2 `--headless --editor --quit` — first pass reported a missing font cache while creating fresh-worktree imports; second pass yielded no `ERROR:` or `SCRIPT ERROR`.
- Native game composition, browser/Windows/Samsung S23 performance, and all-scene cutscene behavior were **not** tested in this package. Those are integration acceptance tasks after the asset names are wired.

Integration targets: `client-godot/resources/art/cinematics-v2/griya-arrival-dock.png` for late prologue 0.3, `griya-beranda-moonlit.png` for late epilogue 4.6, and `client-godot/resources/art/gajah-mina-motion-v2-healed/swim.png` for victory 4.3. The original corrupted atlas should remain the boss-intro form. On selecting a healed atlas, keep all non-boss cutscene physics and six-resonance outcomes unchanged. Re-run the 667×375/844×390 director capture on integrated `main`, especially frame 0/3/6/9 motion, 4.3 contact with Nala, and the epilogue's moonlit pan. Review the Godot native output before promoting to staging.
