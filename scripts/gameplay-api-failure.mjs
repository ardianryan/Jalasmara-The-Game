const gameplayPath = /^\/api\/(adventure|homestead|kedai|dive|calendar)\//;

export function gameplayFailureDetails(path, sent = {}, body = {}) {
  if (!gameplayPath.test(path)) return {};
  const finite = (value) => (Number.isFinite(value) ? value : undefined);
  return {
    code: typeof body.code === "string" ? body.code : undefined,
    error: typeof body.error === "string" ? body.error : undefined,
    requestVersion: finite(sent.version),
    fromPositionAt: finite(sent.fromPositionAt),
    expectedRevision: finite(sent.expectedRevision),
    action: typeof sent.action === "string" ? sent.action : undefined,
    area: ["hub", "forest", "home"].includes(sent.area) ? sent.area : undefined,
    x: finite(sent.x),
    y: finite(sent.y),
    pathPoints: Array.isArray(sent.path) ? sent.path.length : undefined,
    positionPath: Array.isArray(sent.path)
      ? sent.path.slice(0, 64).map((point) => ({
          x: finite(point?.x),
          y: finite(point?.y),
        }))
      : undefined,
    playerVersion: finite(body.player?.version),
    surfaceVersion: finite(body.surface?.playerVersion),
    surfacePositionAt: finite(body.surface?.positionAt),
  };
}

export function watchGameplayFailures(page, origin, failures) {
  const requests = new WeakMap();
  page.on("request", (request) => {
    const url = new URL(request.url());
    if (url.origin === origin && url.pathname.startsWith("/api/"))
      requests.set(request, Date.now());
  });
  page.on("response", async (response) => {
    const url = new URL(response.url());
    if (
      url.origin !== origin ||
      !url.pathname.startsWith("/api/") ||
      response.status() < 400
    )
      return;
    const request = response.request();
    let sent = {},
      body = {};
    if (gameplayPath.test(url.pathname)) {
      if (request.method() === "POST") {
        try {
          sent = request.postDataJSON() ?? {};
        } catch {
          // Invalid JSON is itself a useful failure; never fall back to raw bodies.
        }
      }
      body = (await response.json().catch(() => ({}))) ?? {};
    }
    const failure = {
      path: url.pathname,
      method: request.method(),
      status: response.status(),
      at: requests.get(request),
      respondedAt: Date.now(),
      ...gameplayFailureDetails(url.pathname, sent, body),
    };
    failures.push(failure);
    console.log(JSON.stringify({ phase: "api-failure", ...failure }));
  });
}
