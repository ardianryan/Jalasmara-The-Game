#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
target="$repo_root/.runtime/tools/pixelhand"
pin="e14af5884bd1a7ceaac33f8725c1a25dcd2cfbdb"

if [ -d "$target/.git" ]; then
  current="$(git -C "$target" rev-parse HEAD)"
  if [ "$current" = "$pin" ]; then
    echo "PixelHand already installed at $pin"
    exit 0
  fi
  echo "Refusing to replace different PixelHand checkout: $current" >&2
  exit 1
fi
if [ -e "$target" ]; then
  echo "Refusing to replace non-Git directory: $target" >&2
  exit 1
fi

mkdir -p "$(dirname "$target")"
git clone https://github.com/SirLichDevCraft/PixelHand.git "$target"
git -C "$target" checkout --detach "$pin"
test "$(git -C "$target" rev-parse HEAD)" = "$pin"
test -f "$target/src/cli.js"
echo "Installed PixelHand at $target ($pin)"
