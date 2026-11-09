# Frozen-ramp body preparation: captured geometry peer

CPU replay of actual combined reversal failure `fa2732f`; no runtime edit, engine or browser. Source/candidate ownership remains the character lane. Reproducer: `tools/player-gait/model_ramp_body_anticipation.py`. It reads the unchanged original daily atlas, captured records and manifest and verifies their WORLD hash. Output in this worktree is `.runtime/ramp-body-anticipation-fa2732f.json`.

## Why chunk reordering alone is insufficient

The requested short handover worked: right frozen target is logicalY1140.998/Z36.185879, duration21, center-curve bound4.846947. Nevertheless, the actual rig rejects at root `(1120,1121.70007324219)`, accepted distance29.115723, right phase19.115723/21, NW body height44.666992, required pelvis drop10.334792px. The left foot is actually planted at48. The free right ankle is `(1125.38708496094,-2040.98449707031,41.2615051269531)`.

`_transfer_body` runs before the chunk writes its new free-foot logical position. `_support_transfer_active` only sees current actor/foot center positions. It neither recognizes the frozen ramp path earlier nor the actual opaque foot extent. The right foot center first reaches the crest at phase13.950926, leaving only5.164796 accepted units until the rejected observation. Body descent at rate1 would need6.183263 units to reach the maximum body height41.816737 compatible with the unchanged8px drop guard. Thus even continuous center-entry activation with no chunk lag is insufficient by≈1.01847world. Moving the existing call after the chunk can recover about2world units from the observed chunk lag but still leaves the rejected drop≈8.69649px. Raising the rate or guard is not justified by this result.

The old long-target32 path is not retained here: this is the actual shorter21 plan. Its faster arrival at the nearer lower support changes the coupled torso/foot timing, so the prior endpoint-only CPU planning comparison could not establish whole-rig acceptance.

## Original current footprint provides an earlier geometric signal

The CPU tool transforms the original NW right shoe's60 alpha vertices and separately the same set plus2 direct sole markers using the captured Q and the existing pivot-correction decay. Q is identical at the last accepted and rejected observations in this interval. It computes the current footprint's actual worldXY extent against the authored continuous dock ramp, including the real upper flat crest. It does not move the foot, raise a floor, add pixels, change a target or mark contact.

Both60 and62point sets first overlap the ramp at phase**12.898220**, before the sole center at13.950926. That leaves6.217503 accepted units. A conditional continuous rate1 torso target using the lowest real ground beneath this **current original footprint**, bounded by the standing foot's48, reaches body height**41.782492** at the frozen failed observation. Halving the integration step from0.0005 to0.00025 changes that number by≈2.4e-12world. The captured-foot requested drop would become**7.971948px**, only0.028052px below8. The body-height margin is0.034245world: this is a tight conditional witness, not runtime acceptance.

At that frozen NW final geometry, both original leg annuli remain feasible after the corresponding pelvis drop: left hip-to-ankle12.522232, right27.977849world, original inner1.220775 and outer28.077816world. These are checks of the captured final feet/view and a changed body baseline only. They do not establish intermediate reach or a different body/shoe view.

This model uses the bare physical ramp profile for torso planning. It does not replace actual painted-triangle/full-mask clearance checks. Ground under an airborne toe is a geometric preparation signal, not a new grounded support or an audio/contact event. A frozen ramp plan can identify the relevant real corridor and authorize anticipatory queries; its future destination must not be treated as an already planted support. Blindly targeting the future minimum landing height is not what this model tested.

## Implementation hazards and pending coupled proof

- The current planner receives `_landing_geometry` before its update; Q/pivot in that dictionary belong to the previous Lower pose. Lower then changes Q, decays C and possibly switches the shoe source after planner movement. Reusing old C as if it were the current chunk transform can alter the footprint enough to consume the0.034world margin. The prospective/current transform and ordering must be explicit.
- The model queries the footprint after the hypothetical chunk's current logical/Q/C projection. The current before-chunk transfer call still contains the delay; merely adding an original-mask query at that old point in the sequence does not reproduce this witness.
- H changes ankle Z; original Q/C/view changes also affect the worldXY shadow. Earlier body transfer may permit a WEST body view that the captured NW sequence rejected, followed by a different free-foot mask. Such feedback must be measured, not inferred from the frozen replay.
- Keep body travel rate1 here,6px facing admission,8px drop, original inner/outer limb lengths,5× ankle displacement and whole original-mask clearance. No reset, imaginary contact, extra clearance height or global stride change is proposed.
- The required next evidence is a real combined ascent→descent with inherited facing, unchanged frozen destinations and explicit torso/foot telemetry. Preserve the failure and any new failures. No full16/32, native or natural-gait acceptance follows from this CPU witness.

