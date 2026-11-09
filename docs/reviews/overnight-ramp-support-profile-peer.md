# Peer CPU: kurva support ramp 209a49b

Review read-only source karakter `209a49b5e2f0a4667ecf28fe08222902d28ea2fc`, terutama `NalaFootPlant.gd:339–361,440–461,505–513`, model `tools/player-gait/model_ramp_profile.py` dan bukti crest di `Jalasmara-overnight-character/artifacts/godot/nala-ramp-sole-cpu/actual-crest-profile-3fb2e86.json`. Tidak mengubah karakter/controller/renderer, menjalankan Godot, atau menerima gait native.

## Bound sesuai formula pose, dengan domain eksplisit

Tulis `u=d/D`, `s=u²(3−2u)`, panjang XY path `L`, kemiringan support terhadap panjang XY pada span ke-i `mᵢ`, dan selisih raw-start di atas ground `a`. Source menggunakan XY pada jarak arc `Ls` dan `Z=g(Ls)+a(1−s)+3sin(πu)`. Dalam span affine, turunannya terhadap u adalah `s'·(L·tangentXY, mᵢL−a)+(0,0,3πcos(πu))`. Karena `0≤s'≤1.5`, triangle inequality memberi bound norm per accepted distance:

`[1.5·hypot(L, maxᵢ|mᵢL−a|)+3π]/D`.

Ini tepat formula source, dengan tambahan `|a|` konservatif pada maksimum. Round-up D ke0.25 tidak mengurangi konservatisme. Pada knot crest yang C0, derivative boleh berubah mendadak: bound pada kedua derivative satu sisi tetap membatasi selisih pose melalui integrasi. Derivative tidak wajib kontinu. Offset awal bukan lift baru; `s(0)=0` memberi Zawal raw-start dan `s(1)=1` memberi Zend ground. Nilai sine nol di kedua endpoint.

Prasyaratnya: XY path kontinu, finite dan piecewise affine, ground-height affine pada setiap span yang didata, semua perubahan slope/priority relevan terpotong, serta tangent ternormalisasi terhadap panjang XY. `_path_metrics` memotong connector rectangles, bukan seluruh polygon/priority boundaries. Karena itu formula ini **tidak membuktikan seluruh world atau side-exit dengan height jump**. Pada CPU model dock yang direkam, ramp dan adjoining floor atas bertemu di48; knot benar-benar35.016369→48→48 dan perubahan slope ramp→flat tercakup. Tidak ditemukan counterexample legal baru di lane ini.

Recompute mandiri CPU dari knot bukti,100.001 evaluasi derivative: `L=16.160884077773265`, slopes`[1.0720659219080848,0]`, `a=2.8266107692308466`, effective vertical span`14.498922318456838`, bound`4.199215543864915`, dense derivative peak`3.334516135433952` pada u`0.42218`. Ini cocok dengan model author, tanpa mengulang rumus GDScript sebagai klaim native.

Zero-XY dengan ground sama dan offset-only memberi norm `|-a·s'+3πcos|/D`, juga dibatasi formula. Uji CPU a0 dan±2.826610769 pada D10 memberi peak0.942478/1.057040 dan bound0.942478/1.366469. Untuk XYlen<1e−5 dan height berbeda>1e−5, source menandai invalid; bukan menciptakan slope infinite.

## Reanchor dan downstream valid gate

Sharp turn mengubah from/fromWorld ke pose aktual, reset distance, mempertahankan target, lalu mengganti seluruh `rampCurvePlan` hasil `_ramp_duration`; offset, knots, endpoint dan D dihitung ulang. Resume dari `settlingTarget` memperoleh actual ground-below lalu memanggil `_begin`, yang menghapus dan membuat plan baru. Formula moving tidak memakai plan lama saat settlement: branch stopped memakai move_toward tersendiri dan fixture mengecualikannya dari stale-plan assertion. Tidak ditemukan mismatch budget/pose atau stale-plan baru pada jalur source tersebut. Ini belum membuktikan ankle/pivot/view/whole-mask clearance.

Review awal sempat mengira valid flag hanya metadata karena moving planner tidak membacanya. Author menunjukkan downstream consumer; pembacaan ulang membuktikan `NalaLowerBody3D.gd:212–218` menolak ramp/tread plan invalid sebelum rendering, mengembalikan enabled=false/rejected dan fallback proxy. `scripts/tests/nala-lower-body.gd:113` mewajibkan enabled pada setiap sample, sehingga actual fixture juga menolak plan invalid. **Temuan metadata-only ditarik; tidak ada blocker valid-gate.** Direct assertion finite bound≤4.9 di fixture dapat menjadi diagnostik tambahan, bukan pengganti gate yang sudah ada. Tidak ada actual zero-XY vertical case yang ditemukan dan tidak dibuat klaim terrain semacam itu lolos.

## Bukti actual tetap terpisah

Invocation author `nala-terrain-dock-up-support-profile-209a49b` sudah menghasilkan `rejected.json`, check40, opaque right-foot vertex `(0,4)` enters/misses actual dock surface. Itu bukti whole-foot geometry masih gagal, bukan kegagalan algebra bound4.9 atau penerimaan ramp/native. Lane ini hanya membaca log/artifact tersebut. Full16, flat same-source, proper contacts, cadence/arms, dan actual device tetap bukan hasil peer CPU ini.
