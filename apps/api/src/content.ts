import { z } from "zod";
import type {
  Catalog,
  Question,
  Subject,
} from "../../../packages/shared/src/index.js";
const id = z.string().regex(/^[a-z][a-z0-9_-]{1,63}$/);
export const questionSchema = z
  .object({
    id,
    subject: z.enum(["Biologi", "Lingkungan", "Matematika", "Kimia"]),
    phase: z.literal(1),
    difficulty: z.number().int().min(1).max(3),
    prompt: z.string().min(8).max(2000),
    options: z.array(z.string().min(1).max(500)).length(4),
    correctIndex: z.number().int().min(0).max(3),
    explanation: z.string().min(10).max(3000),
    source: z.string().url().max(1000),
    timeLimitMs: z.number().int().min(5000).max(180000),
    fragmentId: id,
  })
  .strict();
export const catalogSchema = z
  .object({
    questions: z.array(questionSchema).min(12).max(2000),
    fragments: z
      .array(
        z
          .object({
            id,
            name: z.string().min(2).max(100),
            subject: z.enum(["Biologi", "Lingkungan", "Matematika", "Kimia"]),
            description: z.string().min(5).max(1000),
            weight: z.number().min(0.1).max(10),
          })
          .strict(),
      )
      .min(4)
      .max(100),
    recipes: z
      .array(
        z
          .object({
            id,
            day: z.number().int().min(1).max(3),
            customer: z.string().min(2).max(100),
            complaint: z.string().min(5).max(1000),
            solution: z.string().min(5).max(2000),
            fragmentId: id,
            reward: z.number().int().min(1).max(10000),
          })
          .strict(),
      )
      .min(9)
      .max(100),
    abilities: z
      .array(
        z
          .object({
            id: z.enum(["oxygen", "bag", "speed", "net"]),
            name: z.string().min(2).max(100),
            description: z.string().min(5).max(500),
            prices: z.array(z.number().int().min(1).max(100000)).min(1).max(5),
            values: z.array(z.number().positive().max(1000)).min(2).max(6),
            unit: z.string().max(30),
          })
          .strict(),
      )
      .length(4),
    balance: z
      .object({
        oxygenDrainPerSecond: z.number().min(0.05).max(1),
        wrongPenalty: z.number().min(1).max(30),
        starMultipliers: z.array(z.number().min(0.1).max(5)).length(3),
        bossHits: z.number().int().min(3).max(6),
        bossDamage: z.number().min(1).max(20),
      })
      .strict(),
  })
  .strict()
  .superRefine((c, ctx) => {
    for (const list of [c.questions, c.fragments, c.recipes, c.abilities])
      if (new Set(list.map((x) => x.id)).size !== list.length)
        ctx.addIssue({
          code: "custom",
          message: "ID harus unik dalam setiap kategori.",
        });
    const fragments = new Map(c.fragments.map((f) => [f.id, f]));
    for (const q of c.questions)
      if (fragments.get(q.fragmentId)?.subject !== q.subject)
        ctx.addIssue({
          code: "custom",
          message: `Fragmen soal ${q.id} tidak sesuai mata pelajaran.`,
        });
    for (const r of c.recipes)
      if (!fragments.has(r.fragmentId))
        ctx.addIssue({
          code: "custom",
          message: `Fragmen resep ${r.id} tidak ditemukan.`,
        });
    for (const a of c.abilities)
      if (
        a.values.length !== a.prices.length + 1 ||
        a.values.some((v, i) => i > 0 && v < a.values[i - 1])
      )
        ctx.addIssue({
          code: "custom",
          message: `Level kemampuan ${a.id} tidak berurutan.`,
        });
    if (new Set(c.abilities.map((a) => a.id)).size !== 4)
      ctx.addIssue({
        code: "custom",
        message: "Empat kemampuan wajib tersedia.",
      });
    for (let day = 1; day <= 3; day++)
      if (c.recipes.filter((r) => r.day === day).length !== 3)
        ctx.addIssue({
          code: "custom",
          message: "Setiap hari harus memiliki tepat tiga pelanggan.",
        });
    for (const f of c.fragments)
      if (!c.questions.some((q) => q.fragmentId === f.id))
        ctx.addIssue({
          code: "custom",
          message: `Fragmen ${f.id} tidak memiliki soal.`,
        });
    for (const s of ["Biologi", "Lingkungan", "Matematika", "Kimia"])
      if (c.questions.filter((q) => q.subject === s).length < 3)
        ctx.addIssue({
          code: "custom",
          message: `Minimal tiga soal ${s} diperlukan.`,
        });
  });
