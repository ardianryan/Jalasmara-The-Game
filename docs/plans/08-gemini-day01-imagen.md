# Kontrak dan prompt Imagen untuk Gemini day01

Bagian dari [handoff day01](08-gemini-day01-handoff.md). Tujuan: mengisi kekurangan art yang terbukti, dengan identitas Jalasmara yang konsisten. Bukan regenerasi massal atau pengganti perbaikan gerak/kamera. Semua hasil mula-mula **kandidat offline**.

## 1. Inventaris sebelum generate

1. Periksa `assets/source-2d/hud-bahari-v1/`, `client-godot/resources/art/hud-bahari-v1/`, `assets/source-2d/loading-bandar-hujung-v1/`, serta library proyek. Loading parallax dan HUD raster sudah ada; jangan menganggap belum dibuat.
2. Ambil screenshot native/browser baseline dengan source/PCK, waktu, cuaca, kamera, viewport dan render backend yang dicatat. Pilih kekurangan spesifik: ikon sulit terbaca, frame terlalu sibuk, hand/arm surface hilang atau noise tekstur.
3. Buat task card satu kalimat: aset existing, kekurangan, alasan script/penyesuaian existing tidak cukup, ukuran target, konsumen runtime, dan tes. Jika tidak ada kekurangan yang bisa dijelaskan, gunakan library yang ada.
4. Verifikasi tool/model Imagen yang benar-benar tersedia dalam sesi Gemini. Catat nama/model yang diberikan tool; jangan menuliskan “Imagen4” atau versi tertentu berdasarkan dugaan. Jika tidak tersedia, teruskan art scripting/aset existing dan catat blocker. Jangan memasang MCP, membeli kredit, memakai token chat lama, atau mengganti layanan berbayar diam-diam.

## 2. Aturan output

- Source baru: `assets/source-2d/gemini-day01/<task-id>/`. Tool/script baru: `tools/player-gait/gemini-day01/` atau `tools/hud-bahari/gemini-day01/` sesuai kartu. Preview/varian lengkap ignored: `artifacts/player-gait/gemini-day01/<run-id>/` atau `artifacts/hud/gemini-day01/<run-id>/`.
- Jangan menimpa sumber/aset v1. Turunan runtime UI baru, jika diterima: `client-godot/resources/art/hud-bahari-v2/`. Menambahkan folder bukan penerimaan otomatis. Karakter kandidat tetap offline sampai seluruh gate gait/upper terpenuhi.
- Setiap request memakai nama/task-id/run-id baru. Simpan prompt persis, parameter yang tersedia, referensi yang benar-benar dilampirkan, timestamp, provider/model aktual, hash source mentah dan seluruh turunan, ukuran, crop/snap/palette/alpha transform, keputusan seleksi dan alasannya.
- Moodboard adalah arah suasana, bukan aset distribusi. Jangan menghapus watermark atau mengambil piksel pack itch.io berbayar. Referensi pihak ketiga hanya dipakai jika hak penggunaan jelas. Artwork proyek yang dilampirkan dicatat sebagai input asli proyek.
- Jangan melabeli semua output AI “MIT” atau mengklaim kepemilikan engine baru atas kode upstream. Catat ketentuan provider yang diketahui; jika tidak diketahui, status lisensi/provenance belum lengkap dan aset belum boleh didistribusikan. Notice upstream yang benar-benar dipakai tetap ada.
- Transparansi harus benar-benar alpha, bukan papan checker yang digambar. Jika tool tidak mendukung alpha, simpan source opaque dengan jujur, ekstrak secara terukur pada turunan, periksa halo/outline/holes dan catat prosesnya. Jangan menghapus kulit/kain dengan threshold global tanpa inspeksi.
- Untuk runtime pixel: ukuran final berupa integer, nearest sampling, tidak ada blur/antialias fringe atau resample berkali-kali. UI ikon target32×32; cek juga tampilan48/64 lewat integer scaling jika konsumen memerlukan. Border, grid, warna dan alignment divalidasi pada hasil aktual, bukan diasumsikan dipatuhi model.
- Jangan meminta teks, angka stat, label level, progress isi, atau bahasa UI dalam gambar. Semua teks/state/timer/bar dinamis tetap dirender kode, terbaca dan terlokalisasi.
- Maksimum empat ikon pilot dahulu. Jika ada ikon ditolak, revisi terarah; jangan generate banyak varian tanpa diagnosis. Setelah pilot diterima visual/native, batch kedua maksimal delapan ikon yang masih dibutuhkan. Maksimum tiga putaran revisi per aset sebelum kembali ke existing art/pendekatan lain.

