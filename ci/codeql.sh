#!/usr/bin/env bash
set -euo pipefail
mkdir -p reports .cache/codeql .runtime
bundle=.cache/codeql/bundle.tar.gz
if [ ! -s "$bundle" ]; then
  curl -fL --retry 2 https://github.com/github/codeql-action/releases/latest/download/codeql-bundle-linux64.tar.gz -o "$bundle"
fi
# Keep tool sources outside the checkout so bundled externs are not project files.
tool_root=$(mktemp -d /tmp/jalasmara-codeql.XXXXXX)
trap 'rm -rf "$tool_root"' EXIT
tar -xzf "$bundle" -C "$tool_root"
printf '%s\n' '{"type":"commonjs"}' > "$tool_root/package.json"
codeql="$tool_root/codeql/codeql"
node -e 'console.log("Runner memory:",Math.round(require("os").totalmem()/1048576),"MiB; CodeQL budget: 3072 MiB, 1 thread")'
"$codeql" database create .runtime/codeql-db --language=javascript-typescript --source-root=. --build-mode=none --codescanning-config=ci/codeql-config.yml --ram=3072 --threads=1
"$codeql" database analyze .runtime/codeql-db javascript-security-and-quality.qls --format=sarif-latest --output=reports/codeql.sarif --ram=3072 --threads=1
node -e 'const fs=require("fs");const r=JSON.parse(fs.readFileSync("reports/codeql.sarif"));const errors=r.runs.flatMap(x=>(x.results??[]).filter(y=>(y.level??x.tool.driver.rules.find(z=>z.id===y.ruleId)?.defaultConfiguration?.level??"warning")==="error"));if(errors.length){console.error(errors.length+" CodeQL errors");process.exit(1)}'
