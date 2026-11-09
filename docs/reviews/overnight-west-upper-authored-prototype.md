# Nala WEST daily: satu proposal upper-body

Kandidat authoring offline terpisah, **bukan aset runtime dan belum diterima secara visual oleh integrator**. Permintaan terbaru mengizinkan satu proposal piksel baru dari palet/aset original; ini memperluas audit coverage lama yang belum mengizinkan hidden fill. Tidak ada image API, moodboard, voxel, identitas baru, mirror, Godot atau browser. Source atlas asli tetap SHA `342724d1724490279cd0f65c0340c5b35cdf366ecc36a99af716c51f751b8fc3`.

`tools/player-gait/prototype_west_upper.py` + `west-upper-prototype.json` membuat hanya dua upper texture128×76, frame0/4 arah WEST daily. Sleeve/upper arm, forearm dan palm dipotong menjadi enam layer source terpisah, dengan row-runs dan pixel ownership eksklusif. Near/far memakai hierarchical rigid joint transforms tersendiri tanpa scale/interpolasi warna. Palms tetap dari potongan original, bukan kepalan generik baru. Near wrist berpindah51→71.838 pada sumbuX, far wrist81→58.112, sehingga kedua lengan sekarang mempunyai extreme berlawanan. Near/far adalah label depth view; belum dipetakan ke anatomical leg/contact runtime.

## Gap asli dan pixels authored

Tidak ada clean original torso di bawah near-arm yang selalu maju atau far shoulder lengkap. Proposal menandai **136 posisi repair torso** sebagai authored, memakai donor dari patch original WEST0 `[69,47,73,62]` yang sudah diverifikasi; koordinat donor tercatat per pixel. Far sleeve/hidden upper segment serta joint seals juga authored dari palet original. Tidak menyebutnya pemulihan texel tersembunyi atau source limb lengkap.

Mask provenance: abu-abu original torso/head, cyan near cutouts, emas far cutouts, magenta authored repair/cap/seal. Yang terlihat authored berjumlah21pixels pada pose0 dan88 pada pose4. Pose0 berbeda21pixels dari original, jadi **bukan** klaim rest recomposition identik. Pose4 berbeda509pixels terhadap base0 karena pose baru. Semua warna opaque tetap anggota palet source0; kepala sebelum y43 byte-identik. Bagian bawah contact sheet memakai frame kaki original0/4 hanya untuk konteks, bukan hasil koreksi kaki.

## Artefak dan tinjauan sendiri

Output final lokal: `artifacts/player-gait/west-upper-daily-review/`, worktree `Jalasmara-overnight-resident-art`. Lihat **`west-upper-before-after.png`**,36.766byte, SHA `2345cbfbece08be96b2cc4ae0a84e6c177cb0e6eae382bbfbc9e71cbbab46635`; juga tersedia torso plate, mask repair, enam cutout, dua texture/provenance mask dan manifest berisi source/spec/script hashes serta transforms. Script menolak output existing dan direktori runtime/app.

Lane membaca contact sheet original dan hasil via CPU image inspection. Identitas kepala/pakaian serta opposition dua extreme terbaca. V0 masih menyisakan beberapa old-arm edgepixels dan bahu kasar; bukti v0 dipertahankan, mask diperbaiki sekali menjadi v1. Output final mempunyai contact sheet byte-identik dengan v1 yang ditinjau. Bahu/rotasi nearest masih perlu art review dan dapat membutuhkan redraw lebih baik; jangan menyebut kedua endpoint ini animasi berjalan natural. Tidak dibuat64variant atau empat/eight arah baru. PNG kandidat tetap di artifacts untuk review, belum masuk galeri accepted atau resource game.

**6/6 uji CPU PASS:** source checksum tidak berubah; enam cutout pixel-exact/exclusive dengan provenance; authored repair hanya donor palette yang dibatasi; kepala/palet tetap; transform rigid dan near/far berlawanan; fresh-output/runtime-directory guards. Ini tidak membuktikan mask anatomi benar atau gerak native.

```sh
python3 tools/player-gait/prototype_west_upper.py --output artifacts/player-gait/west-upper-fresh
python3 -m unittest discover -s tools/player-gait -p test_west_upper_prototype.py -v
```

Kode/arrangement baru original proyek. Derived art mempertahankan ketentuan original-art proyek; Pillow offline memakai notice MIT-CMU existing `tools/player-gait/LICENSE-Pillow.txt`. Berikutnya tinjau gambar kecil ini dahulu, lalu koreksi sleeve seams/hidden anatomy jika diperlukan, tentukan near/far→leg mapping dan fase accepted displacement, baru susun interval/integrasi opt-in serta native proof. Tidak ada default adoption pada paket ini.

## Iterasi delapan frame WEST daily, CPU saja

Sesudah integrator melihat `4c49923`, dua endpoint boleh dilanjutkan menjadi **satu loop delapan frame WEST daily**, dengan koreksi sleeve/occlusion lebih dahulu. Bukti endpoint di atas tetap historis; angka21/88 dan6tes tidak menggambarkan iterasi baru.

