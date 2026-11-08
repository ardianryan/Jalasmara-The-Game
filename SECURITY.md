# Pelaporan keamanan

Jangan membuka issue publik yang berisi token, data akun, langkah pengambilalihan yang siap digunakan, atau dump database. Gunakan kanal privat yang disediakan pemilik repository; jika kanal belum tersedia, buka issue tanpa rincian eksploit untuk meminta kontak privat.

Laporan sebaiknya menyertakan commit/versi, endpoint terdampak, prasyarat, dampak, serta reproduksi minimal menggunakan akun dan data uji milik pelapor. Pengujian tidak boleh mengganggu pemain atau layanan pihak ketiga.

Owner dibuat melalui terminal interaktif. Password disimpan dengan Argon2id. Token undangan/reset sekali pakai disimpan dalam bentuk hash. Cookie sesi menggunakan HttpOnly dan Secure pada produksi. Setiap endpoint admin memeriksa izin server.

CI berjalan di GitLab. Temuan CodeQL terdapat di artefak SARIF; laporan di GitHub adalah salinan berkas, bukan upload ke GitHub Code Scanning. Tidak ada jaminan bebas kerentanan dari keberhasilan pemindaian.
