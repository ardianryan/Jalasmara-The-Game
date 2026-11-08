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

## Perombakan lingkungan dan properti

Dibuat melalui **built-in imagegen**, lalu diperiksa dan disalin ke `client-godot/resources/art/`:

- `coastal-village-map.png`: desa pesisir Nusantara tiga perempat 2400 × 1600, dua pelataran, kedai bambu kiri, galangan kanvas tengah, rakit tani timur, pos pengawas timur laut, tangga selam di dermaga selatan, jalan hutan timur laut. Tanpa karakter, UI, tulisan atau lambang sakral. Jalur dan collision disesuaikan setelah inspeksi gambar.
- `ocean-depth-background.png`: jurang bawah air jauh, siluet batu berlapis dan reruntuhan samar, kolom tengah kosong, toska menuju nila, tanpa fauna atau penghalang dekat. Engine menambahkan cahaya dan atmosfer.
- `ocean-terrain-atlas.png`: kisi 3 × 2; tiga material batu di atas, coral garden, karang piringan, dan lamun berakar di bawah. Tidak ada UI. Putaran kedua membersihkan alpha latar bagian bawah; versi awal ditolak dan disimpan lokal.
- `forest-props-atlas.png`: kisi 3 × 2 transparan, bibit/kayu lapuk, akar bakau, stasiun sampel air bambu, longsoran batu, jembatan patah, gerbang tertutup berlumut. Perspektif tiga perempat, palet tanah dan lumut, tanpa teks. Alpha ditinjau dan dibersihkan pada putaran kedua.
- `ocean-props-atlas.png`: kisi 4 × 2 transparan; tablet memori di batu, katup pipa, filter air, kerangka lampu tanaman, bulu babi, pipa bocor, pilar roboh, peti berjala. Benda fisik bertekstur, tanpa panel UI atau tulisan.
- `sea-life-atlas.png`: delapan fauna laut, dibuat dan dibersihkan alpha-nya untuk eksplorasi awal. Fauna runtime kemudian diganti dengan keluaran generator prosedural pilihan pengguna; atlas ini bukan sumber animasi generator tersebut.

Konten referensi Dave the Diver tetap hanya pada `moodboard/` yang diabaikan Git dan tidak didistribusikan. Properti, arsitektur dan material dunia mempertahankan arah Nusantara keseharian yang telah disetujui.

- `coral-clusters.png`: tiga rumpun koral tropis berbeda dalam tiga kolom sama besar, dasar kapur, koral cabang merah muda/teal, spons oker, kipas merah redup dan lamun zaitun. Latar alpha asli, tanpa gradien, bayangan lantai, teks, atau simbol budaya. Palet mengacu atlas Jalasmara sendiri; satu edit pembersihan edge. Hasil 2172 × 724, sel 724 × 724, tanpa pengambilan piksel karya game lain.
