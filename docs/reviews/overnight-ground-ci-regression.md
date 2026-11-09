# Regresi biaya query lantai pada CI

Pipeline GitLab3046596759 menguji source `7ad5d503e0eee4a55ca80a9b2e53849b73f1226e`, sebelum optimasi AABB4795d28. Verify17874625472 lulus213,676detik dan CodeQL17874625475 lulus193,541detik. Godot17874625473 gagal310,577detik; build berikutnya dilewati. Ini bukan CI yang seluruhnya lulus.

Log aktual `.runtime/ci-3046596759/godot.log` menunjukkan `resident-commute-contact.gd` berhenti dengan `Bounded fixture runtime exceeded55seconds` pada sampel9421/Cempaka. Tidak ada kegagalan panjang tungkai yang dilaporkan pada pose tersebut. Batas55detik dan timeout runner60detik dipertahankan. Kelulusan suite62 lokal179.811ms pada source yang sama tidak menggantikan hasil CI ini.

Benchmark terpisah mengonfirmasi scalar GDScript tanpa filter memerlukan208,067µs/query hub dan81,044µs/query forest, sekitar14–16kali baseline predicate native lama. [Optimasi AABB](overnight-ground-query-aabb.md) mempertahankan scalar kanonis tetapi menolak titik di luar batas sebelum memeriksa polygon:32,231µs/query hub dan16,121µs/query forest. Fokus324titik+20kasus/20.783pemeriksaan lulus, seluruh jumlah query serta checksum benchmark sebelum/sesudah sama. Angka tersebut merupakan biaya query lokal, bukan FPS perangkat.

Berikutnya: selesaikan konsistensi metadata traversal/material pada titik ramp yang sama, ulang suite gabungan dengan batas lama, lalu jalankan CI baru pada source yang benar-benar akan diekspor. Belum ada ekspor/rilis paket query ini. Staging798/image d044/PCK1315 tetap dipertahankan. Tidak ada perubahan dependency, proxy, data, atau lisensi akibat optimasi ini.
