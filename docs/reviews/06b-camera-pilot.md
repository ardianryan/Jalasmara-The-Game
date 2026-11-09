# Kamera kiri dan alignment Griya: pembanding native 06-B

9 November 2026. Kandidat integrasi mencakup helper kamera `93ae5ca` dan alignment Griya `b765587`. **Default gameplay masih azimut0/elevasi35**. Gambar kiri adalah pembanding mesh sebenarnya, bukan bukti bahwa input, seluruh NPC, canopy dan penanda dunia sudah dipindahkan ke kamera diagonal global.

## Perubahan dan keputusan pengguna

`LandCameraPose.gd` menerjemahkan perhitungan orbit/snap Noxe ke sumbu Z-up Godot. Default menghasilkan posisi/basis yang sama dengan kamera lama. Helper menyediakan pose ortografis, proyeksi layar dan ray ke tinggi yang diketahui; fixture memakai kamera kiri azimut−45 dengan elevasi30 serta35,26438968. Peta dan karakter tidak dicerminkan. Arah perjalanan kiri→kanan dapat diproyeksikan dari kedua sisi kamera; pengguna memilih sisi kiri sebagai arah seni.

Pengguna kemudian mengoreksi bahwa rumah di atas dermaga tidak sejajar dek. Pemeriksaan source menemukan footprint rumah sudah diskew dalam koordinat map, sementara dek mengikuti sumbu map. Pernyataan sebelumnya bahwa dua sisi rumah terlihat belum membuktikan alignment. Fix Griya memakai rectangle(78,420,164,145), pusat sama, aisle38 setiap sisi. Fasad, atap, serambi dan post mengikuti footprint itu. Native test memeriksa sumbu rumah/dek/roof yang sama dengan dot0; footprint lama mempunyai dot−0,212585. Ini koreksi geometri, bukan pencerminan atau penggantian sudut kamera untuk menyamarkan masalah.

## Bukti yang dijalankan integrator

- Tes `land-camera-pose.gd` di runner gabungan awal lulus480 sampel Camera3D nyata: tiga viewport, lima pose, snap on/off, empat tinggi dan empat offset. Proyeksi helper cocok dengan `unproject_position`, ray kembali ke tinggi asal, pose legacy mempunyai parity dan pose isometrik kiri memberi panjang proyeksi sumbu yang sama. Batas proyeksi0,002px, ray0,01 world unit.
- Fixture `land-quarter-pilot-render.gd` sesudah alignment menghasilkan18 frame: low/balanced × day/night/rain × legacy/quarter-left/isometric-left. Seluruh log bebas SCRIPT ERROR/ERROR/Assertion. Metadata mencatat azimut−45; galat telapak layar maksimum0,0000610352px, di bawah batas0,01px.
- Iterasi awal memanggil update dengan delta0 sehingga clock cuaca tidak mencapai interval0,25detik. Fixture diperbaiki menjadi0,5detik; gambar akhir malam memang gelap dengan lampu menyala. Material cutaway juga diperbarui setelah pose pilot aktif, mengikuti basis kamera sebenarnya.
- Integrator meninjau gambar siang/malam kiri pada ukuran480×270. Dinding, atap dan dek sekarang mengikuti dua arah yang sama; balok/tiang bawah dek terbaca dan lampu rumah memberi aksen malam. Gambar sebelum alignment disimpan terpisah di worktree shelter, bukan digunakan sebagai bukti final.

Artefak integrator: `artifacts/godot/06b-quarter-pilot/results.json`,18 PNG bernama eksplisit `left-minus45`, dan `.runtime/06b-left-camera-final.log`. Gambar tidak dimasukkan sebagai aset game. Laporan konstruksi/API serta49 sampel migrasi CPU ada pada [review shelter](06b1a-shelter-architecture.md).

## Tool, atribusi dan batas

Godot4.7.2 Compatibility dijalankan native AppleM2, secara bergantian dengan pengujian subagent. Port hanya perhitungan kamera dari Noxe `d619d856398b44ad084003fac0a9fbfc9c8393e7`, ©2026 Daniel Jankulovski/MIT. Notice lengkap pada `client-godot/resources/licenses/noxe-MIT.txt` ikut filter export `.txt`; [daftar lisensi](../../THIRD_PARTY_LICENSES.md) dan [audit Noxe/PixelDoll](../world/noxe-pixeldoll-reference.md) diperbarui. Tidak ada runtime Three.js, shader multipass, aset demo atau exporter upstream yang disalin. Rumah ditulis sebagai modul native Godot.

Fixture mengkalibrasi satu aktor statis pada tinggi lantai yang diketahui melalui subclass pengujian. Itu bukan adapter produksi bagi seluruh aktor/input. Embedding map lama memberi kompensasi tinggi, sehingga kamera diagonal memerlukan inverse screen-to-map, follow pada elevasi aktual, visual facing terpisah dari jarak gait, canopy-right dari basis kamera, serta penanda/equipment yang konsisten. Pada batas pandang kiri, tepi water backing juga perlu diperiksa sebelum penerimaan global. Kontrol/hutan/HUD browser tetap memakai default sampai paket adapter itu lolos.

Hard Gate PASS untuk pembanding: source/tes/native benar-benar dijalankan, tidak ada kontrol baru atau klaim FPS/perangkat. Purpose Gate PASS: helper menyatukan rumus kamera, alignment memperbaiki kesalahan sumbu dan aisle menjaga akses. Liveliness PASS: ENERGY2/RHYTHM2/MOTION1 mengikuti brief comfy pesisir, rumah/kolong menjadi fokus dan lampu memberi aksen malam. Craftsmanship PASS dalam ruang lingkup fixture:480 sampel dan18 frame diperiksa, perbedaan pilot/default serta batas interaksi dinyatakan. Gate kamera gameplay global tetap terbuka.
