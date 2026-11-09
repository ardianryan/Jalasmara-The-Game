import { useRef } from "react";
import { formatDownloadBytes, type LoadingProgress } from "./loading";
import "./game-loading.css";

interface Props {
  progress: LoadingProgress;
  stalled: boolean;
  onRetry: () => void;
}

export function GameLoading({ progress, stalled, onRetry }: Props) {
  const scene = useRef<HTMLDivElement>(null);
  const downloading = progress.phase === "downloading";
  const failed = progress.phase === "error";
  const percent =
    downloading && progress.totalBytes !== null
      ? Math.floor((progress.downloadedBytes / progress.totalBytes) * 100)
      : null;
  const title = failed
    ? "Perjalanan belum dapat dimulai"
    : "Menuju Bandar Hujung";
  const stage = failed
    ? "Aset belum berhasil dimuat"
    : downloading
      ? "Mengunduh aset petualangan"
      : "Menyiapkan dunia petualangan";

  return (
    <div
      className="game-loading harbor-loading"
      ref={scene}
      onPointerMove={(event) => {
        if (
          event.pointerType !== "mouse" ||
          !matchMedia(
            "(prefers-reduced-motion: no-preference) and (pointer: fine)",
          ).matches
        )
          return;
        const bounds = event.currentTarget.getBoundingClientRect();
        scene.current?.style.setProperty(
          "--harbor-x",
          `${((event.clientX - bounds.left) / bounds.width - 0.5) * 8}px`,
        );
        scene.current?.style.setProperty(
          "--harbor-y",
          `${((event.clientY - bounds.top) / bounds.height - 0.5) * 6}px`,
        );
      }}
      onPointerLeave={() => {
        scene.current?.style.setProperty("--harbor-x", "0px");
        scene.current?.style.setProperty("--harbor-y", "0px");
      }}
    >
      <div className="harbor-loading-scene" aria-hidden="true">
        <div className="harbor-loading-harbor" />
        <div className="harbor-loading-foreground" />
      </div>
      <div className="harbor-loading-shade" aria-hidden="true" />
      <div className="harbor-loading-brand" aria-label="Jalasmara">
        <img src="/brand/symbol-white.svg" alt="" width="40" height="40" />
        <span>Jalasmara</span>
      </div>
      <section
        className="harbor-loading-panel"
        aria-labelledby="loading-title"
        aria-busy={!failed}
      >
        <h1 id="loading-title">{title}</h1>
        <div
          className="harbor-loading-stage"
          role="status"
          aria-live="polite"
          aria-atomic="true"
        >
          <p>{stage}</p>
          <span className="harbor-loading-percent" aria-hidden="true">
            {percent === null ? "" : `${percent}%`}
          </span>
        </div>
        {!failed && (
          <progress aria-label={stage} max={100} value={percent ?? undefined} />
        )}
        <p className="harbor-loading-detail">
          {failed
            ? "Periksa koneksi internet, lalu coba muat kembali."
            : downloading
              ? progress.totalBytes !== null
                ? `${formatDownloadBytes(progress.downloadedBytes)} dari ${formatDownloadBytes(progress.totalBytes)}`
                : progress.downloadedBytes > 0
                  ? `${formatDownloadBytes(progress.downloadedBytes)} diunduh. Ukuran total belum tersedia.`
                  : "Menghubungkan perjalananmu ke Bandar Hujung…"
              : "Unduhan selesai. Menata desa, hutan, dan lautan untukmu…"}
        </p>
        {downloading && !failed && (
          <p className="harbor-loading-note">
            Unduhan pertama lebih besar. Aset yang tersimpan dapat digunakan
            pada kunjungan berikutnya.
          </p>
        )}
        {stalled && !failed && (
          <p className="harbor-loading-stalled" role="status">
            Belum ada pembaruan pemuatan. Koneksi lambat dapat memerlukan waktu
            lebih lama.
          </p>
        )}
        {(stalled || failed) && (
          <div className="harbor-loading-actions">
            <button onClick={onRetry}>Muat ulang permainan</button>
            <a href="/game/index.html">Buka di tab ini</a>
          </div>
        )}
      </section>
    </div>
  );
}
