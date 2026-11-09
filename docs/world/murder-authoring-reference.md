# Referensi authoring: Murder, Pixprite, dan OpenWorld

Diperiksa pada 9 November 2026. **Status Jalasmara: riset sumber resmi; belum ada kode, editor, paket, atau aset dari ketiga proyek yang diimpor.** Godot tetap menjadi runtime web. Manifest bersama tetap menentukan lantai, footprint, rute, zona, dan validasi server.

## Murder: pola editor dunia

[Murder](https://github.com/isadorasophia/murder/blob/f4ee951bb4f2f925fe8b0252844357e21ffd6b8d/README.md) adalah engine C# untuk pixel art, dibangun di atas FNA dengan ECS Bang. Editor menjadi proyek terpisah milik game; README menyatakan web dan mobile belum didukung secara resmi. Karena Jalasmara memerlukan browser, pendekatan yang relevan adalah cara mengarang dunia, bukan pemindahan engine.

| Yang diperiksa pada sumber Murder | Adaptasi konkret yang diusulkan untuk Jalasmara |
| --- | --- |
| [WorldAsset](https://github.com/isadorasophia/murder/blob/f4ee951bb4f2f925fe8b0252844357e21ffd6b8d/src/Murder/Assets/WorldAsset.cs) menyimpan instance beridentitas GUID, referensi atlas, serta kelompok editor. | Pertahankan ID prop/POI yang stabil; kelompokkan permukaan, bangunan, vegetasi, interaksi, dan dekorasi belakang tanpa mengubah identitas save. |
| [WorldAssetEditor](https://github.com/isadorasophia/murder/blob/f4ee951bb4f2f925fe8b0252844357e21ffd6b8d/src/Murder.Editor/CustomEditors/WorldAssetEditor.cs) menyediakan stage, palet prefab, inspector, serta tab tiles, pathfinding, story, dan sound. | Buat alat authoring lokal dengan overlay footprint, clearance badan, rute NPC, tangga, dan gerbang terkunci di atas preview Godot. Perlihatkan collider bersama bentuk visual saat menempatkan prop. |
| [PrefabAsset](https://github.com/isadorasophia/murder/blob/f4ee951bb4f2f925fe8b0252844357e21ffd6b8d/src/Murder/Assets/PrefabAsset.cs) mengemas entity beserta anaknya. | Definisikan modul rumah limas, kantor kontainer, jembatan, dan bilik sebagai kumpulan render serta footprint yang berpasangan; penempatan tidak boleh hanya menambah gambar. |
| [UndoTracker](https://github.com/isadorasophia/murder/blob/f4ee951bb4f2f925fe8b0252844357e21ffd6b8d/src/Murder.Editor/Core/UndoTracker.cs) memisahkan aksi undo/redo. | Perubahan authoring menjadi operasi yang dapat dibatalkan, lalu menghasilkan diff manifest untuk ditinjau. |

Semua adaptasi editor di atas **masih usulan**. Jalasmara sudah mempunyai manifest modular dan pengujian lintasan/renderer; itu bukan hasil impor Murder. Langkah implementasi berikutnya dapat berupa Godot `EditorPlugin` lokal yang membaca snapshot manifest dan mengekspor perubahan tervalidasi. Ekspor harus melewati pemeriksaan lantai/rute/footprint sebelum mengganti versi layout. Editor tidak diberi akses langsung ke saldo, hadiah, atau akun produksi.

## Pixprite: penyunting sprite offline

[Pixprite](https://github.com/vicimpa/pixprite/blob/d4a180d8d49cc409e96e8c30e52a4d20c2f51013/README.md) adalah aplikasi penyunting pixel art, animasi, dan tilemap. Sumber yang diperiksa adalah versi 0.0.6, commit `d4a180d8d49cc409e96e8c30e52a4d20c2f51013`. Browser menyimpan proyek melalui IndexedDB dan mendukung penggunaan offline setelah pemuatan awal lengkap. Desktop menggunakan Tauri; [package.json](https://github.com/vicimpa/pixprite/blob/d4a180d8d49cc409e96e8c30e52a4d20c2f51013/package.json) menunjukkan aplikasi React/Vite privat, bukan paket runtime Godot.

Pemakaian yang masuk akal ialah menyunting layer pakaian, memperbaiki siluet dan pivot, serta memeriksa frame animasi melalui onion skin. Hasil PNG/spritesheet kemudian masuk pipeline aset Jalasmara yang sudah ada. Ekspor JSON/CSV tilemap memerlukan konverter dan validasi sebelum dapat menjadi `WORLD.landMaps`; format tersebut tidak otomatis memiliki kontrak elevasi, collision, rute, atau hadiah server kita. File `.pixprite`/`.aseprite` tetap menjadi berkas kerja authoring. **Belum ada uji round-trip ekspor Pixprite ke Godot atau konverter manifest dalam perubahan ini.**

## OpenWorld: format peta dan penghubung wilayah

[OpenWorld](https://github.com/SihanXU/openworld/blob/076ab27d5312416cbabe19c12b90e086f5fc32d7/README.md) menyediakan game browser, engine TypeScript deterministik, serta editor. Pin penelitian: `076ab27d5312416cbabe19c12b90e086f5fc32d7`. Pemeriksaan [chunk.ts](https://github.com/SihanXU/openworld/blob/076ab27d5312416cbabe19c12b90e086f5fc32d7/packages/engine/src/chunk.ts), [skema](https://github.com/SihanXU/openworld/blob/076ab27d5312416cbabe19c12b90e086f5fc32d7/packages/format/schema/map.schema.json), dan [peta cottage](https://github.com/SihanXU/openworld/blob/076ab27d5312416cbabe19c12b90e086f5fc32d7/games/starter/maps/cottage.json) menunjukkan format aktif `map` + `entities`: terrain berupa baris karakter, `heights` opsional, portal dengan tujuan/koordinat, serta anchor. Ini **bukan impor Tiled JSON langsung**; catatan desain lama harus dibedakan dari format kode saat ini. `stamps` dan rekaman brush merupakan petunjuk authoring/render, bukan terrain otoritatif.

Adaptasi yang diusulkan ialah adapter offline menuju `WORLD.landMaps`: tetapkan ukuran tile ke piksel dunia; gabungkan tile lantai menjadi poligon; petakan ketinggian ke elevasi dan konektor; ubah entity penghalang menjadi footprint; ubah portal menjadi gerbang dengan spawn tujuan yang sah. Material Nusantara, ID zona, rute NPC, serta prasyarat cerita tetap memakai data Jalasmara. Validasi harus menolak ID ganda, endpoint portal di air/solid, loncatan elevasi tanpa tangga, serta lintasan terputus sebelum preview Godot dan kenaikan versi layout.

**Belum ada adapter, editor, streaming chunk, atau runtime OpenWorld yang dipasang.** Fitur usulan ini tidak mengaktifkan aturan LLM saat permainan berjalan atau mengubah kewenangan server atas akun, kuis, ekonomi, dan hadiah. Manfaat terdekat adalah authoring peta serta pengujian konektivitas antarwilayah.

## Lisensi dan batas pemakaian

[Murder LICENSE](https://github.com/isadorasophia/murder/blob/f4ee951bb4f2f925fe8b0252844357e21ffd6b8d/LICENSE) dan [Pixprite LICENSE](https://github.com/vicimpa/pixprite/blob/d4a180d8d49cc409e96e8c30e52a4d20c2f51013/LICENSE) memakai MIT. Jika kode atau bagian substansial perangkat lunaknya disalin/didistribusikan, pertahankan pemberitahuan hak cipta dan teks izin MIT. Dependensi serta aset pihak lain harus diperiksa menurut lisensinya masing-masing. Dokumen ini hanya mencatat temuan dan rancangan adaptasi; tidak menyalin implementasi atau menetapkan lisensi baru untuk Jalasmara. Kebijakan kontribusi Murder juga menolak kontribusi berbantuan AI; tidak ada kontribusi upstream yang dibuat di sini.

[Lisensi OpenWorld](https://github.com/SihanXU/openworld/blob/076ab27d5312416cbabe19c12b90e086f5fc32d7/LICENSE) menetapkan MIT untuk kode, dengan pengecualian eksplisit: art/audio `games/openworld/public/` mempunyai ketentuan tersendiri, karya `assets/lsw/` dan paket Ninja Adventure disebut CC0, sedangkan font Fusion Pixel memakai OFL 1.1. Tidak ada aset tersebut disalin; jika kelak dipilih, catat sumber dan lisensi berkas yang benar.
