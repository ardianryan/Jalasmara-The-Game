# 06-B2 — tindak lanjut karya arah dan genggaman Ujang

Audit CPU pada cabang `work/06b-body-pilot`, mengacu pada kandidat runtime `f7d3f0d50d5f970c92c53fcddfe0aa21c66b3bad`. Dokumen ini tidak menerima kandidat tersebut sebagai mutu animasi akhir atau rilis. Lihat [kandidat kontak mekanik](06b2-ujang-contact-pilot.md) dan [persiapan B2](06b2-pilot-preparation.md).

Tidak ada gambar baru, pengunduhan pustaka, pekerjaan API berbayar, engine, browser, atau perubahan runtime dalam tindak lanjut ini. Pemeriksaan berkas, metadata, kode pemotong, dan catatan asal aset menemukan **belum ada empat arah Ujang yang digambar secara autentik** dalam pustaka proyek.

## Sumber yang tersedia dan hak pakai

| Berkas | Fakta yang diperiksa | Pemakaian yang masuk akal |
| --- | --- | --- |
| `client-godot/resources/art/village-residents-v1.png` | RGBA 1536 × 1024, tiga kolom × dua baris. Ujang berada pada sel kanan atas: crop `[1024, 0, 512, 512]` dalam format x/y/lebar/tinggi. | Sumber identitas, warna, dan potongan asli Ujang. Hanya satu pose tiga perempat. |
| `client-godot/resources/art/npc-rigs/ujang.png` dan `ujang.json` | Atlas RGBA 320 × 256, grid 5 × 4, sel 64 × 64, 16 bagian, `bodyHeight: 100`, `footPivot: [0, 0]`. | Rig yang sedang diuji; bukan kumpulan empat ilustrasi arah. |
| `client-godot/resources/art/player-gait/male-default-explorer-idle-8way-v1.png` | RGBA 1024 × 128, delapan sel 128 × 128 dengan pivot produksi `[64, 104]`. Manifest sumber berada di `assets/source-2d/nala-eightway-batch/manifest.json`. | Referensi teknis arah/pivot dan karya orisinal proyek; **bukan tubuh atau pakaian Ujang siap pakai**. |
| `assets/source-3d/polyfork/` | Atribusi mencatat model Bamboo Stalk, Fern Plant, dan Small Reef Rock, berlisensi CC BY 4.0. | Lingkungan; tidak menyediakan nelayan atau anggota tubuh manusia. |
| `client-godot/resources/art/library/crawl/` | Empat ubin dirt/grass/sand/limestone terpilih, CC0; bukti asal di `assets/source-2d/crawl-tiles/source.json`. | Bahan permukaan lingkungan; tidak menyediakan pose atau telapak. |

`LICENSE` bagian 1 menerapkan MIT pada kode dan alat. Bagian 2 menyatakan **All Rights Reserved (ARR)** untuk karya asli permainan, termasuk `client-godot/resources/art/`. Izin mengerjakan Jalasmara dari pemilik proyek tidak mengubah atlas menjadi paket sprite MIT atau memberi izin pemakaian dalam permainan lain. Aset pihak ketiga tetap mengikuti lisensinya sendiri; lihat `THIRD_PARTY_LICENSES.md`. Catatan generasi karya warga dan turunan potongannya berada di `docs/assets/provenance.md` dan `tools/npc-rig/README.md`.

### Hash sumber dan turunan yang diaudit

SHA-256 berikut mengikat audit pada isi berkas, bukan sekadar nama:

```text
09fd3e55f16b7a17c5077a1b693d4284e04437c7c19ab90ccbca8f210bc5afde  client-godot/resources/art/village-residents-v1.png
cb56e361fdff2ffe0efedfdc63d35c7f945a6357576f3c86a7e4a5e4141fb89c  client-godot/resources/art/npc-rigs/ujang.png
65f59d975a31ec0691d36a520969a3d67ce6fdd150d5f09d2c9a833742d3c9b3  client-godot/resources/art/npc-rigs/ujang.json
1b129c202dc0d9653cf7e8b15358527264f22e2ac749e61ad5212f0dffa7ff53  client-godot/resources/art/player-gait/male-default-explorer-idle-8way-v1.png
```

## Identitas dan arah yang belum tersedia

Sumber Ujang memperlihatkan topi biru tua dengan tali emas, rambut kelabu, kemeja krem, rompi cokelat bertambal, celana pendek indigo bertambal, sandal, serta kaki kayu pada sisi kanan gambar sumber. Asimetri ini harus dipertahankan. Nala berusia lebih muda, memakai ikat kepala dan pakaian/alas kaki berbeda; mengganti warna atau menukar kepala Nala tidak memenuhi identitas Ujang.

`tools/npc-rig/generate.py:15` menetapkan crop Ujang dan mask. Bagian pemotongan pada baris 83–119 mengambil gambar asli serta menambal kain tertutup dengan sampel dari potret yang sama. Baris 120–132 membuat `head_back` dan `torso_back` dari silhouette depan dengan palet rambut `#697079` dan kain `#816348`. Itu konstruksi warna, bukan pengamatan atau ilustrasi belakang yang baru.

