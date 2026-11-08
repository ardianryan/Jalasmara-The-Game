import { useEffect, useState } from "react";
import { Notice } from "./components";
export function Play() {
  const [ready, setReady] = useState(false),
    [slow, setSlow] = useState(false);
  useEffect(() => {
    const receive = (e: MessageEvent) => {
      if (e.origin === location.origin && e.data?.type === "jalasmara:ready")
        setReady(true);
    };
    window.addEventListener("message", receive);
    const timer = setTimeout(() => setSlow(true), 45000);
    return () => {
      window.removeEventListener("message", receive);
      clearTimeout(timer);
    };
  }, []);
  return (
    <main className="godot-player">
      <iframe
        title="Jalasmara — Petualangan Bandar Hujung dan Palung Smara"
        src="/game/index.html"
        allow="autoplay; fullscreen; gamepad"
        allowFullScreen
        onLoad={() => {}}
      />
      {!ready && (
        <div className="game-loading">
          <h1>Menuju Bandar Hujung</h1>
          <p>
            Memuat dunia petualangan Godot. Unduhan pertama lebih besar karena
            mencakup mesin permainan.
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
      <div className="landscape-hint">
        Putar HP ke posisi lanskap agar dunia dan kontrol dapat terlihat nyaman.
      </div>
    </main>
  );
}
