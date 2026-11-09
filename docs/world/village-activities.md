# Kegiatan warga Bandar Hujung

Jadwal mengikuti kalender akun tersimpan dengan satu hari permainan selama 36 menit aktif. Snapshot server dipakai bersama oleh jadwal, cahaya dan kebun; interpolasi klien tidak menjadi sumber hadiah, pertumbuhan, inventori atau kemajuan cerita. Heartbeat sekitar lima detik memakai satu penulis Redis, batas jeda 15 detik dan tanpa kemajuan offline.

| Warga              | Kegiatan                                          | Jam kerja   |
| ------------------ | ------------------------------------------------- | ----------- |
| Ki Lurah Wirabhumi | Mengamati pasang                                  | 08.00–17.30 |
| Mbok Ratih         | Menata barang dagangan                            | 07.00–18.00 |
| Mang Ujang         | Memancing di tepi dermaga                         | 06.00–17.30 |
| Kang Tedi          | Memeriksa alat dan sampel air                     | 07.30–17.30 |
| Yu Sari            | Menenun serat                                     | 08.00–17.00 |
| Saras              | Membaca catatan penelitian; muncul mulai siklus 2 | 09.00–17.00 |
| Bu Darmi           | Menyiram di tepi kebun                            | 07.00–17.30 |

Di luar jam kerja warga berjalan menuju titik istirahat di depan rumah. Hujan deras mengalihkan tujuan ke titik berteduh. Perubahan jam tidak memindahkan posisi secara instan: navigasi memakai jalur desa dan commute yang divalidasi terhadap lantai serta footprint penghalang. Bila rute tidak tersedia, warga berhenti dan mencoba kembali; mereka tidak menembus bangunan sebagai jalan pintas.

Pemain yang mendekat menghentikan langkah warga agar percakapan mudah diakses. Buku, dialog, dan kuis menjeda jam serta kegiatan; shader lingkungan tetap dapat bergerak. Mode pengurangan gerak menghentikan perjalanan dan goyangan kegiatan. Posisi interaksi Bu Darmi mengikuti posisinya yang sebenarnya.

Joran, tali, pelampung, alat tenun, penyiram, alat pemeriksa air, barang dagangan dan buku penelitian dirender terpisah. Tiga pilot, Mang Ujang, Bu Darmi dan Yu Sari, kini mempunyai rig tubuh dari potongan sprite, sendi serta IK untuk memancing, menyiram dan menenun. Gerak tangan dan badan tidak hanya bergantung pada alat yang bergoyang. Namun, ketiganya belum merupakan empat arah yang digambar lengkap; tujuh pemeran lain mempertahankan jadwal atau respons idle yang ada dan belum mendapat rig ilustrasi baru. Ini belum merupakan simulasi panen atau jual-beli mandiri NPC, maupun penyimpanan posisi warga antarlogin. Titik istirahat berada di luar pintu rumah. Pos PT tetap memakai kontainer terpisah, sementara bangunan lurah mengikuti arsitektur desa bertingkat.

Sumber jadwal: `packages/shared/src/village.ts`. Navigasi: `NpcActivityNavigation.gd`. Pelaksana jadwal: `HubActor.gd`. Properti kegiatan: `VillageActivity3D.gd`. Pemeriksaan: `scripts/tests/village-activities.gd`, tes API rute dan bangunan, serta pemeriksaan renderer/browser.

## Hubungan dengan rumah dan kegiatan pemain

Hub memakai tata letak 8 dengan delapan bangunan rumah/kedai/kantor, termasuk Griya Sasmita. Rumah warga dan balai menyediakan titik istirahat di luar pintu; interior yang dapat dimainkan saat ini khusus rumah Nala. Interior itu mempunyai dipan, arsip, peti dan rak pameran. Kegiatan kebun pemain menggunakan dua petak dengan aturan server, bukan hasil dari animasi Bu Darmi atau aktivitas NPC.

Menutup kedai yang selesai menyimpan marker kemajuan cerita, lalu tidur Nala menyelesaikannya secara transaksional. Nomor hari kalender tidak disamakan dengan siklus cerita. Izin kebun memerlukan misi `akar` dan tindakan pada papan balai; dialog atau shader hujan tidak membuka izin sendiri.

Status verifikasi Plan 03: 77 tes backend lulus; tiga pilot rig serta rumah telah diperiksa melalui pengujian native/semantik lokal. Regresi browser lokal rumah/kebun serta kedai–pulang–tidur telah lulus tanpa error; hasil CI dan staging mengikuti revisi sumber pada repository. Jangan menafsirkan tabel jadwal sebagai bukti bahwa seluruh sepuluh pemeran sudah memiliki animasi empat arah atau simulasi kehidupan penuh.
