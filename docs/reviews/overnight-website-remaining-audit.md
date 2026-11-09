# Audit sisa website setelah perbaikan draft admin

Status: audit source saja pada 10 November 2026 WIB, tanpa browser tambahan atau perubahan runtime game. Perbaikan admin dan penerimaan 35 checks dicatat di [laporan draft array](overnight-admin-array-drafts.md). Hunk copy `11d4344` mengganti label key internal menjadi bahasa Indonesia; typecheck dan syntax lulus, bukan pengulangan browser35.

Pemeriksaan `play.tsx`, `GameLoading.tsx`, `loading.ts`, `style.css`, dan `game-loading.css` pada source gabungan tidak menemukan blocker baru yang terkonfirmasi:

- Host immersive memakai fixed inset dan tinggi `100dvh`; menu dibatasi tinggi viewport, dapat digulir, mempunyai target 48px, serta mengirim ukuran/safe-area ke iframe.
- Fullscreen mengikuti DOM `fullscreenchange`, menangani rejection/unsupported dengan pesan, dan menyediakan keluar fullscreen. `scripts/play-host-browser.mjs` sudah berisi pemeriksaan actual fullscreen entry/exit, external exit, fallback, resize, dan fokus Lanjut bermain. Audit ini membaca cakupannya; tidak mengklaim menjalankannya kembali.
- Loading menampilkan byte nyata, persentase hanya untuk total diketahui, teks 16px, indeterminate ketika ukuran belum tersedia, error/retry serta satu iframe baru per retry. Sumber dan origin message diperiksa sebelum state diterima. Cakupan `scripts/loading-screen-browser.mjs` meliputi invalid message, preparation/ready, stalled/error/retry dan preferensi reduced motion. Bukti body-fault aktual terpisah ada di [laporan export2](overnight-export2-browser.md).

Satu celah cakupan yang belum dibuktikan sebagai masalah produk: panel loading memakai absolute bottom; harness memeriksa bounds saat download biasa, tetapi tidak memeriksa bounds panel stalled/error pada landscape sangat pendek (misalnya tinggi ≤320px). Jika keluhan layar pendek muncul, langkah berikutnya adalah fixture aktual viewport itu dengan state stalled, mengukur panel/menu/aksi dan melihat PNG sebelum mengubah CSS. Tidak ada perubahan spekulatif atau klaim gagal dalam audit ini.

Tool aktual hanya pembacaan source, pencarian `rg`, typecheck dan pemeriksaan syntax. Tidak ada proxy, akun, game export atau API preview yang diubah.

Follow-up: celah cakupan landscape pendek kemudian diuji, menemukan overlap frame/Menu pada844×320 dan diperbaiki secara terbatas; lihat [bukti gagal serta penerimaan16checks](overnight-loading-short-landscape.md). Audit source di atas tetap menggambarkan apa yang diketahui sebelum run tersebut.
