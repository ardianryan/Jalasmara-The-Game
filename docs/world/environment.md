# Waktu, cuaca, dan efek lingkungan

Status berikut berdasarkan implementasi sumber dan pengujian browser pada 8 November 2026. Jam serta cuaca merupakan presentasi klien; server tetap menentukan hari cerita, oksigen, misi, hadiah, dan pergantian penyelaman–kedai. Menunggu jam visual berubah tidak melewati misi atau membuka kedai.

## Yang sudah tersedia

| Unsur                  | Perilaku saat ini                                                                                                                                                                                                |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Jam visual             | Autoload `EnvironmentState` mempertahankan waktu saat berganti scene dalam tab yang sama. HUD menampilkan jam dan nama cuaca.                                                                                    |
| Siang dan malam        | Warna dunia berubah bertahap melalui `CanvasModulate`. Tahap cerita `night` mengaktifkan segmen malam; bukan pergantian bebas berdasarkan jam dunia.                                                             |
| Cuaca                  | Siklus lokal 90 detik: cerah → berawan → hujan ringan → cerah. Kerapatan hujan dan peredupan awan berubah halus.                                                                                                 |
| Hujan                  | Garis hujan dan ring dampak kecil pada bagian bawah layar; tidak digambar di bawah laut. Dampak belum mengikuti geometri atap/tanah.                                                                             |
| Air permukaan          | Garis gelombang bergerak melalui gambar native dunia. Belum ada simulasi permukaan air atau perpindahan volume air.                                                                                              |
| Pembiasan bawah laut   | Screen shader dengan dua pergeseran UV kecil dan filter nearest untuk menjaga tepi pixel art.                                                                                                                    |
| Caustic dan cahaya air | Pola cahaya prosedural memudar dari kedalaman 20 hingga 110 meter. Ada berkas cahaya dan partikel ambient.                                                                                                       |
| Percikan               | Masuk laut memanggil percikan/ripple singkat dan tiga tetes lensa di tepi layar. Pemanggilan masuk laut saat ini memakai pusat layar, bukan simulasi kontak air pada setiap titik dunia.                         |
| Gelembung penyelam     | `Player.gd` mengeluarkan gelembung saat menyelam; lebih sering ketika bergerak atau oksigen rendah. Ini indikator visual, bukan konsumsi oksigen tambahan.                                                       |
| Basah setelah naik     | Pemain di hub menetes selama lima detik dan meninggalkan tanda basah sementara. Tanda belum membedakan material lantai atau mengikuti langkah kaki yang sebenarnya; actor hutan memakai implementasi tersendiri. |
| Angin hutan            | Shader menggeser kanopi secara lembut, dengan pangkal lokal tetap. Collision tidak bergoyang.                                                                                                                    |
| Lampu                  | Cahaya radial mengikuti penyelam. Empat lampu dermaga menyala pada tahap malam. Belum ada kerucut senter, bayangan occluder, atau sistem lampu malam hutan yang lengkap.                                         |

## Aturan waktu dan integrasi

`EnvironmentState.update_story(day, stage)` menyelaraskan konteks. Perubahan hari atau pergantian segmen siang/malam mengatur ulang waktu visual. Setiap tiga detik nyata memajukan satu menit: siang mulai 08:00 dan berhenti 17:50; tahap `night` mulai 18:30 dan berhenti 23:50. Perubahan tahap siang seperti `dive` ke `boss` tidak mengulang jam. Tidak ada siklus 24 jam bebas.

`snapshot()` menyediakan `clock`, `weather`, `rain`, `clouds`, `daylight`, `night`, dan `day`. Cuaca mengikuti kurva kosinus 90 detik; intensitas hujan maksimum 0,6. Jam dan cuaca tidak disimpan ke database atau penyimpanan browser. Refresh memulai kembali segmen visual sesuai progres cerita, dan perangkat berbeda tidak dijamin menampilkan jam/cuaca yang sama.

