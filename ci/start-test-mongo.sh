#!/usr/bin/env bash
set -euo pipefail

# The GitHub job container owns this disposable server; no production connection is used.
if [ "${GITHUB_ACTIONS:-}" != true ] || [ "${GITHUB_REPOSITORY:-}" != ardianryan/Jalasmara-The-Game ]; then
  echo 'Run this bootstrap only inside the Jalasmara GitHub Actions job.' >&2
  exit 1
fi
if [ "$(id -u)" != 0 ] || [ "$(dpkg --print-architecture)" != amd64 ]; then
  echo 'Expected the root amd64 Debian job container.' >&2
  exit 1
fi
curl --fail --silent --show-error --location --retry 2 \
  https://pgp.mongodb.com/server-8.0.asc \
  -o /tmp/jalasmara-mongodb-signing-key.asc
gpg --batch --dearmor -o /usr/share/keyrings/jalasmara-mongodb-8.gpg \
  /tmp/jalasmara-mongodb-signing-key.asc
printf '%s\n' 'deb [arch=amd64 signed-by=/usr/share/keyrings/jalasmara-mongodb-8.gpg] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main' \
  > /etc/apt/sources.list.d/jalasmara-mongodb-8.list
apt-get update -qq
apt-get install -y -qq mongodb-org-server
printf '\n127.0.0.1 mongo\n' >> /etc/hosts
mkdir -p /tmp/jalasmara-ci-mongo
mongod --replSet rs0 --bind_ip 127.0.0.1 --port 27018 \
  --dbpath /tmp/jalasmara-ci-mongo --logpath /tmp/jalasmara-ci-mongo.log --fork
