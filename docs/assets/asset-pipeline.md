# Produksi aset Jalasmara

Permainan memakai Godot Compatibility dan GDScript pada browser. Laut/gua memakai mesh 3D dan Sprite3D dalam viewport piksel; kota/hutan masih 2D. Alat produksi offline dapat menghasilkan GLB langsung atau sprite ortografis. Lihat [daftar integrasi tetap](../reference-integrations.md).

| Jalur | Kegunaan | Status di proyek |
| --- | --- | --- |
| Bitmap AI yang diarahkan | Karakter dan lingkungan Nusantara dengan sudut serta palet yang ditentukan | Dipakai; setiap hasil tetap perlu pemeriksaan budaya, siluet, transparansi, skala, dan collision |
| GLB Polyfork → render ortografis → PNG | Prop alam sederhana dengan sudut yang dapat diulang | Tiga GLB gratis dirender lokal; PNG pakis dan bambu dipakai pada hutan/hub; GLB batu karang dipakai langsung pada pilot laut 3D, sementara render PNG batunya belum dipakai |
| img2threejs → model prosedural → GLB → PNG | Rekonstruksi satu prop dari referensi yang haknya jelas | Forge resmi dipatok, strict spec/factory dijalankan; GLB backing tablet aktif. Three.js hanya alat ekspor offline. Lihat `tools/img2threejs/README.md` |
| Metode Strata | Menata kepadatan piksel dan batas material pada medan | Profil top/side/edge/teras aktif dalam implementasi Godot orisinal; tanpa menyalin paket Unity yang belum menyatakan lisensi |
| Procedural Pixel Creatures | Variasi tubuh, warna, rig, dan animasi dari parameter | Sepuluh spesies diekspor offline; 722 bingkai, klip arah/locomotion, dan metadata pivot dipakai oleh animator Godot |

## Jalur rekonstruksi prop

[img2threejs](https://github.com/img2threejs/img2threejs) menggunakan rekonstruksi melalui kode, bukan fotogrametri otomatis. Prosesnya menyusun spesifikasi bentuk dan detail dari gambar, membangun geometri bertahap, lalu membandingkan hasil render dengan referensi. Kode proyek tersebut berlisensi Apache 2.0. [Arsitektur resminya](https://github.com/img2threejs/img2threejs/blob/main/docs/ARCHITECTURE.md) memisahkan penilaian visual dari validasi serta pencatatan hasil.

Untuk satu prop Jalasmara, jalur yang sesuai adalah:

1. Pilih gambar milik proyek dan catat ukuran serta sudutnya.
2. Pisahkan komponen, proporsi, bahan, dan bagian yang tidak terlihat.
3. Bangun mesh prosedural dan periksa siluet dari beberapa arah.
4. Ekspor GLB setelah geometri dan warnanya disetujui.
5. Render melalui kamera ortografis yang sama dengan prop lain, lalu periksa PNG pada ukuran sebenarnya di game.

Bagian yang tidak terlihat dalam gambar harus dicatat sebagai perkiraan. Pipeline lokal menjalankan forge resmi melalui Python 3.10+ dan mengekspor factory melalui GLTFExporter. Installer global tidak dijalankan dan konfigurasi agen tidak diubah. Model pertama adalah backing tablet beresolusi rendah, bukan rekonstruksi seluruh peta atau hasil delapan tahap fidelity yang sudah disetujui.

## Batas alat dan referensi

[Strata](https://github.com/carthageadev/strata) adalah alat medan pixel art untuk Unity. Prinsip kisi piksel dan tepi material dapat menjadi bahan desain, sedangkan implementasi Godot tetap memerlukan shader, geometri, dan collision yang sesuai. Peta dekoratif tidak menggantikan mask jalur dan penghalang.

[Procedural Pixel Creatures](https://github.com/idlerunner00/procedural-pixel-creatures) menyediakan generator serta ekspor PNG/spritesheet melalui Godot .NET/C#. Generasi dan ekspor dilakukan offline; game menerima sprite dan metadata animasinya. CreatureAnimator membaca ukuran bingkai, pivot, arah E/W, dan klip locomotion dari JSON; tekstur dan metadata disimpan dalam cache. Pengujian memeriksa perubahan piksel antarbingkai dan batas setiap bingkai untuk sepuluh spesies. Adapter mengunduh commit upstream yang dipatok dan menjalankan Core C# di luar proyek Godot web. Pemberitahuan MIT disertakan pada adapter dan keluaran runtime; dua generasi terpisah telah diperiksa byte identik.

Render Polyfork dapat direproduksi melalui [panduan lokal](polyfork.md). Kredit CC BY 4.0 dan keterangan perubahan menyertai sumber maupun render turunannya. Rujukan moodboard berhak cipta tetap privat dan tidak menjadi aset distribusi.

## Pemeriksaan lokal

- `node scripts/geographic-map-check.mjs` memuat metadata dunia aktual dan memeriksa transformasi koordinat, penanda pemain, pemilihan lokasi, serta sambungan pintu hutan.
- `godot --headless --path client-godot --script ../scripts/godot-creature-animation.gd` memeriksa arah, batas bingkai, dan perubahan piksel animasi untuk sepuluh spesies.
- `node scripts/geographic-map-browser.mjs` memerlukan server uji lokal dan fixture owner privat di `.runtime/browser.json`; pengujian membuat pemain terpisah dan menyimpan hasil ke `artifacts/godot/geographic-map/`.

## Font pixel

Ark Pixel 12px proportional Latin berasal dari rilis resmi 2026.10.25. Berkas OTF, OFL, serta catatan SHA-256 berada di `client-godot/resources/fonts/`. Tema global memakai ukuran dasar 12 px; HUD dan label peta memuat font yang sama. Import Godot menonaktifkan antialias, hinting, mipmap, dan posisi subpixel, dengan oversampling 1. Ukuran teks khusus yang sudah ada dipertahankan. Huruf Latin Indonesia, angka, tanda baca, diakritik, dan panah telah diperiksa terhadap font yang dimuat engine.
