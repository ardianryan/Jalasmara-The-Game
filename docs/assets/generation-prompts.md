# Brief generasi aset

Semua bitmap baru di bawah dibuat melalui alat imagegen bawaan, lalu disalin ke `client-godot/resources/art/`. Screenshot moodboard menjadi referensi sudut kamera, komposisi, skala, dan hierarki ruang; tidak digunakan sebagai sprite, tekstur, atau bagian bitmap distribusi.

## Karakter

Empat berkas `male-default.png`, `male-nusantara.png`, `female-default.png`, `female-nusantara.png` memakai atlas transparan 3 × 3: baris pertama idle dan dua langkah berjalan; dua baris berikutnya enam pose renang. Brief bersama: karakter dewasa, pixel cluster jelas, outline tipis gelap, tabung oksigen sian dan Jala Kognisi, pose praktis, sembilan sel terpisah tanpa teks atau kisi, bentuk dan skala konsisten. Nala awal menjadi referensi konsistensi internal.

- Laki-laki penyelam: rompi oranye, kaus abu-abu, celana utilitas gelap, ikat kepala tenun sederhana.
- Laki-laki pesisir: kulit sawo matang, rompi teal bergaris tenun geometris umum, kain pinggang oker, celana utilitas, tanpa lambang sakral.
- Perempuan penyelam: kulit tan hangat, rambut terikat, rompi oranye dan perlengkapan selam modern.
- Perempuan pesisir: kulit sawo matang, kemben pendek teal yang menutup dada, rompi utilitas terbuka, celana pinggang tinggi, kain ikat dan harness selam. Tidak memakai pose seksual atau pakaian upacara.

## Peta darat

`forest-muara.png`: peta hutan tropis pesisir asli, sudut tiga perempat dari atas, jalur kosong dari barat daya melalui tajuk–akar–aliran timur laut dan cabang ke peti tenggara. Kelapa, pisang, bakau, paku, pondok penelitian bambu, aliran kecil dan jembatan kayu. Tidak ada karakter, UI, teks, atau simbol sakral. Lapisan tajuk, collision, cahaya, angin, dan hujan dibuat terpisah dalam Godot.

`bandar-hujung-map.png`: panorama pelabuhan rakit Nusantara, pandangan tiga perempat. Bangunan berada di bagian belakang: kedai kayu, galangan rongsok, kebun rakit, pos korporasi. Koridor pejalan kaki kosong, tangga ke laut di depan, jalur hutan di timur. Perahu kerja, bambu dan anyaman menjadi bahan sehari-hari. Tanpa karakter atau tulisan. Collision bangunan dan air mengikuti posisi pada bitmap; NPC dan peti menjadi objek terurut menurut kaki.

## Koleksi

`item-atlas.png`: delapan ikon asli dalam kisi 4 × 2 tanpa teks: Ubur-Ubur Klorofil, ikan ekosistem, Keong Rasio, ikan lentera alkalin, peti kayu berikat anyaman, prasasti memori tembaga dengan garis sirkuit fiksi, tabung oksigen, dan jala rakitan. Sudut tiga perempat untuk alat, tampak samping untuk biota, palet sian–tembaga–teal. Iterasi kedua membersihkan derau alfa latar; versi yang ditolak disimpan lokal dan tidak didistribusikan.

Generasi AI belum menggantikan tinjauan budaya atau animasi oleh manusia. Motif hanya terinspirasi tekstil sehari-hari secara umum dan tidak diklaim sebagai motif tradisional tertentu yang autentik.

## Pemeran dermaga

`npc-atlas.png`: atlas transparan 2 × 2, empat pemeran seluruh tubuh dengan kaki sejajar, sudut tiga perempat dari atas dan pixel cluster yang terbaca pada 64 piksel. Urutan Mbah Wira (blangkon, lurik, celemek, janggut putih), Beno (kupluk merah, kacamata las, wearpack biru), Bu Darmi (pakaian kebun, caping di punggung, bibit tanaman), Inspektur Raka (mantel putih, visor merah, koper). Busana keseharian pesisir yang distilisasi, tanpa simbol sakral, teks, latar, atau karakter karya lain. Dibuat menggunakan mode built-in image generation dan disalin ke aset proyek.
