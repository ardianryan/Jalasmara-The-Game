# Kostum dan perlengkapan karakter modular

Empat atlas dasar `resources/art/{male-default,male-nusantara,female-default,female-nusantara}-base-v1.png` dibuat pada 9 November 2026 menggunakan tool imagegen bawaan, masing-masing sebagai edit atlas karakter orisinal dengan identitas yang sama. Keluaran PNG disalin tanpa pengolahan piksel; atlas lama tetap disimpan. Ini bukan sprite dari game referensi.

Empat atlas tambahan `resources/art/{male-default,male-nusantara,female-default,female-nusantara}-outfits-v1.png` kemudian dibuat melalui edit per identitas untuk pakaian berdiri: baris pertama kaus harian, baris kedua jaket lapangan dengan celana panjang, baris ketiga wetsuit penuh. Setiap baris berisi tiga pose idle/berjalan dengan tangan kosong.

Setiap atlas dasar tetap mempunyai sembilan sel: tiga pose berdiri/berjalan memakai kaus harian dan enam pose berenang dengan pakaian renang indigo. Identitas wajah, rambut, kulit, ikat kepala dan alas kaki mengikuti varian asal. Rompi, tabung oksigen, pipa, tas dan jala yang semula tergambar menyatu dihapus dari gambar dasar. Pose serta jarak antarsel tetap mengikuti atlas sumber, dengan kalibrasi kaki berdasarkan alpha saat dirender.

`CharacterVisual.gd` memilih gambar dasar baru dan menyediakan `set_outfit`, `set_equipment` serta `get_equipment_state`. Kostum `daily` tidak membawa perlengkapan; `explorer` memilih jaket lapangan pada atlas pakaian dan menampilkan tas terpisah; `diving` menampilkan tabung dan jala. Tabung, jala dan tas dibuat sebagai geometri orisinal terpisah di `CharacterEquipment3D.gd`, kemudian dipasang mengikuti pose/facing oleh renderer daratan dan laut. Perlengkapan dapat dinonaktifkan sendiri tanpa mengganti gambar badan. Atlas lama yang masih memuat perlengkapan tidak menerima tabung/jala tambahan.

Batas implementasi: ini bukan sistem rig tulang atau simulasi kain. Tas explorer adalah model sederhana yang mengikuti badan; gerakan tangan dan kaki tetap animasi atlas. Sirip pada pose berenang masih bagian dari gambar dasar. Pakaian selam berdiri mempunyai baris wetsuit sendiri; pose berenang menggunakan kembali atlas dasar tanpa perlengkapan. Rompi model hanya menjadi fallback ketika atlas pakaian khusus belum tersedia. Sistem ini tidak mengubah statistik oksigen, inventori, harga atau progres.

## Instruksi edit yang dipakai

Setiap panggilan menyertakan satu atlas asal yang sudah diperiksa. Instruksi utamanya: pertahankan kisi 3×3, wajah, rambut, gender, kulit, ikat kepala Nusantara, proporsi, posisi kaki dan sembilan pose; ganti tiga pose darat dengan kaus lengan pendek teal dan celana kargo gelap; ganti enam pose berenang dengan pakaian renang indigo berlengan pendek; hapus seluruh rompi, tali, tabung, pipa, kacamata, tas, jala dan alat genggam; tangan kosong; latar alpha transparan; tanpa tulisan, simbol baru, lantai atau elemen budaya sakral.

Panggilan tambahan untuk atlas pakaian mempertahankan identitas dan tiga pose darat, lalu menyusun tiga baris pakaian berbeda: kaus harian, jaket lapangan dengan celana kargo panjang, serta wetsuit indigo berlengan/pipa panjang dengan panel teal. Seluruh tangan kosong, tanpa tabung, tas, jala atau alat lainnya.

## Verifikasi

Tes `scripts/tests/character-outfits.gd` memeriksa empat identitas, tiga keadaan kostum, pemilihan sel animasi, perlengkapan independen yang jumlah meshnya dibatasi, penolakan tabung ganda pada atlas lama, serta tidak adanya perubahan data permainan. Hasil render native perlu diperiksa bersama adegan permainan sebelum rilis karena tes keadaan saja tidak membuktikan kualitas pemasangan visual.
