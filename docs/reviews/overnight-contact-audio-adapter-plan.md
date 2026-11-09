# Audit CPU: contact-trigger audio untuk Nala physical pilot

Read-only source karakter HEAD5b14ffd untuk file audio/animasi yang tidak diubah eksperimen H: `WorldFoley.gd`, `CharacterVisual.gd`, `Player.gd`, `Forest.gd`, `SurfaceTraversal.gd`, `AudioManager.gd`, serta test yang disebut di bawah. Nala planner/rig hanya dibaca untuk lokasi kontak dan validasi; author sedang mengerjakan geometri di file tersebut. Tidak ada implementasi runtime, engine, audio playback atau klaim sinkronisasi baru.

## Aturan04 dan perilaku yang benar-benar ada

`docs/plans/04-hud-fullscreen-performa-dan-gerak.md:135–137` meminta animasi dari perpindahan accepted setelah collision dan footstep pada contact frame/material terrain yang benar. **WorldFoley sudah contact-driven untuk karakter yang punya gait.** `CharacterVisual.set_locomotion:138–144` menambah travel dari moved logical velocity dan membuat queue setiap setengah stride; `WorldFoley:153–156` mengonsumsinya. Timer/distance38/.24 hanya fallback actor tanpa `consume_foot_contacts`, bukan penggerak normal Nala. Jangan menggambarkan default audio sebagai timer terpisah seluruhnya.

Untuk directional Nusantara, stride64logical → satu event per32logical. Controller mengirim actual moved logical velocity setelah collision; ketika blocked, travel berhenti. Ini diuji existing `scripts/tests/locomotion-collision-foley.gd` dengan actual Player100logical/s, house collision, phase/SFX berhenti dan count half-stride sama. Test tersebut tidak memasang lower-body pilot. `scripts/tests/world-foley.gd` menguji imported/playable WAV, delapan material, stationary/mute silence, area/connector override dan breathing/ambience; actor dummy-nya tanpa gait memakai fallback distance. Tidak ada actual-pilot contact/audio acceptance dari dua test itu.

## Gap terhadap kaki physical pilot

1. Lower planner mengukur accepted worldXY, fixed tread/ramp landings dan stopped-foot settlement. Kontak naik saat moving landing atau real stopped settlement, sedangkan CharacterVisual tetap memakai logical half-stride. `NalaFootPlant.snapshot` masih menyatakan `legacyFoleyChanged=false`; belum ada explicit validated-contact queue yang menyambungkannya. Bahkan pada flat north embedding,100worldXY/s≈57.3576logical/s memberi legacy57.3576/32≈1.7924contacts/s versus ideal physical100/32=3.125; EAST bisa kebetulan sama. Ini source estimate, bukan playback measurement.
2. `WorldFoley:154–155` mengubah seluruh array menjadi satu boolean. Dua atau lebih kontak yang terantre di satu process menjadi **satu** play_sfx. CharacterVisual sendiri membatasi empat event per update/delapan pending. Test actual biasa belum membuktikan batch behavior atau audio pada frame hitch.
3. Material diambil dari **actor.position** sebelum consume. `material_at(point):70–74` bahkan memprioritaskan actor.traversal_state saat onConnector, terlepas dari point argumen. Fungsi itu tidak boleh langsung dipakai untuk material kaki yang berada di support berbeda. Ground/surface tie semantics juga perlu mengikuti support aktual; existing legacy material test memilih elevasi lebih tinggi pada priority sama, sedangkan canonical ground memilih urutan surface terakhir pada priority sama. Jangan mengubah legacy policy diam-diam dalam adapter.
4. `_contact_count` bukan queue event: snapshot hanya counter dan feet akhir. `_reset` tidak mengulang counter; satu update dapat menyelesaikan beberapa kontak. Menebak side/plant dari counterdelta dan finalfeet dapat kehilangan urutan dan material. Counter juga dapat bertambah sebelum rig menolak Q/reach/opaque geometry; raw counterdelta bukan audio event yang sah.
5. Actual production-gait fixture mematikan Forest WorldFoley dan mengonsumsi CharacterVisual queue sendiri untuk `legacyContacts`. Angka planner/legacy di artifact adalah diagnostik, bukan suara yang telah sinkron.
6. `AudioManager.can_play_environment` hanya unlocked/mute/focus. WorldFoley tidak mempunyai gate modal/clock pause untuk foot-contact queue. Pose frozen tidak membuat kontak baru, tetapi queue yang sudah pending perlu dikuras tanpa bunyi saat pause; tidak boleh menganggap mute gate otomatis mencakup menu. Current teleport>80 branch juga return sebelum consume. Ini batas desain yang harus diuji, bukan klaim bug audio actual yang sudah direproduksi.

