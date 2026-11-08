# Polyfork sebagai sumber model dan sprite

Tiga model lingkungan gratis tersedia di `assets/source-3d/polyfork/`: Bamboo Stalk, Fern Plant, dan Small Reef Rock. Bentuk alamnya dipilih sebagai bahan lingkungan umum; model tidak dianggap sebagai representasi spesies atau tradisi tertentu di Indonesia. Asal kit bambu tidak menjadi alasan memakai bangunan atau simbol budaya dari kit tersebut.

GLB gratis dipilih dengan **CC BY 4.0**, sehingga kredit dan keterangan perubahan harus menyertai distribusinya. Kredit per model, tautan, waktu pengambilan, serta SHA-256 tercatat bersama berkas. Sumber modul `.mjs`, edisi HD, dan gambar toko tidak disertakan. Ketentuan sumber diperiksa melalui [lisensi Polyfork](https://polyfork.dev/licensing) dan [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

API resmi menyediakan pencarian `GET /api/assets?q=fern&free=1`, detail `GET /api/assets/{id}`, dan URL GLB pada `download.glb`. Pengambilan tiga model ini tidak membutuhkan akun atau kunci. Lihat [referensi API Polyfork](https://polyfork.dev/api). Tidak ada pembelian atau permintaan pembuatan model.

## Render lokal yang sudah diuji

`tools/polyfork-render/` adalah proyek Godot khusus alat, terpisah dari game. Renderer memuat GLB lokal, memakai kamera ortografis miring, warna vertex tanpa bayangan material, latar transparan, tanpa antialias, dan konversi warna untuk PNG. Hasil prototipe 128 × 128 ada di subdirektori `renders/`.

```sh
/Applications/Godot.app/Contents/MacOS/Godot \
  --path tools/polyfork-render --script render.gd -- \
  /absolute/path/model.glb /absolute/path/sprite.png 128
```

Gunakan Godot 4.7.2 dengan tampilan grafis; `--headless` ditolak karena renderer dummy tidak menghasilkan gambar 3D. Ketiga model sudah berhasil dirender pada Apple M2 melalui Compatibility/OpenGL. Script memeriksa bahwa hasil memiliki piksel objek dan transparansi sebelum menyimpan.

PNG pakis dan bambu sudah dipakai sebagai dekorasi kecil pada hutan dan pelataran Bandar Hujung, dengan filter nearest serta skala yang mengikuti lingkungan. Render batu karang masih berupa prototipe dan belum dipakai. Salinan runtime identik byte dengan PNG sumber; kredit CC BY 4.0 serta keterangan perubahan tersedia di `client-godot/resources/art/polyfork/ATTRIBUTION.txt` dan ikut ekspor game. Pada pilot 2.5D, GLB Small Reef Rock juga dipakai langsung sebagai prop 3D melalui Godot. Salinan sumber tanpa perubahan serta kreditnya berada di `client-godot/resources/models/`; skala dan material render disesuaikan saat instancing. Tidak ada dependensi Three.js.


## Arsip batu darat perantara (sebelum layout 4)

`LandRockVisual.gd` menggunakan GLB Small Reef Rock yang sama; tidak ada model atau unduhan sumber baru. Mesh dirender langsung dalam SubViewport transparan 128 × 128 dan ditampilkan melalui ViewportTexture dalam Y-sort daratan. Material runtime memakai shader batu orisinal: grain berpetak, variasi mineral, pori kecil, serta lumut terbatas pada permukaan menghadap atas. Warna abu kecokelatan dan roughness tinggi menggantikan warna hijau rata; specular dinonaktifkan. Sumber GLB tetap tidak diubah. Cahaya siang/malam berasal dari state lingkungan. Skala serta pivot dikalibrasi dari batas alpha hasil render agar tetap di dalam footprint solid lama, tanpa collider tambahan. Kredit CC BY 4.0 yang telah disertakan berlaku juga untuk penggunaan ini.

Uji native `scripts/tests/land-rock-render.gd` membuktikan mesh serta viewport nyata, proyeksi kaki, silhouette yang stabil dan perubahan luminansi saat cahaya berubah. Uji ini memerlukan renderer grafis; tidak dimasukkan ke runner headless. Ini penggunaan 3D terpilih dalam komposisi darat 2D, bukan perubahan seluruh hub atau hutan menjadi dunia 3D penuh.


Penempatan hub terpilih berada di (790, 850) dengan ukuran 65 × 46 piksel, di dalam area solid lama (740, 675, 250, 205). Dua bayangan kontak pendek digambar dekat kaki batu. Sprite hasil proyeksi disembunyikan sampai kalibrasi alpha selesai agar bingkai awal tidak tampil pada posisi/skala yang salah. Tangkapan komposit native siang/malam pada `artifacts/godot/land-rock-3d/composite-*.png` dipakai untuk meninjau pertemuan model dengan bitmap peta; kelulusan helper terisolasi tidak dianggap otomatis sebagai kelulusan kualitas penempatan.


## Renderer modular layout 4

Renderer `LandWorld3D` kini memuat model batu pada scene komponen darat bersama floor, rumah dan pohon. Bukti per-rock SubViewport di atas adalah tahap migrasi sebelumnya; tampilan aktif tidak memakai bitmap peta sebagai floor atau collision. Model sumber dan kredit CC BY 4.0 tidak berubah. Finishing material, pencahayaan dan komposisi komponen tetap ditinjau pada native lokal serta browser; keberadaan GLB bukan jaminan kualitas visual akhir.
