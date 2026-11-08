#!/usr/bin/env python3
"""Validate supplied exploration SFX and their deterministic PCM synthesis, without rewriting assets."""
import importlib.util
import math
from pathlib import Path
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("jalasmara_synthesis", ROOT / "scripts/generate_audio.py")
synth = importlib.util.module_from_spec(spec)
spec.loader.exec_module(synth)
NAMES = ["footstep_dock", "footstep_bridge", "footstep_sand", "footstep_stone", "footstep_water_shallow", "footstep_dirt", "punch_swing", "punch_hit", "hit_wood", "hit_stone", "machete_cut_bush", "wood_break_barricade", "boulder_push_slide", "path_reveal_chime"]
for name in NAMES:
    generated = getattr(synth, "gen_" + name)()
    assert generated and all(math.isfinite(value) for value in generated), name + ": nonfinite samples"
    assert max(map(abs, generated)) < 0.98, name + ": synthesis would clip before encoding"
    assert generated == getattr(synth, "gen_" + name)(), name + ": nondeterministic synthesis"
    with wave.open(str(ROOT / "client-godot/audio/sfx" / (name + ".wav")), "rb") as stream:
        assert stream.getcomptype() == "NONE" and stream.getsampwidth() == 2, name + ": expected PCM16 WAV"
        assert stream.getnchannels() == 1 and stream.getframerate() == synth.SAMPLE_RATE == 44100, name + ": unexpected channel/sample rate"
        assert stream.getnframes() == len(generated), name + ": generated duration differs from supplied asset"
        assert 0.08 <= stream.getnframes() / stream.getframerate() <= 1.2, name + ": unexpected duration"
        data = stream.readframes(stream.getnframes())
    samples = struct.unpack("<" + "h" * (len(data) // 2), data)
    assert all(abs(value) < 32760 for value in samples), name + ": clipped encoded samples"
    assert any(abs(value) > 1000 for value in samples), name + ": effectively silent"
    expected = b"".join(struct.pack("<h", int(value * 32767)) for value in generated)
    assert data == expected, name + ": supplied WAV does not match the checked source generator"
    print(name + ": PCM16/44.1kHz, duration, finite unclipped synthesis, deterministic matching samples PASS")
print("PASS audio synthesis: 14 supplied SFX, no clipping, byte-exact source reproduction; no files regenerated")
