# Fish Gen: pilot yang benar-benar diintegrasikan

Baseline rilis5f5 tetap; paket ini kandidat overnight, belum ekspor/browser/dirilis. Root mengerjakan jalur8 saat tiga subagent menangani gerak, desa/server, dan HUD/performa.

Fish Gen0.1.0 pada pin0faa79003ca50a7d422b618cb59179d9834094f1 kini benar-benar dijalankan offline. Python3.11.16/NumPy2.2.6/Pillow11.3.0, nativeC disabled. Clownfish1519:48×32cell/32frame, empat klip renang/putaran. Atlas19,444byte dan metadata9.715byte. Wrapper `tools/fish-gen/produce.py` menolak source pin salah/modified, versi dependency berbeda dan overwrite; dua reproduksi menghasilkan PNG/JSON byte-identik. CLI membutuhkan1,53detik pada percobaan awal; bukan benchmark game/perangkat.

Adapter stateful Godot mempertahankan `duration_ms`, `next`, `yaw`, memulai putaran pada batas loop dan menunggu sampai arah baru selesai. School3D dekoratif memakai satu sharedatlas, tiga aktor (satu profilRingan), tumpuan air diuji terhadap kontur sebenarnya, culling900unit, tanpa boss/session exit. Tidak menambah tangkapan/quest/hadiah atau mengganti sepuluh spesies/722frame existing. Kode generator tidak masuk runtime; sourcewrapper/adapter original dengan notice MIT upstream dan izin hasil README pin dipertahankan.

## Pemeriksaan aktual

- Sourceatlas/metadata direproduksi byte-identik; provenance memuat command/pin/versi/hash.
- `fishgen-animation.gd` PASS32frame/empatklip, timing/yaw/pause,5.400kontakair, qualitycap dan cleanupboss/session. Seluruh log bersih.
- Fresh editorimport dua tahap selesai bersih pada logkedua.
- Native Compatibility AppleM2, productionHybridOcean/OceanActors/FishGenSchool:40frame aktual960×540/3aktor, koin700/O277 tetap, exit0/0SCRIPT ERROR/ERROR. Root meninjau frame016: ikan kecil terbaca dalam ruang air dengan karakter/terrain; bukan klaim seluruh animasi/artstyle/perangkat sudah selesai.
- Fixture awal gagal compile karena scriptautoload dipreload sebelum SceneTree memuat GameState. Ditolak, proses milik fixture dihentikan, dependencies tersebut di-load deferred seperti fixture existing. Rerun clean. Tidak mengubah productionautoload atau toleransi untuk menutup hasil gagal.

Log `.runtime/overnight-fishgen-{test,test-2,native}.log`; PNG/JSON `artifacts/godot/fishgen-school/`. Regresi baru didaftarkan ke `verify-living-world.mjs`. Tes gabungan, ekspor dan actualbrowser berikutnya dilakukan integrator setelah lane lain dibekukan. Native fixture bukan bermain lewat API dan tidak membuktikan S23/Windows fisik. Pengguna bersedia membantu pengukuran perangkat setelah recorder siap.

## Tool/lisensi

[Tool dan cara reproduksi](../../tools/fish-gen/README.md), [provenance runtime](../../client-godot/resources/art/fishgen/provenance.json), [MIT notice](../../tools/fish-gen/LICENSE.upstream), [kredit](../../THIRD_PARTY_LICENSES.md). Tidak memakai APIkey/MCP/layanan berbayar atau mengambil galeri upstream. Gambar asli dihasilkan dari preset/seed dan dipakai dengan izin hasil upstream; sumber moodboard tidak didistribusikan.
