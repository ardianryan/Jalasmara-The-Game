# Persiapan Security Audit Cloudflare — 12 November 2026

**Catatan historis:** Dokumen ini merekam pemeriksaan pada 12 November 2026. Status Cloudflare, alamat host, dan konfigurasi saat ini harus diperiksa ulang sebelum perubahan operasional.

Audit ini mencatat postur keamanan aktual staging, celah yang ditemukan dari
pemeriksaan live header, dan langkah integrasi Cloudflare beserta perubahan
konfigurasi yang diperlukan. Tidak ada perubahan produksi yang dilakukan dalam
sesi ini.

## 1. Kondisi saat ini

| Komponen | Nilai |
|---|---|
| URL publik | `https://staging-jalasmara.ardianryan.com` |
| TLS terminator | nginx 1.24.0 pada host proxy internal (aaPanel) |
| Upstream | Fastify pada host aplikasi di jaringan privat |
| Cloudflare | **Belum aktif** — tidak ada `cf-ray`/`cf-cache-status` di response |
| DNS | Langsung ke IP server tanpa proxy Cloudflare |

Header aktual dari `GET /api/health` (12 November 2026, 07:32 UTC):

```
HTTP/2 200
content-security-policy: default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; ...
cross-origin-opener-policy: same-origin
cross-origin-resource-policy: same-origin
referrer-policy: no-referrer
strict-transport-security: max-age=31536000; includeSubDomains   ← dari Helmet
strict-transport-security: max-age=31836000                       ← duplikat dari nginx
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
x-ratelimit-limit: 180
x-ratelimit-remaining: 179
x-ratelimit-reset: 60
server: nginx
```

## 2. Temuan pra-Cloudflare

### 2a. HSTS duplikat (severity: medium)

nginx mengirim `Strict-Transport-Security: max-age=31836000` tanpa
`includeSubDomains`. Helmet mengirim versi lengkap. Browser menggunakan
nilai pertama yang diterima; RFC 6797 tidak mendefinisikan perilaku ini
secara eksplisit — beberapa implementasi mengambil yang lebih rendah.

**Perbaikan**: Hapus header HSTS dari konfigurasi vhost nginx atau jadikan
konsisten dengan nilai Helmet. Karena Helmet sudah menangani header ini,
yang paling aman adalah menonaktifkan penambahan di nginx:

```nginx
# Hapus baris ini dari vhost nginx (jika ada):
add_header Strict-Transport-Security "max-age=...";
```

Cloudflare juga menambahkan HSTS melalui "Edge Certificates → HSTS" —
matikan jika Helmet sudah mengaturnya agar tidak tiga kali duplikat.

### 2b. Rate-limit headers terbuka (severity: low)

`x-ratelimit-limit`, `x-ratelimit-remaining`, `x-ratelimit-reset` terekspos
ke semua klien, termasuk penyerang yang memetakan batas endpoint. Ini bukan
risiko kritis mengingat batas sudah diatur per-route di auth, tetapi
Cloudflare rate limiting di edge akan bekerja lebih baik bila tidak
menginformasikan keadaan internal.

**Perbaikan** (opsional, setelah Cloudflare aktif): Tambahkan opsi
`addHeaders: false` pada `@fastify/rate-limit` untuk menyembunyikan header
ini, atau biarkan Cloudflare WAF menyembunyikannya melalui Transform Rules.

### 2c. `Permissions-Policy` tidak ada (severity: low)

Helmet v8 tidak lagi menambahkan `Permissions-Policy` secara default.
Header ini membatasi akses API browser (kamera, mikrofon, geolokasi).

**Perbaikan**: Tambahkan ke konfigurasi Helmet:

```typescript
permissionsPolicy: {
  features: {
    camera: ["'none'"],
    microphone: ["'none'"],
    geolocation: ["'none'"],
    payment: ["'none'"],
  },
},
```

### 2d. CSP `style-src 'unsafe-inline'` (severity: low)

Diperlukan untuk animasi CSS inline Godot/React. Dapat dimitigasi sebagian
dengan nonce di masa depan, tetapi bukan prioritas saat ini karena tidak
ada input HTML dari pengguna yang di-render sebagai markup.

### 2e. `server: nginx` terekspos (severity: informational)

Cloudflare otomatis menyembunyikan header `server` upstream dan menggantinya
dengan `cloudflare`. Tidak perlu patch manual.

### 2f. HSTS tanpa `preload` (severity: informational)

