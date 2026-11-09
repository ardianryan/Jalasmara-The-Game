# Source warga perluasan desa

Enam identitas original disusun sesuai urutan `npc_direktur_cakrawala`, Bagas, Kinasih, Danu, Gito dan Cempaka. [Provenance](provenance.json) membedakan generasi awal dari produksi potongan. Gambar awal ditinjau; model voxel sebelumnya ditolak karena tidak cocok dengan gaya cast existing.

Potongan bersih berada di `cutouts/`, masih aset produksi dan belum dipasang ke renderer. Alpha biner menghilangkan halo berwarna di luar tubuh; warna dipadatkan tanpa dithering untuk menjaga detail kecil. Kepala direktur tetap utuh dalam batas sumber; script tidak menggambar ulang atau melengkapi piksel yang tidak ada.

Reproduksi dengan Pillow11.3.0, memakai direktori keluaran yang belum ada:

```sh
python3 tools/npc-rig/village_expansion.py \
  --source assets/source-2d/village-expansion-v1/source.png \
  --out .runtime/resident-art-reproduction-new
```

PNG49.540byte, SHA256 `6dc5fbb107327c97205660817cf245661bea838d50be606735fe2c6a247d413e`. Dua produksi independen pada versi yang sama menghasilkan PNG dan JSON identik. Enam sel128piksel tinggi mempunyai alpha0/255, margin transparan dan ID unik; ketajaman masih perlu dinilai pada skala gameplay bersama Nala setelah rig dipasang.

Belum ada arah belakang/samping asli, langkah natural, animasi alat atau bukti pergerakan di sini. Source satu arah tidak boleh dilaporkan sebagai delapan arah hanya dengan mirror.
