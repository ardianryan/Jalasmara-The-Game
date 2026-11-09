# Kegiatan warga Bandar Hujung

Jadwal memakai jam visual 36 menit nyata per 24 jam permainan. Jam ini mengatur aktivitas kosmetik; hadiah, hasil kebun, inventori, dan kemajuan cerita tetap ditentukan server.

| Warga | Kegiatan | Jam kerja |
| --- | --- | --- |
| Ki Lurah Wirabhumi | Mengamati pasang | 08.00–17.30 |
| Mbok Ratih | Menata barang dagangan | 07.00–18.00 |
| Mang Ujang | Memancing di tepi dermaga | 06.00–17.30 |
| Kang Tedi | Memeriksa alat dan sampel air | 07.30–17.30 |
| Yu Sari | Menenun serat | 08.00–17.00 |
| Saras | Membaca catatan penelitian; muncul mulai siklus 2 | 09.00–17.00 |
| Bu Darmi | Menyiram di tepi kebun | 07.00–17.30 |

Di luar jam kerja warga berjalan menuju titik istirahat di depan rumah. Hujan deras mengalihkan tujuan ke titik berteduh. Perubahan jam tidak memindahkan posisi secara instan: navigasi memakai jalur desa dan commute yang divalidasi terhadap lantai serta footprint penghalang. Bila rute tidak tersedia, warga berhenti dan mencoba kembali; mereka tidak menembus bangunan sebagai jalan pintas.

Pemain yang mendekat menghentikan langkah warga agar percakapan mudah diakses. Buku, dialog, dan kuis menjeda jam serta kegiatan; shader lingkungan tetap dapat bergerak. Mode pengurangan gerak menghentikan perjalanan dan goyangan kegiatan. Posisi interaksi Bu Darmi mengikuti posisinya yang sebenarnya.

Joran, tali, pelampung, alat tenun, penyiram, alat pemeriksa air, barang dagangan, dan buku penelitian merupakan mesh terpisah dari sprite warga. Ini belum merupakan simulasi panen, jual-beli NPC, interior rumah, atau penyimpanan posisi warga antarlogin. Titik istirahat berada di luar pintu rumah. Pos PT tetap memakai kontainer terpisah, sementara bangunan lurah mengikuti arsitektur desa bertingkat.

Sumber jadwal: `packages/shared/src/village.ts`. Navigasi: `NpcActivityNavigation.gd`. Pelaksana jadwal: `HubActor.gd`. Properti kegiatan: `VillageActivity3D.gd`. Pemeriksaan: `scripts/tests/village-activities.gd`, tes API rute dan bangunan, serta pemeriksaan renderer/browser.