## 3. Arah visual bersama

Pesisir Nusantara, kuningan tua bersih, kayu hangat, anyaman/lontar secukupnya, aksen teal/lamun. Highlight krem hangat, bayangan indigo/teal, outline gelap berwarna. Siluet tegas dan area warna bersih; tidak ada noise padat, outline hitam berlebihan, bevel plastik glossy, neon berlebihan atau panel lebar yang menutup dunia. Gunakan gaya/cluster piksel yang cocok dengan HUD Bahari existing. Warna material dipilih bersama penerangan; jangan memaksakan seluruh objek menjadi kuning.

Untuk semua prompt di bawah, lampirkan crop **art proyek existing yang relevan** jika tool mendukung reference. Catat crop SHA dan bahwa input itu benar-benar dilampirkan. Jangan mengaku memakai screenshot jika request sebenarnya text-only.

## 4. Prompt pilot empat ikon

Jalankan satu ikon per request; bukan sprite sheet besar dengan cell yang tidak pasti. Gunakan paragraf style berikut persis, lalu salah satu subject di bawah.

```text
Create ONE original pixel-art game HUD icon for Jalasmara, a cozy Indonesian maritime exploration game. Match the attached existing Jalasmara HUD artwork in pixel cluster density, colored dark outline and material treatment. Warm aged brass and clean timber, restrained teal accents, cream highlights, cool indigo shadows. A compact readable silhouette designed to survive reduction to a final 32 by 32 pixel icon. Front-facing UI symbol, centered, consistent visual weight, generous transparent padding, isolated on a genuinely transparent background if supported. Crisp intentional pixel clusters, no smooth vector appearance, no painterly noise, no glow cloud, no photorealism. No letters, numbers, text, watermark, checkerboard pattern, button frame, background scene, secondary icon or duplicate object. Leave all UI labels and values to the game code. Produce a single icon, not a presentation sheet.
```

Subjects, satu per request:

```text
SUBJECT oxygen: one small diving oxygen cylinder with a clearly readable valve and short regulator detail, worn brass fittings and a teal-painted cylinder. No diver, no backpack, no second cylinder, no long hose crossing the silhouette.
```

```text
SUBJECT journal: one compact folded lontar field journal in a warm timber-colored cover, simple brass clasp and small teal cloth bookmark. The page shapes imply a journal without any drawn letters or pseudo-writing. No floating pages or decorative rays.
```

```text
SUBJECT interaction: one simple open human hand gesture indicating interaction, readable at tiny size, warm skin colors and minimal dark outline. Five anatomically coherent digits, no extra hand, no sleeve decoration, no exclamation mark. Preserve a clean silhouette rather than adding detail.
```

```text
SUBJECT net: one compact hand-held fishing capture net with an unmistakable loop, sparse readable woven mesh and a short warm wooden handle with a brass binding. No fish, water, character, weapon blade or surrounding scenery.
```

Pilot ikon hanya dikerjakan jika masing-masing punya gap yang nyata; ikon existing yang baik tidak perlu diganti agar jumlahnya genap empat.

## 5. Prompt frame modular, hanya bila pilot dan gap UI sudah jelas

```text
Create ONE original reusable pixel-art UI frame for Jalasmara's cozy Indonesian maritime field journal. Match the attached project HUD style. A restrained rectangular frame of warm clean timber with subtle aged brass corners and a thin colored-dark outer outline. Symmetric constant-width edges suitable for nine-slice scaling: plain repeatable horizontal and vertical edge strips, distinct compact corners, no decoration intruding into the center content area. Keep the interior a uniform calm parchment field, without text, illustrations, symbols, painted labels, numbers or fake UI controls. No perspective, no tilted panel, no drop shadow baked outside the frame, no photorealism, no dense noise or glossy plastic bevels. Crisp pixel clusters. The artwork must remain quiet behind long readable quiz text and fit a compact HUD. One frame only, isolated from any scene. Treat this as a source candidate; the game will define exact nine-slice margins after inspection.
```

Jangan otomatis memakai frame hasil AI sebagai button/header/dialogue sekaligus. Tentukan corner/edge/center region pada source asli, crop deterministik, lalu uji stretch pada ukuran kecil/lebar/tinggi. Border yang berubah ketebalan atau ornamen masuk teks berarti ditolak. Source center tidak boleh menjadi teks/raster soal. Bandingkan dengan panel existing sebelum memilih.

## 6. Prompt karakter: studi satu arah, bukan atlas produksi

