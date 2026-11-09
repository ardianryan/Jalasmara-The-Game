# Nala: giliran arah dan berhenti dari langkah

9 November 2026. Branch `work/06b-nala-gait-next`, worktree `Jalasmara-06-nala-next`, dibuat dari main/rilis lokal `f319da9`. Rilis tersebut tidak diubah. Ownership runtime hanya `CharacterVisual.gd`; tidak mengubah `Player`, collider, NpcBodyRig, LandActors, state/API atau aset gambar. Laporan ini checkpoint source sebelum slot engine.

## Diagnosis dari artwork dan runtime sebenarnya

Runtime darat sudah memakai12 set ×8 arah yang digambar, bukan fallback cutout lama. Dua atlas MC male_nusantara daily/explorer memperlihatkan contact terbuka, kaki melewati bawah badan, tekukan lutut dan ayunan tangan. Source still tidak membuktikan semua telapak terkunci ke lantai; sebagian contact memang lebar dan perubahan tinggi sole ada di aset. Jangan menyebut inspeksi hash sebagai natural-walk acceptance.

Dua cacat transisi dapat diperbaiki tanpa menggambar ulang tubuh:

- Requested facing langsung mengganti row seluruh tubuh sampai180°, tanpa lewat pandangan antara; peralatan mengikuti requested row yang sama secara mendadak.
- Berhenti dari pose lutut terangkat langsung memilih neutral idle. Tidak ada urutan menurunkan kaki, walaupun artwork menyediakan pose perantara. Uji lama memeriksa row dan distance, bukan urutan berhenti/berbelok.

## Perubahan bounded

Rendered facing melewati octant tetangga, satu row tiap4unit perpindahan aktual, memakai jalur terpendek. Requested input dan arah server tidak ditunda; `_travel` serta contact/foley half-stride tetap membaca jarak nyata. Pose dan tank/tas/net memakai **rendered** direction/phase yang sama sehingga gear tidak berbalik lebih dahulu. Tidak ada mirror atau deformasi tungkai.

Polish berhenti berlaku pada **male_nusantara daily dan explorer** yang diperiksa. Pose3 turun lewat2→1 sebelum neutral; pose7 lewat6→5. Pose0/4 memakai lowering1/5. Masing-masing pose ditahan50ms, maksimum150ms biasa; hingga200ms bila giliran180° yang belum selesai perlu satu hold landing tambahan. Ini gerak visual lokal, tanpa perpindahan root, tambahan travel atau langkah palsu. Outfit/identitas lain mempertahankan perilaku berhenti lama, sementara giliran arah memakai delapan pandangan yang sudah tersedia untuk seluruh12set.

Pause lingkungan, host dan owner.frozen membekukan frame serta antrean landing. Reduced motion tetap mendapat gerak langkah esensial. `phase` tetap distance phase; `posePhase`, `poseWalking`, `settling` dan `poseFrozen` menjelaskan pose yang benar-benar ditampilkan. Peralatan memakai posePhase selama landing, dan kembali netral saat selesai.

**Batas yang sengaja tidak disembunyikan:** restart tetap mengambil fase dari jarak yang dipertahankan; belum ada interpolation restart yang digambar khusus. Tidak ada perbaikan painted sole world-lock, seluruh karakter masih bitmap dengan pivot, dan clipping/silhouette semua768frame belum merupakan analisis anatomi. Normal walk cycle dan gambar tidak diubah; jangan menyatakan keluhan kaki membuka/menggunting sudah selesai menyeluruh dari paket ini.

## Bukti source/CPU

Inspeksi `view_image` terhadap atlas runtime dan lembar4kolom ×8arah: `artifacts/godot/nala-gait-source-review/{daily,explorer}-{first,second}-lowering.png`. Urutan kolom adalah3→2→1→neutral atau7→6→5→neutral. Garis lantai dan teks ditambahkan hanya pada artefak review; tidak masuk resource game.

Hash atlas MC yang tidak diubah:

- daily `342724d1724490279cd0f65c0340c5b35cdf366ecc36a99af716c51f751b8fc3`
- explorer `a429c378400bd5ac60a45124ac48672b4cb1360beb379cc83297b52ea48ae3b9`

`python3 tools/player-gait/test_eightway.py` PASS: source/output hashes,12sets,768frames,96idle; log `/tmp/nala-eightway-source-check.log`. CPU model memeriksa8 starting phases dan64 pasangan octant: rute lowering tetap satu half-cycle, jalur arah shortest-neighbor, tanpa perubahan jarak. `git diff --check` PASS. Tidak ada Godot/browser dijalankan pada checkpoint ini.