type Row = [string, string, string, string, string, string];
const bio: Row[] = [
  [
    "Mengapa daun yang kekurangan magnesium dapat menguning?",
    "Magnesium merupakan bagian dari molekul klorofil",
    "Magnesium mengubah daun menjadi akar",
    "Magnesium menghalangi cahaya",
    "Magnesium adalah sumber karbon tumbuhan",
    "Magnesium merupakan atom pusat klorofil. Kekurangannya dapat mengurangi pembentukan pigmen hijau, meskipun daun kuning juga dapat memiliki penyebab lain.",
  ],
  [
    "Dari mana sebagian besar massa karbon pada tumbuhan berasal?",
    "Karbon dioksida dari udara",
    "Mineral dari tanah",
    "Oksigen dari air",
    "Nitrogen dari pupuk",
    "Karbon dioksida difiksasi melalui fotosintesis menjadi senyawa organik penyusun biomassa.",
  ],
  [
    "Organel apa yang menjadi tempat utama fotosintesis?",
    "Kloroplas",
    "Ribosom",
    "Lisosom",
    "Inti sel",
    "Kloroplas mengandung klorofil dan membran tilakoid untuk reaksi terang serta stroma untuk fiksasi karbon.",
  ],
  [
    "Apa fungsi utama stomata pada daun?",
    "Mengatur pertukaran gas dan kehilangan air",
    "Menyerap seluruh mineral tanah",
    "Menyimpan DNA",
    "Membentuk biji",
    "Stomata memungkinkan CO₂ masuk dan uap air keluar. Sel penjaga mengatur bukaan stomata.",
  ],
  [
    "Mengapa akar membutuhkan oksigen?",
    "Untuk respirasi sel yang menghasilkan ATP",
    "Untuk membuat tanah menjadi basa",
    "Untuk menggantikan semua unsur hara",
    "Untuk menghentikan penyerapan air",
    "Akar menggunakan respirasi aerob untuk menyediakan energi, termasuk bagi transpor aktif ion mineral.",
  ],
  [
    "Apa dampak genangan berkepanjangan pada akar?",
    "Ketersediaan oksigen dapat menurun",
    "Fotosintesis akar pasti meningkat",
    "Seluruh mikroba pasti mati",
    "Akar tidak membutuhkan respirasi lagi",
    "Air mengisi pori tanah sehingga difusi oksigen menuju akar berkurang dan respirasi akar terganggu.",
  ],
  [
    "Unsur apa yang diperlukan untuk menyusun asam amino?",
    "Nitrogen",
    "Helium",
    "Neon",
    "Argon",
    "Asam amino mempunyai gugus amino yang mengandung nitrogen. Tumbuhan memperoleh nitrogen antara lain sebagai nitrat atau amonium.",
  ],
  [
    "Jaringan apa yang terutama mengangkut air dari akar ke daun?",
    "Xilem",
    "Floem",
    "Epidermis",
    "Kambium gabus",
    "Xilem mengangkut air dan mineral, didorong antara lain oleh tarikan transpirasi.",
  ],
  [
    "Jaringan apa yang mengangkut gula hasil fotosintesis?",
    "Floem",
    "Xilem",
    "Kutikula",
    "Tudung akar",
    "Floem mengangkut hasil fotosintesis dari sumber menuju organ yang membutuhkan atau menyimpannya.",
  ],
  [
    "Apa yang terjadi pada enzim jika suhu terlalu tinggi?",
    "Strukturnya dapat berubah sehingga aktivitas menurun",
    "Selalu bekerja semakin cepat tanpa batas",
    "Berubah menjadi klorofil",
    "Tidak pernah terpengaruh suhu",
    "Panas berlebihan dapat mendenaturasi protein enzim dan mengubah bentuk situs aktif.",
  ],
  [
    "Apa fungsi pengurai dalam ekosistem?",
    "Mengembalikan unsur hara dari bahan organik",
    "Menciptakan energi baru",
    "Menghilangkan seluruh karbon",
    "Mengubah semua hewan menjadi produsen",
    "Bakteri dan fungi menguraikan bahan organik dan membantu mendaur ulang unsur hara.",
  ],
  [
    "Mengapa keanekaragaman hayati membantu ketahanan ekosistem?",
    "Beragam spesies dapat menjalankan fungsi yang saling melengkapi",
    "Semua spesies mempunyai peran identik",
    "Tidak ada lagi persaingan",
    "Ekosistem menjadi kebal terhadap semua gangguan",
    "Keragaman fungsi dan respons spesies dapat membantu ekosistem mempertahankan prosesnya saat terganggu.",
  ],
  [
    "Pasangan mana yang merupakan contoh mutualisme?",
    "Karang dan alga fotosintetik simbionnya",
    "Hiu memangsa ikan",
    "Jamur parasit pada daun",
    "Dua tanaman berebut cahaya",
    "Alga memasok hasil fotosintesis sementara karang menyediakan tempat hidup dan nutrien. Hubungan ini dapat terganggu oleh stres lingkungan.",
  ],
  [
    "Apa sumber energi awal utama pada rantai makanan terumbu dangkal?",
    "Cahaya matahari",
    "Predator puncak",
    "Pasir",
    "Garam terlarut",
    "Produsen fotosintetik menangkap energi cahaya dan mengubahnya menjadi energi kimia yang kemudian berpindah melalui jaring makanan.",
  ],
  [
    "Mengapa tanaman layu di tanah yang sangat asin?",
    "Potensial air tanah menurun sehingga penyerapan air terganggu",
    "Garam selalu mempercepat osmosis ke akar",
    "Akar berubah menjadi daun",
    "Klorofil langsung berubah menjadi gula",
    "Konsentrasi zat terlarut tinggi menurunkan potensial air di luar akar, sehingga air sulit diserap atau keluar dari sel.",
  ],
];
const env: Row[] = [
  [
    "Limbah kaya nitrogen dan fosfor paling mungkin memicu apa?",
    "Eutrofikasi",
    "Fotosintesis tanpa cahaya",
    "Pembentukan oksigen tanpa organisme",
    "Hilangnya semua bakteri seketika",
    "Nutrien berlebih dapat memicu ledakan alga. Penguraian biomassa kemudian menghabiskan oksigen terlarut.",
  ],
  [
    "Mengapa ledakan alga dapat menyebabkan ikan mati?",
    "Penguraian biomassa menghabiskan oksigen terlarut",
    "Alga mengubah semua air menjadi minyak",
    "Ikan tidak memerlukan oksigen",
    "Alga selalu menurunkan suhu hingga beku",
    "Respirasi organisme dan penguraian biomassa alga meningkatkan kebutuhan oksigen sehingga kondisi hipoksia dapat terjadi.",
  ],
  [
    "Apa arti BOD yang tinggi pada air?",
    "Banyak oksigen dibutuhkan mikroorganisme untuk menguraikan bahan organik",
    "Air pasti aman diminum",
    "Tidak ada bahan organik",
    "Air tidak mengandung mikroorganisme",
    "Biochemical oxygen demand mengukur kebutuhan oksigen biologis. Nilai tinggi dapat menunjukkan beban bahan organik yang besar.",
  ],
  [
    "Bagaimana arang aktif membantu pengolahan air?",
    "Mengadsorpsi sebagian zat terlarut pada permukaannya",
    "Menjamin hilangnya semua patogen",
    "Mengubah garam menjadi oksigen",
    "Menghilangkan semua logam dengan pasti",
    "Arang aktif memiliki permukaan luas untuk adsorpsi zat tertentu, tetapi bukan jaminan air menjadi layak minum.",
  ],
  [
    "Apa fungsi sedimentasi dalam pengolahan air?",
    "Mengendapkan partikel tersuspensi yang cukup berat",
    "Membunuh seluruh virus",
    "Menghilangkan semua garam terlarut",
    "Menambah nutrien sebanyak mungkin",
    "Sedimentasi menggunakan gravitasi untuk memisahkan partikel tersuspensi sebelum tahap pengolahan lain.",
  ],
  [
    "Mengapa filtrasi pasir saja belum menjamin air layak minum?",
    "Patogen dan zat terlarut tertentu dapat tetap ada",
    "Pasir tidak dapat menahan partikel apa pun",
    "Air selalu menjadi asam kuat",
    "Filtrasi menghilangkan molekul air",
    "Penyaringan mengurangi partikel, tetapi penilaian keamanan memerlukan pengujian serta pengolahan sesuai kontaminannya.",
  ],
  [
    "Apa peran mangrove bagi pesisir?",
    "Menahan sedimen dan menyediakan habitat",
    "Menghilangkan seluruh risiko tsunami",
    "Mengubah air asin menjadi air tawar seketika",
    "Menggantikan semua terumbu karang",
    "Akar mangrove membantu menahan sedimen, mengurangi erosi dalam kondisi tertentu, dan menyediakan habitat asuhan biota.",
  ],
  [
    "Apa yang dimaksud biomagnifikasi?",
    "Konsentrasi polutan tertentu meningkat pada tingkat trofik lebih tinggi",
    "Energi selalu bertambah di setiap tingkat trofik",
    "Semua polutan cepat terurai",
    "Ukuran tubuh semua hewan membesar",
    "Zat persisten yang sulit dikeluarkan dapat terakumulasi melalui makanan dan mencapai konsentrasi tinggi pada predator.",
  ],
  [
    "Apa akibat yang mungkin terjadi jika predator puncak berkurang?",
    "Perubahan populasi dapat merambat melalui jaring makanan",
    "Semua organisme pasti langsung punah",
    "Produsen pasti tidak terpengaruh",
    "Aliran energi berhenti total",
    "Kaskade trofik terjadi ketika perubahan satu tingkat trofik memengaruhi tingkat lain melalui hubungan makan.",
  ],
  [
    "Apa pilihan terbaik untuk mengurangi sampah sekali pakai?",
    "Mengurangi penggunaan sejak sumbernya",
    "Membuangnya ke laut pada malam hari",
    "Membakar semua plastik di ruang tertutup",
    "Memecah plastik menjadi butiran kecil",
    "Mengurangi dari sumber mencegah timbulnya sampah sebelum pengumpulan, penggunaan ulang, dan daur ulang diperlukan.",
  ],
  [
    "Mengapa air hangat lebih berisiko kekurangan oksigen?",
    "Kelarutan oksigen umumnya menurun saat suhu meningkat",
    "Air hangat tidak memiliki molekul",
    "Semua ikan berhenti bernapas",
    "Garam berubah menjadi oksigen",
    "Selain kelarutan oksigen yang menurun, kenaikan suhu dapat meningkatkan kebutuhan metabolik organisme.",
  ],
  [
    "Apa arti indikator pH 7 pada air murni sekitar 25 °C?",
    "Netral",
    "Asam kuat",
    "Basa kuat",
    "Tidak memiliki ion sama sekali",
    "Pada sekitar 25 °C, air netral memiliki aktivitas ion hidrogen dan hidroksida yang seimbang, dengan pH sekitar 7.",
  ],
  [
    "Mengapa limbah industri tidak boleh dinetralkan sembarangan?",
    "Komposisi dan reaksi samping perlu diketahui terlebih dahulu",
    "Semua limbah hanya mengandung air",
    "Semua campuran pasti aman",
    "Warna saja menentukan dosis",
    "Pengolahan membutuhkan identifikasi kontaminan, pengukuran, dan prosedur aman; pencampuran sembarang dapat menghasilkan panas atau gas berbahaya.",
  ],
  [
    "Apa manfaat rotasi tanaman dengan legum tertentu?",
    "Dapat membantu pasokan nitrogen melalui bakteri simbion",
    "Selalu menggantikan seluruh pupuk dan air",
    "Membunuh semua organisme tanah",
    "Menghilangkan kebutuhan cahaya",
    "Bakteri penambat nitrogen pada bintil akar legum dapat berkontribusi pada siklus nitrogen, bergantung kondisi dan pengelolaan.",
  ],
  [
    "Apa yang membedakan jaring makanan dari rantai makanan?",
    "Jaring makanan menghubungkan banyak jalur makan",
    "Jaring makanan hanya memuat satu spesies",
    "Rantai makanan tidak memiliki produsen",
    "Jaring makanan tidak melibatkan energi",
    "Jaring makanan menggambarkan hubungan makan yang bercabang dan saling terhubung di dalam ekosistem.",
  ],
];
const math: Row[] = [
  [
    "Tangki berisi 120 L air. Sebanyak 25% digunakan. Berapa sisanya?",
    "90 L",
    "30 L",
    "95 L",
    "100 L",
    "Air yang digunakan = 0,25 × 120 = 30 L. Sisanya 120 − 30 = 90 L.",
  ],
  [
    "Tiga pompa identik mengalirkan total 18 L/menit. Berapa debit satu pompa?",
    "6 L/menit",
    "54 L/menit",
    "15 L/menit",
    "9 L/menit",
    "Dengan debit sama, debit tiap pompa = 18 ÷ 3 = 6 L/menit.",
  ],
  [
    "Larutan model memakai perbandingan bahan A:B = 2:3. Jika A = 8 mL, berapa B?",
    "12 mL",
    "10 mL",
    "6 mL",
    "24 mL",
    "Faktor pengali = 8 ÷ 2 = 4. Volume B = 3 × 4 = 12 mL. Ini model matematika, bukan petunjuk mencampur limbah nyata.",
  ],
  [
    "Pada peta skala 1:200, panjang 4 cm mewakili berapa meter?",
    "8 m",
    "0,8 m",
    "80 m",
    "800 m",
    "Panjang sebenarnya = 4 × 200 = 800 cm = 8 m.",
  ],
  [
    "Data oksigen terlarut adalah 4, 6, dan 8 mg/L. Berapa rata-ratanya?",
    "6 mg/L",
    "18 mg/L",
    "4 mg/L",
    "8 mg/L",
    "Rata-rata = (4 + 6 + 8) ÷ 3 = 6 mg/L.",
  ],
  [
    "Kotak berukuran 2 m × 1,5 m × 1 m mempunyai volume berapa?",
    "3 m³",
    "4,5 m³",
    "1,5 m³",
    "5 m³",
    "Volume balok = panjang × lebar × tinggi = 2 × 1,5 × 1 = 3 m³.",
  ],
  [
    "Satu meter kubik air setara dengan berapa liter?",
    "1.000 L",
    "100 L",
    "10 L",
    "10.000 L",
    "Satu liter sama dengan satu desimeter kubik. Karena 1 m = 10 dm, maka 1 m³ = 1.000 dm³ = 1.000 L.",
  ],
  [
    "Biaya bahan 40 koin dan harga jual 65 koin. Berapa laba sebelum biaya lain?",
    "25 koin",
    "105 koin",
    "40 koin",
    "65 koin",
    "Laba kotor per unit = harga jual − biaya bahan = 65 − 40 = 25 koin; biaya lain belum diperhitungkan.",
  ],
  [
    "Harga naik dari 80 menjadi 100 koin. Berapa persentase kenaikannya?",
    "25%",
    "20%",
    "80%",
    "125%",
    "Kenaikan = 20 koin. Persentase terhadap harga awal = 20 ÷ 80 × 100% = 25%.",
  ],
  [
    "Pompa mengisi 150 L dalam 5 menit. Berapa debit rata-ratanya?",
    "30 L/menit",
    "750 L/menit",
    "15 L/menit",
    "5 L/menit",
    "Debit rata-rata = volume ÷ waktu = 150 ÷ 5 = 30 L/menit.",
  ],
  [
    "Peluang mengambil satu fragmen biru dari 3 biru dan 2 hijau adalah?",
    "3/5",
    "2/3",
    "1/3",
    "3/2",
    "Ada lima fragmen dengan peluang sama, tiga di antaranya biru. Peluangnya 3 ÷ 5.",
  ],
  [
    "Median data 2, 3, 5, 7, 18 adalah?",
    "5",
    "7",
    "18",
    "35",
    "Pada lima data yang telah diurutkan, median adalah data ketiga, yaitu 5.",
  ],
  [
    "Jika 2x + 6 = 20, berapa x?",
    "7",
    "13",
    "10",
    "14",
    "Kurangi kedua ruas dengan 6 sehingga 2x = 14, lalu bagi dua: x = 7.",
  ],
  [
    "Sebuah jala menangkap 12 fragmen dalam 4 menit. Pada laju tetap, berapa dalam 7 menit?",
    "21 fragmen",
    "28 fragmen",
    "19 fragmen",
    "48 fragmen",
    "Laju = 12 ÷ 4 = 3 fragmen per menit. Dalam 7 menit diperoleh 3 × 7 = 21 fragmen.",
  ],
  [
    "Saringan menurunkan partikel dari 200 menjadi 50 mg/L. Berapa persen penurunannya?",
    "75%",
    "25%",
    "150%",
    "50%",
    "Penurunan = 150 mg/L. Persentase terhadap nilai awal = 150 ÷ 200 × 100% = 75%.",
  ],
];
const chem: Row[] = [
  [
    "Dalam model larutan encer, reaksi H⁺ + OH⁻ menghasilkan apa?",
    "H₂O",
    "CO₂",
    "NaCl tanpa ion lain",
    "O₂",
    "Ion hidrogen dan hidroksida membentuk air. Persamaan ini adalah bentuk ionik sederhana netralisasi asam-basa.",
  ],
  [
    "Apa yang terjadi pada pH jika konsentrasi H⁺ naik sepuluh kali?",
    "pH turun satu unit",
    "pH naik satu unit",
    "pH tetap",
    "pH naik sepuluh unit",
    "pH = −log₁₀ aktivitas H⁺. Pada pendekatan larutan encer, kenaikan konsentrasi sepuluh kali menurunkan pH sekitar satu unit.",
  ],
  [
    "Larutan pH 3 dibanding pH 5 memiliki konsentrasi H⁺ kira-kira berapa kali?",
    "100 kali",
    "2 kali",
    "10 kali",
    "1/100 kali",
    "Selisih dua unit pH berarti faktor 10² = 100 pada pendekatan aktivitas dengan konsentrasi larutan encer.",
  ],
  [
    "Apa sifat umum larutan asam dalam air?",
    "Dapat meningkatkan konsentrasi ion hidronium",
    "Selalu aman disentuh",
    "Selalu berwarna merah",
    "Tidak dapat bereaksi dengan basa",
    "Menurut pendekatan Arrhenius, asam meningkatkan konsentrasi ion hidronium dalam air. Warna dan keamanan tidak ditentukan hanya oleh keasaman.",
  ],
  [
    "Mengapa netralisasi dapat meningkatkan suhu?",
    "Banyak reaksi netralisasi melepaskan kalor",
    "Semua reaksi menyerap seluruh kalor",
    "Air berubah menjadi logam",
    "pH tidak berhubungan dengan reaksi",
    "Netralisasi asam kuat dan basa kuat umumnya eksoterm. Karena itu pencampuran memerlukan kontrol dan prosedur keselamatan.",
  ],
  [
    "Apa arti konsentrasi 0,1 mol/L?",
    "Terdapat 0,1 mol zat terlarut per liter larutan",
    "Terdapat 1 mol per mililiter",
    "Larutan pasti netral",
    "Semua zat terlarut berbentuk padat",
    "Molaritas menyatakan jumlah mol zat terlarut dibagi volume larutan dalam liter.",
  ],
  [
    "Berapa mol zat dalam 0,5 L larutan 0,2 mol/L?",
    "0,1 mol",
    "0,4 mol",
    "2,5 mol",
    "1 mol",
    "Jumlah mol n = M × V = 0,2 × 0,5 = 0,1 mol.",
  ],
  [
    "Pada model HCl + NaOH → NaCl + H₂O, perbandingan mol asam:basa adalah?",
    "1:1",
    "1:2",
    "2:1",
    "3:1",
    "Koefisien reaksi setara menunjukkan satu mol HCl bereaksi dengan satu mol NaOH.",
  ],
  [
    "Apa fungsi indikator asam-basa?",
    "Memberi perubahan warna pada rentang pH tertentu",
    "Mendeteksi semua racun",
    "Menghilangkan seluruh asam",
    "Menentukan semua unsur logam",
    "Indikator berubah struktur dan warna dalam rentang pH tertentu; indikator bukan pengujian lengkap keamanan air.",
  ],
  [
    "Mengapa air pH netral belum tentu aman diminum?",
    "Dapat mengandung patogen atau kontaminan lain",
    "pH netral berarti tidak mengandung air",
    "Semua logam hilang pada pH 7",
    "Virus hanya hidup pada asam kuat",
    "pH hanya satu parameter. Kontaminan mikrobiologis dan kimia dapat ada pada air dengan pH mendekati netral.",
  ],
  [
    "Apa yang dimaksud pengenceran larutan?",
    "Menambah pelarut sehingga konsentrasi turun",
    "Menghilangkan semua zat terlarut",
    "Selalu mengubah jenis zat",
    "Menambah zat terlarut tanpa pelarut",
    "Jika jumlah zat terlarut tetap dan volume bertambah, konsentrasi menurun. Pengenceran tidak otomatis menetralkan limbah.",
  ],
  [
    "Jika volume larutan digandakan tanpa perubahan mol zat, konsentrasinya menjadi?",
    "Setengah semula",
    "Dua kali semula",
    "Empat kali semula",
    "Tetap selalu",
    "Dari M = n/V, volume dua kali dengan n tetap menghasilkan molaritas setengah nilai awal.",
  ],
  [
    "Apa contoh perubahan kimia?",
    "Besi berkarat",
    "Es mencair",
    "Air membeku",
    "Garam larut tanpa reaksi lanjut",
    "Perkaratan menghasilkan zat baru melalui reaksi oksidasi besi, sedangkan perubahan wujud merupakan perubahan fisika.",
  ],
  [
    "Apa yang dimaksud larutan penyangga?",
    "Larutan yang menahan perubahan pH akibat sedikit asam atau basa",
    "Larutan yang tidak mengandung ion",
    "Larutan yang selalu pH 7",
    "Larutan yang dapat menetralkan semua limbah tanpa batas",
    "Penyangga mengandung pasangan asam-basa konjugat yang membantu menahan perubahan pH, dengan kapasitas yang terbatas.",
  ],
  [
    "Mengapa dosis penetral pada limbah nyata perlu uji laboratorium?",
    "Jenis kontaminan, kapasitas penyangga, dan reaksi samping dapat berbeda",
    "Warna selalu menunjukkan jumlah mol",
    "Semua limbah setara HCl murni",
    "pH mengukur semua racun sekaligus",
    "Model stoikiometri sederhana tidak mewakili seluruh campuran limbah. Karakterisasi dan uji terkontrol diperlukan untuk menentukan penanganan.",
  ],
];
const sources: Record<Subject, string> = {
  Biologi: "https://openstax.org/details/books/biology-2e",
  Lingkungan: "https://openstax.org/details/books/biology-2e",
  Matematika: "https://openstax.org/details/books/prealgebra-2e",
  Kimia: "https://openstax.org/details/books/chemistry-2e",
};
export function seedCatalog(): Catalog {
  const questions: Question[] = [];
  for (const [subject, rows, fragmentId] of [
    ["Biologi", bio, "klorofil"],
    ["Lingkungan", env, "ekosistem"],
    ["Matematika", math, "rasio"],
    ["Kimia", chem, "netralisasi"],
  ] as [Subject, Row[], string][])
    rows.forEach((r, i) => {
      const offset = i % 4,
        options = r.slice(1, 5);
      for (let j = 0; j < offset; j++) options.unshift(options.pop()!);
      questions.push({
        id: `${fragmentId}_${String(i + 1).padStart(2, "0")}`,
        subject,
        phase: 1,
        difficulty: i < 5 ? 1 : i < 10 ? 2 : 3,
        prompt: r[0],
        options,
        correctIndex: offset,
        explanation: r[5],
        source: sources[subject],
        timeLimitMs:
          subject === "Matematika" ||
          (subject === "Kimia" && [2, 6, 7, 11].includes(i))
            ? 45000
            : 15000,
        fragmentId,
      });
    });
  return catalogSchema.parse({
    questions,
    fragments: [
      {
        id: "klorofil",
        name: "Benih Hayati",
        subject: "Biologi",
        description:
          "Ingatan tentang tumbuhan, sel, dan kehidupan yang saling menopang.",
        weight: 1,
      },
      {
        id: "ekosistem",
        name: "Simpul Ekosistem",
        subject: "Lingkungan",
        description:
          "Ingatan tentang air, rantai makanan, dan keseimbangan pesisir.",
        weight: 1,
      },
      {
        id: "rasio",
        name: "Pola Bilangan",
        subject: "Matematika",
        description:
          "Ingatan tentang ukuran, perbandingan, dan perhitungan sehari-hari.",
        weight: 1,
      },
      {
        id: "netralisasi",
        name: "Inti Senyawa",
        subject: "Kimia",
        description:
          "Ingatan tentang larutan dan reaksi kimia yang perlu dipahami dengan hati-hati.",
        weight: 1,
      },
    ],
    recipes: [
      {
        id: "daun_kuning",
        day: 1,
        customer: "Bu Darmi",
        complaint:
          "Daun kebun apung saya menguning. Saya lupa apa yang dibutuhkan tanaman.",
        solution:
          "Periksa akar, cahaya, air, dan unsur hara sebelum menambah pupuk. Daun kuning dapat memiliki beberapa penyebab.",
        fragmentId: "klorofil",
        reward: 100,
      },
      {
        id: "air_keruh",
        day: 1,
        customer: "Pak Jaya",
        complaint:
          "Air penampungan kami keruh. Apakah disaring saja sudah cukup?",
        solution:
          "Pengendapan dan filtrasi membantu mengurangi partikel. Keamanan air tetap membutuhkan pengujian dan pengolahan sesuai kontaminannya.",
        fragmentId: "ekosistem",
        reward: 100,
      },
      {
        id: "takaran",
        day: 1,
        customer: "Beno",
        complaint:
          "Saya butuh menghitung perbandingan bahan untuk wadah penyaring.",
        solution:
          "Gunakan rasio yang sama pada setiap bagian dan periksa kembali satuannya.",
        fragmentId: "rasio",
        reward: 100,
      },
      {
        id: "akar",
        day: 2,
        customer: "Bu Darmi",
        complaint: "Akar di kebun terus terendam. Mengapa tanaman tetap layu?",
        solution:
          "Akar membutuhkan oksigen untuk respirasi. Perbaiki aerasi dan pengelolaan air agar pori media tidak selalu tergenang.",
        fragmentId: "klorofil",
        reward: 120,
      },
      {
        id: "alga",
        day: 2,
        customer: "Pak Jaya",
        complaint: "Alga memenuhi teluk dan ikan mulai kekurangan napas.",
        solution:
          "Kurangi sumber nutrien pencemar. Ledakan alga dan penguraiannya dapat menghabiskan oksigen terlarut.",
        fragmentId: "ekosistem",
        reward: 120,
      },
      {
        id: "pompa",
        day: 2,
        customer: "Beno",
        complaint:
          "Pompa warga harus mengisi tangki tanpa menghabiskan energi.",
        solution:
          "Hitung debit sebagai volume per waktu, lalu sesuaikan waktu operasi dengan kapasitas tangki.",
        fragmentId: "rasio",
        reward: 120,
      },
      {
        id: "kebun_baru",
        day: 3,
        customer: "Bu Darmi",
        complaint:
          "Bagaimana kebun kami bisa lebih tahan setelah pencemaran ini?",
        solution:
          "Pelihara keragaman tanaman, kondisi media, dan siklus unsur hara. Pantau tanaman secara berkala.",
        fragmentId: "klorofil",
        reward: 150,
      },
      {
        id: "rantai",
        day: 3,
        customer: "Saras",
        complaint:
          "Hilangnya predator ternyata mengubah seluruh teluk. Bagaimana menjelaskannya?",
        solution:
          "Perubahan populasi dapat merambat dalam jaring makanan. Pemulihan perlu mempertimbangkan hubungan antarspesies.",
        fragmentId: "ekosistem",
        reward: 150,
      },
      {
        id: "logistik",
        day: 3,
        customer: "Beno",
        complaint:
          "Kita harus menghitung bekal sebelum turun ke sumber limbah.",
        solution:
          "Pisahkan kapasitas, laju pemakaian, dan cadangan. Pastikan satuan konsisten sebelum menghitung durasi.",
        fragmentId: "rasio",
        reward: 150,
      },
    ],
    abilities: [
      {
        id: "oxygen",
        name: "Tabung napas",
        description:
          "Lebih banyak cadangan oksigen untuk mencapai sumber limbah.",
        prices: [150, 300, 500],
        values: [100, 140, 180, 220],
        unit: "O₂",
      },
      {
        id: "bag",
        name: "Tas fragmen",
        description: "Membawa lebih banyak ingatan dari satu penyelaman.",
        prices: [120, 250, 400],
        values: [12, 16, 20, 24],
        unit: "kg",
      },
      {
        id: "speed",
        name: "Sirip arus",
        description: "Berenang lebih cepat di antara terumbu.",
        prices: [120, 250, 400],
        values: [110, 135, 160, 185],
        unit: "px/detik",
      },
      {
        id: "net",
        name: "Jala Kognisi",
        description: "Menjangkau fragmen dari jarak yang lebih jauh.",
        prices: [120, 250, 400],
        values: [65, 85, 105, 125],
        unit: "px",
      },
    ],
    balance: {
      oxygenDrainPerSecond: 0.18,
      wrongPenalty: 8,
      starMultipliers: [0.6, 1, 1.4],
      bossHits: 6,
      bossDamage: 4,
    },
  });
}