Pada rig, arah selatan memakai potret tiga perempat; barat/timur memakai karya yang dicerminkan. Arah utara menggunakan bagian belakang sederhana tadi. Koreksi kontak, bidang lutut, dan IK pada kandidat `f7d3f0d` tidak mengisi kekurangan karya arah tersebut. Sumber Nala delapan arah dapat memberi contoh kontrak teknis, tetapi tidak membuktikan adanya tampak belakang/samping Ujang.

## Pilot karya terkecil berikutnya: utara, dua slot tubuh atas

Usulan **belum dibuat**: satu atlas `ujang-north-upper-v1.png` berisi dua sel 64 × 64 untuk `head_back` dan `torso_back`. Ukuran opak acuan saat ini adalah kepala 29 × 27 dan torso 33 × 34. Karya baru perlu memperlihatkan belakang topi/tali, rambut kelabu, kerah, rompi dan tambalan dengan silhouette belakang yang memang digambar, tanpa wajah depan yang sekadar diwarnai ulang.

Kontrak yang perlu ditinjau setelah karya tersedia:

- Root/telapak tetap `[0, 0]`, tinggi acuan tetap 100, jumlah bagian rig tetap 16. Tidak mengubah navigasi atau prop modular.
- Acuan sambungan lama: leher `[0, -69.140625]`; bahu kiri `[-12.109375, -60.15625]`, kanan `[14.6484375, -62.890625]`.
- Pusat kepala lama `[-4.6875, -81.54296875]` mengandung offset pose/hidung depan. Jangan menyalinnya sebagai pivot belakang tanpa peninjauan gambar; pusat torso lama `[0.09765625, -52.44140625]` juga perlu dibandingkan dengan sambungan bahu karya baru.
- Tinjau pada ukuran permainan, arah utara diam/berjalan/bicara, dan pergantian arah. Jangan menerima hanya karena atlas dapat dimuat atau jumlah piksel berubah.

Pilot ini memperbaiki **satu arah dan dua lapisan**. Ia belum menyelesaikan tampak samping asli, anggota tubuh belakang, kontak telapak tangan, maupun mutu berjalan keseluruhan. Detail belakang yang tidak terlihat pada sumber tetap memerlukan karya orisinal baru; tidak ada aset pustaka yang dapat dianggap mengisinya otomatis. PixelDoll tetap kandidat alat mendatang, tanpa asumsi akses, lisensi hasil, atau hasil yang sudah tersedia.

## Genggaman: pengukuran independen masih belum tersedia

Sumber asli memuat tali/jala di satu tangan dan pipa rokok pada tangan terangkat; benda itu bukan joran produksi. `generate.py:107–112` mengambil crop tangan 26 × 25 lalu mengecilkannya menjadi 5 × 5. Titik terminal lengan Ujang pada sumber lokal adalah `[211, 270]` dan `[343, 146]`. Sisa tali/pipa pada potongan tidak sama dengan telapak memegang joran.

`ujang.json` menyediakan crop dan pivot tangan `[2.5, 0]`, tetapi belum mempunyai anotasi independen `gripPixel`, sumbu batang, atau posisi jari. Jarak socket IK ke garis joran yang dibangun dari socket itu sendiri bersifat melingkar. Karena itu, kandidat `VillageActivity3D.gd` menandai pengukuran Ujang sebagai **unknown**, bukan kontak nol piksel yang dinyatakan lulus.

Jika genggaman didahulukan, alternatif pilot kecil adalah **satu telapak memancing arah barat**, sekitar paling besar 7 × 7 piksel runtime, dengan warna kulit Ujang. Setelah gambar benar-benar ada, tandai piksel kontak jari/telapak dan sumbu joran pada karya tersebut, lalu ukur transform keduanya secara terpisah pada prepare/work/end dan pose bicara. Ukuran dan arah ini usulan batas kerja, bukan metadata yang sudah sah. Jangan mengisi koordinat grip hipotetis sekarang. Referensi tangan Nala tidak menggantikan peninjauan tangan Ujang.

## Batas bukti dan keputusan lanjutan

Audit ini memakai sumber tersimpan dan inspeksi CPU sebelumnya; tidak menambah rekaman visual atau mengulang tes runtime. Bukti kontak mekanik kandidat tetap dirujuk melalui `06b2-ujang-contact-pilot.md`, termasuk batas silhouette boneka dan status belum diterima sebagai karya berjalan akhir. Hash memastikan sumbernya sama, bukan membuktikan mutu gambar.

Langkah berikut yang paling kecil adalah meninjau karya utara dua slot sebelum integrasi, atau memilih telapak grip sebagai pilot terpisah. Keduanya memerlukan karya yang belum ada; keduanya tidak boleh dilabeli empat arah selesai, tidak memperluas rig warga lain, dan tidak otomatis memasukkan kandidat `f7d3f0d` ke rilis.
