# Pemeriksa urutan kontak tangga (CPU)

Kandidat alat audit terpisah dari runtime Nala. Tidak ada perubahan controller, planner, fixture Godot, toleransi mesh, atau aset. Pemeriksa membaca `samples.jsonl`, `source.json`, metadata penyelesaian, dan WORLD yang hash-nya harus cocok; setiap run dinilai sendiri.

`tools/player-gait/check_stair_contacts.py` memperoleh lantai awal/akhir dan jumlah tread dari `landMaps.hub.terraces/stairs`, dengan kontrak elevasi renderer 48 unit per tingkat. Central/west: naik 60→72→84→96, turun 84→72→60→48. Ridge: naik 112→128→144, turun 128→112→96. Ramp dilaporkan sebagai rentang tinggi kontinu dan alternasi kontak, bukan urutan tread buatan.

Kontak berasal dari kaki yang grounded setelah free, atau plant baru yang grounded, disandingkan dengan perubahan counter. Nilai `plant.z` yang sudah mendarat dipakai; `landingHeight`/`toWorld` masih dapat merupakan target. Sample diam pada plant yang sama tidak dihitung ulang. Kontak awal setinggi lantai pendekatan dan pengulangan setinggi tumpuan terakhir diperbolehkan; tread yang dilewati/berbalik atau sisi sama berturut-turut merupakan kontradiksi. Kontak simultan, counter gap, dan counter pertama nonzero menandakan observasi tidak cukup; alat tidak mengarang urutan di dalam frame. Batas 0,001 pada perbandingan tinggi hanya menangani pembulatan string Vector Godot, bukan toleransi geometri baru.

Klaim `complete16CasesVerified` memerlukan 16 kelompok observasi yang lolos, metadata entered/crossed/stop-pause-restart/tanpa root placement yang lengkap, hasil final yang sama, dan flag final 16 kasus. Satu run terfilter yang selesai dapat lolos untuk kasus tersebut, tetapi bukan matriks penuh. `rejected.json` tetap membuat run gagal walaupun prefix urutan valid. CLI mengembalikan 0 untuk kasus terpilih yang selesai, 1 untuk kontradiksi/run ditolak, 2 untuk bukti belum lengkap/input tidak sah. Output memakai exclusive-create sehingga tidak menimpa bukti lama.

## Verifikasi yang dijalankan

- `python3 -m unittest discover -s tools/player-gait -p test_check_stair_contacts.py -v`: **15/15 PASS**. Meliputi naik/turun benar, skip, arah terbalik, sisi duplikat, sample diam, landing tanpa swing tersampel, counter gap/simultan, prefix parsial, WORLD berbeda, metadata 16 palsu, matriks sintetis lengkap/tanpa satu kelompok, dan ramp kontinu. Ini data sintetis untuk pemeriksa, bukan hasil gait 16 kasus.
- Run aktual lama `Jalasmara-overnight-character/artifacts/godot/nala-terrain-central-up-anchor-b78d14b`: **FAIL sebagaimana mestinya**, exit 1. WORLD SHA-256 `28455e6f7ec053d8e090457cae6e747d848aa3fd994e797e32608a0710dd5743` cocok. Frame 20: kanan mendarat 48 sebagai pendekatan. Frame 38: kiri mendarat 72 saat tread berikut seharusnya 60. Pemeriksa mendeteksi skip 60, mempertahankan pesan asli `Actual ankle jumps across terrain central_stone_steps/false/false travel side=right`, dan tidak mengklaim kasus selesai atau 16 kasus. Hasil lokal tersimpan di `.runtime/stair-contact-b78d14b.json` pada worktree resident-art; artefak asli tidak diubah.

Reproduksi dari worktree character setelah kandidat alat digabung:

```sh
python3 tools/player-gait/check_stair_contacts.py \
  --world .runtime/world-map.json \
  --run artifacts/godot/nala-terrain-central-up-anchor-b78d14b \
  --output /tmp/stair-contact-b78-review.json
```

Belum ada run next-tread baru yang diperiksa atau penerimaan matriks aktual 16 kasus. Urutan plant-height tidak membuktikan posisi kaki tepat di permukaan tread, clearance riser, panjang tulang, kontinuitas ankle, animasi lengan, gambar native, atau natural walking; pemeriksaan tersebut tetap milik fixture dan tinjauan karakter. Tidak ada engine/browser dijalankan untuk paket ini. Kode original Python standar, tanpa dependensi/aset upstream baru.
