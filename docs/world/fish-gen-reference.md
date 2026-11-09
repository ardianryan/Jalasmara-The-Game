# Fish Gen: referensi fauna laut yang disimpan

Tanggal pemeriksaan: 9 November 2026. Permintaan pengguna: simpan tool untuk kemungkinan memperkaya lingkungan laut. **Status: source tersimpan dan audit baca selesai; belum dipasang, dieksekusi, menghasilkan aset, atau diintegrasikan.** Pekerjaan inti 06 dan konflik sinkronisasi setelah ekstraksi tetap didahulukan.

## Source dan salinan lokal

| Data | Nilai |
| --- | --- |
| Upstream | [JacobKulberg/fish-gen](https://github.com/JacobKulberg/fish-gen) |
| Pin commit | `0faa79003ca50a7d422b618cb59179d9834094f1` |
| Waktu commit upstream | `2026-10-18T16:44:10-04:00` |
| Versi paket pada pin | `fishgen 0.1.0` |
| Clone lokal yang disimpan | `/Users/ardianryan/Documents/Jalasmara-06-fish-gen/.runtime/reference-audit/fish-gen` |
| Isi clone | 34 berkas tracked, sekitar 4.1 MiB termasuk metadata Git pada disk lokal |
| Lisensi software | MIT, copyright 2026 Jacob Kulberg |

Clone dibuat dengan Git melalui HTTPS, tanpa menjalankan kode repo. `git status --short` pada clone kosong; `.runtime/` sudah diabaikan oleh aturan proyek. Dokumen/pin masuk Git Jalasmara; salinan source lokal tetap berada di direktori audit. Clone bukan dependensi npm/Python, bukan submodule dan tidak masuk ekspor/PCK. Belum ada source upstream yang divendor ke berkas distribusi Jalasmara.

Untuk mengambil ulang **source saja**, gunakan Git lalu cocokkan pin sebelum melakukan tindakan lain:

```sh
git -c core.hooksPath=/dev/null clone --no-checkout https://github.com/JacobKulberg/fish-gen.git .runtime/reference-audit/fish-gen
git -C .runtime/reference-audit/fish-gen checkout --detach 0faa79003ca50a7d422b618cb59179d9834094f1
git -C .runtime/reference-audit/fish-gen rev-parse HEAD
```

Jangan menjalankan command clone di atas bila direktori audit sudah ada. Salinan yang sudah disimpan cukup diperiksa dengan `git -C ... rev-parse HEAD` dan `git -C ... status --short`.

Hash SHA-256 berkas yang diperiksa:

| Berkas upstream | SHA-256 |
| --- | --- |
| `LICENSE` | `258e998b9f86b8e525ba83132437e35fa4c964dd54544279141fee92f3f32b6e` |
| `README.md` | `1162be0bc391d319da652e89ebb545bca1be33882fe93951acba2146d9444184` |
| `pyproject.toml` | `f266e9b91d893bac1d8261ee59b7d1ae1f7dc5ccdd5a7346418818c7efe5ef26` |
| `fishgen/export.py` | `7a58bc5fa1b77673a47fd69d5c5d1060cc5c6df2ae7e2efea7bacc8b24cef595` |

## Yang cocok dan yang belum dibuktikan

Fish Gen membentuk fauna secara prosedural dengan seed, merender bentuk 3D menjadi sprite, lalu menyediakan renang kanan/kiri dan putaran yang menampakkan muka. Kandidat penggunaannya ialah fauna dekoratif atau biota tambahan. Ia tidak membuat terrain, batu, arus, buih, koral, parallax atau pencahayaan dunia. Source yang diaudit menyediakan keluaran raster, bukan jalur ekspor model GLB. Kamera/pitch pada proses produksi juga tidak otomatis sama dengan kamera dunia Jalasmara. [README pada pin](https://github.com/JacobKulberg/fish-gen/blob/0faa79003ca50a7d422b618cb59179d9834094f1/README.md), [CLI](https://github.com/JacobKulberg/fish-gen/blob/0faa79003ca50a7d422b618cb59179d9834094f1/fishgen/cli.py).

Ekspor menyediakan PNG RGBA, JSON persegi bingkai, pivot tengah, fps/loop, `next`, dan yaw per bingkai. Berkas Godot `.tres` berisi `SpriteFrames`/`AtlasTexture`, tetapi tidak membawa transisi `next` dan yaw JSON sebagai state perilaku. Pengendali tetap harus menunggu siklus renang, memainkan putaran sekali, lalu meneruskan arah baru. GIF hanya untuk preview karena transparansinya terbatas; PNG yang akan dinilai untuk produksi. [Exporter](https://github.com/JacobKulberg/fish-gen/blob/0faa79003ca50a7d422b618cb59179d9834094f1/fishgen/export.py), [animasi](https://github.com/JacobKulberg/fish-gen/blob/0faa79003ca50a7d422b618cb59179d9834094f1/fishgen/animation.py).

Analisis source menemukan kebutuhan adapter: [CreatureAnimator.gd](../../client-godot/scripts/CreatureAnimator.gd) saat ini memuat format `ppc.spritesheet`, arah 0/4 dan clip idle/walk. JSON Fish Gen memakai kontrak berbeda. Mengganti ekstensi atau menyalin `.tres` tidak menyambungkan transisi ke simulasi yang ada. Adapter perlu mempertahankan pivot, timing putaran, ukuran, tint kedalaman, pemilihan habitat dan jumlah instance. Navigasi, kawanan, penghindaran kontur, tangkapan serta hadiah tetap memakai logika Godot/API Jalasmara.

Manifest yang ada dibaca ulang pada audit ini: **10 spesies, 722 bingkai** di `client-godot/resources/art/procedural/manifest.json`. Semuanya tetap dipakai. Tidak ada penggantian aset, ID biota, collider, quest, kuis, hadiah atau batas populasi.

## Lisensi software dan keluaran

[LICENSE MIT pada pin](https://github.com/JacobKulberg/fish-gen/blob/0faa79003ca50a7d422b618cb59179d9834094f1/LICENSE) mengizinkan penggunaan/modifikasi/distribusi software dengan notice copyright dan izin yang tetap disertakan pada salinan atau bagian substansial. [Bagian lisensi README](https://github.com/JacobKulberg/fish-gen/blob/0faa79003ca50a7d422b618cb59179d9834094f1/README.md#license) secara terpisah menyatakan sprite yang dihasilkan boleh dipakai, termasuk pada game komersial. Pernyataan keluaran ini disimpan sebagai sumber izin, bukan diasumsikan dari nama lisensi software saja. Dependensi NumPy, Pillow dan opsi preview mempunyai lisensi masing-masing; belum ada dependensi tersebut yang dipasang atau didistribusikan untuk Fish Gen dalam pekerjaan ini.

Saat ini tidak perlu menambahkan Fish Gen ke notice software runtime karena tidak ada kode/asetnya pada paket game. Jika nanti kode upstream disalin, simpan `LICENSE` asli yang cocok hash di folder tool dan tambahkan sumber/pin/cakupan pada `THIRD_PARTY_LICENSES.md`. Untuk aset hasil pilot, simpan seed, command, genome, versi dependensi, hash output, serta sumber pernyataan izin dalam manifest produksi; jangan menyalin gambar galeri sebagai hasil generasi kita. Attribution tetap mencantumkan Fish Gen/Jacob Kulberg sesuai kebijakan proyek meskipun README membolehkan penggunaan hasil secara luas. Menamai adapter WorldKit tidak menghapus provenance upstream.

## Eksekusi yang belum dilakukan

[pyproject.toml](https://github.com/JacobKulberg/fish-gen/blob/0faa79003ca50a7d422b618cb59179d9834094f1/pyproject.toml) menyebut Python ≥3.10, NumPy ≥1.24 dan Pillow ≥10; preview menggunakan pygame-ce, tes menggunakan pytest. [Launcher GUI](https://github.com/JacobKulberg/fish-gen/blob/0faa79003ca50a7d422b618cb59179d9834094f1/gui.py) dapat membuat venv dan memasang paket otomatis. [Loader native](https://github.com/JacobKulberg/fish-gen/blob/0faa79003ca50a7d422b618cb59179d9834094f1/fishgen/native/__init__.py) dapat mengompilasi C ketika diimpor; opsi `FISHGEN_NO_NATIVE=1` tersedia. Karena tahap ini audit source, tidak ada import Python upstream, pip, kompilasi, GUI, tes upstream, atau permintaan API generator yang dijalankan. Tidak memakai akun, token atau layanan berbayar.

Tidak ada angka waktu generasi, FPS pemain, penghematan PCK atau kualitas visual hasil lokal yang dapat diklaim dari pemeriksaan ini. Gambar galeri upstream dan kode tes hanya referensi, bukan tes yang sudah lulus di mesin ini.

## Pilot berikutnya setelah pekerjaan inti

1. Pemilik tooling menyiapkan environment produksi offline terisolasi dengan dependensi dipatok. Mulai satu spesies laut pada seed tetap, PNG/JSON/SpriteFrames saja, serta native compiler dinonaktifkan pada percobaan awal. Catat seluruh keluaran dan provenance.
2. Gunakan ID pilot baru, bukan mengganti 10 spesies aktif. Bandingkan di scene uji terpisah: ukuran/pivot stabil, alpha bersih, palet tropis nyaman, loop dan putaran tersambung tanpa flip mendadak, serta pencahayaan hasil render tidak bertentangan dengan tint malam/kedalaman game. Spesies referensi tidak menjadi klaim spesies endemik Indonesia.
3. Buat adapter kecil setelah kontrak output nyata diperiksa. Pertahankan metadata `next`/yaw yang tidak dibawa `.tres`; pengurangan kecepatan saat berputar harus tetap aman bagi kontur dunia. Jangan ubah aturan tangkapan/server agar sprite tampak bekerja.
4. Ukur jumlah bingkai, ukuran atlas, disk, PCK dan transfer aktual sebelum batch. Default CLI smoothness 3 berarti lebih banyak bingkai daripada 1; pemilihannya memerlukan perbandingan animasi, bukan langsung memakai jumlah terbesar. Ini keputusan produksi berikutnya, belum benchmark.
5. Setelah pemeriksaan Godot native dan browser berurutan lulus, baru integrator memutuskan penambahan fauna pada zona tertentu dengan instance/quality limit yang sudah ada. Windows/S23 fisik tetap perlu pengujian tersendiri. Jadwal ini tidak mendahului penyelesaian UI, tubuh, rumah, dan konflik ekstraksi paket 06.

Pemeriksaan aktual paket dokumentasi ini: clone/pin/status/ignore, pembacaan source primer GitHub dan filesystem, SHA-256 empat berkas, dan penjumlahan manifest fauna lama. Tidak membuka browser WebGL/Godot atau mengubah database. Branch `work/06-fish-gen-reference` dibuat dari `90e639b`; tiga dokumen ini adalah hasil yang direview, sedangkan tool lokal tetap berstatus referensi tersimpan.
