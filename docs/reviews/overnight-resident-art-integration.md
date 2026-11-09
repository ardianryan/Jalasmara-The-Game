# Regresi integrasi rig warga

Kandidat CPU pada `work/overnight-resident-art`, setelah `70d8486`. File baru `scripts/tests/resident-art-integration.gd` sengaja tidak memanggil configure helper secara langsung: seluruh pemilihan, cache, update, tint dan visibility harus melewati LandWorld3D/LandActors3D produksi. Belum dijalankan sampai wire integrator tersedia dan root memberi slot. Tidak ada perubahan LandActors/HubActor dari lane ini.

Fixture membuat enam HubActor canonical dari WORLD, menggunakan appearance/custom-sheet seperti spawn Main saat ini. Ia mewajibkan frame original 96×128 yang valid, hidden billboard, satu body dan satu properti perwarga, tidak ada generic research book/watering can kedua, night tint pada shader, sole pada support nyata dan Ujang tetap pada rig/joran lama. Lifecycle mencakup pause, land-viewport disable selama dive, resume, actor dilepas tetapi masih hidup, reattach, queue_free dan recreate dengan identitas canonical sama. WORLD tidak boleh berubah.

Audit CPU menemukan dua hal untuk penulis LandActors (root): old atlas 3×2 tidak cukup untuk appearance6..11 meskipun billboard nanti disembunyikan; dan rig cache semula hanya membersihkan actor freed/queued, sehingga actor yang dilepas tetapi masih hidup dapat meninggalkan badan 3D. VillageActivity juga memberi buku/can kedua pada tangan yang sudah membawa properti rig. Temuan dikirim root, bukan ditutupi oleh fixture. Guard tetap ketat dan tanpa production edits di lane ini.

Reproduksi di worktree gabungan yang sudah berisi wire root: `Godot --headless --path client-godot --script ../scripts/tests/resident-art-integration.gd`. Bukti helper terisolasi 576 pose dan native pair tidak menggantikan regresi integrasi ini.
