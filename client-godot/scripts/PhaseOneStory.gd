extends RefCounted

static func goal(state: Dictionary) -> String:
	var player: Dictionary = state.get("player",{})
	var progress: Dictionary = player.get("progress",{})
	var day := int(progress.get("day",1))
	var stage := str(progress.get("stage","dive"))
	var discoveries: Array = state.get("adventure",{}).get("discoveries",[])
	var puzzles: Array = state.get("adventure",{}).get("puzzles",[])
	var dive: Dictionary = state.get("dive",{})
	if state.get("homestead",{}).get("pendingStoryAdvance") != null:
		return "Pulang ke Griya Sasmita di barat desa dan tidur di dipan."
	if stage == "done":
		return "Gajah Mina pulih dan Prasasti Smara Kuno tersimpan. Fase 1 selesai; baca penutup di jurnal."
	if stage == "boss":
		var abilities: Dictionary = player.get("abilities",{})
		if int(abilities.get("oxygen",0)) < 3 or int(abilities.get("net",0)) < 3:
			return "Minta Beno meningkatkan Tabung O2 dan Jala ke level 3 sebelum ke Tamansari."
		return "Selami Tamansari. Jawab enam resonansi pada Gajah Mina, hindari semburan, lalu kembali ke permukaan."
	if stage == "night":
		return "Temui Mbah Wira di Kedai Waras. Layani tiga keluhan warga, tutup kedai, lalu tidur di Griya Sasmita."
	if day == 1:
		return "Selami Dangkalan Segaran, amati fragmen dan jala bahan untuk tiga racikan Kedai Waras."
	if day == 2:
		var garden := _count(discoveries,["garden_leaf","garden_root","garden_channel"])
		var forest := _count(discoveries,["forest_canopy","forest_roots","forest_stream"])
		var sea := _count(discoveries,["nitrogen","photosynthesis","osmosis"])
		if not dive.is_empty():
			return "Hutan Lamun Wringin (25–60 m): amati tiga bukti laut (%d/3) dan jala Benih Hayati." % sea
		return "Bantu Bu Darmi: kebun %d/3, hutan pesisir %d/3, hutan lamun %d/3; bawa Benih Hayati." % [garden,forest,sea]
	if not discoveries.has("corporate_pipe"):
		return "Babak 3: selami Jalatunda dan amati pipa korporasi di dekat instalasi air."
	if not puzzles.has("filter"):
		return "Pipa ditemukan. Pecahkan teka-teki penyaring Jalatunda sebelum membuka Kedai Waras."
	return "Penyaring pulih. Jala bahan untuk tiga racikan terakhir, lalu temui Mbah Wira di Kedai Waras."

static func chapters(state: Dictionary) -> Array:
	var progress: Dictionary = state.get("player",{}).get("progress",{})
	var day := int(progress.get("day",1))
	var stage := str(progress.get("stage","dive"))
	var missions: Array = progress.get("missions",[])
	var defeated := bool(progress.get("bossDefeated",false))
	return [
		{"title":"Babak 1 · Kabut dan Kopi Pahit","subtitle":"Hari cerita 1 · Segaran dan Kedai Waras","text":"Kabut Nir-Aksara merenggut pengetahuan warga. Nala membantu Mbah Wira dengan mengamati Segaran, menjala fragmen, lalu melayani tiga keluhan pertama di Kedai Waras. Sesudah giliran berakhir, tidur di Griya Sasmita membuka babak berikutnya.","unlocked":true,"icon":"ekosistem"},
		{"title":"Babak 2 · Kebun Apung yang Sekarat","subtitle":"Hari cerita 2 · Bu Darmi","text":"Bu Darmi menolak Kapsul Tani instan. Bandingkan tiga gejala kebun dengan tiga bukti Hutan Pesisir Wringin dan tiga bukti Hutan Lamun Wringin. Bawa Benih Hayati ke kedai agar akar mendapat udara dan hara kembali.\n\n" + ("Racikan akar telah dilayani; kebun mulai pulih." if missions.has("akar") else "Bicara dengan Bu Darmi di petak kebunnya."),"unlocked":day>=2,"icon":"klorofil"},
		{"title":"Babak 3 · Jejak Pipa Jalatunda","subtitle":"Hari cerita 3 · Instalasi dan penyaring","text":"Jejak asam mengarah ke pipa PT Cakrawala Sintetis di Jalatunda. Amati pipa, pecahkan teka-teki penyaring, lalu racik tiga solusi warga terakhir. Catatan ilmiah lebih kuat daripada Kapsul Instan.","unlocked":day>=3,"icon":"netralisasi"},
		{"title":"Babak 4 · Penjaga Tamansari","subtitle":"Gajah Mina · Enam resonansi","text":"Setelah pelayanan terakhir, gempa membuka Tamansari. Mbah Wira meminta Nala membebaskan Gajah Mina dari pipa dan lapisan asam, bukan melukainya. Tingkatkan tabung dan jala ke level 3 di galangan Beno. Enam resonansi membuka inti ingatan; kembali ke permukaan untuk menyelesaikan pemulihan.","unlocked":stage in ["boss","done"],"icon":"ekosistem"},
		{"title":"Babak 5 · Ingatan yang Kembali","subtitle":"Penutup Fase 1","text":"Gajah Mina tenang dan Prasasti Smara Kuno membuka petunjuk ruang ingatan pada kedalaman 300 meter. Kebun mulai menghijau, warga mengandalkan pengetahuan mereka sendiri, dan gerbang Tamansari menanti perjalanan berikutnya. Hadiah serta prasasti tersimpan di akun.","unlocked":defeated,"icon":"ekosistem"}
	]

static func wake_note(state: Dictionary) -> String:
	var progress: Dictionary = state.get("player",{}).get("progress",{})
	var stage := str(progress.get("stage","dive"))
	var day := int(progress.get("day",1))
	if stage == "boss": return "Babak 4 · Gempa membuka Tamansari. Temui Mbah Wira, siapkan tabung dan jala level 3 bersama Beno, lalu selami penjaga laut."
	if day == 3: return "Babak 3 · Limbah belum berhenti. Selidiki pipa di Jalatunda dan pulihkan penyaring sebelum malam terakhir di kedai."
	if day == 2: return "Babak 2 · Kebun Bu Darmi sekarat. Temui beliau, amati kebun, hutan pesisir, dan hutan lamun sebelum meracik."
	return "Babak 1 · Kumpulkan pengetahuan di Segaran untuk membantu warga di Kedai Waras."

static func _count(haystack: Array,needles: Array) -> int:
	var total := 0
	for needle in needles:
		if haystack.has(needle): total += 1
	return total
