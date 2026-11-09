# Kebutuhan pembuktian tangga untuk pilot fisik Nala

Audit source baca-saja,10November2026. Tidak menjalankan engine atau mengubah karakter. Acuan source karakter `59f0356`, shared WORLD layout hub11/forest6 dan renderer/query kanonis yang telah diuji terpisah.

## Lantai dan diskontinuitas yang memang diauthor

Probe CPU memakai `isLandSegmentWalkable` server radius12: seluruh centerline berikut sah dua arah. Batas itu bukan izin berjalan menembus sisi/tanah di luar stair.

| Connector | Tinggi awal→akhir | Tread atas | Panjang logis/tread | XY aktual/tread |
| --- | --- | --- | --- | --- |
| central_stone_steps | 48→96 | 60,72,84,96 | 20 | 17,731160 |
| western_stone_steps | 48→96 | 60,72,84,96 | 20 | 17,731160 |
| forest_ridge_steps | 96→144 | 112,128,144 | 20 | 12,018568 |
| dock_gangway ramp | 0→48 | bidang kontinu, bukan tread | 65total | 44,772937total |

`StairGeometry3D.contact_point` memakai XY bidang tinggi linear agar tiap riser tidak menggeser kaki ke tread lain, lalu mengganti Z dengan tread aktual. Pada kenaikan, t0 sudah berada pada tread pertama (60atau112), bukan floor rendahnya. Pada batas antar-tread, upper tread menang menurut floor(progress×steps); underside/risernya tetap geometri padat. Pendaratan sole harus mengikuti actual tread, sedangkan fase/cadence horizontal tidak menghitung loncatan Z diskret sebagai jarak badan.

## Cara memutuskan landing yang perlu dibuktikan

Planner sekarang memilih forward target dalam unit worldXY, mencari titik dengan support heel/mid/toe pada tread yang sama, lalu menyimpan landingHeight. Retarget hanya free foot dan mempertahankan tinggi landing yang dipilih. Ini arah kontrak yang tepat; jangan membulatkan target ke tinggi torso atau menaruh sole pada tepi riser tanpa ruang bagi opaque heel/toe.

Target harus berada di tread maju yang benar-benar muat dalam reach tungkai artwork dan bisa dicapai kurva swing. Sebelum ujung opaque sepatu memasuki footprint tread lebih tinggi, seluruh ujung yang relevan harus sudah di atas permukaan/riser tersebut. Saat turun, jangan merendahkan sepatu ketika heel/toe masih berada di atas tread lama yang lebih tinggi. Titik centroid saja tidak membuktikan bebas penetrasi. Bidang tertinggi mesh di tiap heel/toe menentukan batas, bukan hanya query nominal.

`_safe` boleh mencari sepanjang tangent agar sepatu muat, tetapi jalur fallback akhirnya dapat mengembalikan origin jika pencarian gagal. Fixture perlu memastikan actual hasil akhir tetap legal/supported/requiredHeight dan reachable; source fallback bukan bukti. Tidak ada kegagalan runtime baru yang dinyatakan dari pembacaan ini. Jangan mengubah collider, mengangkat actor root, menambah panjang tulang atau menaikkan tolerance untuk membuat target diterima.

Kurva ascent/descent menggunakan `advance` delay/window, sehingga batas cubic datar pada [peer actualbase](overnight-nala-short-step-algebra-peer.md) tidak otomatis berlaku. Periksa derivative akibat remapping tersebut, posisi target yang berubah, transfer tubuh, sole/ankle3D dan pijakan endpoint pada sampel controller yang benar-benar diterima.

## Cakupan yang sudah ada dan celah source nyata

- `stair-foot-grounding.gd` menguji geometri tread/ramp aktual, invers lokal/proyeksi, permukaan tertinggi dan traversal/bodyLift. Ini gate ground yang berguna, bukan bukti swing kaki modular.
- `nala-lower-body.gd` memiliki guard kuat: actual mesh triangle sole/opaque heel/toe, panjang tulang tetap, planted drift, ankle continuity5×accepted distance, transfer torso dan gear. Namun `_tick` **menulis player.position secara langsung**. Ia tidak menguji percepatan/collision aktual controller.
- Legacy fixture itu tidak mengaktifkan `nala_physical_walk_pilot`; planner memakai kontrak default. Stair loop hanya memanggil `_reset_case(...,"daily")`. Karena loop flat terakhir memakai reduced=true dan `_reset_case` tidak mengatur ulang clock, **stair loop mewarisi reduced=true**. Flat8arah/daily/explorer/normal/reduced tidak berarti kombinasi tersebut sudah diuji pada tangga.
- `nala-production-gait.gd` menjalankan actual Player/Forest dan kontrak fisik bila opt-in, tetapi `_origin` sengaja memilih clear flat radius105 dan32kasus berfokus pada arah/analog/stop/turn. Ia tidak memaksa perjalanan stair.
- `nala-physical-boundary-input.gd` menguji input/kecepatan ground aktual, tetapi secara eksplisit mematikan lower-body pilot. Karena itu kelulusannya tidak menutup gap swing/landing di tangga.
- Probe `_forward_units` lama hanya memilih connector bertipe stairs; ramp entrance/exit belum tercakup oleh probe jarak kaki tersebut. Catatan ini celah coverage source, bukan klaim kegagalan actual ramp yang belum dijalankan.

## Matriks berikutnya yang minimal dan bermakna

Aktifkan kontrak fisik pada actual Player/Forest, gunakan collider/ground renderer yang sama, dan inherit guard actual mesh/foot di atas. Lewati masing-masing tiga stair dua arah dari floor approach melewati landing exit. Catat source/helper/manifest hash, waktu physics/wall, accepted arc, tread index kedua kaki dan semua pose gagal. Tambahkan normal/reduced serta daily/explorer yang dinyatakan eksplisit; jangan membiarkan flag dari kasus sebelumnya menentukan cakupan.

Mulai centerline agar kegagalan dapat diisolasi, kemudian legal lateral offset, berhenti/settle/lanjut di sekitar riser dan berbalik pada tread yang cukup luas. Sampling sebelum/tepat/sesudah riser harus memeriksa opaque heel/toe dan fixed bone, bukan hanya actor progress. Pause harus menahan pose; grounded sole tetap pada dunia saat torso/gear berpindah. Catat footprint/rute yang tidak sah sebagai setup reject, bukan memindahkan pemain ke lantai buatan.

Native berurutan pada zoom gameplay diperlukan setelah guard tersebut lolos: naik/turun, torso transfer, kaki tidak menyapu riser, alat mengikuti badan. Tidak cukup satu screenshot atau angka bodyLift. Natural cadence/arm opposition tetap gate terpisah. Belum ada counterexample gait tangga baru yang dijalankan pada audit ini, dan belum ada alasan enable pilot default.
