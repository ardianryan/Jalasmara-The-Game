import { Component, lazy, Suspense, type ReactNode } from "react";
import type { AuthState } from "./api";
import { Loading, Notice } from "./components";

const Admin = lazy(() =>
  import("./admin").then(({ Admin }) => ({ default: Admin })),
);

class AdminLoadBoundary extends Component<
  { children: ReactNode },
  { failed: boolean }
> {
  state = { failed: false };

  static getDerivedStateFromError() {
    return { failed: true };
  }

  render() {
    if (this.state.failed)
      return (
        <main className="settings">
          <h1>Pengelola belum dapat dibuka</h1>
          <Notice error>
            Halaman pengelola belum dapat ditampilkan. Muat ulang halaman untuk
            mencoba lagi.
          </Notice>
          <button onClick={() => location.reload()}>Muat ulang halaman</button>
        </main>
      );
    return this.props.children;
  }
}

export function AdminRoute({ auth }: { auth: AuthState }) {
  return (
    <AdminLoadBoundary>
      <Suspense fallback={<Loading />}>
        <Admin auth={auth} />
      </Suspense>
    </AdminLoadBoundary>
  );
}
