# Peer CPU: ankle kanan pada ascent tengah

Source karakter `b78d14b`, baca-saja/tanpa engine. Bukti actual sebelum perbaikan terrain: `Jalasmara-overnight-character/artifacts/godot/nala-terrain-central-up-anchor-b78d14b/rejected.json` dan `samples.jsonl`. Guard gear-anchor sudah dilewati sebelum ankle kanan ditolak setelah26sampel; itu bukan penerimaan seluruh terrain.

## Selisih actual frame gagal

Posisi badan `(1370,794.617736816406)`→`(1370,793.284423828125)`: delta logis `(0,−1.33331299)`, accepted worldXY **1.182006835938**. Ground actor berada pada tread72 di kedua sampel, sementara support-weighted bodyHeight bergerak57.9390869→59.1210938 secara kontinu.

Ankle kanan berubah dengan delta `(0.135009766,5.617553711,2.055229187)`, panjang **5.983235273934**, melebihi guard5×accepted=**5.910034179688**. Foot/body view tetap north_west; sourceWorld tetap `(1374.243,−1501.572,48)` dan targetWorld tetap `(1373.889,−1449.218,84)`. Left stance/plant tetap; tulang tidak dipanjangkan dan reachValid tetap benar.

Pivot correction kanan berkurang dengan delta `(0.171483994,−0.171483994,−0.168243051)`, panjang0.295159693. Mengurangkan delta correction dari delta ankle menghasilkan delta **planner murni** `(-0.036474228,5.789037704,2.223472238)`, panjang **6.201460852444**. Karena view sepatu tidak berubah, offset ankle sumber konstan dan hilang pada selisih. Jadi decay correction **mengurangi** loncatan, bukan menyebabkannya; mengutak-atik pivot/gear tidak mengatasi kecepatan kurva yang mendasar.

Logical free-foot melewati y816.1527→810.7371: floor di bawahnya48→60 pada entry stair815. Namun XY stair tetap bidang linear; planner sole sudah jauh di atas tread tersebut. Target84 dan source48 tidak berubah. Tidak ditemukan pergantian query/facing/target yang menjelaskan loncatan actual ini.

## Rekonstruksi kurva

LandingDistance D20, rise36 memberikan window0.6/delay0.3. SwingDistance9.939086914063→11.12109375, sehingga u0.496954→0.556055; `advance=(u−.3)/.7` menjadi0.281363351→0.365792411. Cubic `H=3a²−2a³` bertambah **0.110575666**. Dikalikan span worldY target52.354 menghasilkan≈5.789, cocok dengan delta plannerY aktual.

Amplifikasi ascent `1/(1−delay)=1/.7` tidak ada pada bound datar. Horizontal peak untuk arc≈52.3552 adalah≈`1.5W/(20*.7)=5.6095`, sebelum komponen vertikal. Ini sebab yang didukung record: jarak swing48→84 besar dipadatkan oleh kurva ascent, bukan guard yang terlalu kecil.

Eksplorasi numerik CPU100.001nilai u, mempertahankan **target yang sama** dan membawa decay pivot awal≈`(-2.90157,+2.90157,+2.84674)`:

| D | Maks norm turunan plannerXYZ | Dengan correction yang sama |
| --- | --- | --- |
| 20 | 5.61358 | 5.47697 |
| 21 | 5.23915 | 5.10899 |
| 22 | 4.91154 | 4.78724 |
| 23 | 4.78297 | 4.66261 |

Angka eksplorasi itu bukan bound terverifikasi/native pass atau izin memakai22 secara global. Ia mendukung kandidat terbatas: simpan target/tread landing yang dipilih, hitung ulang budget kurva actualXYZ/pivot/clearance, dan retime tanpa memanggil `_forward_point(newD+16)` yang akan mendorong target lebih jauh/lebih tinggi. Reach anatomical, opaque heel/toe, stance dan pause tetap gate. Bila target tetap tidak dapat dipertahankan karena badan maju dan reach gagal, barulah actual tread-target planning diperlukan; jangan menggeser lantai/actor atau melonggarkan guard.

Tidak ada source karakter yang diubah dari peer ini. Seluruh kaki/gait/terrain masih memerlukan actual controller dan native sequence; diagnosis satu frame tidak sama dengan penyelesaian natural walking.

Arahan root sesudah analisis ini: produksi harus memprioritaskan **urutan landing per tread sebenarnya**, bukan mempertahankan lompatan36unit/3riser. Angka fixed-targetD22 di atas hanya diagnosis, bukan arah implementasi yang diterima. Global flat32 tetap. Bukti perlu memperlihatkan urutan landing dari entry60→72→84→96; record lama sudah melewatkan60 saat left mendarat72, sehingga memperbaiki target right saat ini saja tidak cukup. Pada alternasi alami, free-foot bisa berpindah48→72 ketika support terakhir60: dua riser per kaki bukan berarti melewati tread pada urutan kontak global. Definisikan target dari urutan kontak, bukan sekadar actor yang terlanjur maju atau fromHeight kaki ditambah12. Budget kurva XYZ tetap harus diperiksa pada target satu-next-tread tersebut. Character tetap satu penulis implementasi.