## Kontrak adapter bounded, pilot-only

Usulan API, belum ditambahkan:

```gdscript
# WorldFoley; Callable kosong mempertahankan jalur legacy persis.
set_foot_contact_source(source: Callable)
# Callable mengembalikan batch atomik; hanya WorldFoley mengonsumsi queue.
# LowerBody/renderer menjadi publisher sesudah geometri current pose diterima.
{
  "mode": "pilot", # pilot | legacy | suppressed
  "epoch": "actorInstance/rigGeneration/area",
  "paused": false,
  "validated": true,
  "latestSequence": 23,
  "contacts": [{
    "sequence": 23, "side": "left", "kind": "landing", # landing | stop_settlement
    "logical": Vector2(...), "worldPlant": Vector3(...),
    "supportId": "central_stone_steps", "material": "stone",
    "acceptedDistance": 123.0, "physicsFrame": 900,
    "processFrame": 901
  }]
}
```

- Producer menaruh record eksplisit pada transisi free→valid grounded, dengan side/plant/material saat kontak tersebut; initial idle dua planted feet, paused snapshot dan reset bukan contact. Char mengusulkan `NalaLowerBody3D.drain_validated_contacts()` setelah source geometry stabil. Mode/interface wrapper dapat tetap memakai Callable agar WorldFoley tidak bergantung langsung pada rig.
- Kontak provisional dari planner baru dipublish setelah LowerBody enabled, support/plane/reach/original fixed-bone validation diterima. Batch multi-contact memerlukan record per landing dan bukti validasi masing-masing; jangan memberi stempel accepted untuk intermediate contact yang hanya ditebak dari final pose. Jika producer belum bisa membuktikannya, test batch tetap gagal/open, bukan dikompresi ke satu boolean.
- Unique key `(epoch,sequence)` monotonik. Epoch berubah pada rig/area/config/outfit lifecycle, detach/rebuild, atau authoritative relocation/reset yang membatalkan old support. Repeat poll sama tidak membunyikan ulang; pending queue lama dibuang dan latestSequence menjadi watermark, bukan di-replay setelah configure atau fallback. Diagnostics memakai peek/copy, bukan consumer kedua yang mencuri event.
- Selama modepilot/suppressed, consumer tetap menguras legacy CharacterVisual queue tanpa memainkannya. Array pilot kosong berarti **tidak ada footstep**, bukan izin memakai fallback38timer. Pilot invalid/rejected, missing/deleted source, water entry, mute, focus loss, locked audio, modal/host/clock pause dan teleport membuang pending event sesuai reason serta me-rebaseline. Transition ke legacy membuang queue lama pada barrier itu, lalu memakai event legacy baru; default Callable kosong tidak mengubah default lama.
- Stop boleh menghasilkan **satu** bunyi dari real stopped landing sesudah settlement/Q siap. Diam setelah itu tidak menghasilkan event lagi. Pause tidak menyelesaikan kontak atau memutar suara; resume tidak membuat contact palsu sebelum valid new landing. Jangan mencampur stationary-after-settlement silence dengan satu landing fisik saat berhenti.
- Material harus ditentukan pada foot logical/worldPlant, area yang sama dan actual support yang cocok: connector id/material jika benar menyokong foot, selain itu surface priority/order/height yang sesuai support. Resolver pilot harus menghindari actor.traversal override. Unknown material atau stale area/epoch tidak diterka; tidak play dan dicatat. Tidak membaca/mengubah ekonomi, posisi server atau layout.
- Consumer memproses setiap distinct validated record sesuai urutan; tidak memakai cooldown/timer baru untuk menebak cadence. Pitch/volume dan mapping delapan existing SFX tetap. Bila event batch/hitch belum bisa diputar tanpa artefak, dokumentasikan batas/overflow, jangan klaim jumlah sinkron. BGM, coastal wave queue dan underwater breathing tidak diubah.
- Publish→consume boleh bergeser maksimum satu process-frame bila WorldFoley dijadwalkan sebelum renderer, dengan timestamp/ledger untuk membuktikannya; jangan mengganti update order global agar test tampak hijau. Bila perlu strict same-frame, root dapat menghubungkan explicit post-validated callback, sesudah ownership dibahas.

