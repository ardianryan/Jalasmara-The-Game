# Peer CPU: lazy admin chunk

Read-only review WIP integration `apps/web/src/AdminRoute.tsx`, `main.tsx`, dan `scripts/admin-chunk-browser.mjs`. Tidak mengubah source bersama, menjalankan browser, membangun host atau mengakses API. Root melaporkan build/typecheck PASS dan browser compiled9PASS/0pageerrors; angka tersebut bukan run lane peer.

Tidak ditemukan blocker runtime pada pemisahan chunk. `lazy` module-level mempunyai identity stabil dan import baru dipanggil ketika AdminRoute benar-benar dirender, di dalam cabang `/admin` yang sudah memeriksa sesi/peran seperti sebelumnya. Guest/player tidak memicu import melalui deklarasi lazy saja. Auth diteruskan ke Admin yang sama; tidak ada perubahan action/server gate. Rerender normal tidak meremount Admin. Suspense menampilkan status yang sudah ada; full-page reload adalah retry yang benar untuk promise/module import yang sudah ditolak, berbeda dari sekadar reset boundary.

Batas draft: boundary menangkap semua error render descendant, termasuk sesudah Admin terpasang. Fallback meng-unmount Admin beserta beforeunload listener draft di `admin.tsx`. Jadi ini bukan mekanisme pemulihan draft atau diagnosis khusus chunk transport. Error render yang tidak tertangkap sebelumnya juga dapat meng-unmount root; review tidak membuktikan regresi kehilangan draft baru. Jangan menyatakan draft setelah crash tersimpan. Harness hanya menguji kegagalan chunk awal sebelum editor ada.

Tiga saran QA konkret dikirim root sebelum pengulangan:

1. Baseline dari ignored `apps/web/dist` tidak tersedia pada checkout baru dan bisa sudah berisi kandidat, menyebabkan ukuran tidak dapat dibandingkan. Root sudah sedang menggantinya dengan build `write:false` kedua dari source/config yang sama, hanya mengembalikan import Admin statik di memori.
2. `finally` menunggu browser.close sebelum server.close dan penulisan hasil. Exception shutdown dapat melewatkan keduanya. Tangkap error shutdown terpisah; cleanup/output harus selalu dijalankan. Simpan pula status/failure assertion, karena checks parsial+errors kosong saja bisa terbaca sebagai sukses walaupun proses gagal.
3. Output hardcoded `artifacts/browser/admin-chunk` menimpa hasil/PNG run sebelumnya. Pakai output baru per run atau exclusive-create; pertahankan bukti9PASS awal sebelum rerun.

Coverage yang benar: host compiled dengan session/API fixture dan iframe kosong; role owner merupakan authorized path yang benar-benar diuji, admin-role tambahan belum diuji browser meskipun gate source tidak berubah. Tidak membuktikan form draft/action bisnis, failure sesudah mounted, startup Godot, deploy publik, FPS, atau perangkat fisik. Pageerror kosong juga bukan klaim console/API kosong; beberapa endpoint fixture sengaja404. Tidak ada approval flow atau framework baru yang diperlukan dari review ini.
