# Waktu dan cuaca Jalasmara

Jam dan cuaca bersifat kosmetik. Server tetap menentukan siklus cerita, oksigen, misi, serta pergantian siang–kedai. Menunggu malam pada jam visual tidak melewati misi atau membuka kedai.

`EnvironmentState` adalah autoload yang mempertahankan jam saat berganti scene. `update_story(day, stage)` menyelaraskan konteks; perubahan hari atau pergantian siang/malam mengatur ulang segmen visual. Setiap tiga detik nyata memajukan satu menit: siang dimulai 08:00 dan berhenti 17:50, sedangkan tahap `night` dimulai 18:30 dan berhenti 23:50. Perubahan tahap siang seperti `dive` ke `boss` tidak mengulang jam.

`snapshot()` menyediakan `clock`, `weather`, `rain`, `clouds`, `daylight`, `night`, dan `day`. Cuaca mengikuti kurva kosinus 90 detik: cerah, berawan, hujan ringan, lalu kembali cerah. Intensitas hujan maksimum 0,6; perubahan warna dan intensitas bertahap. Ini belum merupakan simulasi meteorologi atau cuaca yang disimpan di server.

`EnvironmentEffects.configure("hub" | "forest" | "sea")` memberi setiap scene modulasi warna dunia dan overlay efek pada CanvasLayer 5. HUD berada di layer 10 dan dialog di atasnya, sehingga teks tidak diredupkan oleh cuaca. Scene laut memperlihatkan tiga berkas cahaya dan partikel air; hujan tidak digambar di bawah air.

Efek memakai satu Node2D gambar, bukan GPU particles. Batasnya 56 garis hujan, 16 partikel ambient, tiga berkas cahaya, serta 24 entri percikan/ripple yang berumur maksimal 0,7 detik. `splash(screenPoint)` menerima posisi layar logis dan dibatasi jeda 0,12 detik. Scene memanggilnya saat masuk air atau tindakan yang menyentuh permukaan. Tidak ada collider, node, atau alokasi partikel baru per frame.

Cuaca dan jam boleh terus bergerak saat dialog dibuka; keduanya tidak menjalankan bahaya, timer kuis, maupun kemajuan permainan. Gerakan air dan pemanggilan percikan diintegrasikan oleh scene dunia. Kualitas visual dan kinerja tetap memerlukan pengujian pada perangkat HP nyata.

## Pembiasan, cahaya, dan angin

`shaders/water.gdshader` memakai screen texture Godot 4 dengan sampler `hint_screen_texture, filter_nearest`, dua gelombang UV kecil (kekuatan 0,0015), dan garis caustic prosedural berintensitas maksimum 0,025. Overlay berada pada CanvasLayer 3, di bawah cuaca (5), HUD (10), dan dialog. Hanya aktif pada `configure("sea")`; `update_depth(meter)` mengurangi caustic bertahap dari 20 sampai 110 meter. Filter nearest mempertahankan tepi pixel art. Tidak ada perubahan fisika, visibilitas server, atau posisi objek karena efek ini.

`shaders/foliage.gdshader` menggeser vertex kanopi secara lembut. Titik kaki lokal `y=0` tetap diam, sedangkan vertex di atasnya bergerak maksimal 2,5 piksel secara bawaan. Uniform `strength`, `wind_speed`, dan `wind_phase` memungkinkan tiap pohon mempunyai ritme berbeda. Collision tidak bergerak; bangunan tidak menerima material ini.

Hujan menambahkan maksimal 12 ring dampak kecil pada bagian bawah layar; ring digambar langsung tanpa alokasi partikel. Percikan juga menampilkan tiga tetes lensa pada tepi layar selama 1,5 detik. Tetes tidak menutupi pusat penglihatan. Efek petir dan kedipan kuat belum diaktifkan.

## Batas kewenangan klien

Saat ini jam, hujan, pembiasan, angin, dan tetes lensa merupakan presentasi klien. Bila kelak badai memengaruhi oksigen, arus, akses wilayah, atau hadiah, kondisi cuaca dan pergantian waktunya harus berasal dari server melalui state sesi yang diberi versi. Klien hanya menginterpolasi tampilan; perubahan clock lokal atau scene tidak boleh menghasilkan keuntungan permainan. Protokol cuaca server tersebut belum diterapkan pada versi ini.
