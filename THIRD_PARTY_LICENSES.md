# PEMBERITAHUAN LISENSI PIHAK KETIGA (THIRD-PARTY LICENSES)

Dokumen ini memuat daftar pustaka perangkat lunak (*libraries*), mesin permainan (*game engines*), fon tipografi (*fonts*), dan model 3D pihak ketiga yang digunakan dalam pengembangan dan pendistribusian **Jalasmara**.

Semua hak cipta, merek dagang, dan lisensi di bawah ini tetap menjadi milik pemegang hak cipta masing-masing.

---

## Ringkasan Pustaka & Lisensi

| Komponen / Pustaka | Pemegang Hak Cipta / Pengembang | Lisensi | Peran dalam Proyek |
| :--- | :--- | :--- | :--- |
| **Godot Engine** | Juan Linietsky, Ariel Manzur, Godot Engine contributors | **MIT** | Mesin inti permainan 2D/3D & runtime WebAssembly |
| **Noxe Pixel Engine (adaptasi kamera)** | Daniel Jankulovski | **MIT** | Port pose ortografis dan pixel snapping ke helper Godot; pembanding kamera tiga perempat, tanpa runtime Three.js kedua |
| **Ark Pixel Font** | TakWolf (https://takwolf.com) | **SIL OFL 1.1** | Fon piksel tema HUD, dialog, dan label peta |
| **Lora Font** | Cyreal, Alexei Vanyashin | **SIL OFL 1.1** | Fon tipografi judul dan identitas web |
| **Nunito Sans Font** | Vernon Adams, Jacques Le Bailly, Manvel Shmavonyan, Alexei Vanyashin | **SIL OFL 1.1** | Fon antarmuka pengguna web |
| **Polyfork 3D Assets** | Polyfork (https://polyfork.dev) | **CC BY 4.0** | Model *Bamboo Stalk*, *Fern Plant*, dan *Small Reef Rock* |
| **Procedural Pixel Creatures** | idlerunner00 | **MIT** | Alat generasi fauna prosedural offline |
| **Pixelbolt** | skulitom / PixelForge contributors | **MIT** | Kompiler efek partikel piksel (*lantern-flame*, dll.) |
| **Pillow** | Jeffrey A. Clark and contributors; PIL by Secret Labs AB/Fredrik Lundh | **MIT-CMU** | Pemrosesan atlas dan pemeriksaan alpha offline; tidak disematkan dalam runtime game |
| **img2threejs** | img2threejs contributors | **Apache 2.0** | Pipa generasi mesh tablet relief offline |
| **Three.js** | Ricardo Cabello (Mr.doob) and contributors | **MIT** | Pembantu kompilasi GLB offline |
| **React & React-DOM** | Meta Platforms, Inc. and contributors | **MIT** | Kerangka kerja frontend aplikasi web |
| **Vite** | Evan You and Vite contributors | **MIT** | Bundler & build tool frontend web |
| **Fastify Framework** | Fastify contributors | **MIT** | Server API backend HTTP/REST |
| **Zod** | Colin McDonnell and Zod contributors | **MIT** | Validasi skema data dan tipe TypeScript |
| **Argon2** | Ran Murphey and Argon2 contributors | **MIT** | Hashing kata sandi kredensial aman |
| **IORedis** | Zihua Li and contributors | **MIT** | Klien koneksi basis data in-memory Redis |
| **MongoDB Node Driver** | MongoDB, Inc. | **Apache 2.0** | Driver koneksi basis data dokumen MongoDB |
| **Pino** | Matteo Collina, David Mark Clements | **MIT** | Logger performa tinggi terstruktur |
| **Jose & OAuth4webapi** | Filip Skokan | **MIT / Apache 2.0** | Otentikasi JWT, OIDC, dan PKCE |

---

## 1. Mesin Permainan (Game Engine)

### Godot Engine
- **Situs:** https://godotengine.org
- **Lisensi:** MIT License
- **Teks Lisensi:**
```text
Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Noxe Pixel Engine: port kamera terbatas

- **Sumber:** https://github.com/danieljan-design/noxe-pixel-engine
- **Revisi:** `d619d856398b44ad084003fac0a9fbfc9c8393e7`
- **Berkas upstream:** `engine/pixel-engine.js`, perhitungan orbit kamera dan penguncian posisi pada grid piksel.
- **Adaptasi Godot:** `client-godot/scripts/land/LandCameraPose.gd`, konversi Y-up ke Z-up dan helper proyeksi/ray untuk pilot. Pose rilis 0°/35° dipertahankan; kamera menyudut serta snap diuji pada fixture terpisah. Material, shader multipass, scene demo, exporter dan runtime Three.js Noxe tidak disalin.
- **Lisensi:** MIT; teks lengkap dan pemberitahuan hak cipta disertakan pada `client-godot/resources/licenses/noxe-MIT.txt`, ikut paket resource `.txt`.

---

## 2. Model 3D & Aset Grafis (Creative Commons)

### Polyfork Free Low-Poly Assets
- **Karya yang Digunakan:**
  - *Bamboo Stalk* (https://polyfork.dev/asset/bamboo-stalk-e4d362)
  - *Fern Plant* (https://polyfork.dev/asset/fern-plant-1559b8)
  - *Small Reef Rock* (https://polyfork.dev/asset/small-reef-rock-99062d)
- **Pembuat:** Polyfork (https://polyfork.dev)
- **Lisensi:** Creative Commons Attribution 4.0 International (CC BY 4.0)
- **Tautan Lisensi:** https://creativecommons.org/licenses/by/4.0/
- **Pemberitahuan Modifikasi (Notice of Modifications):**
  - Berkas asli mesh GLB disimpan pada direktori sumber tanpa modifikasi byte.
  - Untuk aset vegetasi darat (*Bamboo Stalk* dan *Fern Plant*), aset ditransformasikan melalui proses render ortografis miring 128 piksel dengan konversi palet warna untuk menghasilkan sprite 2D dekoratif pada pelataran dermaga dan hutan.
  - Untuk aset *Small Reef Rock*, model GLB diinstansiasikan langsung ke dalam pilot laut Godot dengan penyesuaian skala, material perairan, dan tata letak runtime.

---

## 3. Tipografi & Fon (SIL Open Font License)

### Ark Pixel Font
- **Situs:** https://github.com/TakWolf/ark-pixel-font
- **Pembuat:** Copyright (c) 2021, TakWolf (https://takwolf.com)
- **Lisensi:** SIL Open Font License, Version 1.1
- **Ketentuan:** Fon disematkan (*embedded*) ke dalam tema permainan Jalasmara dan label peta.

### Lora & Nunito Sans Fonts
- **Situs:** https://fonts.google.com / https://fontsource.org
- **Pembuat:** Cyreal, Vernon Adams, Jacques Le Bailly, Manvel Shmavonyan, Alexei Vanyashin
- **Lisensi:** SIL Open Font License, Version 1.1

*(Teks lengkap SIL OFL 1.1 tersedia pada [client-godot/resources/fonts/OFL.txt](./client-godot/resources/fonts/OFL.txt) serta [docs/assets/LICENSE-lora.txt](./docs/assets/LICENSE-lora.txt))*

---

## 4. Peralatan Pipa Aset & Generator Prosedural (Pipeline Tools)

### Jalasmara WorldKit dan komponen baru

WorldKit adalah nama lapisan integrasi asli Jalasmara, bukan penggantian nama kepemilikan kode upstream.

- **Sprite Fusion Pixel Snapper:** Hugo Duprez / Sprite Fusion, MIT. CLI Rust dipakai offline, sumber tanpa modifikasi dikunci pada commit `02f9315d73d3219274d17767b36d9a231a6b1f4b`. [Teks lisensi asli](tools/pixel-snapper/vendor/LICENSE), [manifest hash](tools/pixel-snapper/source.json), dan [adapter](tools/pixel-snapper/README.md) disertakan. Binary dan dependensi Cargo tidak dibundel ke game.
- **Image-to-Pixel 3.2.0:** Copyright 2023–2026 Tezumie, MIT, dipakai untuk konversi palet PNG offline. [Lisensi asli](tools/image-to-pixel/LICENSE.upstream.txt) disertakan. Dependensi ShaderMate mempertahankan [lisensi MIT Tezumie](tools/image-to-pixel/LICENSE.shadermate.txt), sedangkan pngjs 7.0.0 mempertahankan [lisensi Luke Page, Kuba Niegowski dan kontributor](tools/image-to-pixel/LICENSE.pngjs.txt). Paket terisolasi dari runtime game dan dikunci melalui lockfile alat.
- **Adapter format OpenWorld:** implementasi asli WorldKit berdasarkan format publik yang ditinjau, bukan salinan engine atau aset OpenWorld. [Asal format dan batas adapter](tools/worldkit/source.json) serta [sumber penelitian](docs/world/murder-authoring-reference.md) dicatat. WorldKit tidak mengimpor runtime LLM OpenWorld, FNA/Bang Murder, atau UI Pixprite.

Nunito Sans kini juga disematkan untuk teks dialog/kuis Godot. [Salinan lisensi font game](client-godot/resources/fonts/LICENSE-nunito-sans.txt) tetap OFL 1.1.

### Procedural Pixel Creatures
- **Pembuat:** Copyright (c) 2026 idlerunner00 (https://github.com/idlerunner00/procedural-pixel-creatures)
- **Lisensi:** MIT License
- **Keterangan:** Digunakan secara luring (*offline tool*) bersama adapter Jalasmara untuk menghasilkan sprite atlas fauna perairan; runtime C# tidak disertakan pada build web permainan.

### Pixelbolt
- **Pembuat:** Copyright (c) 2026 PixelForge contributors / skulitom (https://github.com/skulitom/Pixelbolt)
- **Lisensi:** MIT License
- **Keterangan:** Digunakan secara luring untuk menyusun resep simulasi partikel piksel (*pot-steam*, *lantern-flame*, *bubble-splash*, *memory-spark*).

### img2threejs
- **Situs:** https://github.com/img2threejs/img2threejs
- **Lisensi:** Apache License, Version 2.0
- **Keterangan:** Digunakan pada pipa produksi luring untuk membuat mesh backing tablet relief.

### Three.js
- **Pembuat:** Copyright (c) 2010-2026 Three.js Authors
- **Lisensi:** MIT License
- **Keterangan:** Digunakan secara luring saat ekspor GLB; pustaka Three.js tidak disertakan dalam runtime permainan akhir.

### Konsep Strata
- **Keterangan:** Arsitektur relief tanah daratan mengadaptasi prinsip tata lapisan *top*, *side*, dan *edge* dari [Strata](https://github.com/carthageadev/strata). Seluruh kode ditulis ulang secara orisinal untuk Godot GDScript; tidak ada kode sumber maupun aset upstream Strata/Unity yang disalin ke proyek ini.

---

### Pillow

Alat Python pembuat atlas memakai Pillow. Versi authoring lokal 11.3.0 mencantumkan MIT-CMU; [salinan pemberitahuan](tools/player-gait/LICENSE-Pillow.txt) berasal dari paket terpasang. CI memasang paket distribusi `python3-pil` beserta pemberitahuan paketnya. Kode Pillow tidak disalin ke runtime Godot dan lisensi alat tersebut tidak mengubah lisensi artwork hasil generasi proyek.

## 5. Pustaka Node.js, Fastify & Ekosistem Web

Seluruh dependensi ekosistem JavaScript/TypeScript di bawah ini dilisensikan di bawah **MIT License** atau **Apache License 2.0**:

- **React & React-DOM** — MIT License — Copyright (c) Meta Platforms, Inc.
- **Vite** — MIT License — Copyright (c) 2019-present Evan You & Vite Contributors
- **Fastify & Plugin Ekosistem (@fastify/helmet, @fastify/cookie, @fastify/rate-limit, @fastify/static)** — MIT License — Copyright (c) Fastify Contributors
- **Zod** — MIT License — Copyright (c) 2020 Colin McDonnell
- **Argon2** — MIT License — Copyright (c) 2016 Ran Murphey
- **IORedis** — MIT License — Copyright (c) 2015-2026 Zihua Li
- **MongoDB Node Driver** — Apache License 2.0 — Copyright (c) 2012-present MongoDB, Inc.
- **Pino** — MIT License — Copyright (c) Matteo Collina and David Mark Clements
- **Jose** — MIT License — Copyright (c) 2019-present Filip Skokan
- **OAuth4webapi** — Apache License 2.0 — Copyright (c) 2022-present Filip Skokan

*(Lisensi mendetail dari setiap modul npm tersimpan pada masing-masing subdirektori di dalam `node_modules/`)*


## Fish Gen offline-generated decorative fauna

[JacobKulberg/fish-gen](https://github.com/JacobKulberg/fish-gen), revision `0faa79003ca50a7d422b618cb59179d9834094f1`, version0.1.0, copyright2026JacobKulberg, MIT. Original notice: [tools/fish-gen/LICENSE.upstream](tools/fish-gen/LICENSE.upstream), also packaged at `client-godot/resources/licenses/FISH-GEN-MIT.txt`. The pinned README separately permits use of generated sprites, including commercial games.

Actual use: one offline Clownfish pilot seed1519 (48×32cells/32frames), PNG/JSON under `client-godot/resources/art/fishgen/`, with command/dependency/hash provenance. Python3.11/NumPy2.2.6/Pillow11.3.0, nativeC disabled; no upstream software runtime or second3Dengine is embedded. Godot adapter and steering are original project code. Ten previous fauna species remain. See [production tool](tools/fish-gen/README.md) and the overnight acceptance report for release status.
