# Inventaris payload ekspor ketiga

Pemeriksaan read-only memakai `scripts/performance/pck-inventory.py` pada PCK Mac `73d45630ab69033ac36a64740ecc73ecdb7363c9f99805222b6a9237dcb2d18b`, 64.494.656 byte. Semua **691 payload** cocok MD5 tabel PCK; hash seluruh paket juga dipatok. Tidak ada ekstraksi, penghapusan aset atau perubahan preset export. [JSON lengkap](overnight-export3-payload-inventory.json).

| Kelompok | Berkas | Byte tersimpan |
| --- | ---: | ---: |
| Tekstur `.ctex` | 146 | 44.007.882 |
| Musik `.mp3str` | 4 | 16.187.080 |
| Efek suara `.sample` | 61 | 1.931.147 |
| Font `.fontdata` | 2 | 1.242.284 |
| Skrip compiled `.gdc` | 85 | 630.701 |
| JSON | 53 | 288.823 |

Payload 64.425.577 byte dan header/direktori/alignment 69.079 byte. Kelebihan byte identik teoretis tetap351.494byte; ini belum membuktikan referensinya aman dialihkan atau resource tidak dipakai. Paket baru bertambah3.336byte dibanding PCK1315 sebelumnya (64.491.320byte). Aset besar tetap musik dan ilustrasi/atlas yang telah dicatat pada [audit sebelumnya](06p-payload-audit.md).

Context transfer source+export baru69.191.680byte menggantikan cara transfer repo sekitar265MB dengan reuse WASM yang hash/ukurannya identik. Penghematan context pengembangan ini **tidak mengurangi unduhan game64,5MB**, ukuran WASM, penggunaan VRAM atau biaya frame. Jangan menggunakannya sebagai klaim peningkatan FPS Samsung/Windows. Penyaringan `all_resources`, penghapusan fallback musik dan pengurangan resolusi tetap memerlukan audit referensi serta regresi visual tersendiri.

Tool existing original proyek/Python mengikuti format Godot4.7.2 yang sudah dirujuk audit sebelumnya; tidak ada dependency atau lisensi baru. Pemeriksaan ini berjalan CPU bersamaan smoke browser publik tanpa menjalankan engine kedua.
