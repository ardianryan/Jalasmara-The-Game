import type {
  Player,
  Catalog,
  DiveView,
  ShiftView,
} from "../../../packages/shared/src/index";
export interface AuthState {
  user: Player | null;
  csrf: string;
  oidcEnabled: boolean;
  oidcLabel: string;
  linked: boolean;
}
export interface GameState {
  player: Player;
  catalog: Omit<Catalog, "questions">;
  contentId: string;
  dive: DiveView | null;
  shift: ShiftView | null;
}
let csrf = "";
export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
    public code?: string,
  ) {
    super(message);
  }
}
export async function api<T = any>(
  path: string,
  body?: unknown,
  method = body === undefined ? "GET" : "POST",
  key?: string,
): Promise<T> {
  const response = await fetch(`/api${path}`, {
    method,
    credentials: "same-origin",
    headers: {
      ...(body === undefined ? {} : { "Content-Type": "application/json" }),
      ...(method === "GET"
        ? {}
        : {
            "X-CSRF-Token": csrf,
            "Idempotency-Key": key ?? crypto.randomUUID(),
          }),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const data = await response.json();
  if (!response.ok)
    throw new ApiError(
      response.status,
      data.error ?? "Permintaan gagal.",
      data.code,
    );
  if (data.csrf) csrf = data.csrf;
  return data;
}
export async function session() {
  return api<AuthState>("/auth/session");
}
export const fmt = (n: number) => new Intl.NumberFormat("id-ID").format(n);
