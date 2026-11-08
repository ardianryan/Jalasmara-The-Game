# Berkontribusi

Gunakan merge request GitLab. GitHub menerima mirror sumber dan laporan CI; build dan pemindaian dijalankan di GitLab.

1. Buat branch dari `main` dengan nama yang menjelaskan perubahan.
2. Jelaskan perilaku yang berubah dan cara memverifikasinya. Sertakan tangkapan layar untuk perubahan visual.
3. Jalankan `npm run typecheck`, `npm test`, dan `npm run build`. Tes integrasi membutuhkan MongoDB replica set serta Redis khusus tes.
4. Pastikan perubahan ekonomi, hadiah, atau admin memiliki validasi server, idempotensi, serta audit sesuai pola yang tersedia.
5. Catat sumber dan hak penggunaan aset. Jangan commit moodboard, gambar game pihak ketiga, token, password, `.env`, atau backup database.

Arah visual menggunakan Jala Muara dan lingkungan Nusantara yang ditulis dalam `docs/brand/`. Nama fiksi tidak boleh dipresentasikan sebagai klaim sejarah. Penggambaran simbol, busana, dan makhluk yang terkait tradisi perlu konteks serta peninjauan sebelum publikasi.

Perubahan antarmuka harus menyertakan keadaan memuat, kosong, gagal, fokus keyboard, serta tampilan HP lanskap. Jangan mengklaim pengujian perangkat nyata jika hanya memakai emulasi browser.

Lisensi proyek belum ditetapkan. Diskusikan kontribusi kode/aset eksternal dengan pemilik sebelum memasukkannya.
