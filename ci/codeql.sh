#!/usr/bin/env bash
set -euo pipefail
mkdir -p reports .cache/codeql
if [ ! -x .cache/codeql/codeql/codeql ]; then
  curl -fL --retry 2 https://github.com/github/codeql-action/releases/latest/download/codeql-bundle-linux64.tar.gz -o .cache/codeql/bundle.tar.gz
  tar -xzf .cache/codeql/bundle.tar.gz -C .cache/codeql
  rm .cache/codeql/bundle.tar.gz
fi
.cache/codeql/codeql/codeql database create .runtime/codeql-db --language=javascript-typescript --source-root=. --build-mode=none --threads=2
.cache/codeql/codeql/codeql database analyze .runtime/codeql-db javascript-security-and-quality.qls --format=sarif-latest --output=reports/codeql.sarif --threads=2
node -e 'const fs=require("fs");const r=JSON.parse(fs.readFileSync("reports/codeql.sarif"));const errors=r.runs.flatMap(x=>x.results??[]).filter(x=>x.level==="error");if(errors.length){console.error(errors.length+" CodeQL errors");process.exit(1)}'
