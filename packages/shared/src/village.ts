/** Dialogue and short workplace routes; rewards remain owned by game services. */
export const VILLAGE_RESIDENTS = [
  {
    id: "npc_ki_lurah_wirabhumi", name: "Ki Lurah Wirabhumi", title: "Juru Kunci Pasang", appearance: 0, cycle: 1,
    route: [[580, 950], [680, 958]],
    line: "Ukiran di tongkat ini mencatat tinggi pasang. Ingatan boleh berkabut, tetapi pengukuran harus bisa diperiksa kembali. Gunakan tangga desa; tebing bukan jalan pintas.",
    evening: "Lentera sudah menyala. Periksa bekalmu sebelum turun ke palung. Jangan biarkan tuntutan perusahaan membuatmu mengabaikan keselamatan.",
  },
  {
    id: "npc_mbok_ratih", name: "Mbok Ratih", title: "Pedagang Pasar Tambakbaya", appearance: 1, cycle: 1,
    route: [[620, 1030], [710, 1040]],
    line: "Berat barang bersama wadah disebut bruto. Kurangi berat wadah, atau tara, untuk mendapatkan netto. Timbangan dacin ini bisa diperiksa bersama pembeli.",
    evening: "Bahan dapur untuk Mbah Wira sudah kutimbang. Catat berat bersihnya supaya racikan malam ini tidak meleset.",
  },
  {
    id: "npc_mang_ujang", name: "Mang Ujang", title: "Nakhoda Bandar Hujung", appearance: 2, cycle: 1,
    route: [[1210, 1250], [1330, 1280]],
    line: "Bilik Beno ada sebelum tangga selam. Lewati biliknya untuk memasang tabung dan Jala Kognisi. Perjalanan pulang juga memerlukan oksigen; jangan habiskan semuanya saat mengejar tangkapan.",
    evening: "Permukaan yang tenang belum tentu berarti arus di bawah juga tenang. Lihat arah renik air dan simpan bekal oksigen untuk pulang.",
  },
  {
    id: "npc_kang_tedi", name: "Kang Tedi", title: "Mandor Air Desa", appearance: 3, cycle: 1,
    route: [[1150, 980], [1230, 970]],
    line: "Air jernih belum tentu aman diminum. Penyaringan mengurangi partikel, tetapi tidak otomatis menghilangkan zat terlarut dan mikroorganisme. Kita harus memeriksa sumber airnya juga.",
    evening: "Aku mencatat rembesan dari arah pipa perusahaan. Di Rongga Kapur Jalatunda nanti, amati sumber pencemaran sebelum menentukan cara penanganannya.",
  },
  {
    id: "npc_yu_sari", name: "Yu Sari", title: "Penenun Serat Bahari", appearance: 4, cycle: 1,
    route: [[760, 650], [900, 650]],
    line: "Serat kususun berpilin agar beban terbagi. Bawa perlengkapan ke Beno untuk peningkatan kemampuan. Baju lapangan dipakai saat masuk hutan; tabung baru dipasang di bilik dermaga.",
    evening: "Kain basah kuangin-anginkan dulu. Menyimpan jala lembap terlalu lama membuat serat cepat rusak.",
  },
  {
    id: "npc_saras", name: "Saras", title: "Arkeolog Maritim", appearance: 5, cycle: 2,
    route: [[1480, 680], [1540, 690]],
    line: "Aku sedang membandingkan ukiran batu dengan catatan warga. Jika menemukan prasasti di palung, catat tempat penemuannya. Benda kuno kehilangan banyak cerita jika dipisahkan dari konteksnya.",
    evening: "Mbah Wira mengizinkanku memeriksa catatan di kedai. Gerbang di bawah Tamansari mungkin menyimpan jejak peradaban yang lebih tua dari Bandar Hujung.",
  },
] as const;
