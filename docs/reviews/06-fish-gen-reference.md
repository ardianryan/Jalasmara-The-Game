# Fish Gen: hasil penyimpanan dan audit source

9 November 2026. Branch `work/06-fish-gen-reference`, baseline integrasi `90e639b`. Status lokal: dokumen siap review; clone tool disimpan, belum diintegrasikan atau dirilis. Permintaan pengguna ialah menyimpan tool yang berpotensi memperkaya lingkungan laut.

Source `JacobKulberg/fish-gen` dipatok `0faa79003ca50a7d422b618cb59179d9834094f1`, dengan lisensi MIT software dan izin keluaran sprite pada README yang dibedakan. Clone 34 berkas tersimpan di `.runtime/reference-audit/fish-gen` dalam worktree `Jalasmara-06-fish-gen`, bersih dan diabaikan Git. Tidak ada install, import, kompilasi, eksekusi generator, aset baru atau source upstream yang masuk runtime. Sepuluh spesies/722 bingkai lama tetap dipakai.

Bukti pemeriksaan aktual: Git HTTPS/commit/status/ignore, pembacaan primer README/LICENSE/pyproject/export/animation/CLI/native, SHA-256 empat berkas, serta pembacaan manifest dan kontrak `CreatureAnimator.gd`. Pemeriksaan tautan lokal tiga dokumen dan `git diff --check` lulus. Tidak ada Godot/browser WebGL, perubahan database, layanan berbayar atau benchmark.

[Audit rinci, hash, lisensi, keterbatasan dan langkah pilot](../world/fish-gen-reference.md) menjadi rujukan kedua indeks authoring/integrasi. Langkah berikutnya dimiliki tooling sesudah pekerjaan inti: satu output pilot berprovenance, adapter kontrak JSON/turn, ukuran atlas/PCK, lalu native/browser bergiliran. Tidak mengklaim plugin runtime sudah dipasang atau hasil visual sudah dinilai. Integrator memperbarui handoff dan status gabungan setelah menerima dokumen ini.