Focused `player-locomotion.gd` tetap terdaftar pada runner dunia dan sekarang menambah sequence stop3/7,180/90turn, pose/gear agreement, clock/host/owner pause, normal/reduced, no-root-motion dan no-new-foley. Native opsional `NALA_GAIT_CAPTURE=1` menyimpan rangkaian PNG serta `results.json` pada `artifacts/godot/nala-gait-transitions`. Ini fixture runtime komponen2D dari bitmap yang sama, bukan fullworld/HP acceptance. `player-batch-render.gd` memeriksa idle sesudah200ms dan tidak lagi menuntut hard-cut idle di frame pertama.

## Gate berikutnya

Ambil slot engine hanya sesudah integrator memberi grant. Import dan jalankan focused `player-locomotion`, `locomotion-collision-foley`, `land-left-gameplay`, `character-outfits`; scan seluruh log. Render sequence native, tinjau frame kaki/badan dan gear, lalu minta integrator menilai apakah pilot diterima. Jika fixture gagal, perbaiki source; jangan melonggarkan cadence/distance/sole tolerances atau menyebut frame statis sebagai naturalwalking.

Tool aktual: Git/worktree, ripgrep, Python3+Pillow untuk artefak review, `view_image`. Tidak ada raster baru, API SpriteAI, image generation, library atau lisensi baru; seluruh atlas original tetap byte-for-byte seperti rilis. Release/handoff utama tetap milik integrator.

## Hasil engine checkpoint 5d52aba

Integrator memberi slot, kemudian agent karakter menjalankan import, focused dan native bergantian, lalu melepas slot dan memeriksa tidak ada proses Godot tersisa. Paket source berurutan: `375a7bb`, `b79a3a7`, `5d52aba`. Perbaikan tambahan memastikan pending turn selesai dari neutral pada seluruh12set, sedangkan lowering pilot tetap dua outfit MC.

- `nala-focused-final.log`:144 stop/turn samples normal/reduced serta baseline12×8 PASS; owner/host/clock pause dan frame/gear agreement teruji.
- `nala-collision.log`: controller100px/s mengenai bangunan solid, travel berhenti dan3 event langkah tetap; noextraSFX PASS.
- `nala-left-gameplay.log`:60 actual Player/Forest controller/connector checks PASS, termasuk distance phase dan pause; ini regresi kontrol sebenarnya, berbeda dari native komponen.
- `nala-outfits-final.log`:4identitas×3outfit dan equipment independen PASS.
- `nala-native.log`: focused yang sama PASS pada Godot4.7.2 Compatibility/AppleM2;496 PNG berurutan beserta results.json. Bukan benchmark FPS atau perangkat Windows/S23.

Semua path log di `.runtime/` worktree ini; bersama `nala-import-final.log`, scan6log penuh nol `SCRIPT ERROR`, `ERROR:` atau assertion. Collision fixture mengeluarkan warning4ObjectDB instance leak pada exit; warning identik juga ada pada log baseline integrasi `world-check/scripts-tests-locomotion-collision-foley.gd.log`. Tidak mengklaim leak baru diperbaiki oleh paket ini.

Iterasi gagal tersimpan sebagai sejarah: import pertama kehilangan font-cache, lalu import ulang bersih; test awal perlu tipeint eksplisit untuk index arah; legacy row test hanya menerima14unit padahal kandidat worst-case180° memakai16unit, sehingga interval aktualtest dijadikan17.5unit; static preload CharacterVisual dalam outfit test belum mengenal autoload identifier, diperbaiki dengan lookup root-node. Gate akhir di atas dijalankan sesudah perbaikannya, bukan hanya membaca exitcode0 dari error Godot.

### Bukti urutan native yang ditinjau

Folder `artifacts/godot/nala-gait-transitions/` berisi `0000.png`…`0495.png`, `results.json`, dan `transition-contact-sheet.png` (32pose actual native terpilih). Contactsheet memperlihatkan kaki terangkat turun lewat passing/lowering sebelum neutral serta tubuh berputar memakai row antara; gambar dirender2× dan diberi garis referensi baseline. Ini gambar dari Sprite2D runtime komponen, tidak mengukur actualopaque sole terhadap triangle lantai3D. Tank/tas/net diuji state/row-nya, tidak digambar dalam fixture komponen ini.

Daily normal:stop3 frame0012–0023,stop7 frame0040–0051,pause0069–0071,resume0074–0085,turn180 frame0106–0117,turn90 frame0118–0123. Explorer normal memakai index+248; blok reduced masing-masing+124 dan+372. Semua gambar dibaca dari file setelah engine berhenti; tidak ada browser/game render kedua bersamaan.

CPU audit lanjutan mempertahankan dua batas nyata: restart neutral0023→walk0024 mengambil lagi raw phase3 sehingga knee pop belum ditutup; pada cadence175px/s/30Hz, loop facing berpotensi melewati dua octant pada satu update. Temuan stress-turn dikirim ke integrator untuk bounded followup sebelum penerimaan. Jangan menyebut checkpoint ini natural walk lengkap atau menganggap still membuktikan world-space footplant.
