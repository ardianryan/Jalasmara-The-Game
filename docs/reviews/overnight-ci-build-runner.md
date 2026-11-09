# Build CI gagal sebelum mendapat runner

Pemeriksaan GitLab API pada 10 November 2026, sekitar04.13WIB, memperbarui status pipeline3046660664/source3af35a6. Job build17875131575 sudah **failed**, alasan resmi `stuck_pending_no_matching_runners`. Job tidak mempunyai runner, `started_at=null`, `duration=null`; selesai2026-11-09T21:07:25.662Z/04.07:25WIB sesudah queued5.593,835689detik. Tidak ada hasil compile dari job ini. Jangan menyebut quota sebagai penyebab pasti karena API hanya menyatakan tidak ada runner yang cocok.

Verify17875131573 lulus187,616detik termasuk120API, Godot17875131574 lulus300,990detik termasuk63world, dan CodeQL17875131576 lulus174,458detik dengan satu warning/dua notes. Hasil ketiganya tidak menjadikan seluruh pipeline PASS. Artefak Linux PCK8c7e43e3 dan PCK Mac73d tetap dipatok terpisah.

Host yang benar-benar aktif dibangun terpisah di VPS dari sourcee171734; [rilis host](overnight-admin-host-release.md) memegang full asset/API verification, backup dan actualpublic6PASS. Ini bukti build alternatif, bukan penggantian status job GitLab. Source lazy Admin sesudah3af memiliki typecheck/build lokal dan browser sendiri, bukan diklaim sudah diuji pipeline tersebut.

Bukti mentah lokal `.runtime/ci-3046660664/jobs-latest.json` serta `build-final.json`. Pembacaan memakai `glab api`, tanpa token di command/source/log, tanpa memasang runner, mengubah GitLab CE, `.env`, quota atau akun. Migrasi CE tetap dibatalkan. Tindak lanjut: simpan status gagal ini ketika memirror source berikutnya; jangan mengulang seluruh suite hanya untuk menghapus bukti antrean atau menaikkan timeout dunia.
