# Ujang: fase lepas tumpuan pada kamera kiri

9 November 2026. Kandidat source `d3bbc19`, branch `work/06b-foot-boundary-next`, worktree `Jalasmara-06-foot-next`, dibuat dari HEAD view `944f945`. Hanya `UjangFootPlant.gd` diubah; camera-facing rig dan target alat tetap milik agent shelter. Agent shelter menggabungkannya sebagai `e9797e6` dan focused fixture kini lulus; belum dirilis.

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

## Hasil focused sesudah integrasi oleh shelter

Log `Jalasmara-06-view/.runtime/view-ujang-foot-contact.log` sesudah `e9797e6` memuat PASS 1.242 sampel termasuk 168 sharp turns; max pelvis **6.98886826**, alpha-sole stance drift **0.000349122**, knee join **0.000272984**, dan 26 grip poses max error **0.01535710**. Scan read-only seluruh log oleh agent karakter mendapati nol `SCRIPT ERROR`, `ERROR:` atau assertion. Agent karakter tidak menjalankan engine bersamaan. Kegagalan 9.0749 di atas tetap dicatat sebagai sejarah repro yang telah ditutup; batas pelvis8 tetap dipertahankan.

Native `06b-left-runtime/ujang-work.png` telah ditinjau: western head terbaca, kaki penyangga tetap di kanan anatomis, arah rod/line kini ke kiri. Pelampung berada di luar frame gambar closeup, sehingga gambar itu sendiri tidak membuktikan endpoint air. `darmi-work.png` masih tertutup palm, dan `sari-work.png` memotong kepala/torso/alat di atas canvas; agent shelter diminta membetulkan framing. Ketiga pilot memakai zoom3.0, berbeda dari ordinary viewport zoom1.15; tidak mengklaim acceptance visual pada ukuran main atau gerak natural dari still image. Tidak ada native loop baru yang dijalankan oleh agent karakter.

### Review ulang sesudah framing diperbaiki

Agent shelter menulis ulang ketiga gambar pada path yang sama. Review read-only dengan `view_image` terhadap file terbaru:

- `Jalasmara-06-view/artifacts/godot/06b-left-runtime/ujang-work.png`: line turun ke kiri sampai pelampung yang kini terlihat di air; kepala west, tubuh dan kaki penyangga kanan konsisten. Topi sedikit terpotong tepi atas closeup.
- `Jalasmara-06-view/artifacts/godot/06b-left-runtime/darmi-work.png`: Darmi kini terlihat, kepala east, tangan dan kaleng mengikuti sisi yang sama. Palm masih menutupi area bed sehingga gambar ini tidak sendiri membuktikan endpoint tanah; actual-mesh fixture tetap menjadi bukti endpoint.
- `Jalasmara-06-view/artifacts/godot/06b-left-runtime/sari-work.png`: kepala/wajah, torso, tangan, frame tenun dan telapak dapat dibaca bersama; pucuk rambut terpotong sedikit. Tidak terlihat sambungan tangan/tubuh yang terlepas pada pose ini.

Source view terbaru mengarahkan kembali tiga pilot saat work dan mempertahankan arah diagonal pada idle biasa. `village-tool-contact.gd` menambahkan repro Darmi north sesudah incoming `(370,-115)` lalu east ketika memasuki `start_work`. Log focused yang dibaca memuat PASS 480 working samples,260 visible drops,8 view-facing checks dan tidak memuat error. Fishing target memakai inverse view vector dan WaterField; `LandWater3D` sendiri memakai `map_point(logical,-14)`, sehingga `map_point(logical,-11)` konsisten dengan convention world bidang air.

Tidak menemukan mismatch anatomis/tangan baru yang menghalangi pada tiga still terbaru. Ini penerimaan komponen statis setelah framing dibetulkan, tetap bukan bukti seluruh arah artwork original, natural walk Darmi/Sari, ordinary play-size atau browser/S23 fisik. Seluruh render dilakukan agent shelter pada slotnya; review karakter hanya membaca source/log/gambar.
