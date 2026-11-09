# Regresi browser paralel: malam dan HUD ringkas

## Kesiapan versi

Pengujian dimulai sesudah root menyatakan **NEWEXPORT READY**, 9 November 2026 pukul 12.08 WIB. Kandidat runtime mencakup `7ff41a7`, dengan HEAD saat pencatatan `41b36b8e66d6527714a7f477e6a17f1811f23520`. SHA-256 PCK lokal yang diuji: `18a8fc08061b9f31308bdc100b809a4c6e0709724956272209b67c63ac5f0a6c`.

Browser menggunakan `http://localhost:3100`, Chromium dengan SwiftShader. Engine Godot yang sebenarnya dimuat melalui iframe aplikasi; tidak ada engine tiruan. Akun pengujian dibuat khusus dengan UUID acak. Akun owner dan fixture pengujian agen lain tidak diubah.

## Putaran malam

```sh
VERIFY_COMPACT_NIGHT=1 APP_TEST_ORIGIN=http://localhost:3100 \
  node --import tsx scripts/night-home-browser.mjs
```

Hasil: exit 0, **7 pemeriksaan lulus, 8 operasi server**, tanpa error browser atau respons API 4xx. Alur yang benar-benar dimainkan:

1. Berjalan ke Kedai Waras dan membuka pelayanan malam.
2. Melayani seluruh pelanggan hari pertama dengan fragmen nyata; satu kangkung dikonsumsi untuk bonus 5 koin sekali.
3. Menutup pelayanan; hari cerita tetap 1 dan hak kemajuan disimpan sampai tidur.
4. Memasuki rumah, berjalan ke dipan, tidur, keluar, lalu reload.
5. Hari cerita dan kalender menjadi 2; hasil pelayanan, konsumsi kangkung, dan status rumah bertahan.

Mode tambahan memperlihatkan dialog hasil, dunia malam sesudah dialog ditutup, dan tas pada **667×375** serta **390×844**. Insets 24 kiri, 16 kanan, 12 atas, dan 18 bawah disimulasikan melalui CSS probe host yang sebenarnya. Ini emulasi ruang aman, bukan pengujian notch fisik. Pusat kontrol berada dalam batas aman; aspek canvas mengikuti viewport. Membuka tas melalui sentuhan menjeda jam dan melepas input gerakan; Escape menutupnya.

Gambar diperiksa langsung. HUD ringkas tetap menyisakan dunia yang terlihat pada lanskap pendek. Tas dan dialog menyembunyikan kontrol gameplay; tombol Menu milik host tetap tersedia. Teks tas terbaca dan tidak terpecah per karakter. Snapshot dialog saat teks sedang muncul tidak dipakai untuk menilai kelengkapan seluruh kalimat.

Bukti lokal: `artifacts/godot/night-home/results.json`, `02-night-clear-gameplay-667x375.png`, `02-night-clear-gameplay-390x844.png`, `02-night-result-dialogue-*.png`, `bag-night-*.png`, serta `04-reloaded-morning.png`.

Sesudah browser ditutup, cleanup menghapus hanya akun UUID pengujian beserta receipt, shift dan sesi miliknya.

## Putaran Plan04 sebelum pembaruan web terakhir

Pengujian `VERIFY_QUALITY=1` pada PCK yang sama lulus **15 pemeriksaan**, tanpa error. Cakupannya mencakup rotasi layar, tas/jurnal/peta/misi, joystick dua jari, kalender server yang tetap saat menu terbuka, penolakan pesan host palsu, profil kualitas yang benar-benar diterapkan Godot, dan fullscreen browser.

Putaran ini selesai sebelum pembaruan web terakhir untuk tautan kegagalan loading diterapkan. Karena itu, hasilnya membuktikan integrasi engine/HUD pada PCK tersebut, bukan tautan web terakhir. Root kemudian menyatakan **WEBFINAL/API READY**, bundle `index-BDELBY0B.js`; pemeriksaan final terhadap bundle ini selesai dengan hasil di bawah.


## Putaran web final dan sentuhan

Sesudah pemberitahuan **WEBFINAL/API READY**, pemeriksaan Plan04 diulang pada bundle `index-BDELBY0B.js` dan PCK yang sama. Hasil final: **15 pemeriksaan lulus, tanpa error browser**. Kalender server tetap pada menit yang sama selama menu terbuka melewati heartbeat berikutnya; jam visual juga berhenti. Pesan dari sumber/origin/versi yang salah tidak dapat mengubah kualitas atau melepas jeda. Dropdown host benar-benar mengubah profil Godot menjadi low, balanced, dan auto; pada emulasi coarse pointer, auto memilih low. Fullscreen, rotasi dengan atlas terbuka, dialog/panel, serta joystick dua jari tetap bekerja.

Setelah browser tersebut ditutup, `scripts/godot-touch.mjs` dijalankan terhadap akun uji lokal yang sama, tanpa reset posisi atau perubahan progres melalui API bypass. Hasil: **7 pemeriksaan lulus, tanpa error browser**:

- Navigasi joystick horizontal dan vertikal melalui rute desa yang sebenarnya.
- Dead zone dan pelepasan joystick.
- Memulai penyelaman melalui tombol aksi.
- Berenang dan menjala target biasa tanpa membuka kuis.
- Rotasi ke potret tetap mempertahankan sesi penyelaman.

Bukti final: `artifacts/godot/plan04/results.json`, screenshot panel/menu/atlas di folder tersebut, serta `artifacts/godot/touch-results.json` dan `touch.png`. Tangkapan layar sentuh diperiksa: fauna dan terrain asli tampil; indikator O2, aksi, dan joystick terlihat. Baris maksimum O2/bobot berada dekat bingkai bawah instrumen, dicatat sebagai pemolesan kecil, bukan kegagalan gameplay.

Jumlah putaran yang dilaporkan: **7 malam + 15 Plan04 + 7 sentuhan = 29 pemeriksaan**. Browser terakhir sudah ditutup. Akun khusus sentuhan, receipt/shift/sesi miliknya, dan berkas fixture privat dihapus secara terarah; akun owner tidak diubah.

## Batas bukti

Ini pengujian Chromium lokal dengan emulasi sentuh dan software GPU, bukan pengujian Windows atau Samsung S23 fisik. Telemetri FPS/waktu proses/draw calls tersedia, tetapi angka dari CPU bersama tidak diperlakukan sebagai benchmark perangkat. Tidak ada deploy, perubahan proxy, atau pembuktian HTTPS produksi dalam pekerjaan ini.
