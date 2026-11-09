import { useEffect, useId, useRef, type ReactNode } from "react";
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
  const titleId = useId();
  const closeHandler = useRef(onClose);
  closeHandler.current = onClose;
  useEffect(() => {
    const d = ref.current!;
    const previousFocus = document.activeElement;
    d.showModal();
    const close = (e: Event) => {
      e.preventDefault();
      closeHandler.current?.();
    };
    d.addEventListener("cancel", close);
    return () => {
      d.removeEventListener("cancel", close);
      d.close();
      if (previousFocus instanceof HTMLElement && previousFocus.isConnected)
        previousFocus.focus();
    };
  }, []);
  return (
    <dialog ref={ref} aria-labelledby={titleId}>
      <header className="dialog-heading">
        <h2 id={titleId}>{title}</h2>
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
