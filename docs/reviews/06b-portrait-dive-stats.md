# HUD statistik selam pada layar potret

9 November 2026. Branch `work/06b-hud-portrait-next`, worktree `Jalasmara-06-hud-portrait`, dibuat dari kandidat integrasi `b9701d0`. Perubahan runtime hanya pada `GameHud.gd`; focused regression memakai `scripts/tests/hud-oxygen.gd` yang sudah terdaftar pada runner dunia. Tidak mengubah state/API, renderer dunia atau aset.

## Masalah actual dan perubahan

QA browser menemukan value O2, maximum, kedalaman dan berat tas saling menempel/keluar panel pada potret390×844. Bukti: `Jalasmara-06-integration/artifacts/browser/plan06-layout-f695ff9d-ab78-4f4b-aa38-1519d35e1aee/ocean-night-portrait-joystick-cancelled.png`, observasi dengan nama sama dalam `results.json`. Logical viewport saat itu667×1443, oxygen100/100,depth2m,bag0/12kg, rainy night dan aksi tangga pulang.

Penyebab: font dinaikkan untuk16px fisik, tetapi posisi tetap8/40/80/110 dalam panel140logical, dengan dua kolom tetap. Bar dan ikon juga digambar memakai koordinat lama sehingga layout teks tidak dapat mengatur ruangnya.

Kandidat menambah layout **hanya ketika orientasi fisik potret**. Header Oksigen, angka utama/max dan feedback kehilangan memakai slot terukur; bar mengisi baris sendiri; kedalaman dan tas memakai dua kolom bawah. Ukuran font diukur terhadap rasio canvas dan skala instrument. Tinggi panel mengikuti font, lebar maksimum300px fisik; panel tetap berakhir di atas area joystick/warning. Tank/bar/loss-line mempertahankan artwork kit Bahari yang sama, dengan rect portrait tersendiri. Layout landscape mereset ke posisi/bar/tinggi asli, termasuk sesudah rotasi kembali.

## Verifikasi dan gate

`git diff --check` lulus. Belum menjalankan Godot/browser pada checkpoint source ini karena slot engine milik integrator. Kandidat belum disebut PASS atau rilis.

Focused test mempertahankan kasus35/15threshold, loss/capacity/modal, target sentuh48px dan font16px; menambah actual fixture390 di atas serta feedback−20O2. Semua label harus frame-contained, cukup lebar tanpa ellipsis, tidak saling tumpang tindih, tidak mengenai bar, dan panel tidak mengenai joystick/tombol/aksi. Panel dibatasi301px lebar/170px tinggi fisik. Landscape harus mempertahankan bar rect dan tinggi140logical. Flag opsional `HUD_PORTRAIT_CAPTURE=1` pada native menyimpan `artifacts/godot/hud-portrait/ocean390-stats.png` sebagai fixture komponen, bukan capture game actual.

Integrator berikutnya: import/focused `hud-oxygen.gd` dengan scan log penuh; native fixture untuk visual; lalu export tunggal dan ulang actual browser portrait sebelum rilis. Jika teks tidak muat, perbaiki ukuran/row berdasarkan metrik, jangan mengecilkan font di bawah16px atau melonggarkan assertion.

Tool aktual: Git/worktree, ripgrep dan pembacaan screenshot/source; tanpa generator gambar, upstream baru atau dependensi. Lisensi kit dan sumber tetap seperti sebelumnya. Natural walk dan artwork empat arah tidak dipengaruhi paket ini.
