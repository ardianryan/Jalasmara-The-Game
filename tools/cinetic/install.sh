#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
target="$repo_root/.runtime/tools/cinetic"
pin="f4bbfc844877891fe92279d47b7874fb44d485ae"

if [ -d "$target/.git" ]; then
  current="$(git -C "$target" rev-parse HEAD)"
  if [ "$current" = "$pin" ]; then
    echo "Cinetic already installed at $pin"
    exit 0
  fi
  echo "Refusing to replace different Cinetic checkout: $current" >&2
  exit 1
fi
if [ -e "$target" ]; then
  echo "Refusing to replace non-Git directory: $target" >&2
  exit 1
fi

mkdir -p "$(dirname "$target")"
git clone https://github.com/Leonxlnx/cinetic.git "$target"
git -C "$target" checkout --detach "$pin"
test "$(git -C "$target" rev-parse HEAD)" = "$pin"
test -f "$target/skills/cinetic/SKILL.md"
echo "Installed Cinetic at $target ($pin)"
