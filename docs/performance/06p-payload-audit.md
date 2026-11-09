# 06-P: inventaris payload dan satu usulan pemuatan website

Tanggal: 9 November 2026. Audit CPU dan ukuran berkas; tidak menjalankan browser, Godot, import/export, atau benchmark. Paket yang diperiksa ialah PCK rilis 06-A dengan SHA-256 `a9378a52c9fbb64ec96ae579bcef1ced1ab7920962823025e238a453eb8a716b`. Source runtime-nya `2f7f551`; eksperimen website memakai `ca78445`.

## Ukuran yang benar-benar dihitung

| Berkas/kelompok | Byte tersimpan | Makna |
| --- | ---: | --- |
| `index.pck` | 64.249.828 | Paket resource impor Godot, bukan ukuran tekstur setelah didekode oleh GPU. |
| `index.wasm` | 39.514.754 | Representasi WASM tanpa content encoding HTTP. |
| `index.wasm.gz` | 10.054.758 | Sidecar gzip yang tersedia; staging mengembalikannya untuk permintaan dengan `Accept-Encoding: gzip`. |
| `index.js` / `index.js.gz` | 279.815 / 68.471 | JavaScript loader engine dan sidecar, berbeda dari bundle React website. |
| Seluruh berkas dalam `public/game`, termasuk `.gz` | 114.210.145 | Penggunaan disk. Menjumlahkan versi asli dan gzip bukan jumlah unduhan pemain. |
| Berkas utama `public/game`, tanpa `.gz` | 104.081.993 | Jumlah ukuran berkas sebelum HTTP encoding, termasuk HTML/ikon/worklet. Tidak membuktikan semua berkas selalu diminta. |
| Representasi gzip bila tersedia, berkas lainnya asli | 74.401.306 | Potensi ukuran body HTTP jika semua berkas utama diminta sekali. Belum termasuk header/TLS dan bukan rekaman transfer jaringan. |

Empat berkas inti bootstrap–loader–WASM–PCK berjumlah **104.048.396 B** sebelum encoding dan **74.374.625 B** dengan sidecar gzip yang tersedia. Ini kalkulasi berkas, bukan waktu startup atau jumlah transfer pada sesi tertentu. Cache, worklet yang benar-benar dipakai, respons API, gambar loading dan aset website di luar folder game perlu dihitung lewat rekaman jaringan tersendiri.

Pemeriksaan HEAD publik pada **9 November 2026, 08.00.36 UTC**: `/game/index.wasm` merespons `Content-Encoding: gzip` dengan `Content-Length: 10054758`; `/game/index.pck` tidak mengirim content encoding dan panjangnya `64249828`. Keduanya `200`, `Vary: accept-encoding`, dan `Cache-Control: public, max-age=0`. HEAD memeriksa header representasi, bukan mengunduh dan menghitung trafik tubuh respons. Tidak ada perubahan server atau cache.

Gzip level 9 pada PCK menghasilkan **63.469.128 B**, hanya mengurangi **780.700 B atau 1,22%**. `scripts/export-game.mjs` memang melewati sidecar PCK jika penghematannya di bawah 5%. Memaksa gzip pada paket ini bukan usulan utama.

## Isi PCK dan resource terbesar

