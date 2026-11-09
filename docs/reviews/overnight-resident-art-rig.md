# Rig original untuk enam warga: kandidat integrasi

Branch `work/overnight-resident-art`, worktree `Jalasmara-overnight-resident-art`, basis `ead46b5`. Helper ini belum dipasang ke LandActors atau dirilis. Root menilai gambar dan menggabungkan adapter. Lane tidak mengubah LandActors3D, HubActor, Player, atlas portrait bersama, layout, collider atau state server.

## Perubahan dan sumber

`ResidentArtRig3D.gd` memakai kepala, torso, lengan, tangan, tungkai dan telapak dari enam cutout original yang ditinjau root (`e0a128b`). Sumber adalah `assets/source-2d/village-expansion-v1/cutouts/residents.png`, SHA256 `6dc5fbb107327c97205660817cf245661bea838d50be606735fe2c6a247d413e`. Provenance generasi serta hak aset tetap pada `assets/source-2d/village-expansion-v1/provenance.json` dan LICENSE proyek. Tidak memakai Sprite AI, gambar moodboard atau aset upstream tambahan.

Generator `tools/npc-rig/resident_parts.py` hanya membagi pixel original. Overlap kecil di joint menyalin pixel pada lokasi sumber yang sama. Bagian kaki yang tertutup baju tidak diberi kulit rekaan. Dua produksi independen merekonstruksi alpha dan setiap RGBA opaque asli persis 1:1. Atlas 84 bagian SHA256 `34c0612cbdb2212d6deb31dac2ac947c23ae1221a2020f79020d4c7374c81788`; Pillow 11.3.0, satu tes CPU rekonstruksi/determinisme/palm-opaque PASS. Tidak resize, recolor, mirror, dither atau membuat arah belakang baru.

Setiap warga memakai satu MultiMesh berisi 14 atlas quad nearest/cutout, sehingga enam badan memerlukan enam body drawcall, bukan 84 Sprite3D. Held props dibuat sebagai geometri native terpisah di opaque palm socket: briefcase, teleskop, toples keong, ember, ketapel dan centong. Properti ini masih sederhana; belum merupakan paket ikon/peralatan terperinci.

Tulang mempertahankan panjang sumber; endpoint quad tungkai diukur dalam tiga dimensi terhadap hip/knee/ankle. Sole mengikuti `ground_point` dan helper Ujang yang sudah dipakai runtime. Penambahan `stepScale` pada `UjangFootPlant.gd` hanya memparameterisasi stride/lift; default 25/3.4 serta algoritme turn/contact tidak diubah. Anak memakai skala langkah sesuai bodyScale. `workFacing.point/height` memakai Camera3D dan target dunia aktual, termasuk Danu menuju pen pada [275,990], z=-11. Artwork tetap satu front-three-quarter, tanpa klaim empat/delapan arah atau mirror palsu.

## Hasil pengujian sendiri

Godot 4.7.2 stable ed1daf0bf, native Compatibility Apple M2. Seluruh import/native dilakukan dalam slot root, sudah RELEASE; tidak ada proses Godot lane tersisa.

- Cold import dua tahap dan import atlas revisi PASS, scan penuh tanpa SCRIPT ERROR/ERROR.
- CPU `python3 tools/npc-rig/test_resident_parts.py` PASS: determinisme, 84 bagian, semua pixel original, palm socket opaque.
- Headless dan native final **576 pose di central court datar** normal/reduced PASS: actual submitted transform dan native MultiMesh readback, panjang tulang 3D, endpoint mesh joint, alpha sole ke support, palm ke prop, turn/stop dan pause. Pelvis max **4.20688676 world**. Log `.runtime/resident-sized-headless.log` dan `.runtime/resident-sized-native.log`.
- Regresi default Ujang **1242 sampel PASS** termasuk 168 sharp-turn: alpha-sole drift max 0.0003491, knee error 0.0002730, pelvis 6.98887, west grip 0.0153571. Log `.runtime/ujang-default.log`. Tidak mengulang tes ini sesudah perubahan baseline warga karena helper Ujang tidak diubah lagi.
- Guard framebuffer shown/hidden seluruh enam warga PASS; seluruh sudut quad masuk frame. Enam pair shots kemudian mengisolasi badan satu per satu pada lantai asli terbuka, zoom dan kamera yang sama dengan Nala. Tidak menyembunyikan/menghapus pohon produksi.

