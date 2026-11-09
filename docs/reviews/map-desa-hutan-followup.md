# Tindak lanjut peta desa dan hutan

Baseline: `3d648e851940184148857d45025ce75c89470417`. Pekerjaan dilakukan pada branch `work/map-desa-hutan` di worktree tersendiri.

## Hasil audit

- Hutan sudah mempunyai dua penyeberangan berbeda, `bridge_upper` dan `bridge_lower`. Papan mengikuti sumbu masing-masing jembatan; balok samping, ketebalan dek, dan pagar memakai data bersama. Tidak perlu menambah jembatan atau mengganti rutenya.
- Fondasi visual pada ujung jembatan sebelumnya hanya berupa batang melintang di bawah dek. Belum ada volume yang mengikat ujung dek dengan bentuk tepian sungai yang sebenarnya.
- Tangga sudah mempunyai tread dan riser, tetapi sisi bentangnya terbuka. Pada elevasi desa, anak tangga dapat terbaca sebagai lembaran tipis yang menggantung.
- Balai tetap beratap bertingkat. Rumah pelana dan limasan sudah mempunyai bubungan serta pengaku kayu. Tidak ada perubahan atap dalam perbaikan terbatas ini karena temuan yang ditangani berada pada sambungan tanah–penyeberangan.
- Kantor kontainer milik pos Raka sudah tersedia. Tokoh direktur/RV baru belum menjadi identitas cerita yang ditetapkan; audit ini tidak menambah NPC, bangunan duplikat, transaksi, atau misi.
- Jadwal warga memakai kalender server 36 menit dan rute/elevasi yang sudah diuji. Tidak ada perubahan pada kalender maupun simulasi warga.

## Perubahan

`BridgeLandings.gd` menghitung potongan fondasi pada kedua ujung jembatan. Setiap potongan berada di bawah area ujung dek sepanjang paling banyak 64 unit atau seperempat panjang jembatan. Bentuknya dipotong oleh polygon dek yang sudah ada dan wajib mempunyai irisan kontak dengan lantai tepian/dek yang memang dapat dipijak pada elevasi yang sama. Bagian kecil yang mengarah ke sungai tetap berada di bawah lantai jembatan; tidak ada perluasan lantai. Minimal 20% luas fondasi harus mempunyai kontak tepian; irisan kecil yang tidak cukup menopang ditolak. Dekorasi jalur tidak dianggap sebagai tanah baru.

`LandWorld3D.gd` merender fondasi batu di bawah bidang pijakan. Papan dan pagar yang sudah ada tetap dipakai. Sisi tangga dan ramp ditutup sampai dasar bentangnya sehingga tread tidak terlihat menggantung. Geometri baru ikut pengelompokan material statis yang sudah tersedia.

Tidak ada perubahan pada polygon lantai, collider, elevasi pijakan, kamera 35°, warna dunia, air, portal, ID save, atau keputusan server. Tidak ada aset bitmap baru.

## Berkas

- `client-godot/scripts/land/BridgeLandings.gd` dan sidecar UID-nya
- `client-godot/scripts/land/LandWorld3D.gd`
- `scripts/tests/map-grounding.gd`
- Dokumen tinjauan ini.

## Verifikasi

Pemeriksaan sumber: `git diff --check` lulus. Import resource dari worktree bersih berhasil dengan dua tahap pemuatan font; berkas project dipulihkan sesudah import.

Regresi geometri berjalan pada Godot 4.7.2 Compatibility native dan lulus: tiga jembatan, enam fondasi, seluruh kontak tepian/dek valid, dua sisi untuk setiap anak tangga/ramp, dan WORLD tidak berubah. Headless final juga lulus, termasuk penolakan fondasi tanpa bank dan bank yang hanya berupa irisan kecil. Regresi `land-renderer.gd` tetap lulus: 16 pijakan pada empat elevasi, kamera 35°, pengelompokan mesh tetap dalam anggaran, pagar dan transisi penyelaman tidak berubah. Gambar native diperiksa sesudah ukuran fondasi disesuaikan agar pengikat di bawah papan pertama terlihat.

Gambar lokal berada di `artifacts/godot/map-followup/forest.png` dan `hub.png`, dengan pembanding baseline `before-forest.png` serta `before-hub.png`. Pijakan, bentuk rute dan pagar tetap sama; perubahan yang terlihat terbatas pada pengikat bawah ujung dek dan penutupan sisi tangga. Tidak ada klaim pengujian browser publik atau perangkat HP untuk branch ini.

Perintah regresi setelah fixture WORLD tersedia dan resource diimpor:

```sh
GODOT_BIN=/path/to/godot
"$GODOT_BIN" --headless --path client-godot --script ../scripts/tests/map-grounding.gd
"$GODOT_BIN" --path client-godot --script ../scripts/tests/map-grounding.gd -- --capture
```

Tes memeriksa tiga jembatan yang sudah ditetapkan, fondasi di kedua bank, seluruh titik fondasi berada pada dek, kontak fondasi berada pada tepian dan dek, pagar tetap dihasilkan, dua sisi penopang untuk setiap tread/ramp, serta WORLD tidak berubah. Ini pemeriksaan geometri dan renderer; tidak menggantikan pengujian permainan pada perangkat nyata.
