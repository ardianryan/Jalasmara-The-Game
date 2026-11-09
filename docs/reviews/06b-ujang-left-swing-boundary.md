# Ujang: fase lepas tumpuan pada kamera kiri

9 November 2026. Kandidat source `d3bbc19`, branch `work/06b-foot-boundary-next`, worktree `Jalasmara-06-foot-next`, dibuat dari HEAD view `944f945`. Hanya `UjangFootPlant.gd` diubah; camera-facing rig dan target alat tetap milik agent shelter. Belum dirilis atau dinyatakan lulus engine.

## Repro actual yang diterima

Agent shelter menjalankan focused fixture pada runtime view kiri dan mendapatkan satu sampel gagal; rig baru menghasilkan kegagalan sama. Log sumber: `Jalasmara-06-view/.runtime/view-ujang-foot-contact.log`.

- Aktor `(910.3999,1360)`, arah east, `turn=false`.
- Requested pelvis `9.0749044`, melebihi batas tetap `8`.
- Left swing phase `.5619970703125`, right stance phase `.0619970703125`.
- Left sole `(889.2021,-2366.806,0)` masih sama dengan plant; right sole `(921.4529,-2377.441,0)`.

Fixture lama lulus pada paket kamera sebelumnya. Ini kegagalan kandidat kiri yang harus ditutup, bukan alasan memperbesar toleransi atau mengabaikan sampel.

## Penyebab dan perubahan bounded

Saat gerakan melewati batas stance `.5`, `_begin_swing()` menyimpan `startProgress=(phase-.5)*2`. Update yang sama kemudian mengurangi nilai tersebut dari progress; hasil selalu `u=0`. Kaki yang baru bebas tertahan pada lokasi tumpuan lama, tanpa lift, selama seluruh jarak yang sudah diterima pada frame crossing itu. Pada kamera diagonal, kedalaman dan proyeksi hip membuat keterlambatan ini meminta pelvis terlalu rendah.

Startup dan handover turn memang harus mulai dari pose saat itu. Kandidat menambah argumen opsional `from_stance_boundary`, dipakai **hanya** saat normal stance beralih ke swing. Kasus itu mulai pada progress nol dari batas swing, sehingga update frame berjalan mengonsumsi overshoot. Startup dan turn tetap memakai perilaku lama. Sole yang masih grounded tetap terkunci world-space; panjang tungkai, batas pelvis, stride dan toleransi tes tidak berubah.

Pemeriksaan CPU dengan Python3 pada fase log memberikan:

| Nilai | Sebelum | Kandidat |
| --- | ---: | ---: |
| Swing `u` | 0 | 0.123994141 |
| Lift | 0 | 1.291191027 |
| Smooth travel weight | 0 | 0.042310933 |

Ini bukti perbaikan integrasi fase, **bukan** bukti bahwa seluruh kontak sudah lulus. Source diff bersih terhadap whitespace; tidak ada Godot/browser dijalankan oleh agent karakter pada checkpoint ini.

## Gate berikutnya dan pembagian kerja

Agent shelter menerima kandidat untuk digabungkan ke source view miliknya lalu mengulang `ujang-foot-contact` lengkap (1.242 kontak, sharp turns, stop/reduced, grip independen), dengan scan seluruh log `SCRIPT ERROR`/`ERROR`. Jika masih gagal, periksa `swingFrom`, `swingTo`, `startProgress` dan actual alpha sole sampel tersebut sebelum merancang perubahan lain. Jangan merilis hanya karena CPU math lulus.

Review native Ujang/Darmi/Sari kamera kiri masih menunggu gambar. Saat checkpoint ini dibuat, worktree view belum mempunyai direktori `artifacts/`; tidak ada gambar baru yang diklaim sudah ditinjau. Review source alat/facing terdahulu ada di `06b-left-rig-source-audit.md` (commit doc-only `39fbeca` pada branch dialog), dan agent shelter sedang memperbaiki target air serta orientasi kerja stasiun.

Tool aktual: Git/worktree, ripgrep, Python3 standard-library; tanpa aset, generator gambar, API berbayar atau dependensi baru. Tidak ada perubahan lisensi.
