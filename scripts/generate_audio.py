#!/usr/bin/env python3
"""
Generator Efek Suara (SFX) & Musik Latar (BGM) Prosedural Jalasmara
Menghasilkan berkas audio WAV 16-bit PCM tanpa dependensi eksternal.
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def write_wav(filename, samples, sample_rate=SAMPLE_RATE, channels=1):
    """Menyimpan array sample float (-1.0 s.d. 1.0) menjadi berkas WAV 16-bit PCM."""
    ensure_dir(os.path.dirname(filename))
    with wave.open(filename, 'w') as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(2) # 16-bit
        wf.setframerate(sample_rate)

        packed = bytearray()
        for s in samples:
            # Clamping
            s = max(-1.0, min(1.0, s))
            val = int(s * 32767.0)
            packed.extend(struct.pack('<h', val))
        wf.writeframes(packed)
    print(f"Generated: {filename} ({len(samples)/sample_rate:.2f}s, {channels}ch)")

def write_stereo_wav(filename, left_samples, right_samples, sample_rate=SAMPLE_RATE):
    """Menyimpan stereo WAV 16-bit."""
    ensure_dir(os.path.dirname(filename))
    with wave.open(filename, 'w') as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)

        packed = bytearray()
        for l, r in zip(left_samples, right_samples):
            l = max(-1.0, min(1.0, l))
            r = max(-1.0, min(1.0, r))
            packed.extend(struct.pack('<hh', int(l * 32767.0), int(r * 32767.0)))
        wf.writeframes(packed)
    print(f"Generated Stereo: {filename} ({len(left_samples)/sample_rate:.2f}s)")

# ----------------- SFX GENERATORS -----------------

def gen_bubble_pop():
    """Letupan gelembung air (pitch sweep naik cepat dengan decay eksponensial)."""
    dur = 0.16
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # Frekuensi naik melengkung dari 450Hz ke 1600Hz
        freq = 450.0 + 1150.0 * math.pow(t / dur, 0.6)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        # Envelope: instan naik, decay eksponensial cepat
        env = math.exp(-22.0 * t)
        # Karakter suara: gelombang sinus dengan sentuhan harmonik ke-2 tipis
        val = (math.sin(phase) + 0.25 * math.sin(phase * 2.0)) * env
        samples.append(val * 0.75)
    return samples

def gen_water_splash():
    """Percikan air saat melompat terjun ke laut (thud benturan + desis buih)."""
    dur = 0.65
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase_thud = 0.0
    # Random seed konsisten
    rnd = random.Random(42)
    last_noise = 0.0

    for i in range(n):
        t = i / SAMPLE_RATE
        # 1. Hantaman massa air (low frequency plunge punch 110Hz -> 35Hz)
        freq_thud = 110.0 * math.exp(-12.0 * t) + 35.0
        phase_thud += 2.0 * math.pi * freq_thud / SAMPLE_RATE
        thud = math.sin(phase_thud) * math.exp(-9.0 * t) * 0.6

        # 2. Desis busa/percikan air (filtered noise)
        raw_noise = rnd.uniform(-1.0, 1.0)
        # Low-pass filter sederhana
        noise = last_noise + 0.15 * (raw_noise - last_noise)
        last_noise = noise
        spray = noise * math.pow(t / 0.05, 1.0) * math.exp(-7.0 * t) if t < 0.05 else noise * math.exp(-6.0 * t)

        # 3. Micro bubble gurgles
        gurgle = math.sin(2.0 * math.pi * 700.0 * t) * math.exp(-15.0 * t) * 0.2 if t > 0.08 else 0.0

        val = (thud + spray * 0.7 + gurgle) * 0.85
        samples.append(val)
    return samples

def gen_player_hit():
    """Efek saat Nala terkena serangan atau benturan batu keras (punchy impact thud)."""
    dur = 0.38
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    rnd = random.Random(1337)

    for i in range(n):
        t = i / SAMPLE_RATE
        # Pitch drop cepat dari 160Hz ke 32Hz (memberi bobot berat)
        freq = 160.0 * math.exp(-14.0 * t) + 32.0
        phase += 2.0 * math.pi * freq / SAMPLE_RATE

        # Distorsi saturasi lembut (soft clipping)
        raw_sine = math.sin(phase)
        distorted = math.tanh(raw_sine * 2.5) * 0.65

        # Noise benturan awal (transient click)
        noise = rnd.uniform(-1.0, 1.0) * math.exp(-35.0 * t) * 0.45

        env = math.exp(-8.5 * t)
        val = (distorted + noise) * env
        samples.append(val * 0.8)
    return samples

def gen_diver_breath():
    """Napas tarikan udara regulator selam Nala (filtered rhythmic air hiss)."""
    dur = 1.25
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(99)
    last_val = 0.0

    for i in range(n):
        t = i / SAMPLE_RATE
        # Envelope: hisapan napas naik perlahan lalu mengecil
        if t < 0.4:
            env = math.sin((t / 0.4) * (math.pi / 2.0))
        else:
            env = math.exp(-4.0 * (t - 0.4))

        raw = rnd.uniform(-1.0, 1.0)
        # Resonant band-pass filter approximation
        last_val = last_val + 0.18 * (raw - last_val)
        val = last_val * env * 0.5
        samples.append(val)
    return samples

def gen_harpoon_shoot():
    """Tembakan jala/harpun pneumatik bawah air (pneumatic hiss + snap)."""
    dur = 0.28
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    rnd = random.Random(777)

    for i in range(n):
        t = i / SAMPLE_RATE
        # Downward snap 1400Hz -> 180Hz
        freq = 1400.0 * math.exp(-18.0 * t) + 180.0
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        snap = math.sin(phase) * math.exp(-16.0 * t) * 0.55

        # Air release hiss
        hiss = rnd.uniform(-1.0, 1.0) * math.exp(-12.0 * t) * 0.35
        samples.append((snap + hiss) * 0.8)
    return samples

def gen_coin_collect():
    """Koleksi koin/pendapatan penjualan kedai (two-tone bright chime)."""
    dur = 0.38
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase1 = 0.0
    phase2 = 0.0

    f1 = 987.77 # B5
    f2 = 1318.51 # E6

    for i in range(n):
        t = i / SAMPLE_RATE
        if t < 0.09:
            phase1 += 2.0 * math.pi * f1 / SAMPLE_RATE
            env1 = math.exp(-10.0 * t)
            val = (math.sin(phase1) + 0.3 * math.sin(phase1 * 2.0)) * env1
        else:
            t2 = t - 0.09
            phase2 += 2.0 * math.pi * f2 / SAMPLE_RATE
            env2 = math.exp(-8.0 * t2)
            val = (math.sin(phase2) + 0.25 * math.sin(phase2 * 2.0)) * env2
        samples.append(val * 0.55)
    return samples

def gen_item_pickup():
    """Mengambil bahan laut atau ramuan jamu (cheerful tri-tone arpeggio)."""
    dur = 0.24
    n = int(SAMPLE_RATE * dur)
    samples = []
    freqs = [523.25, 659.25, 783.99] # C5, E5, G5
    step_dur = 0.07
    phases = [0.0, 0.0, 0.0]

    for i in range(n):
        t = i / SAMPLE_RATE
        idx = min(int(t / step_dur), 2)
        f = freqs[idx]
        t_note = t - (idx * step_dur)
        phases[idx] += 2.0 * math.pi * f / SAMPLE_RATE
        env = math.exp(-12.0 * t_note)
        val = math.sin(phases[idx]) * env * 0.5
        samples.append(val)
    return samples

def gen_oxygen_alarm():
    """Sirene peringatan bahaya oksigen menipis (urgent alternating electronic beep)."""
    dur = 0.48
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0

    for i in range(n):
        t = i / SAMPLE_RATE
        # 4 nada berulang cepat
        cycle = t % 0.12
        if cycle < 0.08:
            # Bergantian antara 1760 Hz dan 2200 Hz
            f = 2200.0 if t > 0.24 else 1760.0
            phase += 2.0 * math.pi * f / SAMPLE_RATE
            val = (1.0 if math.sin(phase) > 0 else -1.0) * 0.28 # Pulse square wave
        else:
            val = 0.0
        samples.append(val)
    return samples

def gen_heartbeat():
    """Detak jantung dalam helm saat oksigen kritis (heavy sub-bass lub-dub)."""
    dur = 0.75 # ~80 BPM loopable pulse
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase1 = 0.0
    phase2 = 0.0

    for i in range(n):
        t = i / SAMPLE_RATE
        val = 0.0
        # Thump 1 (Lub) di t = 0.0
        if t < 0.18:
            f = 58.0 * math.exp(-8.0 * t) + 38.0
            phase1 += 2.0 * math.pi * f / SAMPLE_RATE
            val += math.sin(phase1) * math.exp(-14.0 * t) * 0.75

        # Thump 2 (Dub) di t = 0.24
        if 0.22 <= t < 0.40:
            t2 = t - 0.22
            f = 50.0 * math.exp(-9.0 * t2) + 32.0
            phase2 += 2.0 * math.pi * f / SAMPLE_RATE
            val += math.sin(phase2) * math.exp(-15.0 * t2) * 0.58

        samples.append(val)
    return samples

def gen_menu_click():
    """Klik tombol kayu/antarmuka HUD (crisp tactile wooden tap)."""
    dur = 0.05
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 1100.0 * math.exp(-35.0 * t) + 400.0
        phase += 2.0 * math.pi * f / SAMPLE_RATE
        val = math.sin(phase) * math.exp(-55.0 * t) * 0.4
        samples.append(val)
    return samples

def gen_boss_roar():
    """Raungan monster laut purba / Gajah Mina (sub-bass rumble + cavitation frequency modulation)."""
    dur = 2.0
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase_carrier = 0.0
    phase_mod = 0.0
    rnd = random.Random(666)
    last_n = 0.0

    for i in range(n):
        t = i / SAMPLE_RATE
        # Envelope: swell pelan, tahan, fade out
        if t < 0.4:
            env = t / 0.4
        elif t < 1.4:
            env = 1.0
        else:
            env = math.exp(-4.0 * (t - 1.4))

        # Frequency Modulation synthesis (FM)
        phase_mod += 2.0 * math.pi * 14.0 / SAMPLE_RATE
        mod_val = math.sin(phase_mod) * 18.0

        freq_carrier = 48.0 + mod_val
        phase_carrier += 2.0 * math.pi * freq_carrier / SAMPLE_RATE
        carrier = math.sin(phase_carrier)

        # Noise rumble
        raw_n = rnd.uniform(-1.0, 1.0)
        last_n = last_n + 0.08 * (raw_n - last_n)

        # Saturasi overdrive tebal
        mixed = carrier * 0.7 + last_n * 0.5
        val = math.tanh(mixed * 2.2) * env * 0.8
        samples.append(val)
    return samples

# ----------------- SFX SWOOSH, WHOOSH, SWISH & PUKULAN TAMBAHAN -----------------

def gen_swoosh_light():
    """Tebasan cepat senjata/tangan di udara (swish / wish lincah)."""
    dur = 0.18
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(21)
    phase = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        prog = t / dur
        # Lengkungan amplitudo: naik cepat ke puncak 40%, lalu luruh
        amp = math.pow(math.sin(math.pi * prog), 1.6)
        # Sapuan frekuensi formant (600Hz -> 2400Hz -> 450Hz)
        cf = 500.0 + 1900.0 * math.pow(math.sin(math.pi * prog), 2.2)
        phase += 2.0 * math.pi * cf / SAMPLE_RATE
        raw = rnd.uniform(-1.0, 1.0)
        core = raw * (0.65 + 0.35 * math.sin(phase))
        lp += 0.32 * (core - lp)
        samples.append(lp * amp * 0.85)
    return samples

def gen_swoosh_heavy():
    """Ayunan gada kayu berat / kibasan ekor monster (whoosh / swosh dalam bertenaga)."""
    dur = 0.35
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(55)
    phase_wind = 0.0
    phase_sub = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        prog = t / dur
        amp = math.pow(math.sin(math.pi * prog), 1.4)

        # 1. Resonansi desau angin berat (120Hz -> 680Hz -> 90Hz)
        cf = 120.0 + 560.0 * math.sin(math.pi * prog)
        phase_wind += 2.0 * math.pi * cf / SAMPLE_RATE
        raw = rnd.uniform(-1.0, 1.0)
        core = raw * (0.5 + 0.5 * math.sin(phase_wind))
        lp += 0.18 * (core - lp)

        # 2. Desakan massa udara rendah (sub-bass sine 75Hz -> 140Hz -> 45Hz)
        f_sub = 75.0 + 65.0 * math.sin(math.pi * prog)
        phase_sub += 2.0 * math.pi * f_sub / SAMPLE_RATE
        sub = math.sin(phase_sub) * 0.45

        val = (lp * 0.75 + sub) * amp
        samples.append(val * 0.9)
    return samples

def gen_swoosh_water():
    """Manuver renang cepat / dash pendorong sirip di bawah air (swosh fluida bergelembung)."""
    dur = 0.32
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(88)
    lp = 0.0
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        prog = t / dur
        amp = math.pow(math.sin(math.pi * prog), 1.3)
        # Sapuan frekuensi rendah teredam air (90Hz -> 420Hz -> 80Hz)
        cf = 90.0 + 330.0 * math.sin(math.pi * prog)
        phase += 2.0 * math.pi * cf / SAMPLE_RATE
        raw = rnd.uniform(-1.0, 1.0)
        # Low-pass ganda untuk efek kedap air
        lp += 0.12 * (raw - lp)
        water_swish = lp * (0.7 + 0.3 * math.sin(phase))

        # Jejak gelembung mikro di sepertiga akhir durasi
        bubble = 0.0
        if t > 0.18:
            dt_b = (t - 0.18) * 4.0
            bubble = math.sin(2.0 * math.pi * 950.0 * t) * math.exp(-14.0 * (dt_b % 0.06)) * 0.22

        samples.append((water_swish * 1.1 + bubble) * amp)
    return samples

def gen_dodge_swish():
    """Gerakan menghindar / dash darat tangkas (swesh lincah)."""
    dur = 0.16
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(333)
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # Serangan sangat cepat, luruh tajam
        if t < 0.04:
            amp = t / 0.04
        else:
            amp = math.exp(-18.0 * (t - 0.04))
        raw = rnd.uniform(-1.0, 1.0)
        lp += 0.45 * (raw - lp) # Karakter renyah
        samples.append(lp * amp * 0.8)
    return samples

def gen_net_throw():
    """Lemparan jala ikan membentang di udara/air (fwoosh-shhh terkembang)."""
    dur = 0.32
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(404)
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        prog = t / dur
        amp = math.sin(math.pi * prog)
        # Desau kain/tali jala bergetar
        flutter = math.sin(2.0 * math.pi * 35.0 * t) * 0.25
        raw = rnd.uniform(-1.0, 1.0)
        lp += 0.22 * (raw - lp)
        val = lp * (0.8 + flutter) * amp
        samples.append(val * 0.75)
    return samples

def gen_hit_heavy():
    """Hantaman pukulan berat / gada tumpul (kra-thud dengan getaran sub-bass)."""
    dur = 0.34
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    rnd = random.Random(505)
    for i in range(n):
        t = i / SAMPLE_RATE
        # Pitch drop cepat dari 180Hz ke 26Hz
        freq = 180.0 * math.exp(-16.0 * t) + 26.0
        phase += 2.0 * math.pi * freq / SAMPLE_RATE

        # Distorsi hantaman keras (hard saturation)
        raw_core = math.sin(phase)
        distorted = math.tanh(raw_core * 3.5) * 0.75

        # Retakan getaran awal (crack transient)
        crack = rnd.uniform(-1.0, 1.0) * math.exp(-45.0 * t) * 0.55

        env = math.exp(-8.0 * t)
        samples.append((distorted + crack) * env * 0.85)
    return samples

def gen_hit_flesh():
    """Pukulan mengenai daging monster laut / ikan berlendir (splat-thud basah)."""
    dur = 0.22
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    rnd = random.Random(606)
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 140.0 * math.exp(-18.0 * t) + 45.0
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        punch = math.sin(phase) * math.exp(-12.0 * t) * 0.6

        # Percikan lendir / squish noise
        raw = rnd.uniform(-1.0, 1.0)
        lp += 0.15 * (raw - lp)
        squish = lp * math.exp(-15.0 * t) * 0.5

        samples.append((punch + squish) * 0.8)
    return samples

def gen_hit_critical():
    """Serangan kritikal telak (dentuman keras + lentingan lonceng logam jernih)."""
    dur = 0.38
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase_thud = 0.0
    phase_chime = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # Benturan dasar
        freq_thud = 220.0 * math.exp(-22.0 * t) + 38.0
        phase_thud += 2.0 * math.pi * freq_thud / SAMPLE_RATE
        thud = math.tanh(math.sin(phase_thud) * 3.0) * math.exp(-10.0 * t) * 0.6

        # Lentingan kritikal bernada tinggi (1860Hz)
        phase_chime += 2.0 * math.pi * 1860.0 / SAMPLE_RATE
        chime = math.sin(phase_chime) * math.exp(-6.5 * t) * 0.45

        samples.append((thud + chime) * 0.85)
    return samples

def gen_hit_shield():
    """Tangkisan perisai / cangkang penyu (dentang kayu/logam padat menepis serangan)."""
    dur = 0.22
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase1 = 0.0
    phase2 = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        phase1 += 2.0 * math.pi * 480.0 / SAMPLE_RATE
        phase2 += 2.0 * math.pi * 960.0 / SAMPLE_RATE
        clang = (math.sin(phase1) + 0.4 * math.sin(phase2)) * math.exp(-16.0 * t) * 0.7
        samples.append(clang)
    return samples

def gen_knife_slash():
    """Sayatan pisau tajam pada tanaman air / tali jala (shing-slice berdesis)."""
    dur = 0.22
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(707)
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # Sapuan nada tajam 2200Hz turun ke 800Hz
        freq = 2200.0 * math.exp(-12.0 * t) + 800.0
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        tone = math.sin(phase) * 0.35
        noise = rnd.uniform(-1.0, 1.0) * 0.55
        env = math.exp(-14.0 * t)
        samples.append((tone + noise) * env * 0.8)
    return samples

def gen_monster_bite():
    """Caplokan rahang bergigi predator laut (klik taring tajam + katupan rahang berat)."""
    dur = 0.25
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase_snap = 0.0
    phase_jaw = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # 1. Klik gigi berbenturan (snap 1300Hz)
        phase_snap += 2.0 * math.pi * 1300.0 / SAMPLE_RATE
        snap = math.sin(phase_snap) * math.exp(-40.0 * t) * 0.55

        # 2. Katupan rahang berat (62Hz)
        phase_jaw += 2.0 * math.pi * 62.0 / SAMPLE_RATE
        jaw = math.tanh(math.sin(phase_jaw) * 2.0) * math.exp(-11.0 * t) * 0.65

        samples.append((snap + jaw) * 0.85)
    return samples

def gen_rock_smash():
    """Hancuran batu karang runtuh / benturan pilar (crash bergemuruh)."""
    dur = 0.45
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    rnd = random.Random(808)
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 110.0 * math.exp(-10.0 * t) + 30.0
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        impact = math.sin(phase) * math.exp(-7.0 * t) * 0.65

        raw = rnd.uniform(-1.0, 1.0)
        lp += 0.2 * (raw - lp)
        gravel = lp * math.exp(-5.0 * t) * 0.5

        samples.append((impact + gravel) * 0.8)
    return samples

def gen_footstep_grass():
    """Langkah kaki di tanah/rumput desa pesisir (gesekan lembut taktil)."""
    dur = 0.12
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(909)
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-25.0 * t)
        raw = rnd.uniform(-1.0, 1.0)
        lp += 0.25 * (raw - lp)
        samples.append(lp * env * 0.45)
    return samples

def gen_footstep_wood():
    """Langkah kaki di atas papan kayu dermaga (ketukan berongga tok-clop)."""
    dur = 0.10
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 380.0 * math.exp(-28.0 * t) + 120.0
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        env = math.exp(-32.0 * t)
        samples.append(math.sin(phase) * env * 0.5)
    return samples

# ----------------- SFX LANGKAH KAKI BERAGAM PERMUKAAN -----------------

def gen_footstep_dock():
    """Langkah kaki di papan kayu dermaga (pantulan kayu berongga + riak air halus di kolong)."""
    dur = 0.16
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(1111)
    phase_wood1 = 0.0
    phase_wood2 = 0.0
    water_lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # 1. Hentakan kayu papan berongga (dua nada resonan 310Hz & 155Hz turun cepat)
        freq1 = 310.0 * math.exp(-26.0 * t) + 110.0
        freq2 = 155.0 * math.exp(-22.0 * t) + 65.0
        phase_wood1 += 2.0 * math.pi * freq1 / SAMPLE_RATE
        phase_wood2 += 2.0 * math.pi * freq2 / SAMPLE_RATE
        env_wood = math.exp(-28.0 * t)
        wood_tap = (0.6 * math.sin(phase_wood1) + 0.4 * math.sin(phase_wood2)) * env_wood

        # 2. Sentuhan riak air mikro di bawah tiang pancang dermaga (t: 0.03 - 0.15s)
        water_val = 0.0
        if t > 0.03:
            dt = t - 0.03
            raw_noise = rnd.uniform(-1.0, 1.0)
            water_lp += 0.18 * (raw_noise - water_lp)
            water_env = math.sin(math.pi * min(1.0, dt / 0.11)) * math.exp(-12.0 * dt)
            water_val = water_lp * water_env * 0.35

        samples.append((wood_tap * 0.75 + water_val) * 0.85)
    return samples

def gen_footstep_bridge():
    """Langkah kaki di jembatan gantung kayu / tangga pondok (kayu melentur berderit tipis)."""
    dur = 0.18
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(2222)
    phase = 0.0
    creak_phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # Ketukan kayu lentur
        freq = 270.0 * math.exp(-20.0 * t) + 95.0
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        env = math.exp(-24.0 * t)
        wood = math.sin(phase) * env * 0.6

        # Deritan mikro serat kayu meregang (frekuensi tinggi modulasi cepat)
        creak_freq = 680.0 + 80.0 * math.sin(2.0 * math.pi * 35.0 * t)
        creak_phase += 2.0 * math.pi * creak_freq / SAMPLE_RATE
        creak_env = math.sin(math.pi * min(1.0, t / 0.16)) * math.exp(-8.0 * t)
        creak = (math.sin(creak_phase) * 0.25 + rnd.uniform(-0.1, 0.1)) * creak_env * 0.4

        samples.append((wood + creak) * 0.8)
    return samples

def gen_footstep_sand():
    """Langkah kaki di pasir pantai pesisir (gesekan butir pasir berdesis halus)."""
    dur = 0.14
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(3333)
    hp = 0.0
    thud_phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # Hentakan lembut tumit di pasir
        thud_phase += 2.0 * math.pi * (90.0 * math.exp(-35.0 * t) + 40.0) / SAMPLE_RATE
        thud = math.sin(thud_phase) * math.exp(-30.0 * t) * 0.35

        # Gesekan butiran pasir (high-pass noise)
        raw = rnd.uniform(-1.0, 1.0)
        hp = raw - 0.75 * hp
        sand_env = math.sin(math.pi * min(1.0, t / 0.12)) * math.exp(-15.0 * t)
        sand = hp * sand_env * 0.45

        samples.append((thud + sand) * 0.8)
    return samples

def gen_footstep_stone():
    """Langkah kaki di lantai batu candi / batuan karang tebing (benturan padat berdenting pendek)."""
    dur = 0.11
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase1 = 0.0
    phase2 = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        phase1 += 2.0 * math.pi * 780.0 / SAMPLE_RATE
        phase2 += 2.0 * math.pi * 1450.0 / SAMPLE_RATE
        click = (math.sin(phase1) + 0.35 * math.sin(phase2)) * math.exp(-48.0 * t) * 0.45

        freq_thud = 180.0 * math.exp(-32.0 * t) + 60.0
        thud = math.sin(2.0 * math.pi * freq_thud * t) * math.exp(-30.0 * t) * 0.45
        samples.append((click + thud) * 0.75)
    return samples

def gen_footstep_water_shallow():
    """Langkah kaki menciprat di genangan air dangkal / tepian rawa muara (splosh)."""
    dur = 0.19
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(4444)
    bubble_phase = 0.0
    noise_lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # Gelembung/desakan air menciprat naik
        bubble_freq = 380.0 + 550.0 * (t / dur)
        bubble_phase += 2.0 * math.pi * bubble_freq / SAMPLE_RATE
        bubble = math.sin(bubble_phase) * math.exp(-16.0 * t) * 0.45

        # Cipratan air (noise bandpass)
        raw = rnd.uniform(-1.0, 1.0)
        noise_lp += 0.3 * (raw - noise_lp)
        splash_env = math.sin(math.pi * min(1.0, t / 0.16)) * math.exp(-11.0 * t)
        splash = noise_lp * splash_env * 0.55

        samples.append((bubble + splash) * 0.8)
    return samples

def gen_footstep_dirt():
    """Langkah kaki di tanah padat jalan setapak hutan mangrove."""
    dur = 0.13
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(5555)
    phase = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 135.0 * math.exp(-26.0 * t) + 45.0
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        thud = math.sin(phase) * math.exp(-24.0 * t) * 0.6

        raw = rnd.uniform(-1.0, 1.0)
        lp += 0.15 * (raw - lp)
        dirt = lp * math.exp(-22.0 * t) * 0.35

        samples.append((thud + dirt) * 0.75)
    return samples

# ----------------- SFX PUKULAN & MEMBUKA JALAN -----------------

def gen_punch_swing():
    """Desau ayunan pukulan cepat tangan kosong (fist whoosh pendek)."""
    dur = 0.15
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(6666)
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # Sapuan nada 520Hz turun ke 130Hz
        freq = 520.0 * math.exp(-12.0 * t) + 130.0
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        tone = math.sin(phase) * 0.4
        noise = rnd.uniform(-1.0, 1.0) * 0.35
        env = math.sin(math.pi * (t / dur))
        samples.append((tone + noise) * env * 0.8)
    return samples

def gen_punch_hit():
    """Bogem mentah mendarat telak pada sasaran / musuh (daging padat + sentakan tumpul)."""
    dur = 0.22
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    snap_phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # Benturan tumpul berbobot
        freq = 190.0 * math.exp(-18.0 * t) + 42.0
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        thud = math.tanh(math.sin(phase) * 2.5) * math.exp(-12.0 * t) * 0.65

        # Sentakan kontak awal (snap)
        snap_phase += 2.0 * math.pi * 820.0 / SAMPLE_RATE
        snap = math.sin(snap_phase) * math.exp(-45.0 * t) * 0.35

        samples.append((thud + snap) * 0.85)
    return samples

def gen_hit_wood():
    """Pukulan / hantaman beliung menghantam kayu balok, tiang atau pagar (clack beresonansi)."""
    dur = 0.20
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(7777)
    phase1 = 0.0
    phase2 = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        freq1 = 580.0 * math.exp(-24.0 * t) + 210.0
        freq2 = 290.0 * math.exp(-18.0 * t) + 105.0
        phase1 += 2.0 * math.pi * freq1 / SAMPLE_RATE
        phase2 += 2.0 * math.pi * freq2 / SAMPLE_RATE
        wood = (math.sin(phase1) + 0.5 * math.sin(phase2)) * math.exp(-18.0 * t) * 0.65

        crack = rnd.uniform(-1.0, 1.0) * math.exp(-38.0 * t) * 0.35
        samples.append((wood + crack) * 0.79)
    return samples

def gen_hit_stone():
    """Pukulan beliung / senjata menghantam batu karang kokoh (denting lentingan kerikil tajam)."""
    dur = 0.22
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase_chink = 0.0
    phase_mass = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # Lentingan keras batu (1650Hz + 2700Hz)
        phase_chink += 2.0 * math.pi * 1650.0 / SAMPLE_RATE
        chink = (math.sin(phase_chink) + 0.3 * math.sin(phase_chink * 1.63)) * math.exp(-32.0 * t) * 0.5

        # Massa batu dasar
        phase_mass += 2.0 * math.pi * 135.0 / SAMPLE_RATE
        mass = math.sin(phase_mass) * math.exp(-14.0 * t) * 0.4

        samples.append((chink + mass) * 0.85)
    return samples

def gen_machete_cut_bush():
    """Tebasan parang memotong semak belukar rimbun / liana untuk membuka jalan di hutan."""
    dur = 0.32
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(8888)
    phase_blade = 0.0
    rustle_lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # 1. Tebasan pisau tajam (slice 2200Hz -> 850Hz)
        freq_blade = 2200.0 * math.exp(-15.0 * t) + 850.0
        phase_blade += 2.0 * math.pi * freq_blade / SAMPLE_RATE
        blade = math.sin(phase_blade) * math.exp(-18.0 * t) * 0.45

        # 2. Gemerisik daun dan ranting putus rontok
        raw = rnd.uniform(-1.0, 1.0)
        rustle_lp += 0.25 * (raw - rustle_lp)
        rustle_env = math.sin(math.pi * min(1.0, t / 0.28)) * math.exp(-9.0 * t)
        rustle = rustle_lp * rustle_env * 0.55

        samples.append((blade + rustle) * 0.85)
    return samples

def gen_wood_break_barricade():
    """Hancuran barikade kayu lapuk / pintu pagar patah berkeping membuka jalan tembus."""
    dur = 0.48
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(9999)
    thud_phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # Hantaman awal patah
        freq = 175.0 * math.exp(-14.0 * t) + 40.0
        thud_phase += 2.0 * math.pi * freq / SAMPLE_RATE
        thud = math.tanh(math.sin(thud_phase) * 2.0) * math.exp(-10.0 * t) * 0.6

        # Serpihan kayu berderak berurutan (crackles)
        splinters = 0.0
        for trigger_t in [0.02, 0.07, 0.14, 0.21, 0.29]:
            if t >= trigger_t:
                dt = t - trigger_t
                c_freq = 420.0 + (trigger_t * 600.0)
                splinters += math.sin(2.0 * math.pi * c_freq * dt) * math.exp(-35.0 * dt) * 0.25
                splinters += rnd.uniform(-0.15, 0.15) * math.exp(-25.0 * dt)

        samples.append((thud + splinters) * 0.8)
    return samples

def gen_boulder_push_slide():
    """Gesekan batu monolit raksasa didorong / digeser membuka jalan tembus reruntuhan candi."""
    dur = 0.70
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(1234)
    lp1 = 0.0
    lp2 = 0.0
    phase_sub = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # Sub-bass massa batu bergeser (55Hz)
        phase_sub += 2.0 * math.pi * 55.0 / SAMPLE_RATE
        sub = math.sin(phase_sub) * 0.35

        # Grating friction (gesekan butiran batu kasar)
        raw = rnd.uniform(-1.0, 1.0)
        lp1 += 0.12 * (raw - lp1)
        lp2 += 0.22 * (raw - lp2)
        grating = (lp1 * 0.6 + lp2 * 0.4)

        # Envelope geseran
        env = math.sin(math.pi * min(1.0, t / 0.65)) * (1.0 if t < 0.55 else math.exp(-12.0 * (t - 0.55)))
        samples.append((sub + grating * 0.65) * env * 0.85)
    return samples

def gen_path_reveal_chime():
    """Lentingan jingle magis saat jalan setapak rahasia / rute baru berhasil dibuka."""
    dur = 0.95
    n = int(SAMPLE_RATE * dur)
    samples = []
    # Arpeggio mistis bernuansa pelog bahari: E4, G4, A4, B4, D5, E5
    notes = [
        (0.00, 329.63), # E4
        (0.12, 392.00), # G4
        (0.24, 440.00), # A4
        (0.36, 493.88), # B4
        (0.48, 587.33), # D5
        (0.60, 659.25)  # E5 tahan
    ]
    phases = [0.0] * len(notes)
    for i in range(n):
        t = i / SAMPLE_RATE
        val = 0.0
        for idx, (st, f) in enumerate(notes):
            if t >= st:
                dt = t - st
                phases[idx] += 2.0 * math.pi * f / SAMPLE_RATE
                env = math.exp(-4.2 * dt)
                # Harmoni lonceng berkilau
                bell = math.sin(phases[idx]) + 0.35 * math.sin(phases[idx] * 2.0) + 0.15 * math.sin(phases[idx] * 3.0)
                val += bell * env * 0.28
        samples.append(val * 0.85)
    return samples

def gen_quest_complete():
    """Fanfare kemenangan misi / penemuan pusaka bahari (5 nada pentatonik maritim)."""
    dur = 0.70
    n = int(SAMPLE_RATE * dur)
    samples = []
    # Nada cerah D mayor pentatonik: D4, F#4, A4, B4, D5
    notes = [
        (0.00, 293.66), # D4
        (0.10, 369.99), # F#4
        (0.20, 440.00), # A4
        (0.30, 493.88), # B4
        (0.42, 587.33)  # D5 tahan
    ]
    phases = [0.0] * len(notes)
    for i in range(n):
        t = i / SAMPLE_RATE
        val = 0.0
        for idx, (st, f) in enumerate(notes):
            if t >= st:
                dt = t - st
                phases[idx] += 2.0 * math.pi * f / SAMPLE_RATE
                env = math.exp(-5.5 * dt)
                # Harmoni lonceng
                val += (math.sin(phases[idx]) + 0.3 * math.sin(phases[idx] * 2.0)) * env * 0.32
        samples.append(val)
    return samples

# ----------------- SFX LEDAKAN, PINTU, KAYU & INTERAKSI MEKANIKAL -----------------

def gen_explosion_heavy():
    """Ledakan masif di daratan / bom peledak (boooom menggelegar + serpihan retak)."""
    dur = 1.35
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    rnd = random.Random(111)
    lp_noise = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # 1. Hantaman bola api awal (sub-bass punch 160Hz -> 22Hz)
        freq = 160.0 * math.exp(-14.0 * t) + 22.0
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        core = math.sin(phase) * math.exp(-4.5 * t)

        # 2. Desauan gelombang kejut & serpihan debu meletup (debris crackle)
        raw_n = rnd.uniform(-1.0, 1.0)
        lp_noise += 0.18 * (raw_n - lp_noise)
        debris = lp_noise * math.exp(-3.2 * t)

        # Distorsi overdrive tebal
        mixed = core * 0.8 + debris * 0.6
        val = math.tanh(mixed * 3.5) * math.exp(-2.5 * t)
        samples.append(val * 0.95)
    return samples

def gen_underwater_boom():
    """Ledakan terendam di bawah air / ranjau laut (dhoooom kedap air berat + kavitasi)."""
    dur = 1.50
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase_sub = 0.0
    phase_mod = 0.0
    rnd = random.Random(222)
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # Modulasi rongga air (cavitation pulse 9Hz)
        phase_mod += 2.0 * math.pi * 9.0 / SAMPLE_RATE
        mod = math.sin(phase_mod) * 12.0

        freq = 38.0 + mod
        phase_sub += 2.0 * math.pi * freq / SAMPLE_RATE
        sub = math.sin(phase_sub) * math.exp(-2.2 * t)

        # Gemuruh air diredam (low-pass filter ketat)
        raw = rnd.uniform(-1.0, 1.0)
        lp += 0.04 * (raw - lp) # cutoff sangat rendah khas air dalam
        water_rumble = lp * math.exp(-2.0 * t) * 1.5

        val = math.tanh((sub * 0.75 + water_rumble * 0.6) * 2.8) * math.exp(-1.8 * t)
        samples.append(val * 0.9)
    return samples

def gen_door_open_wood():
    """Membuka pintu kayu rumah panggung berderit (deritan engsel kayu + pelepasan kusen)."""
    dur = 0.46
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase_creak = 0.0
    rnd = random.Random(333)
    for i in range(n):
        t = i / SAMPLE_RATE
        # Derit gesekan kayu dengan micro-jitter (260Hz - 420Hz)
        jitter = rnd.uniform(-25.0, 25.0)
        f_creak = 280.0 + math.sin(t * 45.0) * 110.0 + jitter
        phase_creak += 2.0 * math.pi * f_creak / SAMPLE_RATE
        env_creak = math.sin(math.pi * (t / 0.38)) if t < 0.38 else 0.0
        creak = math.sin(phase_creak) * env_creak * 0.45

        # Ketukan lepas kusen di akhir (wooden frame release tap)
        tap = 0.0
        if 0.32 <= t < 0.42:
            dt = t - 0.32
            tap = math.sin(2.0 * math.pi * 380.0 * dt) * math.exp(-35.0 * dt) * 0.4

        samples.append(creak + tap)
    return samples

def gen_door_close_wood():
    """Menutup pintu kayu panggung rapat (dentum kayu solid + klik grendel kayu)."""
    dur = 0.35
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase_thud = 0.0
    phase_latch = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # 1. Hantaman pintu kayu rapat (110Hz -> 45Hz)
        f_thud = 110.0 * math.exp(-22.0 * t) + 45.0
        phase_thud += 2.0 * math.pi * f_thud / SAMPLE_RATE
        thud = math.tanh(math.sin(phase_thud) * 2.2) * math.exp(-14.0 * t) * 0.7

        # 2. Klik grendel/selot kayu (850Hz)
        latch = 0.0
        if 0.03 <= t < 0.15:
            dt = t - 0.03
            f_latch = 850.0 * math.exp(-30.0 * dt) + 320.0
            phase_latch += 2.0 * math.pi * f_latch / SAMPLE_RATE
            latch = math.sin(phase_latch) * math.exp(-38.0 * dt) * 0.45

        samples.append(thud + latch)
    return samples

def gen_chest_open():
    """Membuka peti kayu peninggalan purba / peti bahan (derit tutup kayu + bunyi engsel)."""
    dur = 0.52
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    rnd = random.Random(444)
    for i in range(n):
        t = i / SAMPLE_RATE
        prog = t / dur
        # Derit tarikan engsel peti
        f = 310.0 + math.sin(prog * 18.0) * 85.0 + rnd.uniform(-15.0, 15.0)
        phase += 2.0 * math.pi * f / SAMPLE_RATE
        env = math.sin(math.pi * prog)
        creak = math.sin(phase) * env * 0.45

        # Lentingan kunci peti terbuka tipis di awal (1400Hz)
        chime = 0.0
        if t < 0.12:
            chime = math.sin(2.0 * math.pi * 1420.0 * t) * math.exp(-22.0 * t) * 0.3

        samples.append(creak + chime)
    return samples

def gen_chest_close():
    """Menutup peti kayu bahan (bantingan tutup kayu berbobot)."""
    dur = 0.28
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 130.0 * math.exp(-24.0 * t) + 48.0
        phase += 2.0 * math.pi * f / SAMPLE_RATE
        val = math.tanh(math.sin(phase) * 2.5) * math.exp(-16.0 * t) * 0.75
        samples.append(val)
    return samples

def gen_wooden_click_light():
    """Klik taktil tombol kayu ringan (pilihan menu slot inventaris / hover)."""
    dur = 0.045
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 1450.0 * math.exp(-48.0 * t) + 650.0
        phase += 2.0 * math.pi * f / SAMPLE_RATE
        val = math.sin(phase) * math.exp(-75.0 * t) * 0.5
        samples.append(val)
    return samples

def gen_wooden_click_heavy():
    """Ketukan kayu padat mantap (konfirmasi pilihan resep / beli barang kedai)."""
    dur = 0.08
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 560.0 * math.exp(-32.0 * t) + 210.0
        phase += 2.0 * math.pi * f / SAMPLE_RATE
        val = math.tanh(math.sin(phase) * 1.8) * math.exp(-38.0 * t) * 0.65
        samples.append(val)
    return samples

def gen_wooden_toggle():
    """Sakelar tuas kayu beralih (dua ketukan klik berjarak mikro)."""
    dur = 0.075
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase1 = 0.0
    phase2 = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        val = 0.0
        # Klik 1 di t=0
        if t < 0.035:
            f1 = 780.0 * math.exp(-45.0 * t) + 380.0
            phase1 += 2.0 * math.pi * f1 / SAMPLE_RATE
            val += math.sin(phase1) * math.exp(-65.0 * t) * 0.5
        # Klik 2 di t=0.03
        if t >= 0.028:
            dt = t - 0.028
            f2 = 1150.0 * math.exp(-55.0 * dt) + 520.0
            phase2 += 2.0 * math.pi * f2 / SAMPLE_RATE
            val += math.sin(phase2) * math.exp(-70.0 * dt) * 0.55
        samples.append(val)
    return samples

def gen_page_turn():
    """Membuka lembaran buku saku / jurnal lapangan Nala (desir kertas perkamen lembut)."""
    dur = 0.28
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(555)
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        prog = t / dur
        amp = math.pow(math.sin(math.pi * prog), 1.5)
        raw = rnd.uniform(-1.0, 1.0)
        # Desau lembut kertas bergeser
        lp += 0.28 * (raw - lp)
        samples.append(lp * amp * 0.6)
    return samples

def gen_recipe_cooked():
    """Masakan jamu Mak Waras siap / panggangan ikan berdesis (sizzle mendidih uap panas)."""
    dur = 0.85
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(666)
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # Envelope: desis kencang awal lalu perlahan reda
        if t < 0.15:
            env = t / 0.15
        else:
            env = math.exp(-3.5 * (t - 0.15))

        raw = rnd.uniform(-1.0, 1.0)
        lp += 0.4 * (raw - lp) # Desis frekuensi tinggi
        sizzle = lp * 0.6

        # Letupan gelembung kuah mendidih mikro
        pop = 0.0
        if rnd.random() < 0.008:
            pop = math.sin(2.0 * math.pi * rnd.uniform(600.0, 1200.0) * t) * 0.4

        samples.append((sizzle + pop) * env * 0.75)
    return samples

def gen_rope_creak():
    """Tali tambang perahu berderit meregang di dermaga (deritan serat ijuk tegang)."""
    dur = 0.60
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    rnd = random.Random(777)
    for i in range(n):
        t = i / SAMPLE_RATE
        prog = t / dur
        amp = math.sin(math.pi * prog)
        # Tegangan tali elastis bergesekan (210Hz - 290Hz)
        f = 230.0 + math.sin(prog * 12.0) * 55.0 + rnd.uniform(-12.0, 12.0)
        phase += 2.0 * math.pi * f / SAMPLE_RATE
        val = math.sin(phase) * amp * 0.45
        samples.append(val)
    return samples

def gen_metal_valve_turn():
    """Memutar katup pipa limbah industri berkarat (derit logam karat + gesekan berat)."""
    dur = 0.50
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    rnd = random.Random(888)
    for i in range(n):
        t = i / SAMPLE_RATE
        prog = t / dur
        amp = math.sin(math.pi * prog)
        # Pekikan logam berkarat (1350Hz - 1700Hz)
        f = 1480.0 + math.sin(t * 70.0) * 180.0 + rnd.uniform(-20.0, 20.0)
        phase += 2.0 * math.pi * f / SAMPLE_RATE
        squeak = math.sin(phase) * 0.4

        # Hantaman katup berhenti di ujung putaran
        clunk = 0.0
        if t > 0.38:
            dt = t - 0.38
            clunk = math.sin(2.0 * math.pi * 180.0 * dt) * math.exp(-25.0 * dt) * 0.5

        samples.append((squeak + clunk) * amp * 0.8)
    return samples

def gen_bell_ding():
    """Lonceng kuningan kasir Kedai Waras berdering (ting lonceng jernih berkilau)."""
    dur = 0.75
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase1 = 0.0
    phase2 = 0.0
    f1 = 2093.0 # C7 nada lonceng
    f2 = 4186.0 # C8 harmonik oktaf
    for i in range(n):
        t = i / SAMPLE_RATE
        phase1 += 2.0 * math.pi * f1 / SAMPLE_RATE
        phase2 += 2.0 * math.pi * f2 / SAMPLE_RATE
        env = math.exp(-5.0 * t)
        val = (math.sin(phase1) + 0.35 * math.sin(phase2)) * env * 0.5
        samples.append(val)
    return samples

def gen_water_drip():
    """Tetesan air gua laut / tetesan pakaian selam basah jatuh di batu (tik-plop jernih)."""
    dur = 0.16
    n = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # Sweep naik sangat cepat 1100Hz -> 2300Hz
        f = 1100.0 + 1200.0 * math.pow(t / dur, 0.7)
        phase += 2.0 * math.pi * f / SAMPLE_RATE
        env = math.exp(-28.0 * t)
        samples.append(math.sin(phase) * env * 0.6)
    return samples

# ----------------- SFX DEBURAN OMBAK & DERU AIR PESISIR (OCEAN WAVES & SURF) -----------------

def gen_coastal_wave_lap():
    """Deburan ombak pesisir (gelombang air bergulung, pecahan lembut di pasir pantai, lalu desis buih surut)."""
    dur = 2.8
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(10101)
    
    rumble_phase = 0.0
    pink_lp1 = 0.0
    pink_lp2 = 0.0
    foam_hp = 0.0
    foam_lp = 0.0
    
    for i in range(n):
        t = i / SAMPLE_RATE
        
        # 1. Gelombang masuk bergulung (Inflow surge: t dari 0.0 ke 1.1s)
        inflow_env = 0.0
        if t < 1.1:
            inflow_env = math.sin(math.pi * 0.5 * (t / 1.1))
        else:
            inflow_env = math.exp(-2.2 * (t - 1.1))
            
        rumble_freq = 55.0 + 18.0 * math.sin(2.0 * math.pi * 0.4 * t)
        rumble_phase += 2.0 * math.pi * rumble_freq / SAMPLE_RATE
        rumble = math.sin(rumble_phase) * inflow_env * 0.45
        
        # 2. Deburan pecahan ombak di pasir (Crest break & white water: puncak di t=0.9 - 1.6s)
        raw = rnd.uniform(-1.0, 1.0)
        pink_lp1 += 0.08 * (raw - pink_lp1)
        pink_lp2 += 0.12 * (pink_lp1 - pink_lp2)
        
        break_env = 0.0
        if 0.5 < t < 2.0:
            dt = t - 0.5
            break_env = math.sin(math.pi * (dt / 1.5))
        water_body = pink_lp2 * break_env * 0.75
        
        # 3. Desisan air laut surut berbusa di butiran pasir (Seafoam hiss & percolation: t=1.1 ke 2.8s)
        foam_env = 0.0
        if t > 1.1:
            dt = t - 1.1
            foam_env = math.sin(math.pi * min(1.0, dt / 0.5)) * math.exp(-1.4 * dt)
            
        foam_hp = raw - 0.65 * foam_hp
        foam_lp += 0.25 * (foam_hp - foam_lp)
        foam = foam_lp * foam_env * 0.42
        
        total = rumble + water_body + foam
        samples.append(math.tanh(total * 1.5) * 0.85)
        
    return samples

def gen_coastal_wave_surge():
    """Deru ombak laut pasang besar (gemuruh massa air laut bertenaga menghempas bibir pesisir)."""
    dur = 3.4
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(20202)
    
    sub_phase = 0.0
    body_lp = 0.0
    wash_hp = 0.0
    wash_lp = 0.0
    
    for i in range(n):
        t = i / SAMPLE_RATE
        
        # Sub-bass massa air laut besar (42Hz - 68Hz)
        sub_freq = 46.0 + 20.0 * math.sin(2.0 * math.pi * 0.3 * t)
        sub_phase += 2.0 * math.pi * sub_freq / SAMPLE_RATE
        
        surge_env = math.sin(math.pi * min(1.0, t / 1.3)) if t < 1.3 else math.exp(-1.3 * (t - 1.3))
        sub = math.sin(sub_phase) * surge_env * 0.55
        
        # Hempasan gulungan air berbusa tebal
        raw = rnd.uniform(-1.0, 1.0)
        body_lp += 0.07 * (raw - body_lp)
        body_env = math.sin(math.pi * min(1.0, t / 1.5)) if t < 1.5 else math.exp(-1.6 * (t - 1.5))
        body = body_lp * body_env * 0.85
        
        # Deru desis sapuan busa panjang
        wash_hp = raw - 0.7 * wash_hp
        wash_lp += 0.2 * (wash_hp - wash_lp)
        wash_env = 0.0
        if t > 0.8:
            dt = t - 0.8
            wash_env = math.sin(math.pi * min(1.0, dt / 0.7)) * math.exp(-1.1 * dt)
        wash = wash_lp * wash_env * 0.45
        
        val = math.tanh((sub + body + wash) * 1.6) * 0.88
        samples.append(val)
        
    return samples

def gen_wave_crash_rock():
    """Hempasan deburan ombak menabrak tiang pancang dermaga atau batu karang pemecah ombak."""
    dur = 1.9
    n = int(SAMPLE_RATE * dur)
    samples = []
    rnd = random.Random(30303)
    
    impact_phase = 0.0
    splash_lp = 0.0
    spray_hp = 0.0
    
    for i in range(n):
        t = i / SAMPLE_RATE
        
        # 1. Hantaman massa air pada karang / tiang (benturan padat tumpul)
        impact_freq = 110.0 * math.exp(-14.0 * t) + 38.0
        impact_phase += 2.0 * math.pi * impact_freq / SAMPLE_RATE
        impact = math.tanh(math.sin(impact_phase) * 2.2) * math.exp(-10.0 * t) * 0.65
        
        # 2. Guyuran dan cipratan air deras (splash)
        raw = rnd.uniform(-1.0, 1.0)
        splash_lp += 0.15 * (raw - splash_lp)
        splash_env = math.sin(math.pi * min(1.0, t / 0.6)) * math.exp(-6.0 * t)
        splash = splash_lp * splash_env * 0.8
        
        # 3. Percikan partikel air menyembur ke udara (spray hiss)
        spray_hp = raw - 0.8 * spray_hp
        spray_env = math.exp(-4.5 * t)
        spray = spray_hp * spray_env * 0.35
        
        samples.append(math.tanh((impact + splash + spray) * 1.1) * 0.85)
        
    return samples

def gen_ambient_coastal_waves(dur=12.0):
    """Loop ambien deburan ombak pesisir pantai stereo (gelombang air laut mengalun lembut di latar belakang)."""
    n = int(SAMPLE_RATE * dur)
    left = []
    right = []
    rnd = random.Random(40404)
    
    lp_l = 0.0
    lp_r = 0.0
    sub_phase_l = 0.0
    sub_phase_r = 0.0
    
    for i in range(n):
        t = i / SAMPLE_RATE
        
        # 2 siklus ombak dalam 12 detik (periode 6 detik)
        cycle_mod_l = 0.5 + 0.5 * math.sin(2.0 * math.pi * (t / 6.0) - math.pi * 0.5)
        cycle_mod_r = 0.5 + 0.5 * math.sin(2.0 * math.pi * (t / 6.0) - math.pi * 0.5 + 0.35)
        
        # Sub-rumble massa air
        sub_phase_l += 2.0 * math.pi * 48.0 / SAMPLE_RATE
        sub_phase_r += 2.0 * math.pi * 51.0 / SAMPLE_RATE
        sub_l = math.sin(sub_phase_l) * (0.15 + 0.35 * cycle_mod_l)
        sub_r = math.sin(sub_phase_r) * (0.15 + 0.35 * cycle_mod_r)
        
        # Deburan dan buih air laut (pink/bandpass noise)
        raw_l = rnd.uniform(-1.0, 1.0)
        raw_r = rnd.uniform(-1.0, 1.0)
        lp_l += 0.09 * (raw_l - lp_l)
        lp_r += 0.09 * (raw_r - lp_r)
        
        body_l = lp_l * (0.2 + 0.75 * cycle_mod_l)
        body_r = lp_r * (0.2 + 0.75 * cycle_mod_r)
        
        # Seamless loop crossfade di ujung awal dan akhir
        fade = 1.0
        if t < 0.4:
            fade = t / 0.4
        elif t > (dur - 0.4):
            fade = (dur - t) / 0.4
            
        val_l = math.tanh((sub_l + body_l) * 1.5) * 0.8 * fade
        val_r = math.tanh((sub_r + body_r) * 1.5) * 0.8 * fade
        left.append(val_l)
        right.append(val_r)
        
    return left, right

# ----------------- BGM GENERATORS -----------------

def gen_underwater_ambient(dur=14.0):
    """Lagu Latar Suasana Bawah Air Laut Segaran (Drone Ambient & Chime Pentatonik Maritim)."""
    n = int(SAMPLE_RATE * dur)
    left = []
    right = []

    # Nada pentatonik Pelog/Slendro: D3 (146.8), F3 (174.6), G3 (196.0), A3 (220.0), C4 (261.6), D4 (293.6)
    drone_roots = [73.4, 110.0, 146.8] # D2, A2, D3
    drone_phases_l = [0.0, 0.0, 0.0]
    drone_phases_r = [0.0, 0.0, 0.0]

    # Chimes jadwal waktu
    chimes = [
        (1.5, 293.66, 0.3),  # D4
        (3.8, 392.00, 0.25), # G4
        (6.0, 440.00, 0.3),  # A4
        (8.5, 523.25, 0.35), # C5
        (11.0, 587.33, 0.28) # D5
    ]

    rnd = random.Random(101)
    water_noise_l = 0.0
    water_noise_r = 0.0

    for i in range(n):
        t = i / SAMPLE_RATE

        # 1. Deep Sub-Surface Drone (Stereo Spread)
        l_val = 0.0
        r_val = 0.0
        for idx, f in enumerate(drone_roots):
            # Perlahan bergerak dengan vibrato lembut
            vib = math.sin(2.0 * math.pi * 0.2 * t + idx) * 0.5
            drone_phases_l[idx] += 2.0 * math.pi * (f + vib) / SAMPLE_RATE
            drone_phases_r[idx] += 2.0 * math.pi * (f - vib + 0.2) / SAMPLE_RATE

            amp = 0.18 / (idx + 1)
            l_val += math.sin(drone_phases_l[idx]) * amp
            r_val += math.sin(drone_phases_r[idx]) * amp

        # 2. Resonansi Air Dalam (Gentle ocean low-pass noise)
        raw_l = rnd.uniform(-1.0, 1.0)
        raw_r = rnd.uniform(-1.0, 1.0)
        water_noise_l += 0.015 * (raw_l - water_noise_l)
        water_noise_r += 0.015 * (raw_r - water_noise_r)

        l_val += water_noise_l * 0.25
        r_val += water_noise_r * 0.25

        # 3. Twinkling Metallic Chimes
        for start_t, freq, amp in chimes:
            if t >= start_t:
                dt = t - start_t
                c_env = math.exp(-3.2 * dt)
                chime_sample = (math.sin(2.0 * math.pi * freq * dt) +
                                0.35 * math.sin(2.0 * math.pi * freq * 2.71 * dt)) * c_env * amp
                # Panning sedikit bergantian
                pan = math.sin(start_t) * 0.4
                l_val += chime_sample * (0.5 - pan)
                r_val += chime_sample * (0.5 + pan)

        # Seamless Loop Envelope (Fade in 0.5s awal, fade out 0.5s akhir)
        loop_fade = 1.0
        if t < 0.6:
            loop_fade = t / 0.6
        elif t > (dur - 0.6):
            loop_fade = (dur - t) / 0.6

        left.append(l_val * loop_fade * 0.8)
        right.append(r_val * loop_fade * 0.8)

    return left, right

def gen_coastal_day(dur=12.0):
    """Lagu Latar Siang Hari Pesisir Bandar Hujung (Acoustic Bamboo Marimba & Rhythmic Bass)."""
    n = int(SAMPLE_RATE * dur)
    left = []
    right = []

    # Tangga nada Pelog Barang: E4 (329.6), G#4 (415.3), A4 (440.0), B4 (493.8), D#5 (622.2), E5 (659.2)
    # Melodi Rindik bambu per 0.375 detik (160 BPM triplet groove)
    melody = [
        # (waktu_detik, frekuensi, kekuatan, panning)
        (0.00, 329.6, 0.40, -0.2),
        (0.38, 415.3, 0.35,  0.2),
        (0.75, 493.8, 0.45, -0.3),
        (1.12, 440.0, 0.30,  0.1),
        (1.50, 659.2, 0.40,  0.3),
        (1.88, 493.8, 0.35, -0.2),
        (2.25, 415.3, 0.38,  0.0),
        (2.62, 329.6, 0.42, -0.2),

        (3.00, 440.0, 0.40,  0.2),
        (3.38, 493.8, 0.35, -0.2),
        (3.75, 622.2, 0.45,  0.3),
        (4.12, 659.2, 0.50, -0.1),
        (4.50, 493.8, 0.38,  0.2),
        (4.88, 440.0, 0.32, -0.3),
        (5.25, 415.3, 0.36,  0.1),
        (5.62, 329.6, 0.40,  0.0),

        # Pengulangan variasi bar ke-2
        (6.00, 329.6, 0.42, -0.2),
        (6.38, 415.3, 0.36,  0.2),
        (6.75, 493.8, 0.44, -0.3),
        (7.12, 622.2, 0.38,  0.2),
        (7.50, 659.2, 0.48,  0.3),
        (7.88, 493.8, 0.35, -0.1),
        (8.25, 440.0, 0.38,  0.2),
        (8.62, 415.3, 0.35, -0.2),

        (9.00, 493.8, 0.40,  0.1),
        (9.38, 440.0, 0.35, -0.2),
        (9.75, 415.3, 0.40,  0.2),
        (10.12, 329.6, 0.42, -0.1),
        (10.50, 246.9, 0.45,  0.0), # B3 bas
        (10.88, 329.6, 0.38,  0.1),
        (11.25, 415.3, 0.35, -0.2),
        (11.62, 493.8, 0.30,  0.2)
    ]

    # Bass denyut (E2 = 82.4Hz, B2 = 123.4Hz)
    bass_notes = [
        (0.0, 82.41), (1.5, 123.47), (3.0, 82.41), (4.5, 110.0),
        (6.0, 82.41), (7.5, 123.47), (9.0, 82.41), (10.5, 123.47)
    ]

    for i in range(n):
        t = i / SAMPLE_RATE
        l_val = 0.0
        r_val = 0.0

        # 1. Rindik / Bamboo Marimba Strikes
        for start_t, freq, amp, pan in melody:
            if t >= start_t:
                dt = t - start_t
                if dt < 0.65:
                    # Karakter bambu: Attack kayu cepat + resonansi bulat
                    env = math.exp(-7.5 * dt)
                    # Harmonics
                    strike = (math.sin(2.0 * math.pi * freq * dt) +
                              0.4 * math.sin(2.0 * math.pi * freq * 2.0 * dt) +
                              0.15 * math.sin(2.0 * math.pi * freq * 3.01 * dt)) * env * amp
                    l_val += strike * (0.5 - pan * 0.5)
                    r_val += strike * (0.5 + pan * 0.5)

        # 2. Bass Denyut Akustik
        for start_t, freq in bass_notes:
            if t >= start_t:
                dt = t - start_t
                if dt < 1.3:
                    b_env = math.exp(-3.5 * dt)
                    bass = math.sin(2.0 * math.pi * freq * dt) * b_env * 0.22
                    l_val += bass
                    r_val += bass

        # Seamless Loop Fade
        loop_fade = 1.0
        if t < 0.3:
            loop_fade = t / 0.3
        elif t > (dur - 0.3):
            loop_fade = (dur - t) / 0.3

        left.append(l_val * loop_fade * 0.85)
        right.append(r_val * loop_fade * 0.85)

    return left, right

# ----------------- MAIN EXECUTION -----------------

def main():
    sfx_dir = "client-godot/audio/sfx"
    bgm_dir = "client-godot/audio/bgm"

    print("=== SYNTHESIZING JALASMARA PROCEDURAL AUDIO ASSETS ===")

    # 1. SFX Eksplorasi Bawah Air & Eksistensi
    write_wav(os.path.join(sfx_dir, "bubble_pop.wav"), gen_bubble_pop())
    write_wav(os.path.join(sfx_dir, "water_splash.wav"), gen_water_splash())
    write_wav(os.path.join(sfx_dir, "player_hit.wav"), gen_player_hit())
    write_wav(os.path.join(sfx_dir, "diver_breath.wav"), gen_diver_breath())
    write_wav(os.path.join(sfx_dir, "harpoon_shoot.wav"), gen_harpoon_shoot())
    write_wav(os.path.join(sfx_dir, "coin_collect.wav"), gen_coin_collect())
    write_wav(os.path.join(sfx_dir, "item_pickup.wav"), gen_item_pickup())
    write_wav(os.path.join(sfx_dir, "oxygen_alarm.wav"), gen_oxygen_alarm())
    write_wav(os.path.join(sfx_dir, "heartbeat.wav"), gen_heartbeat())
    write_wav(os.path.join(sfx_dir, "menu_click.wav"), gen_menu_click())
    write_wav(os.path.join(sfx_dir, "boss_roar.wav"), gen_boss_roar())

    # 2. SFX Gerakan, Tebasan & Desau (Swoosh, Whoosh, Swish, Swesh)
    write_wav(os.path.join(sfx_dir, "swoosh_light.wav"), gen_swoosh_light())
    write_wav(os.path.join(sfx_dir, "swoosh_heavy.wav"), gen_swoosh_heavy())
    write_wav(os.path.join(sfx_dir, "swoosh_water.wav"), gen_swoosh_water())
    write_wav(os.path.join(sfx_dir, "dodge_swish.wav"), gen_dodge_swish())
    write_wav(os.path.join(sfx_dir, "net_throw.wav"), gen_net_throw())

    # 3. SFX Hantaman, Pertarungan & Senjata
    write_wav(os.path.join(sfx_dir, "hit_heavy.wav"), gen_hit_heavy())
    write_wav(os.path.join(sfx_dir, "hit_flesh.wav"), gen_hit_flesh())
    write_wav(os.path.join(sfx_dir, "hit_critical.wav"), gen_hit_critical())
    write_wav(os.path.join(sfx_dir, "hit_shield.wav"), gen_hit_shield())
    write_wav(os.path.join(sfx_dir, "knife_slash.wav"), gen_knife_slash())
    write_wav(os.path.join(sfx_dir, "monster_bite.wav"), gen_monster_bite())
    write_wav(os.path.join(sfx_dir, "rock_smash.wav"), gen_rock_smash())
    write_wav(os.path.join(sfx_dir, "punch_swing.wav"), gen_punch_swing())
    write_wav(os.path.join(sfx_dir, "punch_hit.wav"), gen_punch_hit())
    write_wav(os.path.join(sfx_dir, "hit_wood.wav"), gen_hit_wood())
    write_wav(os.path.join(sfx_dir, "hit_stone.wav"), gen_hit_stone())

    # 4. SFX Langkah Kaki Berbagai Permukaan (Dermaga, Jembatan, Pasir, Batu, Air Dangkal, Tanah)
    write_wav(os.path.join(sfx_dir, "footstep_grass.wav"), gen_footstep_grass())
    write_wav(os.path.join(sfx_dir, "footstep_wood.wav"), gen_footstep_wood())
    write_wav(os.path.join(sfx_dir, "footstep_dock.wav"), gen_footstep_dock())
    write_wav(os.path.join(sfx_dir, "footstep_bridge.wav"), gen_footstep_bridge())
    write_wav(os.path.join(sfx_dir, "footstep_sand.wav"), gen_footstep_sand())
    write_wav(os.path.join(sfx_dir, "footstep_stone.wav"), gen_footstep_stone())
    write_wav(os.path.join(sfx_dir, "footstep_water_shallow.wav"), gen_footstep_water_shallow())
    write_wav(os.path.join(sfx_dir, "footstep_dirt.wav"), gen_footstep_dirt())
    write_wav(os.path.join(sfx_dir, "quest_complete.wav"), gen_quest_complete())

    # 5. SFX Membuka Jalan (Tebas Semak, Patah Barikade Kayu, Geser Batu Monolit, Jalan Terbuka)
    write_wav(os.path.join(sfx_dir, "machete_cut_bush.wav"), gen_machete_cut_bush())
    write_wav(os.path.join(sfx_dir, "wood_break_barricade.wav"), gen_wood_break_barricade())
    write_wav(os.path.join(sfx_dir, "boulder_push_slide.wav"), gen_boulder_push_slide())
    write_wav(os.path.join(sfx_dir, "path_reveal_chime.wav"), gen_path_reveal_chime())

    # 5. SFX Ledakan & Dentuman (Boom, Underwater Shockwave)
    write_wav(os.path.join(sfx_dir, "explosion_heavy.wav"), gen_explosion_heavy())
    write_wav(os.path.join(sfx_dir, "underwater_boom.wav"), gen_underwater_boom())

    # 6. SFX Pintu & Peti Harta (Kayu Berderit, Buka Tutup Pintu/Peti)
    write_wav(os.path.join(sfx_dir, "door_open_wood.wav"), gen_door_open_wood())
    write_wav(os.path.join(sfx_dir, "door_close_wood.wav"), gen_door_close_wood())
    write_wav(os.path.join(sfx_dir, "chest_open.wav"), gen_chest_open())
    write_wav(os.path.join(sfx_dir, "chest_close.wav"), gen_chest_close())

    # 7. SFX Interaksi Taktil Kayu & Menu UI (Wooden Click, Toggle, Page Turn)
    write_wav(os.path.join(sfx_dir, "wooden_click_light.wav"), gen_wooden_click_light())
    write_wav(os.path.join(sfx_dir, "wooden_click_heavy.wav"), gen_wooden_click_heavy())
    write_wav(os.path.join(sfx_dir, "wooden_toggle.wav"), gen_wooden_toggle())
    write_wav(os.path.join(sfx_dir, "page_turn.wav"), gen_page_turn())
    write_wav(os.path.join(sfx_dir, "recipe_cooked.wav"), gen_recipe_cooked())

    # 8. SFX Mekanisme, Katup Logam & Lingkungan
    write_wav(os.path.join(sfx_dir, "rope_creak.wav"), gen_rope_creak())
    write_wav(os.path.join(sfx_dir, "metal_valve_turn.wav"), gen_metal_valve_turn())
    write_wav(os.path.join(sfx_dir, "bell_ding.wav"), gen_bell_ding())
    write_wav(os.path.join(sfx_dir, "water_drip.wav"), gen_water_drip())

    # 9. SFX Deburan Ombak Pesisir & Deru Air Pantai (Coast Surf, Wave Lap & Crash)
    write_wav(os.path.join(sfx_dir, "coastal_wave_lap.wav"), gen_coastal_wave_lap())
    write_wav(os.path.join(sfx_dir, "coastal_wave_surge.wav"), gen_coastal_wave_surge())
    write_wav(os.path.join(sfx_dir, "wave_crash_rock.wav"), gen_wave_crash_rock())
    ambient_w_l, ambient_w_r = gen_ambient_coastal_waves(12.0)
    write_stereo_wav(os.path.join(sfx_dir, "ambient_coastal_waves.wav"), ambient_w_l, ambient_w_r)

    # 10. BGM Suasana Prosedural (Loopable fallback)
    bgm_amb_l, bgm_amb_r = gen_underwater_ambient(14.0)
    write_stereo_wav(os.path.join(bgm_dir, "bgm_underwater_ambient.wav"), bgm_amb_l, bgm_amb_r)

    bgm_day_l, bgm_day_r = gen_coastal_day(12.0)
    write_stereo_wav(os.path.join(bgm_dir, "bgm_coastal_day.wav"), bgm_day_l, bgm_day_r)

    print("=== AUDIO ASSETS SYNTHESIS COMPLETE ===")

if __name__ == "__main__":
    main()

