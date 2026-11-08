#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
archive="${1:?Gunakan: scripts/verify-restore.sh /path/backup.archive.gz}"
test -s "$archive"
sha256sum --check "$archive.sha256"
# Restore into a separate database, leaving the live game untouched.
docker compose exec -T mongo mongorestore --archive --gzip --nsInclude='jalasmara.*' --nsFrom='jalasmara.*' --nsTo='jalasmara_restore_check.*' < "$archive"
docker compose exec -T mongo mongosh --quiet --eval '
const live=db.getSiblingDB("jalasmara"), restored=db.getSiblingDB("jalasmara_restore_check");
for (const name of live.getCollectionNames()) {
  const a=live.getCollection(name).countDocuments(),b=restored.getCollection(name).countDocuments();
  if(a!==b) throw new Error(name+": jumlah berbeda "+a+" / "+b);
  print(name+": "+b+" dokumen cocok");
}
restored.dropDatabase();
print("Restore terverifikasi; database pemeriksaan dihapus.");'
