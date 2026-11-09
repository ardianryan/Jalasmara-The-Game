# Kebun jahe dan keramba: browser ekspor2

**PASS5, lokal, belum bukti rilis publik.** Run oleh lane ini memakai Chromium SwiftShader, viewport1440×900 dan UI/input aktual pada localhost3111. Runtime ekspor root source593dc79, PCK SHA256 `1315f34672b0fc5694a5f73684ca68bfbc6b5be1f6f4560b9628cc14ac2ef5e0`, decoded64491320byte. Hash/byte diperiksa sebelum membuat player. Harness root5489bf4, termasuk dry-UUID08c737b dan native-fetch guard5489bf4.

Artefak worktree `/Users/ardianryan/Documents/Jalasmara-overnight-integration/artifacts/browser/garden-pen-b85bf993-c6d4-423e-adcf-b771e04c3f0d/`: `results.json` serta lima PNG01–05. Log `.runtime/overnight-garden-pen-export2-rerun.log`. Results SHA256 `a4b7ed13b7e4201dc2c3d0bb8de79d60c16e392cc96b40ff9e41e4dcfaf77ced`. Source tidak menyimpan cookie/password/token; trace398response mencatat action/revision/version dan receiptUUID yang diperlukan.

Lima hasil aktual:

- Layanan keramba terdekat dibuka dari posisi sah. Feed upstream berhasil, fixture menyuntik satu503TEST_RESPONSE_LOST; tombol retry mengirim receipt/body sama dan memperoleh response identik dengan commit upstream. Coins250→248 tepat sekali, offspring tidak bertambah akibat retry.
- Panen offspring fixture lewat tombol: offspring1→0, produce.ikan_seruni0→1, parents tetap2. Tab dari feed-disabled mencapai tombol panen, tidak memerlukan perubahan fokus produksi.
- Jalan nyata via physicalRoute/inverse kamera kiri ke plot1. UI menawarkan Jahe karena seed resmi tersedia; plant mengonsumsi benih, cropId=jahe. Manual water berhasil pada dryUUID hari2, wateredDay2. Tidak mengandalkan air hujan otomatis untuk klaim tombol Siram.
- Jalan nyata ke Mbah Wira, membuka menu titip dan selector pantry. Stock satu jahe lalu satu ikan seruni lewat UI; produce masing-masing1→0, pantry masing-masing0→1. Tidak membawa kangkung untuk melewati guard lama: runtime memakai guard any canonical serving yang telah diperbaiki root.
- Reload dan login session tetap valid; canonical revision7/version6/coins248, plot, pen dan pantry sama persis. Ini menguji persistensi setelah aksi, bukan hanya perubahan teks panel.

Tidak ada page/console error atau API failure tak terduga. Satu503 adalah fault injection eksplisit sesudah commit feed. Run exit0, completedtrue, ownTemporaryPlayerRemovedtrue. Finally menghapus hanya UUID fixture beserta receipt/auth/calendar/surface/home/dive keys miliknya dan membuktikan sisa nol. Chromium ditutup, process scan owned Chromium kosong; slot browser dilepas ke root sebelum penulisan laporan ini.

Run pendahulu `garden-pen-20446f62-4b75-406b-9d01-dba30c759eb3` gagal **sebelum** DB/player/Chromium dibuat akibat harness memanggil native Fetch Response.ok sebagai fungsi. Failure tetap disimpan; df7ded3 memperbaiki satu baris menjadi property.ok, root5489bf4. Bukan kegagalan API/game dan tidak ada fixture tertinggal. Seluruh .ok() lain telah diaudit sebagai Playwright APIResponse yang benar memakai method.

## Batas bukti dan gambar

Fixture secara eksplisit memberi story day2, calendar day2 kering, permit, satu benih dan satu produce jahe, dua parents serta satu offspring. Jadi hasil ini **tidak** membuktikan browser penangkapan indukan, ekstraksi, breeding dua fed settlements, pertumbuhan jahe empat hari atau bonus penyajian. Jalur/negative/replay server telah diuji API terpisah; rancangan browser tambahan ada di `overnight-live-parent-cycle-browser-design.md`, belum diimplementasi/dijalankan.

PNG02 terlihat feed-disabled dan panen; PNG03 terlihat pilihan Jahe/counts; PNG04 terlihat selector dua bahan pantry. PNG05 memperlihatkan kembali dunia/HUD dengan248koin setelah reload. Lane membuka keempat gambar tersebut; bentuk/nama kontrol terbaca, tidak ada quad NPC abu-abu yang jelas pada frame ini, tetapi ini bukan audit semua NPC/semua waktu. PNG05 hash `077523c8ffc89bfc07bc7d97378f24055e1f3deba38490aae053834593b0699a`, PNG04 `0bf0eb8eb5f1c60039fa72dbeb8115adda4308f18fb4826d2d2e43d377e9cb3b`. Rute memerlukan sebagian besar budget8menit di software renderer; tidak diubah speed/posisi/clock atau dinaikkan timeout untuk memperoleh PASS. Tidak ada klaim FPS/performa SamsungS23 atau Windows, natural gait selesai, delapan arah artwork atau rilis publik.
