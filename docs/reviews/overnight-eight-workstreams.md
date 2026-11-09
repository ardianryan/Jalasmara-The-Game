# Penyelesaian delapan jalur malam ini

Arahan pengguna: lanjutkan seluruh delapan pekerjaan, maksimalkan subagent dan gunakan branch bersama yang terisolasi. Baseline main `d070a7b`; runtime aktif tetap sourceb5b459e/PCK5f5baf sampai rilis berikutnya benar-benar diuji.

| Jalur | Pemilik | Hasil yang dikerjakan | Batas penerimaan |
|---|---|---|---|
| 1 Loading publik | Root/integrator | Isolasi serial header/cache/jalur transfer; perbaikan yang berdasarkan hasil | Actual browser default ready dan gameplay, bukan health/curl saja |
| 2 Gerak Nala | Character | Integrasikan pilot restart, perbaiki pose/loop seluruh badan dan gear | Sequence/contact/controller + native dan actualbrowser |
| 3 Performa | Website/perf | Pengukuran sebelum/sesudah, update visual yang terukur, alat ukur perangkat | Pisahkan emulator/Mac dari Windows/S23 fisik; jangan mengarang FPS |
| 4 HUD/dialog | Website | HUDmalam ringkas, buku/kuis/dialog responsive, menu tidak menghalangi | Actual viewports, teks panjang, touch/pause/input |
| 5 Warga | Character | Arah tubuh/alat/aktivitas Ujang,Darmi,Sari; alphaSaras | Gerak dan interaksi aktual dengan alat, bukan atlas-valid saja |
| 6 Desa | Shelter | Rumah pribadi Lurah, direktur terpisah+RV, Laskar dengan rute/jadwal/interaksi | Manifest/collider/save migration dan layanan lama tetap sah |
| 7 Hutan/laut | Website setelah HUD | Review air/arus/buih/canopy/cahaya bergerak, perbaiki temuan | Rute/gerak/cuaca sebenarnya; pertahankan volume/parallax |
| 8 Fitur lanjutan | Shelter+root | Tanaman kedua, keramba satu alur lengkap, interior pilot; FishGen offline/adapter pilot | Transaksi/cycle/idempotency, kegunaan nyata dan provenance |

Branch/worktree terpisah: `work/overnight-integration`, `work/overnight-character`, `work/overnight-village`, `work/overnight-hud-perf`. Satu penulis berkas bersama: root delivery APIapp/export; shelter sharedworld/land/APIfeature dan bangunan; character actors/rig/CharacterVisual; website HUD/presentasi/perf/air. FishGen/CreatureAnimator adapter milik root. Perubahan kontrak antarlane disampaikan lebih dulu.

Semua Godot import/export/native/browser/GPU serial dengan grant root. CPU/API/source independen paralel. Maksimal empat slot termasuk root; lane selesai mendapat tugas antrean. Commit belum berarti rilis; integrator menggabungkan, meninjau gambar dan menjalankan tes yang relevan.

Tidak ada pekerjaan CE, resetowner/reseed, penghapusan volume, atau pengubahan proxy shared sebagai bagian deployment. Pengguna telah mengizinkan implementasi; pilihan rutin tidak memerlukan konfirmasi ulang. Perangkat fisik yang belum tersedia dicatat sebagai batas, bukan hasil selesai. Pertahankan `.env`, save, 36menit/hari, mode pakaian dan current+rollback. Dokumentasi/galeri diperbarui tiap paket; hasil build/cache yang terbukti superseded dibersihkan.

## Checkpoint awal

SerialcurlPCK membuktikan pola berulang padaURL/IP yang sama: curlidentity1,62detik lalu1,37detik; browseridentity/gzip dancurlgzip tidak selesai6detik. Semuanya200, length/ETag sama. Ini mempersempit penelitian, belum sebab yang terbukti. Artefak `.runtime/overnight-transfer-probes.json`.

FishGen environment Python3.11 terisolasi dengan NumPy2.2.6/Pillow11.3.0 sedang disiapkan, nativeC dinonaktifkan pada pilot awal. Source upstream tetap pin0faa790; belum ada perubahan pada10spesies aktif. Pengujian fisik memerlukan perangkat; pertanyaan ketersediaan dikirim tanpa menghentikan lane lain.