Tonjolan di bahu belakang berasal dari **cap far sleeve authored yang ikut diputar**, sehingga muncul di luar shirt plate sebagai lengan baju kedua. Cap itu sekarang dihilangkan; extension skin yang tersembunyi tetap terpisah. Near sleeve source mempunyai outline/cuff gelap yang ikut berpindah dan memotong sambungan. Seluruh source part `near/upper` sekarang dilepas dari komposisi, diganti satu sleeve kompak yang **baru diauthor** dari empat warna palet original. Cutout original tersebut masih diekspor untuk audit, tetapi manifest mencatatnya sebagai `omittedSourceParts`. Semua source arm pixels sudah dihapus dari torso plate sebelum repair; tidak menumpuk dua sleeve. Forearm/palm near dan ketiga potongan far tetap cutout source. Magenta mencakup repair torso, sleeve baru, extension dan joint seal; bukan klaim original shirt yang tersembunyi ditemukan kembali.

Urutan depth sengaja tetap far arm → repaired shirt → near arm. Palm far juga berada **di belakang** shirt, bukan ditempel di atas depan badan. Texel palm yang tertutup shirt pada frame0..7: **0,28,41,26,13,26,41,28**. Tes membuktikan tidak ada texel provenance far yang terlihat di dalam alpha shirt. Tangan yang muncul di tepi depan pada frame3/4/5 merupakan bagian yang melewati siluet shirt; pemilihan depth ini masih perlu review native saat arm dipasang, termasuk saat alat dipegang.

Setiap sudut joint memakai bobot `(1-cos(2πf/8))/2`, frame0/4 tetap endpoint, frame8 identik dengan0 secara analitik. Shoulder selalu tetap; elbow/wrist mengikuti dua rigid joint tanpa skala. Jarak wrist antarframe, termasuk7→0, near: **3.188,7.740,7.849,3.297,3.297,7.849,7.740,3.188px**; far: **3.872,9.256,9.243,3.859,3.859,9.243,9.256,3.872px**. Segmen penutup tidak mendapat perpindahan khusus, dan turunan bobot sama-sama nol di0/8. Ini smoothness geometris untuk proposal, **bukan pengukuran cadence atau kecepatan tangan dalam gameplay**. Kepala y<43 byte-identik terhadap WEST0 dan torso plate/head anchor konstan di semua frame. Bagian bawah comparison strip memakai kaki original frame yang sama sebagai konteks saja.

### Provenance anatomi dan batas fase

Koordinasi dengan lane karakter memakai `tools/player-gait/annotate_lower_body.py` pada source `ff5a2c21effa3ce81e859eefb17ec95518657f2d` (SHA `aa2870ff8a4bf5abab87bb98c58ae2762fb19ed2ba99c3975ebc8fc8aa855910`) dan metadata daily SHA `f46253f21b32fc5e4ff027c4dce5e36c9be317ade6feffb1a7174fd1774b8d48`. Urutan SOUTH→SW→WEST→NW→N memberi hipX left71→68→61→59→58 dan right58→58→64→70→71. Dengan konvensi anatomical FRONT yang sudah dipakai, **intended WEST near=left/far=right**, bukan inferensi dari screenX saja.

Kedua kaki WEST tetap `occludedReuse=true`; generated profile tidak mempunyai penanda pakaian asimetris yang membuktikan limb identity secara mandiri. Karena itu mapping dicatat sebagai **konvensi anotasi yang dimaksud**, belum contralateral contact phase yang diterima. Fase terhadap actual accepted displacement/foot plant belum dipasang atau diukur. Tidak ada perubahan pada source annotation karakter, atlas original, runtime, gait helper atau default.

### Artefak final dan verifikasi

Lokasi absolut: `/Users/ardianryan/Documents/Jalasmara-overnight-resident-art/artifacts/player-gait/west-upper-daily-loop-review/`.

- `west-upper-before-after.png`: delapan frame × original/proposal/provenance,109.550byte; SHA `0b2989f79a7e7ba7a75a33fdb0811fb9b6bb30fa91ddbd62e111b6391bc54d63`.
- `west-upper-eight-frame-textures.png`: hanya upper textures1024×76,9.154byte; SHA `826306d52bbd3d75705f5872686df6844d5b2a1d8996227ee5530a1f714bb6f5`.
- `west-upper-eight-frame-strip.png`: konteks kaki original,24.358byte; SHA `bb1f9fc6ffe9356b9cdc27eb4a7928c4cbdaa07e234f17bf6a7e2f72674958a8`.

CPU image inspection membaca seluruh delapan frame. Tonjolan cap hilang, near sleeve lebih bersih dan dua extreme tetap berbeda. Source/authoring provenance tetap terlihat. Visible authored pixels perframe:91,90,116,134,131,134,116,90. **9/9 tes CPU PASS**, termasuk delapan frame/head/palet, source pixel ownership, repair donor, rigid transforms, cyclic joint closure, provenance anatomi, old sleeve omission/far hand occlusion, dan output guard. `py_compile`/`git diff --check` juga PASS. Percobaan tes pertama masih mengharapkan dua endpoint dan gagal; assertion diperbarui ke delapan frame yang diminta, bukan mengendurkan aturan pixel/head/palette.

PNG tetap artefak review yang tidak dikirim ke resource game. Belum ada review native, walking contact phase, delapan arah, explorer outfit atau props. Integrator belum menerima loop ini untuk runtime; tidak boleh menggantikannya sebagai gait final.

Integrator memeriksa final comparison delapan frame serta mengulang9tes CPU, semuanya PASS. Satu salinan PNG109.550byte yang sama kini dikurasi dalam [galeri proposal](../visual/README.md#west-arm-authoring-proposal-not-installed), tanpa crop/recolor/recompression. Gambar jelas diberi status belum dipasang; kaki atlas konteks bukan lower-body pilot. Root tidak menerima contactphase/anatomicalside dari gambar tersebut. Tidak ada PNG baru pada resource runtime atau perubahan lisensi aset.