`EnvironmentEffects.configure("hub" | "forest" | "sea")` memilih suasana scene. Modulasi warna berlaku pada dunia, pembiasan memakai CanvasLayer 3, efek cuaca memakai layer 5, HUD layer 10, dan dialog berada di atasnya. Cuaca tidak meredupkan teks HUD. Jam dan efek tetap boleh bergerak selama dialog; keduanya tidak menjalankan timer kuis, bahaya, atau kemajuan cerita.

`shaders/water.gdshader` memakai sampler Godot 4 `hint_screen_texture, filter_nearest`, kekuatan pembiasan 0,0015, dan caustic maksimum 0,025. `update_depth(meter)` mengatur pemudaran cahaya. Efek hanya aktif pada area `sea`; posisi, collision, dan jangkauan interaksi tidak ikut bergeser.

`shaders/foliage.gdshader` menyediakan `strength`, `wind_speed`, dan `wind_phase`. Dengan koordinat pangkal lokal `y=0`, vertex di atas pangkal bergerak maksimal 2,5 piksel secara bawaan. Material diterapkan pada kanopi, bukan bangunan; shader tidak memindahkan collider.

## Batas biaya gambar dan pengujian

Efek lingkungan memakai satu Node2D gambar dan satu screen shader ketika menyelam. Tidak menggunakan GPU particles atau collider per partikel.

- Modul lingkungan: maksimal 56 garis hujan, 12 kandidat ring dampak hujan, 16 partikel ambient, dan tiga berkas cahaya.
- `splash(screenPoint)`: maksimal 24 entri percikan/ripple, umur 0,7 detik, jeda pemanggilan 0,12 detik. Tiga tetes lensa hanya berada di tepi layar selama 1,5 detik.
- Pemain: maksimal 24 gelembung berumur 2,2 detik dan 24 tanda basah berumur lima detik. Interval gelembung 1,5 detik ketika diam, 0,28 ketika bergerak, dan 0,16 ketika oksigen di bawah 25.
- Batas tersebut berlaku per modul; bukan batas total gambar seluruh permainan. Dunia juga menggambar biota, gelembung latar yang disaring menurut kamera, lamun, gelombang, dan cahaya.

Impor Godot headless dan pemeriksaan script lulus. Pembiasan/caustic aktif pada pengujian Chromium lanskap 844×390 melalui WebGL Compatibility tanpa error console/shader. Alur hutan dan HUD juga diuji terpisah. Bukti lokal berada pada `artifacts/godot/` dan diabaikan Git. Belum ada pengukuran FPS/baterai lintas perangkat atau pengujian HP fisik, sehingga tidak ada klaim anggaran frame tertentu.

## Yang belum diterapkan

- Cuaca yang memengaruhi arus, berenang, oksigen, spawn, akses wilayah, atau hadiah.
- Waktu/cuaca otoritatif dan persisten di server, prakiraan, musim, pasang-surut, serta sinkronisasi antar pemain/perangkat.
- Petir, kilat, badai, dan perubahan terang mendadak.
- Audio hujan, guntur, angin, langkah, tetesan, gelembung, atau audio lingkungan yang berubah mengikuti scene/cuaca.
- Simulasi air, dampak hujan sesuai geometri, genangan persisten, basah pada seluruh permukaan, dan pengeringan menurut bahan/angin.
- Bayangan dinamis atau pengaruh pencahayaan terhadap deteksi musuh dan gameplay.
- Pengaturan kualitas efek serta preferensi terpisah untuk mengurangi gerakan efek lingkungan.

Jika cuaca kelak menjadi mekanik permainan, server harus menerbitkan kondisi dan waktu transisinya sebagai bagian state sesi yang diberi versi. Perhitungan arus, oksigen, akses, spawn, serta hadiah harus memakai kondisi server. Klien hanya menginterpolasi tampilan dan tidak boleh memperoleh keuntungan melalui perubahan jam lokal, reload, atau pergantian scene. Protokol tersebut merupakan pekerjaan lanjutan, belum menjadi perilaku versi ini.
