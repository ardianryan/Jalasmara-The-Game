#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
backup_dir="${BACKUP_DIR:-/var/backups/jalasmara}"
mkdir -p "$backup_dir"
archive="$backup_dir/jalasmara-$(date -u +%Y%m%dT%H%M%SZ).archive.gz"
docker compose exec -T mongo mongodump --db jalasmara --archive --gzip > "$archive"
test -s "$archive"
sha256sum "$archive" > "$archive.sha256"
printf 'Backup tersimpan: %s\n' "$archive"