Frame final ada di `artifacts/godot/resident-art-rig-sized/`: `pair-<canonicalID>.png`, `danu-actual-pen-work.png`, `measured-alpha-heights.json`, `visibility.json`, `results.json`. Lane membuka seluruh enam pair shots. Semua tubuh utuh dan identitas original tampak, ukuran anak masuk akal di samping Nala. Root harus tetap membuka gambar sebelum wire.

### Ukuran alpha yang benar-benar terlihat

Semua cutout asli memiliki alpha setinggi 112px. Helper menormalkan ke baseline `CharacterVisual.LAND_SIZE=100`, menerapkan bodyScale tepat sekali. Ujang legacy sudah bermetadata bodyHeight100 dan tidak diubah. Fixture Nala memakai `set_locomotion(Vector2.ZERO,0)` seperti runtime, bukan fallback legacy 99.04 world. Difference framebuffer body-mesh shown/hidden menghasilkan:

| Warga | BodyScale | Alpha pixel native | Alpha world | Rasio terhadap Nala |
|---|---:|---:|---:|---:|
| Nala directional | 1 | 258 | 86 | 1 |
| Direktur | 1 | 297 | 99 | 1.151 |
| Bagas | .68 | 201 | 67 | .779 |
| Kinasih | .64 | 192 | 64 | .744 |
| Danu | .66 | 195 | 65 | .756 |
| Gito | .70 | 207 | 69 | .802 |
| Cempaka | .62 | 183 | 61 | .709 |

Direktur lebih tinggi dari Nala sesuai baseline dewasa legacy; tidak mengubah ukuran Nala/Ujang untuk menyamakan hasil.

## Kegagalan yang dipertahankan

1. Sole awal kehilangan kedalaman kontak karena depth quad tetap; assertion menolak. Offset depth sekarang mengikuti sole lokal asli.
2. Native pertama seluruhnya latar #081f29 karena fixture menghentikan LandWorld sebelum `_process` pertama: display nol dan SubViewport UPDATE_DISABLED. PNG kosong di `artifacts/godot/resident-art-rig/` tetap dipertahankan. Numeric readback 288 saat itu tidak menjadi bukti visual.
3. Audit menemukan uji tulang awal hanya 2D meskipun kaki di kedalaman 3D. Diganti IK/quad 3D serta endpoint mesh aktual; guard panjang tidak dilemahkan.
4. Frame iterasi `resident-art-rig-3d/` berisi dunia tetapi baris logical-X keluar layar; strict visibility menolak. Iterasi `resident-art-rig-framed/` lolos guard namun pohon menutupi Nala/sebagian anak. Kedua folder tidak dipakai untuk mengklaim enam identitas jelas.
5. Baseline 70 world membuat Danu 46.2 world versus Nala fallback 99.04, rasio .466. Root menolak ukuran tersebut. Baseline100 dan pair reference directional Nala menghasilkan ukuran terukur di atas.

## Batas dan integrasi berikutnya

Belum ada adapter runtime, full suite gabungan, browser, FPS perangkat Windows/S23, rekaman gait yang ditinjau, endpoint mesh setiap scaled-child commute di tangga, atau artwork belakang/samping baru. Still image dan numeric pose tidak membuktikan natural walking lengkap. Runtime cutout tidak mengubah atlas portrait yang dimiliki root. Props sederhana dan single-view tetap batas pekerjaan ini.

Integrator dapat memilih helper baru di `LandActors3D._body_rig` berdasarkan resident_id yang terdapat pada rigs.json, sambil mempertahankan path tiga rig lama serta `_sprite` shadow/readable tint. `configure(renderer, actor) -> bool`, `update_pose(tint)`, dan `pose_snapshot()` mengikuti kontrak lama. Reproduksi focused: `Godot --headless --path client-godot --script ../scripts/tests/resident-art-rig.gd`. Native memakai script sama dengan `--rendering-method gl_compatibility --resolution 1440x810 -- --output=res://../artifacts/godot/resident-art-rig-sized`. Root perlu mendaftarkan focused ke runner pada saat benar-benar mengintegrasikan, lalu menjalankan full world dan review runtime bersama UI.
