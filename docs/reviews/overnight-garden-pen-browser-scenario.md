# Skenario browser lanjutan: jahe dan keramba

Persiapan CPU, belum dijalankan. Dasar kontrak server: `homestead-breeding.test.ts` dan definitions dari paket f74bc55. UI aktual berada di HomesteadUI, navigasi kiri -45 memakai `physicalRoute`, `keyboardPulse` dan `corridorTargets` yang telah dipakai night-home-browser. Jangan menyalin keyboard logical-X/Y dari homestead-browser lama karena tidak sesuai kamera kiri.

## Scope dan fixture

Buat UUID player lokal tersendiri, story day2, misi `akar`, permit true, calendar hari1 pukul08.00, coins250, seeds kosong, plots kosong, inventori knowledge yang cukup untuk satu resep kedai. Jangan memakai owner, mengubah akun lain, atau menyentuh layanan/config produksi. Browser harus mematok source/PCK SHA256 dan ukuran byte; trace seluruh homestead/calendar/kedai requests dengan action, itemId, expectedRevision dan receipt key tanpa cookie/token.

Untuk lane UI keramba, fixture membawa `homestead.liveCatch.reef_seruni=2` secara eksplisit. Ini **setup data milik fixture**, bukan klaim penangkapan browser. Asal tangkapan/dua-star/fainted/extract replay sudah memiliki regresi API tersendiri; penangkapan dan ekstraksi melalui kontrol gameplay browser tetap scope tambahan yang harus dinyatakan terpisah. Jangan memberikan indukan dari knowledge fragments atau memberi dua ikan lagi saat reload.

Tidak perlu memajukan jam database untuk pertumbuhan: tombol dipan `Lewati hari ini dan tidur` mengirim `sleep` dengan confirmEarly dan memajukan satu hari kalender secara sah. Dengan empat putaran kebun→dipan→keluar, jahe dan dua putaran keramba dapat selesai dalam fixture browser yang dibatasi waktu. Jangan mengubah waktu/hari lewat JS game.

## Urutan aktual dan invariant

1. Login dan tunggu ready byte asli. PCK harus cocok, snapshot berisi azimut -45 dan homestead definitions resmi. Catat state/version/revision awal, bukan hanya halaman tampil.
2. Jalan ke `WORLD.homestead.market`. Buka market, pilih bibit jahe dari urutan `definitions.crops` (saat ini tombol kedua sesudah kangkung). Tekan Enter lewat fokus aktual. Tunggu response `buy_seed`, itemId benih_jahe, qty1: coins turun30 sekali, seed naik1 dan revision tersimpan. Reload dan buktikan tidak terulang.
3. Jalan ke gardenPlots[0].interaction; hanya jahe tersedia sehingga tombol `Tanam Jahe` pertama. `plant` mengonsumsi benih, plot cropId jahe, growthDays0. `water` memenuhi watered hari ini. Catat model cropId/seed yang terlihat; PNG berbeda dari kangkung tidak cukup tanpa state.
4. Jalan ke fishPen.interaction **[275,850]** pada dek. Buka Keramba, pilih `Masukkan 2 ikan hidup sebagai indukan`; actual action stock_pen reef_seruni qty2 mengubah liveCatch2→0, breeders0→2. Reopen/reload tidak boleh mengulang konsumsi. Bukan interaksi dari posisi jauh hanya karena keramba terlihat.
5. Beri pakan dari tombol UI, action feed_pen: coins-2, fed true, tombol yang sama disabled. Tutup dan buka kembali; tetap disabled. Jangan menganggap double-click yang ditahan UI sebagai bukti receipt replay server.
6. Jalan ke pintu Griya, `enter`; jalan di interior ke pendekatan bed, pilih tidur awal secara eksplisit. Action sleep memajukan calendarDay satu kali, minute06.00, growthDays jahe1 dan pen.progressDays1. Buka kembali panel dipan/reload tanpa menekan tidur tidak boleh memajukan hari lagi. Keluar rumah lewat UI exit dan buktikan source posisi/version ACK benar sebelum berjalan.
7. Putaran kedua: siram jahe, beri pakan keramba dan tidur. Pen menghasilkan offspring1 tepat sekali; jahe growthDays2 belum siap. Harvest_pen melalui UI mengurangi offspring1→0 dan produce.ikan_seruni0→1. Reopen tombol panen hilang, parent tetap2.
8. Putaran ketiga dan keempat: siram jahe setiap hari, lalu tidur. Jahe belum siap pada3 dan siap pada4; harvest UI memberi produce.jahe3 dan plot empty. Hari tanpa siram/pakan dapat diuji pada fixture terpisah agar urutan utama tetap jelas; API sudah meliputi kondisi itu.
9. Pergi ke kedai dan titipkan satu jahe serta satu ikan melalui pilihan `servings` resmi. pantry bertambah masing-masing1, produce turun masing-masing1. Dalam pesanan nyata pilih pelengkap via gardenItemId, assert respons `/kedai/serve` memakai item yang dipilih dan bonus definitions (jahe12 atau ikan10), tetap mengonsumsi knowledge fragment wajib. Bila jendela kedai tutup, catat stock UI sudah PASS dan jadwalkan fixture night-service terpisah; jangan memalsukan pelayanan.
10. Cleanup dalam finally hanya UUID fixture dan auth/calendar/surface/home/dive/idempotency keys miliknya. Simpan results dengan cleanup true, semua response error, console/page errors, pin PCK dan screenshot. Browser/GPU ditutup sebelum RELEASE.