Reproduce with:

```sh
python3 tools/player-gait/model_ramp_body_anticipation.py \
  --character-root /Users/ardianryan/Documents/Jalasmara-overnight-character \
  --run /Users/ardianryan/Documents/Jalasmara-overnight-character/artifacts/godot/nala-terrain-dock-up-down-requested-handover-fa2732f \
  --world /Users/ardianryan/Documents/Jalasmara-overnight-character/.runtime/world-map.json \
  --output .runtime/ramp-body-anticipation-fa2732f.json
```

- `rejected.json` SHA256 `78aa7e36b887d28c54d57606abbaa8e186230e76ab7447dadc031d7b46d3353d`.
- `samples.jsonl` SHA256 `8cd51fe09305a5dae21c0bd4fdef5c42ef2f76536abdea2486f5b3b58d4c062f`.
- `source.json` SHA256 `a9461a0b15ec57891b56e9b81929f8c8e7908ce934aa1e654d20858bd61c7dd5`.
- CPU output SHA256 `aef08ca8f82dae063126f7ad7ca8a21d77c263f9c004438c11f930939c6e4c55`; it remains an ignored artifact, not a shipped asset.

## Endpoint transfer proposal: independent timing replay

The subsequent character candidate `2c6ddb5` moves the support query after Lower has committed the current foot view, Q, H and C, before anatomy. It reads `entry.sole` with correction already applied and queries original current corners/markers, rather than the previous planner geometry. The planner then commits from **stored body height before update** toward this current-ground target, bounded by the whole accepted-distance allowance once. This replaces the provisional chunk result; adding the allowance to an already advanced planner height would double-count motion and is not the reviewed design. Initial empty feet, physical-only mode, discontinuity counters and frozen-return guards preserve initialization/default/pause behavior.

The new endpoint update is not the earlier continuous witness. Extending the CPU reproducer reconstructs the captured final right ankle using original-mask H to within0.000764world. With its original NW/Q/C sequence frozen, step budgets corresponding to100worldXY/s give:

| Endpoint samples | Final body baseline | Final requested pelvis drop | Final effective hipZ after drop |
| --- | ---: | ---: | ---: |
|60Hz steps|41.333659|7.604957px|66.231410|
|30Hz steps|41.333659|7.604957px|66.231410|
|Mixed60/30/merged|39.666992|6.239703px|66.231410|
|One captured13.333-unit merged step|34.666992|2.143943px|66.231410|

Every virtual endpoint respects baseline displacement≤accepted distance and the original inner/outer leg annuli. Reduced motion does not alter this frozen CPU formula; that is not an actual reduced-motion fixture result. These schedules start at the recorded phase5.782715, not a separate retimed full controller run. The source-independent continuous reference stays41.782492.

The baseline difference is important, but is **not itself a seven-world-unit visual crouch**: the positive anatomy pelvis correction cancels it in this frozen case, yielding the same final effective hip. Baseline changes still affect subsequent un-dropped body-view admission and thus future foot/view/Q/H feedback; only real coupled execution and native sequence review can settle that behavior. The tool explicitly checks the frozen endpoint annuli rather than inferring them from the baseline number alone.

One lifecycle edge was sent to the author before committing the runtime candidate: `fixedRampTarget` persists after contact, so a historical ramp plan plus both grounded feet could enter the endpoint block with zero accepted XY while no foot settlement is active. An unrestricted24δ allowance there would create new torso-only idle settlement. The zero-XY allowance must use the explicitly permitted existing settlement state, or that broader idle behavior needs its own deliberate contract/test; it cannot be silently justified by a stale plan flag. Paused states return before the block. This peer did not edit character source or grant engine execution.

### Source peer completion: zero-distance lifecycle

Reviewed exact `b05a211` follow-up on `2c6ddb5`: the footprint body block now additionally requires accepted `moved_distance>0.00001` or the existing Lower `settling` state (prior free foot and zeroXY). This closes the historical-grounded-ramp-plan idle issue described above. Frozen poses return earlier; empty prior feet and changed discontinuity counters prevent stale baseline reuse. The commit starts from stored pre-planner body height and replaces the provisional planner result once, rather than adding two full allowances. No remaining concrete source blocker was found in this bounded review. This is a source ACK only; parsing, the actual combined reversal, differing rendering cadence, reduced motion and native visual acceptance are still pending at the time of this record.
