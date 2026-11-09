# Peer CPU: lintasan kaki saat masuk ramp

Audit read-only atas run character `nala-terrain-full16-next-tread-d498b6e` dan pembanding aktual `nala-terrain-dock-up-allcuts-19e3989`. Tidak mengubah runtime, guard, planner, atau aset; tidak menjalankan engine. Script mandiri `tools/player-gait/audit_ramp_curve.py` membaca WORLD dengan hash yang cocok (`28455e6f7ec053d8e090457cae6e747d848aa3fd994e797e32608a0710dd5743`) dan merekonstruksi kurva dari from/to/phase/pivot yang tercatat.

## Kegagalan awal

Pasangan actor `(1120,1190.43212890625)` → `(1120,1189.47619628906)` menerima perpindahan XY dunia **1.1142578125**. Guard ankle tetap **5.5712890625**; delta ankle kiri aktual **6.3461852848**, sehingga gagal. Target berubah dari Z23.64943 ke Z28.06226, berjarak XYZ **6.0344448468**. Rekonstruksi CPU kurva chord lama cocok dengan sole tercatat dalam **0.0003595 / 0.0010024** unit (string Vector dibulatkan); delta model **6.3464765662** cocok dengan kegagalan nyata.

Lintasan dari origin kaki melewati batas ramp. Pada target sebelum/sesudah, jumlah arc XYZ dengan cut semua connector adalah **68.8144396 / 74.8333747**, dibanding chord XYZ lama **63.1478188 / 68.6521254**. Arc XY juga berbeda sedikit karena lintasan kaki diagonal. Untuk jalur vertikal monoton, total XY chord dapat sama dengan jumlah span XY; inverse jarak→parameter tetap salah jika memakai satu skala untuk lantai dan ramp. Dua uji CPU analitik membuktikan perbedaan ini tanpa menjalankan planner gait.

Eksperimen CPU yang hanya menambahkan cut tetapi mempertahankan **dua target lama yang tercatat** masih menghasilkan delta **7.0421577456**; ini kondisi terbatas, bukan prediksi hasil runtime dengan target yang dihitung ulang. Retained-target memberi 2.8488272 sebagai diagnosis saja; tidak menjadi alasan memasang freeze atau melemahkan guard.

## Bukti aktual sesudah cut semua connector

Character kemudian menyediakan run aktual `19e3989`, yang dibaca ulang secara independen. Actor pada pasangan posisi yang sama berada di frame 30/31. Target sebelum kini Z**27.85646**, sesudah Z**28.06226**. Delta ankle aktual **3.2880467815 ≤ 5.5712890625**, jadi crossing lama **lolos tanpa freeze**. Rekonstruksi kurva semua-cut cocok dengan sole baru dalam **0.0005558 / 0.0005849** unit. Hasil aktual ini menggantikan kekhawatiran bersyarat dari eksperimen dua target lama.

Model forward scalar memakai basis kamera yang disimpulkan `(.707,-.707,0)`. Target sesudah cocok; target sebelum model cocok dengan hasil baru, tetapi tidak mereproduksi target sebelum lama. Penyebab internal perbedaan target lama itu belum dibuktikan dari snapshot (base/heading aktual tidak direkam). Jangan menyebut model forward lama tervalidasi atau mengarang mekanisme tambahan.

Run baru tetap **gagal pada pemeriksaan berikutnya**: `Stair body baseline jumps across a riser dock_gangway/false/false travel`. Ini bukan kelulusan ramp lengkap, 16 kasus, native, atau natural walking. Metadata dan kegagalan asli tetap dipertahankan. Laju ramp vertikal per XY kontinu memang berbeda dari lantai: tinggi48 / panjang XY44.77294 ≈1.07212; penanganannya dimiliki character dan tidak diubah di paket peer ini.

Reproduksi CPU:

```sh
python3 -m unittest discover -s tools/player-gait -p 'test_*ramp*.py' -v
python3 tools/player-gait/audit_ramp_curve.py \
  --world /path/to/character/.runtime/world-map.json \
  --run /path/to/character/artifacts/godot/nala-terrain-full16-next-tread-d498b6e \
  --comparison-run /path/to/character/artifacts/godot/nala-terrain-dock-up-allcuts-19e3989 \
  --output /tmp/ramp-curve-fresh.json
```

**2/2 uji analitik PASS**; pembacaan kedua run berhasil. Output lokal `.runtime/ramp-curve-d498-and-19e.json` tidak menggantikan artefak asli. Kode original Python standar, tanpa dependensi baru.
