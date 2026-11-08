#!/usr/bin/env bash
set -euo pipefail
latest_sha=$(git ls-remote origin "refs/heads/${CI_DEFAULT_BRANCH:-main}" | cut -f1)
if [ "$latest_sha" != "$CI_COMMIT_SHA" ]; then
  echo "Pipeline telah digantikan commit terbaru; mirror laporan dilewati."
  exit 0
fi
if [ -z "${GITHUB_DEPLOY_KEY_B64:-}" ]; then
  echo 'GITHUB_DEPLOY_KEY_B64 belum dikonfigurasi.' >&2
  exit 1
fi
umask 077
report_repo=
cleanup() {
  rm -f "$HOME/.ssh/jalasmara"
  if [ -n "$report_repo" ]; then rm -rf "$report_repo"; fi
}
trap cleanup EXIT
mkdir -p "$HOME/.ssh" reports
printf '%s' "$GITHUB_DEPLOY_KEY_B64" | base64 -d > "$HOME/.ssh/jalasmara"
curl -fsSL https://api.github.com/meta | python3 -c 'import json,sys; print("\n".join("github.com "+k for k in json.load(sys.stdin)["ssh_keys"]))' > "$HOME/.ssh/known_hosts"
export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/jalasmara -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes"
repo=git@github.com:ardianryan/Jalasmara-The-Game.git
git push "$repo" "$CI_COMMIT_SHA:refs/heads/main"
python3 - <<'PY'
import json,os,pathlib
p=pathlib.Path('reports')
meta={k:os.environ.get(k) for k in ['CI_COMMIT_SHA','CI_PIPELINE_ID','CI_PIPELINE_URL','CI_PROJECT_URL']}
(p/'pipeline.json').write_text(json.dumps(meta,indent=2))
(p/'README.md').write_text('# Laporan Jalasmara\n\nEksekusi dilakukan di GitLab CI. GitHub Actions dinonaktifkan.\n\nPipeline: '+os.environ['CI_PIPELINE_URL']+'\n\nCommit sumber: `'+os.environ['CI_COMMIT_SHA']+'`\n\nBerkas tersedia di direktori ini: JUnit, audit dependensi, dan CodeQL SARIF jika job terkait menghasilkan laporan. Status pipeline GitLab menjadi sumber kebenaran.\n')
PY
report_repo=$(mktemp -d)
cp -R reports/. "$report_repo/"
git -C "$report_repo" init -b ci-reports
git -C "$report_repo" config user.name 'Jalasmara GitLab CI'
git -C "$report_repo" config user.email 'ci@jalasmara.invalid'
git -C "$report_repo" add .
git -C "$report_repo" commit -m "Report GitLab pipeline $CI_PIPELINE_ID for $CI_COMMIT_SHORT_SHA"
git -C "$report_repo" push --force "$repo" HEAD:refs/heads/ci-reports
rm -f "$HOME/.ssh/jalasmara"
