import { createHash } from "node:crypto";

const PRELOADER_SHA256 =
  "5205574baa83a992d8fcc4e18e753f1fea2f37d0386d6863756e0f42719562bf";
const ORIGINAL = `\t\t\tstart: function (controller) {
\t\t\t\tonloadprogress(reader, controller).then(function () {
\t\t\t\t\tcontroller.close();
\t\t\t\t});
\t\t\t},`;

const PATCHED = `\t\t\tstart: function (controller) {
\t\t\t\treturn onloadprogress(reader, controller).then(function () {
\t\t\t\t\tcontroller.close();
\t\t\t\t}, function (error) {
\t\t\t\t\tcontroller.error(error);
\t\t\t\t});
\t\t\t},`;

function occurrences(source, fragment) {
  return source.split(fragment).length - 1;
}

export function withTrackedStreamErrors(source) {
  const oldCount = occurrences(source, ORIGINAL);
  const patchedCount = occurrences(source, PATCHED);
  const start = source.indexOf("const Preloader =");
  const end = source.indexOf("\n};", start);
  if (
    start < 0 ||
    end < 0 ||
    occurrences(source, "const Preloader =") !== 1 ||
    oldCount + patchedCount !== 1
  ) {
    throw new Error("Godot 4.7.2 tracked-stream export pattern changed");
  }
  let originalSection = source.slice(start, end + 3).replace(PATCHED, ORIGINAL);
  if (
    source.startsWith("const jalasmaraAssetFetch = (function createPckFetch(")
  )
    originalSection = originalSection.replace(
      "return jalasmaraAssetFetch(file).then(function (response) {",
      "return fetch(file).then(function (response) {",
    );
  if (
    createHash("sha256").update(originalSection).digest("hex") !==
    PRELOADER_SHA256
  ) {
    throw new Error("Godot 4.7.2 tracked-stream export implementation changed");
  }
  return patchedCount === 1 ? source : source.replace(ORIGINAL, PATCHED);
}
