export type LoadingPhase = "downloading" | "preparing" | "error";
export interface LoadingProgress {
  phase: LoadingPhase;
  downloadedBytes: number;
  totalBytes: number | null;
}
export const INITIAL_LOADING: LoadingProgress = {
  phase: "downloading",
  downloadedBytes: 0,
  totalBytes: null,
};

export function parseLoadingMessage(data: unknown): LoadingProgress | null {
  if (!data || typeof data !== "object") return null;
  const value = data as Record<string, unknown>;
  if (
    value.type !== "jalasmara:loading" ||
    value.version !== 1 ||
    !["downloading", "preparing", "error"].includes(String(value.phase))
  )
    return null;
  if (
    !Number.isSafeInteger(value.downloadedBytes) ||
    Number(value.downloadedBytes) < 0
  )
    return null;
  if (
    value.totalBytes !== null &&
    (!Number.isSafeInteger(value.totalBytes) ||
      Number(value.totalBytes) <= 0 ||
      Number(value.downloadedBytes) > Number(value.totalBytes))
  )
    return null;
  return {
    phase: value.phase as LoadingPhase,
    downloadedBytes: Number(value.downloadedBytes),
    totalBytes: value.totalBytes as number | null,
  };
}

export function formatDownloadBytes(bytes: number): string {
  return `${new Intl.NumberFormat("id-ID", { maximumFractionDigits: 1 }).format(bytes / 1_000_000)} MB`;
}
