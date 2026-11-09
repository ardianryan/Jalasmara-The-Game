# Panel pengelola dimuat saat dibuka

Implementasi lokal menindaklanjuti [usulan audit payload](../performance/06p-payload-audit.md): `main.tsx` kini memakai `AdminRoute`, dengan `React.lazy`/`Suspense` di dalam cabang sesi/peran yang sama. Halaman masuk/pemain/akun tidak perlu mengunduh kode editor. Tidak ada dependency, izin server, data atau aset game baru. **Belum masuk image staging203; PCK73d tidak diubah.**

`Loading` yang sudah ada tampil selama chunk diunduh. Error boundary memberi pesan dan tombol **Muat ulang halaman** bila chunk gagal; reload penuh menghapus promise import yang ditolak. Identity lazy berada di level module, sehingga render normal tidak memasang ulang editor.

## Bukti aktual

Typecheck dan build Vite produksi PASS. Dua run browser compiled masing-masing9/9PASS/0pageerror; run kedua memakai baseline eager yang dibangun di memori dari source yang sama, hanya mengembalikan import Admin statis. Tidak bergantung pada output dist lama. Build tidak menulis dist atau menyalin PCK; preview3111 dan image publik tetap.

Pemeriksaan meliputi guest login, player/admin ditolak, akun player/owner tanpa request chunk/APIadmin, host route pemain tanpa chunk Admin, authorized loading tertahan sebelum API, chunk asli selesai dan daftar pemain terbuka, HTTP503 chunk→fallback tanpa action API, serta klik reload→request module baru→panel berhasil. Viewport390×844 dan667×375 tanpa overflow. Seluruh API dan iframe game pada run ini adalah fixture lokal; bukan transaksi database atau startup Godot.

| JS | Eager baseline | Kandidat awal | Chunk Admin tertunda |
| --- | ---: | ---: | ---: |
| Byte tanpa encoding | 275.525 | 251.313 | 25.827 |
| Perkiraan gzip level9 | 85.649 | 79.092 | 8.055 |

Muatan entry turun24.212byte/8,79%, perkiraan gzip6.557byte/7,66%. Jika Admin dibuka, total kedua chunk277.140byte, bertambah1.615byte dibanding eager dan satu request tambahan. Angka gzip dihitung CPU dari output, bukan transfer terkompresi yang diukur di VPS. Ini bukan pengurangan PCK, biaya render, atau bukti FPS/perangkat fisik.

Bukti pertama `artifacts/browser/admin-chunk/`, log `.runtime/overnight-admin-chunk-browser.log`; run baseline independen `artifacts/browser/admin-chunk-1794255691789/`, log `.runtime/overnight-admin-chunk-browser-independent-baseline.log`, hasil SHA`65d88124fd11b33fd71f75edcb303697c69093f196025a21987e60755998f954`. Root meninjau loading portrait dan error landscape asli. Tidak ada browser/proses server uji yang dipertahankan.

Sesudah run9kedua, harness diperkuat agar setiap run mendapat direktori baru dan kegagalan assertion/shutdown mencatat outcome/failure/cleanup; cleanup browser gagal tidak melewati close server/penulisan hasil. Refactor pelaporan ini baru diperiksa sintaks, belum run browser tambahan. Source runtime sama dengan dua run9PASS. [Review independen](overnight-admin-chunk-peer.md) tidak menemukan blocker runtime.

Batas: boundary juga dapat menangkap error render sesudah editor terbuka, yang meng-unmount editor dan listener beforeunload. Ini bukan pemulihan draft setelah crash; run hanya menguji gagal chunk sebelum editor ada. Perlindungan draft normal tetap milik editor sebelumnya. Role gate owner diuji bersama player denial; seluruh variasi peran dan crash pascamount belum dibuktikan run ini.

Tool: Vite6.4.5, React19 existing, Playwright/Chromium, Python dan skill web-perf untuk pemeriksaan fokus source/network. ChromeDevToolsMCP tidak tersedia; tidak ada klaim CoreWebVitals atau skor Lighthouse baru. Tidak ada library/aset upstream baru, lisensi existing tetap.
