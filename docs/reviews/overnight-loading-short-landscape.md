# Loading pada landscape pendek

Status: kandidat CSS website **lulus 16 pemeriksaan browser lokal** pada 10 November 2026 WIB. PCK, engine, server, data akun, dan proxy tidak diubah. Pengujian memakai UI host React sebenarnya dengan iframe dan sesi API fixture; bukan unduhan game atau perangkat S23 fisik.

## Kegagalan awal yang dipertahankan

Pada viewport 844×320, state stalled menempatkan panel pada y37,20–304, sedangkan Menu berada pada y4–52. Menu menimpa garis atas panel sekitar 14,8px dan panel menutupi sebagian brand. Retry/link tetap berada di viewport, masing-masing 48px, dan body 16px; ini **kegagalan clearance/komposisi**, bukan bukti retry tidak dapat ditekan. PNG diperiksa sebelum perubahan. Run berhenti di assertion tersebut, sehingga 932×280 belum diuji sebelum fix.

Bukti awal: `Jalasmara-overnight-hud-perf/artifacts/browser/website-loading-short/{results.json,short-844-stalled.png}` dan `.runtime/overnight-loading-short.log`. Results mencatat `status=failed`, empat pemeriksaan awal lulus dan 0 JavaScript errors. Browser ditutup melalui `finally`; kegagalan tidak diganti menjadi hasil lulus.

## Perubahan terbatas

Tambahan 10 baris `apps/web/src/game-loading.css` hanya berlaku pada landscape dengan tinggi ≤320px. `max-height` menyisakan ruang Menu+safe-area di atas dan 16px/safe-area di bawah, sementara panel memakai `overflow-y:auto`. Font body 16px dan target sentuh 48px tetap. CSS untuk viewport lebih tinggi tidak berubah. Pada layar pendek, isi panel dapat digulir; laporan ini tidak mengklaim seluruh isi dan semua aksi selalu terlihat sekaligus.

Mode `LOADING_SHORT_ONLY=1` pada `scripts/loading-screen-browser.mjs` membatasi fixture ke 844×320 dan 932×280, touch serta reduced-motion. Ia menyimpan bounds panel/Menu/aksi, font, scroll range dan posisi aktual. Bila aksi meluap, gesture browser CDP `touchStart`/`touchMove`/`touchEnd` menggulir panel; tidak ada `scrollTop` setter atau geometri palsu. Sesudah itu Menu ditap, Escape menutup dialog, dan retry ditap sampai tepat satu iframe baru muncul. Kasus error dan readiness juga diperiksa. Mode biasa harness dipertahankan; hasil short mendapat direktori bertimestamp agar bukti sebelumnya tidak tertimpa.

## Hasil aktual

Build web kandidat: Vite6.4.5, 45 modul, 558ms. `node --check` dan `git diff --check` lulus. Pengujian melalui production preview sendiri port5176:

```sh
PLAY_HOST_ORIGIN=http://localhost:5176 LOADING_SHORT_ONLY=1 \
node scripts/loading-screen-browser.mjs
```

**16 pemeriksaan lulus, 0 JavaScript errors.** Kedua viewport memeriksa known/unknown bytes, penolakan message invalid, teks 16px/reduced-motion, preparation vs ready, stalled/error/retry, Menu clearance dan target sentuh. Nilai yang terukur:

| Viewport/state | Panel y–bottom | Tinggi panel | Scroll sesudah gesture | Target aksi |
| --- | --- | --- | --- | --- |
| 844×320 stalled | 60–304 | 244px | 23px | 48px |
| 844×320 error | 133,20–304 | 170,80px | 0px | 48px |
| 932×280 stalled | 60–264 | 204px | 63px | 48px |
| 932×280 error | 93,20–264 | 170,80px | 0px | 48px |

Menu berakhir pada y52; panel stalled mulai y60. Aksi setelah gesture berada di dalam panel dan viewport. PNG controls kedua ukuran sudah dilihat: Menu/brand bebas dari panel, body dan retry terbaca. Heading/progress dapat bergerak keluar jendela panel ketika digulir ke aksi; ini scroll internal, bukan seluruh halaman bergeser atau font diperkecil. Tidak ada klaim penerimaan browser Safari/Chrome Android fisik atau performa game.

Bukti final di worktree sendiri:

- `.runtime/overnight-loading-short-final.log` dan `.runtime/overnight-loading-short-build.log`.
- `artifacts/browser/website-loading-short-1794250143300/results.json`, SHA256 `da9c2f8f45712b5b2858af869089e348a3758bf2c1e72505d930fd9716572ca4`.
- `short-844-stalled-controls.png`, SHA256 `a0ba55201482cc0d77bbd5ca0e88cd37fc387f606ede8f4fab58cbb0d92fdc11`.
- `short-932-stalled-controls.png`, SHA256 `62d96666ffc98d96faedd1f088ab442c0d25bcc1e14d941aeb96b2e7e60f5a16`.
- Screenshot sebelum gesture, download dan error kedua viewport tersedia di direktori yang sama.

Browser/context ditutup dan slot dilepas sesudah run. Preview port5176 sendiri dihentikan setelah bukti diperiksa; API/game preview3111 tidak disentuh. Tidak ada aset, dependency atau lisensi baru.
