import { useCallback, useEffect, useRef, useState } from "react";
import { GameLoading } from "./GameLoading";
import { INITIAL_LOADING, parseLoadingMessage } from "./loading";
import { api } from "./api";
import menuFrame from "../../../client-godot/resources/art/hud-bahari-v1/button-normal.png";
import {
  downloadPerformance,
  recordPerformance,
  type PerformanceReport,
} from "./performance-capture";

interface PlayProps {
  canManage?: boolean;
  onLogout: () => Promise<void>;
}
type GraphicsQuality = "auto" | "low" | "balanced";
const QUALITY_STORAGE_KEY = "jalasmara.graphicsQuality";

function storedGraphicsQuality(): GraphicsQuality {
  try {
    const value = localStorage.getItem(QUALITY_STORAGE_KEY);
    if (value === "low" || value === "balanced") return value;
  } catch {
    // Restricted storage must not prevent playing or changing this session's setting.
  }
  return "auto";
}

export function Play({ canManage = false, onLogout }: PlayProps) {
  const shell = useRef<HTMLElement>(null);
  const game = useRef<HTMLIFrameElement>(null);
  const menuButton = useRef<HTMLButtonElement>(null);
  const fullscreenButton = useRef<HTMLButtonElement>(null);
  const safeArea = useRef<HTMLSpanElement>(null);
  const [ready, setReady] = useState(false);
  const [loading, setLoading] = useState(INITIAL_LOADING);
  const [stalled, setStalled] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const lastProgress = useRef(Date.now());
  const progressKey = useRef("");
  const [menuOpen, setMenuOpen] = useState(false);
  const [fullscreen, setFullscreen] = useState(false);
  const [notice, setNotice] = useState("");
  const [loggingOut, setLoggingOut] = useState(false);
  const [resettingPosition, setResettingPosition] = useState(false);
  const [graphicsQuality, setGraphicsQuality] = useState<GraphicsQuality>(
    storedGraphicsQuality,
  );
  const [captureDuration, setCaptureDuration] = useState<30_000 | 300_000>(
    30_000,
  );
  const [captureActive, setCaptureActive] = useState(false);
  const [captureReport, setCaptureReport] = useState<PerformanceReport | null>(
    null,
  );
  const capture = useRef<ReturnType<typeof recordPerformance> | null>(null);
  const menuOpenForCapture = useRef(menuOpen);
  menuOpenForCapture.current = menuOpen;

  useEffect(() => () => capture.current?.cancel(), []);

  useEffect(() => {
    try {
      localStorage.setItem(QUALITY_STORAGE_KEY, graphicsQuality);
    } catch {
      // The in-memory selection still applies when browser storage is unavailable.
    }
  }, [graphicsQuality]);

  const sendViewport = useCallback(() => {
    const host = shell.current;
    const target = game.current?.contentWindow;
    if (!host || !target) return;
    const bounds = host.getBoundingClientRect();
    const menuBounds = menuButton.current?.getBoundingClientRect();
    const style = safeArea.current && getComputedStyle(safeArea.current);
    const inset = (side: "Top" | "Right" | "Bottom" | "Left") =>
      style ? Number.parseFloat(style[`padding${side}`]) || 0 : 0;
    target.postMessage(
      {
        type: "jalasmara:viewport",
        version: 1,
        width: Math.round(bounds.width),
        height: Math.round(bounds.height),
        devicePixelRatio: window.devicePixelRatio,
        fullscreen: document.fullscreenElement === host,
        safeArea: {
          top: inset("Top"),
          right: inset("Right"),
          bottom: inset("Bottom"),
          left: inset("Left"),
        },
        hostMenuOpen: menuOpen,
        graphicsQuality,
        performanceCapture: captureActive,
        reservedTopPx: inset("Top") + 52,
        focused: document.hasFocus() && !document.hidden && !menuOpen,
        hostControl: {
          placement: "top-center",
          x: menuBounds ? menuBounds.left - bounds.left : bounds.width / 2 - 32,
          y: menuBounds ? menuBounds.top - bounds.top : 4,
          width: menuBounds?.width ?? 64,
          height: menuBounds?.height ?? 48,
        },
      },
      location.origin,
    );
  }, [menuOpen, graphicsQuality, captureActive]);

  function startCapture() {
    if (!ready || !game.current || captureActive) return;
    try {
      setCaptureReport(null);
      capture.current = recordPerformance(game.current, {
        durationMs: captureDuration,
        quality: graphicsQuality,
        paused: () => menuOpenForCapture.current,
        complete: (report) => {
          capture.current = null;
          setCaptureActive(false);
          setCaptureReport(report);
        },
      });
      setCaptureActive(true);
      setMenuOpen(false);
      game.current.contentWindow?.focus();
    } catch {
      setNotice(
        "Rekaman belum dapat dimulai. Tunggu permainan siap, lalu coba lagi.",
      );
    }
  }

  useEffect(() => {
    let scheduled = 0;
    const schedule = () => {
      cancelAnimationFrame(scheduled);
      scheduled = requestAnimationFrame(sendViewport);
    };
    const receive = (event: MessageEvent) => {
      if (
        event.origin !== location.origin ||
        event.source !== game.current?.contentWindow
      )
        return;
      if (event.data?.type === "jalasmara:ready") {
        setReady(true);
        schedule();
        return;
      }
      const progress = parseLoadingMessage(event.data);
      if (!progress) return;
      const key = `${progress.phase}:${progress.downloadedBytes}:${progress.totalBytes}`;
      if (key !== progressKey.current) {
        progressKey.current = key;
        lastProgress.current = Date.now();
        setStalled(false);
      }
      setLoading((previous) => {
        if (previous.phase === "error") return previous;
        if (previous.phase === "preparing" && progress.phase === "downloading")
          return previous;
        return progress;
      });
    };
    const changed = () => {
      setFullscreen(document.fullscreenElement === shell.current);
      schedule();
    };
    const failed = () =>
      setNotice(
        "Layar penuh ditolak browser. Permainan tetap memenuhi jendela ini.",
      );
    const observer = new ResizeObserver(schedule);
    if (shell.current) observer.observe(shell.current);
    window.addEventListener("message", receive);
    window.addEventListener("resize", schedule);
    window.addEventListener("orientationchange", schedule);
    window.addEventListener("focus", schedule);
    window.addEventListener("blur", schedule);
    window.visualViewport?.addEventListener("resize", schedule);
    document.addEventListener("visibilitychange", schedule);
    document.addEventListener("fullscreenchange", changed);
    document.addEventListener("fullscreenerror", failed);
    schedule();
    return () => {
      cancelAnimationFrame(scheduled);
      observer.disconnect();
      window.removeEventListener("message", receive);
      window.removeEventListener("resize", schedule);
      window.removeEventListener("orientationchange", schedule);
      window.removeEventListener("focus", schedule);
      window.removeEventListener("blur", schedule);
      window.visualViewport?.removeEventListener("resize", schedule);
      document.removeEventListener("visibilitychange", schedule);
      document.removeEventListener("fullscreenchange", changed);
      document.removeEventListener("fullscreenerror", failed);
    };
  }, [sendViewport]);

  useEffect(() => {
    if (ready || loading.phase === "error") return;
    const timer = setInterval(() => {
      if (!document.hidden && Date.now() - lastProgress.current >= 30000)
        setStalled(true);
    }, 1000);
    const visible = () => {
      lastProgress.current = Date.now();
      setStalled(false);
    };
    document.addEventListener("visibilitychange", visible);
    return () => {
      clearInterval(timer);
      document.removeEventListener("visibilitychange", visible);
    };
  }, [ready, loading.phase, attempt]);

  function retryLoading() {
    setReady(false);
    setLoading(INITIAL_LOADING);
    setStalled(false);
    lastProgress.current = Date.now();
    progressKey.current = "";
    setAttempt((previous) => previous + 1);
  }

  useEffect(() => {
    if (menuOpen) fullscreenButton.current?.focus();
  }, [menuOpen]);

  function closeMenu() {
    setMenuOpen(false);
    menuButton.current?.focus();
  }

  async function resetPlayerPosition() {
    if (resettingPosition || !ready) return;
    setResettingPosition(true);
    setNotice("");
    try {
      await api("/adventure/reset-position", {});
      setMenuOpen(false);
      retryLoading();
    } catch (error) {
      setNotice(
        error instanceof Error
          ? error.message
          : "Posisi belum dapat direset. Periksa koneksi lalu coba lagi.",
      );
    } finally {
      setResettingPosition(false);
    }
  }

  async function toggleFullscreen() {
    setNotice("");
    game.current?.contentWindow?.postMessage(
      { type: "jalasmara:ui-sfx", version: 1 },
      location.origin,
    );
    try {
      if (document.fullscreenElement === shell.current) {
        await document.exitFullscreen();
      } else if (
        shell.current?.requestFullscreen &&
        document.fullscreenEnabled
      ) {
        await shell.current.requestFullscreen();
      } else {
        setNotice(
          "Browser ini belum mendukung layar penuh. Permainan tetap memenuhi jendela; bilah browser dapat tetap terlihat.",
        );
      }
    } catch {
      setNotice(
        "Layar penuh tidak dapat dibuka. Coba lagi melalui tombol ini, atau lanjutkan di jendela sekarang.",
      );
    }
  }

  return (
    <main
      className="godot-player immersive-player"
      ref={shell}
      aria-label="Permainan Jalasmara"
    >
      <iframe
        key={attempt}
        ref={game}
        title="Jalasmara: Petualangan Bandar Hujung dan Palung Smara"
        src="/game/index.html"
        allow="autoplay; fullscreen; gamepad"
        allowFullScreen
        onLoad={sendViewport}
      />
      <span className="play-safe-area" ref={safeArea} aria-hidden="true" />
      <button
        ref={menuButton}
        className="play-menu-toggle"
        style={{ borderImageSource: `url(${menuFrame})` }}
        data-capture={
          captureActive ? "active" : captureReport ? "ready" : undefined
        }
        title={
          captureActive
            ? "Perekaman performa aktif. Buka Menu untuk berhenti."
            : captureReport
              ? "Laporan performa siap diunduh melalui Menu."
              : "Menu permainan"
        }
        aria-expanded={menuOpen}
        aria-controls="play-browser-menu"
        onClick={() => {
          setMenuOpen(!menuOpen);
          setNotice("");
        }}
      >
        Menu
      </button>
      {menuOpen && (
        <div className="play-menu-backdrop" onClick={closeMenu}>
          <section
            className="play-browser-menu"
            id="play-browser-menu"
            role="dialog"
            aria-modal="true"
            aria-labelledby="play-menu-title"
            onClick={(event) => event.stopPropagation()}
            onKeyDown={(event) => {
              if (event.key === "Escape") {
                event.preventDefault();
                closeMenu();
              }
              if (event.key === "Tab") {
                const controls = Array.from(
                  event.currentTarget.querySelectorAll<HTMLElement>(
                    "button:not(:disabled), a[href], select:not(:disabled)",
                  ),
                );
                const first = controls[0],
                  last = controls.at(-1);
                if (event.shiftKey && document.activeElement === first) {
                  event.preventDefault();
                  last?.focus();
                } else if (!event.shiftKey && document.activeElement === last) {
                  event.preventDefault();
                  first?.focus();
                }
              }
            }}
          >
            <h1 id="play-menu-title">Jalasmara</h1>
            <button
              ref={fullscreenButton}
              onClick={() => void toggleFullscreen()}
              aria-pressed={fullscreen}
            >
              {fullscreen ? "Keluar layar penuh" : "Layar penuh"}
            </button>
            {notice && (
              <p className="play-fullscreen-notice" role="status">
                {notice}
              </p>
            )}
            <div style={{ fontSize: 16 }}>
              <label
                htmlFor="play-graphics-quality"
                style={{ display: "block", fontSize: 16, margin: 0 }}
              >
                Kualitas dunia
              </label>
              <select
                id="play-graphics-quality"
                value={graphicsQuality}
                onChange={(event) => {
                  const value = event.target.value;
                  if (
                    value === "auto" ||
                    value === "low" ||
                    value === "balanced"
                  )
                    setGraphicsQuality(value);
                }}
                style={{
                  display: "block",
                  width: "100%",
                  minHeight: 48,
                  marginTop: 6,
                  fontSize: 16,
                  color: "#302d2a",
                  background: "#f1e1bc",
                  border: "1px solid #654733",
                  borderRadius: 2,
                  padding: "10px 12px",
                }}
              >
                <option value="auto">Auto (perangkat)</option>
                <option value="low">Ringan</option>
                <option value="balanced">Seimbang</option>
              </select>
            </div>
            <button
              disabled={!ready || resettingPosition}
              onClick={() => void resetPlayerPosition()}
            >
              {resettingPosition ? "Memindahkan Nala…" : "Reset posisi pemain"}
            </button>
            <p className="play-position-help">
              Jika Nala tersangkut, pindahkan ke titik aman di wilayah ini.
              Koin, barang, dan progres tetap tersimpan.
            </p>
            <fieldset className="play-capture">
              <legend>Uji performa perangkat</legend>
              <p>
                Rekam sambil bermain di area yang terasa berat. Tidak ada data
                akun yang dikirim; laporan diunduh ke perangkat ini.
              </p>
              {captureActive ? (
                <>
                  <p role="status">
                    Sedang merekam. Lanjutkan bermain atau hentikan rekaman
                    untuk mengunduh hasilnya.
                  </p>
                  <button onClick={() => capture.current?.stop()}>
                    Hentikan rekaman
                  </button>
                </>
              ) : (
                <>
                  <label htmlFor="play-capture-duration">Durasi rekaman</label>
                  <select
                    id="play-capture-duration"
                    value={captureDuration}
                    onChange={(event) =>
                      setCaptureDuration(
                        event.target.value === "300000" ? 300_000 : 30_000,
                      )
                    }
                  >
                    <option value={30_000}>30 detik</option>
                    <option value={300_000}>5 menit · sesi panjang</option>
                  </select>
                  <button disabled={!ready} onClick={startCapture}>
                    Mulai rekam performa
                  </button>
                </>
              )}
              {captureReport && (
                <>
                  <p role="status">
                    Laporan siap. Waktu frame menunjukkan penjadwalan browser,
                    bukan waktu GPU.
                  </p>
                  <button onClick={() => downloadPerformance(captureReport)}>
                    Unduh laporan JSON
                  </button>
                </>
              )}
            </fieldset>
            <a href="/settings">Akun dan pengaturan</a>
            {canManage && <a href="/admin">Panel pengelola</a>}
            <button
              disabled={loggingOut}
              onClick={async () => {
                setLoggingOut(true);
                try {
                  await onLogout();
                } catch {
                  setNotice("Belum dapat keluar dari akun. Coba lagi.");
                  setLoggingOut(false);
                }
              }}
            >
              {loggingOut ? "Keluar…" : "Keluar dari akun"}
            </button>
            <button
              className="play-resume"
              onClick={() => {
                closeMenu();
                game.current?.focus();
                game.current?.contentWindow?.focus();
              }}
            >
              Lanjut bermain
            </button>
          </section>
        </div>
      )}
      {!ready && (
        <GameLoading
          progress={loading}
          stalled={stalled}
          onRetry={retryLoading}
        />
      )}
      {!ready && (
        <div className="landscape-hint">
          Putar HP ke posisi lanskap untuk ruang bermain lebih luas. Menu tetap
          tersedia di atas.
        </div>
      )}
    </main>
  );
}
