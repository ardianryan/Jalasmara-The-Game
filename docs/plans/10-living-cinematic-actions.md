# Living cinematic actions

The Phase 1 cutscenes already have animated atmosphere, but the screenplay's actions still rely on static paintings and dialogue. This package adds small, code-authored pixel layers at the exact beats where Nala arrives by boat, the contaminated pipe fractures, and the ancient map is revealed. They use the existing Godot renderer and art, with no generated sprite sheet or new runtime dependency.

Acceptance: the boat crosses the water during prologue beat 6 and its oar cycles; pipe pieces separate after boss resonance 3/6 while Gajah Mina remains visible; the epilogue map draws a moving depth route on beat 4. All action pauses into a legible static pose for reduced motion. The additions must remain behind dialogue and skip controls, pass the cutscene fixture at 960×540 and 667×375, and not alter server-owned progression, combat, rewards or calendar time.

Use PixelHand only as a reviewed offline reference for future authored sprite sheets. This pass draws editable pixel geometry in GDScript. Cinetic stays an offline trailer/cutscene option; it is not required for these real-time interactions.

The owner also suggested [Konado](https://github.com/godothub/konado). Its current repository describes a Godot dialogue/visual-novel toolkit under a choice of MIT, BSD-3-Clause or Mulan PSL 2.0. It could help author branching conversations later, but the existing `DialoguePresenter.gd` and server-owned story gates already work. No Konado files, license obligations or runtime dependency are added in this package; evaluate it separately against the live dialogue bridge before integration.
