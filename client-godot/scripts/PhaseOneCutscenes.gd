extends RefCounted

# Cinematic beats are presentation only. Progress, rewards, and the six boss resonances stay server-owned.
static func first_customer_from_shift(shift: Dictionary) -> String:
	for recipe in shift.get("customers",[]):
		if not (recipe is Dictionary) or str(recipe.get("id",""))!="daun_kuning": continue
		var name := str(recipe.get("customer","")).strip_edges()
		return name if not name.is_empty() else "Pelanggan Kedai"
	return "Pak Ranto" if shift.is_empty() else "Pelanggan Kedai"

static func sequence(id: String, first_customer: String = "Pak Ranto") -> Dictionary:
	var customer := first_customer.strip_edges()
	if customer.is_empty(): customer = "Pak Ranto"
	var legacy_darmi := customer == "Bu Darmi"
	var first_complaint := "Daun di kebunku pucat. Raka menyuruhku membeli cairan pabrik, tetapi aku lupa apa yang dibutuhkan daun untuk membuat makanan." if legacy_darmi else "Mbah Wira, kepalaku berat. Nota pasar ini kubaca terbalik. Raka menyuruhku membeli cairan pabrik untuk daun pucat di lapakku. Aku lupa cara daun membuat makanan." if customer == "Pak Ranto" else "Daun tanaman di rumahku pucat. Aku lupa bagaimana daun membuat makanan dan bingung harus mulai dari mana."
	var first_welcome := "Duduklah, Darmi. Nala membawa fragmen dari Segaran. Kita racik Seduhan Tunas Klorofil dan pahami cara daun bekerja." if legacy_darmi else "Duduklah, Ranto. Nala membawa sesuatu yang segar dari Dangkalan Segaran. Seduhan Tunas Klorofil ini akan membantu ingatanmu kembali jernih." if customer == "Pak Ranto" else "Duduklah. Nala membawa fragmen dari Segaran. Kita racik Seduhan Tunas Klorofil dan pahami cara daun bekerja."
	match id:
		"prologue":
			return {"title":"Kabut di Atas Bandar Hujung","bgm":"title_theme","lines":[
				{"shot":"0.1 · Bandar Hujung, lima bulan lalu","tone":"warm","name":"Mbah Wira","text":"Sebelum kabut datang, rakit-rakit Bandar Hujung ramai oleh perahu. Ki Lurah mengajari anak-anak membaca arah mata angin di dermaga."},
				{"shot":"0.1 · Sektor Tuban-7","tone":"plum","name":"Mbah Wira","text":"Lima bulan lalu, pipa PT Cakrawala Sintetis membuang residu ungu ke Palung Smara. Kabut Nir-Aksara naik dan ingatan warga mulai memudar."},
				{"shot":"0.1 · Pasar dan kebun","tone":"plum","name":"Mbah Wira","text":"Ingatan bukan benda mati, Nala. Ia mengalir seperti air pasang. Kini Pak Ranto lupa timbangan; Bu Darmi lupa cara merawat kebunnya."},
				{"shot":"0.2 · Kapal korporasi di Dermaga Bubat","tone":"plum","name":"Inspektur Raka","emotion":"happy","text":"Mengapa lelah menghafal rumus dan menghitung takaran? Minumlah Kapsul Kognisi Instan dari PT Cakrawala Sintetis! Bebas pusing, patuh bekerja, hidup tenang!"},
				{"shot":"0.2 · Penolakan","tone":"warm","name":"Ki Lurah Wirabhumi","emotion":"angry","text":"Bagas, Kinasih, Gito, Cempaka, Danu—berlindung di belakangku. Selama aku di sini, Bandar Hujung tidak menukar akal sehat dengan kapsul."},
				{"shot":"0.3 · Kepulangan Nala","tone":"warm","sfx":"explosion_heavy","name":"Beno","emotion":"shock","text":"Uhuk! Hampir saja! Eh—Nala?! Kau benar-benar pulang?!"},
				{"shot":"0.3 · Asap dari bengkel Beno","tone":"warm","name":"Nala","emotion":"shock","text":"Bang Beno? Apa yang kau rakit sampai meledak? Dan kenapa warga di pasar tadi menatapku dengan mata linglung?"},
				{"shot":"0.3 · Ajakan ke Kedai Waras","tone":"warm","name":"Mbah Wira","text":"Masuklah dulu ke Kedai Waras, Nala. Kabut di luar sana tidak ramah bagi pikiran yang belum diseduh rempah."},
				{"shot":"0.4 · Kedai Waras","tone":"warm","name":"Mbah Wira","text":"Kakekmu hilang saat menyelidiki pipa di Palung Smara. Ia meninggalkan SmaraPedia dan rancangan Jala Kognisi. Bawa fragmen biota pada siang hari; malamnya kuracik untuk warga."},
				{"shot":"0.4 · Jala Kognisi","tone":"teal","name":"Beno","emotion":"happy","text":"Perkenalkan, Jala Kognisi Tipe-1! Ingatan warga diserap biota Segaran. Tahan lalu lepaskan jala untuk menjaring fragmennya; resonansi di inti akan menguji pengetahuanmu."},
				{"shot":"0.4 · Janji Nala","tone":"warm","name":"Nala","emotion":"happy","text":"Kalau begitu, jangan biarkan Kedai Waras tutup lagi, Mbah. Tunjukkan tempat menyelamnya!"},
				{"shot":"Panduan perjalanan","tone":"warm","name":"Petualangan dimulai","text":"WASD atau joystick untuk bergerak; E untuk berinteraksi. Tahan lalu lepas spasi untuk menjala. M membuka peta, J jurnal, I tas. Tangga selam ada di Galangan Bubat."}
			]}
		"first_dive":
			return {"title":"Tetes Pertama di Segaran","bgm":"underwater_segaran","lines":[
				{"shot":"1.1 · Dangkalan Segaran","tone":"teal","sfx":"wave_crash_rock","name":"Nala","emotion":"happy","text":"Masker terpasang. Beno, kau mendengarku? Aku turun sekarang."},
				{"shot":"1.1 · Radio sonar","tone":"teal","name":"Beno","text":"Tes, tes! Sonar aman! Tahan jala hingga lingkaran terbuka, lalu lepaskan untuk menjaring Ubur-Ubur Klorofil. Kuis muncul di titik resonansi terkunci. Awasi oksigenmu."}
			]}
		"first_kedai":
			return {"title":"Malam Pertama di Kedai Waras","bgm":"kedai_waras_night","lines":[
				{"shot":"1.2 · Lentera kedai menyala","tone":"warm","name":customer,"emotion":"thinking","text":first_complaint},
				{"shot":"1.2 · Seduhan pertama","tone":"warm","name":"Mbah Wira","emotion":"happy","text":first_welcome}
			]}
		"first_service":
			return {"title":"Ingatan yang Menyala","bgm":"kedai_waras_night","lines":[
				{"shot":"1.2 · Secangkir seduhan","tone":"warm","name":customer,"emotion":"shock","text":"ASTAGA! Klorofil dan fotosintesis! Daun butuh cahaya, air, dan karbon dioksida untuk membuat makanan. Bagaimana aku bisa lupa?"},
				{"shot":"1.2 · Di luar jendela","tone":"plum","name":"Inspektur Raka","emotion":"thinking","text":"Kedai Waras buka lagi? Kita lihat berapa lama mereka bertahan."}
			]}
		"garden_crisis":
			return {"title":"Krisis Kebun Apung","bgm":"coastal_day","lines":[
				{"shot":"2.1 · Rakit tani Bu Darmi","tone":"plum","name":"Bu Darmi","emotion":"thinking","text":"Daun kebunku menguning, tetapi media tanamnya terus tergenang. Petugas pabrik hendak menyegel rakit ini dan menyalahkan hitunganku."},
				{"shot":"2.1 · Laskar Kognisi","tone":"warm","name":"Gito","emotion":"angry","text":"Pergi kalian! Jangan sita rakit Bu Darmi. Bagas, Kinasih, Cempaka, Danu—kita bantu Kak Nala!"},
				{"shot":"2.1 · Ancaman petugas pabrik","tone":"plum","name":"Petugas Korporasi","emotion":"angry","text":"Rakit ini gagal panen karena pemiliknya tak becus menghitung kadar garam dan unsur hara! Sesuai aturan perusahaan, rakit tak produktif harus dibongkar!"},
				{"shot":"2.1 · Tongkat ukur pasang-surut","tone":"warm","name":"Ki Lurah Wirabhumi","emotion":"angry","text":"Selama tongkat ulin ini menancap, tak ada rakit boleh dibongkar tanpa izin Balai Adat. Tolong Darmi; izin kebun kakekmu ada di papan balai setelahnya."},
				{"shot":"2.1 · Petunjuk Kinasih","tone":"teal","name":"Kinasih","emotion":"happy","text":"Kakekmu bilang rahasia kebun ada di Hutan Pesisir dan Hutan Lamun Wringin, 25–60 meter. Cari Koral Nitrogen, Lentera Fotosintesis, dan Kerang Osmosis."}
			]}
		"saras_visit":
			return {"title":"Tamu Rahasia di Kedai Waras","bgm":"village_hall","lines":[
				{"shot":"2.2 · Setelah kebun dirawat","tone":"warm","name":"Bu Darmi","emotion":"happy","text":"Akar mulai bernapas lagi setelah salurannya dibuka. Terima kasih, Nala. Pucuk baru masih perlu waktu untuk tumbuh."},
				{"shot":"2.2 · Pecahan prasasti","tone":"plum","name":"Saras","emotion":"thinking","text":"Raka mencabut izin penelitianku. Prasasti retak ini kutemukan di Jalatunda, 60 meter di bawah pipa utama. Ukirannya menunjukkan penjaga samudra."},
				{"shot":"2.2 · Arah Jalatunda","tone":"teal","name":"Nala","text":"Besok aku akan mengikuti pipa itu dan mencatat apa yang terjadi di sana."}
			]}
		"cave_warning":
			return {"title":"Gema dari Jalatunda","bgm":"underwater_cave_deep","lines":[
				{"shot":"3.1 · Rongga Kapur Jalatunda","tone":"deep","name":"Saras","emotion":"shock","text":"Cahaya hampir padam. Pipa PT Cakrawala Sintetis menembus batu kapur dan menyemburkan limbah ungu ke arah gerbang Tamansari."},
				{"shot":"3.1 · Raungan dari bawah","tone":"deep","sfx":"underwater_boom","name":"Saras","text":"Nala, mundur! Arus asam di gerbang terlalu pekat. Teliti dinding kapur dan pipa, pulihkan penyaring, lalu siapkan perlengkapan sebelum turun lebih jauh."}
			]}
		"earthquake":
			return {"title":"Lagu Sandi Sang Penjaga","bgm":"village_hall","lines":[
				{"shot":"3.2 · Pagi setelah kedai malam ketiga","tone":"plum","sfx":"underwater_boom","name":"Ki Lurah Wirabhumi","emotion":"angry","text":"Raka! Apa yang pabrikmu lakukan semalam? Air muara masih bergelembung ungu, dan pagi ini dermaga berguncang!"},
				{"shot":"3.2 · Pengakuan Raka","tone":"plum","name":"Inspektur Raka","emotion":"shock","text":"Makhluk di dasar palung menghalangi pipa kami. Kami menyuntikkan asam pekat agar ia mati, tetapi ia malah mengamuk!"},
				{"shot":"3.2 · Lagu Kinasih","tone":"teal","name":"Kinasih","text":"Gajah Mina bertapa di Tamansari, gadingnya batu, mahkotanya memori. Bila racun membelenggu dahi, basuhlah dengan kapur dan kasih yang murni."},
				{"shot":"3.2 · Peta batu Balai Adat","tone":"warm","name":"Saras","emotion":"thinking","text":"Dia bukan monster jahat. Pipa melilit tubuhnya dan meracuni Inti Kristal Smara di dahinya. Jika ia mati, ekosistem dan ingatan Palung Smara ikut musnah."},
				{"shot":"3.2 · Persiapan","tone":"warm","name":"Beno","emotion":"happy","text":"Bagas dan Mang Ujang menyiapkan lensa UV untuk helm selammu. Tingkatkan tabung oksigen dan Jala Kognisi ke level tiga di galangan sebelum turun ke Tamansari."},
				{"shot":"3.2 · Pesan Mbah Wira","tone":"warm","name":"Mbah Wira","text":"Enam resonansi menjaga inti ingatannya. Tiga membuka lapisan racun; tiga lagi memulihkan inti. Bawa Pelontar Kapsul Basa jika sudah kau siapkan."}
			]}
		"boss_intro":
			return {"title":"Gajah Mina · Penjaga yang Tercemar","bgm":"boss_gajah_mina","lines":[
				{"shot":"4.1 · Pelataran Kuno Tamansari · 100 m","tone":"deep","sfx":"underwater_boom","name":"Saras","emotion":"shock","text":"Lampu UV menyapu candi. Di balik pipa bocor, dua mata merah terbuka. Itulah Gajah Mina, penjaga samudra yang diracuni korporasi."},
				{"shot":"4.1 · Mahkota Smara","tone":"plum","name":"Nala","text":"Belalainya terlilit pipa, dan katup itu menjepit mahkotanya. Aku akan melepaskan asamnya, lalu menarik kabut dari inti di dahinya."},
				{"shot":"PENJAGA SAMUDRA YANG TERCEMAR","tone":"deep","name":"GAJAH MINA","text":"Enam titik resonansi. Hindari semburan, jawab pertanyaan, dan selamatkan sang penjaga."}
			]}
		"boss_phase_two":
			return {"title":"Inti Smara Terbuka","bgm":"boss_gajah_mina","lines":[
				{"shot":"4.2 · Tiga resonansi pertama","tone":"teal","sfx":"explosion_heavy","name":"Saras","emotion":"shock","text":"Katup asam retak! Limbah ungu mendesis menjadi gelembung jernih. Nala, bidik tiga resonansi tersisa di Inti Kristal Smara dan tarik residu kabutnya!"},
				{"shot":"4.2 · Pusaran Tamansari","tone":"deep","name":"Nala","text":"Aku melihat inti itu. Bertahanlah, Gajah Mina; sebentar lagi kau bebas."}
			]}
		"victory":
			return {"title":"Hujan Cahaya Ingatan","bgm":"coastal_dusk","lines":[
				{"shot":"4.3 · Purifikasi","tone":"teal","name":"Nala","emotion":"happy","text":"Kabut hitam tercabut dari mahkotanya. Mata Gajah Mina kini biru; ia menyentuh helmku pelan dengan ujung belalainya."},
				{"shot":"4.3 · Hadiah sang penjaga","tone":"warm","name":"Saras","emotion":"shock","text":"Ia menutup mulut pipa utama dengan batu candi, lalu menyerahkan Prasasti Smara Kuno! Bawa ke permukaan; ukirannya menyimpan petunjuk."},
				{"shot":"4.4 · Bandar Hujung","tone":"warm","name":"Beno","emotion":"happy","text":"Lihat, Nala! Cahaya ingatan naik menembus laut. Kabut Nir-Aksara buyar; warga Bandar Hujung tersadar!"}
			]}
		"epilogue":
			return {"title":"Fajar Baru di Bandar Hujung","bgm":"village_hall","lines":[
				{"shot":"4.5 · Pesta Kedai Waras","tone":"warm","name":"Inspektur Raka","emotion":"angry","text":"Tekanan pipa Sektor Tuban-7 mati! Mengapa tak ada yang mengantre kapsul? Aku akan menyegel kedai ilegal ini sekarang juga!"},
				{"shot":"4.5 · Warga berdiri bersama","tone":"warm","name":"Ki Lurah Wirabhumi","emotion":"angry","text":"Simpan suratmu, Raka. Warga sudah mengingat cara berpikirnya sendiri. Kami tidak butuh kapsul pelupamu. Dewan Adat akan menuntut pencemaran Palung Smara."},
				{"shot":"4.5 · Perayaan","tone":"warm","name":"Gito","emotion":"happy","text":"Dadah, Inspektur Kapsul! Jangan lupa belajar kimia dasar di jalan pulang!"},
				{"shot":"4.6 · Ruang peta Griya Sasmita","tone":"deep","bgm":"coastal_dusk","name":"Saras","emotion":"shock","text":"Lampu UV Bagas membuka peta di prasasti ini! Tamansari hanya gerbang luar. Di bawahnya ada Zona Senja Abisal, 100–300 meter, dan Perpustakaan Tenggelam Nusantara Kuno."},
				{"shot":"4.6 · Jejak kakek Nala","tone":"teal","name":"Ki Lurah Wirabhumi","text":"Di kedalaman 300 meter, PT Cakrawala Sintetis menancapkan bor Reaktor Inti Samudra. Pantas kakekmu menyelam ke sana dan belum kembali, Nala."},
				{"shot":"4.6 · Janji Beno","tone":"warm","name":"Beno","emotion":"happy","text":"Beri aku waktu merombak bengkel. Kita butuh Baju Selam Tekanan Tinggi untuk turun ke 300 meter dan membuka jalur bagi teman penyelammu."},
				{"shot":"4.6 · Beranda saat malam","tone":"warm","name":"Mbah Wira","emotion":"happy","text":"Istirahatlah malam ini, Nala. Kau telah mengembalikan senyum dan akal sehat Bandar Hujung. Besok, samudra yang lebih dalam menunggu."},
				{"shot":"TERIMA KASIH TELAH BERMAIN · FASE 1","tone":"teal","name":"Jala Smara","text":"Progres tersimpan. Bersiaplah menuju Fase 2: Zona Senja Abisal dan petualangan bersama!"}
			]}
	return {}