`max-age=31536000; includeSubDomains` sudah memenuhi syarat minimum preload.
Tambahkan `; preload` dan daftarkan ke `hstspreload.org` setelah Cloudflare
aktif dan domain stabil.

## 3. Rencana integrasi Cloudflare

### 3a. Prasyarat

- [ ] Domain `ardianryan.com` terdaftar dan NS dapat dipindah ke Cloudflare
- [ ] Akun Cloudflare (Free tier cukup untuk WAF dasar; Pro untuk OWASP
      Managed Rules dan Bot Fight Mode)
- [ ] Akses aaPanel pada host proxy internal untuk mengubah firewall

### 3b. Urutan aktivasi (jangan loncat langkah)

1. **Tambahkan domain ke Cloudflare** dan ekspor DNS records existing sebelum
   mengubah NS. Verifikasi semua A/CNAME sudah masuk.

2. **Pindah NS** ke Cloudflare. Jangan aktifkan orange-cloud (proxy) dulu —
   biarkan grey-cloud sampai semua konfigurasi selesai.

3. **SSL/TLS mode**: Atur ke **Full (Strict)**. Jangan gunakan Flexible karena
   TLS sudah terminate di nginx dengan sertifikat valid; Flexible membuka
   celah MITM antara Cloudflare dan origin.

4. **Aktifkan orange-cloud** (proxy) pada record
   `staging-jalasmara.ardianryan.com`. IP origin tersembunyi, traffic masuk
   hanya dari Cloudflare.

