# Suara gerakan dan eksplorasi

Berkas SFX tambahan dari pengguna dipertahankan dan dimuat oleh `AudioManager.gd`. Seluruh 14 tambahan memakai WAV PCM 16-bit, mono, 44,1 kHz. `scripts/generate_audio.py` menyediakan sumber sintesisnya. Import Godot yang sudah tersedia memakai kompresi QOA pada resource runtime; berkas WAV sumber tetap PCM 16-bit dan tidak diubah menjadi format 8-bit. Satu sampel `hit_wood` semula terpotong pada batas amplitudo; gain generatornya diturunkan dari 0,85 menjadi 0,79, lalu hanya WAV tersebut yang dibuat ulang.

`WorldFoley.gd` membaca `WORLD.landMaps[area].surfaces`. Polygon berprioritas tertinggi dipilih terlebih dahulu; pada prioritas yang sama, elevasi yang lebih tinggi menang. Konektor dari state traversal aktual atau polygon tangga pada manifest mengutamakan material konektornya. Koordinat Y dan warna gambar latar tidak menentukan suara.

| Material atau peristiwa | Suara | Pemicu |
| --- | --- | --- |
| Dermaga | `footstep_dock` | Jarak langkah aktual pada permukaan `dock` |
| Jembatan | `footstep_bridge` | Gerakan aktual pada permukaan atau konektor `bridge` |
| Pasir, batu, tanah, rumput, kayu | `footstep_sand`, `footstep_stone`, `footstep_dirt`, `footstep_grass`, `footstep_wood` | Material polygon lantai atau tangga |
| Air dangkal | `footstep_water_shallow` | Hanya jika manifest menetapkan permukaan yang dapat diinjak sebagai `water_shallow`; tidak membuat laut menjadi area jalan |
| Menyelam | `diver_breath`, `swoosh_water` | Interval napas dan jarak renang aktual |
| Jalan yang benar-benar dibuka | `path_reveal_chime` | Sesudah server mengonfirmasi puzzle baru selesai; tidak dipicu saat menyentuh gerbang terkunci |
| Pukulan, tebasan, penghalang kayu, bongkah batu | Berkas tambahan pengguna dimuat | Aset tersedia; tidak menambahkan mekanik pertarungan atau penghancuran yang belum ada |

Langkah tidak berbunyi ketika karakter diam atau tertahan. Jarak saat mute tidak ditumpuk untuk diputar setelah unmute. Berpindah jauh atau berganti area mengawali ulang pengukuran jarak. Oksigen, koin, dan hadiah tidak diubah oleh foley.

```sh
python3 scripts/verify_audio.py
GODOT --headless --path client-godot --script ../scripts/tests/world-foley.gd
```

Pemeriksaan Python menguji sampel sintesis sebelum encoding, tidak adanya clipping/nonfinite, durasi, format WAV, determinisme, dan kecocokan byte dengan berkas yang disediakan. Pemeriksaan Godot menempatkan delapan material pada Y yang sama, menguji prioritas/elevasi dan override konektor, lalu memeriksa cadence, idle, mute, serta napas. Pemeriksaan ini tidak membuktikan kualitas pendengaran melalui speaker; keseimbangan volume tetap memerlukan tinjauan manusia saat bermain.
