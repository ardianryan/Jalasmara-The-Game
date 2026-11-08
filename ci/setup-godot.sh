#!/usr/bin/env bash
set -euo pipefail
godot_version=4.7.2
cache_dir="${CI_PROJECT_DIR:-$PWD}/.cache/godot-$godot_version"
mkdir -p "$cache_dir" "$HOME/.local/share/godot/export_templates/$godot_version.stable"
base="https://github.com/godotengine/godot/releases/download/$godot_version-stable"
if [ ! -x "$cache_dir/godot" ]; then
  curl --fail --location --retry 2 "$base/Godot_v${godot_version}-stable_linux.x86_64.zip" -o "$cache_dir/engine.zip"
  unzip -q -o "$cache_dir/engine.zip" -d "$cache_dir"
  mv "$cache_dir/Godot_v${godot_version}-stable_linux.x86_64" "$cache_dir/godot"
  rm "$cache_dir/engine.zip"
fi
if [ ! -s "$cache_dir/web_nothreads_release.zip" ]; then
  curl --fail --location --retry 2 "$base/Godot_v${godot_version}-stable_export_templates.tpz" -o "$cache_dir/templates.tpz"
  unzip -j -q -o "$cache_dir/templates.tpz" templates/web_nothreads_release.zip -d "$cache_dir"
  rm "$cache_dir/templates.tpz"
fi
cp "$cache_dir/web_nothreads_release.zip" "$HOME/.local/share/godot/export_templates/$godot_version.stable/"
GODOT_BIN="$cache_dir/godot" node scripts/export-game.mjs
