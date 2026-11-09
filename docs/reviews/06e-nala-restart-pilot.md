# Nala: calon restart rendah, pandangan east terbatas

9 November 2026. Cabang `work/06e-nala-restart-pilot`, worktree `Jalasmara-06-nala-restart`, basis source `11c75762b4616f82efa324941fe7e101170d64cd`. Paket stop/turn yang sedang diperiksa integrator tidak diubah. **Calon ini baru diperiksa CPU; belum diimpor, dijalankan oleh Godot, dinilai native, digabung, atau dirilis.** Integrator tetap pemilik handoff/rilis.

## Repro dan perubahan

Native integrator 592 frame pada `Jalasmara/artifacts/godot/nala-gait-transitions/results.json` masih memperlihatkan neutral pada distance24, lalu lutut tinggi walk3 pada26. Root-distance yang diterima hanya2, tetapi bitmap langsung kembali ke pose sebelum stop. Hasil native itu milik source sebelumnya; bukan bukti calon ini berjalan.

`CharacterVisual.gd` memakai low pose2 sampai half-stride contact aktual berikutnya untuk satu kasus yang telah diperiksa: `male_nusantara`, daily/explorer, east, fully settled, rawframe3, gerak hampir mendatar ke kanan layar, dan displacement pertama paling banyak4 view-unit. `_travel`, collider, akselerasi, fase mentah, hitungan contact/foley, urutan arah dan peralatan tetap. PosePhase yang diberikan kepada tas mengikuti low pose2 yang benar-benar tampil; saat distance mencapai contact32, pose mengikuti rawphase lagi. Berhenti/pause/berganti arah atau pakaian membatalkan/menahan transisi melalui alur yang sama dengan source sebelumnya. Frame3 yang lebih pendek/bertelapak miring tidak dilewati pada restart pilot ini.

Halfcycle7, arah lain, identity lain, partial landing dan first-step besar tetap fallback lama. Ini sengaja tidak menjanjikan startup semua arah dari metadata yang belum ada. Tidak ada timer yang menghasilkan langkah, root inertia, bitmap warp, atau raster baru.

## Anotasi dan model

[`restart-support-east.json`](../../tools/player-gait/restart-support-east.json) menyimpan SHA256 empat atlas existing, heel/toe pada pixel opaque asli, serta batas anotasinya. Mark berada pada **visible lower supporting shin** dari pandangan east. Artwork seluruh badan tidak memberi identitas kiri/kanan independen yang dapat dipastikan dari piksel ini; `physicalSide` ditandai `unassigned`, bukan diberi label anatomis palsu. Footprint0/4 dan pose1/5 juga sangat mirip secara silhouette sehingga nama fase generator bukan bukti pergantian kaki.

Model menghitung perpindahan marker yang telah ditandai ditambah perpindahan root yang diproyeksikan oleh formula `LandCameraPose`/`LandViewProjection`, bukan centroid alpha. Model berhenti **sebelum handover contact32**; ia tidak menyambungkan dua kaki berbeda seolah satu support terus bertahan. Batas per-step4 view-unit mencegah low pose dipakai pada displacement awal besar yang justru dapat membuat marker lebih jauh dari baseline.

Command CPU yang sudah dijalankan:

```sh
python3 tools/player-gait/test_restart_support.py --output artifacts/godot/nala-restart-source
git diff --check
```

Hasil: **112 trace heel/toe PASS**, pada dua pakaian; mencakup model akselerasi850 pada30/60/120Hz, repro komponen100px/s50Hz, dan variasi view-step. Maksimum perpindahan marker per sampel dan jumlah drift tidak lebih buruk dibanding neutral→raw3 pada path identik. Contoh model daily60Hz: toe max12,710→3,710 view-unit, jumlah drift20,531→11,531. Nilai bukan pixel layar fisik atau bukti telapak world-lock. Drift masih ada: seluruh badan masih satu gambar; heel/toe ini bukan socket 3D independen.

Artefak CPU yang dilihat melalui `view_image`:

- `artifacts/godot/nala-restart-source/annotated-support-east.png`: idle/low2/raised3, daily+explorer, semua mark di atas karya sumber.
- `artifacts/godot/nala-restart-source/support-model.json`: hasil112 trace baseline/candidate.

## Pemeriksaan runtime yang disiapkan, belum dijalankan

Fixture `scripts/tests/player-locomotion.gd` yang sudah terdaftar pada runner ditambah kasus pilot/fallback, pause saat low pose, nol perpindahan/collision-stop, true contact32, gear-row/phase, dan normal/reduced pada30/60Hz. Ia juga menginstansiasi **Player aktual** beserta `LandCollision` dari `.runtime/world-map.json`, memakai inverse input kamera kiri serta visual-motion projection actual helper. Akselerasi/decelerasi850 berasal dari controller, kemudian diperiksa bahwa distance visual sama dengan perpindahan collider dan contact hanya keluar sekali. Bagian ini masih pending Godot; model Python tidak dianggap menggantikannya.

Pada slot engine berikutnya: import, focused default player-locomotion, regresi collision/foley dan left gameplay, scan **seluruh** log untuk `SCRIPT ERROR`/`ERROR`, lalu capture `NALA_GAIT_CAPTURE=1` dan tinjau urutan restart ukuran main. Uji helper kamera ini memakai flat projection; bukti lereng/floor3D, browser actual, Windows/S23 dan anatomis L/R masih belum tersedia. Jangan menggabungkan calon sebelum integrator menerima rangkaian native dan batas ini. Jika low2 menimbulkan sliding atau kelainan lain pada runtime, simpan kegagalannya dan perbaiki/hold; toleransi model tidak dilonggarkan untuk memaksakan lulus.

Tool yang dipakai: Python3, Pillow untuk bukti sumber, pembacaan source/JSON, `apply_patch`, Git dan `view_image`. Tidak ada API key, layanan berbayar, imagegen, aset moodboard, lisensi/dependensi baru, Godot/browser pada checkpoint ini. Notice Pillow existing tetap berlaku; atlas original proyek tidak ditulis ulang.
