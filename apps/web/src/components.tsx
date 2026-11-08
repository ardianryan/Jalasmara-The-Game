import { useEffect, useRef, type ReactNode } from "react";
export function Dialog({
  title,
  children,
  onClose,
}: {
  title: string;
  children: ReactNode;
  onClose?: () => void;
}) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const d = ref.current!;
    d.showModal();
    const close = (e: Event) => {
      e.preventDefault();
      onClose?.();
    };
    d.addEventListener("cancel", close);
    return () => {
      d.removeEventListener("cancel", close);
      d.close();
    };
  }, []);
  return (
    <dialog ref={ref} aria-labelledby="dialog-title">
      <header className="dialog-heading">
        <h2 id="dialog-title">{title}</h2>
        {onClose && (
          <button className="quiet" onClick={onClose} aria-label="Tutup dialog">
            Tutup
          </button>
        )}
      </header>
      {children}
    </dialog>
  );
}
export function Notice({
  children,
  error = false,
}: {
  children: ReactNode;
  error?: boolean;
}) {
  return (
    <p
      role={error ? "alert" : "status"}
      className={`notice ${error ? "error" : ""}`}
    >
      {children}
    </p>
  );
}
export function Loading() {
  return (
    <div className="loading" role="status">
      Menyiapkan ingatan…
    </div>
  );
}
export function Brand() {
  return (
    <a className="brand" href="/play" aria-label="Jalasmara, beranda">
      <img className="brand-mark" src="/brand/symbol.svg" alt="" />
      Jalasmara
    </a>
  );
}
