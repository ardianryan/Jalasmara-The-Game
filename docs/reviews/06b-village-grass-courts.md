# Pelataran desa hijau dengan jalur tanah yang terpotong pada batas lantai

9 November 2026. Branch `work/06-village-ground`, worktree `Jalasmara-06-village-ground`, base root `9c195de`. **Modul/data dan unit CPU saja; hook world, renderer/native/export/browser tetap milik integrator.** Tidak mengubah `land.ts`, shader, material palette, collider, kalender, ekonomi atau layanan.

`packages/shared/src/village-ground.ts` menyediakan fungsi murni `decorateVillageGround(map: LandMap): LandMap`. Hasil adalah deepclone; pemanggil harus memakai nilai return. Hanya base `lower_court`/`upper_court` yang diubah materialnya menjadi grass. Polygon/elevasi/priority/floorflag asli tetap. Seluruh bidang lain, route, obstacle, stairs/connector, bridge, gateway dan metadata lainnya tidak berubah. Map selain hub dikembalikan identik secara data, tanpa dekorasi.

Tanah selebar72unit mengikuti segmen route hub aktual, dengan quad sederhana dan join delapan sisi. Duplikasi segmen bolak-balik serta join yang sama dibuang. Setiap polygon dipotong terhadap pelataran convex dengan half-plane clipping dan dipotong lagi untuk mengurangi area stone/wood/dock/bridge/connector dan footprint kebun. Jadi permukaan batu lama dipertahankan dan tidak ditimpa/digandakan oleh tanah tersembunyi. Paint selalu `walkable:false`, priority4 (di bawah stone8 dan edgegrass6), serta elevasi ownerfloor. Tidak menambah union lantai atau menyatakan tanah sebagai jalur baru yang dapat dilalui.

Pada manifest base ini hasilnya37surface paint/175vertex polygon:18di lower dan19di upper. Batas kliping dipertahankan dalam float, tidak dibulatkan sehingga keluar footprint. Input convex/finite divalidasi; geometri concave yang tidak didukung menolak, bukan mengecat luar batas. Jumlah fragment/surface dibatasi. Fungsi idempotent: prefix paint lama dibuang lalu diturunkan ulang, bukan menumpuk setiap panggilan.

Pemeriksaan aktual: `node --import tsx --test apps/api/test/village-ground.test.ts` **6/6 PASS**, `npm run typecheck` API/web PASS, format/diffcheck lulus. Tes membuktikan:

- Input JSON tidak berubah dan geometry/elevasi/connector serta metadata selain material dua court tetap identik.
- Semua vertex dan sampel sepanjang edge paint, termasuk titik tepat pada batas kliping, berada di ownerfloor; priority/walkable/elevasi benar.
- Fixture persegi100×100 dengan route melintas dari luar mempunyai clip tepat0…100 dan lebar72/area7.200; winding dibalik tetap benar.
- Strip protected stone/wood/connector/garden10unit dikurangi persis, menghasilkan dua bidang totalarea6.480 tanpa menambah geometri bidang lama.
- Lebih dari2.000titik radius13 dan seluruh segmen route mempunyai walkability/clearance sama sebelum/sesudah; jalur layanan batu lama tetap material sama. Pada grid20unit, grass mencakup lebih60%lantai pelataran yang dapat dilalui.
- Forest tetap sama dan court concave ditolak; panggilan dua kali identik.

Belum ada claim fullAPI gabungan, CI baru, perubahan staging, gambar before/after, FPS atau perjalanan player dari hasil CPU ini. Integrator memasang return fungsi ke LAND_MAPS hub sesudah pembentukan geometri, mengulang fullAPI/world, meninjau native di kamera/profil/waktu yang sama, lalu memberi PCKpin untuk browser gateway/canopy yang sudah disiapkan. Jika user masih melihat pelataran terlalu kuning atau jalan terputus, hasil gambar/runtime yang menentukan penerimaan, bukan enam tes CPU saja.

Tool aktual: Node26.12.1/tsx, TypeScript, Git/worktree dan Prettier. Tidak ada dependency/library/asset baru, AI generator, Godot/browser, request jaringan/API atau akun uji yang dibuat pada lane ini.

## Triangulasi minimap pada paket gabungan: skala layar, bukan polygon dunia rusak

Fullworld integrator sempat berhenti pada `scripts/godot-map-geometry.gd`: pesan PASS141roundtrip diikuti `Invalid polygon data, triangulation failed` dari `GeoMap._draw_land_polygon`. Log gagal tetap di `Jalasmara-06-buildings-gates/.runtime/06b2-world-final.log`. CPU lane ini membaca worldJSON aktual paket gabungan dan memeriksa37paint: semuanya valid/nondegenerate pada ukuran dunia, tanpa adjacentduplicate atau titik kollinear yang perlu dihapus. Satu triangle kecil `village_dirt_lower_court_segment_7_1` mempunyai titik `[[1125.2023300571911,962.2465934906937],[1128.3419706559803,961.6186653709359],[1128.07,962.87]]`, area1,87898149unit² dan sisi minimum1,28054925unit.

Integrator kemudian menguji triangulasi Godot asli: triangle tersebut sah di dunia, tetapi gagal pada proyeksi minimap×0,01; triangle upper38_0 yang tipis juga bermasalah pada×0,005. Area layar triangle7_1 pada×0,01 hanya≈0,000187898pixel², jauh di bawah satu piksel. Ini tidak membuktikan route/floor kliping salah atau alasan untuk membuang semua bidang kecil yang sah di render dunia.

Atas koreksi integrator, **tidak ditambahkan sanitizer atau perubahan37paint** hanya untuk menyamarkan batas zoom. Root memperbaiki GeoMap dengan cull berdasarkan area layar aktual<0,25pixel² dan mengulang141pemeriksaan map sampai lulus; polygon besar/invalid tidak disembunyikan oleh aturan tersebut. Implementasi/test GeoMap tetap milik root, bukan hasil engine dari lane ini. API gabungan sempat99/100 karena fixture perbandingan floor mengharapkan dua material court lama tetap dirt; root mengganti tepat dua ekspektasi yang disetujui menjadi grass sambil mempertahankan perbandingan polygon/elevasi/metadata. FullAPI100/world50 masih menjadi pemeriksaan integrator berikutnya pada checkpoint ini, belum hasil yang boleh dinyatakan oleh commit dokumentasi ini.

Tool tambahan aktual lane ini hanya pembacaan log/source dan perhitungan polygon Node. Tidak ada browser/Godot, API mutation atau perubahan geometry/tolerance unit untuk membuat kegagalan berlalu. Bukti gagal dan perbedaan skala dunia/layer minimap dipertahankan agar sesi selanjutnya tidak menambahkan cleanup geometri yang tidak diperlukan sebelum ekspor final.
