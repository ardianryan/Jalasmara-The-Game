import { useCallback, useEffect, useRef, useState } from "react";
import { Notice } from "./components";

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
  const [slow, setSlow] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [fullscreen, setFullscreen] = useState(false);
  const [notice, setNotice] = useState("");
  const [loggingOut, setLoggingOut] = useState(false);
  const [graphicsQuality, setGraphicsQuality] = useState<GraphicsQuality>(
    storedGraphicsQuality,
  );

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
        reservedTopPx: inset("Top") + 52,
        focused: document.hasFocus() && !document.hidden && !menuOpen,
        hostControl: { placement: "top-center", width: 88, height: 48 },
      },
      location.origin,
    );
  }, [menuOpen, graphicsQuality]);

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
      }
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
    const timer = setTimeout(() => setSlow(true), 45000);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    if (menuOpen) fullscreenButton.current?.focus();
  }, [menuOpen]);

  function closeMenu() {
    setMenuOpen(false);
    menuButton.current?.focus();
  }

  async function toggleFullscreen() {
    setNotice("");
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
        ref={game}
        title="Jalasmara: Petualangan Bandar Hujung dan Palung Smara"
        src="/game/index.html"
        allow="autoplay; fullscreen; gamepad"
        allowFullScreen
      />
      <span className="play-safe-area" ref={safeArea} aria-hidden="true" />
      <button
        ref={menuButton}
        className="play-menu-toggle"
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
        <div className="game-loading" role="status">
          <h1>Menuju Bandar Hujung</h1>
          <p>
            Memuat dunia petualangan Godot. Unduhan pertama mencakup mesin
            permainan.
          </p>
          {slow && (
            <>
              <Notice>
                Jika pemuatan terhenti, buka permainan pada tab tersendiri.
                Browser memerlukan WebGL 2.
              </Notice>
              <a href="/game/index.html">Buka permainan langsung</a>
            </>
          )}
        </div>
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