Hanya jika kartu upper menyebut permukaan yang memang hilang. Lampirkan crop identitas dan pakaian proyek yang berhak dipakai. Pilih **satu arah konkret**; contoh berikut khusus explorer SOUTH/front, tidak boleh dilabeli NW atau dipakai sebagai karakter lain.

```text
Create ONE source-art candidate of the existing Jalasmara explorer character shown in the attached original project reference. Preserve this exact character identity, face, hair, headband, clothing cut, vest, belt, skin palette and pixel-cluster style. Show a direct south-facing/front view consistent with the attached project's original south-view sprite, not an isometric house camera and not a mirrored rear view. Full body, both feet visible, one neutral balanced standing pose, arms relaxed slightly away from the torso so sleeve, forearm, hand and garment boundaries can be inspected. Natural coherent anatomy with two arms, two legs and normal hands. Do not exaggerate stride or spread the legs. No weapon, fishing net, satchel, backpack, oxygen tank, tool, floating accessory, text, shadow baked on the ground, decorative background or second pose. Keep the original outfit rather than adding equipment or changing fashion. Transparent background if supported. This is a reference candidate for manual source-specific authoring, NOT a finished animation, measured joint map, rig or production sprite atlas.
```

Kandidat baru bukan sumber terukur untuk panjang tulang/joint/pivot lama. Jangan meregangkan karakter agar cocok dengan atlas128×128. Semua transform dan perubahan identitas diperiksa pada native size; pose yang salah ditolak. Arah lain perlu prompt tersendiri dari inventaris sumber arahnya, tanpa menyalin anatomi atau mask SOUTH. AI tidak menghasilkan label joint/socket yang otomatis sah.

## 7. Gerbang seleksi dan integrasi

Untuk setiap aset, catat PASS/FAIL/unknown pada siluet skala aktual, alpha/halo, palette/noise, arah/identitas/pakaian, modular gear, crop/grid, konsistensi keluarga dan ukuran byte. Lihat output asli dan turunan; jangan hanya contact sheet yang dikecilkan. Periksa gerak pada APNG/native jika aset beranimasi. Lima pose unik dalam delapan frame waktu bukan delapan pose anatomi baru.

UI kandidat hanya diintegrasikan setelah review sumber dan tes importer/atlas/slicing, lalu screenshot native/browser pada HUD siang/malam, dialogue panjang, jurnal, inventory, landscape mobile, keyboard/touch dan fullscreen. Pertahankan ukuran/hit area; jangan memperbesar HUD untuk memamerkan gambar. Tepatkan teks soal minimal sesuai standar proyek, jangan mengecilkan teks untuk memuat ornamen.

Karakter tidak masuk runtime hanya karena gambarnya lebih bagus. Ikuti gait/contact/recovery/native gates handoff; pemisahan tabung/tas/alat dan attachment harus terbukti. Building/terrain baru, sinematik, potret seluruh warga dan regenerasi loading bukan scope generasi hari ini.

Hasil yang diterima lokal tetap diberi provenance dan source SHA; yang ditolak tetap dicatat dengan alasan pada output ignored. Tidak ada penghapusan source lama, penggantian atlas massal, push, atau deploy otomatis dari Imagen.

## 8. Catatan provenance minimum per aset

Simpan `provenance.json` di folder source milik task. Bentuk berikut adalah template, **bukan metadata yang boleh disalin sebagai fakta**. Isi dari tool/file aktual; nilai tidak diketahui tetap null dengan alasan. Jangan menyimpan token, cookie, URL download bertanda tangan atau header autentikasi.

```json
{
  "taskId": "day01-ui-oxygen-pilot",
  "status": "candidate",
  "createdAt": null,
  "provider": null,
  "modelReportedByTool": null,
  "requestIdNonSecret": null,
  "exactPromptFile": "prompt.txt",
  "referencesActuallyAttached": [],
  "rawOutput": {"path": null, "sha256": null, "width": null, "height": null, "mode": null},
  "derivatives": [],
  "transformCommands": [],
  "rights": {"projectReference": null, "providerTermsKnown": false, "notice": null},
  "visualReview": {"nativeSize": "unknown", "alpha": "unknown", "identity": "unknown", "reason": null},
  "runtimeConsumer": null,
  "acceptedSourceCommit": null,
  "runtimeIntegrated": false,
  "released": false
}
```

Tambahkan hash/dimensi/alpha dan command turunan ke setiap item `derivatives`. Mencatat provider tidak otomatis membuktikan hak distribusi. `runtimeIntegrated` hanya true setelah kode konsumen dan tes benar-benar diterima lokal; `released` tetap false sepanjang delegasi day01 ini.
