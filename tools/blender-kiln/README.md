# Pemeriksaan GLB dengan Blender Kiln

Adapter ini menjalankan `plugin/studio/checks.py` dan `studiolib.py` asli dari [Blender Kiln](https://github.com/elithril/blender-kiln), commit `e9a421467dd95d0de71d45b3d331f8efa4b80f26`, berlisensi MIT. Kedua modul diunduh ke `.runtime/blender-kiln-source/` pada penggunaan pertama dan diperiksa terhadap SHA-256 di `source.json` sebelum diimpor. Cache berikutnya dapat digunakan tanpa jaringan.

```sh
python3 tools/blender-kiln/check-assets.py
python3 tools/blender-kiln/check-assets.py client-godot/resources/models/reef-rock.glb
```

Hasil lengkap berada di `.runtime/kiln-asset-checks.json`: jumlah segitiga, ukuran, titik pijak model, tekstur, dan saran kompresi dari pemeriksa upstream. Adapter tidak menghapus temuan. Saat dijalankan pada `memory-slab.glb` dan `reef-rock.glb`, geometri terbaca dengan 60 dan 430 segitiga; masing-masing memiliki satu saran kompresi untuk distribusi GLB langsung di web. Godot mengimpor GLB pada tahap produksi dan mengemas hasil ke PCK, sehingga saran ini perlu dibaca bersama ukuran paket dan profil rendering Godot.

Tidak ada berkas model yang ditulis ulang oleh pemeriksaan. Adapter ini bukan pemasangan plugin Claude Code, server MCP, atau Blender. Blender tidak ditemukan pada PATH maupun direktori aplikasi lokal ketika diperiksa. Pemodelan, UV baking, retopologi, animasi Blender, dan persetujuan fidelity tidak diklaim dijalankan. Untuk melakukan tahap tersebut, diperlukan Blender serta alat produksi yang sesuai. Lisensi upstream disimpan pada `LICENSE.upstream.txt`.
