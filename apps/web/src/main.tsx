import React, { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import "@fontsource/nunito-sans/400.css";
import "@fontsource/nunito-sans/600.css";
import "@fontsource/nunito-sans/700.css";
import "@fontsource/lora/500.css";
import "@fontsource/lora/600.css";
import { api, session, type AuthState } from "./api";
import { Brand, Loading, Notice } from "./components";
import { Play } from "./play";
import { AdminRoute } from "./AdminRoute";
import "./style.css";
function Auth({
  mode,
  onAuthenticated,
  auth,
}: {
  mode: string;
  onAuthenticated: () => Promise<void>;
  auth: AuthState;
}) {
  const [email, setEmail] = useState(""),
    [name, setName] = useState(""),
    [password, setPassword] = useState(""),
    [busy, setBusy] = useState(false),
    [error, setError] = useState(""),
    [done, setDone] = useState(false);
  const activate = mode === "/activate",
    reset = mode === "/reset",
    token = location.hash.slice(1);
  useEffect(() => {
    if (token) history.replaceState(null, "", location.pathname);
  }, []);
  const [storedToken] = useState(token);
  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setBusy(true);
    try {
      if (activate)
        await api("/auth/activate", { name, password, token: storedToken });
      else if (reset) {
        await api("/auth/reset", { password, token: storedToken });
        setDone(true);
        return;
      } else await api("/auth/login", { email, password });
      await onAuthenticated();
      location.assign("/play");
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }
  return (
    <main className="entry">
      <div
        className="entry-art"
        role="img"
        aria-label="Kedai kayu di Bandar Hujung, di atas laut dengan terumbu dan biota bercahaya"
      >
        <div className="entry-story">
          <span>Bandar Hujung · Palung Smara</span>
          <h1>
            Yang hilang
            <br />
            belum terlupakan.
          </h1>
          <p>
            Selami lautan. Jaring pengetahuan.
            <br />
            Hidupkan kembali ingatan kota.
          </p>
        </div>
      </div>
      <section className="entry-panel">
        <Brand />
        <div className="entry-form">
          <h2>
            {activate
              ? "Sebuah ingatan baru."
              : reset
                ? "Pulihkan akses."
                : "Pulang ke Bandar."}
          </h2>
          <p>
            {activate
              ? "Tetapkan nama dan password untuk menerima undangan."
              : reset
                ? "Buat password baru untuk akun Jalasmara."
                : "Masuk untuk melanjutkan perjalanan Nala."}
          </p>
          {done ? (
            <>
              <Notice>
                Password diperbarui. Semua sesi sebelumnya sudah dicabut.
              </Notice>
              <a className="button" href="/">
                Masuk kembali
              </a>
            </>
          ) : (activate || reset) && !storedToken ? (
            <Notice error>
              Tautan tidak lengkap. Buka kembali tautan dari pengelola, atau
              minta tautan baru jika sudah tidak tersedia.
            </Notice>
          ) : (
            <form onSubmit={submit} aria-busy={busy}>
              {activate && (
                <label>
                  Nama pemain
                  <input
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    minLength={2}
                    maxLength={60}
                    autoComplete="nickname"
                  />
                </label>
              )}
              {!activate && !reset && (
                <label>
                  Email
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    autoComplete="username"
                  />
                </label>
              )}
              <label>
                Password
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  minLength={activate || reset ? 12 : 1}
                  maxLength={128}
                  autoComplete={
                    activate || reset ? "new-password" : "current-password"
                  }
                  aria-describedby={
                    activate || reset ? "password-guidance" : undefined
                  }
                />
              </label>
              {(activate || reset) && (
                <small id="password-guidance">
                  Minimal 12 karakter. Gunakan password yang tidak dipakai pada
                  layanan lain.
                </small>
              )}
              {error && <Notice error>{error}</Notice>}
              {new URLSearchParams(location.search).has("authError") && (
                <Notice error>
                  Identitas belum ditautkan. Masuk dengan akun lokal terlebih
                  dahulu.
                </Notice>
              )}
              <button className="primary" disabled={busy}>
                {busy
                  ? "Memproses…"
                  : activate
                    ? "Terima undangan"
                    : reset
                      ? "Simpan password"
                      : "Masuk ke Jalasmara"}
              </button>
            </form>
          )}
          {!activate && !reset && auth.oidcEnabled && (
            <a className="button secondary social" href="/api/auth/oidc/start">
              Masuk dengan {auth.oidcLabel}
            </a>
          )}
          <p className="entry-note">
            {activate || reset
              ? "Tautan hanya dapat digunakan sekali."
              : "Demo menggunakan undangan. Untuk akses atau pemulihan password, hubungi pengelola."}
          </p>
        </div>
        <footer>
          <span>Jalasmara</span>
          <a href="/credits.html" target="_blank" rel="noreferrer">
            Kredit aset
          </a>
        </footer>
      </section>
    </main>
  );
}
function Settings({
  auth,
  refresh,
}: {
  auth: AuthState;
  refresh: () => Promise<void>;
}) {
  const [password, setPassword] = useState(""),
    [message, setMessage] = useState(""),
    [busy, setBusy] = useState(false),
    [error, setError] = useState("");
  async function reauth(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError("");
    setMessage("");
    try {
      await api("/auth/reauth", { password });
      setPassword("");
      setMessage(
        "Password dikonfirmasi. Anda dapat menautkan atau melepas login tambahan selama lima menit.",
      );
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }
  async function unlink() {
    setBusy(true);
    setError("");
    setMessage("");
    try {
      await api("/auth/oidc/unlink", {});
      await refresh();
      setMessage("Identitas dilepas. Akun lokal tetap tersedia.");
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }
  return (
    <main className="settings sheet">
      <h1>Pengaturan akun</h1>
      <p className="account-identity">
        {auth.user!.name} · {auth.user!.email}
      </p>
      <h2>Login tambahan</h2>
      <p>
        Konfirmasi password sebelum mengubah tautan identitas. Kesamaan email
        tidak menggabungkan akun secara otomatis.
      </p>
      {auth.oidcEnabled ? (
        <>
          <form onSubmit={reauth} aria-busy={busy}>
            <label>
              Password saat ini
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="current-password"
              />
            </label>
            <button disabled={busy}>
              {busy ? "Memproses…" : "Konfirmasi password"}
            </button>
          </form>
          {auth.linked ? (
            <button disabled={busy} onClick={unlink}>
              Lepas identitas tambahan
            </button>
          ) : (
            <a className="button" href="/api/auth/oidc/start?mode=link">
              Tautkan {auth.oidcLabel}
            </a>
          )}
        </>
      ) : (
        <Notice>
          Login tambahan belum diaktifkan pengelola. Gunakan email dan password
          untuk masuk.
        </Notice>
      )}
      {message && <Notice>{message}</Notice>}
      {error && <Notice error>{error}</Notice>}
    </main>
  );
}
function App() {
  const [auth, setAuth] = useState<AuthState>(),
    [error, setError] = useState(""),
    [logoutError, setLogoutError] = useState(""),
    [loggingOut, setLoggingOut] = useState(false);
  async function refresh() {
    setAuth(await session());
  }
  useEffect(() => {
    void refresh().catch((e) => setError(e.message));
  }, []);
  if (error)
    return (
      <main className="settings">
        <h1>Koneksi belum tersambung</h1>
        <Notice error>{error}</Notice>
        <button onClick={() => location.reload()}>Coba lagi</button>
      </main>
    );
  if (!auth) return <Loading />;
  const path = location.pathname;
  if (!auth.user || path === "/activate" || path === "/reset")
    return <Auth mode={path} auth={auth} onAuthenticated={refresh} />;
  async function logout() {
    await api("/auth/logout", {});
    location.assign("/");
  }
  const playing = !path.startsWith("/admin") && path !== "/settings";
  return (
    <>
      {!playing && (
        <header
          className={`app-header ${path.startsWith("/admin") ? "admin-header" : path === "/play" ? "game-header" : ""}`}
        >
          <Brand />
          <nav aria-label="Navigasi utama">
            <a
              href="/play"
              aria-current={path === "/play" ? "page" : undefined}
            >
              Perjalanan
            </a>
            <a
              href="/settings"
              aria-current={path === "/settings" ? "page" : undefined}
            >
              Akun
            </a>
            {auth.user.role !== "player" && (
              <a
                href="/admin"
                aria-current={path.startsWith("/admin") ? "page" : undefined}
              >
                Pengelola
              </a>
            )}
            <button
              className="quiet"
              disabled={loggingOut}
              onClick={async () => {
                setLoggingOut(true);
                setLogoutError("");
                try {
                  await logout();
                } catch {
                  setLogoutError(
                    "Belum dapat keluar dari akun. Periksa koneksi lalu coba lagi.",
                  );
                } finally {
                  setLoggingOut(false);
                }
              }}
              aria-label="Keluar dari akun"
            >
              {loggingOut ? "Keluar…" : "Keluar"}
            </button>
          </nav>
        </header>
      )}
      {!playing && logoutError && (
        <div className="account-feedback">
          <Notice error>{logoutError}</Notice>
        </div>
      )}
      {path.startsWith("/admin") ? (
        auth.user.role === "player" ? (
          <main className="settings">
            <h1>Akses terbatas</h1>
            <p>Halaman ini hanya tersedia untuk pengelola.</p>
          </main>
        ) : (
          <AdminRoute auth={auth} />
        )
      ) : path === "/settings" ? (
        <Settings auth={auth} refresh={refresh} />
      ) : (
        <Play canManage={auth.user.role !== "player"} onLogout={logout} />
      )}
    </>
  );
}
createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
