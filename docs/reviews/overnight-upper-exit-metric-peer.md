# Upper stair exit: physical metric and third-step peer

Independent CPU review of character model `37c586d` against actual rejection `nala-terrain-first7-carried-resume-6b6a7e3`. Own rerun: `.runtime/stair-exit-handover-37c586d-peer.{json,log}`. No runtime/world edits or engine/browser/GPU runs occurred.

The new actual rejection limits the trailing LEFT144 stance, not the earlier resumed NORTH/C shoe. Original NW reconstruction gives horizontal distance21.88036world below conservative reach27.97782, requested drop8.717411px versus recorded8.717361 (difference0.000051). RIGHT requests only about3.1805px. The current exit target is the extrapolated next logical tread center at380, beyond actual upper boundary390.

## Profile-derived target

The production embedding is `W(x,y,h)=(x,-y/cos55-h*tan55,h)`. A straight connector's continuous XY span is therefore `length([Δx,-Δy/cos55-Δh*tan55])`. One physical inside tread is that span divided by actual step count.

For ridge `(1780,450,96)` to `(1780,390,144)`, the inside span is36.0557034world and tread depth12.0185678. Upper-flat north motion costs`1/cos55`world per logical y, so extending one inside physical tread onto that flat requires6.8935673 logical units. The candidate y is383.1064327, not the old extrapolated380. The old10-logical extension costs17.4344633world, approximately45% longer. Central stairs nearly hide this error: their inside tread is17.731world versus17.434 for the same10-logical flat extension. Their earlier pass cannot establish ridge correctness.

The target must be derived through actual profile/end/ground transforms and validated as a real upper-flat original-mask landing. No floor, actor position or obstacle may be invented or moved. If `_safe` adjusts it back onto the connector, the exit classification must not silently repeat boundary contacts. Once a genuine exit plant is outside, the existing ascending `support_progress>1` rule already leaves stair selection. A one-shot actual exit-contact handover can reuse the existing adaptive short-step policy without changing accepted facing counters or steady32 semantics; runtime validation remains required.

## Frozen two-step witness and a concrete third-step limitation

The model reproduces the old failure and retains the zero/half-depth/default32 counterexamples. Its selected physical-depth exit derives RIGHT15.5 (drop6.88213px, inner slack8.03094, ankle ratio4.29725), then existing adaptive LEFT22 (drop7.52969, inner20.48168, ankle3.97993). Both have no horizontal failures and preserve source lengths. These are finite frozen NW/identityQ/zeroC witnesses. Both stages use a continuous-taper geometry study, not proof of the current ordinary-flat code.

Independent original opaque corner/marker checks cover116 LEFT and62 RIGHT points. Initial LEFT144 stance, candidate RIGHT exit and next LEFT target all lie on the actual144 floor; their minimum support gap is0. Canonical shared `isLandWalkable(map,point,0)` accepts every candidate exit/next landing corner. The new exit center is `(1783.889,383.1064327)`. The next LEFT center `(1776.464466,359.9658693)` is foot-legal; failure of a12-unit **body** margin there does not by itself invalidate a foot.

However, the model's third ordinary32 target is not actually legal. World `(1783.889087,-808.659276,144)` places41 of62 original RIGHT corners inside `hub_margin_tree_10`, whose authoritative footprint is `[[1755,325],[1785,325],[1785,355],[1755,355]]`. Bare-ground third-step metrics (drop7.11072, ankle3.04311) therefore do not establish a legal third landing or production `_safe` behavior. The real `_safe` must adjust that target, changing the frozen trajectory. The production fixture may stop before completing this third contact; neither that possibility nor collision handling proves the untested full step. Keep this case as unknown until actual safe-target/collision handling is included. Do not move the tree or weaken guards to preserve the model.

Own evidence: `.runtime/stair-exit-fixed-support-mask-37c-peer.json`, `.runtime/stair-exit-landing-mask-logical-37c-peer.json` and `.runtime/stair-exit-third-mask-37c-peer.json`, checked with the actual shared TypeScript land predicates via Node's type stripping. The target path and body model remain C0, not a natural-motion/C1 or all-profile proof. Original-mask/source-Q/C evolution, actual next-step feedback, collision acceptance, contact traces and native cadence still require their independent runtime checks.
