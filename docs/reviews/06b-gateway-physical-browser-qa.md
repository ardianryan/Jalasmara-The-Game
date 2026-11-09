# QA gerbang fisik dan sisa build

9 November 2026. Branch `work/06-gateway-route-qa`, worktree `Jalasmara-06-gateway-qa`, base `7dc679a`. **Mode baru masih CPU/source; tidak ada browser/Godot/API mutation atau request publik pada checkpoint ini.** Integrator memegang produksi, world/renderer dan paket ekspor. Report ini tidak mengubah penerimaan publik43df yang masih parsial.

## Mode gateway sempit

`PLAN06_ROUTE_MODE=gateways` pada harness lokal membuat akun UUID baru dengan initial save sah di approach hub2295/210, titik komponen yang sudah disetujui integrator dari rute gate sebelumnya. Ini bukan klaim memainkan ulang seluruh desa dari spawn. Setelah startup, seluruh perpindahan tetap input nyata melalui `land.view.motion`; tidak ada teleport, override kamera/cuaca atau penghapusan collider.

Urutan source yang disiapkan:

1. Baca `world.landMaps[area].gateways[0]`; validasi dua post/collider, sumbu physical `(x,-y/cos55)`, crossing±36unit dan radius13 dua arah. Approach dihitung `physicalRoute` dari posisi aktual.
2. Periksa `land.gateways[gate.id]` aktual: center/post/footprint/crossing sama, semua emitted box memakai basis jalan yang unit/orthogonal, dua base berada pada pusat post, empat sudut base di collider, roof berpusat122unit di atas jalan. Metadata tanpa emitted vertices ditolak. Ini konsumsi diagnostics mesh yang sungguh dibuat renderer, bukan penerimaan visual dari JSON saja; capture sebelum/tengah/sesudah tetap wajib ditinjau.
3. Berjalan before→aperture→after→aperture→before. Signed distance sepanjang jalan wajib berganti dari<−25 ke>25; midpoint harus dekat plane dan lateral tetap dalam gap setelah clearance tubuh. Screenshot menyimpan tiga posisi nyata.
4. Dekati sisi dalam post0 dari lantai sah. Tahan arah ke pusat collider selama16pulse100ms, selalu dihitung dari matriks aktual. Tubuh harus tetap di lantai/luar polygon (clearance≥11,5), benar-benar mendekat sebelum terhalang, lalu empat sampel terakhir berhenti<3unit dari titik akhir dan clearance<18. Semua sampel/keys disimpan. Jalan keluar memakai `physicalRoute` menuju crossing endpoint, lalu wajib ada surface POST200 dengan requestVersion/ACKplayerVersion yang sesuai dan posisi<8unit dari hasil gerak. Berdiri diam+GET state tidak dihitung sebagai ACK gerak.
5. Aksi E aktual di portal hub menghasilkan travel200/area forest. Dari spawn forest, ulang crossing dua arah dan post collision/recovery, kemudian posisi disimpan/reload. Koin200, inventory kosong, story day2/stage dive/missions dan kalender36menit tetap; travel memang mengubah surface area/layout. Bukti error/409 dan cleanup UUID tetap wajib.

Batas mode5menit. Guard literal layout9 lama yang masih berada sebelum fixture dihapus; source harus mempunyai versi integer dan API harus cocok dengan manifest kandidat yang diimpor. Mode canopy sebelumnya juga tidak akan terblokir oleh guard9 ketika rumah/gerbang10/6 digabung. Tidak ada perluasan/rewrite HUD atau UI dari lane ini.

## Pemeriksaan CPU dan batasnya

Source world gateway pada worktree integrator mula-mula masih unstaged sementara base7dc hanya memuat factory/type. Karena itu CPU helper diuji pada salinan JSON **data WORLD aktual** dari worktree tersebut, disimpan hanya dalam ignored `.runtime/gateway-world-candidate.json`; tidak menyalin source produksi ke commit QA. Enam tes baru mencakup dua route/collision opening, dua post approach/body clearance, metadata/crossing salah ditolak, dan metadata tanpa emitted geometry ditolak. Ditambah consumer5 dan sanitizer3: **14/14 PASS**. Ini bukan hasil browser/engine ataupun CI source gabungan. Sesudah metadata `eb58f3c` tersedia, branch QA di-fast-forward (termasuk renderer3b08659) tanpa menyalin source produksi secara manual. Command normal tanpa JSON menjalankan gateway6+canopy4+consumer5+sanitizer3: **18/18 PASS** pada layout10/6. Hook JSON percobaan dihapus dari tes; source manifest gabungan sekarang menjadi input normal. Tidak ada browser/Godot dari pengulangan ini.

