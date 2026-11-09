# Peer CPU: ankle ramp pertama pada d8bf012

Audit read-only atas `Jalasmara-overnight-character/artifacts/godot/nala-terrain-dock-up-rigid-plane-d8bf012/{samples.jsonl,rejected.json,source.json}`. Runtime yang direkam memuat NalaFootPlant SHA`f03156f7be355b71c31aef0fa0f32de9a517ac00c7d6424974e072549e2c90ae` dan LowerBody SHA`677d7165bcdfcea4a5a9bdc9f306f2339e131c5211924185b323e151bd1de6e2`. Tidak mengubah source/guard dan tidak menjalankan engine.

## Penyebab terisolasi

Guard4.9 pada `_terrain_duration` **tidak berlaku pada swing ramp ini**. `_begin` hanya memanggil fungsi tersebut di cabang `_next_tread` nonempty; planner next-tread hanya memilih stairs. Rekaman ramp memiliki `fixedTreadTarget:false`, tanpa `treadPlan`, dan memakai landingDistance20 dari handover lama. Jadi ini bukan kegagalan bound4.9 yang telah diterapkan.

Frame43 actor `(1120,1170.85620117188)` menuju rejected `(1120,1169.25622558594)`. AcceptedXY **1.10205078125**, phaseDistance **5.055419921875→6.157470703125**, D20. RIGHT tetap northwest dengan quaternion/supportAxis sama, angleRemaining0; fromWorldZ0 dan toWorldZ43.14186→43.14195. Logical kaki tetap `(1124.243,1196.947)`.

Rumus kurva asli memberi `u=.25277099609375→.30787353515625`, window=`clamp(R/(3D),.25,.65)=.65`, delay=.325. Kedua u masih sebelum delay, sehingga advance horizontal tepat0. Semua gerak raw saat itu adalah lift vertikal cubic plus toe sine:

```text
Z(s) = R*h(s/(D*w)) + 3*sin(pi*s/D), h(e)=e²(3−2e)
dZ/ds = R*6e(1−e)/(D*w) + 3*pi*cos(pi*u)/D
```

Dari nilai target masing-masing record, rawZ **16.6380437332→22.3373922651**, delta **5.6993485319**, kecepatan rata-rata **5.1715843125**. Bahkan dengan R tetap43.14195, puncak derivative adalah **5.2323741880** pada u**.3119554507** (phase6.2391090), masih sebelum delay horizontal. Retarget hanya9e−5 pada Z dan tidak menjelaskan pelanggaran ini.

Kompensasi pivot meluruh dengan delta `(+.2439174652,−.2054874897,−.1927464008)`. Menambahkan delta itu pada raw lift menghasilkan delta ankle prediksi `(.2439174652,−.2054874897,5.5066021310)`, norm **5.5158306598**. Rekaman aktual norm **5.5158391797**, selisih hanya **0.00000852**. Aktual/accepted=**5.00506807**, melampaui guard5×accepted **5.51025390625** bahkan setelah tambahan0.003. Peluruhan kompensasi justru mengurangi komponen lift; quaternion, pergantian view, interpolasi arc horizontal, atau perpindahan target besar bukan penyebab pasangan ini.

## Implikasi yang dibatasi

Kurva ramp yang memakai D20 perlu bound lintasan aktualnya; tidak sah mengandalkan label4.9 dari cabang stairs yang tidak dipanggil. Bound kurva-only tetap belum mencakup retarget berikutnya, perubahan orientasi, peluruhan/reset kompensasi, support kaki pada batas ramp, atau settle. Tidak menetapkan konstanta durasi baru, membekukan target, atau menaikkan guard dari temuan ini. Character tetap pemilik perbaikannya dan sedang mengerjakan support/settle terpisah.

Ini rekonstruksi CPU kegagalan aktual lama, bukan runtime kandidat baru, penerimaan ramp/16 kasus, native, atau natural walking. Angka dihitung langsung dari JSON dengan Python standar dan persamaan source; artefak asli dipertahankan.
