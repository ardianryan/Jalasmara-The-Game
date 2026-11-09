/** Cosmetic local-time activities only; server rewards and progression never trust this clock. */
export const VILLAGE_RESIDENTS = [
  {
    id: "npc_ki_lurah_wirabhumi", name: "Ki Lurah Wirabhumi", title: "Juru Kunci Pasang", appearance: 0, cycle: 1,
    route: [[580, 950], [680, 958]],
    activity: { kind: "tidewatch", startMinute: 480, endMinute: 1050, work: [580, 950], rest: [940, 310], shelter: [940, 310], commute: [[580, 950], [600, 950], [600, 815], [600, 735], [595, 650], [900, 650], [900, 350], [940, 310]] },
    line: "Ukiran di tongkat ini mencatat tinggi pasang. Ingatan boleh berkabut, tetapi pengukuran harus bisa diperiksa kembali. Gunakan tangga desa; tebing bukan jalan pintas.",
    evening: "Lentera sudah menyala. Periksa bekalmu sebelum turun ke palung. Jangan biarkan tuntutan perusahaan membuatmu mengabaikan keselamatan.",
  },
  {
    id: "npc_mbok_ratih", name: "Mbok Ratih", title: "Pedagang Pasar Tambakbaya", appearance: 1, cycle: 1,
    route: [[620, 1030], [710, 1040]],
    activity: { kind: "trading", startMinute: 420, endMinute: 1080, work: [620, 1030], rest: [465, 320], shelter: [465, 320], commute: [[620, 1030], [600, 950], [600, 815], [600, 735], [595, 650], [900, 650], [900, 350], [940, 310], [640, 320], [465, 320]] },
    line: "Berat barang bersama wadah disebut bruto. Kurangi berat wadah, atau tara, untuk mendapatkan netto. Timbangan dacin ini bisa diperiksa bersama pembeli.",
    evening: "Bahan dapur untuk Mbah Wira sudah kutimbang. Catat berat bersihnya supaya racikan malam ini tidak meleset.",
  },
  {
    id: "npc_mang_ujang", name: "Mang Ujang", title: "Nakhoda Bandar Hujung", appearance: 2, cycle: 1,
    route: [[1210, 1250], [1330, 1280]],
    activity: { kind: "fishing", startMinute: 360, endMinute: 1050, work: [900, 1360], rest: [1210, 1250], shelter: [1210, 1250], commute: [[900, 1360], [1120, 1360], [1210, 1250]] },
    line: "Bilik Beno ada sebelum tangga selam. Lewati biliknya untuk memasang tabung dan Jala Kognisi. Perjalanan pulang juga memerlukan oksigen; jangan habiskan semuanya saat mengejar tangkapan.",
    evening: "Permukaan yang tenang belum tentu berarti arus di bawah juga tenang. Lihat arah renik air dan simpan bekal oksigen untuk pulang.",
  },
  {
    id: "npc_kang_tedi", name: "Kang Tedi", title: "Mandor Air Desa", appearance: 3, cycle: 1,
    route: [[1150, 980], [1230, 970]],
    activity: { kind: "pump", startMinute: 450, endMinute: 1050, work: [1150, 980], rest: [1005, 975], shelter: [1005, 975], commute: [[1150, 980], [1005, 975]] },
    line: "Air jernih belum tentu aman diminum. Penyaringan mengurangi partikel, tetapi tidak otomatis menghilangkan zat terlarut dan mikroorganisme. Kita harus memeriksa sumber airnya juga.",
    evening: "Aku mencatat rembesan dari arah pipa perusahaan. Di Rongga Kapur Jalatunda nanti, amati sumber pencemaran sebelum menentukan cara penanganannya.",
  },
  {
    id: "npc_yu_sari", name: "Yu Sari", title: "Penenun Serat Bahari", appearance: 4, cycle: 1,
    route: [[760, 650], [900, 650]],
    activity: { kind: "weaving", startMinute: 480, endMinute: 1020, work: [760, 650], rest: [1325, 300], shelter: [1325, 300], commute: [[760, 650], [900, 650], [900, 350], [940, 310], [1150, 320], [1325, 300]] },
    line: "Serat kususun berpilin agar beban terbagi. Bawa perlengkapan ke Beno untuk peningkatan kemampuan. Baju lapangan dipakai saat masuk hutan; tabung baru dipasang di bilik dermaga.",
    evening: "Kain basah kuangin-anginkan dulu. Menyimpan jala lembap terlalu lama membuat serat cepat rusak.",
  },
  {
    id: "npc_saras", name: "Saras", title: "Arkeolog Maritim", appearance: 5, cycle: 2,
    route: [[1480, 680], [1540, 690]],
    activity: { kind: "research", startMinute: 540, endMinute: 1020, work: [1480, 680], rest: [1020, 310], shelter: [1020, 310], commute: [[1480, 680], [1350, 635], [900, 650], [900, 350], [940, 310], [1020, 310]] },
    line: "Aku sedang membandingkan ukiran batu dengan catatan warga. Jika menemukan prasasti di palung, catat tempat penemuannya. Benda kuno kehilangan banyak cerita jika dipisahkan dari konteksnya.",
    evening: "Mbah Wira mengizinkanku memeriksa catatan di kedai. Gerbang di bawah Tamansari mungkin menyimpan jejak peradaban yang lebih tua dari Bandar Hujung.",
  },
] as const;

/** Work remains outside the planted-bed footprint; watering is cosmetic, never a harvest reward. */
export const VILLAGE_DISTRICT_ACTIVITIES = {
  "Bu Darmi": {
    activity: {
      kind: "gardening", startMinute: 420, endMinute: 1050,
      work: [1720, 520], rest: [1395, 310], shelter: [1395, 310],
      commute: [[1720, 520], [1350, 635], [900, 650], [900, 350], [940, 310], [1150, 320], [1395, 310]],
    },
  },
} as const;