5. **Batasi akses origin**: Tambahkan aturan firewall di aaPanel/UFW agar
   port 443 (atau 80 jika nginx listen di HTTP) **hanya** menerima dari
   [Cloudflare IPv4](https://www.cloudflare.com/ips-v4) dan
   [Cloudflare IPv6](https://www.cloudflare.com/ips-v6). Ini mencegah
   bypass Cloudflare langsung ke IP origin:

   ```bash
   # Contoh dengan iptables (jalankan di host proxy, bukan VPS aplikasi):
   # Izinkan Cloudflare IPs
   for ip in $(curl -s https://www.cloudflare.com/ips-v4); do
     iptables -I INPUT -p tcp --dport 443 -s "$ip" -j ACCEPT
   done
   # Tolak semua selain Cloudflare
   iptables -A INPUT -p tcp --dport 443 -j DROP
   ```

   Verifikasi rule aktual, jangan hanya menambahkan tanpa memeriksa yang
   sudah ada. Simpan di unit systemd/aaPanel agar persist setelah reboot.

6. **`TRUST_PROXY` tidak perlu diubah** — Cloudflare terminating di
   Host proxy internal → nginx meneruskan ke host aplikasi dengan header
   `X-Forwarded-For` dari nginx. Nilai `TRUST_PROXY` yang aktif tetap harus dipertahankan.
   Cloudflare juga menambahkan `CF-Connecting-IP`; jika ingin IP asli klien
   di log, tambahkan ke nginx:

   ```nginx
   set_real_ip_from 103.21.244.0/22;   # range Cloudflare
   # ... (tambahkan seluruh CIDR dari https://www.cloudflare.com/ips-v4)
   real_ip_header CF-Connecting-IP;
   ```

   Jangan mengubah `trustProxy` di `.env` aplikasi tanpa pemeriksaan konfigurasi proxy aktif.

### 3c. Konfigurasi WAF Cloudflare

Aktifkan setelah orange-cloud aktif dan lalu lintas terkonfirmasi lewat
Cloudflare.

| Fitur | Rekomendasi | Catatan |
|---|---|---|
| **Managed Rules (OWASP CRS)** | Aktifkan, mode Block | Butuh plan Pro atau higher |
| **Cloudflare Managed Rules** | Aktifkan default ruleset | Plan Free mendapat sebagian |
| **Bot Fight Mode** | Aktifkan | Plan Free; mencegah scraping dasar |
| **Rate Limiting** | 50 req/10 detik per IP ke `/api/auth/*` | Tambahan di atas app-level limit |
| **DDoS L7** | Otomatis aktif | Tidak perlu konfigurasi tambahan |
| **Browser Integrity Check** | Aktifkan | Blokir request tanpa UA valid |

### 3d. Cache rules untuk aset game

Aset game besar (`/game/index.wasm`, `/game/index.pck`, bagian PCK) statis
dan di-fingerprint. Cloudflare dapat meng-cache ini di edge untuk mengurangi
beban VPS.

```
# Cache Rule 1 — Aset game statis
Match: URI Path matches /game/* AND URI Path does NOT match /game/index.wasm.map
Cache TTL: 30 hari (browser), 7 hari (edge)
Edge Cache TTL: 1 minggu

# Cache Rule 2 — API tidak boleh di-cache
Match: URI Path starts with /api/
Cache: Bypass
```

Pastikan Cloudflare tidak meng-cache `/api/` — ini sudah dikontrol oleh
header `Cache-Control: no-store` dari aplikasi, tetapi tambahkan cache rule
eksplisit sebagai lapisan kedua.

### 3e. Transform Rules — sembunyikan header internal

```
# Remove Response Header Rule
Field: X-Ratelimit-Limit, X-Ratelimit-Remaining, X-Ratelimit-Reset
Action: Remove
Applies to: semua request
```

### 3f. Turnstile (captcha bot protection) — opsional

Untuk endpoint registrasi (`/api/auth/register`) dan reset password
(`/api/auth/reset-password`), pertimbangkan Cloudflare Turnstile
(pengganti CAPTCHA). Implementasi:

1. Daftarkan site di Cloudflare Dashboard → Turnstile
2. Tambahkan widget di form React (web)
3. Verifikasi token di endpoint Fastify:
   ```typescript
   // apps/api/src/auth.ts — di handler register
   const turnstileToken = body.turnstileToken;
   const resp = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
     method: 'POST',
     body: new URLSearchParams({
       secret: process.env.TURNSTILE_SECRET!,
       response: turnstileToken,
       remoteip: req.ip,
     }),
   });
   const result = await resp.json();
   if (!result.success) fail('Verifikasi gagal.', 400, 'TURNSTILE');
   ```
   Jangan simpan `TURNSTILE_SECRET` di source atau laporan.

## 4. Checklist pra-aktivasi

Sebelum orange-cloud aktif, verifikasi:

- [ ] Semua DNS records sudah diimpor dan benar di Cloudflare dashboard
- [ ] SSL/TLS mode sudah diatur Full (Strict)
- [ ] Test akses langsung ke origin IP masih bekerja (grey-cloud, sebelum
      restrict firewall)
- [ ] Backup konfigurasi nginx vhost dan iptables
- [ ] Hapus/disable header HSTS duplikat di nginx

Setelah orange-cloud aktif:

- [ ] Verifikasi `cf-ray` header muncul di response
- [ ] Jalankan smoke publik 6-check dari `docs/operations.md`
- [ ] Konfirmasi `/api/health` masih 200 lewat Cloudflare
- [ ] Test WebSocket jika ada (Godot tidak menggunakannya, tapi perlu
      dikonfirmasi)
- [ ] Periksa WASM load masih berhasil (Cloudflare harus meneruskan MIME
      `application/wasm` — lihat `Cache-Control` di response)
- [ ] Verifikasi PCK segmented download masih bekerja (partial content /
      Range headers harus di-pass-through)

## 5. Perubahan kode yang direkomendasikan (terlepas dari Cloudflare)

| File | Perubahan | Prioritas |
|---|---|---|
| `apps/api/src/app.ts` | Tambah `permissionsPolicy` ke Helmet | Low |
| `apps/api/src/app.ts` | Tambah `addHeaders: false` ke `rateLimit` | Low |
| nginx vhost | Hapus duplikat `add_header Strict-Transport-Security` | Medium |

## 6. Yang tidak berubah

- Nilai `TRUST_PROXY` di `.env` tidak diubah dalam audit historis ini.
- Konfigurasi upstream proxy aaPanel — tidak diubah (hanya tambah IP allow)
- Cookie `__Host-jalasmara` prefix, httpOnly, sameSite: lax — sudah benar
- CSRF double-token (origin check + header) — tidak perlu diubah
- CodeQL CI — tetap berjalan di Gitea, independen dari Cloudflare
- Database/volume/`.env` — tidak disentuh

## Status

Dokumen ini adalah **persiapan audit**, bukan bukti aktivasi. Cloudflare
belum aktif. Tidak ada perubahan code, konfigurasi, atau DNS dalam sesi ini.

Langkah berikutnya (membutuhkan akses DNS registrar dan aaPanel):
1. Tambah domain ke Cloudflare, ekspor DNS
2. Pindah NS (koordinasi dengan owner)
3. Ikuti checklist Section 4 sebelum orange-cloud
