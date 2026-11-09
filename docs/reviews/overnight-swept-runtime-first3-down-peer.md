# Swept stair runtime peer: FIRST3 geometry and later DOWN rejection

CPU/source/artifact review of runtime05c5beb/08bbf42. No engine/browser or runtime edits by this lane. `NalaStairSupportCurve.gd` source SHA256 `d5d252172af456b43b219695dd5ba69a3b8c4aa4b8de547a1d4ed66390d49ff4` is pinned by the actual FIRST3 source record. Default physical/lower-body prototype remains OFF.

## Source review and actual partial result

The port derives riser world lines from the canonical profile's actual across/tangent geometry, projects every original opaque corner/sole marker onto that plane, and adds a conservative0.02world lead margin before crossing. XYZ polyline arc only bounds free-foot speed; phase remains accepted continuous ACTOR worldXY, and intermediate waypoints are not contacts. Duration is derived from `(1.5*arc+3π)/4.9`, rounded upward to the existing quarter grid. Frozen targets, body policy and ordinary/unsupported curves remain explicit.

Read-only peer issues were fixed before the moving proof: zero tread count and nonfinite source basis/pivot reject; canonical ascending profile scope is explicit; invalid sample u/arc/length/knots/world inverse fails closed; sharp-turn reanchors label their legacy path correctly. The exact helper fixture compares independent CPU knots/arc and preserves original endpoints. This is fresh ascending identity-plane/C0 scope, not DOWN support geometry, changing-source-view clearance or a whole-world theorem.

Actual FIRST3 source08bbf42 exits0 in8.514044375s with no recorded errors:136 measured samples across normal dock ascent, normal dock descent and central normal ascent. The actual guard extension in08bbf42 registers the independently checked `stair_swept_support` type; it does not change the original8px pelvis, source bone,5× ankle, full-mask or pause guards. Central uses swept durations10.75→60,17→84,16.5→96 and19→top96, with the72 legacy fallback explicitly labelled unsupported by the swept scope. Largest measured pelvis drop is5.79670central,6.51454dock-up and7.10936dock-down; largest source-length error across these cases is0.000189782world. At the last observation of all three cases, requested artwork/body/both feet agree and foot held-view seconds/distance are0.

**Contact order is not accepted by that geometry PASS.** The independent existing `stair-swept-first3-08bbf42-contact-order.json` is FAIL. Central frame233 has counterDelta2 but only one observable left plant, leaving60unobservable. The stop sequence then records left84 at266 followed by right72 at268; the next new contact is again right96 at291. These issues were sent immediately to root/character and are owned by the author's validated contact trace investigation. No full staircase/natural-motion acceptance follows from the136 geometry samples.

## Actual FULL16 rejection: free RIGHT is horizontally unreachable

Same-source FULL16 completes those first three cases, then rejects central normal DOWN at actor `(1370,730.744140625)`, requested drop21.4370524667507px. The current body isSW, both feet still use held NW artwork with identity Q/C0, desired feetSW, held for0.25s/24.97925accepted units. The left96support is legitimate. The right is free at17.4490967/20.480957 toward frozen84, using the explicitly labelled legacy descending curve; the ascending swept helper has not been silently adopted for DOWN.

Reconstructing current BODY hips from actual renderer map/camera basis and SW original source, while reconstructing each ankle from its held NW FOOT source, gives:

| Limb | Hip world | Ankle world | Horizontal separation |
| --- | --- | --- | ---: |
|LEFT96stance|(1372.828427,−1413.944166,122.848803)|(1365.05,−1404.717,102.103873)|12.06833world|
|RIGHTfree|(1365.757359,−1406.873098,122.848803)|(1368.953553,−1445.368553,96.647374)|38.62791world|

The original conservative outer reach is27.97782world. Right horizontal separation alone exceeds it; a pelvis height change cannot fix this. The reported21.43705value is the existing `sqrt(max(0.001,outer²-horizontal²))` fallback signature in an already horizontally invalid pose. Retaining the earlier WEST body view still leaves about34.27world horizontal separation, so this is not a Q/facing-only remedy. No guard should be widened.

## Upper-flat ordinal alias and a bounded classification proposal

The support at96 is **outside** the canonical connector, as is the actor. Current `_next_tread` accepts a provisional point inside the connector and infers support ordinal4 merely from96height. It therefore targets ordinal3/84 before any real on-connector last-tread96support. The free foot starts on upper flat at logical717.23 and targets765, a57.84725world XY path while the actor remains before the735connector entrance.

Own CPU assertions against the actual canonical profile distinguish:

- Captured upper-flat support: progress1.099075, membership false, height96, ordinal absent.
- Current actor: progress1.053198, membership false, height96, ordinal absent.
- Actual last-tread center: progress0.875, membership true, height96, ordinal4.
- Premature frozen target: progress0.625, membership true, height84, ordinal3.

Equal96height therefore does not establish equal contact provenance. The proposal uses canonical membership/actual support ground, not literal case coordinates: an outside upper-flat support is `upper_approach`, not ordinalN. Select a real legal same-height96approach at/just inside the upper profile boundary, validate its whole original foot and reach, and keep its actual frozen target. If the actor is still outside after a real approach plant, do not advance toN−1 solely from the planted height. Additional same-height approach contacts are legitimate if physically landed; no extra floor or fabricated contact is proposed. Actual actor and grounded-support connector membership should establish eligibility before ordinal advancement. The exact approach anchor and subsequent timing still need geometry/controller proof; simply choosing the last-tread center can also be too far under held-source hips.

The author owns contact tracing/FootPlant and received this classification before runtime edits. CPU classification assertions5/5 pass; this is not a gameplay test. Own `.runtime/approach-classification-08bbf42.json` SHA256 `9bc22ed65d9edf416364abe5bb30f552bcc7c160a4cf33ad3fc3c22cba0264b4`. Actual FIRST3 samples SHA256 `40ea99eeb804f68881ee7215b23f9268c7d470a7cf8cbf4c8848f55410485c40`; FULL16 rejection SHA256 `9848fcef4edfb1e72314ddd49c7d3eadd7ef87ccc4b7ad7518c5a6b31bd4bb3e`.
