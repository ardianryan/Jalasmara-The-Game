// Kept self-contained: the exporter embeds this function in the pinned Godot loader.
export function createPckFetch(manifest, fetchAsset, options) {
  const { baseUrl, subtle, partTimeoutMs = 30000 } = options;
  const validHash = (value) =>
    typeof value === "string" && /^[a-f0-9]{64}$/.test(value);
  if (
    manifest?.version !== 1 ||
    !validHash(manifest.sha256) ||
    !Number.isSafeInteger(manifest.bytes) ||
    manifest.bytes < 1 ||
    manifest.bytes > 512 * 1024 * 1024 ||
    manifest.partSize !== 1024 * 1024 ||
    !Array.isArray(manifest.hashes) ||
    manifest.hashes.length !== Math.ceil(manifest.bytes / manifest.partSize) ||
    !manifest.hashes.every(validHash)
  )
    throw new Error("Invalid PCK manifest");
  manifest = Object.freeze({
    version: manifest.version,
    sha256: manifest.sha256,
    bytes: manifest.bytes,
    partSize: manifest.partSize,
    hashes: Object.freeze(manifest.hashes.slice()),
  });
  const pckUrl = new URL("index.pck", baseUrl);
  const partBase = new URL(`pck/${manifest.sha256}/`, pckUrl);
  let verifiedIdentity = null;
  let identityRequest = 0;
  try {
    if (
      options.identityTarget &&
      Object.isExtensible(options.identityTarget) &&
      !Object.hasOwn(options.identityTarget, "jalasmaraPckIdentity")
    )
      Object.defineProperty(options.identityTarget, "jalasmaraPckIdentity", {
        get: () => verifiedIdentity,
        configurable: false,
        enumerable: false,
      });
  } catch {
    // Optional metadata must not block a verified game download.
  }

  return function pckFetch(file) {
    const url = new URL(file, baseUrl);
    if (url.origin !== pckUrl.origin || url.pathname !== pckUrl.pathname)
      return fetchAsset(file);
    const requestIdentity = ++identityRequest;
    verifiedIdentity = null;
    if (!subtle?.digest)
      return Promise.reject(
        new Error("Buka game melalui HTTPS agar aset dapat diverifikasi."),
      );
    const abort = new AbortController();
    const pending = new Map();
    let next = 0;
    let stopped = false;
    function launch(index) {
      const part = (async () => {
        const ownAbort = new AbortController();
        const onAbort = () => ownAbort.abort();
        abort.signal.addEventListener("abort", onAbort, { once: true });
        if (abort.signal.aborted) ownAbort.abort();
        const timeout = setTimeout(() => ownAbort.abort(), partTimeoutMs);
        try {
          const response = await fetchAsset(
            new URL(String(index), partBase).href,
            { signal: ownAbort.signal },
          );
          const size = Math.min(
            manifest.partSize,
            manifest.bytes - index * manifest.partSize,
          );
          if (
            response.status !== 200 ||
            response.headers.get("Content-Length") !== String(size) ||
            response.headers.get("X-Pck-Offset") !==
              String(index * manifest.partSize) ||
            response.headers.get("X-Pck-Length") !== String(manifest.bytes)
          )
            throw new Error(
              "Versi atau panjang aset game berubah. Muat ulang halaman.",
            );
          const bytes = new Uint8Array(await response.arrayBuffer());
          if (bytes.byteLength !== size)
            throw new Error("Unduhan aset game terputus.");
          const digest = await subtle.digest("SHA-256", bytes);
          const actual = Array.from(new Uint8Array(digest), (value) =>
            value.toString(16).padStart(2, "0"),
          ).join("");
          if (actual !== manifest.hashes[index])
            throw new Error("Pemeriksaan aset game gagal. Coba lagi.");
          return bytes;
        } finally {
          clearTimeout(timeout);
          abort.signal.removeEventListener("abort", onAbort);
        }
      })();
      part.catch(() => {});
      pending.set(index, part);
    }
    function stop() {
      stopped = true;
      abort.abort();
      pending.clear();
    }
    const body = new ReadableStream(
      {
        start() {
          for (
            let index = 0;
            index < Math.min(4, manifest.hashes.length);
            index++
          )
            launch(index);
        },
        async pull(controller) {
          if (stopped) return;
          try {
            const index = next++;
            const bytes = await pending.get(index);
            if (stopped) return;
            pending.delete(index);
            controller.enqueue(bytes);
            if (index + 4 < manifest.hashes.length) launch(index + 4);
            if (next === manifest.hashes.length) {
              stop();
              controller.close();
              // All parts reached the consumer; this does not attest Godot READY.
              if (requestIdentity === identityRequest)
                verifiedIdentity = Object.freeze({
                  schemaVersion: 1,
                  pckSha256: manifest.sha256,
                  pckBytes: manifest.bytes,
                  partCount: manifest.hashes.length,
                  verification: "all-parts-verified-manifest",
                });
            }
          } catch (error) {
            stop();
            controller.error(error);
          }
        },
        cancel() {
          stop();
        },
      },
      { highWaterMark: 0 },
    );
    return Promise.resolve(
      new Response(body, {
        headers: {
          "Content-Type": "application/octet-stream",
          "Content-Length": String(manifest.bytes),
        },
      }),
    );
  };
}

export function withSegmentedPck(source, manifest) {
  const before = "return fetch(file).then(function (response) {";
  if (
    source.split(before).length !== 2 ||
    source.includes("const jalasmaraAssetFetch =")
  )
    throw new Error("Godot 4.7.2 PCK fetch export pattern changed");
  return (
    `const jalasmaraAssetFetch = (${createPckFetch.toString()})(${JSON.stringify(manifest)}, globalThis.fetch.bind(globalThis), {baseUrl: globalThis.location.href, subtle: globalThis.crypto?.subtle, identityTarget: globalThis});\n` +
    source.replace(
      before,
      "return jalasmaraAssetFetch(file).then(function (response) {",
    )
  );
}
