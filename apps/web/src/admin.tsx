import { useEffect, useState, type FormEvent } from "react";
import type {
  Catalog,
  ContentVersion,
  Player,
} from "../../../packages/shared/src/index";
import {
  freshAbilities,
  freshProgress,
} from "../../../packages/shared/src/index";
import { api, fmt, type AuthState } from "./api";
import { Dialog, Notice } from "./components";
const actions: Record<string, string> = {
  coins: "Saldo koin",
  inventory: "Inventori fragmen",
  ability: "Alat dan kemampuan",
  progress: "Progres cerita",
  reset: "Reset permainan",
  block: "Blokir akses",
  unblock: "Buka akses",
  revoke: "Cabut semua sesi",
  role: "Ubah peran",
};
const labels: Record<string, string> = {
  id: "ID",
  subject: "Mata pelajaran",
  phase: "Fase",
  difficulty: "Kesulitan",
  prompt: "Pertanyaan",
  correctIndex: "Jawaban benar (indeks mulai 0)",
  explanation: "Penjelasan",
  source: "URL sumber",
  timeLimitMs: "Batas tiga bintang (ms)",
  fragmentId: "ID fragmen",
  name: "Nama",
  description: "Deskripsi",
  weight: "Bobot (kg)",
  day: "Hari",
  customer: "Pelanggan",
  complaint: "Keluhan",
  solution: "Solusi",
  reward: "Hadiah dasar (koin)",
  prices: "Harga per level (array JSON)",
  values: "Nilai tiap level (array JSON)",
  unit: "Satuan",
  oxygenDrainPerSecond: "Pemakaian oksigen per detik",
  wrongPenalty: "Penalti jawaban salah",
  starMultipliers: "Pengali bintang 1–3 (array JSON)",
  bossHits: "Jumlah perisai boss",
  bossDamage: "Kerusakan serangan boss",
};
function EditFields({
  value,
  onChange,
  disabled = false,
}: {
  value: Record<string, any>;
  onChange: (v: Record<string, any>) => void;
  disabled?: boolean;
}) {
  return (
    <div className="fields-grid">
      {Object.entries(value).map(([key, v]) =>
        key === "options" ? (
          <fieldset key={key}>
            <legend>Pilihan jawaban</legend>
            {v.map((option: string, i: number) => (
              <label key={i}>
                Pilihan {String.fromCharCode(65 + i)}
                <input
                  disabled={disabled}
                  value={option}
                  onChange={(e) => {
                    const options = [...v];
                    options[i] = e.target.value;
                    onChange({ ...value, options });
                  }}
                />
              </label>
            ))}
          </fieldset>
        ) : Array.isArray(v) ? (
          <label key={key}>
            {labels[key] ?? key}
            <input
              disabled={disabled}
              key={`${key}:${JSON.stringify(v)}`}
              defaultValue={JSON.stringify(v)}
              onBlur={(e) => {
                try {
                  const parsed = JSON.parse(e.target.value);
                  if (!Array.isArray(parsed)) throw Error();
                  onChange({ ...value, [key]: parsed });
                  e.target.setCustomValidity("");
                } catch {
                  e.target.setCustomValidity(
                    "Vektor JSON diperlukan, contoh [100,140,180].",
                  );
                  e.target.reportValidity();
                }
              }}
            />
          </label>
        ) : key === "subject" ? (
          <label key={key}>
            Mata pelajaran
            <select
              disabled={disabled}
              value={v}
              onChange={(e) => onChange({ ...value, [key]: e.target.value })}
            >
              {["Biologi", "Lingkungan", "Matematika", "Kimia"].map((s) => (
                <option key={s}>{s}</option>
              ))}
            </select>
          </label>
        ) : (
          <label
            key={key}
            className={
              typeof v === "string" && v.length > 100 ? "span-two" : ""
            }
          >
            {labels[key] ?? key}
            {typeof v === "number" ? (
              <input
                disabled={disabled}
                type="number"
                step="any"
                value={v}
                onChange={(e) =>
                  onChange({ ...value, [key]: Number(e.target.value) })
                }
              />
            ) : [
                "prompt",
                "explanation",
                "description",
                "complaint",
                "solution",
              ].includes(key) ? (
              <textarea
                aria-label={labels[key] ?? key}
                disabled={disabled}
                value={v}
                rows={3}
                onChange={(e) => onChange({ ...value, [key]: e.target.value })}
              />
            ) : (
              <input
                aria-label={labels[key] ?? key}
                disabled={disabled}
                value={v}
                onChange={(e) => onChange({ ...value, [key]: e.target.value })}
              />
            )}
          </label>
        ),
      )}
    </div>
  );
}
export function Admin({ auth }: { auth: AuthState }) {
  const [tab, setTab] = useState("players"),
    [error, setError] = useState(""),
    [notice, setNotice] = useState(""),
    [busy, setBusy] = useState(false),
    [players, setPlayers] = useState<Player[]>([]),
    [total, setTotal] = useState(0),
    [page, setPage] = useState(1),
    [search, setSearch] = useState(""),
    [status, setStatus] = useState("all"),
    [detail, setDetail] = useState<any>(),
    [catalog, setCatalog] = useState<Omit<Catalog, "questions">>(),
    [audit, setAudit] = useState<any[]>([]),
    [auditTotal, setAuditTotal] = useState(0),
    [auditPage, setAuditPage] = useState(1),
    [versions, setVersions] = useState<any[]>([]),
    [content, setContent] = useState<ContentVersion>(),
    [hash, setHash] = useState(""),
    [dirty, setDirty] = useState(false),
    [category, setCategory] = useState<keyof Catalog>("questions"),
    [record, setRecord] = useState(0),
    [reason, setReason] = useState(""),
    [action, setAction] = useState("coins"),
    [mode, setMode] = useState("add"),
    [amount, setAmount] = useState(100),
    [fragmentId, setFragment] = useState("klorofil"),
    [stars, setStars] = useState(3),
    [ability, setAbility] = useState("oxygen"),
    [level, setLevel] = useState(1),
    [progress, setProgress] = useState(freshProgress()),
    [role, setRole] = useState("player"),
    [pending, setPending] = useState<any>(),
    [invite, setInvite] = useState(false),
    [inviteEmail, setInviteEmail] = useState(""),
    [oneTimeLink, setOneTimeLink] = useState(""),
    [reauth, setReauth] = useState(""),
    [password, setPassword] = useState("");
  const owner = auth.user!.role === "owner";
  async function run(fn: () => Promise<void>) {
    setBusy(true);
    setError("");
    try {
      await fn();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }
  async function loadPlayers() {
    const r = await api(
      `/admin/players?search=${encodeURIComponent(search)}&status=${status}&page=${page}`,
    );
    setPlayers(r.players);
    setTotal(r.total);
  }
  async function loadVersions() {
    setVersions((await api("/admin/content")).versions);
  }
  async function loadAudit() {
    const r = await api(`/admin/audit?page=${auditPage}`);
    setAudit(r.audits);
    setAuditTotal(r.total);
  }
  useEffect(() => {
    void run(async () => {
      setCatalog((await api("/game/state")).catalog);
      await loadPlayers();
      await loadVersions();
    });
  }, []);
  useEffect(() => {
    void run(loadPlayers);
  }, [page, status]);
  useEffect(() => {
    if (tab === "audit") void run(loadAudit);
  }, [tab, auditPage]);
  async function openPlayer(id: string) {
    await run(async () => {
      const r = await api(`/admin/players/${id}`);
      setDetail(r);
      setProgress(r.player.progress);
      setReason("");
      setAction("coins");
    });
  }
  function preview(e: FormEvent) {
    e.preventDefault();
    const p = detail.player as Player;
    const b: any = { version: p.version, reason, action };
    let after: any;
    if (action === "coins") {
      Object.assign(b, { mode, amount });
      after = {
        coins:
          mode === "set"
            ? amount
            : mode === "add"
              ? p.coins + amount
              : p.coins - amount,
      };
    } else if (action === "inventory") {
      Object.assign(b, { mode, amount, fragmentId, stars });
      const old =
        p.inventory.find(
          (x) => x.fragmentId === fragmentId && x.stars === stars,
        )?.quantity ?? 0;
      after = {
        fragmentId,
        stars,
        quantity:
          mode === "set"
            ? amount
            : mode === "add"
              ? old + amount
              : old - amount,
      };
    } else if (action === "ability") {
      Object.assign(b, { ability, level });
      after = { ...p.abilities, [ability]: level };
    } else if (action === "progress") {
      b.progress = progress;
      after = progress;
    } else if (action === "reset")
      after = {
        coins: 0,
        inventory: [],
        abilities: freshAbilities(),
        progress: freshProgress(),
      };
    else if (action === "role") {
      b.role = role;
      after = { role };
    } else
      after = {
        status:
          action === "block"
            ? "blocked"
            : action === "unblock"
              ? "active"
              : p.status,
        sessions: "dicabut",
      };
    setPending({ body: b, after });
  }
  async function apply() {
    await run(async () => {
      const r = await api(
        `/admin/players/${detail.player.id}/change`,
        pending.body,
      );
      setPending(undefined);
      setDetail({ ...detail, player: r.player });
      setNotice(
        "Perubahan disimpan bersama audit. Sesi permainan sebelumnya dibatalkan.",
      );
      await loadPlayers();
      setDetail(await api(`/admin/players/${r.player.id}`));
    });
  }
  async function openContent(id: string) {
    await run(async () => {
      const r = await api(`/admin/content/${id}`);
      setContent(r.content);
      setHash(r.hash);
      setDirty(false);
      setRecord(0);
      setReason("");
    });
  }
  const editable = content?.state === "draft";
  const rows =
    content && category !== "balance"
      ? (content.catalog[category] as any[])
      : [];
  const current = content
    ? category === "balance"
      ? content.catalog.balance
      : rows[record]
    : undefined;
  function editRecord(v: any) {
    if (!content) return;
    const next = structuredClone(content);
    if (category === "balance") next.catalog.balance = v;
    else (next.catalog[category] as any[])[record] = v;
    setContent(next);
    setDirty(true);
  }
  function addRecord() {
    if (!content) return;
    const next = structuredClone(content),
      id = `baru_${crypto.randomUUID().slice(0, 8)}`;
    let value: any;
    if (category === "questions")
      value = {
        id,
        subject: "Biologi",
        phase: 1,
        difficulty: 1,
        prompt: "Tuliskan pertanyaan baru di sini.",
        options: ["Pilihan A", "Pilihan B", "Pilihan C", "Pilihan D"],
        correctIndex: 0,
        explanation: "Tuliskan penjelasan jawaban di sini.",
        source: "https://openstax.org/details/books/biology-2e",
        timeLimitMs: 15000,
        fragmentId: "klorofil",
      };
    else if (category === "fragments")
      value = {
        id,
        name: "Fragmen baru",
        subject: "Biologi",
        description: "Deskripsi pengetahuan fragmen.",
        weight: 1,
      };
    else if (category === "recipes")
      value = {
        id,
        day: 1,
        customer: "Pelanggan baru",
        complaint: "Tuliskan keluhan pelanggan.",
        solution: "Tuliskan solusi berbasis pengetahuan.",
        fragmentId: "klorofil",
        reward: 100,
      };
    else return;
    const arr = next.catalog[category] as any[];
    arr.push(value);
    setRecord(arr.length - 1);
    setContent(next);
    setDirty(true);
  }
  async function saveContent() {
    await run(async () => {
      const r = await api(
        `/admin/content/${content!.id}`,
        { catalog: content!.catalog, hash, reason },
        "PUT",
      );
      setContent(r.content);
      setHash(r.hash);
      setDirty(false);
      setNotice("Draft disimpan. Tinjau sebelum publikasi.");
    });
  }
  function exportQuestions() {
    const blob = new Blob(
        [JSON.stringify(content!.catalog.questions, null, 2)],
        { type: "application/json" },
      ),
      url = URL.createObjectURL(blob),
      a = document.createElement("a");
    a.href = url;
    a.download = "jalasmara-soal.json";
    a.click();
    URL.revokeObjectURL(url);
  }
  async function importQuestions(file: File) {
    await run(async () => {
      if (file.size > 1500000) throw new Error("Berkas maksimal 1,5 MB.");
      const parsed = JSON.parse(await file.text()),
        r = await api("/admin/questions/validate", parsed);
      if (
        !confirm(
          `${r.count} soal valid. Ganti bank soal draft lokal untuk ditinjau?`,
        )
      )
        return;
      setContent((c) => ({
        ...c!,
        catalog: { ...c!.catalog, questions: r.questions },
      }));
      setDirty(true);
      setRecord(0);
      setNotice(
        "Impor masuk ke draft lokal. Simpan dan publikasikan setelah peninjauan.",
      );
    });
  }
  return (
    <div className="admin-layout">
      <aside className="admin-nav">
        <p>Ruang pengelola</p>
        <span>
          {auth.user!.name}
          <small>{auth.user!.role}</small>
        </span>
        <nav aria-label="Navigasi pengelola">
          {[
            ["players", "Pemain"],
            ["content", "Konten permainan"],
            ["audit", "Jejak audit"],
          ].map(([id, label]) => (
            <button
              key={id}
              aria-current={tab === id ? "page" : undefined}
              onClick={() => {
                setTab(id);
                setDetail(undefined);
                setContent(undefined);
                setNotice("");
              }}
            >
              {label}
            </button>
          ))}
        </nav>
        <p className="admin-nav-note">
          Setiap perubahan pemain memerlukan alasan dan tercatat dalam audit.
        </p>
      </aside>
      <main className="admin-sheet" data-ui>
        {error && <Notice error>{error}</Notice>}
        {notice && <Notice>{notice}</Notice>}
        {tab === "players" && !detail && (
          <>
            <div className="section-heading">
              <div>
                <h1>Pemain</h1>
                <p>
                  {total} akun · Kelola akses dan perjalanan di Palung Smara.
                </p>
              </div>
              {owner && (
                <button
                  className="primary"
                  onClick={() => {
                    setInvite(true);
                    setReason("");
                  }}
                >
                  Undang pemain
                </button>
              )}
            </div>
            <form
              className="filter-bar"
              onSubmit={(e) => {
                e.preventDefault();
                setPage(1);
                void run(loadPlayers);
              }}
            >
              <label>
                Cari nama atau email
                <input
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Nama atau email pemain"
                />
              </label>
              <label>
                Status
                <select
                  value={status}
                  onChange={(e) => {
                    setPage(1);
                    setStatus(e.target.value);
                  }}
                >
                  <option value="all">Semua</option>
                  <option value="active">Aktif</option>
                  <option value="blocked">Diblokir</option>
                </select>
              </label>
              <button disabled={busy}>Cari</button>
            </form>
            <div className="table-scroll">
              <table>
                <thead>
                  <tr>
                    <th>Pemain</th>
                    <th>Peran</th>
                    <th>Perjalanan</th>
                    <th className="numeric">Koin</th>
                    <th>Status</th>
                    <th>Aksi</th>
                  </tr>
                </thead>
                <tbody>
                  {players.map((p) => (
                    <tr key={p.id}>
                      <td>
                        <strong>{p.name}</strong>
                        <small>{p.email}</small>
                      </td>
                      <td>{p.role}</td>
                      <td>
                        Hari {p.progress.day} · {p.progress.stage}
                      </td>
                      <td className="numeric">{fmt(p.coins)}</td>
                      <td>{p.status === "active" ? "Aktif" : "Diblokir"}</td>
                      <td>
                        <button
                          className="quiet"
                          onClick={() => void openPlayer(p.id)}
                        >
                          Kelola
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            {!players.length && (
              <Notice>Tidak ada pemain yang cocok dengan pencarian.</Notice>
            )}
            <div className="pagination">
              <button
                disabled={busy || page === 1}
                onClick={() => setPage((x) => x - 1)}
              >
                Sebelumnya
              </button>
              <span>Halaman {page}</span>
              <button
                disabled={busy || page * 20 >= total}
                onClick={() => setPage((x) => x + 1)}
              >
                Berikutnya
              </button>
            </div>
          </>
        )}
        {tab === "players" && detail && (
          <>
            <button className="quiet back" onClick={() => setDetail(undefined)}>
              Kembali ke pemain
            </button>
            <div className="section-heading">
              <div>
                <h1>{detail.player.name}</h1>
                <p>
                  {detail.player.email} · {detail.player.role} · versi{" "}
                  {detail.player.version}
                </p>
              </div>
              <button
                disabled={busy}
                onClick={() => void openPlayer(detail.player.id)}
              >
                Muat ulang
              </button>
            </div>
            <div className="player-summary">
              <div>
                <strong>{fmt(detail.player.coins)}</strong>
                <span>Koin</span>
              </div>
              <div>
                <strong>Hari {detail.player.progress.day}</strong>
                <span>{detail.player.progress.stage}</span>
              </div>
              <div>
                <strong>
                  {detail.player.inventory.reduce(
                    (n: number, x: any) => n + x.quantity,
                    0,
                  )}
                </strong>
                <span>Fragmen</span>
              </div>
            </div>
            <div className="admin-columns">
              <section>
                <h2>Kontrol pemain</h2>
                <p>
                  Sesi aktif:{" "}
                  {detail.activeSession.dive
                    ? "menyelam"
                    : detail.activeSession.shift
                      ? "kedai"
                      : "tidak ada"}
                  . Perubahan membatalkan sesi permainan dan tangkapan
                  sementara.
                </p>
                <form onSubmit={preview}>
                  <label>
                    Tindakan
                    <select
                      value={action}
                      onChange={(e) => setAction(e.target.value)}
                    >
                      {Object.entries(actions)
                        .filter(([key]) => key !== "role" || owner)
                        .map(([key, label]) => (
                          <option value={key} key={key}>
                            {label}
                          </option>
                        ))}
                    </select>
                  </label>
                  {["coins", "inventory"].includes(action) && (
                    <div className="fields-grid">
                      <label>
                        Mode
                        <select
                          value={mode}
                          onChange={(e) => setMode(e.target.value)}
                        >
                          <option value="add">Tambah</option>
                          <option value="subtract">Kurangi</option>
                          <option value="set">Tetapkan</option>
                        </select>
                      </label>
                      <label>
                        Jumlah
                        <input
                          type="number"
                          min={0}
                          max={10000000}
                          required
                          value={amount}
                          onChange={(e) => setAmount(Number(e.target.value))}
                        />
                      </label>
                    </div>
                  )}
                  {action === "inventory" && (
                    <div className="fields-grid">
                      <label>
                        Fragmen
                        <select
                          value={fragmentId}
                          onChange={(e) => setFragment(e.target.value)}
                        >
                          {catalog?.fragments.map((f) => (
                            <option value={f.id} key={f.id}>
                              {f.name}
                            </option>
                          ))}
                        </select>
                      </label>
                      <label>
                        Bintang
                        <select
                          value={stars}
                          onChange={(e) => setStars(Number(e.target.value))}
                        >
                          {[1, 2, 3].map((n) => (
                            <option key={n}>{n}</option>
                          ))}
                        </select>
                      </label>
                    </div>
                  )}
                  {action === "ability" && (
                    <div className="fields-grid">
                      <label>
                        Kemampuan
                        <select
                          value={ability}
                          onChange={(e) => setAbility(e.target.value)}
                        >
                          {catalog?.abilities.map((a) => (
                            <option value={a.id} key={a.id}>
                              {a.name}
                            </option>
                          ))}
                        </select>
                      </label>
                      <label>
                        Level
                        <input
                          type="number"
                          min={0}
                          max={
                            (catalog?.abilities.find((a) => a.id === ability)
                              ?.values.length ?? 1) - 1
                          }
                          value={level}
                          onChange={(e) => setLevel(Number(e.target.value))}
                        />
                      </label>
                    </div>
                  )}
                  {action === "progress" && (
                    <>
                      <div className="fields-grid">
                        <label>
                          Hari
                          <input
                            type="number"
                            min={1}
                            max={3}
                            value={progress.day}
                            onChange={(e) =>
                              setProgress({
                                ...progress,
                                day: Number(e.target.value),
                              })
                            }
                          />
                        </label>
                        <label>
                          Tahap
                          <select
                            value={progress.stage}
                            onChange={(e) =>
                              setProgress({
                                ...progress,
                                stage: e.target.value as any,
                                bossDefeated: e.target.value === "done",
                              })
                            }
                          >
                            {["dive", "night", "boss", "done"].map((t) => (
                              <option key={t}>{t}</option>
                            ))}
                          </select>
                        </label>
                      </div>
                      <label>
                        Misi selesai (pisahkan dengan koma)
                        <input
                          value={progress.missions.join(",")}
                          onChange={(e) =>
                            setProgress({
                              ...progress,
                              missions: e.target.value
                                ? e.target.value.split(",").map((s) => s.trim())
                                : [],
                            })
                          }
                        />
                      </label>
                      <label className="check-label">
                        <input
                          type="checkbox"
                          checked={progress.tutorial}
                          onChange={(e) =>
                            setProgress({
                              ...progress,
                              tutorial: e.target.checked,
                            })
                          }
                        />{" "}
                        Tutorial selesai
                      </label>
                    </>
                  )}
                  {action === "role" && (
                    <label>
                      Peran baru
                      <select
                        value={role}
                        onChange={(e) => setRole(e.target.value)}
                      >
                        <option value="player">player</option>
                        <option value="admin">admin</option>
                      </select>
                    </label>
                  )}
                  <label>
                    Alasan perubahan
                    <textarea
                      required
                      minLength={5}
                      maxLength={500}
                      value={reason}
                      onChange={(e) => setReason(e.target.value)}
                      placeholder="Contoh: pemulihan progres setelah laporan pemain"
                    />
                  </label>
                  <button className="primary" disabled={busy}>
                    Tinjau perubahan
                  </button>
                </form>
                {owner && detail.player.role !== "owner" && (
                  <button
                    className="secondary"
                    onClick={() => {
                      setReauth("reset");
                      setReason("");
                    }}
                  >
                    Terbitkan tautan reset password
                  </button>
                )}
              </section>
              <section>
                <h2>Inventori dan kemampuan</h2>
                <ul className="inventory-list">
                  {detail.player.inventory.map((l: any) => (
                    <li key={`${l.fragmentId}:${l.stars}`}>
                      <span>
                        {catalog?.fragments.find((f) => f.id === l.fragmentId)
                          ?.name ?? l.fragmentId}{" "}
                        · {l.stars} bintang
                      </span>
                      <strong>{l.quantity}</strong>
                    </li>
                  ))}
                </ul>
                {!detail.player.inventory.length && <p>Inventori kosong.</p>}
                <dl>
                  {catalog?.abilities.map((a) => (
                    <div key={a.id}>
                      <dt>{a.name}</dt>
                      <dd>Level {detail.player.abilities[a.id]}</dd>
                    </div>
                  ))}
                </dl>
                <h2>Perubahan terakhir</h2>
                <AuditList entries={detail.audits} />
              </section>
            </div>
          </>
        )}
        {tab === "content" && !content && (
          <>
            <div className="section-heading">
              <div>
                <h1>Konten permainan</h1>
                <p>
                  Versi aktif tetap tersimpan pada sesi yang sedang berjalan.
                </p>
              </div>
              <button disabled={busy} onClick={() => void run(loadVersions)}>
                Muat ulang
              </button>
            </div>
            <div className="table-scroll">
              <table>
                <thead>
                  <tr>
                    <th>Versi</th>
                    <th>Status</th>
                    <th>Dibuat</th>
                    <th>Aksi</th>
                  </tr>
                </thead>
                <tbody>
                  {versions.map((c) => (
                    <tr key={c.id}>
                      <td>{c.label}</td>
                      <td>{c.state}</td>
                      <td>{new Date(c.createdAt).toLocaleString("id-ID")}</td>
                      <td>
                        <button onClick={() => void openContent(c.id)}>
                          Buka
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}
        {tab === "content" && content && (
          <>
            <button
              className="quiet back"
              onClick={() => {
                if (
                  !dirty ||
                  confirm("Buang perubahan draft yang belum disimpan?")
                ) {
                  setContent(undefined);
                  void run(loadVersions);
                }
              }}
            >
              Kembali ke versi
            </button>
            <div className="section-heading">
              <div>
                <h1>{content.label}</h1>
                <p>
                  {content.state} · {content.catalog.questions.length} soal
                  {dirty ? " · perubahan belum disimpan" : ""}
                </p>
              </div>
              {!editable && (
                <button
                  className="primary"
                  disabled={busy}
                  onClick={() => {
                    setReason("Salinan untuk pembaruan konten");
                    setPending({ clone: true });
                  }}
                >
                  Buat draft salinan
                </button>
              )}
            </div>
            <div className="content-tabs">
              {[
                ["questions", "Soal"],
                ["fragments", "Fragmen"],
                ["recipes", "Pelanggan & resep"],
                ["abilities", "Kemampuan"],
                ["balance", "Keseimbangan"],
              ].map(([key, label]) => (
                <button
                  key={key}
                  aria-pressed={category === key}
                  onClick={() => {
                    setCategory(key as keyof Catalog);
                    setRecord(0);
                  }}
                >
                  {label}
                </button>
              ))}
            </div>
            <div className="content-editor">
              <aside>
                {category !== "balance" && (
                  <>
                    <label>
                      Pilih {category}
                      <select
                        value={record}
                        onChange={(e) => setRecord(Number(e.target.value))}
                      >
                        {rows.map((r, i) => (
                          <option key={r.id} value={i}>
                            {r.id} ·{" "}
                            {(r.prompt ?? r.name ?? r.customer).slice(0, 45)}
                          </option>
                        ))}
                      </select>
                    </label>
                    <p>{rows.length} entri</p>
                    {editable &&
                      ["questions", "fragments", "recipes"].includes(
                        category,
                      ) && (
                        <div className="actions">
                          <button onClick={addRecord}>Tambah entri</button>
                          <button
                            disabled={!current}
                            onClick={() => {
                              if (
                                !confirm(
                                  "Hapus entri dari draft lokal? Publikasi akan memeriksa referensinya.",
                                )
                              )
                                return;
                              const next = structuredClone(content);
                              (next.catalog[category] as any[]).splice(
                                record,
                                1,
                              );
                              setRecord(0);
                              setContent(next);
                              setDirty(true);
                            }}
                          >
                            Hapus entri
                          </button>
                        </div>
                      )}
                  </>
                )}
                {category === "questions" && (
                  <>
                    <button onClick={exportQuestions}>Ekspor JSON soal</button>
                    {editable && (
                      <label>
                        Impor JSON soal
                        <input
                          type="file"
                          accept="application/json,.json"
                          onChange={(e) => {
                            const f = e.target.files?.[0];
                            if (f) void importQuestions(f);
                            e.target.value = "";
                          }}
                        />
                      </label>
                    )}
                  </>
                )}
                {editable && (
                  <>
                    <label>
                      Alasan penyimpanan/publikasi
                      <textarea
                        minLength={5}
                        value={reason}
                        onChange={(e) => setReason(e.target.value)}
                      />
                    </label>
                    <button
                      className="primary"
                      disabled={busy || !dirty || reason.trim().length < 5}
                      onClick={() => void saveContent()}
                    >
                      Simpan draft
                    </button>
                    <button
                      disabled={busy || dirty || reason.trim().length < 5}
                      onClick={() => setPending({ publish: true })}
                    >
                      Tinjau publikasi
                    </button>
                    <button
                      className="quiet"
                      disabled={busy}
                      onClick={() => setPending({ archive: true })}
                    >
                      Arsipkan draft
                    </button>
                  </>
                )}
              </aside>
              <section>
                {current ? (
                  <EditFields
                    key={`${category}:${record}:${content.id}`}
                    value={current}
                    disabled={!editable}
                    onChange={editRecord}
                  />
                ) : (
                  <Notice>
                    Belum ada entri. Tambahkan konten baru pada draft.
                  </Notice>
                )}
              </section>
            </div>
          </>
        )}
        {tab === "audit" && (
          <>
            <div className="section-heading">
              <div>
                <h1>Jejak audit</h1>
                <p>
                  {auditTotal} peristiwa tercatat. Riwayat tidak dapat dihapus
                  melalui panel.
                </p>
              </div>
              <button disabled={busy} onClick={() => void run(loadAudit)}>
                Muat ulang
              </button>
            </div>
            <AuditList entries={audit} />
            <div className="pagination">
              <button
                disabled={busy || auditPage === 1}
                onClick={() => setAuditPage((p) => p - 1)}
              >
                Sebelumnya
              </button>
              <span>Halaman {auditPage}</span>
              <button
                disabled={busy || auditPage * 30 >= auditTotal}
                onClick={() => setAuditPage((p) => p + 1)}
              >
                Berikutnya
              </button>
            </div>
          </>
        )}
        {busy && (
          <p className="busy-label" role="status">
            Memproses…
          </p>
        )}
      </main>
      {invite && (
        <Dialog title="Undang pemain" onClose={() => setInvite(false)}>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              void run(async () => {
                const r = await api("/admin/invitations", {
                  email: inviteEmail,
                  reason,
                });
                setInvite(false);
                setOneTimeLink(r.url);
              });
            }}
          >
            <label>
              Email penerima
              <input
                required
                type="email"
                value={inviteEmail}
                onChange={(e) => setInviteEmail(e.target.value)}
              />
            </label>
            <label>
              Alasan
              <textarea
                required
                minLength={5}
                value={reason}
                onChange={(e) => setReason(e.target.value)}
              />
            </label>
            <p>
              Tautan berlaku 72 jam. Undangan ulang membatalkan tautan
              sebelumnya.
            </p>
            {error && <Notice error>{error}</Notice>}
            <button disabled={busy} className="primary">
              Terbitkan undangan
            </button>
          </form>
        </Dialog>
      )}
      {oneTimeLink && (
        <Dialog title="Tautan sekali pakai" onClose={() => setOneTimeLink("")}>
          <p>
            Salin sekarang dan bagikan langsung kepada penerima. Tautan tidak
            ditampilkan lagi setelah dialog ditutup.
          </p>
          <label>
            Tautan
            <input
              readOnly
              value={oneTimeLink}
              onFocus={(e) => e.target.select()}
            />
          </label>
          <button
            onClick={() =>
              void navigator.clipboard
                .writeText(oneTimeLink)
                .then(() => setNotice("Tautan disalin."))
                .catch(() => setNotice("Pilih dan salin tautan secara manual."))
            }
          >
            Salin tautan
          </button>
        </Dialog>
      )}
      {reauth && (
        <Dialog
          title="Konfirmasi identitas owner"
          onClose={() => setReauth("")}
        >
          <form
            onSubmit={(e) => {
              e.preventDefault();
              void run(async () => {
                await api("/auth/reauth", { password });
                setPassword("");
                const r = await api(
                  `/admin/players/${detail.player.id}/reset-password`,
                  { reason },
                );
                setReauth("");
                setOneTimeLink(r.url);
              });
            }}
          >
            <label>
              Password owner
              <input
                required
                type="password"
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </label>
            <label>
              Alasan reset
              <textarea
                required
                minLength={5}
                value={reason}
                onChange={(e) => setReason(e.target.value)}
              />
            </label>
            <p>
              Tautan berlaku satu jam. Sesi pemain dicabut setelah password
              diganti.
            </p>
            {error && <Notice error>{error}</Notice>}
            <button className="primary" disabled={busy}>
              Terbitkan tautan reset
            </button>
          </form>
        </Dialog>
      )}
      {pending && (
        <Dialog
          title={
            pending.clone
              ? "Buat draft baru"
              : pending.publish
                ? "Publikasikan konten?"
                : pending.archive
                  ? "Arsipkan draft?"
                  : "Konfirmasi perubahan pemain"
          }
          onClose={() => setPending(undefined)}
        >
          {pending.body ? (
            <>
              <p>
                {actions[pending.body.action]} untuk{" "}
                <strong>{detail.player.email}</strong>. Sesi permainan aktif
                dibatalkan beserta tangkapan sementara.
              </p>
              <div className="preview-columns">
                <div>
                  <h3>Sebelum</h3>
                  <pre>
                    {JSON.stringify(
                      pending.body.action === "coins"
                        ? { coins: detail.player.coins }
                        : pending.body.action === "ability"
                          ? detail.player.abilities
                          : pending.body.action === "inventory"
                            ? detail.player.inventory
                            : detail.player.progress,
                      null,
                      2,
                    )}
                  </pre>
                </div>
                <div>
                  <h3>Sesudah</h3>
                  <pre>{JSON.stringify(pending.after, null, 2)}</pre>
                </div>
              </div>
              <p>Alasan: {pending.body.reason}</p>
              <button
                className="primary"
                disabled={busy}
                onClick={() => void apply()}
              >
                Terapkan dan catat audit
              </button>
            </>
          ) : (
            <>
              <p>
                {pending.publish
                  ? "Sesi baru akan memakai versi ini. Sesi yang sedang berjalan mempertahankan versi sebelumnya."
                  : pending.archive
                    ? "Draft akan menjadi arsip dan tidak dapat diedit."
                    : "Salinan menyimpan seluruh soal, resep, dan konfigurasi untuk diedit sebelum publikasi."}
              </p>
              <label>
                Alasan
                <textarea
                  required
                  minLength={5}
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                />
              </label>
              <button
                className="primary"
                disabled={busy || reason.trim().length < 5}
                onClick={() =>
                  void run(async () => {
                    if (pending.clone) {
                      const r = await api("/admin/content/draft", {
                        sourceId: content!.id,
                        label: `${content!.label.slice(0, 70)} · revisi`,
                        reason,
                      });
                      setContent(r.content);
                      setHash(r.hash);
                      setDirty(false);
                    } else {
                      await api(
                        `/admin/content/${content!.id}/${pending.publish ? "publish" : "archive"}`,
                        pending.publish ? { hash, reason } : { reason },
                      );
                      setContent(undefined);
                      await loadVersions();
                    }
                    setPending(undefined);
                    setNotice("Perubahan konten tercatat.");
                  })
                }
              >
                Konfirmasi
              </button>
            </>
          )}
          {error && <Notice error>{error}</Notice>}
        </Dialog>
      )}
    </div>
  );
}
function AuditList({ entries }: { entries: any[] }) {
  return entries.length ? (
    <ol className="audit-list">
      {entries.map((a) => (
        <li key={a._id}>
          <div>
            <strong>{a.action}</strong>
            <time>{new Date(a.at).toLocaleString("id-ID")}</time>
          </div>
          <p>{a.reason}</p>
          <small>
            Pelaksana: {a.actor} · Target: {a.target}
          </small>
          <details>
            <summary>Lihat nilai sebelum/sesudah</summary>
            <pre>
              {JSON.stringify({ before: a.before, after: a.after }, null, 2)}
            </pre>
          </details>
        </li>
      ))}
    </ol>
  ) : (
    <Notice>Belum ada perubahan yang tercatat.</Notice>
  );
}