Parser read-only `scripts/performance/pck-inventory.py` mengikuti struktur standalone pack pada [reader resmi Godot 4.7.2](https://github.com/godotengine/godot/blob/4.7.2-stable/core/io/file_access_pack.cpp#L268) dan [definisi flag](https://github.com/godotengine/godot/blob/4.7.2-stable/core/io/file_access_pack.h#L38). Versi PCK yang ditemukan ialah **4**, versi engine **4.7.2**, dan flag **2**. Semua **647 payload** cocok dengan MD5 di tabelnya. Parser menolak pack terenkripsi/sparse/delta; ia tidak mengekstrak atau menghapus berkas.

Ukuran payload **64.184.584 B**; header, tabel direktori, dan alignment menyumbang **65.244 B**. Hasil lengkap: [06p-payload-inventory.json](06p-payload-inventory.json).

Perintah reproduksi: `python3 scripts/performance/pck-inventory.py apps/web/public/game/index.pck --expected-sha256 a9378a52c9fbb64ec96ae579bcef1ced1ab7920962823025e238a453eb8a716b`. Pemeriksaan CPU tambahan memastikan SHA kandidat yang salah ditolak dan perubahan satu byte pada payload terdeteksi sebagai ketidakcocokan MD5. Parser lulus kompilasi Python tanpa menjalankan engine.

| Kelompok | Jumlah | Byte di dalam PCK | Bagian dari berkas PCK |
| --- | ---: | ---: | ---: |
| Tekstur impor `.ctex` | 142 | 43.933.810 | 68,38% |
| Musik impor `.mp3str` | 4 | 16.187.080 | 25,19% |
| Suara impor `.sample` | 61 | 1.931.147 | 3,01% |
| Font impor `.fontdata` | 2 | 1.242.284 | 1,93% |
| Skrip terkompilasi `.gdc` | 70 | 523.077 | 0,81% |
| JSON | 49 | 234.302 | 0,36% |

Empat musik masing-masing menyumbang 3,87–4,24 juta B. Tekstur besar berikutnya: `coastal-village-map` **2.972.060 B**, `forest-muara` **2.699.606 B**, `bandar-hujung-map` **2.492.236 B**, `forest-props-atlas` **2.335.724 B**, `muara-sungsang` **2.250.302 B**, serta atlas terrain/atmosfer laut sekitar **2,08 juta B** per resource. Angka tersebut ukuran container impor yang tersimpan; tidak sama dengan memori GPU atau dampak frame time.

## Source, cache import, runtime, dan duplikasi

- Pada main saat audit, source art menempati **56.571.644 B**, model **1.553.543 B**, dan audio **25.658.300 B**. Cache `.godot/imported` menempati **65.398.145 B**. Besaran disk ini tidak dijumlahkan lagi sebagai unduhan pemain.
- PCK berisi `.ctex`, `.mp3str`, `.sample`, `.fontdata`, scene/resource hasil impor, dan `.gdc`. Tidak ada entri PNG, GLB, WAV, MP3, OTF, atau WOFF2 mentah yang menggandakan sumbernya. **211 berkas `.import` hanya 41.052 B** dan merupakan metadata remap, bukan salinan gambar/audio.
- Ada **9 kelompok payload identik secara SHA-256**, dengan kelebihan teoretis **351.494 B atau 0,55%**. Lima pasang tekstur hasil impor `memory-slab_0…4` dan `_5…9` menyumbang 310.164 B; sisanya pasangan ikon tas, oksigen, slot dan panel kertas. Mengurangi berkas secara langsung dapat memutus referensi material/tema. Penghematan itu memerlukan pengalihan referensi lalu import/export dan regresi visual, bukan sekadar menghapus duplikat.
- `bgm_coastal_day.wav` dan `bgm_underwater_ambient.wav` menjadi fallback eksplisit di `AudioManager.gd` setelah MP3. Keduanya menyumbang **927.062 B** di PCK. Mereka belum layak dihapus tanpa mengganti kontrak fallback dan membuktikan MP3 selalu tersedia pada seluruh target.
- `forest-muara`, `coastal-village-map`, dan `bandar-hujung-map` masih ditemukan dalam pemuatan runtime/fallback; contoh pemakaian aktif `forest-muara` ada pada `LandWorld3D.gd`. Pencarian nama tidak menggantikan audit pemuatan dinamis. Export tetap `all_resources`, tanpa perubahan include/exclude.
- `muara-sungsang.png` juga tersedia di website sebagai ilustrasi login **2.641.811 B**. Salinan representasi impor di PCK bukan byte identik dengan PNG, dan keduanya melayani konteks berbeda. Belum ada perubahan atau klaim bahwa seluruh representasi itu tidak terpakai.
- Build website menyimpan banyak subset font di disk karena impor Fontsource. CSS memakai `unicode-range`; jumlah seluruh file font hasil build tidak membuktikan semuanya diunduh pada satu halaman. Aset loading dengan selector CSS yang belum terpasang juga tidak boleh dihitung sebagai request tanpa bukti jaringan.

## Usulan terkecil: muat panel pengelola saat dibuka

`main.tsx` mengimpor `Admin` secara statis sebelum menentukan apakah pengguna sedang login, pemain, atau pengelola. Vite memasukkan `admin.tsx` ke entry yang sama. Usulan pertama ialah memakai `React.lazy` dan `Suspense` dengan komponen `Loading` yang sudah ada untuk route `/admin`. Tidak memerlukan library, perubahan izin server, filter export, atau pemangkasan resource.

Eksperimen build CPU mengubah impor dan pembungkus JSX **di memori**, dengan `write:false`. Source produksi tetap utuh. Vite 6.4.5, plugin React, dan minifikasi sama; nama chunk dibuat tetap untuk perbandingan. [Hasil eksperimen](06p-website-split-experiment.json):

| Representasi JS | Sekarang | Usulan | Selisih awal |
| --- | ---: | ---: | ---: |
| Entry tanpa encoding | 267.576 B | 244.031 B | Berkurang 23.545 B atau 8,80%. |
| Entry, perkiraan gzip level 9 | 82.547 B | 76.217 B | Berkurang 6.330 B atau 7,67%. |
| Chunk Admin terpisah | Tidak ada | 24.559 B; perkiraan gzip 7.555 B | Diminta ketika panel dibuka. |

Jika pengelola membuka kedua chunk, jumlah JS menjadi **268.590 B**, bertambah **1.014 B** dari versi sekarang dan membutuhkan satu permintaan tambahan. CSS dan font tidak dipisah pada eksperimen ini. Penghematan tersebut membantu muatan awal login/pemain dalam lingkup kecil; ia **tidak mengurangi PCK, biaya render dunia, atau membuktikan peningkatan FPS**.

Usulan belum diterapkan. Jika dipilih, penerimaan harus mencakup login/pemain tanpa request chunk Admin, pembukaan panel dengan status pemuatan yang terbaca, kegagalan mengunduh chunk dan pemulihannya, role gate yang sama, serta regresi draft/dialog. Hasil build ini belum membuktikan perilaku browser tersebut.

Tidak ada alasan dari audit ukuran ini untuk mengganti engine, menghapus atlas besar, menurunkan semua kualitas, atau mengubah progres/ekonomi. Optimasi render Windows/S23 tetap mengikuti pengukuran perangkat yang sebenarnya.
