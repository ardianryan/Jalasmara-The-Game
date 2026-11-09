// Keep download accounting in the engine's existing requests, including its cache path.
export function withLoadingBridge(script) {
  if (!script.includes("const GODOT_CONFIG =")) return script;
  const hooks = [
    [
      "function displayFailureNotice(err) {",
      "function displayFailureNotice(err) {\n        reportHostLoading('error');",
    ],
    [
      "'onProgress': function (current, total) {",
      "'onProgress': function (current, total) {\n                reportHostLoading('downloading', current, total);",
    ],
    [
      "setStatusMode('hidden');",
      "reportHostLoading('preparing');\n            setStatusMode('hidden');",
    ],
  ];
  for (const [before, after] of hooks) {
    if (script.split(before).length !== 2)
      throw new Error(`Web export loading hook changed: ${before}`);
    script = script.replace(before, after);
  }
  return `
function reportHostLoading(phase, current = 0, total = 0) {
    if (window.parent === window) return;
    window.parent.postMessage({
        type: 'jalasmara:loading', version: 1, phase,
        downloadedBytes: Number.isSafeInteger(current) && current >= 0 ? current : 0,
        totalBytes: Number.isSafeInteger(total) && total > 0 ? total : null,
    }, window.location.origin);
}
reportHostLoading('downloading');
${script}`;
}
