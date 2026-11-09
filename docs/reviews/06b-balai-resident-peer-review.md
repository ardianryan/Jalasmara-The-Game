# Peer review CPU: Balai dan percakapan Ki Lurah

9 November 2026. Review source `e1bf5a7b2f4882be0ead8b302f5f69cfed20c160` dan `7f33ad7488efcea2e36a86e0a546c0682d1c50a7`. Main blob `3638662b96eea7e12bd0c5f7081ee22b28ceeceb`; HomesteadUI blob `c44363622b1c36e7e2954474e95454b09480a7a6`. Scope hanya baca source. Tidak menjalankan Godot/browser, tidak mengubah berkas runtime milik integrator/alpha. Restart Nala `b93719d` + `5cc90ac` tetap calon paket berikutnya yang belum dijalankan/digabung.

## Temuan: Talk masih aktif selama preflight permit

**P2, `HomesteadUI.gd:365`.** Callback baru memanggil `close()` lalu langsung `host._talk(...)`. `close()` mempunyai `if busy: return` pada209, tetapi nilai kembali tidak diperiksa. Sementara itu `_perform("permit")` mengatur `busy=true` pada413, kemudian dapat menunggu `host.syncing`/`host._sync_surface()` pada425–426 sebelum `_page("Menyimpan kegiatan…")` mengganti panel pada432. Selama await tersebut, panel Balai lama dan tombol Talk masih aktif.

Urutan nyata yang dapat terjadi pada jaringan lambat:

1. Pemain membuka Balai eligible lalu menekan Catat izin.
2. Preflight surface sedang menunggu; `busy=true`, panel awal masih terlihat.
3. Pemain menekan Bicara. `close()` menolak menutup panel karena busy, tetapi callback tetap membuka DialoguePresenter milik Main.
4. Homestead `panel/is_open` dan modal dialog Main kini hidup bersamaan. Hasil permit sesudah await dapat mengganti halaman Homestead di tengah percakapan. Ini bukan kehilangan permit pada server, tetapi lifecycle/focus modal bertumpuk.

Perbaikan terbatas yang disarankan kepada pemilik: `if busy: return` pada awal callback Talk, sebelum close dan `_talk`, lalu pertahankan guard close yang sudah ada. Repro focused dapat menahan preflight await, menekan Talk dan memastikan jumlah `_talk` tetap0, panel/is_open tidak berubah, busy tetaptrue, serta transaksi permit tetap dapat selesai. Menyetel busytrue lalu emit pressed juga mereproduksi guard callback secara deterministik, tetapi tidak menggantikan pemeriksaan preflight async. Temuan ini dikirim langsung ke integrator sebelum laporan disimpan. Belum ada klaim runtime PASS untuk kasus tersebut.

## Bagian yang tidak menunjukkan regresi baru pada inspeksi ini

- `_interact` dan `_balai` memakai `service_resident` yang sama, sehingga pemenang nearest antara resident dan board membuka layanan yang sama saat syarat terpenuhi.
- Service dibatasi darat, Nala valid dan board tersedia. Nala harus dalam100 unit board, serta resident aktual dalam80 unit dari Nala dan board. Jauh dari board, resident tetap memakai percakapan lama; board tanpa resident tetap menyediakan halaman izin.
- Metadata day/evening berasal dari `_ensure_residents`, yang menetapkan keduanya. Service tidak menciptakan dialog tambahan atau mengubah jadwal/posisi warga.
- Eligible `akar`, permit sudah didapat, starter seeds, revision/idempotency dan validasi `/homestead/action` tidak berubah. Server masih memeriksa lokasi board dan misi. Membaca percakapan tidak memanggil grant permit.
- Pada callback Talk normal yang tidak busy, panel Homestead dilepas sinkron, Main `_talk` menetapkan modal/frozen lagi tanpa await, presenter memfokuskan tombol Lanjut, dan Main `_process` memperbarui clock pause dari modal/host/challenge. Selesai dialog melalui `_next_line`→`_close` mengembalikan HUD dan gerak. Untuk izin setelah bicara pemain berinteraksi lagi; fungsi izin tidak hilang.
- Tombol Talk dibangun pertama. Helper `_button` dan `open_for` memfokuskan tombol pertama; tombol permit dan Kembali tetap ada pada urutan Tab. Pembuktian input/touch/focus sebenarnya tetap milik fixture alpha/native, bukan hasil review CPU ini.

Laporan ini tidak menilai layout, performa perangkat, akses line-of-sight baru, atau seluruh flow Homestead di luar perubahan tersebut. Tool aktual: pembacaan source dengan `rg`/`sed`/`nl`, Git blob pin dan `apply_patch` untuk laporan saja. Tidak ada aset/dependensi/lisensi baru.
