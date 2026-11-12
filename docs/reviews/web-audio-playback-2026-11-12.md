# Web music playback repair, 12 November 2026

The owner reports that movement on Windows and Samsung S23 is mostly smooth, but music breaks up or sometimes does not start. This is the first real-device audio observation; the earlier compressed-audio checks only proved file decoding and build structure.

## Diagnosis and change

The active Godot Web export is single-threaded. `AudioManager.gd` explicitly forced BGM, long ambience, the victory jingle and environmental SFX to `PLAYBACK_TYPE_STREAM`. [Godot's audio documentation](https://docs.godotengine.org/en/stable/tutorials/audio/audio_streams.html) says the Web default uses browser sample playback to avoid garbled audio in single-threaded exports; forcing Stream raises latency and crackling risk. All nine BGM MP3s and the jingle still decode correctly, and the current source PCK includes them, so the playback mode is a concrete likely contributor. The user's exact failure was not captured with a browser audio trace, so this is a supported diagnosis, not a confirmed sole cause.

The audio players now use `PLAYBACK_TYPE_DEFAULT` for BGM, ambience, jingle, panic and environmental SFX. This resolves to the platform's Web sample path while retaining native stream behavior; UI SFX keep their explicit sample selection. A targeted Godot test guards against returning long-form audio to forced Stream. Diagnostics expose the current BGM playback type. On Web, Godot's sample path does not support bus effects, so the underwater low-pass effect may be less pronounced; that tradeoff requires listening review. This package changes no music files, source credits, game rules or player data.

## Checks and limits

- Godot 4.7.2 focused `audio-context.gd`: PASS for resource keys, contextual BGM, jingle duck/recovery and default playback mode.
- Full `npm run check:world`: PASS (70 Godot checks); `.runtime/audio-web-world-20261112.log` has no `SCRIPT ERROR` or `ERROR:`.
- `npm run build`: PASS; `.runtime/audio-web-build-20261112.log` has no `SCRIPT ERROR` or `ERROR:`. Local Web PCK SHA-256 `a1b3de0887e6130902fb5c1e51db6ac9cfac624757e6c1231231576f3da1d1a7`, 69,775,548 bytes. Six generated untracked `.gd.uid` files from the Godot check were removed; owner audit notes were untouched.
- CI, browser listening, real-device retest and staging release: pending. No statement about audible quality or physical FPS follows from headless tests.

Next: run GitHub Actions for the committed source, deploy only a verified candidate through the existing backup/rollback procedure, test title/day/forest/night/dive transitions and mute on actual Windows/S23. If long-track sample playback still stalls, move Web BGM to a browser-managed HTML audio path with a hashed/versioned manifest and on-demand loading, as previously scoped in [the startup payload audit](staging-startup-payload-2026-11-11.md). Do not swap assets or ship unverified remote audio URLs.
