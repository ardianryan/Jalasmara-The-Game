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
