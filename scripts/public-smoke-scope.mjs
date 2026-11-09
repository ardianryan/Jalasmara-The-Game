export function isAdminChunkUrl(value, origin) {
  const url = new URL(value, origin);
  return (
    url.origin === new URL(origin).origin &&
    /^\/assets\/admin-[A-Za-z0-9_-]+\.js$/.test(url.pathname)
  );
}

export function publicAcceptance(outcome, http1Diagnostic, hostOnly) {
  return {
    defaultPublicAccepted:
      outcome === "completed" && !http1Diagnostic && !hostOnly,
    hostPublicAccepted: outcome === "completed" && !http1Diagnostic && hostOnly,
    scope: hostOnly
      ? "host-auth-startup-reload-clock-and-admin-chunk-delivery"
      : "full-physical-route-journal-reload-clock",
  };
}
