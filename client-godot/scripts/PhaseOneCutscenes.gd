extends RefCounted

# Cinematic beats are presentation only. Progress, rewards, and the six boss resonances stay server-owned.
static func sequence(id: String) -> Dictionary:
	match id:
		"prologue":
			return {"title":"Kabut di Atas Bandar Hujung","bgm":"title_theme","lines":[
				{"shot":"0.1 · Bandar Hujung, lima bulan lalu","tone":"warm","name":"Mbah Wira","text":"Dulu, rakit-rakit Bandar Hujung ramai oleh perahu dan anak-anak belajar membaca arah angin bersama Ki Lurah Wirabhumi."},
				{"shot":"0.1 · Sektor Tuban-7","tone":"plum","name":"Mbah Wira","text":"Lalu pipa PT Cakrawala Sintetis membuang residu ungu ke Palung Smara. Kabut Nir-Aksara naik dan pengetahuan warga perlahan hilang."},
				{"shot":"0.1 · Pasar dan kebun","tone":"plum","name":"Mbah Wira","text":"Pak Ranto lupa membaca timbangan. Bu Darmi lupa merawat kebunnya. Ingatan mengalir seperti air pasang, Nala; sekarang arusnya diracuni."},
				{"shot":"0.2 · Kapal korporasi di Dermaga Bubat","tone":"plum","name":"Inspektur Raka","emotion":"happy","text":"Mengapa lelah menghafal rumus dan menghitung takaran? Kapsul Kognisi Instan dari PT Cakrawala Sintetis membuat hidup tenang!"},
				{"shot":"0.2 · Penolakan","tone":"warm","name":"Ki Lurah Wirabhumi","emotion":"angry","text":"Anak-anak, tetap di belakangku. Bandar Hujung tidak akan menukar akal sehatnya dengan kapsul."},
				{"shot":"0.3 · Kepulangan Nala","tone":"warm","sfx":"explosion_heavy","name":"Beno","emotion":"shock","text":"Uhuk! Nala? Kau pulang tepat ketika bengkelku hampir meledak. Ayo, Mbah Wira menunggu di Kedai Waras."},
				{"shot":"0.4 · Kedai Waras","tone":"warm","name":"Mbah Wira","text":"Kakekmu hilang saat menyelidiki pipa di Palung Smara. Ia meninggalkan SmaraPedia dan rancangan Jala Kognisi untukmu."},
				{"shot":"0.4 · Jala Kognisi","tone":"teal","name":"Beno","emotion":"happy","text":"Fragmen pengetahuan warga terserap biota laut. Jala ini bisa menangkapnya. Amati biota dan pahami pertanyaannya agar ingatan kembali jernih."},
				{"shot":"0.4 · Janji Nala","tone":"warm","name":"Nala","emotion":"happy","text":"Kalau begitu, kita buka lagi Kedai Waras. Tunjukkan tempat menyelamnya!"},
				{"shot":"Panduan perjalanan","tone":"warm","name":"Petualangan dimulai","text":"WASD atau joystick untuk bergerak; E untuk berinteraksi. Tahan lalu lepas spasi untuk menjala. M membuka peta, J jurnal, I tas. Tangga selam ada di Galangan Bubat."}
			]}
		"first_dive":
			return {"title":"Tetes Pertama di Segaran","bgm":"underwater_segaran","lines":[
				{"shot":"1.1 · Dangkalan Segaran","tone":"teal","sfx":"wave_crash_rock","name":"Nala","emotion":"happy","text":"Masker terpasang. Beno, kau mendengarku? Aku turun sekarang."},
				{"shot":"1.1 · Radio sonar","tone":"teal","name":"Beno","text":"Sonar aman! Jala Kognisi akan mengunci resonansi biota. Jawab pertanyaannya dengan cepat, dan jangan lupa kembali ke tangga sebelum oksigen habis."}
			]}
		"first_kedai":
			return {"title":"Malam Pertama di Kedai Waras","bgm":"kedai_waras_night","lines":[
				{"shot":"1.2 · Lentera kedai menyala","tone":"warm","name":"Pak Ranto","emotion":"thinking","text":"Nota pasarku terbalik lagi. Raka bilang daun pucat hanya perlu cairan pabrik. Tapi... apa yang dipakai daun untuk membuat makanan?"},
				{"shot":"1.2 · Seduhan pertama","tone":"warm","name":"Mbah Wira","emotion":"happy","text":"Duduklah, Ranto. Malam ini kita juga menolong Bu Darmi, pelanggan pertama, dengan fragmen yang Nala bawa. Pengetahuan kembali lewat pemahaman."}
			]}
		"first_service":
			return {"title":"Ingatan yang Menyala","bgm":"kedai_waras_night","lines":[
				{"shot":"1.2 · Secangkir seduhan","tone":"warm","name":"Bu Darmi","emotion":"shock","text":"Klorofil! Cahaya, air, dan karbon dioksida membantu tumbuhan membuat makanan. Bagaimana aku bisa lupa?"},
				{"shot":"1.2 · Di luar jendela","tone":"plum","name":"Inspektur Raka","emotion":"thinking","text":"Kedai Waras buka lagi? Kita lihat berapa lama mereka bertahan."}
			]}
		"garden_crisis":
			return {"title":"Krisis Kebun Apung","bgm":"coastal_day","lines":[
				{"shot":"2.1 · Rakit tani Bu Darmi","tone":"plum","name":"Bu Darmi","emotion":"thinking","text":"Daunku menguning, media tanamnya tergenang. Petugas pabrik hendak menyegel rakit ini sebelum aku tahu penyebabnya."},
				{"shot":"2.1 · Laskar Kognisi","tone":"warm","name":"Gito","emotion":"angry","text":"Jangan sita kebun Bu Darmi! Bagas, Kinasih, Cempaka, Danu—kita bantu Kak Nala!"},
				{"shot":"2.1 · Tongkat ukur pasang-surut","tone":"warm","name":"Ki Lurah Wirabhumi","emotion":"angry","text":"Tidak ada rakit yang dibongkar tanpa izin Balai Adat. Nala, kebun kakekmu kubuka kembali. Cari bukti sebelum senja."},
				{"shot":"2.1 · Petunjuk Kinasih","tone":"teal","name":"Kinasih","emotion":"happy","text":"Amati kebun, Hutan Pesisir Wringin, dan Hutan Lamun Wringin di 25–60 meter. Koral hara dan kerang osmosis mungkin menyimpan jawabannya."}
			]}
		"saras_visit":
			return {"title":"Tamu Rahasia di Kedai Waras","bgm":"village_hall","lines":[
				{"shot":"2.2 · Setelah kebun dirawat","tone":"warm","name":"Bu Darmi","emotion":"happy","text":"Akar mulai mendapat udara lagi. Aku akan membuka saluran pasang malam ini; pucuk baru butuh waktu untuk tumbuh."},
				{"shot":"2.2 · Pecahan prasasti","tone":"plum","name":"Saras","emotion":"thinking","text":"Izin penelitianku dicabut Raka. Tetapi di dekat Jalatunda aku menemukan ukiran penjaga samudra—tepat di bawah pipa pembuangan utama."},
				{"shot":"2.2 · Arah Jalatunda","tone":"teal","name":"Nala","text":"Besok aku akan mengikuti pipa itu dan mencatat apa yang terjadi di sana."}
			]}
		"cave_warning":
			return {"title":"Gema dari Jalatunda","bgm":"underwater_cave_deep","lines":[
				{"shot":"3.1 · Rongga Kapur Jalatunda","tone":"deep","name":"Saras","emotion":"shock","text":"Cahaya hampir habis. Pipa korporasi menembus batu kapur dan limbah ungunya mengalir ke arah gerbang Tamansari."},
				{"shot":"3.1 · Raungan dari bawah","tone":"deep","sfx":"underwater_boom","name":"Saras","text":"Nala, jangan dekati arus asam tanpa persiapan. Amati pipa, pulihkan penyaring desa, dan kumpulkan fragmen untuk racikan malam ini."}
			]}
		"earthquake":
			return {"title":"Lagu Sandi Sang Penjaga","bgm":"village_hall","lines":[
				{"shot":"3.2 · Gempa Bandar Hujung","tone":"plum","sfx":"underwater_boom","name":"Ki Lurah Wirabhumi","emotion":"angry","text":"Raka! Mengapa air di muara bergelembung ungu dan dermaga berguncang?"},
				{"shot":"3.2 · Pengakuan Raka","tone":"plum","name":"Inspektur Raka","emotion":"shock","text":"Tekanan pipa meningkat. Makhluk di dasar palung menghalangi saluran kami... suntikan asam justru membuatnya mengamuk."},
				{"shot":"3.2 · Lagu Kinasih","tone":"teal","name":"Kinasih","text":"Gajah Mina bertapa di Tamansari; gadingnya batu, mahkotanya memori. Bila racun membelenggu dahi, basuhlah dengan kapur dan kasih yang murni."},
				{"shot":"3.2 · Peta batu Balai Adat","tone":"warm","name":"Saras","emotion":"thinking","text":"Dia bukan monster jahat. Pipa melilit tubuhnya dan meracuni inti di dahinya. Kita harus memulihkannya, bukan menyerang tubuhnya."},
				{"shot":"3.2 · Persiapan","tone":"warm","name":"Beno","emotion":"happy","text":"Nala, pastikan tabung oksigen dan Jala Kognisi mencapai level tiga sebelum turun ke Tamansari. Aku siap membantu di galangan."},
				{"shot":"3.2 · Pesan Mbah Wira","tone":"warm","name":"Mbah Wira","text":"Enam resonansi menjaga inti ingatannya. Tiga membuka lapisan racun; tiga lagi memulihkan inti. Pergilah saat perlengkapanmu siap."}
			]}
		"boss_intro":
			return {"title":"Gajah Mina · Penjaga yang Tercemar","bgm":"boss_gajah_mina","lines":[
				{"shot":"4.1 · Pelataran Kuno Tamansari · 100 m","tone":"deep","sfx":"underwater_boom","name":"Saras","emotion":"shock","text":"Lampu Nala menyapu reruntuhan. Di balik pipa bocor, dua mata merah terbuka. Itulah Gajah Mina—penjaga laut yang diracuni."},
				{"shot":"4.1 · Mahkota Smara","tone":"plum","name":"Nala","text":"Belalainya terlilit pipa. Aku akan melepaskan lapisan asam lalu menarik kabut dari inti di dahinya."},
				{"shot":"PENJAGA SAMUDRA YANG TERCEMAR","tone":"deep","name":"GAJAH MINA","text":"Enam titik resonansi. Hindari semburan, jawab pertanyaan, dan selamatkan sang penjaga."}
			]}
		"boss_phase_two":
			return {"title":"Inti Smara Terbuka","bgm":"boss_gajah_mina","lines":[
				{"shot":"4.2 · Tiga resonansi pertama","tone":"teal","sfx":"explosion_heavy","name":"Saras","emotion":"shock","text":"Lapisan asam terlepas dan katup pipa retak! Sekarang bidik tiga resonansi yang tersisa di sekitar Inti Kristal Smara."},
				{"shot":"4.2 · Pusaran Tamansari","tone":"deep","name":"Nala","text":"Aku melihat inti itu. Bertahanlah, Gajah Mina; sebentar lagi kau bebas."}
			]}
		"victory":
			return {"title":"Hujan Cahaya Ingatan","bgm":"coastal_dusk","lines":[
				{"shot":"4.3 · Purifikasi","tone":"teal","name":"Nala","emotion":"happy","text":"Kabut hitam terlepas dari mahkota. Matanya kembali biru; Gajah Mina menyentuh helmku dengan belalainya."},
				{"shot":"4.3 · Hadiah sang penjaga","tone":"warm","name":"Saras","emotion":"shock","text":"Ia menyumbat pipa utama dan meninggalkan Prasasti Smara Kuno! Bawa ke permukaan; kita harus membaca ukirannya."},
				{"shot":"4.4 · Bandar Hujung","tone":"warm","name":"Beno","emotion":"happy","text":"Lihat, Nala! Cahaya ingatan naik ke kota. Kabut Nir-Aksara mulai buyar!"}
			]}
		"epilogue":
			return {"title":"Fajar Baru di Bandar Hujung","bgm":"village_hall","lines":[
				{"shot":"4.5 · Pesta Kedai Waras","tone":"warm","name":"Inspektur Raka","emotion":"angry","text":"Tekanan pipa Sektor Tuban-7 mati! Kalian berhenti mengantre kapsul? Aku akan menyegel kedai ini!"},
				{"shot":"4.5 · Warga berdiri bersama","tone":"warm","name":"Ki Lurah Wirabhumi","emotion":"angry","text":"Simpan suratmu. Warga telah mengingat cara berpikirnya sendiri. Dewan Adat akan menuntut pencemaran Palung Smara."},
				{"shot":"4.5 · Perayaan","tone":"warm","name":"Gito","emotion":"happy","text":"Dadah, Inspektur Kapsul! Jangan lupa belajar kimia dasar di jalan pulang!"},
				{"shot":"4.6 · Ruang peta Griya Sasmita","tone":"deep","name":"Saras","emotion":"shock","text":"Di bawah Tamansari masih ada Zona Senja Abisal hingga 300 meter—dan Perpustakaan Tenggelam Nusantara Kuno."},
				{"shot":"4.6 · Jejak kakek Nala","tone":"teal","name":"Ki Lurah Wirabhumi","text":"Di titik terdalam itu, korporasi menancapkan bor reaktornya. Mungkin kakekmu masih mengikuti jejak yang sama, Nala."},
				{"shot":"4.6 · Janji Beno","tone":"warm","name":"Beno","emotion":"happy","text":"Aku akan merombak bengkel untuk baju selam tekanan tinggi. Untuk malam ini, kita pulang dulu."},
				{"shot":"4.6 · Beranda saat malam","tone":"warm","name":"Mbah Wira","emotion":"happy","text":"Istirahatlah, Nala. Kau telah mengembalikan senyum dan akal sehat Bandar Hujung."},
				{"shot":"TERIMA KASIH TELAH BERMAIN · FASE 1","tone":"teal","name":"Jala Smara","text":"Progres tersimpan. Petunjuk perjalanan menuju kedalaman abisal telah terbuka di SmaraPedia."}
			]}
	return {}

static func eligible_on_load(player: Dictionary, dive: Dictionary, shift: Dictionary) -> String:
	if player.is_empty() or not dive.is_empty() or not shift.is_empty(): return ""
	var progress: Dictionary = player.get("progress",{})
	if not bool(progress.get("tutorial",false)): return "prologue"
	var stage := str(progress.get("stage","dive"))
	var day := int(progress.get("day",1))
	if stage=="done": return "epilogue"
	if stage=="boss": return "earthquake"
	if day>=2 and day<3: return "garden_crisis"
	return ""
