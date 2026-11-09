# 06-A: regresi malam, rumah, dan HUD pada ekspor gabungan

9 November 2026. Regresi memakai API lokal `http://localhost:3100` dan game ekspor sebenarnya pada runtime `2f7f55129c4bafacbf49449d703f3e7913917de3`. SHA-256 PCK sesudah run tetap `a9378a52c9fbb64ec96ae579bcef1ced1ab7920962823025e238a453eb8a716b`, sama dengan penerimaan rute hutan. Tidak ada kode produksi atau harness lama yang diubah.

```sh
VERIFY_COMPACT_NIGHT=1 APP_TEST_ORIGIN=http://localhost:3100 node --import tsx scripts/night-home-browser.mjs
```

Pengujian memakai harness existing dengan satu pemain UUID sementara yang dibuat khusus di MongoDB/Redis lokal. Fixture dimulai pada hari cerita pertama, tahap malam, pukul 19:00, dengan bahan pesanan hari pertama dan satu kangkung. Aksi berikutnya berlangsung melalui formulir login, tombol permainan, perjalanan fisik, serta ikon sentuh. Harness tidak memakai akun pengelola, kredensial akun pengguna, atau fixture tersimpan.

## Hasil

Run berakhir dengan exit 0: **7 pemeriksaan lulus, 8 operasi API utama berhasil, 0 error browser, dan 0 respons API gagal**. Operasinya adalah membuka shift, melayani tiga pelanggan, menutup shift, masuk rumah, tidur, dan keluar rumah.

| Pemeriksaan | Perilaku yang diverifikasi |
| --- | --- |
| Bahan kebun pada pesanan | Satu kangkung dan fragmen pesanan benar-benar dikonsumsi. Pelanggan pertama menghasilkan 145 koin, termasuk bonus kebun 5; dua berikutnya masing-masing 140 tanpa bonus. |
| Dialog hasil malam 667×375 | Dialog penyelesaian tetap aktif pada malam sebenarnya, panel rumah tidak aktif, dan HUD mengikuti rasio layar sentuh. |
| Dialog hasil malam 390×844 | Dialog yang sama tetap dapat ditampilkan pada orientasi potret tanpa kehilangan konteks malam. |
| Penutupan shift | Semua pelanggan hari pertama selesai; hari cerita tetap 1 dan penanda kemajuan tersimpan sampai pemain tidur. Saldo akhir pelayanan menjadi 525 dari saldo awal 100. |
| HUD/bag malam 667×375 | Pusat ikon kontrol berada dalam inset aman yang diemulasikan; bag dibuka lewat sentuhan, menghentikan waktu, melepas input joystick, dan menyembunyikan instrumen O2 saat di daratan. Escape menutup bag. |
| HUD/bag malam 390×844 | Pemeriksaan kontrol, bag, jeda, pelepasan input, dan O2 yang sama lulus pada orientasi potret. |
| Tidur dan reload | Pemain berjalan ke rumah dan dipan. Tidur memajukan cerita sekali ke hari 2, kalender hari 2 pukul 06:00, dan tahap `dive`. Sesudah keluar rumah dan reload, hari, misi selesai, bahan terpakai, dan status di luar rumah tetap tersimpan. |

Inset host diuji melalui probe `.play-safe-area` yang sudah ada dengan nilai kiri 24, kanan 16, atas 12, dan bawah 18 piksel. Harness tidak menyuntikkan state permainan; emulasi ini menguji respons tata letak terhadap inset host. Ia memeriksa pusat kontrol, bukan pengukuran perangkat dengan notch fisik.

Cabang opsional pemeriksaan dua tekanan Enter pada teks yang masih mengetik tidak menghasilkan pemeriksaan tambahan dalam run ini, karena dialog telah selesai mengetik ketika diperiksa. Laporan ini tidak mengklaim cabang tersebut diuji ulang.

## Bukti visual dan pembersihan

Artefak lokal berada di `artifacts/godot/night-home/` dan tidak dibundel:

- `results.json`: tujuh nama pemeriksaan, delapan operasi, bonus/upah aktual, serta daftar error dan kegagalan yang kosong.
- `01-garden-ingredient-served.png` dan `02-shift-closed-pending-sleep.png`: hasil pelayanan dan penutupan shift.
- `02-night-result-dialogue-667x375.png` serta `02-night-result-dialogue-390x844.png`: dialog malam pada dua orientasi.
- `02-night-clear-gameplay-667x375.png` serta `02-night-clear-gameplay-390x844.png`: HUD ketika modal tertutup.
- `bag-night-667x375.png` serta `bag-night-390x844.png`: bag daratan terbuka tanpa O2.
- `03-sleep-advances-morning.png` dan `04-reloaded-morning.png`: hasil tidur dan pagi sesudah reload.

Pemeriksaan manual pada dialog pendek, HUD potret, bag lanskap, dan pagi sesudah reload menunjukkan panel dan kontrol tetap terbaca. Tidak ada desain/aset baru dalam lane ini. Chromium menggunakan SwiftShader di host pengembangan; hasil ini bukan pengukuran performa Windows atau Samsung S23.

Chromium telah ditutup. Sesudah cleanup harness, pemeriksaan baca-saja menggunakan UUID fixture yang diamati selama run menemukan **0 pemain, 0 receipt, 0 shift, 0 kunci surface/home/calendar/dive, dan 0 sesi auth milik fixture itu**. Tidak ada akun lain yang dihapus. Slot GPU/browser dilepas setelah pengujian selesai.
