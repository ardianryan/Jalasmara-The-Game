# Peer CPU: durasi langkah pendek dari pangkal kaki aktual

Source ditinjau: character `59f0356`, perubahan satu baris `_begin` pada `NalaFootPlant.gd`. Baca-saja, tanpa edit source karakter atau engine. Bukti gagal sebelumnya: `Jalasmara-overnight-character/artifacts/godot/nala-physical-daily0-raw-handover-cce25ac/rejected.json` dan `samples.jsonl`.

Kasus aktual datar: badan bergerak1,66664684world, ankle kanan8,41175585, melebihi guard5×jarak badan=8,33323419. Facing badan/sepatu tetap EAST, pivot correction0. Tidak ada alasan mengubah guard atau artwork.

Pada awal swing, projection sole terhadap actorGround−0,50318. Pangkal kaki kanan artwork berada **+7,5unit** sepanjang arah gerak, sehingga projection yang sesuai target sebenarnya−8,00318. Target dibuat dari `_base(at,hips[side],right)`, maka pengukuran dari actorGround salah mengurangi jarak swing7,5unit.

Untuk arah dan target datar tetap, tulis panjang fase gerak badan `D`, lead `L=16`, projection terhadap actualbase `p`, dan fungsi cubic `H(u)=3u²−2u³`. Jarak longitudinal swing `W=D+L−p`. Karena max H′=1,5, rasio kecepatan kaki/badan ≤`1,5W/D`. Membatasi komponen ini pada4 (menyisakan ruang dalam guard5) memberi `D≥1,5(L−p)/2,5`, sama dengan rumus existing. Yang salah adalah basis pengukuran p; revisi menghasilkan **D15**, bukan10. D adalah jarak fase badan, bukan timer wall-clock baru.

Rekonstruksi CPU pada record swingDistance4,344710230827→6,011357069016:

| Nilai | D10 lama | D15 dengan actualbase |
| --- | --- | --- |
| W | 34,00318 | 39,00318 |
| Rasio horizontal maksimum | 5,100477 | 3,900318 |
| Batas turunan lift sinus3unit | 0,942478 | 0,628319 |
| Batas norm turunan3D | 5,186823 | 3,950603 |
| Delta rekonstruksi pada interval fase tersebut | 8,411656 | 5,870867 |

Rekonstruksi lama cocok dengan kegagalan actual8,411756 dalam ketelitian angka source yang dibulatkan pada record. Prediksi baru jauh di bawah guard8,333234 untuk interval yang sama, tetapi bukan pengganti rerun controller dengan sejarah fase baru.

Kesimpulan: koreksi actualbase beralasan untuk kegagalan datar ini. Tidak ditemukan counterexample aktual tambahan dari record tersebut. Rumus projection saja tidak membuktikan semua gap transversal, target yang berubah, atau medan. Pada tangga, `advance` mempunyai delay/window dan turunan tambahan1/(1−delay); pergeseran target, perpindahan tubuh dan landing tread tetap harus dinilai dari actual mesh/foot guard. Tidak ada klaim gait alami, kelulusan seluruh tangga, atau enable default dari review ini; pilot tetap terisolasi sampai gate aktualnya lulus.
