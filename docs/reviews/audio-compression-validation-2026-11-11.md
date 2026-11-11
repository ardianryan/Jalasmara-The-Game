# Compressed audio validation — 11 November 2026

## Change reviewed

The owner placed compressed runtime audio on `main` in commit `00c344c33d26bd745293b9d7a10b33d7e42ac894`. This validation package did not transcode the audio. Nine BGM MP3s and the victory MP3 now use 112 kbps; the 12-second coastal ambience WAV is stereo 22,050 Hz. Original masters are preserved under `assets/source-audio/original-bgm/` and `assets/source-audio/original-sfx/`. Two obsolete runtime BGM WAV fallbacks were removed, and `AudioManager.gd` now selects the existing MP3 tracks only. The five new BGM masters and victory master still match their six previously recorded SHA-256 values in [provenance](../assets/provenance.md).

| Measurement | Previous staging export | New local export | Difference |
| --- | ---: | ---: | ---: |
| Web PCK | 86,885,700 B (`cb5bd527…`) | 69,648,468 B (`cdbfac713fd72506e8458a9cd4fdfc0983f48f2cd805acdd0c9d61fc4f52106a`) | −17,237,232 B (−19.84%) |
| Ten MP3 source files | 38,562,205 B | 22,466,624 B | −16,095,581 B (−41.74%) |
| Imported MP3 streams in PCK | 38,565,574 B | 22,469,990 B | −16,095,584 B |

The new PCK inventory verified 699/699 payload MD5 values and its whole-file SHA-256. It contains 10 imported MP3 streams and 59 `.sample` resources. The source master archive is approximately 43 MB on the repository filesystem; it is not part of the Web PCK. The original provenance sentence claiming a “~23 MB” Web saving was corrected to the measured PCK difference.

## Verification

- FFmpeg 9.0.2 decoded all nine runtime BGM MP3s, the victory MP3, and the resampled coastal WAV with `-xerror` and no decoding errors. FFprobe 9.0.2 found equal original/new track durations to the displayed millisecond for all ten MP3s. This is structural validation, not a listening or perceptual-quality assessment.
- Godot 4.7.2 Web import/export completed with no `SCRIPT ERROR` or `ERROR:` in the build log. The generated PCK is the local candidate above; it has **not** been deployed.
- `npm run check:world` passed all 68 Godot scripts, including contextual BGM selection and Foley. The first attempt timed out after an assertion in `world-foley.gd`: it still expected 44,100 Hz for the ambience now intentionally authored at 22,050 Hz. The test now checks 22,050 Hz only for `ambient_coastal_waves` and retains 44,100 Hz for the other effects. The full serial rerun passed. Headless dummy-driver sample-playback warnings remain; they do not establish audible output.
- `npm run typecheck`, Web build, and API build passed. The first `npm test` attempt could not connect to the absent local MongoDB/Redis fixture and was stopped. A rerun with uniquely named, disposable MongoDB 8.0 and Redis 7.4 containers on the authorized `staginglocaldocker` host, connected through localhost-only SSH forwarding, passed **121/121** tests in 74.7 seconds. Both containers and the tunnel were removed; no production/staging container or data was touched.
- An additional direct static-server browser smoke did **not** reach game READY: the static server had no `/api/auth/session` endpoint, which returned 404 and caused a JSON parse error. This is a test-harness limitation, not evidence of an MP3 failure. No browser audio-playback result is claimed from that attempt.

Ignored local evidence: `.runtime/audio-compression-build-20261111.log`, `.runtime/audio-compression-world-rerun-20261111.log`, `.runtime/audio-compression-test-rerun-20261111.log`, `.runtime/audio-compression-pck-inventory-20261111.json`, and the typecheck log. The failed first-run logs are also retained locally. All tests were run against commit `00c344c` plus the test expectation correction; the documentation-only commit follows this report.

## Release boundary and next steps

Staging remains source `4980d6b172e7524fad8dbef3ea02e3916c4ea3c3`, image `sha256:10bcbab5484c0943a970f8d83819609138c016b5445c57d704414f7358d44a79`, PCK `cb5bd527bca632c66f2d23f7dc1a87758d2e4d057249a28d5efc4a40e3516b27`. The compressed PCK has not been pushed, packaged or installed on staging. Before release, run an authenticated browser smoke against a server with the matching export and API, inspect actual contextual playback/mute/reload, and listen to transitions and the victory jingle. Then pin the new PCK/source/image hashes, run Gitea CI, deploy with the established backup/rollback procedure, and perform public startup and saved-position smoke. Actual Samsung S23/Windows performance remains unmeasured. The `generate_audio.py` source generator can recreate the archived high-rate WAVs if invoked; avoid treating its output as the compressed runtime version without the corresponding transcode step.

Tools actually used for this validation: Git 2.54.0, Node 26.12.1/npm 11.20.0, Godot 4.7.2, Python 3, FFmpeg/FFprobe 9.0.2, Playwright Chromium with SwiftShader for the limited direct-page attempt, SSH, and disposable MongoDB/Redis containers. No image generation, Sprite AI, new audio source, or new dependency was used. Music authorship and rights remain as recorded in provenance.