```sh
node --import tsx --test scripts/gateway-route-fixture.test.mjs scripts/canopy-route-fixture.test.mjs scripts/land-view-navigation.test.mjs scripts/gameplay-api-failure.test.mjs
```

Sesudah root menggabungkan source, mengekspor dan memberi pin/grant lokal:

```sh
APP_TEST_ORIGIN=http://localhost:3101 \
PLAN06_ROUTE_MODE=gateways \
PLAN06_EXPECT_PCK=<sha256-export-kandidat> \
PLAN06_EXPECT_PCK_BYTES=<byte-persis> \
node --import tsx scripts/plan06-layout-browser.mjs
```

Command dengan placeholder tidak dijalankan. Menunggu grant bukan alasan menyebut kandidat sudah lulus atau mengulang public H2. Node26.12.1/tsx/Git menjadi tool CPU aktual. Tidak ada dependensi/aset upstream baru, installer atau API generator.

## Audit prioritas yang belum selesai

Status berikut membedakan **live43df** dari kandidat authoring, berdasarkan handoff, laporan yang dirujuk dan source; bukan pengulangan tes runtime.

| Prioritas                   | Sudah terbukti                                                                                                                                                    | Belum dan langkah berikutnya                                                                                                                                                                                                                                                                                                                     |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Startup dan public smoke    | Live43df health/PCK cocok; loading byte asli. Default240detik gagal pada57%; HTTP1 diagnostik ready≈70detik dan rute hutan2checks                                 | Default H2/full smoke publik tetap terbuka. Target canopy CPU ae7/8cc sudah disiapkan, harus actual local dahulu. Loader8833185 adalah hardening stream independen10CPU, belum bukti perbaikan H2. [Diagnosis](06p-public-startup-transport.md), [QA](06-release-remaining-qa.md)                                                                |
| Rumah, gate dan terrain     | LiveGriya sudah sejajar dek. Kandidat rumah rectangle layout10 mendapat bukti native tujuh rumah/28frame dari integrator, bukan release baru                      | Crossing/post/ACK browser mode ini belum dijalankan. Cliffs/stairs natural dan hutan yang tampak menyambung dari hub adalah scope pengguna terbaru; helper terrain/traversal/scenery masih lane CPU terpisah. Jangan menyebut semuanya masuk live43df. [Rumah](06b-house-next-native.md), [QA canopy/rumah](06b-canopy-house-gate-browser-qa.md) |
| HUD/dialog/website          | Website32focused checks, night7checks/8transaksi bersih pada5f, compact667/390 dan HUDportrait pernah diuji. Local43df punya dialog malam/lurah/permit yang benar | Bukan “belum disentuh”; yang tersisa ialah seluruh variasi buku/kuis/dialog referensi dan QA malam pada paket world baru. Satu409 historis belum diketahui penyebabnya, tidak dihapus oleh rerun bersih. [QA transaksi](06-release-remaining-qa.md), [UI/kamera](06b-integrated-left-and-ui.md)                                                  |
| Gerak dan alpha             | Stop/turn Nala192sampel serta592PNG sudah dirilis; nativealpha7.762sampel bersih                                                                                  | Painted sole/restart natural seluruh siklus belum diterima; pilot restartb937/5cc masih kandidat. Empat arah tubuh Ujang/Darmi/Sari belum lengkap. Saras grayquad belum tertutup karena browser43df tertutup Nala/palm; jangan mengklaim fixed dari frame itu. [Gait](06e-nala-gait-transitions.md), [alpha](06b-alpha-browser-43df.md)          |
| Perluasan desa              | Rutinitas/tujuh shelter dan layanan inti punya bukti terpisah; Raka tetap inspektur                                                                               | Rumah pribadi lurah, direktur tersendiri dengan RV/container dan lima Laskar Kognisi beserta fungsi/rute belum tersedia. Bukan mengganti inspektur atau menambah bangunan dummy. [PRD](../PRD.md), [Rencana06](../plans/06-finishing-dunia-npc-dan-perluasan-desa.md)                                                                            |
| Laut dan performa perangkat | Paket lama mempunyai10spesies/722frame serta actual ocean/HUD/ACK pada5f. Inventori payload membedakan PCK dan transfer                                           | Natural water/motion visual harus ditinjau bergerak; SFX/daftarframe bukan bukti seluruh adegan natural. Windows/S23 fisik, sesi panjang/memori dan FPS belum diukur. Fish Gen hanya tool/pin tersimpan, belum generator/runtime. [Fish Gen](../world/fish-gen-reference.md), [PRD](../PRD.md)                                                   |

Integrator menentukan urutan paket: geometri/terrain/traversal yang sedang dikerjakan→focused local gateway/canopy→perbaikan nyata bila gagal→world/API/export/browser gabungan→public acceptance tersendiri. Tidak menambah UI tak terkait sambil menunggu engine.

