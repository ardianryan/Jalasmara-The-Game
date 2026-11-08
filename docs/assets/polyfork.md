# Polyfork sebagai sumber model untuk sprite

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