## Uji yang bisa menggagalkan proposal

Belum dijalankan; berikut acceptance untuk implementasi berikutnya:

| Kasus | Assertion yang harus dapat gagal |
| --- | --- |
| Default tanpa source | Existing actual collision-foley/world-foley tetap PASS, WAV/material/audio prefs sama |
| Actual pilot flat +4 konektor up/down | Setiap accepted published contact punya tepat satu play request; no play sebelum plant; sequence/side/support cocok event ledger dan actual opaque sole |
| Repeated poll +batch2/3 | Duplicates0, play count2/3; event unique/order utuh, bukan satu boolean |
| Beda material badan/kaki | Foot diwood/actor distone memakaiwood; connector endpoint kaki tidak mewarisi actor connector sembarang |
| Stop/restart +blocked | Satu validated stop settlement boleh bunyi, kemudian0; blocked/heldinput tanpa accepted plant0; resume tidak memutar backlog |
| Pause/mute/focus/locked | Pending event dikonsumsi sebagai discarded;0play selama suppressed; resume/unmute tanpa new plant0 |
| Geometry invalid sesudah planner count naik |0published/0play untuk batch invalid; no false contact karena raw counter |
| Rig/outfit/area reset, relocation, detach | Epoch berubah, old ids tidak replay; initial planted pair0; Callable invalid fallback fresh tanpa duplicate |
| Low/reduced/normal +hitch | Ledger/event count sama, latency≤satu process-frame yang dinyatakan; overflow explicit failure/open |
| Underwater/ambience | Tidak ada land footstep; existing breath/water/coastal/BGM behavior tetap |

Test menggunakan actual producer/WorldFoley/AudioManager dengan bus mute untuk menghitung play request, bukan monkeypatch footstep counter yang meniru implementasi. Rekam seq, plant point/support, accepted/physics/process timestamps, sound name dan discard reason. Setelah geometry/ledger PASS, native moving clip dan audio playback perlu review untuk timing perseptual, mixing, volume dan perangkat; geometry PASS sendiri tidak menyatakan audio aligned.

## Ownership dan langkah berikut

HOLD implementasi sampai core geometry koheren dan parent memberi file ownership. Character: NalaFootPlant explicit provisional records + LowerBody validated publish/epoch. Root: minimal LandActors provider lifecycle/Main/Forest wiring agar satu writer. Lane audio: helper/WorldFoley bounded consumption dan support resolver + dedicated actual fixture. AudioManager hanya dibaca; API/asset/SFX baru tidak dibutuhkan. Existing pilot OFF/default legacy tetap.

Character telah mengonfirmasi direction ini secara CPU dan meminta tidak mengedit rig/planner selama eksperimen H. Laporan ini hanya audit source dan kontrak falsifiable; belum ada event adapter, test audio baru, engine run atau penerimaan audio/cadence.