static func eligible_on_load(player: Dictionary, dive: Dictionary, shift: Dictionary) -> String:
	if player.is_empty() or not shift.is_empty(): return ""
	var progress: Dictionary = player.get("progress",{})
	if not bool(progress.get("tutorial",false)) and dive.is_empty(): return "prologue"
	var stage := str(progress.get("stage","dive"))
	var day := int(progress.get("day",1))
	if stage=="done" and dive.is_empty(): return "victory"
	if not dive.is_empty():
		if not dive.get("challenge",{}).is_empty(): return ""
		if str(dive.get("mode",""))!="boss": return "first_dive" if day==1 and str(dive.get("mode",""))=="dive" else ""
		var hits := int(dive.get("hits",0))
		var required_hits := int(dive.get("requiredHits",6))
		if required_hits<=0 or hits>=required_hits: return ""
		if hits>=ceili(required_hits/2.0): return "boss_phase_two"
		return "boss_intro" if hits==0 else ""
	if stage=="boss": return "earthquake"
	if day>=2 and day<3: return "garden_crisis"
	return ""

static func next_unseen_on_load(player: Dictionary, dive: Dictionary, shift: Dictionary, seen: Callable) -> String:
	if player.is_empty() or not shift.is_empty(): return ""
	if str(dive.get("mode",""))=="boss" and dive.get("challenge",{}).is_empty():
		var hits := int(dive.get("hits",0))
		var required_hits := int(dive.get("requiredHits",6))
		if required_hits>0 and hits<required_hits:
			if hits>=ceili(required_hits/2.0):
				if not bool(seen.call("boss_phase_two")): return "boss_phase_two"
			elif not bool(seen.call("boss_intro")): return "boss_intro"
	var eligible := eligible_on_load(player,dive,shift)
	if eligible.is_empty(): return ""
	if eligible=="victory":
		if not bool(seen.call("victory")): return "victory"
		return "" if bool(seen.call("epilogue")) else "epilogue"
	return "" if bool(seen.call(eligible)) else eligible

static func ready_to_extract_on_load(dive: Dictionary) -> bool:
	return str(dive.get("mode",""))=="boss" and dive.get("challenge",{}).is_empty() and int(dive.get("requiredHits",0))>0 and int(dive.get("hits",0))>=int(dive.get("requiredHits",0)) and float(dive.get("oxygen",0.0))>0.0