## Retry dan batas bukti

Tambahkan satu lost-response setelah action feed_pen atau harvest benar-benar committed, menggunakan route fulfillment terkontrol seperti harness homestead terdahulu. Tombol `Coba kirim kegiatan yang sama` harus memakai body + idempotency key asli, mengambil receipt lama dan tidak menggandakan coins/hasil/hari. Response 503 yang disuntik fixture dilabeli expected; 409/4xx lain tidak disembunyikan. Root baru memperbaiki race canonical version/position sebelum await pada extract dan home; trace browser harus tetap memeriksa zero unexpected conflicts.

Screenshot UI bukan bukti pertumbuhan atau reward. Setiap langkah harus menghubungkan input UI, response server, snapshot/revision, reload persistence dan delta inventori/coins. SwiftShader boleh membuktikan alur, bukan FPS Samsung S23/Windows. Scenario ini masih persiapan; belum menjadi hasil browser atau rilis.

## Smoke bounded yang siap dijalankan

File baru `scripts/garden-pen-browser.mjs` menargetkan localhost3111, wajib env `PLAN06_EXPECT_PCK` + `PLAN06_EXPECT_PCK_BYTES`; script menolak remote/existing fixture. Ia membuat player UUID sendiri, calendar/story day2, permit, satu benih jahe, satu produce jahe, dua indukan dan satu offspring sebagai **setup eksplisit**. Tidak mengklaim acquisition atau playthrough pertumbuhan penuh. Initial surface berada tepat di layanan keramba sah [275,850].

Urutan: actual nearest keramba → feed (commit upstream tetapi respons503 disuntik) → retry UI key yang sama/receipt sama/no double coins → harvest offspring → jalan via physicalRoute dan inverse kamera ke plot1 → pilihan jahe + water → jalan ke Wira → UI stock jahe dan ikan → reload → state/version/coins/pantry/pen/plot tetap. Semua operasi berasal dari keyboard pada UI; surface hanya diset sekali untuk spawn fixture. Script tidak memakai teleport di tengah rute atau API action pengganti tombol.

Full trace hanya mencatat action/itemId/revision/version/receipt UUID, tidak cookie/token/password. Cleanup finally memeriksa UUID/email/name/role dan auth-key userId sebelum menghapus keys milik fixture, lalu membuktikan pemain/receipt/keys terhapus. Expected503 hanya boleh action feed dengan code TEST_RESPONSE_LOST; error lain tetap menggagalkan hasil. Semua browser/GPU harus ditutup sebelum RELEASE.

CPU `node --check` dan prettier PASS. Belum dijalankan di browser atau mendapat slot/PCK final pada saat commit ini. Panen jahe empat hari, pertumbuhan anakan dua fed settlements, penangkapan parent dan bonus penyajian tidak termasuk smoke pendek; regresi API dan skenario panjang di atas mencatat bukti serta batasnya terpisah.

## Celah interaksi yang ditemukan sebelum browser

Fixture jahe/ikan tanpa kangkung menemukan guard Main yang hanya membuka penitipan Wira ketika produce.kangkung positif. Root memperbaiki guard agar membaca seluruh itemId resmi pada definisi servings. Tanpa hasil resmi, percakapan/pelayanan biasa tetap tersedia. Regresi memanggil Main._interact sebenarnya melalui capture khusus: jahe saja, ikan saja dan kangkung saja menuju panel Wira; kosong, nol dan item asing menuju percakapan. Focused homestead-options lulus (`.runtime/overnight-wira-produce-guard.log`). Ini belum bukti transaksi browser; ekspor1d3 sebelumnya masih mempunyai guard lama, jadi smoke kebun harus menunggu ekspor berikutnya.

Preflight berikut memakai `calendarRain(id,2)` resmi untuk memilih UUID fixture baru yang kering pada hari2. Tanpa ini,20% UUID akan sah memperoleh air hujan otomatis dan tombol Siram tidak muncul; script sebelumnya dapat menunggu aksi yang memang tidak tersedia. Tidak mengubah weather/server atau akun existing. Result metadata mencatat rainfalse. Manual water hanya diklaim setelah tombol/respons aktual. CPU node--check/prettier PASS, browser tetap pending hash/slot ekspor2.

Audit aturan aktual sebelum browser: dua **fed settlements**, bukan wajib dua hari berturut-turut; hari tanpa pakan mempertahankan progress, tidak menghasilkan anakan. Full keramba capacity5 memblokir feed sampai panen. Live parents hanya berasal dari successful oxygen>0 extract sesudah3-star reef capture; receipt replay tidak menggandakan transfer. Smoke pendek menanam jahe/menyiram manual, feed/retry, panen offspring fixture dan titip pantry; acquisition, pertumbuhan jahe4hari, breeding2hari dan bonus penyajian tetap dibuktikan regresi API terpisah, belum alur browser lengkap.