## Audit warna/detail untuk integrator, tanpa perubahan renderer

Permintaan pengguna berikutnya: warna lebih ceria seperti login/loading, ambient sejuk dengan cahaya hangat, detail tidak terasa burik. Dibaca langsung: `main.tsx`/`style.css` (`entry-art` memakai `/art/muara-sungsang.png`), `GameLoading.tsx`/`game-loading.css` (dua layer harbor/foregroundWEBP), `ComfyGrade.gdshader`, `LandMaterials.gd`, `RenderBudget.gd`, `RenderQuality.gd`, serta source grounddetail/lighting pada `LandWorld3D.gd`.

Gambar yang benar-benar dilihat dengan `view_image`: kedua artwork login/loading; public73395 `failure.png`; `Jalasmara-06-house-integration/artifacts/godot/06b-house-alignment-framed/after10-kedai_waras-day.png` dan pasangannya `-night.png`. Ini pembacaan bukti yang sudah ada, bukan capture engine baru. Gambar artwork mempunyai bidang teal yang tenang dan highlight peach/amber; frame rumah siang mempunyai stipple kayu/atap yang padat serta tanah olive, sementara malam mempunyai titik cahaya hangat tetapi warna permukaan tetap cenderung abu/olive.

Piksel nearest yang membentuk siluet bangunan adalah bagian gaya yang diminta. Noise frekuensi tinggi berbeda: material memakai hash grid2,7unit, micro Crawl multiplier `.84+texel*.36`, atlas multiplier `.78+texel*.50`, lalu seam/fiber tambahan. Micro dan atlas saling eksklusif dalam material saat ini, **tidak** dijumlahkan keduanya sekaligus; finehash tetap ditumpuk di masing-masing jalur. Pada render half-resolution/budget129.600piksel, detail kecil dapat menjadi bintik1–2piksel dan bergetar ketika kamera bergerak. Rim12unit memakai random hash discard sehingga batas jalan terlihat berbutir. Mengganti nearest dengan blur bukan solusi yang direkomendasikan.

`ComfyGrade` saat strength0,6 hanya memberi vibrance efektif maksimum sekitar2,7% dan tint sangat kecil; ia tidak akan mengatasi palet/material yang kusam sendirian. Lighting setup sun1,15 juga bukan nilai siang stabil: update cuaca menggantinya menjadi maksimal0,55 sesudah≈0,25detik. Ambient siang `bdc0b5`/0,55 hampir netral hangat; ambient malam `8da4a8`/0,50 sudah lebih sejuk namun kurang berwarna dibanding artwork. RenderQualitylow menonaktifkan sunshadow, sementara RenderBudget tetap; audit ini tidak membuktikan FPS perangkat.

Usulan terbatas berikut dikirim ke integrator sebagai **kandidat A/B**, belum implementasi atau hasil yang diterima:

1. Kurangi detail terlebih dahulu, pertahankan resolusi/nearest dan volume3D. Finegrid2,7→6unit, amplitude0,035→0,012, broadpatch0,09→0,055. Micro dinetralkan ke `1+(luma-.5)*.10` (±5%) dan atlas direcenter sekitar1 dengan kontras≈10%. Fiber kayu0,10→0,025, fiber thatch0,10→0,03; seam papan/roof utama tetap memberi struktur. Rim12→6–8unit/coarser ordered pattern bisa diuji terpisah, tanpa blur.
2. A/B palet lokal yang lebih terang: grass`76a268→8caf61`, dirt`9b7c52→b68f58`, sand`cdbb87→e0c58c`, stone`969d98→a8b5aa`, wood`887055→a57b50`, thatch`a48c63→c5a16d`, roof`97674e→b87854`. Angka ini usulan source, bukan hasil render; jangan menganggap semua warna wajib diadopsi.
3. A/B ambient siang coolteal`b7d4d1`, malam`71929c` dengan energy dibatasi keterbacaan, mempertahankan sun`fff0d7`/lentera amber. Sesudah material/palet benar, barulah grade broadshadow/highlight sekitar4–6% dan vibrance8–12% diuji. Jangan memakai boost saturasi global besar untuk menyamarkan noise.

Integrator mengambil slot engine untuk capture sebelum/sesudah dengan source/profil/kamera/waktu yang sama, meninjau siang/malam dan lantai jalan. Lane QA tidak mengedit shader/material/renderer, tidak menghasilkan raster baru dan tidak menjalankan browser/Godot. Startup/public acceptance serta gerak/alpha/performa yang terbuka tidak berubah status hanya karena rekomendasi warna tersedia.
