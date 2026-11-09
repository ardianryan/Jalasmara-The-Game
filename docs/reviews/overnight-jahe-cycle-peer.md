# Peer CPU: jahe empat siklus

Review read-only kandidat `aee7f642148cf6719b30aa6c97d737d81ac3e8c8`: `jahe-cycle-browser.mjs`, helper/tes fixture, serta authority homestead/daily/shared saat ini. Tidak menjalankan browser, membuat akun, menulis DB, mengubah source atau mengganggu slot website.

Tidak ditemukan blocker atau pengganti aksi otoritatif. Satu insert awal menyatakan izin/story2,250koin,satu benih dan hasil/pantry/indukan kosong; flag attempted ditetapkan sebelum await insert. Initial Redis surface ditulis sebelum login. Setelah itu tidak ada penulisan hari, growth, produce atau posisi oleh harness: interaksi memakai keyboard UI, sementara GETstate hanya membaca authority. WORLD HTTP/definitions harus cocok dengan setup shared; tidak mengandalkan definisi harga/durasi buatan.

Empat UUID care days2–5 dipilih benar-benar kering oleh calendarRain deterministik. Setiap loop memverifikasi growth sebelumnya, menekan Siram, memeriksa wateredDay tanpa growth langsung, berjalan ke rumah/bed, mengirim sleep confirmEarly melalui UI, dan memeriksa tepat+1 kalender/+1 growth. Exit dan rute kembali ke petak juga nyata. Ini sesuai `settleCalendar`: hanya wateredDay hari sebelumnya atau hujan yang menaikkan growth, maksimal satu per settlement hari. Calendar2→6/growth0→4/ready terakhir, harvest3 lalu pantry1+produce2,250koin/story2/dive/missionakar/emptyinventory/emptyparents dipatok. Benih disediakan fixture; tidak membuktikan pembelian30koin, penjualan atau bonus penyajian12koin. Tidak ada aksi jual crop langsung pada authority yang diperiksa.

Cleanup membatasi delete player ke UUID/email/name/role fixture, receipt ke prefix UUID, shift ke userId dan Redis ke key miliknya. Auth-cookie dicocokkan userId sebelum dihapus dan scan fallback memakai exactuserId untuk uncertain login ACK; jumlah sisa player/receipt/shift/auth/key harus nol. Exception browser shutdown tidak melewati blok cleanup DB. Tidak ada penghapusan akun lain/reset volume.

Pemeriksaan CPU sendiri: **2/2 fixture tests PASS** dan `node --check scripts/jahe-cycle-browser.mjs` PASS. Rute valid/current WORLD tidak berubah; perubahan durasi crop dan pendekatan bed tak terjangkau ditolak. Ini bukan hasil run aktual yang sedang dipegang website.

Batas/saran kecil, tanpa memperluas skenario:

- Counter akhir memakai `operations` dari respons sukses yang ditunggu; trace lengkap perlu diperiksa bila ingin menyebut jumlah seluruh POST/retry jaringan, bukan jumlah aksi semantik yang diawait. Tidak ada replay/idempotency negatif tambahan dalam skenario ini.
- Screenshot setelah tiap sleep diambil ketika panel bed masih terbuka, sehingga membuktikan konteks tidur dan state respons, bukan empat tampilan visual tahap tanaman di petak.
- Budget15menit diperiksa di loop navigasi/waitState; attach240detik dan response wait60detik dapat menunda penghentian run gagal. Panggil budget sebelum completed bila memerlukan batas sukses akhir yang ketat; jangan menafsirkan watchdog navigasi sebagai deadline wallclock absolut semua fase.
- Kesetaraan reload mematok version/coins/plots/stocks/story/calendarDay dan UI revision sebelum lanjut. Ini tidak menguji semua field migrasi/market/pending-story atau penyajian bonus. Batas tersebut sesuai scope crop lifecycle dan tidak memerlukan perubahan gameplay.
